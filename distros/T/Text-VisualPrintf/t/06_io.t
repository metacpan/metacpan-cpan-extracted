use strict;
use warnings;
use utf8;
use Encode;
use open IO => ':utf8', ':std';

use Test::More;

use Text::VisualPrintf::IO qw(printf vprintf);

{
    open OUT, ">", \(my $out) or die;
    OUT->printf("%10s\n", "あいうえお");
    close OUT;

    is( decode('utf8', $out),  "あいうえお\n", 'FH->printf' );
}

{
    open OUT, ">", \(my $out) or die;
    vprintf OUT "%10s\n", "あいうえお";
    close OUT;

    is( decode('utf8', $out),  "あいうえお\n", 'vprintf FH' );
}

sub subprocess (&) {
    my $block = shift;
    my $pid = open IN, "-|" // die;
    if ($pid == 0) {
	$block->();
	exit;
    }
    my $out = do { local $/; <IN> };
    close IN;
    $out;
}

SKIP: {
    skip "windows", 1 if $^O eq 'MSWin32';
    my $out = subprocess {
	STDOUT->printf("%10s\n", "あいうえお");
    };
    is( $out,  "あいうえお\n", 'STDOUT' );
}

SKIP: {
    skip "windows", 1 if $^O eq 'MSWin32';
    my $out = subprocess {
	use IO::Handle;
	my $io = IO::Handle->new();
	if ($io->fdopen(fileno(STDOUT), "w")) {
	    binmode $io, ':encoding(utf8)';
	    $io->printf("%10s\n", "あいうえお");
	}
    };
    is( $out,  "あいうえお\n", 'IO::Handle' );
}

SKIP: {
    skip "windows", 1 if $^O eq 'MSWin32';
    my $out = subprocess {
	use IO::File;
	my $io = IO::File->new(">/dev/stdout") or die;
	if ($io) {
	    binmode $io, ':encoding(utf8)';
	    $io->printf("%10s\n", "あいうえお");
	    $io->close;
	}
    };
    is( $out,  "あいうえお\n", 'IO::File' );
}

done_testing;
