# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 3.3.2 are described by their release commits.

## 3.5.0 - 2026-10-03

### Features

- Add the authorization code sign-in, with PKCE ([`8fd7644`](https://github.com/vpndetection-io/sdk-perl/commit/8fd76443a1f1b19462517e934267d5418499f314))

## 3.4.1 - 2026-09-29

### Fixes

- Judge an IPv4-mapped address as the IPv4 address it carries ([`6b3f88e`](https://github.com/vpndetection-io/sdk-perl/commit/6b3f88eb7a184d153c4be494415eb08c162ff770))
- Treat a timeout written as a string zero as no bound, as 0 is ([`553b657`](https://github.com/vpndetection-io/sdk-perl/commit/553b657218edc979a8bad180b06aaf6d70b9bb5d))
- Recognize 26 more reserved ranges as bogons, as the API does ([`9f13904`](https://github.com/vpndetection-io/sdk-perl/commit/9f139040f8274b08af84931fd96338ecdcaa644f))

## 3.4.0 - 2026-09-27

### Features

- Re-pin the spec to 2026.09.26, adding client_id_metadata_document_supported ([`a5ad6c1`](https://github.com/vpndetection-io/sdk-perl/commit/a5ad6c12635dbecff6e45cc58df384fbfc411d70))

## 3.3.3 - 2026-09-26

### Fixes

- Share one request per address between concurrent misses ([`88773d9`](https://github.com/vpndetection-io/sdk-perl/commit/88773d911eb347899cc2c262acb1f2d10497c89a))

## 3.3.2 - 2026-09-23

### Fixes

- Back off between retries, and end the poll's sleep at its deadline ([`f54f147`](https://github.com/vpndetection-io/sdk-perl/commit/f54f147bfd1abef3c3eb812c56b9500d6eb246dd))
