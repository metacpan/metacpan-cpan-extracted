# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff. Releases before 3.3.2 are described by their release commits.

## 3.14.0 - 2026-11-14

### Features

- Re-pin the spec to 2026.11.14: is_bogon on every answer, and provider_name beside each provider ([`3d970a5`](https://github.com/vpndetection-io/sdk-perl/commit/3d970a57d4af0655e8a793f94c8c245c1a6e1f61))

## 3.13.2 - 2026-11-13

### Fixes

- Read a served null flag or trial_expired as undef, never 0 ([`0c2100d`](https://github.com/vpndetection-io/sdk-perl/commit/0c2100da57e7daaefbdec5623c1dcf627c4dcefc))
- Re-pin the spec to 2026.11.12: plainer words on the 401 and the batch rate limit ([`2eefa6e`](https://github.com/vpndetection-io/sdk-perl/commit/2eefa6e21398eafec1aaebf0c6d5ff053d66065b))
- Say that a batch request of one address is answered as its lookup ([`2e99c67`](https://github.com/vpndetection-io/sdk-perl/commit/2e99c67135a9d8d78ffe9bac9f8a91c65877aceb))

## 3.13.1 - 2026-11-11

### Fixes

- Say the free plan's daily trial and Unlimited, the free plan, and re-pin the spec ([`913a201`](https://github.com/vpndetection-io/sdk-perl/commit/913a2015f7f113217906aa8b0ef01b6e78589a80))

## 3.13.0 - 2026-11-11

### Features

- Add trial_expired for a trial key's answers, and re-pin the spec ([`726bf3e`](https://github.com/vpndetection-io/sdk-perl/commit/726bf3e86903a48bfab49c4afeaa6f30ffa335c5))

## 3.12.2 - 2026-11-11

### Fixes

- Name the Unlimited tier and its terms, and re-pin the spec ([`bbc1056`](https://github.com/vpndetection-io/sdk-perl/commit/bbc1056ba07626b4dbc464747356d198eb4cfe7e))

## 3.12.1 - 2026-11-11

### Fixes

- Re-pin the spec's 2026.11.11 rebuild: plainer words on lookups without a key ([`d8e0427`](https://github.com/vpndetection-io/sdk-perl/commit/d8e0427a42cd22b651b75e9d724e27e0015a17a6))

## 3.12.0 - 2026-11-11

### Features

- Re-pin the spec to 2026.11.11: a lookup without a key answers more ([`b2a1f78`](https://github.com/vpndetection-io/sdk-perl/commit/b2a1f78ae59f0b636463bf54fb7318bc5506304a))

## 3.11.1 - 2026-11-09

### Fixes

- Say how far a short transfer got under Mojolicious 9.54 too ([`9a51c6f`](https://github.com/vpndetection-io/sdk-perl/commit/9a51c6f5e0f6c1a31f7360ca4a640633596f90c6))
- Re-pin the spec to 2026.11.08: plainer endpoint descriptions ([`253acfc`](https://github.com/vpndetection-io/sdk-perl/commit/253acfc71d022152565f04054591c37da77f3aeb))

## 3.11.0 - 2026-11-07

### Features

- Download the build a database.updated webhook names ([`5cc9d6e`](https://github.com/vpndetection-io/sdk-perl/commit/5cc9d6e58cebea3c07a658c83eb3316c0554de67))

### Fixes

- Re-pin the spec to 2026.11.05: the download's build parameter ([`f7b0582`](https://github.com/vpndetection-io/sdk-perl/commit/f7b05829b93452a3f022aba1f9164cd6afe7cdae))

## 3.10.3 - 2026-11-05

### Fixes

- End a device poll once its wait runs to the deadline, NaN included ([`b0cc83c`](https://github.com/vpndetection-io/sdk-perl/commit/b0cc83c739abadc89ffca096ce6b458fbc17333d))

## 3.10.2 - 2026-11-01

### Fixes

- Refuse a bad retries or concurrency, or a key past U+00FF ([`bc73fac`](https://github.com/vpndetection-io/sdk-perl/commit/bc73fac379ce5e33ee5db5e21af708c8ffe846fb))
- Refuse a date or date-time member that is not RFC 3339 ([`3d2839f`](https://github.com/vpndetection-io/sdk-perl/commit/3d2839f97975408cce89429147dabbeff938f6ce))

## 3.10.1 - 2026-10-26

### Fixes

- Re-pin the spec to 2026.10.25: Retry-After on myip's 429 ([`b2e3199`](https://github.com/vpndetection-io/sdk-perl/commit/b2e3199a4209a2656e7e1b48072845e2ac7aad04))

## 3.10.0 - 2026-10-20

### Features

- Add location and asn to lookup results, a bogon's included ([`0b5c2b6`](https://github.com/vpndetection-io/sdk-perl/commit/0b5c2b67935a7a8a3d91ac7e97b269fb4e324366))

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
