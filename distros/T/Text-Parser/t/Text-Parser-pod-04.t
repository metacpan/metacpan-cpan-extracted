use strict;
use warnings;

use Test::More;
use Test::Output;
use Test::Exception;
use Try::Tiny;

BEGIN { use_ok 'Text::Parser'; }

my $parser = Text::Parser->new();
isa_ok $parser, 'Text::Parser';
lives_ok {
    $parser->read('t/text-simple.txt');
}
'Parses a text file normally';
is( $parser->filename(), 't/text-simple.txt', 'Last file read' );
is( $parser->filehandle(), undef, 'Filehandle was closed' );

open MYFH, "<t/text-simple.txt";
lives_ok {
    $parser->read( \*MYFH );
}
'Reads the content again';
is( $parser->filename(), undef, 'The last file read is lost' );
close MYFH;
isnt( $parser->filehandle(), undef, 'Retains the last filehandle read' );
throws_ok {
    $parser->read( \*MYFH );
}
'Text::Parser::Exception', 'Trying to read a closed filehandle';
isnt( $parser->filehandle(), undef, 'Retains the last filehandle read' );

done_testing();
