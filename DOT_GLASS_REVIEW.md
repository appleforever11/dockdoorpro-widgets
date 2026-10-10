# Dot Glass — local marketplace debut candidate

This package is prepared for review, with the remaining live acceptance checks explicitly listed below. It is not a published marketplace release or a claim of maintainer approval.

## Behavior

Dot Glass is independent of Codex Tracker. It provides a square, transparent dock orb, a glass conversation panel, six host-managed themes, real Dot messaging, confirmed read receipts, observed-session unread badges, opt-in native macOS notifications, and calls using ChatGPT’s actual Dot voice. AI voice calls are not telephone/PSTN calls.

The filled cloud orb recreates the supplied visual reference; it is an independent Metal renderer, not OpenAI’s original renderer. It accepts normalized incoming audio, smooths attack/release, pauses when detached, and supports Reduce Motion. Theme colors also apply to Dot replies; outgoing bubbles remain grey.

First-run setup explains the secure sign-in page and hands off automatically to glass when the rendered Dot composer is ready. A four-step glass tour demonstrates messaging, calling/mute, themes, and notifications without starting a call. It can be previewed before sign-in and revisited from Help.

Routine navigation, offline states, missing controls, expired sessions and WebKit termination retain the glass presentation and in-memory transcript/draft. Recovery is limited to three retries. Call starts time out after 20 seconds. Duplicate or uncertain sends are never automatically retried. Poll callbacks and microphone changes reject stale operations. A dropped call produces native guidance rather than exposing the web page or silently redialing.

Calls belong to the plugin, not the panel. An active-call sampling task ends with the call and continues when the panel hides. Idle updates use throttled host/panel timelines; there is no permanent main-run-loop Timer. Unread replies are sampled up to every three seconds while a host timeline or active call runs. This is not account-wide background push when DockDoor is quit or not rendering the widget.

## Settings and privacy

Appearance is read only through WidgetDefaults and declared in settingsSchema. The illustrated appearance popover is a live preview; saving uses DockDoor Settings → Stacks → Dot Glass because the current SDK has no supported setter. No widget code writes host settings keys or other apps’ configuration.

Notifications belong to DockDoor Pro, are optional, contain no message text, and coalesce under a widget-specific identifier. Clearing removes only this widget’s known notification. The dock badge reflects newly observed replies after the initial conversation snapshot. Read is shown only from explicit rendered read/seen evidence, never inferred from delivery or a generated response.

Standard persistent WebKit storage owns authentication. No cookie, token, credential or keychain extraction. The adapter reads rendered elements and operates existing Send/Call/Mute controls with origin and room checks; it makes no private API calls. Public inbound WebRTC metadata drives the orb. Microphone audio is not inspected or recorded. Fixed diagnostics omit conversations, credentials and audio content. Drafts and transcript survive session navigation/process recovery in memory; quitting the host is not durable draft storage.

## Packaging boundaries

- `dot-glass` is distinct from `dot-glass-personal`; personal build and updater are untouched.
- Widget folder contains only explicitly listed Swift source, widget.json and preview.png.
- Host-owned panel; no custom app window, helper, agent, subprocess, updater, private API, migration or global event monitor in shipped widget code.
- @Observable model; shared throttling prevents panel/dock sampling duplication.
- Both dock orientations and compact/extended sizes use SDK metrics.
- English semantic panel fonts, labelled controls, Cmd-Return send, selected theme accessibility state, reduced motion/transparency support.
- Developer/demo apps live outside Widgets and are not included in the marketplace bundle.
- Prior maintainer constraints from PRs #20/#21 and current CONTRIBUTING.md are respected. The marketplace PR is updated at the user’s request. No release, merge or Discord message has been sent.

## Validation and release gates

Automated local checks: universal arm64/x86_64 build; all 11 widget folders validate; URL/origin guards; rendered-page fixtures for messages, receipts, sending, duplicate prevention, microphone and missing controls; expired-session readiness; recovery exhaustion; hidden panel call ownership; stale voice/microphone state; private notification content by inspection; actual WebKit viewport fixtures; SDK bundle principal-class loading and all four slot layouts. Real GPU output in six palettes was compared with the supplied recording.

Offline UI inspection: actual rebuilt glass tour, four-step navigation, illustrated palette selection and semantic accessibility tree. Example captures are labelled offline examples; they contain no private conversations and do not prove a live call.

Prior user acceptance: two-way real Dot voice, hidden-panel continuation, mute/unmute, recovered glass chat, and the new filled orb. These checks predate this final stability patch.

Current installed-build acceptance: the user confirmed messaging/replies and start, mute/unmute, hide/reopen and end-call controls work.

Still required before release:

1. Explicit Read receipt, hidden-panel unread badge, badge clearing and native notification delivery/denial.
2. Repeated call cycles and a longer call; the basic current-build controls were user-verified.
3. Network loss/return and sleep/wake. Audio cannot continue during actual system sleep; verify useful recovery afterward.
4. Fresh-account sign-in and provider-specific authentication, without erasing the user's existing session.
5. Full VoiceOver keyboard walk and OS Reduce Motion/Reduce Transparency settings in DockDoor.
6. Maintainer acceptance of the rendered-page integration and host permissions. No approval guarantee is made.

Sign-in and deliberate Advanced inspection can show ChatGPT. Unknown web layouts degrade to native recovery guidance. Zero exposure to the sign-in web interface cannot be guaranteed with this integration.

## Installation and rollback

Use the upstream builder: `bash scripts/build-widgets.sh Widgets/DotGlass`. Run `bash scripts/test-dot-glass.sh`. Install via DockDoor’s normal widget installation flow. The local installed copy is ad-hoc signed; the universal review archive is the upstream unsigned builder output, not a notarized standalone app.

Local path: `/Users/kevinhowe/Library/Application Support/DockDoorPro/Widgets/DotGlass.bundle`.
Backup: `/Users/kevinhowe/Library/Application Support/DockDoorPro/WidgetBackups/DotGlass-before-debut-polish-20261010.bundle`.

The candidate has been pushed to the existing marketplace PR for maintainer review. It has not been merged, released through Sparkle, published to the marketplace or posted to Discord.
