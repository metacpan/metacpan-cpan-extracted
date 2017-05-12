# -*- perl -*-
# test that regular (non-pipe) use of the open() function is unaffected

use Test::More;
use warnings;
use strict;

BEGIN {
    if ($] >= 5.008) {
	plan tests => 53;
    }
    else {
	plan tests => 47;
    }
}

BEGIN { use_ok 'Test::MockCommand'; }

# because we're using barewords for open() file handles
no strict 'refs';

# Test::MockCommand calls _handle if it recognises an open() to/from a pipe.
# So if we get to _handle, something bad happened
no warnings;
*Test::MockCommand::_handle = sub { die 'FAIL' };
use warnings;

my $string = "test\n";

# 2-arg open()
ok open(FH, '>testfile.txt'),      '2-arg open() for writing';
ok print(FH $string),              '2-arg open() for writing print';
ok close(FH),                      '2-arg open() for writing close';

ok open(FH, '<testfile.txt'),      '2-arg open() reading';
is <FH>, $string,                  '2-arg open() reading <FH>';
ok close(FH),                      '2-arg open() reading close';

ok open(FH, 'testfile.txt'),       '2-arg open() for reading no mode';
is <FH>, $string,                  '2-arg open() for reading no mode <FH>';
ok close(FH),                      '2-arg open() close';

ok open(FH, ' testfile.txt'),      '2-arg open() reading no mode space';
is <FH>, $string,                  '2-arg open() reading no mode space <FH>';
ok close(FH),                      '2-arg open() reading no mode space close';

my $fh = 'fish biscuits';
ok open($fh, '<testfile.txt'),     '2-arg open() symbolic';
ok defined(*$fh),                  '2-arg open() symbol entry exists';
ok defined(*$fh{IO}),              '2-arg open() symbol IO entry exists';
is <$fh>, $string,                 '2-arg open() symbolic <FH>';
ok close($fh),                     '2-arg open() symbolic close';

$fh = 'another silly name';
package blah;
main::ok open("main::$fh", '<testfile.txt'), '2-arg open() symbolic other pkg';
package main;
ok defined(*$fh),                  '2-arg open() other symbol entry exists';
ok defined(*$fh{IO}),              '2-arg open() other symbol IO entry exists';
is <$fh>, $string,                 '2-arg open() other symbolic <FH>';
ok close($fh),                     '2-arg open() other symbolic close';

$fh = undef;
ok open($fh, '<testfile.txt'),     '2-arg open() reference';
ok defined($fh),                   '2-arg open() reference handle defined';
is <$fh>, $string,                 '2-arg open() reference <FH>';
ok close($fh),                     '2-arg open() reference close';

# 3-arg open()
ok open(FH, '>', 'testfile.txt'),  '3-arg open() for writing';
ok print(FH $string),              '3-arg open() for writing print';
ok close(FH),                      '3-arg open() for writing close';

ok open(FH, '<', 'testfile.txt'),  '3-arg open() reading';
is <FH>, $string,                  '3-arg open() reading <FH>';
ok close(FH),                      '3-arg open() reading close';

if ($] >= 5.008) {
    ok open(FH, ' <', 'testfile.txt'), '3-arg open() reading space';
    is <FH>, $string,                  '3-arg open() reading space <FH>';
    ok close(FH),                      '3-arg open() reading space close';

    ok open(FH, '<:utf8', 'testfile.txt'), '3-arg open() reading iolayer';
    is <FH>, $string,                  '3-arg open() reading iolayer <FH>';
    ok close(FH),                      '3-arg open() reading iolayer close';
}

$fh = 'prune power';
ok open($fh, '<', 'testfile.txt'), '3-arg open() symbolic';
ok defined(*$fh),                  '3-arg open() symbol entry exists';
ok defined(*$fh{IO}),              '3-arg open() symbol IO entry exists';
is <$fh>, $string,                 '3-arg open() symbolic <FH>';
ok close($fh),                     '3-arg open() symbolic close';

$fh = 'the banyan tree';
package blah;
main::ok open("main::$fh", '<', 'testfile.txt'), 
    '3-arg open() symbolic other pkg';
package main;
ok defined(*$fh),                  '3-arg open() other symbol entry exists';
ok defined(*$fh{IO}),              '3-arg open() other symbol IO entry exists';
is <$fh>, $string,                 '3-arg open() other symbolic <FH>';
ok close($fh),                     '3-arg open() other symbolic close';

$fh = undef;
ok open($fh, '<', 'testfile.txt'), '3-arg open() reference';
ok defined($fh),                   '3-arg open() reference handle defined';
is <$fh>, $string,                 '3-arg open() reference <FH>';
ok close($fh),                     '3-arg open() reference close';

# delete our test file
die "deleting file: $!" unless unlink 'testfile.txt';
