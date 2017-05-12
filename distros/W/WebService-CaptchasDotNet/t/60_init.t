use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
local *File::Spec::tmpdir = sub { My::CommonTestRoutines->tmpdir };


use Test::More tests => 7;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  my $dir = File::Spec->catfile(My::CommonTestRoutines->tmpdir,
                                'CaptchasDotNet');

  ok (! -e $dir, "$dir does not exist");

  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  isa_ok($o, $class);

  ok (-e $dir, "$dir created");

  is ($o->{_tempdir},
      $dir,
      'private _tempdir attribute properly set');

  $o->_init;
}
