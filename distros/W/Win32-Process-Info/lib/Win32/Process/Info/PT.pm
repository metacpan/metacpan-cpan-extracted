=head1 NAME

Win32::Process::Info::PT - Provide process information via Proc::ProcessTable.

=head1 SYNOPSIS

This package fetches process information on a given machine, using Dan
Urist's B<Proc::ProcessTable>. This makes the 'Win32::' part of our name
bogus, but lets one use the same basic interface under a wider range of
operating systems.

 use Win32::Process::Info
 $pi = Win32::Process::Info->new (undef, 'PT');
 $pi->Set (elapsed_as_seconds => 0);	# In clunks, not seconds.
 @pids = $pi->ListPids ();	# Get all known PIDs
 @info = $pi->GetProcInfo ();	# Get the max

CAVEAT USER:

This package does not support access to a remote machine,
because the underlying API doesn't. If you specify a machine
name (other than '', 0, or undef) when you instantiate a
new Win32::Process::Info::PT object, you will get an exception.

This package is B<not> intended to be used independently;
instead, it is a subclass of Win32::Process::Info, and should
only be called via that package.

=head1 DESCRIPTION

The main purpose of the Win32::Process::Info::PT package is to get
whatever information is convenient (for the author!) about one or more
processes. GetProcInfo (which see) is therefore the most-important
method in the package. See it for more information.

This package returns whatever process IDs are made available by
Proc::ProcessTable. Under Cygwin, this seems to mean Cygwin process IDs,
not Windows process IDs.

Unless explicitly stated otherwise, modules, variables, and so
on are considered private. That is, the author reserves the right
to make arbitrary changes in the way they work, without telling
anyone. For subroutines, variables, and so on which are considered
public, the author will make an effort keep them stable, and failing
that to call attention to changes.

Nothing is exported by default, though all the public subroutines are
exportable, either by name or by using the :all tag.

The following subroutines should be considered public:

=over

=cut

# 0.001	18-Sep-2007	T. R. Wyant
#		Initial release.
# 0.001_01 01-Apr-2009	T. R. Wyant
#		Make Perl::Critic compliant (to -stern, with my own profile)
# 0.002	02-Apr-2009	T. R. Wyant
#		Production version.
# 0.002_01 07-Apr-2009	T. R. Wyant
#		Use $self->_build_hash(), so that we test it.

package Win32::Process::Info::PT;

use strict;
use warnings;

use base qw{ Win32::Process::Info };

our $VERSION = '1.022';

use Carp;
use File::Basename;
use Proc::ProcessTable;

# TODO figure out what we need to do here.

my %_transform = (
##	CreationDate => \&Win32::Process::Info::_date_to_time_t,
	KernelModeTime => \&Win32::Process::Info::_clunks_to_desired,
	UserModeTime => \&Win32::Process::Info::_clunks_to_desired,
	);

my %lglarg = map {($_, 1)} qw{assert_debug_priv variant};

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $arg = shift;
    if (ref $arg eq 'HASH') {
	my @ilg = grep {!$lglarg{$_}} keys %$arg;
	@ilg and
	    croak "Error - Win32::Process::Info::PT argument(s) (@ilg) illegal";
    } else {
	croak "Error - Win32::Process::Info::PT does not support remote operation."
	    if $arg;
    }
    no warnings qw{once};
    my $self = {%Win32::Process::Info::static};
    use warnings qw{once};
    delete $self->{variant};
    $self->{_xfrm} = \%_transform;
    bless $self, $class;
    return $self;
}


=item @info = $pi->GetProcInfo ();

This method returns a list of anonymous hashes, each containing
information on one process. If no arguments are passed, the
list represents all processes in the system. You can pass a
list of process IDs, and get out a list of the attributes of
all such processes that actually exist. If you call this
method in scalar context, you get a reference to the list.

What keys are available depend on the variant in use. With the PT
variant you can hope to get at most the following keys. The caveat is
that the Win32::Process::Info keys are derived from
Proc::ProcessTable::Process fields, and if your OS does not support the
underlying field, you will not get it. Here are the possible keys and
the fields from which they are derived:

    CreationDate: start
    Description: cmndline
    ExecutablePath: fname (note 1)
    KernelModeTime: stime (note 2)
    Name: basename (fname)
    Owner: '\' . getpwuid (uid) (note 3)
    OwnerSid: uid (note 4)
    ParentProcessId: ppid
    ProcessId: pid
    UserModeTime: utime (note 2)

Notes:

1) ExecutablePath may not be an absolute pathname.

2) We assume that Proc::ProcessTable::Process returns stime and utime in
microseconds, and multiply by 10 to get clunks. This may be wrong under
some operating systems.

3) Owner has a backslash prefixed because Windows returns domain\user. I
don't see a good way to get domain, but I wanted to be consistent (read:
I was too lazy to special-case the test script).

4) Note that under Cygwin this is B<not> the same as the Windows PID,
which is returned in field 'winpid'. But the Subprocesses method needs
the ProcessId and ParentProcessId to be consistent, and there was no
documented 'winppid' field.

The output will contain all processes for which information was
requested, but will not necessarily contain all information for
all processes.

The _status key of the process hash contains the status of
GetProcInfo's request(s) for information. In the case of
Win32::Process::Info::PT, this will always be 0, but is provided
to be consistent with the other variants.

=cut

{

    my %pw_uid;
    my %fld_map = (
	cmndline => 'Description',
	fname => sub {
	    my ($info, $proc) = @_;
	    $info->{Name} = basename (
		$info->{ExecutablePath} = $proc->fname ());
	},
	pid => 'ProcessId',
	ppid => 'ParentProcessId',
	start => 'CreationDate',
##	stime => 'KernelModeTime',
##	utime => 'UserModeTime',
	stime => sub {
	    my ($info, $proc) = @_;
	    $info->{KernelModeTime} = $proc->stime() * 10;
	},
	utime => sub {
	    my ($info, $proc) = @_;
	    $info->{UserModeTime} = $proc->utime() * 10;
	},
	uid => sub {
	    my ($info, $proc) = @_;
	    $info->{OwnerSid} = my $uid = $proc->uid ();
	    $info->{Owner} = $pw_uid{$uid} ||= '\\' . getpwuid($uid);
	},
    );
    my @fld_sup = grep { defined $_ } Proc::ProcessTable->new ()->fields ();

    sub GetProcInfo {
	my ($self, @args) = @_;

	my $my_pid = $self->My_Pid();
	my $opt = ref $args[0] eq 'HASH' ? shift @args : {};
	my $tbl = Proc::ProcessTable->new ()->table ();

	if (@args) {
	    my %filter = map {
		($_ eq '.' ? $my_pid : $_) => 1
	    } @args;
	    $tbl = [grep {$filter{$_->pid ()}} @$tbl];
	}
	my @pinf;
	foreach my $proc (@$tbl) {
	    my $info = {_status => 0};
	    foreach my $key (@fld_sup) {
		my $name = $fld_map{$key} or next;
		if (ref $name eq 'CODE') {
		    $name->($info, $proc);
		} else {
		    # Yes, we could just plop the information into the
		    # hash. But _build_hash() needs to be called in
		    # every variant so it gets tested under any
		    # variant.
		    $self->_build_hash($info, $name, $proc->$key());
		}
	    }
	    push @pinf, $info;
	}
	return wantarray ? @pinf : \@pinf;
    }

}

=item @pids = $pi->ListPids ()

This subroutine returns a list of all known process IDs in the
system, in no particular order. If called in list context, the
list of process IDs itself is returned. In scalar context, a
reference to the list is returned.

=cut

sub ListPids {
    my ($self, @args) = @_;

    my $tbl = Proc::ProcessTable->new ()->table ();
    my $my_pid = $self->My_Pid();
    my @pids;

    if (@args) {
	my %filter = map {
	    ($_ eq '.' ? $my_pid : $_) => 1
	} @args;
	@pids = grep {$filter{$_}} map {$_->pid} @$tbl;
    } else {
	@pids = map {$_->pid} @$tbl;
    }
    return wantarray ? @pids : \@pids;
}

sub My_Pid {
    return $$;
}

=back

=head1 REQUIREMENTS

This library uses the following libraries:

 Carp
 Time::Local
 Proc::ProcessTable

As of this writing, all but Proc::ProcessTable are part of the
standard Perl distribution.

=head1 ACKNOWLEDGMENTS

This module would not exist without the following people

Dan Urist, author (or at least coordinator) of the Proc::ProcessTable
module, upon which this is based.

Jenda Krynicky, whose "How2 create a PPM distribution"
(F<http://jenda.krynicky.cz/perl/PPM.html>) gave me a leg up on
both PPM and tar distributions.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2009-2011, 2013-2014 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

1;
