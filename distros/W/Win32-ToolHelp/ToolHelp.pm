package Win32::ToolHelp;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows declaration	use Win32::ToolHelp ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	WIN32_TOOLHELP_IMPL_VER
	MAX_PATH
	MAX_MODULE_NAME32

	GetProcesses
	GetProcessModules
	GetProcess
	GetProcessModule
	GetProcessMainModule
	SearchProcess
	SearchProcessModule
	SearchProcessMainModule
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();
our $VERSION = '0.32';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    local $! = 0;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Win32::ToolHelp macro $constname";
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

bootstrap Win32::ToolHelp $VERSION;

# Preloaded methods go here.

sub GetProcess
{
	my ($pid) = @_;

	return if !defined($pid);

	my @ps = GetProcesses();
	foreach my $p (@ps)
	{
		next if $$p[1] != $pid;
		return @{$p};
	}

	return;
}

sub GetProcessModule
{
	my ($pid, $mid) = @_;

	return if !defined($pid);
	return if !defined($mid);

	my @ms = GetProcessModules($pid);
	foreach my $m (@ms)
	{
		next if $$m[0] != $mid;
		return @{$m};
	}

	return;
}

sub GetProcessMainModule
{
	my ($pid) = @_;

	return if !defined($pid);

	#my @p = GetProcess($pid);
	#return if scalar(@p) == 0;

	my @ms = GetProcessModules($pid);
	# module ids are allways 1 but module id of the process module is 0
	# dunno why cause the process module cannot be found by its id then
	# hope it's safe to return the first module, grrr...
	#foreach my $m (@ms)
	#{
	#	next if $$m[0] != $p[3];
	#	return @{$m};
	#}
	return @{$ms[0]};

	return;
}

sub SearchProcess
{
	my ($pname) = @_;

	return if !defined($pname) || $pname eq "";

	my @ps = GetProcesses();
	foreach my $p (@ps)
	{
		next if $$p[8] ne $pname;
		return @{$p};
	}

	return;
}

sub SearchProcessModule
{
	my ($pid, $mname) = @_;

	return if !defined($pid);
	return if !defined($mname) || $mname eq "";

	my @ms = GetProcessModules($pid);
	foreach my $m (@ms)
	{
		next if $$m[7] ne $mname;
		return @{$m};
	}

	return;
}

sub SearchProcessMainModule
{
	my ($pname) = @_;

	return if !defined($pname) || $pname eq "";

	my @p = SearchProcess($pname);
	return if scalar(@p) == 0;

	return GetProcessMainModule($p[1]);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Win32::ToolHelp - Perl extension for obtaining information about currently
                  executing applications (using the ToolHelp API on Win32)

=head1 SYNOPSIS

  use Win32::ToolHelp;

  # --- prints names of all processes
  my @ps = Win32::ToolHelp::GetProcesses();
  foreach my $p (@ps)
  { print $$p[8], "\n"; }

  # --- prints names of the modules used by the current process
  my @ms = Win32::ToolHelp::GetProcessModules($$);
  foreach my $m (@ms)
  { print $$m[7], "\n"; }

  # --- prints name of the current process
  my @cp = Win32::ToolHelp::GetProcess($$);
  print $cp[8], "\n";

  # --- prints full path to the executable of the current process
  my @cm = Win32::ToolHelp::GetProcessMainModule($$);
  print $cm[8], "\n";

  # --- prints full path to the executable of the first running perl
  my @pl = Win32::ToolHelp::SearchProcessMainModule("perl.exe");
  print $pl[8], "\n";

=head1 DESCRIPTION

The I<Win32::ToolHelp> module provides a Perl interface to the I<ToolHelp>
API that is present on Windows 95 or higher or Windows 2000 or higher.

The module exposes functionality for obtaining information about currently
executing applications (processes and modules used by the processes).

=head2 B<@processes = GetProcesses()>

Retrieves list of all processes currently running on the system. The list
is returned as an array or array references. See C<GetProcess>
for the description of a nested array (information about a single process).

=head2 B<@modules = GetProcessModules($pid)>

Retrieves list of all modules currently loaded and used by the processes
identified by the process id (B<pid>) passed into. The list is returned
as an array or array references. See C<GetProcessModule> for the description
of a nested array (information about a single module).

=head2 B<($ucnt, $pid, $hid, $mid, $tcnt, $aid, $prio, $flgs, $nam) = GetProcess($pid)>

Retrieves information about the process identified by the process id (B<pid>)
passed into. The information is returned as an array of these scalars:

=over 6

=item B<cnt>

number of references to the process

=item B<pid>

identifier of the process

=item B<hid>

identifier of the default heap for the process

=item B<mid>

module identifier of the process

=item B<tcnt>

number of execution threads started by the process

=item B<aid>

identifier of the process that created the process being examined

=item B<prio>

base priority of any threads created by this process

=item B<flgs>

reserved; do not use

=item B<nam>

path and filename of the executable file for the process

=back

The information is the same as in the structure C<PROCESSENTRY32>
filled by the ToolHelp API functions C<Process32First> and C<Process32Next>.

=head2 B<($mid, $pid, $gc, $pc, $ad, $sz, $h, $nm, $pt) = GetProcessModule($pid, $mid)>

Retrieves information about a module of the process identified by the process
id (B<pid>) and the module id (B<mid>) passed into. The information is
returned as an array of these scalars:

=over 6

=item B<mid>

module identifier in the context of the owning process

=item B<pid>

identifier of the process being examined

=item B<gc>

global usage count on the module

=item B<pc>

module usage count in the context of the owning process

=item B<ad>

base address of the module in the context of the owning process

=item B<sz>

size, in bytes, of the module

=item B<h>

handle to the module in the context of the owning process

=item B<nm>

string containing the module name

=item B<pt>

string containing the location (path) of the module

=back

The information is the same as in the structure C<MODULEENTRY32>
filled by the ToolHelp API functions C<Module32First> and C<Module32Next>.

=head2 B<($mid, $pid, $gc, $pc, $ad, $sz, $h, $nam, $pth) = GetProcessMainModule($pid)>

Retrieves information about the main executable module of the process
identified by the process id (B<pid>) passed into. The information is
returned as an array of scalars. See C<GetProcessModule> for the description
of the array.

=head2 B<($uct, $pid, $hid, $mid, $tct, $aid, $pri, $fls, $nm) = SearchProcess($pname)>

Retrieves information about the process identified by the process executable
name (B<pname>) passed into. The information is returned as an array
of scalars. See C<GetProcess> for the description of the array.

=head2 B<($mid, $pid, $gc, $pc, $ad, $sz, $h, $n, $p) = SearchProcessModule($pid, $m)>

Retrieves information about a module of the process identified by
the process id (B<pid>) and the module name (B<m>) passed into.
The information is returned as an array of scalars.  See C<GetProcessModule>
for the description of the array.

=head2 B<($mid, $pid, $gc, $pc, $ad, $sz, $h, $nm, $pt) = SearchProcessMainModule($p)>

Retrieves information about the main executable module of the process
identified by the process executable name (B<p>) passed into.
The information is returned as an array of scalars.  See C<GetProcessModule>
for the description of the array.

=head1 AUTHOR

Ferdinand Prantl E<lt>F<prantl@host.sk>E<gt>

See F<http://prantl.host.sk/perl/modules/Win32/ToolHelp>
for the most recent version.

=head1 COPYRIGHT

Copyright (c) 2002, Ferdinand Prantl. All rights reserved.

Permission to use, copy, modify, distribute and sell this software
and its documentation for any purpose is hereby granted without fee,
provided that the above copyright notice appear in all copies and
that both that copyright notice and this permission notice appear
in supporting documentation. Author makes no representations
about the suitability of this software for any purpose.  It is
provided "as is" without express or implied warranty.

=head1 SEE ALSO

L<Win32::Process> and L<Win32::Job>.

=cut
