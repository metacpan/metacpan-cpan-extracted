use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
local *File::Spec::tmpdir = sub { My::CommonTestRoutines->tmpdir };


use Test::More tests => 5;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  isa_ok($o, $class);

  my $random = 'RandomZufall';

  my $url = $o->url($random);

  is ($url,
      'http://image.captchas.net/?client=demo&amp;random=RandomZufall',
      'url() generates the proper URL');
}
