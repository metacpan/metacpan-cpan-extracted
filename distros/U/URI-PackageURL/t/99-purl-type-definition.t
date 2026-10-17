#!perl

use File::Spec;
use JSON::PP;
use Test::More;
use File::Find qw(find);

require_ok('URI::PackageURL');
require_ok('URI::PackageURL::Type');
require_ok('URI::PackageURL::Util');


my @PURL_TYPES      = URI::PackageURL::Util::purl_types();
my @PURL_COMPONENTS = ('name', 'namespace', 'version', 'subpath', 'qualifiers');

foreach my $type (@PURL_TYPES) {

    if (my $purl_type = $ENV{PURL_TYPE}) {
        next unless ($purl_type eq $type);
        diag "Test only $ENV{PURL_TYPE} testcases";
    }

    my $t = URI::PackageURL::Type->new($type);

    subtest "$type - component requirement" => sub {

        foreach my $component (@PURL_COMPONENTS) {

            unless ($t->component_have_definition($component)) {
                note "(!) No '$component' component in definition";
                next;
            }

            my $requirement = $t->component_requirement($component);
            like $requirement, qr/(required|optional|prohibited)/,
                "'$component' component requirement --> $requirement";
        }

    };

    subtest "$type - scheme" => sub {

        eval { $t->validate(type => $type) };
        unlike $@, qr/is not a valid scheme/, 'default "pkg" scheme';

        eval { $t->validate(scheme => 'foo', type => $type) };
        like $@, qr/'foo' is not a valid scheme/, 'invalid scheme';

    };

    if ($ENV{PURL_EXAMPLES_TESTING}) {

        my $examples = $t->examples;

        subtest "$type - examples" => sub {

            my $id = 1;

            foreach my $example (@{$examples}) {
                my $purl = eval { URI::PackageURL->from_string($example) };

                if ($@) {
                    fail("Invalid PURL type: $@");
                }
                else {
                    is $purl->to_string, $example, "Test example #$id";
                }

                $id++;
            }
        };

    }
}

done_testing();
