#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Debugbar::Monitor::Git' ) || print "Bail out!\n";
}

my $git = Mojo::Debugbar::Monitor::Git->new();
#my $git_info = $git->git_info('/Users/jon/repos/jontaylor/mojo-debugbar');
