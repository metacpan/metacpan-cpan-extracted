# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::ExcelToClipboard;

use strict;
use Win32::ShellExt;

$Win32::ShellExt::ExcelToClipboard::VERSION='0.1';
$Win32::ShellExt::ExcelToClipboard::COMMAND="ExcelToClipboard file";
@Win32::ShellExt::ExcelToClipboard::ISA=qw(Win32::ShellExt);

sub query_context_menu() {
	my $s = "Win32::ShellExt::ExcelToClipboard";
	my $item;
	foreach $item (@_) { undef $s if($item!~m!\.xls!i); }
	$s;
}

sub action() {
	my $self = shift;
	map { $self->extract($_) } @_;
	1;
}

sub extract() {
	my ($self,$file) = @_;
	
	
}

sub hkeys() {
	my $h = {
	"CLSID" => "{6697F113-BBDD-467C-861E-218402A243AE}",
	"name"  => "Excel extraction shell Extension",
	"package" => "Win32::ShellExt::ExcelToClipboard"
	};
	$h;
}

1;


