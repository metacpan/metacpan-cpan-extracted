# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
#
# a search handler is just a context menu extension with additionnal registry keys, according to
# http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/programmersguide/shell_int/shell_int_extending/extensionhandlers/searchhandlers.asp
#

package Win32::ShellExt::Search;

use strict;
use Win32::ShellExt;

$Win32::ShellExt::Search::VERSION='0.1';
$Win32::ShellExt::Search::COMMAND="Copy path to clipboard";
@Win32::ShellExt::Search::ISA=qw(Win32::ShellExt);

sub query_context_menu() {
	my $self = shift;
	"Win32::ShellExt::Search";
}

sub action() {
	my $self = shift;
	# @_ now holds the list of file paths we want to act on.

	1;
}

sub hkeys() {
	die "Wi3n2::ShellExtSearch is an abstract base class";
	undef;
}

1;


