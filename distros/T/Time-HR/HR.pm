package Time::HR;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Time::HR ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	gethrtime
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	gethrtime
);
our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Time::HR macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Time::HR $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Time::HR - Perl interface to high-resolution timer.

=head1 SYNOPSIS

   use Time::HR;

   $hrtime  = gethrtime();

=head1 DESCRIPTION

Time::HR is a very simple interface to high-resolution timer - it only supports
one function call - gethrtime(). gethrtime() function returns current high-resolution
real time value either as 64-bit integer (on systems with 64-bit support) or double value.
Time is expressed as nanoseconds since some arbitrary time in the past; 
it is not correlated in any way to the time of day, and thus is not subject to resetting or
drifting by way of adjtime or settimeofday. The high resolution timer is ideally suited to 
performance measurement tasks, where cheap, accurate interval timing is required.
Currently, this extension is only supported on Solaris, Linux and Cygwin.

=head2 EXPORT

   gethrtime

=head2 Exportable constants

   none

=head1 AUTHOR

Alexander Golomshtok, golomshtok_alexander@jpmorgan.com

=head1 SEE ALSO

L<perl>.

=cut
