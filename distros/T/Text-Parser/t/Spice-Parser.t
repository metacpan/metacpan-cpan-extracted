use strict;
use warnings;

package SpiceParser;
use parent 'Text::Parser';

use constant {
    SPICE_LINE_CONTD => qr/^[+]\s*/,
    SPICE_END_FILE   => qr/^\.end/i,
};

sub save_record {
    my ( $self, $line ) = @_;
    return $self->__spice_line_contd($line)
        if $self->is_line_continued($line);
    return $self->abort_reading() if $line =~ SPICE_END_FILE;
    $self->SUPER::save_record($line);
}

sub is_line_continued {
    my $self = shift;
    return 1 if $self->SUPER::is_line_continued(@_);
    my $line = shift;
    return $line =~ SPICE_LINE_CONTD;
}

sub __spice_line_contd {
    my ( $self, $line ) = @_;
    $line =~ s/^[+]\s*//;
    my $last_rec = $self->pop_record;
    chomp $last_rec;
    $self->SUPER::save_record( $last_rec . ' ' . $line );
}

package main;
use Test::More;
use Test::Exception;

my $sp = SpiceParser->new();

lives_ok { $sp->read('t/example.sp'); } 'Works fine';
is( scalar( $sp->get_records() ), 1, '1 record saved' );
is( $sp->lines_parsed(),          5, '5 lines parsed' );
is( $sp->last_record, "Minst net1 net2 net3 net4 nmos l=0.09u w=0.13u\n" );

done_testing;
