# Dot voice orb

Run `bash Preview/DotVoiceOrb/run.sh` from the checkout. The independent demo offers all six themes, idle/listening/speaking states, simulated bursts with pauses, manual 0–1 audio input, and sensitivity. No account, microphone, or voice connection is needed.

Embed the component in SwiftUI:

```swift
DotVoiceOrb(state: .speaking, audioLevel: normalizedLevel,
            configuration: VoiceOrbConfiguration(colors: DotTheme.orchid.colors))
    .frame(width: 160, height: 160)
```

Feed a normalized audio envelope in 0–1, preferably incoming speaker RMS for Dot speech. Change state from actual service activity. Invalid levels become zero. Sensitivity scales the input, with 80ms attack and 380ms release smoothing. Configure `colors`, `glowStrength`, `motionSpeed`, `deformationStrength`, `sensitivity`, `attack`, and `release`. The existing widget supplies its observed `voiceLevel`; the renderer never accesses the service itself.

The transparent Metal surface draws at 30fps, pauses when detached from a window, and renders statically with Reduce Motion. Use a square frame for a circular orb. Shader source is embedded to preserve the marketplace's source-only packaging contract.

Reference observations: filled violet circle with pale lavender below; a bright cloudy band moves across its center with fine wisps, a sharp circular edge, modest exterior glow, and continuous breathing. Representative 20–22s and thinking 40–42s moments show ongoing motion. The recording is nearly silent and visibly muted, so speech onset/sustained speech cannot be identified reliably. Audio-driven deformation and state transitions are inferred, configurable behavior rather than recovered original animation parameters.

Validation: universal widget compilation, standalone demo compilation, real GPU offscreen rendering in all six palettes, and existing widget regression suite. Render.swift produces transparent PNGs using the same embedded shader for comparison. This is a close recreation, not the original ChatGPT renderer.
