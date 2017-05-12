use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
local *File::Spec::tmpdir = sub { My::CommonTestRoutines->tmpdir };


use Test::More tests => 10;

my $class = qw(WebService::CaptchasDotNet);

use_ok($class);

{
  my $o = $class->new;

  isa_ok($o, $class);

  my $string = $o->random;

  ok ($string,
      "random string '$string' returned");

  like ($string,
        qr/^[a-z0-9]{32}$/,
        'random string is a md5 hash');

  my $string2 = $o->random;

  ok ($string,
      "another random string '$string2' returned");

  isnt ($string,
        $string2,
        'random strings from the same object are not equal');
}

{
  no warnings qw(redefine);
  local *Digest::MD5::hexdigest = sub { 'foo' };

  my $o = $class->new;

  my $string = $o->random;

  ok ($string,
      "random string '$string' returned");

  my $string2 = $o->random;

  ok (! $string2,
      "random string collision returns false");
}
