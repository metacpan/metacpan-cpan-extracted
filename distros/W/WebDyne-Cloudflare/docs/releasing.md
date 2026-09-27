# Release and npm staging

The public release source is the
[GitHub repository](https://github.com/aspeer/pm-WebDyne-Cloudflare). Verify
that GitHub `main` contains the intended commit before dispatching its release
workflows.

For build and npm staging without creating release tags, run the release
workflow with `publish_release=false`, then stage using its `source_run_id`.

`npm run pack:check` verifies the exact public package allow-list. The
`WebDyne Cloudflare release` GitHub workflow runs the Perl and JavaScript
suites through MakeMaker, checks the source manifest, audits dependencies,
dry-runs npm publication, and creates an attested `.tgz` with a SHA-256/source
manifest. Run it on `main` with `publish_release=true` to create the matching
GitHub tag and Release.

Then run `WebDyne Cloudflare npm package` on the same `main` commit with either
the successful `source_run_id` or its `release_tag`. It verifies the package's
signed build provenance and source commit before staging the exact archive
on npm with provenance. It does not rebuild or replace an existing npm version.
The workflow pins npm 11.17.0 because staging requires npm 11.15.0 or newer.

Staging uses npm Trusted Publishing configured for
`aspeer/pm-WebDyne-Cloudflare`, workflow `webdyne-cloudflare-npm.yml`, with only
staged publishing allowed and no environment restriction. Direct publication
is disabled; there is no `NPM_TOKEN` fallback. In the npm package settings,
select "Require two-factor authentication and disallow tokens".

A successful workflow means "Awaiting MFA approval", not a public release.
Review the candidate in the npmjs.com Staged Packages tab and approve it with
MFA. Alternatively, from an authenticated local terminal:

```sh
npm stage list @webdyne/webdyne-cloudflare
npm stage view <stage-id>
npm stage approve <stage-id>
```

Replace `<stage-id>` with the reviewed candidate's ID. Compare the staged
archive against the qualified GitHub release before approval. After approval,
check the public version and compare `dist.integrity` with that archive:

```sh
npm view @webdyne/webdyne-cloudflare@<version> version dist.integrity --json
```

Approval remains a maintainer action and is never performed by this workflow.
Use a new npm version for changed contents. Never replace an already published
version or approve a candidate automatically. See the [npm staging guide](https://docs.npmjs.com/staged-publishing/).

See [TEST.md](../TEST.md) for qualification commands and limits.
