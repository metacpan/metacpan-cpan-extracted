=pod

Test the C<stash> method

=cut

use strict;
use Test::More tests => 5;

use re::engine::Plugin (
    comp => sub {
        my ($re) = @_;

        my $sv = [ qw< a o e u > ];

        $re->stash( $sv );
    },
    exec => sub {
        my ($re, $str) = @_;

        my $stash = $re->stash;
        my $ret = $re->stash( $stash );
        ok(!$ret, "stash returns no value on assignment");
        my %h = qw< 0 a 1 o 2 e 3 u >;
        for (keys %h) {
            is($h{$_}, $stash->[$_]);
        }
    }
);

"ook" =~ /eek/;
