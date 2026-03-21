use strict;
use warnings;
use Test::More tests => 8;
use YAML::Syck;

# strtok() returns NULL for the type component when a YAML tag contains
# no "/" or ":" delimiter (e.g. "!perl" with no subtype).  The scalar
# ref handler passed the NULL type to newSVpv() without checking.
# The form() calls in the blessing code also passed NULL type as an
# unused variadic argument.

# Test 1-2: tag with no type component + ref-literal content "="
# The "=" prefix is REF_LITERAL — triggers the scalar-ref code path
{
    my $yaml = "--- !perl =\n";
    my $result = eval { YAML::Syck::Load($yaml) };
    ok(!$@, "Load tag with no type + ref-literal content doesn't crash")
        or diag "Error: $@";
    is($result, '=', "falls back to raw scalar content when type is NULL");
}

# Test 3-4: custom (non-perl) tag with no type delimiter
{
    my $yaml = "--- !custom =\n";
    my $result = eval { YAML::Syck::Load($yaml) };
    ok(!$@, "Load custom tag with no type + ref-literal doesn't crash")
        or diag "Error: $@";
    # With no type, custom lang produces just the lang name as the SV
    is($result, 'custom', "custom lang with no type returns lang name");
}

# Test 5-6: tags with type component still work correctly
{
    my $yaml = "--- !perl/ref =\n";
    my $result = eval { YAML::Syck::Load($yaml) };
    ok(!$@, "Load perl/ref with ref-literal works");
    is($result, 'ref', "perl/ref returns type name");
}

# Test 7-8: custom lang with type
{
    my $yaml = "--- !custom/type =\n";
    my $result = eval { YAML::Syck::Load($yaml) };
    ok(!$@, "Load custom/type with ref-literal works");
    is($result, 'custom::type', "custom/type returns lang::type");
}
