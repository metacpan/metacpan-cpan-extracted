use strict;
use warnings;

package SpiceParser;
use parent 'TextFileParser';

sub save_record {
    my ( $self, $line ) = @_;
    return $self->SUPER::save_record($line) if $line !~ /^[+]\s*/;
    $line =~ s/^[+]\s*//;
    my $last_rec = $self->pop_record;
    chomp $last_rec;
    $self->SUPER::save_record( $last_rec . ' ' . $line );
}

package main;
use Test::More;
use Test::Exception;

my $sp = new SpiceParser;

lives_ok { $sp->read('t/example.sp'); } 'Works fine';
is( $sp->lines_parsed, 4, 'Parses 4 lines' );
is( $sp->last_record, "Minst net1 net2 net3 net4 nmos l=0.09u w=0.13u\n" );

done_testing;
