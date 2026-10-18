from pathlib import Path
import math
import struct
import wave

# Original soft two-tone pickup chime, synthesized without external samples.
rate = 44100
duration = 0.16
samples = []
for i in range(round(rate * duration)):
    t = i / rate
    value = 0.0
    for start, frequency, gain in [(0.0, 880.0, 0.65), (0.035, 1320.0, 0.45)]:
        age = t - start
        if age >= 0:
            envelope = (1 - math.exp(-age / 0.003)) * math.exp(-age / 0.032)
            value += gain * envelope * math.sin(math.tau * frequency * age)
    value *= min(1.0, (duration - t) / 0.015)
    samples.append(value)
path = Path(__file__).resolve().parents[1] / 'GodotStarter/audio/exp_pickup.wav'
with wave.open(str(path), 'wb') as sound:
    sound.setnchannels(1)
    sound.setsampwidth(2)
    sound.setframerate(rate)
    sound.writeframes(b''.join(struct.pack('<h', round(x * 32767)) for x in samples))
print('Generated original EXP pickup chime.')
