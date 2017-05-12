use strict;
use warnings;

use Test::More tests => 24;                      # last test to print

use Test::Pod::Snippets;

my $pod = join '', <DATA>;

for my $v ( 0..1 ) {
    for my $m ( 0..1 ) {
        for my $f ( 0..1 ) {
            my $tps = Test::Pod::Snippets->new(
                verbatim => $v, 
                functions => $f,
                methods => $m
            );

            my $code = $tps->generate_test( pod => $pod );
            ok ( $v xor $code !~ qr/verbatim stuff/ );
            ok ( $f xor $code !~ qr/myFunction/ );
            ok ( $m xor $code !~ qr/myMethod/ );
        }
    }
}






__DATA__

=head1 Foo

    verbatim stuff

=head1 METHODS

=head2 myMethod

=head1 FUNCTIONS

=head2 myFunction
