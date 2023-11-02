package App::ansiprintf::Util;
use v5.14;
use warnings;

use Encode;
use Exporter 'import';
our @EXPORT_OK = qw(decode_argv unescape);

use charnames ':full';

sub decode_argv {
    map {
	utf8::is_utf8($_) ? $_ : decode('utf8', $_);
    }
    @_;
}

sub unescape {
    local *_ = @_ > 0 ? \$_[0] : \$_;
    s{
	( \\ x\{[0-9a-f]+\}
	| \\ x[0-9a-f]{2}
	| \\ N\{[\ \w]+\}
	| \\ N\{U\+[0-9a-f]+\}
	| \\ c.
	| \\ o\{\d+\}
	| \\ \d{1,3}
	| \\ .
        )
    }{ eval qq["$1"] or die "$1 : string error.\n"}xiger;
}

1;
