use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Test::More tests => 3;

use_ok( 'Wx::Demo' );


my @warns;
my @plugins = Wx::Demo->load_plugins( sub { push @warns, @_ } );
is_deeply(\@warns, [], 'warnings during load_plugins')
    or diag Dumper \@warns;

#diag Dumper \@plugins;
is scalar(@plugins), 122, 'number of plugins'; # TODO should be set to the correct expected number

