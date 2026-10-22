# To do

Work planned for a later session. CLAUDE.md's
[Planned work](CLAUDE.md#planned-work) has the rules: ask whether each
task should still be done, remove it in the commit that completes it, and
delete this file with the last one. It must be gone before a release.

## Set up the distribution with Minilla

**Waiting for Iain's first module,** `lib/DBIx/Squirrel.pm`, with a
`$VERSION` and POD giving its NAME (the abstract), AUTHOR and LICENSE:
Minilla can't build without it, and Iain writes the code.

**Done on 2026-10-22:** `minil.toml`, `cpanfile` and `README.pod`, with
the three questions settled from Minilla 3.3.2's documentation and
source (CLAUDE.md, Perl and The name, has the decisions):

- **The repository URL** comes from the git remote, and can't be
  overridden: `[Metadata]` is applied first, then the remote overwrites
  `resources`. So `META.json` names DBIx-Squirrel-2 until the cut-over
  renames the repository.
- **The README** is written by hand in `README.pod` (`readme_from`),
  and Minilla generates `README.md` from it, adding the CI badge.
- **Releasing** uses `minil prepare VERSION` and `minil dist
  --skip-prepare`, never `minil release`, which commits, makes an
  unsigned tag and pushes. Uploading needs `cpan-upload`, from
  CPAN::Uploader, which isn't installed: ask Iain before installing it,
  in the MAINTAINING.md task.

**What's left:** once the module is there, `minil build` generates
`Build.PL`, `META.json` and `README.md`; commit them, and check the
generated `README.md` differs from the committed one only by the badge.

**Why:** the Perl CI jobs need the distribution to exist, and the
release steps in docs/MAINTAINING.md depend on it.

**Files:** `Build.PL`, `META.json`, `README.md` (generated).

**Done when:** `minil build` makes a distribution whose `META.json`
requires Perl 5.036, `minil test` passes, and
in a fresh library without Minilla installed (a throwaway
`cpanm -L` directory), `cpanm --installdeps --with-develop .` then
`yath test` passes, and so does `prove -lr t`, which is what CPAN
installers effectively run. The `cpanfile` lists Test2::V0 and
Test2::Plugin::NoWarnings under `on test`, and Test2::Harness,
Perl::Critic, Perl::Tidy and Data::Dump under `on develop`.

## Add the Perl tests to CI

**What:** jobs in `.github/workflows/test.yml` that install the
dependencies (`cpanm --installdeps --with-develop .`, so yath comes
too) and run the tests with `yath test` on Perl 5.36, 5.38, 5.40 and
5.42 on Linux, and the newest Perl on macOS. Add a style job on the
newest Perl: `perlcritic lib`, and a check that `perltidy` would change
nothing. Then add those jobs to `main`'s
required checks, beside `secrets`.

**Why:** CLAUDE.md promises CI from the floor to the newest Perl, and
1.x's matrix stopped at 5.24.

**Done when:** a push runs every job and they pass, and `gh api
repos/nukopian/DBIx-Squirrel-2/branches/main/protection --jq
.required_status_checks.contexts` lists them.

## Write docs/MAINTAINING.md

**What:** the maintainer's guide, as scalar's and grammar's are: branches,
every commit, making a release (Minilla, a signed tag, a GitHub
release and the CPAN upload), when something goes wrong, and the
cut-over to DBIx-Squirrel from the plan doc, with paste-ready commands.

**Why:** so a release, and the one-off cut-over, can be done from the
guide alone, even after a long gap.

**Done when:** each command in it has been run once, and CLAUDE.md links
to it.
