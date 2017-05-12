use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
my $tmpdir = My::CommonTestRoutines->tmpdir;
local *File::Spec::tmpdir = sub { $tmpdir };


use Test::More tests => 6;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  my $o = $class->new;

  my $expire = $o->_time_to_cleanup('testingnonfile');

  ok (! $expire,
      'non-existent file returns false');
}

{
  my $o = $class->new(expire => 2);

  my $file = File::Spec->catfile($tmpdir, 'foo');

  my $fh = IO::File->new(">$file");

  undef $fh;

  my $check1 = $o->_time_to_cleanup($file);

  ok (! $check1,
      'new file returns false');

  sleep 3;

  my $check2 = $o->_time_to_cleanup($file);

  ok ($check2,
      'stale file returns true');
}
