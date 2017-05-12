## $Id: Object.pm,v 1.2 2002/07/14 06:36:42 dshanks Exp $

package BigBrother::Object;

use 5.006;
use strict;
use warnings;

use BigBrother::Object::Config;

our $VERSION = '0.50';

=head1 NAME

BigBrother::Object - Perl extension for common functionality in BigBrother monitoring scripts.

=head1 SYNOPSIS

use BigBrother::Object;

my $bb = new BigBrother::Object(); 
   $bb->send_to_bbout($filename,$message);
   $bb->send_to_bbdisplay($testname,$color,$status);
   $bb->send_to_bbpager($status);

=head1 DESCRIPTION

This module was designed to provide an object-oriented methodology for using PERL scripts within 
the BigBrother System and Network-based monitoring system. Currently it works only with the UNIX 
version, but it should work with cygwin. It is loosely based upon BigBrother.pm by Joe Bryant, 
his module is available at http://www.deadcat.net/1/BigBrother.pm.

During installation, configure.pl should be run. This will create the file Config.pm from the 
bbdef.sh, bbinc.sh, and bbsys.sh files. The configure script can and should be run again should 
you update any of these settings.The module provides easy access to the BB configuration values and
the bb-hosts file values. It also provides methods for sending status reports and pages through the 
bb binary itself as well as debug output to the standard BBOUT filehandle.

BigBrother (http://www.bb4.com/) is owned by BB4 Technologies, a part of Quest Software. While 
this software is meant to compliment the tool, it was not developed in cooperation with BB4 
Technologies, and BB4 Technologies has no responsibility for it workings.

For reference, the module was developed against the UNIX Server version 1.9c.

=head1 METHODS

=item new()                           

Create a BigBrother object. This method reads in the Config.pm and returns the object. 
If the Config load fails, it returns the Error Message instead of the object.

=over 8

B<Arguements:> none.

B<Returns:> BigBrother Object.

=back

=cut
sub new {
  my $class = shift;
	my $self = bless({},$class);
	my $init_success = $self->_init();
	if ($init_success) {
    # if successful, return a blessed object
		return $self;
	} else {
    # if not successful, return the error message
		return $self->{'error_message'};
	}
}

=item get_bbenv()

Gets a hash of the BigBrother config variables.

=over 8

B<Arguements:>  key for the variable wanted or none.

B<Returns:> If a key is passed the result is the value paired with that key, else a hash reference 
containing the BigBrother definitions.

=back

=cut
sub get_bbenv {
	my $self = shift();
  my $key = shift();
  if ($key) {
    return $self->{'ENV'}->{$key};
  } else {
    return $self->{'ENV'};
  }
}

=item get_file()

Gets a text file contents.

=over 8

B<Arguements:> System name of the filename.

B<Returns:> The contents of the file in list or scalar context.

=back

=cut
sub get_file {
	my $filename = shift();
	my @file;
	open FH, $filename;
		@file = <FH>;
		chomp @file;
	close FH;
	return (wantarray) ? @file : join('',@file);
}

=item send_to_bbout()

Append data to a filehandle defined as BBOUT in the BB environment variables.

=over 8

B<Arguements:> Name of the running script; Text to print out.

B<Returns:> Error message if failed.

=back

=cut
sub send_to_bbout {
	my $self = shift();
	my $filename = shift();
	my $message = shift();
	my $datestmp = qx/date/;
	  chomp $datestmp;

	eval {
		open FH, ">>$self->{'ENV'}->{'BBOUT'}" or die $!;
			print FH qq|$datestmp $filename $message\n| or die $!;
		close FH or die $!;
	};
	return ($@) ? $@ : 0;
}

=item send_to_bbdisplay()

Send status data to BBDISPLAY as defined in the BB environment variables.

=over 8

B<Arguements:> Name of the running test; Color code of the message; Status to print out.

B<Returns:> Error code if failed.

=back

=cut
sub send_to_bbdisplay {
	my $self     = shift();
	my $testname = shift();
	my $color    = lc(shift());
	my $status   = shift();
	my $EXITCODE;

	my $env = $self->{'ENV'};
	my $date = qx/date/;
		chomp $date;
	
  # Build the command to report to Big Brother
  my $BBCMD= qq|$env->{'BB'} $env->{'BBDISP'} "status $env->{'MACHINE'}.$testname $color $date $status"|;
	$EXITCODE = system($BBCMD);
	return $EXITCODE;
}

=item send_to_bbpager()

Send status data to BBPAGER as defined in the BB environment variables. The method checks 
the DFPAGE variable to ensure pages are used.

=over 8

B<Arguements:> Status to send to pager.

B<Returns:> Error code if failed.

=back

=cut
sub send_to_bbpager {
	my $self     = shift();
	my $status   = shift();
	my $EXITCODE;

	my $env = $self->{'ENV'};
	my $date = qx/date/;
		chomp $date;

	if ( $env->{'DFPAGE'} eq 'Y' ) {
		# Build the command to report to Big Brother Pager
		my $BBCMD= qq|$env->{'BB'} $env->{'BBPAGE'} "page $env->{'MACHIP'} $status"|;
		$EXITCODE = system($BBCMD);
	}
	return $EXITCODE;
}

=item get_bbhost_ip()

Retrieves the IP Address for a given hostname within the BBHOSTS file.

=over 8

B<Arguements:> Hostname of bb-hosts server.

B<Returns:> IP Address for bb-hosts server or undef if server does not exist.

=back

=cut
sub get_bbhost_ip {
   my $self = shift();
   my $hostname = shift();

   my $hosts = $self->{'BBHOSTS'};

   return $hosts->{$hostname}->{'IP'};
}

=item get_bbhost_svcs()

Retrieves a list of the services for a given hostname within the BBHOSTS file.

=over 8

B<Arguements:> Hostname of bb-hosts server.

B<Returns:> A reference to the list of services for bb-hosts server or undef if server does not exist.

=back

=cut
sub get_bbhost_svcs {
   my $self = shift();
   my $hostname = shift();

   my $hosts = $self->{'BBHOSTS'};

   return $hosts->{$hostname}->{'SVCS'};
}

=item get_bbhost_name()

Retrieves the hostname for a given host IP within the BBHOSTS file.

=over 8

B<Arguements:> IP Address of bb-hosts server.

B<Returns:> The hostname for the bb-hosts server or undef if server does not exist.

=back

=cut
sub get_bbhost_name {
   my $self = shift();
   my $hostip = shift();
   my $hostname = undef;

   my $hosts = $self->{'BBHOSTS'};

   foreach my $host ( keys %$hosts ) {
     if ( $hosts->{$host}->{'IP'} eq $hostip ) {
       $hostname = $host;
       last;
     }
   }

   return $hostname;
}

##
#### Private Methods
##

## 
#### _init() 
##
## This method performs the initialization of the object. It reads the Config.pm for BB configuration
## variables. The Config.pm is a generated file, use configure.pl to generate the Config.pm. 
##
sub _init {
	my $self = shift();
	$self->{'ENV'} = new BigBrother::Object::Config();
	if ( -e $self->{'ENV'}->{'BBHOSTS'} ) {
		$self->{'BBHOSTS'} = _read_bbhosts($self->{'ENV'}->{'BBHOSTS'});
	} else {
		$self->{'error_message'} = "BBHOSTS does not exist";
		return 0;
	}
	return 1;
}

##
#### _read_bbhosts()
##
## This method reads the bbhosts file and stores the information in a hash. The information can be
## retrieved using the getters 
##
sub _read_bbhosts {
	my $bbhosts = shift();
	my $hosts = {};
	my @tmpHosts = get_file($bbhosts);
	foreach my $h ( @tmpHosts ) {
		if ( $h !~ /^group/ && $h !~ /^\s*#/ && $h !~ /^\s*$/ ) {
			my ($ip,$host,$svcs) = ( $h =~ /^\s*?([\d\.]*)\s*(.*?)\s*#\s*(.*)$/ );
			my @svc_list = split(/\s/,$svcs);
			$hosts->{$host}->{'IP'} = $ip;
			$hosts->{$host}->{'SVCs'}= \@svc_list;
		}
	}
	return $hosts;
}

1;
__END__


=head1 AUTHOR

Don Shanks, E<lt>perldev@bpss.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
