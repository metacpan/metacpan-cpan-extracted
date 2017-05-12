package Watchdog::Process;

use strict;
use Alias;
use Proc::ProcessTable;
use base qw(Watchdog::Base);
use vars qw($NAME $PSTRING $HOST $PORT);

=head1 NAME

Watchdog::Process - Check for process in process table

=head1 SYNOPSIS

  use Watchdog::Process;
  $s = new Watchdog::Process($name,$pstring);
  print $s->id, $s->is_alive ? ' is alive' : ' is dead', "\n";

=head1 DESCRIPTION

B<Watchdog::Process> is an extension for monitoring processes running
on a Unix host.  The class provides a trivial method for determining
whether a service is alive.  I<This class has only been successfully
tested on Solaris 2.6>.

=cut

my %fields = ( PSTRING => undef, );

=head1 CLASS METHODS

=head2 new($name,$pstring)

Returns a new B<Watchdog::Process> object.  I<$name> is a string which
will identify the service to a human.  I<$pstring> is a string which
can be used to identify a process in the process table.

=cut

sub new($$) {
  my $DEBUG = 0;
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self  = bless($class->SUPER::new(shift,undef,undef),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->{PSTRING} = shift;

  return $self;
}

#------------------------------------------------------------------------------

=head2 is_alive()

Returns true if the service is alive, else false.

=cut

sub is_alive() {
  my $DEBUG = 0;
  my $self = attr shift;
  my $t    = new Proc::ProcessTable;

  for ( @{$t->table} ) {
    # Proc::ProcessTable::Process::cmndline() seems to return
    # undefined sometimes.  Bug reported to author.
    my $cmndline = $_->cmndline;
    print STDERR "\$cmndline = $cmndline\n" if $DEBUG;
    return 1 if defined($cmndline) && $cmndline =~ /$PSTRING/;
  }
  return 0;
}

#------------------------------------------------------------------------------

=head1 BUGS

This class is I<unreliable> on Linux as
B<Proc::ProcessTable::Process::cmndline()> sometimes returns undef.

=head1 SEE ALSO

L<Proc::ProcessTable>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
