#!perl -T

use strict;
use warnings;

use Config;

use Test::More;

use lib 't/lib';
use VPIT::TestHelpers;

use Thread::Cleanup;

plan skip_all =>
            'perl on Windows with pseudoforks enabled is required for this test'
            unless $^O eq 'MSWin32' and $Config::Config{d_pseudofork};

my $global_end = 0;
END { ++$global_end }

my $pid = fork;

plan skip_all => 'could not fork' unless defined $pid;

if ($pid) {
 waitpid $pid, 0;
} else {
 plan tests => 4;

 my $gd = 0;
 my $immortal = VPIT::TestHelpers::Guard->new(sub { ++$gd });
 $immortal->{self} = $immortal;

 my $local_end = 0;
 eval 'END { ++$local_end }';

 Thread::Cleanup::register {
  pass               'pseudo-fork destructor called';
  is $local_end,  1, 'pseudo-fork destructor called after local END block';
  is $global_end, 1, 'pseudo-fork destructor called after global END block';
  is $gd,         0, 'pseudo-fork destructor called before global destruction';
 };

 exit;
}
