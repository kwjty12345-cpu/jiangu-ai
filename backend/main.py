import json
import os
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

try:
    from google.cloud import dialogflow_v2 as dialogflow
except ImportError:
    dialogflow = None

# ============================================================================
# FastAPI App & CORS
# ============================================================================
app = FastAPI(title="Jian Gu Interactive Guide API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent
KEY_PATH = BASE_DIR / "service-account-key.json"
FEEDBACK_LOG_PATH = BASE_DIR / "feedback_log.jsonl"

# ============================================================================
# Google Cloud Credentials (Cloud Env Var first, Local JSON fallback)
# ============================================================================
DIALOGFLOW_PROJECT_ID: Optional[str] = None
env_creds = os.getenv("GOOGLE_CREDENTIALS_JSON")

if env_creds:
    try:
        key_data = json.loads(env_creds)
        DIALOGFLOW_PROJECT_ID = key_data.get("project_id")
        tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False, encoding="utf-8")
        tmp.write(env_creds)
        tmp.close()
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = tmp.name
    except Exception as exc:
        print(f"[Auth] Failed to load GOOGLE_CREDENTIALS_JSON: {exc}")
        DIALOGFLOW_PROJECT_ID = None
elif KEY_PATH.exists():
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(KEY_PATH)
    try:
        key_data = json.loads(KEY_PATH.read_text(encoding="utf-8"))
        DIALOGFLOW_PROJECT_ID = key_data.get("project_id")
    except Exception:
        DIALOGFLOW_PROJECT_ID = None

# Per-session real user name store (prevents stale/hardcoded names like "Jackson")
SESSION_USER_NAMES: Dict[str, str] = {}

# ============================================================================
# Request Models
# ============================================================================
class ChatRequest(BaseModel):
    session_id: str
    text: str


class FeedbackRequest(BaseModel):
    session_id: str
    intent: str = ""
    reply: str = ""
    rating: int = 0


# ============================================================================
# 11-Topic Structured Knowledge Base (English-Only, Strict Reference Schema)
# ============================================================================
KNOWLEDGE_BASE: Dict[str, Dict[str, Any]] = {
    "origins": {
        "intent": "JianGu_Origins",
        "mood": "explaining",
        "suggest_practice": False,
        "keywords": ["origin", "history", "ancient", "shang", "zhou", "begin", "start"],
        "reply": (
            "The Jian Gu (the ancient Chinese standing drum) traces its lineage back to the Shang "
            "and Zhou dynasties. Unlike suspended drums, it is pierced vertically by a single pillar "
            "and anchored into a sculptural base, serving as a ceremonial centerpiece for over two millennia."
        ),
        "detail": (
            "Across the Warring States, Han, Tang, Ming, and Qing eras, the Jian Gu evolved from a "
            "sacred ritual instrument into a versatile symbol of court authority, martial command, and "
            "festive performance. Classic ritual manuals describe it as the rhythmic foundation of "
            "grand imperial orchestras."
        ),
        "suggestions": [
            "Zeng Hou Yi dragon base",
            "How is the Jian Gu built?",
            "Role in court rituals",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Origins of the Jian Gu",
                "topic_id": "origins",
                "snippet": "Historical lineage of the Chinese standing drum from Shang and Zhou times.",
            },
            {
                "type": "external",
                "title": "Palace Museum Court Ritual Instruments",
                "url": "https://en.dpm.org.cn/",
                "snippet": "Overview of imperial ritual music and ceremonial percussion in China.",
            },
        ],
    },
    "zeng-hou-yi-base": {
        "intent": "JianGu_ZengHouYi_Base",
        "mood": "explaining",
        "suggest_practice": False,
        "keywords": ["zeng", "hou yi", "dragon", "marquis", "hubei", "tomb", "bronze base"],
        "reply": (
            "Unearthed from the 433 BCE tomb of Marquis Yi of Zeng in Hubei, the bronze Jian Gu base "
            "is celebrated as a pinnacle of Warring States metallurgy. Sixteen dragons twist together "
            "in openwork bronze to anchor the tall standing drum."
        ),
        "detail": (
            "Excavated alongside the famous Bianzhong chime bells, the base weighs nearly 180 kilograms "
            "and consists of eight pairs of intertwined dragons—each decorated with coiled serpent motifs "
            "and inlaid details that reveal the extraordinary refinement of Chu state bronzework."
        ),
        "suggestions": [
            "Lost-wax bronze casting",
            "Central pillar function",
            "Overview of the structure",
        ],
        "sources": [
            {
                "type": "artifact",
                "title": "Zeng Hou Yi Bronze Dragon Base",
                "topic_id": "zeng-hou-yi-base",
                "snippet": "Warring States openwork bronze drum stand from 433 BCE.",
            },
            {
                "type": "external",
                "title": "Hubei Provincial Museum — Marquis Yi of Zeng Collection",
                "url": "https://www.hbww.org.cn/",
                "snippet": "Archival documentation of the Marquis Yi of Zeng bronze musical instruments.",
            },
        ],
    },
    "structure-overview": {
        "intent": "JianGu_Structure_Overview",
        "mood": "explaining",
        "suggest_practice": True,
        "keywords": ["overview", "structure", "parts", "built", "anatomy", "made of", "components"],
        "reply": (
            "A ceremonial Jian Gu brings together four signature elements: the ornate Yu Bao "
            "(feather canopy) at the summit, the vertical Guan Zhu (central pillar), the double-headed "
            "lacquered cowhide drum body, and the sculpted pedestal below."
        ),
        "detail": (
            "Because the central pillar passes directly through the wooden drum shell, the entire "
            "instrument stands upright without a hanging rack. The thick cowhide center yields a deep, "
            "commanding tone, while the lacquered wooden rim produces a crisp, bright click."
        ),
        "suggestions": [
            "What is the Guan Zhu?",
            "Significance of the Yu Bao",
            "Lost-wax bronze casting",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Four Structural Highlights Overview",
                "topic_id": "structure-overview",
                "snippet": "Four structural parts of the Jian Gu standing drum.",
            },
        ],
    },
    "central-pillar": {
        "intent": "JianGu_Central_Pillar",
        "mood": "explaining",
        "suggest_practice": True,
        "keywords": ["pillar", "guan zhu", "guanzhu", "pole", "pierce", "upright"],
        "reply": (
            "The Guan Zhu (central penetrating pillar) runs straight through the wooden drum frame, "
            "locking the Jian Gu upright into its base while holding up the canopy overhead."
        ),
        "detail": (
            "This vertical shaft is what gives the Jian Gu its literal name—the 'erected' or 'standing' "
            "drum. By eliminating bulky side frames, drummers could strike freely from either side "
            "during temple rituals, banquets, or chariot processions."
        ),
        "suggestions": [
            "Feather canopy meaning",
            "Zeng Hou Yi dragon base",
            "Han Dynasty drum dance",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Central Pillar (Guan Zhu)",
                "topic_id": "central-pillar",
                "snippet": "Structural role of the vertical pillar piercing the Jian Gu body.",
            },
        ],
    },
    "feather-canopy": {
        "intent": "JianGu_Feather_Canopy",
        "mood": "explaining",
        "suggest_practice": False,
        "keywords": ["feather", "canopy", "yubao", "yu bao", "top", "plume", "tassel"],
        "reply": (
            "Crowning the central pillar, the Yu Bao (feather canopy) adorned with silk tassels and "
            "plumes marked the Jian Gu as a solemn instrument of royal state ritual."
        ),
        "detail": (
            "In imperial court orchestras, the towering canopy visually elevated the drum above other "
            "percussion instruments and symbolized auspicious harmony between heaven, earth, and "
            "sovereign order."
        ),
        "suggestions": [
            "Ming & Qing court rituals",
            "Central pillar function",
            "The Eight Tones system",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Feather Canopy (Yu Bao)",
                "topic_id": "feather-canopy",
                "snippet": "Symbolism of the decorative canopy crowning the ceremonial Jian Gu.",
            },
        ],
    },
    "lost-wax-casting": {
        "intent": "JianGu_Lost_Wax_Casting",
        "mood": "explaining",
        "suggest_practice": False,
        "keywords": ["lost-wax", "lost wax", "casting", "cast", "craft", "bronze made", "metallurgy"],
        "reply": (
            "Artisans crafted the Zeng Hou Yi Jian Gu base using lost-wax bronze casting: they sculpted "
            "the coiled dragon lattice in beeswax, encased it in clay, melted out the wax, and poured "
            "molten bronze into the hollow mold."
        ),
        "detail": (
            "This technique allowed delicate, undercut three-dimensional coils that conventional "
            "piece-molds could never release cleanly. Master founders then joined complex sections "
            "through bronze soldering, preserving crisp patterns after more than 2,400 years."
        ),
        "suggestions": [
            "Zeng Hou Yi dragon base",
            "Four structural highlights",
            "Origins of the Jian Gu",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Lost-Wax Bronze Casting",
                "topic_id": "lost-wax-casting",
                "snippet": "Ancient Chinese lost-wax bronze casting behind the Marquis Yi drum stand.",
            },
        ],
    },
    "court-rituals": {
        "intent": "JianGu_Court_Rituals",
        "mood": "explaining",
        "suggest_practice": True,
        "keywords": ["ritual", "court", "ming", "qing", "shaoyue", "shaole", "zhonghe", "ceremony", "temple", "peaceful"],
        "reply": (
            "During the Ming and Qing dynasties, the Jian Gu served in Zhonghe Shaoyue (imperial court "
            "ritual music) for state sacrifices and grand assemblies. Its deep pulse kept the orchestra "
            "unified, and three ceremonial drum rolls traditionally opened Confucian temple rites."
        ),
        "detail": (
            "Classical treatises praised the Jian Gu as the regulator of ensemble tempo. While bronze "
            "bells opened the musical movement and chime stones closed it, the Jian Gu anchored every "
            "solemn phrase across the courtyard."
        ),
        "suggestions": [
            "The Eight Tones system",
            "Ancient battlefield tactics",
            "Feather canopy symbolism",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Ming & Qing Court Rituals (Zhonghe Shaoyue)",
                "topic_id": "court-rituals",
                "snippet": "Ceremonial role of the Jian Gu in Ming and Qing imperial ensembles.",
            },
            {
                "type": "external",
                "title": "Zhonghe Shaoyue — National Intangible Cultural Heritage",
                "url": "https://www.ihchina.cn/",
                "snippet": "Official heritage profile of imperial Zhonghe Shaoyue court music.",
            },
        ],
    },
    "eight-tones": {
        "intent": "JianGu_Eight_Tones",
        "mood": "explaining",
        "suggest_practice": False,
        "keywords": ["eight tones", "ba yin", "bayin", "leather", "classification", "musicology"],
        "reply": (
            "In the classical Ba Yin (Eight Tones) classification system, the Jian Gu belongs to the "
            "Ge (leather/hide) category, defined by its taut cowhide drumheads."
        ),
        "detail": (
            "The Ba Yin system organizes traditional Chinese instruments by primary vibrating material: "
            "metal, stone, silk, bamboo, gourd, clay, leather, and wood. Leather drums provided the "
            "foundational pulse that balanced melodic bells, strings, and flutes."
        ),
        "suggestions": [
            "Ming & Qing court rituals",
            "Four structural highlights",
            "Origins of the Jian Gu",
        ],
        "sources": [
            {
                "type": "topic",
                "title": 'The "Eight Tones" (Ba Yin) System',
                "topic_id": "eight-tones",
                "snippet": "Where the Jian Gu stands in the classical Chinese acoustic taxonomy.",
            },
        ],
    },
    "battlefield-signaling": {
        "intent": "JianGu_Military_Tactics",
        "mood": "explaining",
        "suggest_practice": True,
        "keywords": ["military", "battle", "battlefield", "war", "army", "sun tzu", "art of war", "tactics", "signal", "advance"],
        "reply": (
            "On ancient battlefields, war drums such as the Jian Gu carried acoustic commands across "
            "vast formations. The Art of War explains that drums and gongs unified the ears of ten "
            "thousand soldiers—a thunderous drumbeat signaled troops to advance and lifted morale."
        ),
        "detail": (
            "Mounted on command chariots or elevated field stands, the deep low-frequency boom of the "
            "drum cut through the clamor of combat. While steady drum rolls drove the vanguard forward, "
            "striking bronze gongs signaled an orderly withdrawal."
        ),
        "suggestions": [
            "Ming & Qing court rituals",
            "Han Dynasty drum dance",
            "Dunhuang Cave 156 murals",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Ancient Battlefield Signaling",
                "topic_id": "battlefield-signaling",
                "snippet": "Military command acoustics of war drums and gongs in ancient China.",
            },
            {
                "type": "external",
                "title": "The Art of War: Military Maneuvers (Chinese Text Project)",
                "url": "https://ctext.org/art-of-war/maneuvering",
                "snippet": "Classical treatise on unifying armies through drums and gongs.",
            },
        ],
    },
    "han-drum-dance": {
        "intent": "JianGu_Han_Dance",
        "mood": "explaining",
        "suggest_practice": True,
        "keywords": ["han", "dance", "acrobat", "acrobatic", "banquet", "relief", "perform", "play", "how to play", "strike"],
        "reply": (
            "Han Dynasty stone reliefs depict lively acrobatic drum dances performed around tall "
            "standing Jian Gu drums at court banquets. Dancers leaped, spun, and struck both drum "
            "faces and rims in sync with rhythmic ensembles."
        ),
        "detail": (
            "Often paired with Pan Gu (plate-and-drum) choreography, these reliefs show how the "
            "Jian Gu crossed effortlessly from solemn ancestral temples into exuberant celebratory "
            "entertainment."
        ),
        "suggestions": [
            "Dunhuang Cave 156 murals",
            "Ancient battlefield tactics",
            "Four structural highlights",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Han Dynasty Acrobatic Drum Dance",
                "topic_id": "han-drum-dance",
                "snippet": "Depictions of the Jian Gu in Han Dynasty stone reliefs and banquet dances.",
            },
        ],
    },
    "dunhuang-murals": {
        "intent": "JianGu_Dunhuang_Murals",
        "mood": "explaining",
        "suggest_practice": False,
        "keywords": ["dunhuang", "mural", "tang", "cave", "156", "mogao", "silk road"],
        "reply": (
            "Tang Dynasty murals in Dunhuang Mogao Cave 156 portray grand military processions and "
            "celestial orchestras where brightly painted standing drums are played in motion."
        ),
        "detail": (
            "These murals highlight how percussion traditions flourished along the Silk Road, "
            "preserving vivid visual evidence of Tang drum silhouettes, lacquer colors, and ensemble "
            "formations."
        ),
        "suggestions": [
            "Han Dynasty drum dance",
            "Ancient battlefield tactics",
            "Origins of the Jian Gu",
        ],
        "sources": [
            {
                "type": "topic",
                "title": "Tang Dynasty Dunhuang Cave 156 Murals",
                "topic_id": "dunhuang-murals",
                "snippet": "Visual records of standing drums in Tang Dynasty Mogao Cave murals.",
            },
            {
                "type": "external",
                "title": "Dunhuang Academy — Digital Cave Archives",
                "url": "https://www.e-dunhuang.com/",
                "snippet": "High-resolution digital archives of Dunhuang Mogao Cave murals.",
            },
        ],
    },
}

# Map Dialogflow intent display names -> knowledge base keys
INTENT_TO_TOPIC_KEY: Dict[str, str] = {
    "JianGu_Origins": "origins",
    "History_Origin": "origins",
    "JianGu_History": "origins",
    "JianGu_ZengHouYi_Base": "zeng-hou-yi-base",
    "Zeng_Hou_Yi": "zeng-hou-yi-base",
    "JianGu_Structure_Overview": "structure-overview",
    "Structure_Overview": "structure-overview",
    "JianGu_Central_Pillar": "central-pillar",
    "Central_Pillar": "central-pillar",
    "JianGu_Feather_Canopy": "feather-canopy",
    "Feather_Canopy": "feather-canopy",
    "JianGu_Lost_Wax_Casting": "lost-wax-casting",
    "Lost_Wax_Casting": "lost-wax-casting",
    "JianGu_Court_Rituals": "court-rituals",
    "Court_Rituals": "court-rituals",
    "JianGu_Eight_Tones": "eight-tones",
    "Eight_Tones": "eight-tones",
    "JianGu_Military_Tactics": "battlefield-signaling",
    "Military_Tactics": "battlefield-signaling",
    "JianGu_Han_Dance": "han-drum-dance",
    "Han_Dance": "han-drum-dance",
    "JianGu_Dunhuang_Murals": "dunhuang-murals",
    "Dunhuang_Murals": "dunhuang-murals",
}

PRACTICE_INTENTS = {
    "JianGu_Structure_Overview",
    "JianGu_Central_Pillar",
    "JianGu_Court_Rituals",
    "JianGu_Military_Tactics",
    "JianGu_Han_Dance",
}


# ============================================================================
# Helper Functions (Text Sanitization, Name Handling, Dialogflow Call)
# ============================================================================
def normalize_english_text(text: str, user_name: str = "") -> str:
    """Enforces strict English-only output, spelling accuracy, and clean punctuation."""
    t = text.replace("$1", "")
    t = re.sub(r"\bZhonghe\s+Shaole\b", "Zhonghe Shaoyue", t, flags=re.IGNORECASE)
    t = re.sub(r"\bShaole\b", "Shaoyue", t, flags=re.IGNORECASE)
    t = re.sub(r"\bJianGu\b", "Jian Gu", t)
    t = re.sub(r"\bJiangu\b", "Jian Gu", t)

    # Strip any CJK parenthetical glosses or stray CJK characters
    t = re.sub(r"\uFF08[^\uFF09]*\uFF09", "", t)
    t = re.sub(r"\([^)]*[\u4e00-\u9fff]+[^)]*\)", "", t)
    t = re.sub(r"[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]+", " ", t)

    # Clean empty quotes/parentheses left behind
    t = re.sub(r"\(\s*\)", "", t)
    t = re.sub(r'["\u201C\u201D]\s*["\u201C\u201D]', "", t)
    t = re.sub(r"'\s*'", "", t)

    # Prevent leaked/fallback vocative names when no real user name exists
    if not user_name:
        t = re.sub(r",\s*Jackson([.!?])", r"\1", t, flags=re.IGNORECASE)

    t = re.sub(r"\s+([.,!?;:])", r"\1", t)
    t = re.sub(r"\s{2,}", " ", t).strip()
    return t


def extract_clean_name(raw_text: str) -> Optional[str]:
    """Extracts a plausible personal name during the onboarding step."""
    cleaned = re.sub(
        r"^(my name is|i am|i'm|call me|it's|this is|hi i'm|hello i'm)\s+",
        "",
        raw_text.strip(),
        flags=re.IGNORECASE,
    )
    cleaned = re.sub(r"[^A-Za-z0-9 '\-]", "", cleaned).strip()
    words = cleaned.split()
    if 1 <= len(words) <= 3 and len(cleaned) <= 28:
        return " ".join(w.capitalize() for w in words)
    return None


def match_local_topic_key(text: str) -> Optional[str]:
    lower = text.lower()
    best_key: Optional[str] = None
    best_score = 0
    for key, entry in KNOWLEDGE_BASE.items():
        score = sum(1 for kw in entry["keywords"] if kw in lower)
        if score > best_score:
            best_score = score
            best_key = key
    return best_key if best_score > 0 else None


def detect_dialogflow_intent(session_id: str, text: str) -> Optional[Dict[str, Any]]:
    """Calls Dialogflow ES if credentials and SDK are available."""
    if dialogflow is None or not DIALOGFLOW_PROJECT_ID:
        return None
    try:
        client = dialogflow.SessionsClient()
        session = client.session_path(DIALOGFLOW_PROJECT_ID, session_id)
        text_input = dialogflow.TextInput(text=text, language_code="en")
        query_input = dialogflow.QueryInput(text=text_input)
        response = client.detect_intent(
            request={"session": session, "query_input": query_input}
        )
        qr = response.query_result
        return {
            "intent": qr.intent.display_name if qr.intent else "",
            "fulfillment_text": qr.fulfillment_text or "",
            "parameters": dict(qr.parameters) if qr.parameters else {},
            "confidence": float(qr.intent_detection_confidence or 0.0),
        }
    except Exception as exc:
        print(f"[Dialogflow] Fallback to local KB due to error: {exc}")
        return None


# ============================================================================
# Routes
# ============================================================================
@app.get("/health")
def health_check() -> Dict[str, Any]:
    return {
        "status": "ok",
        "dialogflow_configured": bool(dialogflow and DIALOGFLOW_PROJECT_ID),
        "topics_loaded": len(KNOWLEDGE_BASE),
    }


@app.post("/chat")
def chat(req: ChatRequest) -> Dict[str, Any]:
    session_id = req.session_id.strip() or "default_session"
    user_text = req.text.strip()
    known_name = SESSION_USER_NAMES.get(session_id, "")

    # 1. System welcome trigger
    if user_text.lower() in {"hi", "hello", "hey"} and not known_name:
        return {
            "reply": (
                "Welcome! I am the Court Music Master, your interactive guide to the "
                "traditional Chinese Jian Gu (the standing drum)—covering its history, "
                "structure, craftsmanship, rituals, and music. Before we begin, what is your name?"
            ),
            "detail": "",
            "suggestions": [],
            "sources": [],
            "mood": "idle",
            "intent": "Default Welcome Intent",
            "suggest_practice": False,
        }

    # 2. First user message before name is set -> treat as name if it is not a topic query
    if not known_name and match_local_topic_key(user_text) is None:
        candidate_name = extract_clean_name(user_text)
        if candidate_name:
            SESSION_USER_NAMES[session_id] = candidate_name
            return {
                "reply": (
                    f"Pleased to meet you, {candidate_name}! Ask me anything about the Jian Gu's "
                    "origins, bronze dragon base, court rituals, or military use—or click "
                    "Drum Practice at the top whenever you want to play."
                ),
                "detail": "",
                "suggestions": [
                    "Origins of the Jian Gu",
                    "How is the Jian Gu built?",
                    "Role in court rituals",
                ],
                "sources": [],
                "mood": "happy",
                "intent": "Get_User_Name",
                "suggest_practice": False,
            }

    # 3. Call Dialogflow ES (if configured) + map into our clean English KB
    df_result = detect_dialogflow_intent(session_id, user_text)
    df_intent = (df_result or {}).get("intent", "")
    df_text = (df_result or {}).get("fulfillment_text", "")

    # Handle Dialogflow Get_User_Name intent explicitly
    if df_intent == "Get_User_Name":
        params = (df_result or {}).get("parameters", {})
        person = params.get("person")
        extracted = ""
        if isinstance(person, dict):
            extracted = str(person.get("name", "")).strip()
        elif isinstance(person, str):
            extracted = person.strip()
        if not extracted:
            extracted = extract_clean_name(user_text) or ""
        if extracted:
            SESSION_USER_NAMES[session_id] = extracted
            known_name = extracted
        greeting = f"Pleased to meet you, {known_name}! " if known_name else "Pleased to meet you! "
        return {
            "reply": (
                f"{greeting}What would you like to discover first about the Jian Gu—"
                "its bronze craftsmanship, Zhonghe Shaoyue court ceremonies, or battlefield signals?"
            ),
            "detail": "",
            "suggestions": [
                "Origins of the Jian Gu",
                "Four structural highlights",
                "Ancient battlefield tactics",
            ],
            "sources": [],
            "mood": "happy",
            "intent": "Get_User_Name",
            "suggest_practice": False,
        }

    # Resolve topic key from Dialogflow intent first, then local keyword match
    topic_key = INTENT_TO_TOPIC_KEY.get(df_intent) or match_local_topic_key(user_text)

    if topic_key and topic_key in KNOWLEDGE_BASE:
        entry = KNOWLEDGE_BASE[topic_key]
        # Prefer Dialogflow fulfillment text if rich & valid, otherwise use curated KB text
        raw_reply = (
            df_text
            if df_text and df_intent != "Default Fallback Intent" and len(df_text) > 40
            else entry["reply"]
        )
        clean_reply = normalize_english_text(raw_reply, user_name=known_name)
        clean_detail = normalize_english_text(entry["detail"], user_name=known_name)

        return {
            "reply": clean_reply,
            "detail": clean_detail,
            "suggestions": entry["suggestions"],
            "sources": entry["sources"],
            "mood": entry["mood"],
            "intent": entry["intent"],
            "suggest_practice": bool(
                entry["suggest_practice"] or entry["intent"] in PRACTICE_INTENTS
            ),
        }

    # 4. Graceful fallback when question is outside the 11 Jian Gu topics
    if df_text and df_intent and df_intent != "Default Fallback Intent":
        return {
            "reply": normalize_english_text(df_text, user_name=known_name),
            "detail": "",
            "suggestions": [
                "Origins of the Jian Gu",
                "How is the Jian Gu built?",
                "Ancient battlefield tactics",
            ],
            "sources": [],
            "mood": "explaining",
            "intent": df_intent,
            "suggest_practice": False,
        }

    return {
        "reply": (
            "As the Court Music Master, my archives focus on the traditional Chinese Jian Gu. "
            "Try asking about its Zeng Hou Yi bronze dragon base, structural parts, Zhonghe Shaoyue "
            "court rituals, or ancient battlefield signaling."
        ),
        "detail": "",
        "suggestions": [
            "Four structural highlights",
            "Zeng Hou Yi dragon base",
            "Ming & Qing court rituals",
        ],
        "sources": [],
        "mood": "confused",
        "intent": "Default Fallback Intent",
        "suggest_practice": False,
    }


@app.post("/feedback")
def record_feedback(req: FeedbackRequest) -> Dict[str, str]:
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "session_id": req.session_id,
        "intent": req.intent,
        "reply": req.reply,
        "rating": req.rating,
    }
    try:
        with FEEDBACK_LOG_PATH.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception as exc:
        print(f"[Feedback] Could not write log: {exc}")
    return {"status": "recorded"}