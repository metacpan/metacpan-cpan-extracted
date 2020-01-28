use strict;
use warnings;
use utf8;
use Encode;
use open IO => ':utf8', ':std';
use Data::Dumper;
use Text::VisualPrintf qw(vprintf vsprintf);

use Test::More;

{
    my $out;

    open OUT, ">", \$out or die;
    Text::VisualPrintf::printf OUT "%12s\n", "あいうえお";
    close OUT;

    is( decode('utf8', $out),  "  あいうえお\n", 'filehandle (class)' );
}

{
    no warnings 'once';
    *IO::Handle::vprintf = \&Text::VisualPrintf::printf;
}

{
    my $out;

    open OUT, ">", \$out or die;
    vprintf OUT "%13s\n", "あいうえお";
    close OUT;

    is( decode('utf8', $out),  "   あいうえお\n", 'filehandle (method)' );
}

{
    my $out;

    open OUT, ">", \$out or die;
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

{
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

{
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
