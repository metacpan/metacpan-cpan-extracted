#!perl -T

use Test::More tests => 1;

use XML::DT::Sequence;

my $i = 0;
my $x = XML::DT::Sequence->new;

my $r = $x->process("t/longsample.xml",
                    -tag => 'bar',
                    -body => {
                              -default => sub {
                                  $i++;
                                  $u->break if $i == 1000;
                              }
                             }
                   );

is $r->{-body} => 1000;
