use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
local *File::Spec::tmpdir = sub { My::CommonTestRoutines->tmpdir };


use Test::More tests => 18;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  my $o = $class->new;

  isa_ok($o, $class);

  ok (exists $o->{_secret},
      "private attribute '_secret' exists");

  ok (! defined $o->{_secret},
      "private attribute '_secret' is undef");

  ok (exists $o->{_uid},
      "private attribute '_uid' exists");

  ok (! defined $o->{_secret},
      "private attribute '_uid' is undef");

  is ($o->{_expire},
      3600,
      "private attribute '_expire' set to 3600");
}

{
  my $o = $class->new(secret => 'mysecret');

  isa_ok($o, $class);

  is ($o->{_secret},
      'mysecret',
      "private attribute '_secret' properly populated");

  ok (exists $o->{_uid},
      "private attribute '_uid' exists");

  ok (! defined $o->{_uid},
      "private attribute '_uid' is undef");

  is ($o->{_expire},
      3600,
      "private attribute '_expire' set to 3600");
}

{
  my $o = $class->new(secret   => 'mysecret',
                      username => 'demo',
                      expire   => 1800);

  isa_ok($o, $class);

  is ($o->{_secret},
      'mysecret',
      "private attribute '_secret' properly populated");

  is ($o->{_uid},
      'demo',
      "private attribute '_uid' properly populated");

  is ($o->{_expire},
      1800,
      "private attribute '_expire' set to 1800");
}
