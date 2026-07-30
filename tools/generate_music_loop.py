# -*- coding: utf-8 -*-
"""Generates a seamlessly-looping rock backing track (Beat It-style groove)
as a 16-bit 44.1 kHz WAV with an embedded smpl loop chunk (auto-loops in Godot).

Output: assets/audio/gallop_beat_loop.wav (~13.9 s, 8 bars @ 138 BPM)
"""
import struct
import numpy as np

SR = 44100
BPM = 138
BARS = 8
BEATS = BARS * 4
SPB = round(60.0 / BPM * SR)          # samples per beat
EIGHTH = SPB // 2
N = BEATS * SPB                        # total loop length in samples

rng = np.random.default_rng(42)
mix = np.zeros(N, dtype=np.float64)


def add(start, sig, gain=1.0):
    """Add a signal at sample position `start`, wrapping past the loop end."""
    start = int(start) % N
    end = start + len(sig)
    if end <= N:
        mix[start:end] += sig * gain
    else:
        first = N - start
        mix[start:] += sig[:first] * gain
        mix[:end - N] += sig[first:] * gain


def onepole_lp(x, cutoff):
    """Simple one-pole lowpass."""
    a = 1.0 - np.exp(-2.0 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y


def env_ad(n, attack_s, decay_rate):
    t = np.arange(n) / SR
    e = np.exp(-t * decay_rate)
    a = max(1, int(attack_s * SR))
    e[:a] *= np.linspace(0.0, 1.0, a)
    return e


def saw(freq, n, detune=1.0):
    t = np.arange(n) / SR
    return 2.0 * ((freq * detune * t) % 1.0) - 1.0


# --- Drums -------------------------------------------------------------

def kick():
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    f = 40.0 + 120.0 * np.exp(-t * 35.0)
    phase = 2.0 * np.pi * np.cumsum(f) / SR
    body = np.sin(phase) * np.exp(-t * 14.0)
    click = rng.standard_normal(n) * np.exp(-t * 500.0) * 0.4
    return body + click


def snare():
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n) * np.exp(-t * 24.0)
    tone = np.sin(2.0 * np.pi * 190.0 * t) * np.exp(-t * 18.0) * 0.5
    return noise * 0.9 + tone


def hat(open_=False):
    n = int((0.22 if open_ else 0.055) * SR)
    t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = np.diff(noise, prepend=0.0)  # crude highpass
    return noise * np.exp(-t * (14.0 if open_ else 90.0))


def tom(freq):
    n = int(0.25 * SR)
    t = np.arange(n) / SR
    f = freq * (1.0 + 0.4 * np.exp(-t * 25.0))
    phase = 2.0 * np.pi * np.cumsum(f) / SR
    return np.sin(phase) * np.exp(-t * 12.0)


# --- Synths ------------------------------------------------------------

def bass_note(freq, dur_samples):
    n = int(dur_samples)
    sig = saw(freq, n) + 0.6 * saw(freq, n, detune=1.006) + 0.5 * np.sign(
        np.sin(2.0 * np.pi * freq * 0.5 * np.arange(n) / SR))
    sig = onepole_lp(sig, 700.0)
    return sig * env_ad(n, 0.004, 7.0)


def power_chord(root_freq, dur_samples):
    n = int(dur_samples)
    sig = np.zeros(n)
    for ratio in (1.0, 1.4983, 2.0):  # root, fifth, octave
        for det in (0.997, 1.004):
            sig += saw(root_freq * ratio, n, detune=det)
    sig = onepole_lp(sig, 1400.0)
    return sig * env_ad(n, 0.003, 11.0) / 6.0


# --- Note frequencies ---------------------------------------------------
C2, D2, Eb2, E2, F2, G2, A2 = 65.41, 73.42, 77.78, 82.41, 87.31, 98.0, 110.0
E3, D3, C3 = 164.81, 146.83, 130.81

# --- Drum pattern (per bar, positions in eighth notes) ------------------
KICK_POS = (0, 3, 4)
SNARE_POS = (2, 6)

for bar in range(BARS):
    base = bar * 4 * SPB
    for p in KICK_POS:
        add(base + p * EIGHTH, kick(), 1.0)
    for p in SNARE_POS:
        add(base + p * EIGHTH, snare(), 0.85)
    for p in range(8):
        accent = 0.5 if p % 2 == 0 else 0.3
        add(base + p * EIGHTH, hat(), accent)
    # open hat pushing into the next bar
    add(base + 7 * EIGHTH, hat(open_=True), 0.25)

# snare/tom fill in the last beat of bar 8
fill_base = 7 * 4 * SPB + 3 * SPB
sixteenth = SPB // 4
for i, drum in enumerate((snare(), tom(150.0), tom(110.0), snare())):
    add(fill_base + i * sixteenth, drum, 0.7)

# --- Bass riff (Em / D, Beat It-style drive) ----------------------------
EM_BAR = [(0, E2, 1), (1, E2, 1), (2, D2, 1), (3, E2, 2), (5, E2, 1), (6, G2, 1), (7, A2, 1)]
D_BAR = [(0, D2, 1), (1, D2, 1), (2, C2, 1), (3, D2, 2), (5, D2, 1), (6, F2, 1), (7, C2, 1)]
CD_BAR = [(0, C2, 1), (1, C2, 1), (2, C2, 1), (3, C2, 1), (4, D2, 1), (5, D2, 1), (6, D2, 1), (7, D2, 1)]
# final bar: chromatic walk-up back into E for a seamless musical loop
END_BAR = [(0, E2, 2), (3, E2, 1), (4, E2, 1), (5, G2, 1), (6, D2, 1), (7, Eb2, 1)]

BAR_RIFFS = [EM_BAR, D_BAR, EM_BAR, D_BAR, EM_BAR, D_BAR, CD_BAR, END_BAR]

for bar, riff in enumerate(BAR_RIFFS):
    base = bar * 4 * SPB
    for pos, freq, dur in riff:
        add(base + pos * EIGHTH, bass_note(freq, dur * EIGHTH * 0.95), 0.55)

# --- Power-chord stabs ---------------------------------------------------
CHORDS = [E2, D2, E2, D2, E2, D2, None, E2]  # bar 7 handled separately

for bar, root in enumerate(CHORDS):
    base = bar * 4 * SPB
    if root is None:  # bar 7: C for half, D for half
        add(base, power_chord(C3, 3 * EIGHTH), 0.5)
        add(base + 4 * EIGHTH, power_chord(D3, 3 * EIGHTH), 0.5)
        continue
    for p in (0, 3):
        add(base + p * EIGHTH, power_chord(root * 2.0, 2 * EIGHTH), 0.45)

# --- Master --------------------------------------------------------------
# gentle saturation for glue, then normalize
mix = np.tanh(mix * 1.2)
mix *= 0.89 / np.max(np.abs(mix))
pcm = (mix * 32767.0).astype('<i2').tobytes()

# --- Write WAV with smpl loop chunk --------------------------------------
fmt = struct.pack('<HHIIHH', 1, 1, SR, SR * 2, 2, 16)
smpl = struct.pack('<9I', 0, 0, 1_000_000_000 // SR, 60, 0, 0, 0, 1, 0)
smpl += struct.pack('<6I', 0, 0, 0, N - 1, 0, 0)  # forward loop, whole file

chunks = b''
for cid, body in ((b'fmt ', fmt), (b'smpl', smpl), (b'data', pcm)):
    chunks += cid + struct.pack('<I', len(body)) + body
    if len(body) % 2:
        chunks += b'\x00'

out_path = 'assets/audio/gallop_beat_loop.wav'
with open(out_path, 'wb') as f:
    f.write(b'RIFF' + struct.pack('<I', 4 + len(chunks)) + b'WAVE' + chunks)

print(f'Wrote {out_path}: {N} samples, {N / SR:.2f} s, {BARS} bars @ {BPM} BPM')
