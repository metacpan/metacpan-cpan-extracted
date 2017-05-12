package Win32::RemoteTOD;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ();
our @EXPORT_OK = qw( GetTOD );
our @EXPORT = qw( GetTOD );
our $VERSION = '1.00';

bootstrap Win32::RemoteTOD $VERSION;

1;
__END__

=head1 NAME

Win32::RemoteTOD - Get the time & timezone of a remote Win32 machine

=head1 SYNOPSIS

	use strict;
	use Win32::RemoteTOD qw(GetTOD);

	my $TimeInfo;
	my $Result = GetTOD('servername', $TimeInfo);

	if ($Result) {
		print "Error: $Result\n";
		exit 1;
	}

	my @days = qw( Sunday Monday Tuesday Wednesday 
					Thursday Friday Saturday );

	printf("Date/Time is %s %02u/%02u/%02u %02u:%02u:%02u.%02u GMT.\n",
		$days[$TimeInfo->{weekday}],
		$TimeInfo->{month},
		$TimeInfo->{day},
		$TimeInfo->{year},
		$TimeInfo->{hours},
		$TimeInfo->{mins},
		$TimeInfo->{secs},
		$TimeInfo->{hunds},
	);
	if ($TimeInfo->{timezone} == -1) {
		print "The timezone is undefined.\n";
	}
	elsif ($TimeInfo->{timezone} == 0) {
		print "The timezone is GMT.\n";
	}
	else {
		printf("The timezone is %u minutes %s of GMT.\n",
			abs($TimeInfo->{timezone}),
			$TimeInfo->{timezone} > 0 ? 'west' : 'east',
		);
	}

=head1 DESCRIPTION

Win32::RemoteTOD is used to retreive the date, time, and timezone from a
remote Win32 machine.  There is one function, called "GetTOD()" which 
sets a hashref containing 12 keys as follows (direct from MSDN):

=head2 Hashref keys

=over

=item elapsedt

Specifies a DWORD value that contains the number of seconds since 00:00:00,
January 1, 1970, GMT. 

=item msecs

Specifies a DWORD value that contains the number of milliseconds from an
arbitrary starting point (system reset).  Typically, this member is read
twice, once when the process begins and again at the end.  To determine
the elapsed time between the process's start and finish, you can subtract
the first value from the second.

=item hours

Specifies a DWORD value that contains the current hour. Valid values are
0 through 23. 

=item mins

Specifies a DWORD value that contains the current minute. Valid values are
0 through 59. 

=item secs

Specifies a DWORD value that contains the current second. Valid values are
0 through 59. 

=item hunds

Specifies a DWORD value that contains the current hundredth second (1.00
second). Valid values are 0 through 99. 

=item timezone

Specifies the time zone of the server. This value is calculated, in minutes,
from Greenwich Mean Time (GMT).  For time zones west of Greenwich, the value
is positive; for time zones east of Greenwich, the value is negative.
A value of -1 indicates that the time zone is undefined. 

=item tinterval

Specifies a DWORD value that contains the time interval for each tick of the
clock.  Each integral integer represents one ten-thousandth second (0.0001
second). 

=item day

Specifies a DWORD value that contains the day of the month. Valid values are
1 through 31. 

=item month

Specifies a DWORD value that contains the month of the year. Valid values are
1 through 12. 

=item year

Specifies a DWORD value that contains the year. 

=item weekday

Specifies a DWORD value that contains the day of the week. Valid values are
0 through 6, where 0 is Sunday, 1 is Monday, and so on. 

=back

=head2 

=head2 EXPORT

The single function, GetTOD() is exported by default.

=head1 AUTHOR

Adam Rich, <arich@cpan.org>

=head1 SEE ALSO

L<perl>.

=cut
