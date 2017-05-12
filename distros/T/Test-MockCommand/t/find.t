# -*- perl -*-
# test all find() functionality

use Test::More tests => 37;
use warnings;
use strict;
use Cwd;

BEGIN { use_ok 'Test::MockCommand'; }

# begin recording
Test::MockCommand->recording(1);

# 1x open:echo test
my $fh; open($fh, "echo test |") && close $fh;

# 2x system:echo hello
system('echo hello');
system('echo hello');

# 3x readpipe:echo world
readpipe('echo world');
readpipe('echo world');
readpipe('echo world');

sub f { return scalar Test::MockCommand->find(@_) }

is scalar(Test::MockCommand->all_commands()), 6, 'all_commands()';
is f(), 6, 'find() finds everything';
is f(command => 'echo test'),  1, 'c = echo test';
is f(command => 'echo hello'), 2, 'c = echo hello';
is f(command => 'echo world'), 3, 'c = echo world';
is f(command => 'nothing'),    0, 'c = nothing';
is f(command => qr/bad/),      0, 'c =~ /bad/';
is f(command => qr/world$/),   3, 'c =~ /world$/';
is f(command => qr/o h/),      2, 'c =~ /o h/';
is f(command => qr/^echo/),    6, 'c =~ /^echo/';
is f(function => 'readpipe'),  3, 'f = readpipe';
is f(function => 'system'),    2, 'f = system';
is f(function => 'open'),      1, 'f = open';
is f(function => 'what'),      0, 'f = what';

is f(function => 'open', command => qr/^echo/),    1, 'open:/^echo/';
is f(function => 'open', command => qr/^fail/),    0, 'open:/^fail/';
is f(function => 'open', command => qr/test$/),    1, 'open:/test$/';
is f(function => 'system', command => qr/test$/),  0, 'system:/test$/';
is f(function => 'system', command => qr/test$/),  0, 'system:/test$/';
is f(function => 'wrong', command => qr/^echo/),   0, 'wrong:/^echo/';
is f(function => 'system', command => qr/test$/),  0, 'system:/test$/';
is f(function => 'wrong', command => 'echo test'), 0, 'wrong:echo test';
is f(function => 'open',  command => 'echo test'), 1, 'open:echo test';

is f(madeup => 'rubbish'), 6, 'madeup attribute';

is f(arguments => ['bad', 'args']), 0, 'bad args';
is f(arguments => [undef, 'echo test |']), 1, 'args to open';
is f(arguments => ['echo hello']), 2, 'args to system';
is f(arguments => ['echo world']), 3, 'args to readpipe';

my $cwd = Cwd::cwd();
is f(cwd => $cwd), 6, 'cwd is correct';
is f(cwd => 'tastes like donkey poop'), 6, 'cwd is wrong';

# run 'echo cwd' in current dir, then subdir, then current dir again
# to ensure the one in the subdir doen't rank first due to chronology
readpipe('echo cwd');
ok mkdir 'testcwd';
ok chdir 'testcwd';
readpipe('echo cwd');
my $newcwd = Cwd::cwd();
ok chdir $cwd;
ok rmdir 'testcwd';
readpipe('echo cwd');

my @results = Test::MockCommand->find(cwd => $newcwd);
is scalar(@results), 9, 'new command picked up';
is $results[0]->cwd(), $newcwd, 'newcwd gets first place for right cwd';
