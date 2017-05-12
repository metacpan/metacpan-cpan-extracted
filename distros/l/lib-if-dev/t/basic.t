use strict;
use warnings;

use Test::More 0.88;
use File::chdir;
use List::AllUtils qw{ any none };

subtest none_matched             => sub { _fail('none')        };
subtest 'only lib/'              => sub { _fail('justlib')     };
subtest 'only dist.ini'          => sub { _fail('justdistini') };
subtest 'matches on Makefile.PL' => sub { _pass('makefile')    };
subtest 'matches on Build.PL'    => sub { _pass('build')       };
subtest 'matches on dist.ini'    => sub { _pass('dist')        };

done_testing;

sub _pass {
    my ($dir) = @_;

    ok do { none { $_ eq 'lib' } @INC }, 'sanity check: lib not in @INC';
    local $CWD = "t/$dir";
    local @INC = (@INC, '../../lib');

    delete $INC{'test.pl'};
    require 'test.pl';

    ok do { any { $_ eq 'lib' } @INC }, 'lib is in @INC';
}

sub _fail {
    my ($dir) = @_;

    ok do { none { $_ eq 'lib' } @INC }, 'sanity check: lib not in @INC';
    local $CWD = "t/$dir";
    local @INC = (@INC, '../../lib');

    delete $INC{'test.pl'};
    require 'test.pl';

    ok do { none { $_ eq 'lib' } @INC }, 'lib is in @INC';
}

