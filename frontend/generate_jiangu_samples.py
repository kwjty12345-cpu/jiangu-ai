import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100


def write_wav(filepath: str, samples: list[float]):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    peak = max((abs(s) for s in samples), default=1.0)
    norm = 0.92 / peak if peak > 0 else 1.0

    with wave.open(filepath, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit PCM
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            val = max(-1.0, min(1.0, s * norm))
            frames.extend(struct.pack("<h", int(val * 32767)))
        wf.writeframes(frames)


def generate_jiangu_center(duration: float, is_heavy: bool) -> list[float]:
    """
    模拟真实中国建鼓（木腔牛皮大鼓）鼓心音色：
    1. 牛皮张力瞬态音高下潜 (Pitch-drop membrane tension)
    2. 圆形鼓膜贝塞尔振动模态 (1.0, 1.593, 2.135, 2.295)
    3. 木质鼓腔低频空气共鸣
    4. 鼓槌撞击牛皮瞬态噪声 + 厅堂自然混响尾音
    """
    rng = random.Random(433 if is_heavy else 434)
    total_samples = int(SAMPLE_RATE * duration)
    out = [0.0] * total_samples

    base_freq = 66.0 if is_heavy else 78.0
    pitch_drop = 52.0 if is_heavy else 34.0
    drop_tau = 0.042 if is_heavy else 0.028
    decay_tau = 0.42 if is_heavy else 0.24

    phase1 = phase2 = phase3 = phase4 = phase_cavity = 0.0
    lp_noise = 0.0

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        # 极短起音包络（4ms），避免爆音同时保留鼓槌扎实触感
        attack = min(1.0, t / 0.004)

        # 牛皮受击瞬间张力增大导致音高略高，随后迅速回落至基频
        inst_freq = base_freq + pitch_drop * math.exp(-t / drop_tau)
        dt = 1.0 / SAMPLE_RATE

        phase1 += 2.0 * math.pi * inst_freq * dt
        phase2 += 2.0 * math.pi * (inst_freq * 1.593) * dt
        phase3 += 2.0 * math.pi * (inst_freq * 2.135) * dt
        phase4 += 2.0 * math.pi * (inst_freq * 2.295) * dt
        phase_cavity += 2.0 * math.pi * (base_freq * 2.02) * dt

        # 鼓膜主振动 + 泛音衰减
        env_main = math.exp(-t / decay_tau)
        env_overtone1 = math.exp(-t / (decay_tau * 0.48))
        env_overtone2 = math.exp(-t / (decay_tau * 0.25))
        env_cavity = math.exp(-t / (decay_tau * 0.65))

        membrane = (
            1.00 * math.sin(phase1) * env_main
            + (0.42 if is_heavy else 0.34) * math.sin(phase2) * env_overtone1
            + 0.18 * math.sin(phase3) * env_overtone2
            + 0.12 * math.sin(phase4) * env_overtone2
            + 0.28 * math.sin(phase_cavity) * env_cavity
        )

        # 鼓槌敲击牛皮瞬态（低通滤波噪声）
        white = rng.uniform(-1.0, 1.0)
        lp_noise = lp_noise * 0.82 + white * 0.18
        slap_env = math.exp(-t / 0.016)
        slap = lp_noise * slap_env * (0.65 if is_heavy else 0.52)

        sample = attack * (membrane + slap)
        # 轻度木腔饱和温暖感
        sample = math.tanh(sample * (1.35 if is_heavy else 1.15))
        out[i] = sample

    # 简易博物馆展厅早期反射混响（28ms 与 47ms 延迟抽头）
    d1 = int(SAMPLE_RATE * 0.028)
    d2 = int(SAMPLE_RATE * 0.047)
    for i in range(d2, total_samples):
        out[i] += 0.16 * out[i - d1] + 0.11 * out[i - d2]

    return out


def generate_jiangu_rim(duration: float = 0.22) -> list[float]:
    """
    模拟敲击建鼓漆木鼓边与铜鼓钉（鼓边清脆木声）：
    高频硬木共振模态 + 极短乾脆衰减
    """
    rng = random.Random(435)
    total_samples = int(SAMPLE_RATE * duration)
    out = [0.0] * total_samples

    modes = [
        (1140.0, 1.00, 0.026),
        (1890.0, 0.72, 0.019),
        (2740.0, 0.48, 0.013),
        (420.0, 0.45, 0.038),
    ]

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        attack = min(1.0, t / 0.0015)
        sig = 0.0
        for freq, amp, tau in modes:
            sig += amp * math.sin(2.0 * math.pi * freq * t) * math.exp(-t / tau)

        click = rng.uniform(-1.0, 1.0) * math.exp(-t / 0.004) * 0.85
        out[i] = attack * math.tanh((sig + click) * 1.4)

    return out


def generate_bronze_gong(duration: float = 1.6) -> list[float]:
    """
    模拟青铜鼓座余韵 / 鸣金收兵锣声（为 P3 预备）
    """
    total_samples = int(SAMPLE_RATE * duration)
    out = [0.0] * total_samples
    freqs = [295.0, 418.0, 588.0, 835.0, 1180.0]
    amps = [1.0, 0.75, 0.55, 0.35, 0.22]

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        attack = min(1.0, t / 0.008)
        glide = 1.0 + 0.018 * math.exp(-t / 0.12)
        sig = 0.0
        for idx, (f, a) in enumerate(zip(freqs, amps)):
            tau = 0.75 / (1.0 + idx * 0.35)
            sig += a * math.sin(2.0 * math.pi * f * glide * t) * math.exp(-t / tau)
        out[i] = attack * math.tanh(sig * 0.9)

    return out


if __name__ == "__main__":
    base_dir = os.path.join(os.path.dirname(__file__), "assets", "audio")
    write_wav(os.path.join(base_dir, "drum_heavy.wav"), generate_jiangu_center(0.95, True))
    write_wav(os.path.join(base_dir, "drum_light.wav"), generate_jiangu_center(0.55, False))
    write_wav(os.path.join(base_dir, "drum_rim.wav"), generate_jiangu_rim(0.22))
    write_wav(os.path.join(base_dir, "gong_retreat.wav"), generate_bronze_gong(1.6))
    print(f"Successfully generated 4 authentic Jian Gu WAV samples in: {base_dir}")