package Win32::MCI::Basic;

require 5.005;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(mciSendString mciGetErrorString);
our $VERSION = '0.02';

use Win32::API;

my $mciSendString		||= new Win32::API('winmm',	'mciSendString',	['P','P','I','P'],	'N');
my $mciGetErrorString	||= new Win32::API('winmm',	'mciGetErrorString',['N','P','I'],		'I');

sub mciSendString {
	my $lpszCommand			= shift;
	my $lpszReturnString	= " " x 256;
	my $cchReturn			= length($lpszReturnString);
	my $ReturnValue			= $mciSendString->Call($lpszCommand, $lpszReturnString, $cchReturn, "\0");
	return ($ReturnValue, (split "\0", $lpszReturnString)[0]);
}

sub mciGetErrorString {
	my $fdwError		= shift;
	my $lpszErrorText	= " " x 128;
	my $cchErrorText	= length($lpszErrorText);
	$mciGetErrorString->Call($fdwError, $lpszErrorText, $cchErrorText);
	return (split "\0", $lpszErrorText)[0];
}

1;
__END__

=head1 NAME

Win32::MCI::Basic - Basic Perl interface to Windows MCI API

=head1 SYNOPSIS

  use Win32::MCI::Basic;
  my $lpszCommand = "status cdaudio number of tracks"; # example MCI command
  my ($APICallReturnValue, $lpszReturnString) = mciSendString($lpszCommand);
  print "Number of tracks: $lpszReturnString\n";

  my $lpszErrorText = mciGetErrorString($ReturnValue);
  print "Error: $lpszErrorText\n";

=head1 DESCRIPTION

Win32::MCI::Basic provides a simple, basic, Perl interface to the 
Windows MCI (Media Control Interface) API.

=head2 EXPORT

=item mciSendString($lpszCommand)

Calls mciSendString with the specified $lpszCommand.
Returns an array containing the API call return value
and the string contained into the $lpszReturnString
buffer. (see Microsoft Platform SDK for details)

=item mciGetErrorString($fdwError)

Calls mciGetErrorString with the specified MCI API
error code (which is mciSendString()'s first return
value). Returns a descriptive string about the error
code.

=head1 AUTHOR

Nilson S. F. Junior (nilsonsfj@cpan.org)

=head1 SEE ALSO

Win32::API, Microsoft Platform SDK

=cut
