# To do

Work planned for a later session. CLAUDE.md's
[Planned work](CLAUDE.md#planned-work) has the rules: ask whether each
task should still be done, remove it in the commit that completes it, and
delete this file with the last one. It must be gone before a release.

## Set up the distribution with Minilla

**What:** a Minilla distribution for DBIx-Squirrel (Iain chose Minilla
over Dist::Zilla on 2026-10-22, for being simpler to come back to):
`minil.toml`, a `cpanfile` with `requires 'perl', '5.036';` and the
dependencies, the Perl 5 licence, and the generated `Build.PL` and
`META.json` committed. Three things to settle from Minilla's own
documentation, not from memory:

- **The repository URL.** Minilla takes it from the git remote by
  default, which here would give DBIx-Squirrel-2. The metadata must
  name the final URL, `https://github.com/nukopian/DBIx-Squirrel`, and
  its issues (see CLAUDE.md, The name). Find how `minil.toml` overrides
  it.
- **The README.** Minilla writes `README.md` from the main module's POD,
  which would replace the hand-written GitHub README. Decide with Iain:
  keep the README hand-written (`readme_from`, or a separate file), or
  let the POD be the README, with `badges` for CI.
- **Releasing.** `minil release` commits, tags and uploads. Our releases
  move `main` by a fast-forward and sign the tag from `Changes`, so find
  how to keep the git steps ours (or make its tag signed) and let it
  build and upload.

**Why:** the Perl CI jobs and the first module need the distribution to
exist, and the release steps in docs/MAINTAINING.md depend on these
answers.

**Files:** `minil.toml`, `cpanfile`, `Build.PL`, `META.json`.

**Done when:** `minil build` makes a distribution whose `META.json`
names the final URL and requires Perl 5.036, `minil test` passes, and
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
