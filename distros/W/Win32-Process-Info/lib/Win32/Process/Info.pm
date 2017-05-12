=head1 NAME

Win32::Process::Info - Provide process information for Windows 32 systems.

=head1 SYNOPSIS

 use Win32::Process::Info;
 $pi = Win32::Process::Info->new ();
 $pi->Set (elapsed_in_seconds => 0);	# In clunks, not seconds.
 @pids = $pi->ListPids ();	# Get all known PIDs
 @info = $pi->GetProcInfo ();	# Get the max
 %subs = $pi->Subprocesses ();	# Figure out subprocess relationships.
 @info = grep {
     defined $_->{Name} &&
     $_->{Name} =~ m/perl/
 } $pi->GetProcInfo ();        # All processes with 'perl' in name.

=head1 NOTICE

This package covers a multitude of sins - as many as Microsoft has
invented ways to get process info and I have resources and gumption
to code. The key to this mess is the 'variant' argument to the 'new'
method (q.v.).

The WMI variant has various problems, known or suspected to be inherited
from Win32::OLE. See L</BUGS> for the gory details. The worst of these
is that if you use fork(), you B<must> disallow WMI completely by
loading this module as follows:

 use Win32::Process::Info qw{NT};

This method of controlling things must be considered experimental until
I can confirm it causes no unexpected insurmountable problems. If I am
forced to change it, the change will be flagged prominently in the
documentation.

This change is somewhat incompatible with 1.006 and earlier because it
requires the import() method to be called in the correct place with the
correct arguments. If you C<require Win32::Process::Info>, you B<must>
explicitly call Win32::Process::Info->import().

See the import() documentation below for the details.

B<YOU HAVE BEEN WARNED!>

=head1 DESCRIPTION

The main purpose of the Win32::Process::Info package is to get whatever
information is convenient (for the author!) about one or more Windows
32 processes. L</GetProcInfo> is therefore the most-important
method in the package. See it for more information.

The process IDs made available are those returned by the variant in
use. See the documentation to the individual variants for details,
especially if you are a Cygwin user.

Unless explicitly stated otherwise, modules, variables, and so
on are considered private. That is, the author reserves the right
to make arbitrary changes in the way they work, without telling
anyone. For methods, variables, and so on which are considered
public, the author will make an effort keep them stable, and failing
that to call attention to changes.

The following methods should be considered public:

=over 4

=cut

package Win32::Process::Info;

use 5.006;

use strict;
use warnings;

our $VERSION = '1.022';

use Carp;
use File::Spec;
use Time::Local;

our %static = (
    elapsed_in_seconds	=> 1,
    variant		=> $ENV{PERL_WIN32_PROCESS_INFO_VARIANT},
    );

#	The real reason for the %variant_support hash is to deal with
#	the apparant inability of Win32::API to be 'require'-d anywhere
#	but in a BEGIN block. The 'unsupported' key is intended to be
#	used as a 'necessary but not required' criterion; that is, if
#	'unsupported' is true, there's no reason to bother; but if it's
#	false, there may still be problems of some sort. This is par-
#	ticularly true of WMI, where the full check is rather elephan-
#	tine.
#
#	The actual 'necessary but not required' check has moved to
#	{check_support}, with {unsupported} simply holding the result of
#	the check. The {check_support} key is code to be executed when
#	the import() hook is called when the module is loaded.
#
#	While I was at it, I decided to consolidate all the variant-
#	specific information in one spot and, while I was at it, write
#	a variant checker utility.

my %variant_support;
BEGIN {
    # Cygwin has its own idea of what a process ID is, independent of
    # the underlying operating system. The Cygwin Perl implements this,
    # so if we're Cygwin we need to compensate. This MUST return the
    # Windows-native form under Cygwin, which means any variant which
    # needs another form must override.

    if ( $^O eq 'cygwin' ) {
	*My_Pid = sub {
	    return Cygwin::pid_to_winpid( $$ );
	};
    } else {
	*My_Pid = sub {
	    return $$;
	};
    }
    %variant_support = (
	NT => {
	    check_support => sub {
		local $@;
		eval {
		    require Win32;
		    Win32->can( 'IsWinNT' ) && Win32::IsWinNT();
		} or return "$^O is not a member of the Windows NT family";
		eval { require Win32::API; 1 }
		    or return 'I can not find Win32::API';
		my @path = File::Spec->path();
DLL_LOOP:
		foreach my $dll (qw{PSAPI.DLL ADVAPI32.DLL KERNEL32.DLL}) {
		    foreach my $loc (@path) {
			next DLL_LOOP if -e File::Spec->catfile ($loc, $dll);
		    }
		    return "I can not find $dll";
		}
		return 0;
	    },
	    make => sub {
		require Win32::Process::Info::NT;
		Win32::Process::Info::NT->new (@_);
	    },
	    unsupported => "Disallowed on load of @{[__PACKAGE__]}.",
	},
	PT => {
	    check_support => sub {
		local $@;
		return "Unable to load Proc::ProcessTable"
		    unless eval {require Proc::ProcessTable; 1};
		return 0;
	    },
	    make => sub {
		require Win32::Process::Info::PT;
		Win32::Process::Info::PT->new (@_);
	    },
	    unsupported => "Disallowed on load of @{[__PACKAGE__]}.",
	},
	WMI => {
	    check_support => sub {
		local $@;
		_isReactOS()
		    and return 'Unsupported under ReactOS';
		eval {
		    require Win32::OLE;
		    1;
		} or return 'Unable to load Win32::OLE';
		my ( $wmi, $proc );
		my $old_warn = Win32::OLE->Option( 'Warn' );
		eval {
		    Win32::OLE->Option( Warn => 0 );
		    $wmi = Win32::OLE->GetObject(
			'winmgmts:{impersonationLevel=impersonate,(Debug)}!//./root/cimv2'
		    );
		    $wmi and $proc = $wmi->Get(
			sprintf q{Win32_Process='%s'}, __PACKAGE__->My_Pid()
		    );
		};
		Win32::OLE->Option( Warn => $old_warn );
		$wmi or return 'Unable to get WMI object';
		$proc or return 'WMI broken: unable to get process object';
		return 0;
	    },
	    make => sub {
		require Win32::Process::Info::WMI;
		Win32::Process::Info::WMI->new (@_);
	    },
	    unsupported => "Disallowed on load of @{[__PACKAGE__]}.",
	},
    );
}

our %mutator = (
    elapsed_in_seconds	=> sub {$_[2]},
    variant		=> sub {
	ref $_[0]
	    and eval { $_[0]->isa( 'Win32::Process::Info' ) }
	    or croak 'Variant can not be set on an instance';
	foreach (split '\W+', $_[2]) {
	    my $status;
	    $status = variant_support_status( $_ )
		and croak "Variant '$_' unsupported on your configuration; ",
		    $status;
	}
	$_[2]
    },
);


=item $pi = Win32::Process::Info->new ([machine], [variant], [hash])

This method instantiates a process information object, connected
to the given machine, and using the given variant.

The following variants are currently supported:

NT - Uses the NT-native mechanism. Good on any NT, including
Windows 2000. This variant does not support connecting to
another machine, so the 'machine' argument must be an
empty string (or undef, if you prefer).

PT - Uses Dan Urist's Proc::ProcessTable, making it possible
(paradoxically) to use this module on other operating systems than
Windows. Only those Proc::ProcessTable::Process fields which seem
to correspond to WMI items are returned. B<Caveat:> the PT variant
is to be considered experimental, and may be changed or retracted
in future releases.

WMI - Uses the Windows Management Implementation. Good on Win2K, ME,
and possibly others, depending on their vintage and whether
WMI has been retrofitted.

The initial default variant comes from environment variable
PERL_WIN32_PROCESS_INFO_VARIANT. If this is not found, it will be
'WMI,NT,PT', which means to try WMI first, NT if WMI fails, and PT as a
last resort. This can be changed using Win32::Process::Info->Set
(variant => whatever).

The hash argument is a hash reference to additional arguments, if
any. The hash reference can actually appear anywhere in the argument
list, though positional arguments are illegal after the hash reference.

The following hash keys are supported:

  variant => corresponds to the 'variant' argument (all)
  assert_debug_priv => assert debug if available (all) This
	only has effect under WMI. The NT variant always
	asserts debug. You want to be careful doing this
	under WMI if you're fetching the process owner
	information, since the script can be badly behaved
	(i.e. die horribly) for those processes whose
	ExecutablePath is only available with the debug
	privilege turned on.
  host => corresponds to the 'machine' argument (WMI)
  user => username to perform operation under (WMI)
  password => password corresponding to the given
	username (WMI)

ALL hash keys are optional. SOME hash keys are only supported under
certain variants. These are indicated in parentheses after the
description of the key. It is an error to specify a key that the
variant in use does not support.

=cut

my @argnam = qw{host variant};
sub new {
    my ($class, @params) = @_;
    $class = ref $class if ref $class;
    my %arg;
    my ( $self, @probs );

    my $inx = 0;
    foreach my $inp (@params) {
	if (ref $inp eq 'HASH') {
	    foreach my $key (keys %$inp) {$arg{$key} = $inp->{$key}}
	} elsif (ref $inp) {
	    croak "Argument may not be @{[ref $inp]} reference.";
	} elsif ($argnam[$inx]) {
	    $arg{$argnam[$inx]} = $inp;
	} else {
	    croak "Too many positional arguments.";
	}
	$inx++;
    }

    _import_done()
	or croak __PACKAGE__,
	    '->import() must be called before calling ', __PACKAGE__,
	    '->new()';
    my $mach = $arg{host} or delete $arg{host};
    my $try = $arg{variant} || $static{variant} || 'WMI,NT,PT';
    foreach my $variant (grep {$_} split '\W+', $try) {
	my $status;
	$status = variant_support_status( $variant ) and do {
	    push @probs, $status;
	    next;
	};
	my $self;
	$self = $variant_support{$variant}{make}->( \%arg ) and do {
	    $static{variant} ||= $self->{variant} = $variant;
	};
	return $self;
    }
    croak join '; ', @probs;
}

=item @values = $pi->Get (attributes ...)

This method returns the values of the listed attributes. If
called in scalar context, it returns the value of the first
attribute specified, or undef if none was. An exception is
raised if you specify a non-existent attribute.

This method can also be called as a class method (that is, as
Win32::Process::Info->Get ()) to return default attributes values.

The relevant attribute names are:

B<elapsed_as_seconds> is TRUE to convert elapsed user and
kernel times to seconds. If FALSE, they are returned in
clunks (that is, hundreds of nanoseconds). The default is
TRUE.

B<variant> is the variant of the Process::Info code in use,
and should be zero or more of 'WMI' or 'NT', separated by
commas. 'WMI' selects the Windows Management Implementation, and
'NT' selects the Windows NT native interface.

B<machine> is the name of the machine connected to. This is
not available as a class attribute.

=cut

sub Get {
my ($self, @args) = @_;
$self = \%static unless ref $self;
my @vals;
foreach my $name (@args) {
    croak "Error - Attribute '$name' does not exist."
	unless exists $self->{$name};
    croak "Error - Attribute '$name' is private."
	if $name =~ m/^_/;
    push @vals, $self->{$name};
    }
return wantarray ? @vals : $vals[0];
}

=item @values = $pi->Set (attribute => value ...)

This method sets the values of the listed attributes,
returning the values of all attributes listed if called in
list context, or of the first attribute listed if called
in scalar context.

This method can also be called as a class method (that is, as
Win32::Process::Info->Set ()) to change default attribute values.

The relevant attribute names are the same as for Get.
However:

B<variant> is read-only at the instance level. That is,
Win32::Process::Info->Set (variant => 'NT') is OK, but
$pi->Set (variant => 'NT') will raise an exception. If
you set B<variant> to an empty string (the default), the
next "new" will iterate over all possibilities (or the
contents of environment variable
PERL_WIN32_PROCESS_INFO_VARIANT if present), and set
B<variant> to the first one that actually works.

B<machine> is not available as a class attribute, and is
read-only as an instance attribute. It is B<not> useful for
discovering your machine name - if you instantiated the
object without specifying a machine name, you will get
nothing useful back.

=cut

sub Set {
my ($self, @args) = @_;
croak "Error - Set requires an even number of arguments."
    if @args % 2;
$self = \%static unless ref $self;
my $mutr = $self->{_mutator} || \%mutator;
my @vals;
while (@args) {
    my $name = shift @args;
    my $val = shift @args;
    croak "Error - Attribute '$name' does not exist."
	unless exists $self->{$name};
    croak "Error - Attribute '$name' is read-only."
	unless exists $mutr->{$name};
    $self->{$name} = $mutr->{$name}->($self, $name, $val);
    push @vals, $self->{$name};
    }
return wantarray ? @vals : $vals[0];
}

=item @pids = $pi->ListPids ();

This method lists all known process IDs in the system. If
called in scalar context, it returns a reference to the
list of PIDs. If you pass in a list of pids, the return will
be the intersection of the argument list and the actual PIDs
in the system.

=cut

sub ListPids {
   confess
   "Error - Whoever coded this forgot to override ListPids.";
}

=item @info = $pi->GetProcInfo ();

This method returns a list of anonymous hashes, each containing
information on one process. If no arguments are passed, the
list represents all processes in the system. You can pass a
list of process IDs, and get out a list of the attributes of
all such processes that actually exist. If you call this
method in scalar context, you get a reference to the list.

What keys are available depends on the variant in use.
You can hope to get at least the following keys for a
"normal" process (i.e. not the idle process, which is PID 0,
nor the system, which is some small indeterminate PID) to
which you have access:

    CreationDate
    ExecutablePath
    KernelModeTime
    MaximumWorkingSetSize
    MinimumWorkingSetSize
    Name (generally the name of the executable file)
    ProcessId
    UserModeTime

You may find other keys available as well, depending on which
operating system you're using, and which variant of Process::Info
you're using.

This method also optionally takes as its first argument a reference
to a hash of option values. The only supported key is:

    no_user_info => 1
	Do not return keys Owner and OwnerSid, even if available.
	These tend to be time-consuming, and can cause problems
	under the WMI variant.

=cut

sub GetProcInfo {
    confess
    "Programming Error - Whoever coded this forgot to override GetProcInfo.";
}

=item Win32::Process::Info->import ()

The purpose of this static method is to specify which variants of the
functionality are legal to use. Possible arguments are 'NT', 'WMI',
'PT', or some combination of these (e.g. ('NT', 'WMI')). Unrecognized
arguments are ignored, though this may change if this class becomes a
subclass of Exporter. If called with no arguments, it is as though it
were called with arguments ('NT', 'WMI', 'PT'). See L</BUGS>, below, for
why this mess was introduced in the first place.

This method must be called at least once, B<in a BEGIN block>, or B<no>
variants will be legal to use. Usually it does B<not> need to be
explicitly called by the user, since it is called implicitly when you
C<use Win32::Process::Info;>. If you C<require Win32::Process::Info;>
you B<will> have to call this method explicitly.

If this method is called more than once, the second and subsequent calls
will have no effect on what variants are available. The reason for this
will be made clear (I hope!) under L</USE IN OTHER MODULES>, below.

The only time a user of this module needs to do anything different
versus version 1.006 and previous of this module is if this module is
being loaded in such a way that this method is not implicitly called.
This can happen two ways:

 use Win32::Process::Info ();

explicitly bypasses the implicit call of this method. Don't do that.

 require Win32::Process::Info;

also does not call this method. If you must load this module using
require rather than use, follow the require with

 Win32::Process::Info->import ();

passing any necessary arguments.

=cut

{	# Begin local symbol block.

    my $idempotent;

    sub import {	## no critic (RequireArgUnpacking)
	my ($pkg, @params) = @_;
	my (@args, @vars);
	foreach (@params) {
	    if (exists $variant_support{$_}) {
		push @vars, $_;
	    } else {
		push @args, $_;
	    }
	}

	if ($idempotent++) {
	    # Warning here maybe?
	} else {
	    @vars or push @vars, keys %variant_support;
	    foreach my $try (@vars) {
		$variant_support{$try} or next;
		$variant_support{$try}{unsupported} = eval {
		    $variant_support{$try}{check_support}->()} || $@;
	    }
	}

	return;

#	Do this if we become a subclass of Exporter
#	@_ = ( $pkg, @args );
#	goto &Exporter::import;;
    }

    # Return the number of times import() done.
    sub _import_done {
	return $idempotent;
    }

}	# End local symbol block.


{
    my $is_reactos = $^O eq 'MSWin32' &&
	defined $ENV{OS} && lc $ENV{OS} eq 'reactos';
    sub _isReactOS {
	return $is_reactos;
    }
}


=item %subs = $pi->Subprocesses ([pid ...])

This method takes as its argument a list of PIDs, and returns a hash
indexed by PID and containing, for each PID, a reference to a list of
all subprocesses of that process. If those processes have subprocesses
as well, you will get the sub-sub processes, and so ad infinitum, so
you may well get back more hash keys than you passed process IDs. Note
that the process of finding the sub-sub processes is iterative, not
recursive; so you don't get back a tree.

If no argument is passed, you get all processes in the system.

If called in scalar context you get a reference to the hash.

This method works off the ParentProcessId attribute. Not all variants
support this. If the variant you're using doesn't support this
attribute, you get back an empty hash. Specifically:

 NT -> unsupported
 PT -> supported
 WMI -> supported

=cut

sub Subprocesses {
my ($self, @args) = @_;
my %prox = map {($_->{ProcessId} => $_)}
	@{$self->GetProcInfo ({no_user_info => 1})};
my %subs;
my $rslt = \%subs;
my $key_found;
foreach my $proc (values %prox) {
    $subs{$proc->{ProcessId}} ||= [];
    # TRW 1.011_01 next unless $proc->{ParentProcessId};
    defined (my $pop = $proc->{ParentProcessId}) or next; # TRW 1.011_01
    $key_found++;
    # TRW 1.011_01 next unless $prox{$proc->{ParentProcessId}};
    $prox{$pop} or next;	# TRW 1.011_01
# TRW 1.012_02    $proc->{CreationDate} >= $prox{$pop}{CreationDate} or next;	# TRW 1.011_01
    (defined($proc->{CreationDate}) &&
	defined($prox{$pop}{CreationDate}) && 
        $proc->{CreationDate} >= $prox{$pop}{CreationDate})
	or next;	# TRW 1.012_02
    # TRW 1.011_01 push @{$subs{$proc->{ParentProcessId}}}, $proc->{ProcessId};
    push @{$subs{$pop}}, $proc->{ProcessId};
    }
my %listed;
return %listed unless $key_found;
if (@args) {
    $rslt = \%listed;
    while (@args) {
	my $pid = shift @args;
	next unless $subs{$pid};	# TRW 1.006
	next if $listed{$pid};
	$listed{$pid} = $subs{$pid};
	push @args, @{$subs{$pid}};
	}
    }
return wantarray ? %$rslt : $rslt;
}

=item @info = $pi->SubProcInfo ();

This is a convenience method which wraps GetProcInfo(). It has the same
calling sequence, and returns generally the same data. But the data
returned by this method will also have the {subProcesses} key, which
will contain a reference to an array of hash references representing the
data on subprocesses of each process.

Unlike the data returned from Subprocesses(), the data here are not
flattened; so if you specify one or more process IDs as arguments, you
will get back at most the number of process IDs you specified; fewer if
some of the specified processes do not exist.

B<Note well> that a given process can occur more than once in the
output. If you call SubProcInfo without arguments, the @info array will
contain every process in the system, even those which are also in some
other process' {subProcesses} array.

Also unlike Subprocesses(), you will get an exception if you use this
method with a variant that does not support the ParentProcessId key.

=cut

sub SubProcInfo {
    my ($self, @args) = @_;
    my $opt = ref $args[0] eq 'HASH' ? shift @args : {};
    my @data = $self->GetProcInfo ($opt);
    my %subs = map {$_->{ProcessId} => $_} @data;
    my $bingo;
    foreach my $proc (@data) {
	exists $proc->{ParentProcessId} or next;
	$proc->{subProcesses} ||= [];
	$bingo++;
	defined (my $dad = $subs{$proc->{ParentProcessId}}) or next;
	(defined $dad->{CreationDate} && defined $proc->{CreationDate})
	    or next;
	$dad->{CreationDate} > $proc->{CreationDate} and next;
	push @{$dad->{subProcesses} ||= []}, $proc;
    }
    $bingo or croak "Error - Variant '@{[$self->Get('variant')
    ]}' does not support the ParentProcessId key";
    if (@args) {
	return (map {exists $subs{$_} ? $subs{$_} : ()} @args);
    } else {
	return @data;
    }
}

=item $pid = $pi->My_Pid()

This convenience method returns the process ID of the current process,
in a form appropriate to the operating system and the variant in use.
Normally, it simply returns C<$$>. But Cygwin has its own idea of what
the process ID is, which may differ from Windows. Worse than that, under
Cygwin the NT and WMI variants return Windows PIDs, while PT appears to
return Cygwin PIDs.

=cut

# This is defined above, trickily, as an assignment to *My_Pid, so we
# don't have to test $^O every time. It's above because code in a BEGIN
# block needs it.

=item $text = Win32::Process::Info->variant_support_status($variant);

This static method returns the support status of the given variant. The
return is false if the variant is supported, or an appropriate message
if the variant is unsupported.

This method can also be called as a normal method, or even as a
subroutine.

=cut

sub variant_support_status {
    my @args = @_;
    my $variant = pop @args or croak "Variant not specified";
    exists $variant_support{$variant}
	or croak "Variant '$variant' is unknown";
    _import_done()
	or croak __PACKAGE__,
	    '->import() must be called before calling ', __PACKAGE__,
	    '->variant_support_status()';
    return $variant_support{$variant}{unsupported};
}

=item print "$pi Version = @{[$pi->Version ()]}\n"

This method just returns the version number of the
Win32::Process::Info object.

=cut

sub Version {
return $Win32::Process::Info::VERSION;
}

#
#	$self->_build_hash ([hashref], key, value ...)
#	builds a process info hash out of the given keys and values.
#	The keys are assumed to be the WMI keys, and will be trans-
#	formed if needed. The values will also be transformed if
#	needed. The resulting hash entries will be placed into the
#	given hash if one is present, or into a new hash if not.
#	Either way, the hash is returned.

sub _build_hash {
my ($self, $hash, @args) = @_;
$hash ||= {};
while (@args) {
    my $key = shift @args;
    my $val = shift @args;
    $val = $self->{_xfrm}{$key}->($self, $val)
	if (exists $self->{_xfrm}{$key});
    $hash->{$key} = $val;
    }
return $hash;
}


#	$self->_clunks_to_desired (clunks ...)
#	converts elapsed times in clunks to elapsed times in
#	seconds, PROVIDED $self->{elapsed_in_seconds} is TRUE.
#	Otherwise it simply returns its arguments unmodified.

sub _clunks_to_desired {
my $self = shift;
@_ = map {defined $_ ? $_ / 10_000_000 : undef} @_ if $self->{elapsed_in_seconds};
return wantarray ? @_ : $_[0];
}

#	$self->_date_to_time_t (date ...)
#	converts the input dates (assumed YYYYmmddhhMMss) to
#	Perl internal time, returning the results. The "self"
#	argument is unused.


sub _date_to_time_t {
my ($self, @args) = @_;
my @result;
local $^W = 0;	# Prevent Time::Local 1.1 from complaining. This appears
		# to be fixed in 1.11, but since Time::Local is part of
		# the ActivePerl core, there's no PPM installer for it.
		# At least, not that I can find.
foreach (@args) {
    if ($_) {
	my ($yr, $mo, $da, $hr, $mi, $sc) = m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
	--$mo;
	my $val = timelocal ($sc, $mi, $hr, $da, $mo, $yr);
	push @result, $val;
	}
      else {
	push @result, undef;
	}
    }
return @result if wantarray;
return $result[0];
}

1;
__END__

=back

=head1 USE IN OTHER MODULES

Other modules that use this module are also subject to the effects of
the collision between Win32::OLE and the emulated fork call, and to the
requirements of the import() method. I will not address subclassing,
since I am not sure how well this module subclasses (the variants are
implemented as subclasses of this module).

Modules that simply make use of this module (the 'has-a' relationship)
should work as before, B<provided> they 'use Win32::Process::Info'. Note
that the phrase 'as before' is literal, and means (among other things),
that you can't use the emulated fork.

If you as the author of a module that uses Win32::Process::Info wish to
allow emulated forks, you have a number of options.

The easiest way to go is

 use Win32::Process::Info qw{NT};

if this provides enough information for your module.

If you would prefer the extra information provided by WMI but can
operate in a degraded mode if needed, you can do something like

 use Win32::Process::Info ();
 
 sub import {
    my $pkg = shift;
    $pkg->SUPER::import (@_);  # Optional (see below)
    Win32::Process::Info->import (@_);
 }

The call to $pkg->SUPER::import is needed only if your package is a
subclass of Exporter.

Note to users of modules that require this module:

If the above 'rules' are violated, the symptoms will be either that you
cannot instantiate an object (because there are no legal variants) or
that you cannot use fork (because the WMI variant was enabled by
default). The workaround for you is to

 use Win32::Process::Info;

before you 'use' the problematic module. If the problem is coexistence
with fork, you will of course need to

 use Win32::Process::Info qw{NT};

This is why only the first import() sets the possible variants.

=head1 ENVIRONMENT

This package is sensitive to a number of environment variables.
Note that these are normally consulted only when the package
is initialized (i.e. when it's "used" or "required").

PERL_WIN32_PROCESS_INFO_VARIANT

If present, specifies which variant(s) are tried, in which
order. The default behavior is equivalent to specifying
'WMI,NT'. This environment variable is consulted when you
"use Win32::Process::Info;". If you want to change it in
your Perl code you should use the static Set () method.

PERL_WIN32_PROCESS_INFO_WMI_DEBUG

If present and containing a value Perl recognizes as true,
causes the WMI variant to assert the "Debug" privilege.
This has the advantage of returning more full paths, but
the disadvantage of tending to cause Perl to die when
trying to get the owner information on the newly-accessible
processes.

PERL_WIN32_PROCESS_INFO_WMI_PARIAH

If present, should contain a semicolon-delimited list of process names
for which the package should not attempt to get owner information. '*'
is a special case meaning 'all'. You will probably need to use this if
you assert PERL_WIN32_PROCESS_INFO_WMI_DEBUG.

=head1 REQUIREMENTS

It should be obvious that this library must run under some
flavor of Windows.

This library uses the following libraries:

 Carp
 Time::Local
 Proc::ProcessTable (if using the PT variant)
 Win32::API (if using the NT-native variant)
 Win32API::Registry (if using the NT-native variant)
 Win32::ODBC (if using the WMI variant)

As of ActivePerl 630, none of this uses any packages that are not
included with ActivePerl. Carp and Time::Local have been in the core
since at least 5.004. Your mileage may, of course, vary.

=head1 BUGS

The WMI variant leaks memory - badly for 1.001 and earlier. After
1.001 it only leaks badly if you retrieve the process owner
information. If you're trying to write a daemon, the NT variant
is recommended. If you're stuck with WMI, set the no_user_info flag
when you call GetProcInfo. This won't stop the leaks, but it minimizes
them, at the cost of not returning the username or SID.

If you intend to use fork (), your script will die horribly unless you
load this module as

 use Win32::Process::Info qw{NT};

The problem is that fork() and Win32::OLE (used by the WMI variant) do
not play B<at all> nicely together. This appears to be an acknowledged
problem with Win32::OLE, which is brought on simply by loading the
module. See import() above for the gory details.

The use of the NT and WMI variants under non-Microsoft systems is
unsupported. ReactOS 0.3.3 is known to lock up when GetProcInfo() is
called; since this  works on the Microsoft OSes, I am inclined to
attribute this to the acknowledged alpha-ness of ReactOS. I have no idea
what happens under Wine. B<Caveat user.>

Bugs can be reported to the author by mail, or through
L<http://rt.cpan.org>.

=head1 RESTRICTIONS

You can not C<require> this module except in a BEGIN block. This is a
consequence of the use of Win32::API, which has the same restriction, at
least in some versions.

If you C<require> this module, you B<must> explicitly call C<<
Win32::Process::Info->import() >>, so that the module will know what
variants are available.

If your code calls fork (), you must load this module as

 use Win32::Process::Info qw{NT};

This renders the WMI variant unavailable. See L</BUGS>.

=head1 RELATED MODULES

Win32::Process::Info focuses on returning static data about a process.
If this module doesn't do what you want, maybe one of the following
ones will.

=over 4

=item Proc::ProcessTable by Dan Urist

This module does not as of this writing support Windows, though there
is a minimal Cygwin version that might serve as a starting point. The
'PT' variant makes use of this module.

=item Win32::PerfLib by Jutta M. Klebe

This module focuses on performance counters. It is a ".xs" module,
and requires Visual C++ 6.0 to install. But it's also part of LibWin32,
and should come with ActivePerl.

=item Win32::IProc by Amine Moulay Ramdane

This module is no longer supported, which is a shame because it returns
per-thread information as well. As of December 27, 2004, Jenda Krynicky
(F<http://jenda.krynicky.cz/>) was hosting a PPM kit in PPM repository
F<http://jenda.krynicky.cz/perl/>, which may be usable. But the source
for the DLL files is missing, so if some Windows upgrade breaks it
you're out of luck.

=item Win32API::ProcessStatus, by Ferdinand Prantl

This module focuses on the .exe and .dll files used by the process. It
is a ".xs" module, requiring Visual C++ 6.0 and psapi.h to install.

=item pulist

This is not a Perl module, it's an executable that comes with the NT
resource kit.

=back

=head1 ACKNOWLEDGMENTS

This module would not exist without the following people:

Aldo Calpini, who gave us Win32::API.

Jenda Krynicky, whose "How2 create a PPM distribution"
(F<http://jenda.krynicky.cz/perl/PPM.html>) gave me a leg up on
both PPM and tar distributions.

Dave Roth, F<http://www.roth.net/perl/>, author of
B<Win32 Perl Programming: Administrators Handbook>, which is
published by Macmillan Technical Publishing, ISBN 1-57870-215-1

Dan Sugalski F<sugalskd@osshe.edu>, author of VMS::Process, where
I got (for good or ill) the idea of just grabbing all the data
I could find on a process and smashing it into a big hash.

The folks of Cygwin (F<http://www.cygwin.com/>), especially Christopher
G. Faylor, author of ps.cc.

Judy Hawkins of Pitney Bowes, for providing testing and patches for
NT 4.0 without WMI.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2005 by E. I. DuPont de Nemours and Company, Inc. All
rights reserved.

Copyright (C) 2007-2011, 2013-2014 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
