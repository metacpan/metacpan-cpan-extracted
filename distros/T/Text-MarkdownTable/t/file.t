use strict;
use warnings;
use Test::More;
use Text::MarkdownTable;
use IO::Handle;
use File::Temp;

my (undef, $file) = File::Temp::tempfile( OPEN => 0 );
Text::MarkdownTable->new( file => $file, condense => 1 )->add({x=>1})->done;
is do { local (@ARGV, $/) = ($file); <> }, "x\n-\n1\n", "write to file";

my $tempdir = File::Temp::tempdir;
foreach ('', '/', undef, Text::MarkdownTable->new, $tempdir) {
    eval { Text::MarkdownTable->new( file => $_ )->add({x=>1})->done; };
    ok $@, 'invalid file';
}

done_testing;
