use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { use_ok 'Text::Parser'; }
BEGIN { use_ok 'FileHandle'; }

my $fname = 'text-simple.txt';

my $pars;
throws_ok { $pars = Text::Parser->new('balaji'); }
'Text::Parser::Exception::Constructor',
    'Throws an exception for non-hash input';
throws_ok { $pars = Text::Parser->new( balaji => 1 ); }
'Text::Parser::Exception::Constructor', 'Throws an exception for bad keys';
throws_ok { $pars = Text::Parser->new( multiline_type => 'balaji' ); }
'Moose::Exception::ValidationFailedForInlineTypeConstraint',
    'Throws an exception for bad value';
lives_ok { $pars = Text::Parser->new( multiline_type => undef ); }
'Improve coverage';
$pars = Text::Parser->new();
isa_ok( $pars, 'Text::Parser' );
is( $pars->setting(),         undef, 'When no setting is called' );
is( $pars->setting('balaji'), undef, 'balaji is not a setting at all' );
is( $pars->filename(),        undef, 'No filename specified so far' );

lives_ok { is( $pars->filehandle(), undef, 'Not initialized' ); }
'This should not die, just return undef';
throws_ok { $pars->filehandle('bad argument'); }
'Moose::Exception::ValidationFailedForInlineTypeConstraint',
    'filehandle() will take only a GLOB or FileHandle input';
throws_ok { $pars->filename( { a => 'b' } ); }
'Moose::Exception::ValidationFailedForInlineTypeConstraint',
    'filename() will take only string as input';
throws_ok { $pars->filename($fname) }
'Moose::Exception::ValidationFailedForInlineTypeConstraint',
    'No file by this name';
throws_ok { $pars->read( bless {}, 'Something' ); }
'Text::Parser::Exception::BadReadInput',
    'filehandle() will take only a GLOB or FileHandle input';
throws_ok { $pars->read($fname); }
'Moose::Exception::ValidationFailedForInlineTypeConstraint',
    'Throws exception for non-existent file';

lives_ok { $pars->read(); } 'Returns doing nothing';
is( $pars->lines_parsed, 0, 'Nothing parsed' );
is_deeply( [ $pars->get_records ], [], 'No data recorded' );
is( $pars->last_record, undef, 'No records' );
is( $pars->pop_record,  undef, 'Nothing on stack' );

lives_ok { $pars->read(''); } 'Reads no file ; returns doing nothing';
is( $pars->filename(),     undef, 'No file name still' );
is( $pars->lines_parsed(), 0,     'Nothing parsed again' );

SKIP: {
    skip 'Tests not meant for root user', 2 unless $>;
    skip 'Tests wont work on MSWin32',    2 unless $^O ne 'MSWin32';
    open OFILE, ">t/unreadable.txt";
    print OFILE "This is unreadable\n";
    close OFILE;
    chmod 0200, 't/unreadable.txt';
    throws_ok { $pars->filename('t/unreadable.txt'); }
    'Moose::Exception::ValidationFailedForInlineTypeConstraint',
        'This file cannot be read';
    is( $pars->filename(), undef, 'Still no file has been read so far' );
    unlink 't/unreadable.txt';
}

my $content = "This is a file with one line\n";
lives_ok { $pars->filename( 't/' . $fname ); } 'Now I can open the file';
lives_ok { $pars->read; } 'Reads the file now';
is_deeply( [ $pars->get_records ], [$content], 'Get correct data' );
is( $pars->lines_parsed, 1,             '1 line parsed' );
is( $pars->last_record,  $content,      'Worked' );
is( $pars->pop_record,   $content,      'Popped' );
is( $pars->lines_parsed, 1,             'Still lines_parsed returns 1' );
is( $pars->filename(),   't/' . $fname, 'Last file read' );

open OUTFILE, ">example";
if ( -r OUTFILE ) {
    lives_ok { $pars->filehandle( \*OUTFILE ); }
    'In some systems output file handles are also readable! Your system is one of those. This could be a potential security hole.';
    is( $pars->filename(), undef, 'Last file read is not available anymore' );
} else {
    throws_ok { $pars->filehandle( \*OUTFILE ); } 'Text::Parser::Exception',
        'Your system is strict and will not read from an output filehandle. This is potentially good for security.';
}
print OUTFILE "Simple text";
close OUTFILE;
open INFILE, "<example";
lives_ok {
    $pars->read( \*INFILE );
    is_deeply( [ $pars->get_records() ],
        ['Simple text'], 'Read correct data in file' );
}
'Exercising the ability to read from file handles directly';
lives_ok { $pars->read( FileHandle->new( 'example', 'r' ) ); }
'No issues in reading from a FileHandle object of STDIN';
unlink 'example';

## Testing the reading from filehandles on STDOUT and STDIN
if ( -r STDOUT ) {
    lives_ok { $pars->filehandle( \*STDOUT ); }
    'Some systems can read from STDOUT. Your system is one of them.';
} else {
    throws_ok { $pars->filehandle( \*STDOUT ); } 'Text::Parser::Exception',
        'Your system is strict and will not read from STDOUT';
}
lives_ok { $pars->filehandle( \*STDIN ); } 'No issues in reading from STDIN';

throws_ok { $pars->read( { a => 'b' } ); } 'Text::Parser::Exception',
    'Invalid type of argument for read() method';

lives_ok { $pars->read( 't/' . $fname ); }
'reads the contents of a file without dying';
is( $pars->last_record,  $content, 'Last record is correct' );
is( $pars->lines_parsed, 1,        'Read only one line' );
is_deeply( [ $pars->get_records ], [$content], 'Got correct file content' );

my $add = "This record is added";
lives_ok { $pars->save_record(); } 'Add nothing';
is( $pars->last_record, undef, 'Last record is undef' );
lives_ok { $pars->save_record($add); } 'Add another record';
is( $pars->lines_parsed, 1,    'Still only 1 line parsed' );
is( $pars->last_record,  $add, 'Last added record' );
is_deeply(
    [ $pars->get_records ],
    [ $content, undef, $add ],
    'But will contain all elements including an undef'
);

is( $pars->pop_record,   $add,     'Popped a record' );
is( $pars->lines_parsed, 1,        'Still only 1 line parsed' );
is( $pars->last_record,  undef,    'There was an undef in between' );
is( $pars->pop_record,   undef,    'Now undef is removed' );
is( $pars->last_record,  $content, 'Now the last record is the one earlier' );
is_deeply( [ $pars->get_records ],
    [$content], 'Got correct content after pop' );

done_testing;
