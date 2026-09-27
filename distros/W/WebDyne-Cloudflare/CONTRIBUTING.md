# Contributing to WebDyne::Cloudflare

Bug reports and focused contributions are welcome. Search the
[GitHub issues](https://github.com/aspeer/pm-WebDyne-Cloudflare/issues) before
opening a new one, and include a minimal reproduction where possible.

Fork the [GitHub repository](https://github.com/aspeer/pm-WebDyne-Cloudflare),
create a topic branch, keep changes focused, and submit a GitHub pull request.
Run the Perl and JavaScript tests before submitting:

```sh
npm ci
npm test
npm run pack:check
```

Changes to a service binding should include focused Perl and JavaScript tests.
Update the corresponding Markdown sidecar and runnable example when public
behavior changes. Do not publish packages, create releases, or use production
Cloudflare resources as part of a contribution.

Do not include credentials or private data. Report potential vulnerabilities
privately as described in [SECURITY.md](SECURITY.md).
