# Orbital Pioneer – Game Design Document

## 1  High‑Level Overview

| Item | Details |
| ---- | ------- |
|      |         |

|   |
| - |

| **Working Title**     | Orbital Pioneer                                                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Genre**             | 2‑D Physics Sandbox / Builder / Simulation                                                                                                                    |
| **Platform**          | **Picotron** fantasy console (480×270 px display; Lua‑like scripting)                                                                                         |
| **Target Audience**   | Players who enjoy creative sandbox engineering (Kerbal Space Program, Besiege) but want a bite‑sized, approachable experience on a fantasy console. Age 12 +. |
| **Core Fantasy**      | *Research, build, and fly your own rockets into a living 2‑D solar system.*                                                                                   |
| **Demo Scope (v0.1)** | • Tech research → • Buy parts → • Assemble rocket → • Launch → • Achieve orbit → • Transfer & land on the Moon                                                |
| **Future Expansions** | Prospecting mini‑game, ISRU, colonies on asteroids/planets, exotic engines, multiplayer race challenges                                                       |

---

## 2  Design Pillars

1. **Hands‑On Engineering** – Every part placed matters; success feels earned.
2. **Accessible Astrodynamics** – Real orbital mechanics simplified to 2‑D, always stable; players *see* why maneuvers work.
3. **Split‑Screen Situational Awareness** – Craft view + Trajectory map always visible.
4. **Room to Grow** – Systems designed to scale toward deeper resources and exploration loops.

---

## 3  Core Gameplay Loops

### 3.1 Research & Economy Loop

```
Missions → Funds & Science → Unlock parts → **Hold or Sell Patents** → Build better rockets → Harder missions
```

*Tech Tree* (v0.1): Command Pod → Liquid Engine Mk‑I → Fuel Tank S → Decoupler → Landing Leg → Parachute.

### 3.2 Construction Loop

1. Enter **VAB** (Vehicle Assembly Bay).
2. Drag‑drop parts on grid; snap & stack.
3. Assign staging order.
4. Validate mass/thrust/delta‑v vs. mission.

### 3.3 Flight Loop

1. **Launch** – Timed space‑bar taps build thrust; keep within 3° of pro‑grade to minimize losses.
2. **Ascent Guidance** – Split screen shows *Stage View* (left) & *Map View* (right) with live apoapsis/periapsis readouts.
3. **Orbit Circularization** – Burn at apoapsis until periapsis ≥ 70 km (edge of atmosphere surrogate).
4. **Lunar Transfer** – Time warp to transfer window; pro‑grade burn sets intercept.
5. **Landing** – Retro burn to cancel horizontal velocity, then throttle feather to soft‑land (≤ 5 m/s) on moon surface.
6. **Recovery** – Transmit science & reclaim funds.

### 3.4 Fundraising & Contracts Loop

1. **Accept Contract** – Browse available missions from various factions; receive an *advance payment* credited immediately.
2. **Fulfill Objectives** – Deliver the specified payload and meet orbital/mission parameters before the deadline.
3. **Outcome**
   - **Success** – Earn completion bonus money **and** *Influence +* with the issuing faction.
   - **Failure / Expired** – Repay advance **plus** 10 % penalty; Influence –; your account can go negative (debt accrues 25 % interest until cleared).
4. **Influence Meter** – Higher standing unlocks exclusive parts, larger budgets, and narrative contracts.

**Contract Archetypes (Demo)**

| Contract             | Issuer (Faction)    | Objective                                                  | Advance | Bonus                           |
| -------------------- | ------------------- | ---------------------------------------------------------- | ------- | ------------------------------- |
| Mass Comms Network   | Private Telecom     | Deploy 3 comm sats in 120°‑spaced equatorial orbits        | ¤8 000  | ¤12 000 + Telecom Influence ++  |
| Weather Scout        | Government          | Insert polar‑orbit weather satellite                       | ¤5 000  | ¤7 500 + Gov Influence +        |
| Deep‑Space Telescope | Research Consortium | Place telescope in high equatorial orbit & run calibration | ¤6 000  | ¤9 000 + Research Influence ++  |
| Recon Eye            | Military            | Launch 300 km retrograde spy satellite                     | ¤10 000 | ¤15 000 + Mil Influence ++      |
| Lunar Cargo Drop     | Colonial Authority  | Deliver 250 kg payload to Moon base                        | ¤12 000 | ¤18 000 + Colonial Influence ++ |

**Faction Benefits (Influence II)**

| Faction             | Theme                   | Perk                                     |
| ------------------- | ----------------------- | ---------------------------------------- |
| Government          | Earth‑science & climate | +5 % research speed                      |
| Military            | National security       | Unlock heat‑resistant spy‑sat parts      |
| Private Telecom     | Communications          | 10 % discount on antenna & battery parts |
| Research Consortium | Astronomy               | Access to advanced sensor suite          |
| Colonial Authority  | Lunar logistics         | Bulk fuel tank unlock                    |

*This loop feeds back into the ****Research & Economy Loop****, giving early‑game liquidity and long‑term reputational progression.*

### 3.5 Earth Market, Patents & Stock System

- **Free Earth Manufacturing** – Producing basic parts on Earth has no monetary cost; only launch‑related expenses apply.
- **Patent Sale Mechanic** – Unlocking a part grants a *patent* that can be **sold** at the Admin Office for immediate funds. Keeping the patent exclusive yields higher contract payouts but foregoes the lump‑sum cash.
- **Black‑Side Research** – Advanced components fabricated in micro‑gravity Refineries create *black‑side patents*. Returning at least one unit to Earth auto‑files the patent, which sells for ×5 the normal value.
- **Element Tags & Commodity Prices** – Every prospectable site is tagged with an elemental symbol (e.g., He‑3, Pt, Ir). Earth’s Commodity Exchange tracks spot prices that fluctuate based on total kilograms delivered globally.
  - Supply increases → gradual price decline.
  - Random demand spikes (events) can temporarily boost prices.
- **Gameplay Flow**: Prospect ⟶ Mine element ⟶ Refine part in‑situ ⟶ Return sample ⟶ Choose *Sell patent / Sell cargo* when market is favorable.
- **UI** – Price ticker and historical chart accessible in **Admin Office**; color‑coded arrows show daily movement.

*This system deepens long‑term progression, rewarding strategic timing and off‑world manufacturing.*

---

## 4  Mechanics Details (v0.1)

### 4.1 Physics Model

- **2‑D Two‑Body Patched‑Conic**: Each celestial body treated as primary when in SOI.
- **Integrator**: Semi‑implicit Euler with adaptive Δt; when *thrust = 0* and *drag = 0*, analytic Kepler step maintains position on conic section → orbit never decays.
- **Units**: Distance in pixels; 1 px ≈ 1 km. Time in seconds; simulation step ≤ 1/30 s.

### 4.2 Stability Guarantee

```lua
if thrust==0 and body==current.primary then
    -- Analytical_kepler_step(dt)
end
```

✓ No atmospheric drag modeled in space layer. ✓ No random perturbations (meteors, etc.) in v0.1.

### 4.3 Part Stats Schema

| Field      | Example      | Notes        |
| ---------- | ------------ | ------------ |
| `id`       | `engine_mk1` |              |
| `mass`     | 1.2 t        |              |
| `thrust`   | 120 kN       |              |
| `isp`      | 300 s        |              |
| `cost`     | ¤1 200       |              |
| `element`  | Fe           | Resource tag |
| `tech_lvl` | 1            |              |
| `tech_lvl` | 1            |              |

#### Component Categories (Core & Future)

| Category       | Core Role                                                                 | Example Abilities                                                                       |
| -------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **Thruster**   | Produce thrust for propulsion                                             | Chemical engines (baseline), **Missile** variant (dual-use; less efficient), Ion drives |
| **Reactor**    | Steady thermal / electrical power source                                  | Fission core powering deep‑space craft                                                  |
| **Generator**  | Convert fuel or reactor heat to electricity                               | Turbine generator, RTG                                                                  |
| **Radiator**   | Dissipate excess heat from reactors & high‑power systems                  | Deployable panel radiators                                                              |
| **Prospector** | Locate & analyze resources                                                | **Robonaut** EVA unit, **Buggy** rover (adjacent‑tile scan), **Ray‑Gun** orbital survey |
| **Refinery**   | In‑situ resource utilization; convert raw ore/ice into propellant & parts | Enables off‑world factories, automated launch/landing, repairs                          |

### 4.4 Split‑Screen Layout

- **Left 240×270** – *Stage View*: rocket, atmosphere backdrop, UI: throttle, staging icons.
- **Right 240×270** – *Map View*: draw orbital path (white), current position (dot), predicted trajectory (dashed), maneuver node gizmo.
- **Hot‑swap** key toggles enlarged Map for fine planning.

### 4.5 Controls (Keyboard & Mouse)

| Key       | Context | Action             |
| --------- | ------- | ------------------ |
| **Z/X**   | Build   | Rotate part CCW/CW |
| **C**     | Build   | Clone part         |
| **Space** | Flight  | Toggle next stage  |
| **↑/↓**   | Flight  | Throttle up/down   |
| **←/→**   | Flight  | Pitch left/right   |
| **Tab**   | Any     | Toggle UI overlay  |

#### Mouse Controls

| Mouse Action     | Context      | Result                      |
| ---------------- | ------------ | --------------------------- |
| **Left‑click**   | Any          | Select / confirm UI element |
| **Left‑drag**    | Build        | Drag part onto vessel grid  |
| **Right‑click**  | Build        | Rotate selected part 90° CW |
| **Scroll Wheel** | Map          | Zoom in/out trajectory view |
| **Left‑click**   | Space Center | Enter highlighted building  |

---

## 5  User Interface & UX

- Minimalistic pixel UI matching Picotron aesthetic.
- Color coding: Green = stable orbit; Orange = sub‑orbital; Grey = escape trajectory.
- Tooltips accessible with *Hold Shift* in VAB.
- Sound cues for stage separation, orbit achieved, landing success.

### 5.1 Space Center Hub

The Space Center acts as the **main navigation menu** that ties together every core loop. On Picotron’s 480 × 270 canvas, the top 20 px serves as a title bar while the remaining area renders a stylized side‑view campus with clickable building sprites (keyboard can cycle focus).

| Building               | Icon / Hotkey | Core Function                                             |
| ---------------------- | ------------- | --------------------------------------------------------- |
| VAB – Vehicle Assembly | 🏗 / **A**    | Design & build rockets, manage staging                    |
| Mission Control        | 🎯 / **M**    | Browse & accept contracts, monitor deadlines              |
| Research Lab           | 🔬 / **R**    | Spend science to unlock tech‑tree nodes                   |
| Tracking Station       | 📡 / **T**    | Review active flights, plan maneuvers, time‑warp          |
| Launch Pad             | 🚀 / **L**    | Roll out selected craft and start Flight Loop             |
| Admin Office           | 💼 / **F**    | Finances: take loans, repay debts, view faction influence |
| Hangar                 | 🛠 / **H**    | Save/load craft files, buy/sell spare parts               |

**UX Notes**

- Buildings glow softly when new actions are available (e.g., finished research, expiring contract).
- Navigation: **← / →** cycles focus dots beneath buildings; **Enter/Space** selects; **Esc** returns to hub.
- Short fade transition (0.3 s) when entering/exiting facilities to mask loading.
- Tooltips pop after 0.5 s hover or long‑press on mobile.
- Mouse: hover reveals building name; left‑click to enter building.

