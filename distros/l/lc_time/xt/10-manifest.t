#! perl -w
use v5.10;
use strict;

use Test::More;
Test::Manifest->import('package_manifest_ok');

package_manifest_ok();

done_testing();

BEGIN {
    package Test::Manifest;
    use warnings;
    use strict;

    use ExtUtils::Manifest qw/fullcheck maniread/;
    use base 'Test::Builder::Module';
    use Exporter 'import';
    our @EXPORT = qw/package_manifest_ok/;

    my $tb = __PACKAGE__->builder;

    sub package_manifest_ok {
        my ($msg) = @_;
        $msg //= "MANIFEST up to date";

        local $ExtUtils::Manifest::Quiet = $ENV{TEST_VERBOSE} ? 0 : 1;
        my ($missing, $extra) = fullcheck();

        my $nok = 0;
        if (@$missing) {
            $tb->diag("The following files are missing:");
            $tb->diag("    $_") for @$missing;
            $nok = 1;
        }
        if (@$extra) {
            $tb->diag("MANIFEST did not declare the following files:");
            $tb->diag("    $_") for @$extra;
            $nok = 1;
        }

        if ($nok) {
            $tb->ok(0, $msg);
            $tb->BAIL_OUT("Fix MANIFEST first.");
        }
        else {
            $tb->ok(1, $msg);
        }

        my $manifest = maniread();
        return sort keys %$manifest;
    }
    1;
}
