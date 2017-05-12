# -*- cperl -*-
# (C) 2002 Jean-Baptiste Nivoit
package Win32::ShellExt::Split;

use strict;
use Win32::ShellExt;

$Win32::ShellExt::Split::VERSION='0.1';
$Win32::ShellExt::Split::COMMAND="Split file";
@Win32::ShellExt::Split::ISA=qw(Win32::ShellExt);

sub query_context_menu() {
	my $s = "Win32::ShellExt::Split";
	$s;
}

sub action() {
	my $self = shift;
	map { $self->split($_) } @_;
	1;
}

sub split() {
	my ($self,$file) = @_;
	
}

sub hkeys() {
	my $h = {
	"CLSID" => "{28CF5A14-D6C0-4AD8-8E5C-D244AF7918B7}",
	"name"  => "file splitter shell Extension",
	"package" => "Win32::ShellExt::Split"
	};
	$h;
}

1;


