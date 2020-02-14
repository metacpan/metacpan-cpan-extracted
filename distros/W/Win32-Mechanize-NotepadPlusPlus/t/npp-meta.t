########################################################################
# Verifies Notepad object messages / methods work
#   subgroup: meta-information methods
########################################################################
use 5.010;
use strict;
use warnings;
use Test::More;
use Win32;

use Path::Tiny 0.018 qw/path tempfile/;

use Win32::Mechanize::NotepadPlusPlus ':main';

my $ret;
$ret = notepad()->getNppVersion;
like $ret, qr/^v\d+[\.\d]*$/, 'getNppVersion';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getPluginVersion;
like $ret, qr/v\d+\.[\._\d]+/, 'getPluginVersion';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getPerlVersion;
ok $ret, 'getPerlVersion';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';
$ret = notepad()->getPerlBits;
ok $ret, 'getPerlBits';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

TODO: {
    local $TODO = 'unimplemented';
    $ret = notepad()->getCommandLine;
    is $ret, '', 'getCommandLine';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';
}

$ret = notepad()->getNppDir;
ok $ret, 'getNppDir';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

$ret = notepad()->getPluginConfigDir;
ok $ret, 'getPluginConfigDir';
    note sprintf "\t=> \"%s\"", defined $ret ? explain $ret : '<undef>';

done_testing;