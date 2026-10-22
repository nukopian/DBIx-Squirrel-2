# To do

Work planned for a later session. CLAUDE.md's
[Planned work](CLAUDE.md#planned-work) has the rules: ask whether each
task should still be done, remove it in the commit that completes it, and
delete this file with the last one. It must be gone before a release.

## Write docs/MAINTAINING.md

**What:** the maintainer's guide, as scalar's and grammar's are: branches,
every commit, making a release (Minilla, a signed tag, a GitHub
release and the CPAN upload), when something goes wrong, and the
cut-over to DBIx-Squirrel from the plan doc, with paste-ready commands.
A release uses `minil prepare VERSION` and `minil dist --skip-prepare`,
never `minil release` (CLAUDE.md, Perl, says why), and uploads with
`cpan-upload`, from CPAN::Uploader, which isn't installed yet: ask Iain
before installing it.
Include changing the CI matrix: `main` requires each job by name, as
`perl 5.42 (macos-26)`, so a new Perl or runner means updating the
required checks, or `main` waits on a check that never reports.

**Why:** so a release, and the one-off cut-over, can be done from the
guide alone, even after a long gap.

**Done when:** each command in it has been run once, and CLAUDE.md links
to it.
