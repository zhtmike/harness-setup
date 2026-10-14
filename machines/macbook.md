# MacBook — machine profile

Local dev frontend to remote GPU servers.

## Environment Constraints

- **macOS local dev only — no testing happens here.** All tests run on remote servers. The local Python environment is not fully provisioned.
- **Never search conda envs.** Do not grep, find, or read files inside `~/.conda/`, `~/miniconda*/`, or any conda-managed directories.
- **~/gitlocal for dependency sources.** When you need to inspect a package, library, or module's internals, check `~/gitlocal/<name>` first — not site-packages or conda envs. When doing a code search for a library or dependency, always `ls ~/gitlocal` first to see if the source is already cloned locally. Only fall back to network/web search if the relevant code is **not** found in `~/gitlocal/`.
- **No heavy local computation.** Do not attempt to train, benchmark, or run compute-intensive work on this machine.
