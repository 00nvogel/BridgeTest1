# Sanitizer Bridge — embedded package

This installation manages **exactly one internal ↔ customer pairing** inside the internal
GitHub repository. No separate bridge repository, projects directory, or project selector
is needed. It uses the same synchronization engine as the standalone multi-project package.

## Install

1. Copy `.sanitizer-bridge/` and `.github/workflows/sanitizer-bridge.yml` from this bundle
   into the internal repository. The package does not replace your root README or add
   unrelated workflows. Commit the installation on the repository's default branch.
2. Edit `.sanitizer-bridge/config.yaml`: select internal/customer branches, set the
   customer repository and an exact internal bootstrap commit, then set `enabled: true`.
   The internal repository is inferred from `GITHUB_REPOSITORY` in Actions; an explicit
   `internal.repository` can be used for local CLI execution. There is one configuration.
3. Add the two access-token secrets referenced by `secrets.internal` and `secrets.customer`.
   The internal token also writes synchronization metadata. Tokens need Contents read/write;
   Workflows write may be needed when publishing commits with workflow history. Temporary
   staging and import branches must be allowed by your repository rules.
4. Edit `.sanitizer-bridge/sanitization.sh` for project-specific whole-file exclusions.
   The engine always protects `.sanitizer-bridge` and `.github` from synchronization.
   The example additionally excludes `private` and `customer-private`.
5. Set `detection.polling` and `detection.notification` independently. Polling is scheduled
   at minutes 17 and 47 each hour. For notifications, install
   `.sanitizer-bridge/templates/customer-notify.yml` as `.github/workflows/bridge-notify.yml`
   in the **customer** repository. Set internal repository/ref and customer push branch;
   provide `BRIDGE_DISPATCH_TOKEN` there with Actions write access to the internal repository.
6. Run **Sanitizer bridge** in the internal repository with `operation: export` to export
   the latest configured internal head. There is no project input. Use `poll` for a manual
   customer check. A notification calls the same workflow with `operation: notification`.

An empty customer waits for explicit export. A populated customer can create an import
branch automatically. Imports use `sanitizer-bridge/import-N`; state lives on the separate
`sanitizer-bridge/state-v2` metadata branch. Internal main is never modified by imports.
Empty customer commits and excluded-only changes do not create import commits. Metadata
may record their observation on its separate branch.

Customer history loss suspends imports until the next successful explicit export, which
first preserves the current customer snapshot. Your team retains required internal commits;
if one is unavailable, the operation fails clearly. Pending commits are temporarily staged
in their destination repository and those staging references are cleaned after completion.
See [OPERATIONS.md](OPERATIONS.md) for the shared behavior, recovery steps and limitations.

## Local use and tests

Requires Linux, Python 3.12+, Git and Bash. From `.sanitizer-bridge/`:

```sh
python -m pip install -r requirements.txt
# Set GITHUB_REPOSITORY=owner/internal, INTERNAL_TOKEN and CUSTOMER_TOKEN for this process.
# INTERNAL_TOKEN also authenticates metadata writes; no separate bridge token is needed.
PYTHONPATH=engine python -m bridge import --embedded
PYTHONPATH=engine python -m bridge export --embedded
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=engine python -m unittest discover -s tests -v
```

For embedded CLI use the internal token supplies both metadata and internal writes.
`--project` and a separate `--bridge-url` destination are rejected. The bundled tests use
isolated local fixtures and cover both standalone and embedded protocol behavior.
