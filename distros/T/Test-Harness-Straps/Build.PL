#!/usr/bin/perl -w

use Module::Build;

print <<'END';
Test::Harness::Straps is provided for backwards compatibility only.
No further development is planned.  No bugs will be fixed.

For customizable TAP parsing please use L<TAP::Parser> instead.

END

sleep 2;

my $build = Module::Build->new(
    module_name     => 'Test::Harness::Straps',
    license         => 'perl',
    requires        => {
        'File::Spec'    => 0.6,
    },
    dist_author     => 'Michael G Schwern <schwern@pobox.com>',
    
    installdirs     => 'core',
);
$build->create_build_script;
