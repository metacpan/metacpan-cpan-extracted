package Win32::API::OutputDebugString;

require 5.005_62;
use strict;
use vars qw(*DStr);
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::API::OutputDebugString ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	OutputDebugString DStr
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';

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
	    croak "Your vendor has not defined Win32::API::OutputDebugString macro $constname";
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

bootstrap Win32::API::OutputDebugString $VERSION;

# Preloaded methods go here.
sub OutputDebugString {
    ODS(join('',@_));
}
# Typeglob aliasing....
*DStr= \&OutputDebugString;
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::API::OutputDebugString - Perl wrapper for the OutputDebugString
                                on Win32 Platforms
=head1 SYNOPSIS

  use Win32::API::OutputDebugString qw(OutputDebugString DStr);
  OutputDebugString("Foo bar", "baz\n"); # sends  Foo barbaz\n to the debugger
  DStr("Foo bar", "baz\n");             # Same

=head1 DESCRIPTION

Wrapper for the OutputDebugString Win32 API. 

It contains two identical 
functions (OutputDebugString and  DStr) which join their args an send them
to the eponymous Win32 Api. 

DStr is meant to just save some typing. 

=head2 EXPORT

None by default.

=head2 Exportable functions

Win32::API::OutputDebugString::OutputDebugString 

Win32::API::OutputDebugString::DStr

=head1 AUTHOR

Alessandro Forghieri alf@orion.it

=head1 LICENSE

GPL or Artistic License.

=head1 SEE ALSO

The Windows API documentation; perl(1).

=cut
