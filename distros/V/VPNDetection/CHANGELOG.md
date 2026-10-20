# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 3.3.2 are described by their release commits.

## 3.9.0 - 2026-10-20

### Features

- Add oauth->register, for RFC 7591 dynamic client registration ([`1248cc4`](https://github.com/vpndetection-io/sdk-perl/commit/1248cc46329a0f2afea4531e97025e8ee546de6d))

## 3.8.1 - 2026-10-20

### Fixes

- Refuse an answer, a key or a Retry-After the spec does not allow ([`c60e555`](https://github.com/vpndetection-io/sdk-perl/commit/c60e555db3b8a48bb85d25f62ad594744f410e59))
- Keep credentials off command lines, and check the tarball CPAN serves ([`782f676`](https://github.com/vpndetection-io/sdk-perl/commit/782f676ecfc367c1971dc554878a8688f5a7b23b))

## 3.8.0 - 2026-10-19

### Features

- Re-pin the spec to 2026.10.19: num_ports and num_proxies in the pubproxy detail ([`ac7ce7c`](https://github.com/vpndetection-io/sdk-perl/commit/ac7ce7cfa8596ddbc817651200538c638fb4d83e))

## 3.7.0 - 2026-10-18

### Features

- Re-pin the spec to 2026.10.18: is_pubproxy and the pubproxy detail ([`93384fc`](https://github.com/vpndetection-io/sdk-perl/commit/93384fc65950d2f8fa8afb59dff03be605a2aabe))

## 3.6.0 - 2026-10-17

### Features

- Re-pin the spec to 2026.10.16: dynamic client registration ([`9875fa0`](https://github.com/vpndetection-io/sdk-perl/commit/9875fa07b2d77d88948c4ffbd523d51abc457f02))

## 3.5.5 - 2026-10-16

### Fixes

- Re-pin the spec to 2026.10.15: descriptions in US spelling ([`a76a981`](https://github.com/vpndetection-io/sdk-perl/commit/a76a98105739a64bb1890188deffe535b01cb6e4))

## 3.5.4 - 2026-10-15

### Fixes

- Retry an unreadable answer to OAuth discovery and device authorization ([`dfde9e2`](https://github.com/vpndetection-io/sdk-perl/commit/dfde9e266170aa081367cb80d1b48ed57680cd0d))

## 3.5.3 - 2026-10-10

### Fixes

- Re-pin the spec to 2026.10.09: rotating a key needs apikeys.reveal ([`891a1d3`](https://github.com/vpndetection-io/sdk-perl/commit/891a1d3fd1cfff847194508f3c68811a6b93b2cd))

## 3.5.2 - 2026-10-06

### Fixes

- Raise a database answer missing what the call returns as server_error ([`4013055`](https://github.com/vpndetection-io/sdk-perl/commit/40130559d6313d9582149e5e12e308c3d1c6c4fb))

## 3.5.1 - 2026-10-04

### Fixes

- Re-pin the spec to 2026.10.03: metadata needs no license ([`746bb99`](https://github.com/vpndetection-io/sdk-perl/commit/746bb99aaeb4d35065959152b4698d3ea917f478))

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
