# Chain replication protocol

TLA+ project proposed by Prof. Carla Ferreira (NOVA FCT) for DARE 2026

Implemented by João Brilha (also NOVA FCT)

## Assumptions

- The storage system is a single variable
- No failures occur
- Chain has size 2

## Behavior

- There are two types of requests:
  - Query requests (read): directed to the tail of the chain
  - Update requests (write): directed to the head of the chain
- The reply to every request is generated and sent by the tail
- State changes are forwarded along a reliable FIFO link to the next element of the chain

## Structure

`ChainReplication.tla` models the two nodes, Head and Tail, each with its own copy of the stored value, and the FIFO link between them.

### Properties

| Property             | Kind      | Says                                                             |
| -------------------- | --------- | ---------------------------------------------------------------- |
| `StrongConsistency`  | Invariant | Every query returns the value of the last update acked before it |
| `HeadIsLatest`       | Invariant | Head holds the newest update                                     |
| `TailIsAcked`        | Invariant | Tail holds the value of the last acked update                    |
| `LinkHasPending`     | Invariant | The link holds exactly the unacked updates, in order             |
| `EveryUpdateIsAcked` | Liveness  | Every update the head applies is eventually acked                |

### Specs

- `Spec`: the protocol, with weak fairness on `Forward`
- `NoFairSpec`: the protocol without fairness
- `BadSpec`: queries read at the head instead of the tail

## Configs

| Config                         | Checks                                                | Expected result                                  |
| ------------------------------ | ----------------------------------------------------- | ------------------------------------------------ |
| `ChainReplication.cfg`         | Invariants, with symmetry                             | Passes                                           |
| `ChainReplicationLive.cfg`     | Invariants and `EveryUpdateIsAcked`, without symmetry | Passes                                           |
| `ChainReplicationNoFair.cfg`   | `EveryUpdateIsAcked` without fairness                 | Fails: an update stays in the link forever       |
| `ChainReplicationBroken.cfg`   | `StrongConsistency` with queries at Head              | Fails in 2 steps: a query reads an unacked write |
| `ChainReplicationScale.cfg`    | Template for `scripts/scale.py`, without symmetry     | —                                                |
| `ChainReplicationScaleSym.cfg` | Template for `scripts/scale.py`, with symmetry        | —                                                |

Symmetry is only used with invariants, as TLC's symmetry reduction is unsound for liveness properties (per a comment in exercise `02_invariants`).

## Running

From the repository root, `scripts/tlc.sh` runs TLC and prints a summary table (similar to what VSCode prints out).
It expects `tla2tools.jar` on the `CLASSPATH`.

```sh
./scripts/tlc.sh ChainReplication.tla -config ChainReplicationLive.cfg
```

## Scaling experiment

`scripts/scale.py` runs TLC while sweeping one constant of a config, and writes `scale.csv` to `results/`.

```sh
python3 scripts/scale.py --spec ChainReplication.tla \
  --cfg ChainReplicationScale.cfg --cfg ChainReplicationScaleSym.cfg \
  --sweep MaxUpdates=1..40 --sweep MaxQueries=0..60 --sweep Values=1..15 \
  --timeout 120
```

It finds `java` on the `PATH`. It takes the jar from `CLASSPATH`, and falls back to the VSCode extension folder.

`scripts/plot.plt` draws the charts into `charts/` with gnuplot:

```sh
gnuplot scripts/plot.plt
```

TLC evaluates every constant definition at startup, including `Perms`, even when the config doesn't use symmetry. `Permutations(Values)` has `|Values|!` elements, so it inflates the observed timings of the `Values` sweep without symmetry.
Hence, that sweep was ran again with `Perms` commented out, into `results-values/`, which `plot.plt` reads from.

### Result summary

Base: 2 values, 3 updates, 2 queries, 120s timeout per model.

- **`MaxUpdates` grows exponentially**, about ×2.4 states per update. The limit is 15 updates (54.5 million states, 71 seconds), or 16 with symmetry.
- **`MaxQueries` and `Values` grow polynomially.** 60 queries give 5.6 million states in 43 seconds. 40 values give 2.2 million states in 3 seconds.
- **Symmetry** halves the state count with 2 values, and keeps it at 220 from 3 values on. Its cost grows with `|Values|!`, so 9 values time out.

These results are further discussed in the presenation.

## AI Usage

Claude Sonnet was used to:

1. Explain some TLA+ concepts and syntax
2. Create the helper scripts in `scripts/`
3. Validate the final implementation
