package Alarm::_TieSIG;

$VERSION = 1.0;

=head1 NAME

Alarm::_TieSIG - Module handling tying of %SIG for alarm extensions.

=head1 DESCRIPTION

This is an internal utility module for use with the Alarm::*
alarm extensions, that handles tying of the Perl built-in
variable C<%SIG>.  This is deep magic and you use this module
at your own risk.

To use this class, simply C<use> it and then call the
C<Alarm::_TieSIG::tiesig()> function.  This replaces C<%SIG> with a dummy tied 
hash.

Whenever the new C<%SIG> is accessed, this class checks to see
if the requested key is ALRM.  If so, it calls C<sethandler()>
for STORE's, and C<gethandler()> for FETCHes.  You must provide
both of these methods in your package.

All other operations are passed on to the original, magic C<%SIG>.

Note: Do I<not> call C<tiesig()> more than once.  Doing so
produces a warning and no other effects.

=head1 EXAMPLE

The following code will disable, with warnings, attempts to
set SIGALRM handlers in your program (although it's not
impossible to get past if someone really wanted to):

  use Alarm::_TieSIG;
  Alarm::_TieSIG::tiesig();

  sub sethandler {
    warn "\$SIG{ALRM} has been disabled.\n";
  }

  sub gethandler {
    warn "\$SIG{ALRM} has been disabled.\n";
  }

=head1 DISCLAIMER

This module is not guaranteed to work.  In fact, it will probably
break at the most inconvient time.  If this module breaks your
program, destroys your computer, ruins your life, or otherwise
makes you unhappy, do I<not> complain (especially not to me).
It's your own fault.

=head1 AUTHOR

Written by Cory Johns (c) 2001.

=cut

use strict;
use Carp;

use vars qw($realSig);

sub tiesig {
  if($realSig) {
    carp "Attempt to re-tie %SIG";
    return;
  }

  $realSig = \%SIG;  # Save old %SIG.
  *SIG = {};         # Replace %SIG with a dummy.

  my $userPkg = caller;
  return tie %SIG, __PACKAGE__, $userPkg, @_;
}

sub _setAlrm {
  $realSig->{ALRM} = shift;
}

sub TIEHASH {
  return bless {'userPkg'=>$_[1]}, shift;
}

sub STORE {
  my ($self, $key, $value) = @_;

  if($key eq 'ALRM') {
    no strict 'refs';
    &{"$self->{userPkg}::sethandler"}($value);
  } else {
    $realSig->{$key} = $value;
  }
}

sub FETCH {
  my ($self, $key) = @_;

  if($key eq 'ALRM') {
    no strict 'refs';
    &{"$self->{userPkg}::gethandler"}();
  } else {
    return $realSig->{$key};
  }
}

sub EXISTS {
  return exists $realSig->{$_[1]};
}

sub DELETE {
  return delete $realSig->{$_[1]};
}

sub CLEAR {
  return %$realSig = ();
}

sub FIRSTKEY {
  return each %$realSig;
}

sub NEXTKEY {
  return each %$realSig;
}

sub DESTROY {
}

1;
