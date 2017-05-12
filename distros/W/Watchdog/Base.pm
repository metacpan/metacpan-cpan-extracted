package Watchdog::Base;

use strict;
use Alias;
use base qw(Watchdog::Util);
use vars qw($VERSION $NAME $HOST $PORT $FILE);

$VERSION = '0.09';

=head1 NAME

Watchdog::Base - Watchdog base class

=head1 SYNOPSIS

  use Watchdog::Base;

=head1 DESCRIPTION

B<Watchdog::Base> is the Watchdog base class.

=cut

my %fields = (
	      NAME    => undef,
	      HOST    => 'localhost',
	      PORT    => undef,
	      FILE    => '',
);

=head1 CLASS METHODS

=head2 new($name,$host,$port,$file)

Returns a new B<Watchdog::Base> object.  I<$name> is a string which
will identify the service to a human.  I<$host> is the name of the
host providing the service (default is 'localhost').  I<$port> is the
port on which the service listens.

=cut

sub new($$$) {
  my $DEBUG = 0;
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, },$class;
  attr $self;

  print STDERR "Watchdog::Base::new() $NAME $HOST $PORT $FILE\n" if $DEBUG;
  my $arg;
  for (\$NAME,\$HOST,\$PORT,\$FILE) {
    $$_ = $arg if $arg = shift;
  }
  print STDERR "Watchdog::Base::new() $NAME $HOST $PORT $FILE\n" if $DEBUG;

  return $self;
}
1;

#------------------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 id()

Return a string describing the name of a service and the host (and
optionally the port) on which it runs.

=cut

sub id() {
  my $self = attr shift;
  my $id = "$NAME\@$HOST";
  $id .= ":$PORT" if defined($PORT);
  $id .= "/$FILE" if ($FILE eq '');
  return $id;
}

#------------------------------------------------------------------------------

=head1 AUTHOR

new Maintainer: Clemens Gesell E<lt>clemens.gesell@vegatron.orgE<gt> 

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
