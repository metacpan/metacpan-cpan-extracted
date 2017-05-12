use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
local *File::Spec::tmpdir = sub { My::CommonTestRoutines->tmpdir };


use Test::More tests => 6;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  my $expire = $o->expire;

  is ($expire,
      3600,
      'default value 3600 returned');

  my $new = $o->expire(1800);

  is ($new,
      1800,
      'new value returned from set');

  my $current = $o->expire;

  is ($current,
      1800,
      'new value returned from get');
}
