use strict;
use warnings;

package SpiceParser;
use Moose;
extends 'Text::Parser';
use Test::More;

use Exception::Class (
    'SpiceParser::Exception',
    'SpiceParser::Exception::ReadOnlyAttribute' => {
        isa   => 'SpiceParser::Exception',
        alias => 'throw_no_change_attribute',
    }
);

use constant { SPICE_LINE_CONTD => qr/^[+]\s*/, };

sub is_line_continued {
    my ( $self, $line ) = @_;
    is $line, $self->this_line, "is_line_continued: $line matches";
    return 0 if not defined $line;
    return $line =~ SPICE_LINE_CONTD;
}

sub join_last_line {
    my ( $self, $last, $line ) = ( shift, shift, shift );
    is $line, $self->this_line, "join_last_line: $line matches";
    return $last if not defined $line;
    $line =~ s/^[+]\s*/ /;
    return $line if not defined $last;
    return $last . $line;
}

sub BUILDARGS {
    my $class = shift;
    return {
        multiline_type => 'join_last',
        auto_chomp     => 1,
        auto_trim      => 'b',
        auto_split     => 1
    };
}

before multiline_type => \&_dont_allow_overwrite;
before auto_chomp     => \&_dont_allow_overwrite;
before auto_trim      => \&_dont_allow_overwrite;

sub _dont_allow_overwrite {
    my $self = shift;
    throw_no_change_attribute error => '' if @_;
    super();
}

my %SPICE_COMMAND = (
    '.END' => sub {
        my $self = shift;
        $self->abort_reading;
    },
    '.INCLUDE' => sub {
        my ( $self, $rest ) = @_;
        my $parser = SpiceParser->new();
        $parser->read($rest);
        $self->push_records( $parser->get_records );
    },
);

sub save_record {
    my $self = shift;
    is $_[0], $self->this_line, "save_record: $_[0]";
    return if $self->NF == 0;
    return $self->_add_instance(@_) if $self->field(0) !~ /^[.]/;
    $self->_call_spice_command(@_);
}

sub _call_spice_command {
    my $self = shift;
    my $cmd  = uc $self->field(0);
    return $SPICE_COMMAND{$cmd}->( $self, $self->splice_fields(1) );
}

sub _add_instance {
    my $self = shift;
    for my $i ( 0 .. ( $self->NF - 1 ) ) {
        my $ln = $self->lines_parsed();
        is $self->field( $i - $self->NF ), $self->field($i),
            "Field # $i matched on line # $ln";
    }
    $self->SUPER::save_record(@_);
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

throws_ok {
    $sp->auto_split(0);
}
'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
    'Dont change auto_split ; it is ro';

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

throws_ok { $sp->read('t/bad-spice.sp'); }
'Text::Parser::Errors::UnexpectedCont', 'Dies as expected';

lives_ok { $sp->read('t/example-5.sp'); }
'Reads spice with include statement';
is( scalar( $sp->get_records ), 3, '3 records saved' );

done_testing;
