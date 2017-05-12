use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok('UML::Sequence::PerlSeq'); }

my $out_rec     = UML::Sequence::PerlSeq
                    ->grab_outline_text(qw(t/roller.methods t/roller));

shift @$out_rec;  # some Perl's make the first line main, others say (eval)
                  # to avoid a false error, discard the first line

chomp(my @correct_out = <DATA>);

unless (is_deeply($out_rec, \@correct_out, "perl CallSeq trace")) {
    local $" = "\n";
    diag("unexpected trace output\n@$out_rec\n");
}

my $methods     = UML::Sequence::PerlSeq->grab_methods($out_rec);

my @correct_methods = (
"DiePair::new",
"Die::new",
"DiePair::roll",
"Die::roll",
"DiePair::total",
"DiePair::doubles",
);

#"DiePair::to_string",
unless (is_deeply($methods, \@correct_methods, "method list")) {
    local $" = "\n";
    diag("unexpected method list @$methods\n");
}

unlink "tmon.out";

__DATA__
  DiePair::new
    Die::new
    Die::new
  DiePair::roll
    Die::roll
    Die::roll
  DiePair::total
  DiePair::doubles
