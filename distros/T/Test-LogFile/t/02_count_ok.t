use strict;
use warnings;
use Test::More;
use Test::LogFile;
use IO::Handle;

my ( $fh, $file ) = log_file;
$fh->autoflush(1);
$fh->print("testing:$$\n") for 1 .. 2;
$fh->close;

count_ok(
    file  => $file,
    str   => 'testing',
    count => 2,
    msg   => "log count is valid",
    hook  => sub {
        my $line = shift;
        chomp $line;
        my @row = split /:/, $line;
        is( $row[1], $$, "hook as log count" );
    }
);

done_testing;
