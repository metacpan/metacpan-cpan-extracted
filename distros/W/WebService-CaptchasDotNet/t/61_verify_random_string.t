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
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  isa_ok($o, $class);

  ok (! $o->_verify_random_string,
      'no random string to verify returns false');
}

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  my $random = 'foobar';

  ok (! $o->_verify_random_string($random),
      "non-md5 random string '$random' returns false");
}

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  my $random = '2639ad44688295f36bbfe9d3e1eadc18';

  ok (! $o->_verify_random_string($random),
      "random md5 random string '$random' returns false");
}

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  my $random = $o->random;

  my $file = $o->_verify_random_string($random);

  like ($file,
        qr!^\Q$tmpdir\E.CaptchasDotNet.\w+!,
        "random string '$random' returns '$file'");
}

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo');

  chmod 0000, $tmpdir;

  my $random = $o->random;

  ok (! $o->_verify_random_string($random),
      "non-writable directory returns false");

  chmod 0777, $tmpdir;
}

{
  my $o = $class->new(secret   => 'secret',
                      username => 'demo',
                      expire   => 2);

  my $random = $o->random;

  ok ($o->_verify_random_string($random),
      'random string verifies');

  sleep 3;

  ok (! $o->_verify_random_string($random),
      "stale random file does not verify");
}
