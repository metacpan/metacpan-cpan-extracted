use strict;
use warnings;
use utf8;
use Encode;
use open IO => ':utf8', ':std';
use Data::Dumper;
use lib 't/lib'; use Text::VPrintf qw(vprintf vsprintf);

use Test::More;

{
    open OUT, ">", \(my $out) or die;
    Text::VPrintf::printf OUT "%12s\n", "あいうえお";
    close OUT;

    is( decode('utf8', $out),  "  あいうえお\n", 'filehandle (class)' );
}

{
    no warnings 'once';
    *IO::Handle::vprintf = \&Text::VPrintf::printf;
}

{
    open OUT, ">", \(my $out) or die;
    vprintf OUT "%13s\n", "あいうえお";
    close OUT;

    is( decode('utf8', $out),  "   あいうえお\n", 'filehandle (method)' );
}

{
    open OUT, ">", \(my $out) or die;
    OUT->vprintf("%14s\n", "あいうえお");
    close OUT;

    is( decode('utf8', $out),  "    あいうえお\n", 'filehandle (->)' );
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
	use IO::Handle;
	my $io = IO::Handle->new();
	if ($io->fdopen(fileno(STDOUT), "w")) {
	    binmode $io, ':encoding(utf8)';
	    $io->vprintf("%14s\n", "あいうえお");
	}
    };
    is( $out,  "    あいうえお\n", 'IO::Handle' );
}

SKIP: {
    skip "windows", 1 if $^O eq 'MSWin32';
    my $out = subprocess {
	use IO::File;
	my $io = IO::File->new(">/dev/stdout") or die;
	if ($io) {
	    binmode $io, ':encoding(utf8)';
	    $io->vprintf("%15s\n", "あいうえお");
	    $io->close;
	}
    };
    is( $out,  "     あいうえお\n", 'IO::File' );
}

done_testing;
