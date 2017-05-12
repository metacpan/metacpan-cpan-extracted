use strict;
use warnings FATAL => qw(all);

use Cwd qw(cwd);
use File::Spec ();

use lib File::Spec->catfile(cwd, qw(t lib));
use My::CommonTestRoutines;

# localize tmpdir to our test directory
no warnings qw(once);
local *File::Spec::tmpdir = sub { My::CommonTestRoutines->tmpdir };


use Test::More tests => 12;

my $class = qw(My::EmptySubclass);

use_ok($class);

my $random = '9ce6504a9e74713662717c613cd49226';  # yelzja

{
  my $o = $class->new;

  my $ok = $o->verify('yelzja', $random);

  ok (! $ok,
      'no secret');
}

my $o = $class->new(secret   => 'secret',
                    username => 'demo');

{
  my $ok = $o->verify;

  ok (! $ok,
      'no captcha or random arguments');
}

{
  my $ok = $o->verify('yelzja');

  ok (! $ok,
      'no random argument');
}

{
  my $ok = $o->verify(undef, $random);

  ok (! $ok,
      'no input argument');
}

{
  my $ok = $o->verify('wvphn', $random);

  ok (! $ok,
      'improper captcha length');
}

{
  my $ok = $o->verify('wvph1h', $random);

  ok (! $ok,
      'improper captcha contents');
}

{
  my $ok = $o->verify('yelzja', 'RandomZufall');

  ok (! $ok,
      'captcha match but no sanity file');
}

{
  my $file = File::Spec->catfile(My::CommonTestRoutines->tmpdir,
                                 qw(CaptchasDotNet), $random);

  my $fh = IO::File->new(">$file");
  undef $fh;

  {
    my $ok = $o->verify('yelzjj', $random);

    ok (! $ok,
        'captcha mismatch');
  }

  {
    my $ok = $o->verify('yelzja', $random);

    ok ($ok,
        'captcha match');
  }
}
