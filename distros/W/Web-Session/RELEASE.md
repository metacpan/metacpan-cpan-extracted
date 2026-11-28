# Release process

Publication is automatic: pushing a `vX.Y.Z` tag on a commit of `master`
builds, tests and publishes the release (GitHub release with the CPAN
distribution and the Debian package, then CPAN after approval). Making a
release therefore means: a release pull request, then a tag on `master`.

## 1. Release pull request

From an up-to-date `master`, create a branch (for example `release-X.Y.Z`)
and:

- set the new version in `dist_version` of `Build.PL`, the `$VERSION` of
  every module and `real_version` of `rpm/perl-Web-Session.spec`:

  ```
  OLD=1.0.0 NEW=1.0.1
  perl -pi -e "s/'\Q$OLD\E'/'$NEW'/ if /\\\$VERSION|dist_version/" \
      Build.PL $(git ls-files 'lib/*.pm')
  perl -pi -e "s/^(%define real_version ).*/\${1}$NEW/" rpm/perl-Web-Session.spec
  ```

- add the new version as the first entry of `Changes`: the user-visible
  changes since the previous release, for administrators. This entry is also
  the text of the GitHub release;

- check the versions:

  ```
  perl .github/check-version.pl vX.Y.Z
  ```

Open the pull request. Its CI checks the versions, runs the tests against the
database servers and builds the Debian package. Merge it once it passes.

## 2. Tag

Tag the merge commit of the release pull request, on `master`, and push the
tag:

```
git fetch origin
git tag -a vX.Y.Z -m "Web::Session X.Y.Z" origin/master
git push origin vX.Y.Z
```

Tag `master` after the merge, not the branch of the pull request: the release
workflow refuses a tag whose commit is not on `master`, and the published code
is then exactly the code tested by the CI of `master`. Only the maintainer can
push `v*` tags (repository ruleset).

## 3. Publication (automatic)

The `Release` workflow then:

1. checks that the tag matches the versions and the first entry of `Changes`,
   and that the tagged commit is on `master`;
2. builds and tests the distribution `Web-Session-X.Y.Z.tar.gz`;
3. builds the Debian package `libweb-session-perl_X.Y.Z-1_all.deb` (Debian
   trixie, `dh-make-perl`, see `.github/build-deb.sh`);
4. creates the GitHub release vX.Y.Z with both files as assets (LemonLDAP::NG
   Docker images install the package from there);
5. uploads the distribution to CPAN once a reviewer approves the deployment
   to the `cpan` environment (Actions tab, "Review deployments").

## If the release fails

Before the GitHub release is created, nothing is published: delete the tag,
fix (with a new pull request) and tag again:

```
git tag -d vX.Y.Z
git push origin :vX.Y.Z
```

Once the GitHub release exists, delete it on GitHub before tagging again. A
CPAN upload can't be redone: PAUSE refuses a file name already uploaded, so
re-running the workflow after a successful upload fails at the last step;
publish a new version instead.

## One-time setup

- A `cpan` environment (Settings > Environments) with required reviewers,
  limited to the `v*` tags, holding the `PAUSE_USERNAME` and `PAUSE_PASSWORD`
  secrets.
- PAUSE permissions on the `Web::Session` namespace for this account.
- Rulesets: `v*` tags and `master` updates restricted to the maintainer,
  `master` only through pull requests.
