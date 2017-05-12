use Test::More tests => 1 + 1;
BEGIN {
    use_ok('Text::Outdent', qw/
        expand_leading_tabs
    /);
}

###############################################################################

use strict;

sub f { my ($str) = @_; $str =~ tr/./ /; return $str }
sub g { my ($str) = @_; $str =~ tr/ /./; return $str }

my $tabs = <<"_TABS_";
\tthis
\t
\t.....\tis\t
...\t\ta
string\t
..\t.\tthat
\t
_TABS_

my $spaces = <<"_SPACES_";
........this
........
................is\t
................a
string\t
................that
........
_SPACES_

is(g(expand_leading_tabs(8, f($tabs))), g(f($spaces)));
