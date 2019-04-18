
use strict;
use warnings;

package MyParser;

use parent 'Text::Parser';

sub new {
    my $pkg = shift;
    $pkg->SUPER::new( auto_split => 1 );
}

sub save_record {
    my $self = shift;
    $self->SUPER::save_record(
        { num => $self->NF, content => [ $self->fields() ] } );
}

package main;

use Test::More;
use Test::Exception;

my $p = MyParser->new();
is $p->auto_trim, 'n', 'This will not be trimmed';
lives_ok {
    $p->read('t/trim-vs-split.txt');
}
'Reads the file with no issues';

is_deeply(
    $p->last_record(),
    { num => 5, content => [ 'some', 'text', 'is', 'written', 'here' ] },
    'This matches the content'
);

done_testing;
