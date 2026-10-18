from pathlib import Path
import math
import random
import struct
import wave

# Original synthetic attack gestures: an airy strike and a heavier palm thump.
rate = 44100
folder = Path(__file__).resolve().parents[1] / 'GodotStarter/audio'
for name, duration, seed in [('strike', 0.13, 2381), ('palm', 0.19, 5913)]:
    rng = random.Random(seed)
    low = 0.0
    samples = []
    for i in range(round(rate * duration)):
        t = i / rate
        u = t / duration
        noise = rng.uniform(-1, 1)
        low += (noise - low) * (0.2 if name == 'strike' else 0.065)
        envelope = (1 - math.exp(-t / 0.003)) * (1 - u) ** 2
        if name == 'strike':
            value = (noise - low) * 0.32 + low * 0.55
        else:
            phase = math.tau * (180 * t - 290 * t * t)
            value = low * 0.9 + math.sin(phase) * math.exp(-t / 0.035) * 0.55
        samples.append(value * envelope)
    peak = max(abs(value) for value in samples)
    with wave.open(str(folder / (name + '_use.wav')), 'wb') as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(rate)
        sound.writeframes(b''.join(struct.pack('<h', round(value / peak * 0.65 * 32767)) for value in samples))
print('Generated original Strike and Palm use sounds.')
