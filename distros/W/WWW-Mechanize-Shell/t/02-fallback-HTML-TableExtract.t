use strict;
use Test::More tests => 4;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

SKIP: {
  #skip "Can't load Term::ReadKey without a terminal", 4
  #  unless -t STDIN;

  eval {
    require Test::Without::Module;
    Test::Without::Module->import('HTML::TableExtract')
  };
  skip "Need Test::Without::Module to test the fallback", 4
    if $@;

  #eval { require Term::ReadKey; Term::ReadKey::GetTerminalSize(); };
  #if ($@) {
  #  no warnings 'redefine';
  #  *Term::ReadKey::GetTerminalSize = sub {80,24};
  #  diag "Term::ReadKey seems to want a terminal";
  #};

  use_ok("WWW::Mechanize::Shell");
  my $shell = do {
    WWW::Mechanize::Shell->new("shell", rcfile => undef, warnings => undef );
  };

  isa_ok($shell,"WWW::Mechanize::Shell");
  my $text;

  my $warned;
  {
    local $SIG{__WARN__} = sub {
      $warned = $_[0];
    };

    $shell->option('warnings',1);
    eval {
      $shell->cmd("tables");
    };
  };
  is( $@, '', "No error without HTML::TableExtract");
  my $pass =    ($warned =~ qr'^HTML\W+TableExtract\.pm did not return a true value')
             || ($warned =~ qr!^Can't locate HTML/TableExtract.pm in \@INC!);
  ok $pass, "Missing HTML::TableExtract raises warning"
      or diag "Caught warning '$warned'";
};
