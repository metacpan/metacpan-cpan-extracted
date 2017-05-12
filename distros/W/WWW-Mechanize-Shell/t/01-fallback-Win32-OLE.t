use strict;
use Test::More tests => 3;

# Disable all ReadLine functionality

SKIP: {
  $ENV{PERL_RL} = 0;
  eval {
    require Test::Without::Module;
    Test::Without::Module->import('Win32::OLE')
  };
  skip "Need Test::Without::Module to test the fallback", 3
    if $@;

  use_ok("WWW::Mechanize::Shell");
  my $shell = do {
    WWW::Mechanize::Shell->new("shell", rcfile => undef, warnings => undef );
  };

  isa_ok($shell,"WWW::Mechanize::Shell");
  my $browser;

  eval {
    $browser = $shell->browser;
  };
  is( $@, '', "No error without Win32::OLE");
};
