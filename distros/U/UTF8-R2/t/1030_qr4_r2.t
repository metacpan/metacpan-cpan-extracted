######################################################################
#
# 1030_qr4_r2.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

tie my %r2, 'UTF8::R2';

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\A"\\c\)" is more clearly written simply as "i" at /   ? return :
        /\A"\\c\}" is more clearly written simply as "\\=" at / ? return :
        /\AIllegal hex digit ignored at /                       ? return :
        /\AUnrecognized escape \\H passed through at /          ? return :
        /\AUnrecognized escape \\R passed through at /          ? return :
        /\AUnrecognized escape \\V passed through at /          ? return :
        /\AUnrecognized escape \\h passed through at /          ? return :
        /\AUnrecognized escape \\v passed through at /          ? return :
        /\A\\C is deprecated in regex; marked by <-- HERE in /  ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub {                         "あああ" =~ $r2{qr/(あ)/}                 },
    sub {                         "あああ" =~ $r2{qr/(あ)?/}                },
    sub {                         "あああ" =~ $r2{qr/(あ)+/}                },
    sub {                         "あああ" =~ $r2{qr/(あ)*/}                },
    sub {                         "あああ" =~ $r2{qr/(あ){1}/}              },
    sub {                         "あああ" =~ $r2{qr/(あ){1,}/}             },
    sub {                         "あああ" =~ $r2{qr/(あ){1,2}/}            },
    sub {                         "あああ" =~ $r2{qr/あ{1}/}                },
    sub {1},
    sub {                         "あああ" =~ $r2{qr/[あ]/}                 },
# 11
    sub {                         "あああ" =~ $r2{qr/[あ]?/}                },
    sub {                         "あああ" =~ $r2{qr/[あ]+/}                },
    sub {                         "あああ" =~ $r2{qr/[あ]*/}                },
    sub {                         "あああ" =~ $r2{qr/[あ]{1}/}              },
    sub {                         "あああ" =~ $r2{qr/[あ]{1,}/}             },
    sub {                         "あああ" =~ $r2{qr/[あ]{1,2}/}            },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
