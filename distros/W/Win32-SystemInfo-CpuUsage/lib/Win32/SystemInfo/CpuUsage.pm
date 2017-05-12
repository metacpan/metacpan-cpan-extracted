package Win32::SystemInfo::CpuUsage;

use 5.008003;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::SystemInfo::CpuUsage ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Win32::SystemInfo::CpuUsage::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Win32::SystemInfo::CpuUsage', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Win32::SystemInfo::CpuUsage - Perl extension for getting CPU Usage in percentage

=head1 SYNOPSIS

  use Win32::SystemInfo::CpuUsage;
  my $intvl = 1000;	# in milliseconds
  my $usage = Win32::SystemInfo::CpuUsage::getCpuUsage($intvl);
  
  my $i = 0;
  while($i < 5){	#query 5 times
  	$i++;
  	$usage = Win32::SystemInfo::CpuUsage::getCpuUsage($intvl);
  	print "$i: cpu usage $usage\n";
  }

=head1 DESCRIPTION

In windows, there is no tool for querying CPU usage and print it in DOS prompt. 

Win32::SystemInfo::CpuUsage is designed for monitoring CPU usage and return the value in percentage.
To calculate the percentage, it needs an interval of twice retrieving CPU info.

=head1 METHODS

=over 8

=item Win32::SystemInfo::CpuUsage::getCpuUsage($intvl)

Get CPU's Usage in Percentage

    Args:

	$intvl		interval for getting CPU info. 1000 means 1 second

Returns CPU's usage in percentage

=back

=head1 SUMMARY

The returned CPU usage number doesn't match the number exactly shown in task manager, 
because of the interval setting and CPU query timing. But the numbers can be very close after tuning.

=head1 AUTHOR

Jing Kang E<lt>kxj@hotmail.comE<gt>

=cut
