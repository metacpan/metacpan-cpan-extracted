use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives >;

# This must be loaded after other modules that use open() in BEGIN
use Test::MockFile ();    # specifically not "strict" to trigger the issue

# This must be loaded after Test::MockFile so we override the core functions
# that will be used in File::Find when it compiles
use File::Find ();

ok(
    lives(
        sub {
            File::Find::find(
                {
                    'wanted' => sub { 1 }
                },
                '.',
            );
        }
    ),
    'Successfully handled bareword filehandles during runtime',
);

done_testing();
