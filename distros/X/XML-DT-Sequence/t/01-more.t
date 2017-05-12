#!perl -T

use Test::More tests => 12;

use XML::DT::Sequence;

my $x = XML::DT::Sequence->new;

my $r = $x->process("t/sample2.xml",
                    -tag => 'listA',
                    -body => sub {
                        my ($self, $xml) = @_;
                        like $xml => qr{\s*<listA>\s*(?:<listB>[a-z]</listB>\s*){4}</listA>\s*}
                    }
                   );

is $r->{-body} => 2;


my $r2 = $x->process("t/sample2.xml",
                     -tag => 'listB',
                     -body => sub {
                         my ($self, $xml) = @_;
                         like $xml => qr{\s*<listB>[a-z]</listB>\s*}
                    }
                   );


is $r2->{-body} => 8;
