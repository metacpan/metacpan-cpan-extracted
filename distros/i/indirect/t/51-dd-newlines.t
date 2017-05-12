#!perl

use lib 't/lib';
use VPIT::TestHelpers;

BEGIN {
 load_or_skip_all("Devel::Declare", 0.006007, undef);
}

use Test::More tests => 1;

sub foo { }

sub foo_magic {
 my($declarator, $offset) = @_;
 $offset += Devel::Declare::toke_move_past_token($offset);
 my $linestr = Devel::Declare::get_linestr();
 substr $linestr, $offset, 0, "\n\n";
 Devel::Declare::set_linestr($linestr);
}

BEGIN {
 Devel::Declare->setup_for("main", { foo => { const => \&foo_magic } });
}

no indirect ":fatal";

sub bar {
 my $x;
 foo; $x->m;
}

ok 1;
