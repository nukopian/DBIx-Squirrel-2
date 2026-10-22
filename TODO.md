# To do

Work planned for a later session. CLAUDE.md's
[Planned work](CLAUDE.md#planned-work) has the rules: ask whether each
task should still be done, remove it in the commit that completes it, and
delete this file with the last one. It must be gone before a release.

## Read dbix-squirrel-v2, then archive it

**What:** read `~/Git/github.com/nukopian/dbix-squirrel-v2` in full: what
it changes from 1.6.5, which changes are syntax and which are design, and
what its last commit ("feat: interim commit") left half-done. Write the
findings into the plan doc. Then add a README note to dbix-squirrel-v2
pointing to DBIx-Squirrel-2, and archive it (`gh repo archive
nukopian/dbix-squirrel-v2 --yes`, with Iain's go-ahead).

**Why:** the plan doc's first session starts from what v2 already worked
out. Archiving it early avoids confusing dbix-squirrel-v2 with
DBIx-Squirrel-2.

**Done when:** the plan doc has the findings, and v2 is archived with
its note.

## Set up the distribution with Dist::Zilla

**What:** a `dist.ini` for DBIx-Squirrel: Perl 5.36 as the minimum, the
Perl 5 licence, and the repository and bug-tracker links naming the
final URL, `https://github.com/nukopian/DBIx-Squirrel`, not
DBIx-Squirrel-2 (see CLAUDE.md, The name). Decide with Iain whether to
commit the generated `Makefile.PL` and `cpanfile`, as 1.x did, so that
CI can test without installing Dist::Zilla.

**Why:** the Perl CI jobs and the first module need the distribution to
exist.

**Files:** `dist.ini`, and `Makefile.PL` and `cpanfile` if committed.

**Done when:** `dzil build` makes a distribution whose `META.json` names
the final URL and requires Perl 5.36, and `dzil test` passes.

## Add the Perl tests to CI

**What:** jobs in `.github/workflows/test.yml` that install the
dependencies and run the tests on Perl 5.36, 5.38, 5.40 and 5.42 on
Linux, and the newest Perl on macOS. Then add those jobs to `main`'s
required checks, beside `secrets`.

**Why:** CLAUDE.md promises CI from the floor to the newest Perl, and
1.x's matrix stopped at 5.24.

**Done when:** a push runs every job and they pass, and `gh api
repos/nukopian/DBIx-Squirrel-2/branches/main/protection --jq
.required_status_checks.contexts` lists them.

## Write docs/MAINTAINING.md

**What:** the maintainer's guide, as scalar's and grammar's are: branches,
every commit, making a release (Dist::Zilla, a signed tag, a GitHub
release and the CPAN upload), when something goes wrong, and the
cut-over to DBIx-Squirrel from the plan doc, with paste-ready commands.

**Why:** so a release, and the one-off cut-over, can be done from the
guide alone, even after a long gap.

**Done when:** each command in it has been run once, and CLAUDE.md links
to it.
