# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 5;

BEGIN { $SIG{__DIE__}  = sub { $legacy_err  = 1; } }
BEGIN { $SIG{__WARN__} = sub { $legacy_warn = 1; warn @_ } }

BEGIN { use_ok 'Win32::GUI::Carp' };

sub my_dodialog {
  $last_err = $_[0];
}

{
  no warnings;
  *{'Win32::GUI::Carp::dodialog'} = \&my_dodialog;
}


# Tests...

{
  local $legacy_err, $legacy_warn;
  warn "Legacy\n";
  eval { die "Legacy\n" };
  is($legacy_err,  1, "Legacy death");
  is($legacy_warn, 1, "Legacy warning");
}

{
  local $Win32::GUI::Carp::FatalsToDialog = 1;
  eval { die "Fatals to dialog\n" };
  is($last_err, "Fatals to dialog\n", "Fatals to dialog");
}

{
  local $Win32::GUI::Carp::WarningsToDialog  = 1;
  local $Win32::GUI::Carp::ImmediateWarnings = 1;
  warn "Warnings to dialog\n";
  is($last_err, "Warnings to dialog\n", "Warnings to dialog");
}
