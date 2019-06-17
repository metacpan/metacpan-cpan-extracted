
use strict;
use warnings;

package MyTestParser;
use Test::More;    # last test to print
use Test::Exception;
use Moose;
use English;
extends 'Text::Parser';

sub save_record {
    my $self = shift;
    return if $self->NF == 0;
    my $old = $self->field(0);
    throws_ok {
        my (@arr) = $self->field_range('some text');
    }
    'Moose::Exception::InvalidArgumentToMethod',
        'String argument to field_range is not right';
    lives_ok {
        is_deeply(
            [ $self->field_range( -1, 0 ) ],
            [ reverse( $self->fields ) ],
            'Reverse order of fields'
        );
        my $rev_str = join ' ', ( reverse( $self->fields ) );
        is( $self->join_range( -1, 0, ' ' ),
            $rev_str, 'String in reverse order' );
    }
    'Does not die on searching backwards';
    is_deeply(
        [ $self->field_range ],
        [ $self->fields ],
        'If all arguments are skipped ; passes'
    );
    is( $self->join_range,
        join( $LIST_SEPARATOR, $self->field_range ),
        'Join all the elements'
    );
    my $nf = $self->NF;
    my (@last) = $self->field_range(-2) if $self->NF >= 2;
    is $nf, $self->NF, 'NF is still intact';
    is( $last[0],
        $self->field( $self->NF - 2 ),
        "$last[0] is the penultimate"
    );
    is( $last[1], $self->field( $self->NF - 1 ), "$last[1] is the last" );
    my (@flds) = $self->splice_fields(1);
    is $self->NF, 1, 'Only one field left now';
    is $old, $self->field(0),
        'The field function still returns the same string';
    $self->SUPER::save_record(@_);
}

sub BUILDARGS {
    return { auto_chomp => 1, auto_split => 1 };
}

package main;

use Test::More;    # last test to print
use Test::Exception;

my $p = MyTestParser->new();
lives_ok {
    $p->read('t/example-split.txt');
}
'No exceptions';

done_testing;
