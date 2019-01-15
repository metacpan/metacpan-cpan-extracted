use strict;
use warnings;

package SpiceParser;
use parent 'Text::Parser';

use constant {
    SPICE_LINE_CONTD => qr/^[+]\s*/,
    SPICE_END_FILE   => qr/^\.end/i,
};

sub is_line_continued {
    my ( $self, $line ) = @_;
    return 0 if not defined $line;
    return $line =~ SPICE_LINE_CONTD;
}

sub join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    return $last if not defined $line;
    $line =~ s/^[+]\s*/ /;
    return $line if not defined $last;
    return $last . $line;
}

sub new {
    my $pkg = shift;
    $pkg->SUPER::new( auto_chomp => 1, multiline_type => 'join_last' );
}

sub save_record {
    my ( $self, $line ) = @_;
    return $self->abort_reading() if $line =~ SPICE_END_FILE;
    $self->SUPER::save_record($line);
}

package main;
use Test::More;
use Test::Exception;

my $sp = new SpiceParser;
isa_ok( $sp, 'SpiceParser' );
can_ok( $sp, 'is_line_continued', 'join_last_line' );
isa_ok( $sp, 'Text::Parser' );

lives_ok { $sp->read('t/example-2.sp'); } 'Works fine';
is( scalar( $sp->get_records() ), 1, '1 record saved' );
is( $sp->lines_parsed(),          6, '6 lines parsed' );
is( $sp->last_record, "Minst net1 net2 net3 net4 nmos l=0.09u w=0.13u" );

lives_ok { $sp->read('t/example-3.sp'); } 'Works fine again';
is( scalar( $sp->get_records() ), 2, '2 records saved' );
is( $sp->lines_parsed(),          2, '2 lines parsed' );

lives_ok { $sp->read('t/example-4.sp'); } 'Works fine again';
is( scalar( $sp->get_records() ), 2, '2 records saved' );
is( $sp->lines_parsed(),          4, '4 lines parsed' );

throws_ok { $sp->read('t/bad-spice.sp'); } 'Text::Parser::Multiline::Error',
    'Dies as expected';
done_testing;
