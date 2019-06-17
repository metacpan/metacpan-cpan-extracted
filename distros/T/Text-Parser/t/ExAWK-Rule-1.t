
use strict;
use warnings;

package SomeParser;

use Moose;
extends 'Text::Parser';
use Text::Parser::Rule;

my (@rules);
push @rules,
    Text::Parser::Rule->new(
    if => '$1 eq "NAME:"',
    do => 'return $2'
    );
push @rules, Text::Parser::Rule->new( if => '$1 eq "SOMETHING"', );

$rules[1]->add_precondition('$2 eq "ELSE:"');

sub save_record {
    my ( $self, $record ) = ( shift, shift );
    foreach my $rule (@rules) {
        next if not $rule->test($self);
        $rule->run($self);
        last if not $rule->continue_to_next;
    }
}

sub BUILD {
    my $self = shift;
    $self->auto_split(1);
}

package main;

use Test::More;
use Test::Exception;

my $parser = SomeParser->new();
isa_ok( $parser, 'Text::Parser' );
lives_ok {
    $parser->read('t/lines-whitespace.txt');
}
'lives without dying';
is_deeply( [ $parser->get_records ], [], 'No records matched' );

lives_ok {
    $parser->read('t/names.txt');
}
'now a real file to parse';
is_deeply(
    [ $parser->get_records ],
    [ "BALAJI", "SOMETHING ELSE: blah blah blah\n", "ELIZABETH", 'BRIAN' ],
    'Got data properly'
);

done_testing;
