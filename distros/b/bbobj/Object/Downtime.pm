## $Id: Downtime.pm,v 1.3 2002/07/15 05:11:11 dshanks Exp $

package BigBrother::Object::Downtime;

use 5.006;
use strict;
use warnings;

use Date::Manip qw/ParseDate DateCalc Date_Cmp/;

our $VERSION = '0.50';

=head1 NAME

BigBrother::Object::Downtime - Perl extension for computing Downtime parameters in BigBrother 
monitoring scripts.

=head1 SYNOPSIS

use BigBrother::Object::Downtime;

my $bbdown = new BigBrother::Object::Downtime(
                   downtime_config_filename); 
   $bbdown->is_down($hostname);

=head1 DESCRIPTION

This module was designed to to complement the BigBrother Object module providing an object-oriented 
methodology for reading downtime configurations and determining whether or not a server is in 
scheduled downtime. Currently it works only with the UNIX version, but it should work with cygwin. 
It is loosely based upon BigBrother.pm by Joe Bryant, his module is available at 
http://www.deadcat.net/1/BigBrother.pm.

BigBrother (http://www.bb4.com/) is owned by BB4 Technologies, a part of Quest Software. While 
this software is meant to compliment the tool, it was not developed in cooperation with BB4 
Technologies, and BB4 Technologies has no responsibility for it workings.

For reference, the module was developed against the UNIX Server version 1.9c.

=head1 METHODS

=item new()                           

Create a BigBrother Downtime object. This method reads in the ${BBHOME}/ext/down.cfg and returns 
the object.  If the Config load fails, it returns the Error Message instead of the object.

=over 8

B<Arguements:> none.

B<Returns:> BigBrother Downtime Object.

=back

=cut
sub new {
  my $class = shift;
  my $bbdownfile = shift;

	my $self = bless({BBDOWN => $bbdownfile},$class);

  $self->_init();
  if ($self->{'error_message'}) {
    # if not successful, return the error message
    return $self->{'error_message'};
  } else {
    # if successful, return a blessed object
    return $self;
  }
}

=item is_scheduled()

Retrieves whether or not the host is scheduled for downtime

=over 8

B<Arguements:> The name of the host you want to check.

B<Returns:> A boolean value ( O False; 1 True ) representing whther or not the server is scheduled
for downtime.

=back

=cut
sub is_scheduled {
  my $self = shift();
  my $hostname = shift();
  my $now = ParseDate("now");
  my $downtime = 0;

  my $downtimes = $self->{'DOWNTIMES'}->{$hostname};

  foreach my $entry ( @$downtimes ) {
    if ((Date_Cmp($entry->{'start'},$now)<0) && (Date_Cmp($entry->{'end'},$now)>0)) {
      $downtime = 1;
      last;
    }
  }

  return $downtime;
}

##
#### Private Methods
##

## 
#### _init() 
##
## This method reads the bb downtime config file and stores the information in a hash. THe down.cfg 
## file should be in the format of <hostname>,<duration>,<downtime>. Once instance per line, and 
## servers can be listed multiple times as long as they are one per line. <hostname> is the server
## as listed in the bb-hosts file. <duration> is as it sounds, the duration of the downtime; listed 
## as 'N days N hours N minutes N seconds'. <downtime> is the time when downtime starts, preferably
## localtime format. The parser uses Date::Manip to parse out the dates, so further instructions
## can be found in that module.
##
## Arguements: none.
## Returns: A hash reference with the server downtimes.
##
sub _init {
	my $self = shift();
  my $downcfg = $self->{'BBDOWN'};
  my $now = ParseDate("now");
  my $downtimes = {};

  if ( -r $downcfg ) {
    open DOWN, "$downcfg";
      while ( my $line = <DOWN>) {
        ## chop off the CRs
        chomp($line);
        ## remove anything after a comment
        $line =~ s/#.*//sgi;
        ## if the line is not blank
        if ( $line !~ /^\s*$/ ) {
          my($host,$duration,$when) = ( $line =~ /^(.*?),(.*?),(.*)$/sgi );
          unless ( !$host || !$duration || !$when ) {
            unless ( exists $downtimes->{$host} ) {
              $downtimes->{$host} = [];
            }
            my $dt = {};
            eval {
              $dt->{'start'} = ParseDate($when) or die $!;
              $dt->{'end'} = DateCalc($when,$duration) or die $!;
            };
            if ($@) {
              $self->{'error_message'} = "Downtime Configuration File is invalid";
              last;
            } else {
              push @{$downtimes->{$host}},$dt;
            }
          }
        }
      }
    close DOWN;
  } else {
    $self->{'error_message'} = "Downtime Config file ($downcfg) is not readable";
  }

  $self->{'DOWNTIMES'} = $downtimes;
}

1;
__END__


=head1 AUTHOR

Don Shanks, E<lt>perldev@bpss.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
