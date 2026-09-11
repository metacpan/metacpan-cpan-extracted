# eBay::Client::OpenAPI3

`eBay::Client::OpenAPI3` is a small Perl client for selected eBay REST APIs,
with the `ebayapi3` command-line utility used by existing applications.

The 0.01 CPAN packaging pass is intentionally compatibility-first: it adds
release metadata, tests, CI, and clearer documentation without changing the
existing CLI output or pagination semantics.

## Configuration

By default `ebayapi3` uses `$HOME/.ebayapi3.conf`:

```ini
[eBay]
client_id = your-client-key
client_secret = your-secret-key
affiliateCampaignId = your-epn-campaign-id
affiliateReferenceId = optional-reference
```

The module constructor accepts the configuration filename explicitly.  The CLI
also accepts `--config FILE` on API subcommands; this makes the option already
documented by the pre-CPAN project functional without changing the default.

## Existing CLI behavior retained in 0.01

```sh
# Bare application token (also the default command when no subcommand is given)
ebayapi3 oauth2

# Browse a category; default output is JSON
ebayapi3 browse --limit 200 --category_ids 66502 --stats --as json

# Follow pagination.  Existing behavior writes each JSON response consecutively;
# 0.01 deliberately does not wrap them into a new array.
ebayapi3 browse --limit 200 --category_ids 66502 --stats --as json --continue > data-dump.json

# YAML remains useful for a naturally document-oriented continued stream.
ebayapi3 browse --limit 200 --category_ids 66502 --as yaml --continue > data-dump.yaml

# Retrieve one item
ebayapi3 item --itemid 123456789012 --as summary

# Browse API rate-limit information
ebayapi3 rate --as summary
```

`--nextcmd`, the default AUCTION filter, `--max` handling, output formatting,
and the historical help exit status are covered by compatibility tests.

## Perl API

```perl
use eBay::Client::OpenAPI3;

my $ebay = eBay::Client::OpenAPI3->new(
    config => "$ENV{HOME}/.ebayapi3.conf",
);

my $results = $ebay->oauth2->browse(
    category_ids => 66502,
    limit        => 200,
    sort         => 'endingSoonest',
);
```

The original `getItem()` spelling remains supported.  `get_item()` is an
additive alias for Perl-style callers.

## Testing

The tests are designed to be offline and must not require live eBay credentials:

```sh
cpanm --notest --installdeps .
prove -lr t
```

For development coverage:

```sh
cover -delete
PERL5OPT=-MDevel::Cover prove -lr t
cover -report text
```

GitHub Actions installs dependencies and runs `prove` directly.  It does not use
Dist::Zilla.

## Local/manual release

`dist.ini` is provided only for local/manual release work:

```sh
dzil test
dzil build
dzil release
```

After the initial release, the next development pass can inventory missing eBay
API support and then work toward 100% statement/branch/condition/subroutine test
coverage without changing behavior merely to satisfy a coverage number.
