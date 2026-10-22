# To do

Work planned for a later session. CLAUDE.md's
[Planned work](CLAUDE.md#planned-work) has the rules: ask whether each
task should still be done, remove it in the commit that completes it, and
delete this file with the last one. It must be gone before a release.

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
A release uses `minil prepare VERSION` and `minil dist --skip-prepare`,
never `minil release` (CLAUDE.md, Perl, says why), and uploads with
`cpan-upload`, from CPAN::Uploader, which isn't installed yet: ask Iain
before installing it.

**Why:** so a release, and the one-off cut-over, can be done from the
guide alone, even after a long gap.

**Done when:** each command in it has been run once, and CLAUDE.md links
to it.
