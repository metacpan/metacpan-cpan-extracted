use strict;
use warnings;

package SpiceParser;
use Moose;
extends 'Text::Parser';

use Exception::Class (
    'SpiceParser::Exception',
    'SpiceParser::Exception::ReadOnlyAttribute' => {
        isa   => 'SpiceParser::Exception',
        alias => 'throw_no_change_attribute',
    }
);

use constant { SPICE_LINE_CONTD => qr/^[+]\s*/, };

my %SPICE_COMMAND = (
    '.END' => sub {
        my ( $self, $rest ) = @_;
        $self->abort_reading;
    },
    '.INCLUDE' => sub {
        my ( $self, $rest ) = @_;
        my $parser = SpiceParser->new();
        $parser->read($rest);
        $self->push_records( $parser->get_records );
    },
);

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

sub BUILDARGS {
    my $class = shift;
    return { multiline_type => 'join_last', auto_chomp => 1 };
}

before multiline_type => \&_dont_allow_overwrite;
before auto_chomp     => \&_dont_allow_overwrite;
before auto_trim      => \&_dont_allow_overwrite;

sub _dont_allow_overwrite {
    my $self = shift;
    throw_no_change_attribute error => '' if @_;
    super();
}

sub trim {
    my $s = shift;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub _call_spice_command {
    my ( $self, $line ) = @_;
    my ( $cmd, $rest ) = split /\s+/, $line, 2;
    $cmd = uc $cmd;
    return $SPICE_COMMAND{$cmd}->( $self, $rest );
}

sub _add_instance {
    my ( $self, $line ) = @_;
    $self->SUPER::save_record($line);
}

sub save_record {
    my ( $self, $line ) = @_;
    $line = trim $line;
    return if $line !~ /\S+/;
    return $self->_add_instance($line) if $line !~ /^[.]/;
    $self->_call_spice_command($line);
}

package main;
use Test::More;
use Test::Exception;

my $sp = new SpiceParser;
isa_ok( $sp, 'SpiceParser' );
can_ok( $sp, 'is_line_continued', 'join_last_line' );
isa_ok( $sp, 'Text::Parser' );
is( $sp->multiline_type, 'join_last', 'Is join_last type' );
is( $sp->auto_chomp,     1,           'Auto-chomp is turned on' );
throws_ok {
    $sp->multiline_type('join_next');
}
'SpiceParser::Exception::ReadOnlyAttribute',
    'Exception thrown if you try to change the multiline_type';
is( $sp->multiline_type, 'join_last', 'Retains old value' );
throws_ok {
    $sp->auto_chomp(0);
}
'SpiceParser::Exception::ReadOnlyAttribute',
    'Exception thrown if you try to change auto_chomp';
ok( $sp->auto_chomp, 'Retains true value' );

lives_ok { $sp->read('t/example-2.sp'); } 'Works fine';
is( $sp->has_aborted,             1, 'Has aborted' );
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

lives_ok { $sp->read('t/example-5.sp'); }
'Reads spice with include statement';
is( scalar( $sp->get_records ), 3, '3 records saved' );

done_testing;
