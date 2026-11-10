# Flood Relief Planner

A classical AI planner written in **Common Lisp** that plans relief deliveries after a flood. Given a depot, a truck with limited capacity, a road network and villages that need supplies, it finds a sequence of actions (load, drive, unload) that delivers everything. It compares two search algorithms, breadth-first search (BFS) and A*, and includes a small web dashboard that calls the Lisp planner.

Built for CPP 4103 (Artificial Intelligence Programming) at KCA University. The map and road distances are illustrative, not real data.

## How it works

- **State:** a list of symbolic facts, for example `(at truck depot)`, `(at food depot)`, `(road depot village-a 4)`, `(needs village-a food)`.
- **Actions:** `load`, `drive` and `unload`. Each has preconditions and effects, and a cost (driving costs the road distance, loading and unloading cost 1). `applicable-p` checks an action and `apply-action` produces the next state.
- **Goal:** no `needs` facts remain.
- **BFS:** explores level by level, so it finds the plan with the fewest actions.
- **A\*:** orders states by cost so far plus a heuristic (the number of outstanding deliveries). Each outstanding delivery needs at least one unload costing 1, so the heuristic never overestimates and A* finds the cheapest plan.
- **Verification:** every plan is replayed from the start state (`verify-plan`) before it is reported.

## Scenarios and results

| Scenario | What it tests | BFS (actions / cost / expanded) | A* (actions / cost / expanded) |
|---|---|---|---|
| S1 Basic delivery | 2 supplies, 2 villages | 6 / 6 / 19 | 6 / 6 / 17 |
| S2 Truck capacity | 3 supplies, capacity 2, return trip | 11 / 11 / 76 | 11 / 11 / 76 |
| S3 Blocked road | A road is unavailable, so a detour is needed | 4 / 4 / 7 | 4 / 4 / 7 |
| S4 Larger network | More villages and supplies | 11 / 11 / 92 | 11 / 11 / 80 |
| S5 Unreachable village | No road reaches the destination | no plan / 4 | no plan / 4 |
| S6 Weighted roads | Fewest actions is not cheapest | 3 / 12 / 8 | 5 / 5 / 9 |

S6 shows the key difference: BFS takes the short but expensive road (3 actions, cost 12), while A* takes the longer cheap route (5 actions, cost 5). On S1 to S4 the simple heuristic prunes only a little, so A* explores about as many nodes as BFS. A stronger heuristic would be the next improvement.

## Run it

Requires [SBCL](https://www.sbcl.org/). Run everything from the project folder.

**Tests and all scenarios (terminal output):**

```
sbcl --load main.lisp --eval "(run-project)"
```

**Web dashboard:** also needs [Quicklisp](https://www.quicklisp.org/) (which installs Hunchentoot automatically).

```
sbcl --load server.lisp --eval "(start-server)"
```

Then open http://localhost:8080/ and choose a scenario and algorithm.

## Files

| File | Purpose |
|---|---|
| `actions.lisp` | State representation, action costs, applicable actions and their effects |
| `planner.lisp` | BFS, A*, heuristic, plan verification and timing |
| `scenarios.lisp` | The six test scenarios |
| `tests.lisp` | 14 automated tests |
| `main.lisp` | Runs the tests and all scenarios from the terminal |
| `server.lisp` | Hunchentoot web server and JSON API (`/run?scenario=N&algorithm=bfs|astar|both`) |
| `public/` | Web dashboard (`index.html`, `style.css`, `script.js`) |

## Limitations

One truck, one road network, no uncertainty or live data, and a simple heuristic. Ideas for later: several trucks, supply quantities, road closures over time and a distance-based heuristic.

## Credits

Group project by Njuguna Juliet, Mark Collins, Ouma Rose Achieng and Keith Walter Odeny (CPP 4103, KCA University). The planner, scenarios, tests, dashboard and documentation are the group's work. The portable server setup, the averaged timing in `server.lisp` and the README were prepared with help from Claude (Anthropic).
