use strict;
use warnings;
use Test::More;
use Test::Fatal;

use XML::LibXML::SAX::ChunkParser;

my $parser = XML::LibXML::SAX::ChunkParser->new();

my $saw_end;
my $saw_start;

$parser->{Methods}->{start_document} = sub {
    $saw_start = 1;
};

$parser->{Methods}->{end_document} = sub {
    $saw_end = 1;
};

$parser->parse_chunk('<xml></xml>');

is( exception { $parser->finish }, undef, 'Finish does not bail' );

ok( $saw_start, "Saw start" );

ok( $saw_end, "Saw end" );
done_testing;
