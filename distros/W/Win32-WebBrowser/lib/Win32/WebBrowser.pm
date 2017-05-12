package Win32::WebBrowser;

our %reg;

use Win32::TieRegistry(TiedHash => \%reg, Delimiter  => '/');
use Win32::Process;
use base qw(Exporter);

our @EXPORT = qw(open_browser);

use strict;
use warnings;

our $VERSION = '1.02';

#
#	open a web browser with our file
#	NOTE: this only works on Win32!!!
#
sub open_browser {
	my $url = shift;
#
# open the registry to find the path to the default browser
#
	my $cmdkey = $reg{ 'HKEY_CLASSES_ROOT/' . 
		$reg{'HKEY_CLASSES_ROOT/.htm//'} . 
			'/shell/open/command'};

	my $sysstr = $cmdkey->{'/'};
#
# replace the argument PH with our URL
#
	$url=~tr/\\/\//;
#	$url = "file://C:$url"
#		unless (substr($url, 0, 7) eq 'http://') ||
#			(substr($url, 0, 7) eq 'file://');

	$sysstr=~s/\-nohome//;
	
	if ($sysstr=~/%1/) {
		$sysstr =~ s!%1!$url!;
	}
	else {
		$sysstr .= " $url";
	}
	my $exe = $sysstr;
#
#	in case we get a fancy pathname, strip the
#	quotes
#
	if ($sysstr=~/^"/) {
		$exe=~s/^"([^"]+)"\s+.+$/$1/;
	}
	else {
		$exe=~s/^(\S+)\s+.+$/$1/;
	}
# start the browser...
	my $browser;
	return 1
		if Win32::Process::Create($browser,
    	   $exe,
    	   $sysstr,
    	   0,
    	   NORMAL_PRIORITY_CLASS|DETACHED_PROCESS,
    	   '.'
    	   );
	$@ = Win32::FormatMessage(Win32::GetLastError());
	return undef;
}

1;

=head1 NAME

Win32::WebBrowser - open the default web browser on Win32

=head1 SYNOPSIS

	use Win32::WebBrowser;
	
	open_browser('file://D:\\some\\directory\\myfile.html');

=head1 DESCRIPTION

In a separate detached process, opens the default web browser instance for the specified URL.
The browser executable is determined by reading the registry.

=head1 METHODS

Only a single exported method is provided:

=head2 $result = open_browser($url)

Create a separate detached process to run the default browser for the platform
(as specified in the registry) and supply the given C<$url> to it.
Returns 1 on success, undef with the error message in C<$@> on failure.

=head1 SEE ALSO

L<HTML::Display> provides similar functionality for multiple OSes/platforms,
but does not currently (as of version 0.39) provide a working
Windows solution.

=head1 AUTHOR, COPYRIGHT, and LICENSE

Copyright(C) 2007, Dean Arnold, Presicient Corp., USA. All rights reserved.

Permission is granted to use this software under the same terms as Perl itself.
Refer to the L<Perl Artistic|perlartistic> license for details.

=cut