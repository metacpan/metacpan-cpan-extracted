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


use Test::More tests => 11;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  no warnings qw(redefine);
  local *Digest::MD5::hexdigest = sub { 'cleantest' };

  # create the directory
  my $o = $class->new(expire => 2);

  my $file = File::Spec->catfile($tmpdir,
                                 qw(CaptchasDotNet cleantest));

  ok (! -e $file,
      'cache file does not exist');

  # put a known random file in it
  my $random = $o->random;

  ok (-e $file,
      'cache file exists');

  sleep 3;

  $o->_cleanup();

  ok (-e $file,
      'cache file was not removed - not a hex file');
}

{
  no warnings qw(redefine);
  local *Digest::MD5::hexdigest = sub { 'b77a27f12f2fb0e1b65ba560659640aa' };

  # create the directory
  my $o = $class->new(expire => 2);

  my $file = File::Spec->catfile($tmpdir,
                                 qw(CaptchasDotNet b77a27f12f2fb0e1b65ba560659640aa));

  ok (! -e $file,
      'cache file does not exist');

  # put a known random file in it
  my $random = $o->random;

  ok (-e $file,
      'cache file exists');

  sleep 3;

  $o->_cleanup();

  ok (! -e $file,
      'cache file removed');
}

{
  my $o = $class->new(expire => 2);

  chmod 0000, $tmpdir;

  my $rc = $o->_cleanup();

  ok (! $rc,
      'unreadable directory returns false');

  chmod 0777, $tmpdir;

  $rc = $o->_cleanup();

  ok ($rc,
      'readable directory returns true');
}
