# NAME

Test::SPDX::Coverage - Perl Test Harness to verify all matched files in Manifest have a SPDX-License-Identifier

# SYNOPSIS

    #File: t/spdx-coverage.t
    use Test::More;
    eval "use Test::SPDX::Coverage";
    plan skip_all => "Test::SPDX::Coverage required for testing SPDX-License-Identifier coverage" if $@;
    spdx_coverage_ok();

# DESCRIPTION

Test::SPDX::Coverage reads your manifest for .pm, .pl, .cgi files then searches for a SPDX-License-Identifier.  Once found, the License specified on the SPDX-License-Identifier line is extracted and verified against the [License::SPDX](https://metacpan.org/pod/License%3A%3ASPDX) database.

For Perl source code, the SPDX-License-Identifier must be formatted like this:

    # SPDX-License-Identifier: LICENSE

Examples:

    # SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later
    # SPDX-License-Identifier: MIT

Essentially, this is a wrapper around License::SPDX->new->check\_license($license\_string, {check\_type => "name"}) for all Perl files in your MANIFEST.

## EXPORT

### spdx\_coverage\_ok

    spdx_coverage_ok();
    spdx_coverage_ok({diag => 99}); #diag level 0-9
    spdx_coverage_ok({manifest => "MANIFEST", match=>qr/\.(?:pm|pl|cgi)\Z/, lines=>500, diag => 0}); #defaults 

# SEE ALSO

[License::SPDX](https://metacpan.org/pod/License%3A%3ASPDX)

# COPYRIGHT AND LICENSE

Copyright (C) 2026 by Michael Davis, Michal Josef Špaček

MIT
