
use strict;
use warnings;

package MyParser;

use Moose;
extends 'Text::Parser';

sub BUILDARGS {
    return {
        auto_split => 1,
        auto_chomp => 1,
        auto_trim  => 'b'
    };
}

sub save_record {
    my $self = shift;
    $self->FS(qr/[,]/) if $self->field(0) eq 'CSV_BELOW';
    $self->SUPER::save_record( [ $self->fields ] );
}

package main;

use Test::More;

my $parser = MyParser->new();
isa_ok $parser, 'Text::Parser';
isa_ok $parser, 'MyParser';
$parser->read('t/input.txt');
my (@rec) = $parser->get_records;
is_deeply( scalar(@rec), 6 );
is_deeply(
    $rec[0],
    [ 'Some', 'information', 'in', 'this', 'file' ],
    'Starts with space as FS'
);
is_deeply( $rec[2], [ 'col1', 'col2', 'col3' ], 'Starts with , as FS' );

done_testing;

