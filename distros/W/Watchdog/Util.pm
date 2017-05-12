=head1 NAME

Watchdog::Util - Watchdog utility functions

=head1 SYNOPSIS

  use Watchdog::Util;

=head1 DESCRIPTION

=cut

package Watchdog::Util;

use strict;
use vars qw($AUTOLOAD $conf);
use Getopt::Long;
#use Log::Service;

my $dir        = '/usr/local/watchdog';
my $status_dir = "$dir/status";
$conf          = "$dir/watchdog.conf";

#------------------------------------------------------------------------------

sub AUTOLOAD {
  my $self  = shift;
  my $type  = ref($self) or die "$self is not an object";

  my $name = $AUTOLOAD;
  $name =~ s/.*://;     # strip fully-qualified portion

  # accessor methods
  $name = uc($name);
  return if ( $name eq 'DESTROY' );  # don't catch 'DESTROY'
  unless ( exists $self->{_PERMITTED}->{$name} ) {
    die "Can't access `$name' field in class $type";
  }
  return @_ ? $self->{$name} = shift : $self->{$name};
}

#------------------------------------------------------------------------------

#=head2 init_dog($host,$service,$frequency)

#Returns the number of seconds that a watchdog should sleep between
#polling its service based on I<$frequency> and a B<Log::Service>
#object configured to log to the file I<$status_dir/$service.$host>.

#=cut

#sub init_dog($$$) {
#  my($host,$service,$frequency) = @_;
#  my($sleep,$opt_frequency);

#  if ( defined($frequency) ) {
#    my %units = ( 's' => 1, 'm' => 60 );
#    $frequency =~ /^(\d+)([m|s])$/ || die("Invalid frequency: $frequency");
#    $sleep = $1 * $units{$2};
#  } else {
#    $sleep = 60;
#  }

#  my $status = "$status_dir/$service.$host";
  #my %stream = ( 'status' => new Log::File($status,"w") );
  #my $logger = new Log::Service($service,\%stream);
  # set hostname where service we're watching is running
  #$logger->host->name($host);

  #return($sleep,$logger);
#}

#------------------------------------------------------------------------------

=head1 AUTHOR

Paul Sharpe I<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
