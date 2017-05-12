# -*- mode:cperl;indent-tabs-mode:nil;comment-column:40;perl-indent-level:2 -*-
#
# SecretPipe.pm - A place to hide a secret
#
# Copyright (C) 1999 by St. Alphonsos.  All Rights Reserved.
#
# Time-stamp: <2006-12-01 16:29:26 attila@stalphonsos.com>
# $Id: SecretPipe.pm,v 1.1.1.1 2006/06/26 16:42:00 attila Exp $
#
# bsy's dumb pipe password trick in perl, but really not as good.
#
package Flail::SecretPipe;
require 5.000;
use IO::Handle;

# new - constructor
#
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  local *R;
  local *W;
  pipe(R, W) || die "could not create pipe: $!\n";
  W->autoflush(1);
  $self->{R} = *R;
  $self->{W} = *W;
  $self->{n} = 0;
  bless($self, $class);
  return $self;
}

# finish - close down
#
sub finish {
  my $self = shift(@_);
  close($self->{R});
  close($self->{W});
  $self->{R} = undef;
  $self->{W} = undef;
  $self->{n} = 0;
  return $self;
}

sub reset {
  my $self = shift(@_);
  $self->finish();
  local *R;
  local *W;
  pipe(R, W) || die "could not create pipe: $!\n";
  W->autoflush(1);
  $self->{R} = \*R;
  $self->{W} = \*W;
  $self->{n} = 0;
  return $self;
}

# hide - hide a secret in the pipe
#
sub hide {
  my $self = shift(@_);
  my $w = $self->{W};
  my $x;
  while (defined($x = shift(@_))) {
    chomp($x);
    print $w "$x\n";
    # What to do about troubling $x floating around? This should really
    # be done in XS so we could erase it for real (I think)...
    ++$self->{n};
  }
  return $self;
}

# reveal - reveal the most recent secret
#
sub reveal {
  my $self = shift(@_);
  my $r = $self->{R};
  return undef unless $self->{n} > 0;
  my $x = <$r>;
  --$self->{n};
  chomp($x);
  return $x;
}

1;

__END__

=pod

=head1 NAME

Flail::SecretPipe - A pipe in which to hide secrets

=head1 SYNOPSIS

 use Flail::SecretPipe;
 $sp = Flail::SecretPipe->new;
 $sp->hide("first secret");
 $sp->hide("second secret");
 $sp->hide("third secret");
 $x = $sp->reveal;  # will read back first secret
 $x = $sp->reveal;  # will read back second secret
 $sp->reset;        # will forget third secret

=head1 DESCRIPTION

This is a poor implementation of a simple trick due to Bennet Yee
(bsy@cs.ucsd.edu).  The idea is to use the Kernel's buffer pool to hide a
secret from prying eyes, since you have to be root to get at it.  Of course,
in this day and age of common remote root exploits, this doesn't seem as
comforting as it once did, but it's still a reasonable short-term deterrent
on a machine being used by more than one person that doesn't happen to be
owned.

The basic idea is that you create a pipe, write a password on the write end
of it, and then when you need it, read it back on the read end.  Obviously,
this trick only really works if you can guarantee that you've erased the
password from memory in the interim, and only keep it around in plaintext as
long as you have to, and even then if an attacker has the ability to make
your process dump core and times it just right, they win.  The pipe trick is
really meant for long-running processes (like mail checkers) that need to
use a password infrequently, but in a context in which it is inconvenient to
have you type it.  They squirrel the password away in the pipe (which is
in the kernel's memory address space), and read it back when they need it.

As humble as this trick is, this implementaton is still shoddy, because
there's no way in Perl to guarantee that the characters in the string you
pass in get zapped.  To do a proper job of this, I should rewrite it in XS
and provide a primitive to zero the contents of a string for real.

=head1 METHOD DESCRIPTIONS

=over

=item *

F<new>: construct a new SecretPipe.  Takes no arguments.

=item *

F<finish>: closes a SecretPipe's file descriptors and sets the counter
of secrets it contains to zero.

=item *

F<hide>: hides a new secret into the pipe.

=item *

F<reveal>: read back the next secret from the pipe (in FIFO order).

=item *

F<reset>: calls F<finish> and then creates a new, empty pipe.

=back

=head1 AUTHORS

Sean Levy <snl@stalphonsos.com>

=head1 SEE ALSO

=over

=item *

perl(1).

=back

=cut
