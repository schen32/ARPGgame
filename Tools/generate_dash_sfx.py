from pathlib import Path
import math, random, struct, wave

# Original short filtered-noise dash whoosh; no recordings or third-party samples.
def generate():
    rate, duration = 44100, 0.22
    rng = random.Random(82371)
    low, band = 0.0, 0.0
    samples = []
    for i in range(round(rate * duration)):
        t = i / rate
        u = t / duration
        cutoff = 700 + 3400 * math.sin(math.pi * u) ** 2
        coefficient = 2 * math.sin(math.pi * cutoff / rate)
        high = rng.uniform(-1, 1) - low - 0.85 * band
        band += coefficient * high
        low += coefficient * band
        envelope = (1 - math.exp(-t / 0.009)) * (1 - u) ** 2 * min(1, (duration - t) / 0.02)
        samples.append((band * 0.8 + low * 0.2) * envelope)
    peak = max(abs(x) for x in samples)
    path = Path(__file__).resolve().parents[1] / 'GodotStarter/audio/dash_whoosh.wav'
    with wave.open(str(path), 'wb') as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        sound.writeframes(b''.join(struct.pack('<h', round(x / peak * 0.7 * 32767)) for x in samples))
    print('Generated original 0.22s dash whoosh.')
if __name__ == '__main__':
    generate()
