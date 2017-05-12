use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('UML::Sequence::PerlOOSeq'); }

my $out_rec     = UML::Sequence::PerlOOSeq
                    ->grab_outline_text(qw(t/roller.methods t/roller));

shift @$out_rec;  # some Perl's make the first line main, others say (eval)
                  # to avoid a false error, discard the first line

chomp(my @correct_out = <DATA>);

unless (is_deeply($out_rec, \@correct_out, "perl OOCallSeq trace")) {
    local $" = "\n";
    diag("unexpected trace output\n@$out_rec\n");
}

my $methods     = UML::Sequence::PerlOOSeq->grab_methods($out_rec);

my @correct_methods = (
"DiePair::new",
"Die::new",
"DiePair::roll",
"Die::roll",
"DiePair::total",
"DiePair::doubles",
);

unless (is_deeply($methods, \@correct_methods, "method list")) {
    local $" = "\n";
    diag("unexpected method list @$methods\n");
}

unlink "tmon.out";

__DATA__
  diePair1:DiePair::new
    die1:Die::new
    die2:Die::new
  diePair1:DiePair::roll
    die1:Die::roll
    die2:Die::roll
  diePair1:DiePair::total
  diePair1:DiePair::doubles
