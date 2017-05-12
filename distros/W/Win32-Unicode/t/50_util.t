use strict;
use warnings;
use utf8;
use Test::More;
use Encode;
use Win32::Unicode::Util;
use Win32::Unicode::Constant qw/CYGWIN/;

subtest 'utf16_to_utf8' => sub {
    my $utf16 = encode 'utf16-le' => 'ほげ';
    is utf16_to_utf8($utf16), decode('utf16-le' => $utf16);
    done_testing;
};

subtest 'utf8_to_utf16' => sub {
    my $utf8 = 'ふが';
    is utf8_to_utf16($utf8), encode('utf16-le', $utf8);
    done_testing;
};

subtest 'to64int' => sub {
    use bigint;
    is to64int(1, 0), 4294967296;
    done_testing;
};

subtest 'is64int' => sub {
    use bigint;
    ok is64int(1 << 32);
    ok !is64int(1 << 32 - 1);
    done_testing;
};

subtest 'cygpathw' => sub {
    plan skip_all => 'cygwin only' unless CYGWIN;
    my $path = '/home';
    is do { chomp(my $res = `cygpath -mw $path`); $res }, cygpathw($path);
    done_testing;
};

done_testing;
