# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 5;

BEGIN { $SIG{__DIE__}  = sub { $legacy_err  = 1; } }
BEGIN { $SIG{__WARN__} = sub { $legacy_warn = 1; } }

BEGIN { use_ok 'Tk::Carp' };

sub my_tkdie {
  $last_err = $_[0];
  $old_tkdie->(@_);
}

sub my_tkwarn {
  $last_warn = $_[0];
  $old_tkwarn->(@_);
}

sub my_dodialog {
  # Don't do it
}

{
  no warnings;
  $old_tkdie  = \&Tk::Carp::tkdie;
  $old_tkwarn = \&Tk::Carp::tkwarn;
  *{'Tk::Carp::tkdie'}    = \&my_tkdie;
  *{'Tk::Carp::tkwarn'}   = \&my_tkwarn;
  *{'Tk::Carp::dodialog'} = \&my_dodialog;
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
  local $Tk::Carp::FatalsToDialog = 1;
  eval { die "Fatals to dialog\n" };
  is($last_err, "Fatals to dialog\n", "Fatals to dialog");
}

{
  local $Tk::Carp::WarningsToDialog = 1, $Tk::Carp::ImmediateWarnings = 1;
  warn "Warnings to dialog\n";
  is($last_warn, "Warnings to dialog\n", "Warnings to dialog");
}
