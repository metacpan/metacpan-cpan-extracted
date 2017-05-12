package Win32::MMF;

require 5.00503;
use strict;
use warnings;
use Carp;
use Storable 0.6 qw( freeze thaw );

require Exporter;
require DynaLoader;

our @ISA = qw/ Exporter DynaLoader /;

our @EXPORT_OK = qw/
        GetDebugMode SetDebugMode
        CreateFile OpenFile CloseHandle
        CreateFileMapping OpenFileMapping
        MapViewOfFile UnmapViewOfFile
        ClaimNamespace ReleaseNamespace UseNamespace
        CreateSemaphore WaitForSingleObject ReleaseSemaphore
        InitMMF CreateVar FindVar SetVar GetVar GetVarType DeleteVar
        Malloc Free DumpHeap
    /;

our $VERSION = '0.09';
our $INITFLAG = 0;       # flag to tell the constructor to initialize MMF
our $LOCKFLAG = 0;

croak "This module can only be used under Windows!" if $^O ne "MSWin32";

bootstrap Win32::MMF $VERSION;


# --------------- High-level Name Space Wrapper Functions ---------------


# Sytax: ($swp, $ns) = UseNamespace($swapfile, $namespace);
sub ClaimNamespace {
    my ($swapfile, $namespace, $size) = @_;
    $size = 128 * 1024 if !$size;    # namespace 128K by default

    # attempt to use existing namespace
    my $ns = OpenFileMapping($namespace);

    # open or create swap file if namespace does not exist
    my $swap = 0;
    if (!$ns) {
        if ($swapfile) {
            # use external swap file
            $swap = OpenFile($swapfile) if -f $swapfile;
            $swap = CreateFile($swapfile) if !$swap;
            croak "Can not create swapfile: $!" if !$swap;
        }

        $ns = CreateFileMapping($swap, $size, $namespace);
        $INITFLAG = 1;   # tell the constructor to initialize MMF
    }

    return ($swap, $ns);
}


# Syntax: ReleaseNamespace($swp, $ns);
sub ReleaseNamespace {
    my ($swp, $ns) = @_;
    CloseHandle($ns) if $ns;
    CloseHandle($swp) if $swp;
}


# Test for existance of a Namespace
sub UseNamespace {
    my $namespace = shift;

    # attempt to use existing namespace
    my $ns = OpenFileMapping($namespace);

    return ($ns);
}


# ------------------- Object Oriented Interface -------------------

sub new
{
    my $class = ref($_[0]) || $_[0] || "Win32::MMF";
    
    # the constructor can use default namespace if no namespace
    # is provided by the caller.
    # @_ > 1 or croak "Usage: new $class (\$namespace[, \$size[, \$swapfile]])\n";

    my $self = {
        _namespace => 'shareable',
        _size      => 128 * 1024,  # 128k namespace by default
        _swapfile  => undef,       # use windows virtual memory
        _reuse     => 0,           # reuse existing namespace only
        _autolock  => 1,           # I/O locking by default
        _swap      => 0,           # swap file handle
        _ns        => 0,           # namespace handle
        _view      => 0,           # view handle
        _timeout   => 10,          # default timeout value
        _semaphore => 0,           # semaphore used for exclusive locking
        _debug     => 0,           # debug mode indicator
    };

    # croak "Namespace must be defined!" if !defined $_[1];

    my $allowed_parameters = "namespace|size|swapfile|reuse|autolock|timeout|debug";

    if (@_ > 1) {
    if (ref $_[1] eq 'HASH') {
        # Parameters passed in as HASHREF
        for my $p (keys %{$_[1]}) {
            croak "Unknown parameter '$p', must be [$allowed_parameters]\n"
                if $p !~ /^(?:$allowed_parameters)$/i;
            $self->{'_' . lc $p} = $_[1]->{$p};
        }
    } elsif ($_[1] =~ /^-(?=$allowed_parameters)/i) {
        # Parameters passed in as named parameters
        my (undef, %p) = @_;
        for my $p (keys %p) {
            croak "Unknown parameter '$p', must be [$allowed_parameters]\n"
                if $p !~ /^-(?:$allowed_parameters)$/i;
            $self->{'_' . lc substr($p,1)} = $p{$p};
        }
    } else {
        # Parameters passed in as normal
        (undef, $self->{_namespace}, $self->{_size}, $self->{_swapfile}, $self->{_reuse})
            = @_;
    }
    }

    # croak "Namespace must be defined!" if !$self->{_namespace};

    # turn on/off debug mode
    $self->{_debug} = 1 if $self->{_debug};
    SetDebugMode($self->{_debug});

    # use or open or create namespace
    if ($self->{_reuse}) {
        $self->{_ns} = UseNamespace($self->{_namespace}) or return undef;
    } else {
        ($self->{_swap}, $self->{_ns}) =
            ClaimNamespace($self->{_swapfile}, $self->{_namespace}, $self->{_size});
    }

    # set default view to the namespace
    $self->{_view} = MapViewOfFile($self->{_ns}, 0, $self->{_size});
    InitMMF($self->{_view}, $self->{_size}) if $INITFLAG;

    # create semaphore object for the view
    $self->{_semaphore} = CreateSemaphore(1, 1, $self->{_namespace} . '.lock')
        or croak("Can not create semaphore!");

    bless $self, $class;
}


sub DESTROY {
    my $self = shift;

    # unmap existing views
    UnmapViewOfFile($self->{_view});

    # close namespace and swap file
    ReleaseNamespace($self->{_swap}, $self->{_ns});
}


sub lock
{
    my ($self, $timeout) = @_;
    my $result;

    $timeout = $self->{_timeout} if !$timeout;
    $result = WaitForSingleObject($self->{_semaphore}, $timeout) if !$LOCKFLAG;

    $LOCKFLAG++;
    return $result;
}


sub unlock
{
    my $self = shift;
    $LOCKFLAG--;
    return 0 if $LOCKFLAG;
    return ReleaseSemaphore($self->{_semaphore}, 1);
}


sub findvar
{
    my ($self, $varname) = @_;
    return !(!(FindVar($self->{_view}, $varname)));
}


sub getvar
{
    my ($self, $varname) = @_;
    my $str;
    my $type;

    return undef if !$varname;

    if ($self->{_autolock}) {
        return undef if !$self->lock($self->{_timeout});
        $type = GetVarType($self->{_view}, $varname);

        if (defined $type) {
            $str = GetVar($self->{_view}, $varname);
        }
        $self->unlock();
    } else {
        $type = GetVarType($self->{_view}, $varname);
        return undef if !defined $type;

        $str = GetVar($self->{_view}, $varname);
    }

    if (defined $str && $type) {
        $str = thaw($str);
    }

    return $str;
}


sub setvar
{
    my $self = shift;
    my $varname = shift;
    return 0 if !$varname;

    my $str;        # simple string or serialized object string
    my $type = 0;   # type of the string 0 = simple, 1 = complex

    if (@_ == 1) {
        $str = shift;
        if (ref $str) {
            # serialize if a complex structure
            $str = freeze($str);
            $type = 1;
        }
        # simple string by default
    } else {
        # always serialize if more than 1 data members
        $str = freeze($str);
        $type = 1;
    }

    if ($self->{_autolock}) {
        return 0 if !$self->lock($self->{_timeout});
        if (defined $str) {
            SetVar($self->{_view}, $varname, $type, $str, length($str));
        } else {
            DeleteVar($self->{_view}, $varname);
        }
        $self->unlock();
    } else {
        if (defined $str) {
            SetVar($self->{_view}, $varname, $type, $str, length($str));
        } else {
            DeleteVar($self->{_view}, $varname);
        }
    }
    return 1;
}


sub deletevar
{
    my $self = shift;
    my $varname = shift;
    return 0 if !$varname;
    my $result;

    if ($self->{_autolock}) {
        return 0 if !$self->lock($self->{_timeout});
        $result = DeleteVar($self->{_view}, $varname);
        $self->unlock();
    } else {
        $result = DeleteVar($self->{_view}, $varname);
    }
    return $result;
}


sub debug
{
    my $self = shift;
    DumpHeap($self->{_view});
}

1;

=pod

=head1 NAME

 Win32::MMF - Win32 Memory Mapped File (MMF) Support for Perl

=head1 SYNOPSIS

 # ===== Object Oriented Interface =====
  use Win32::MMF;

  # --- in process 1 ---
  my $ns1 = new Win32::MMF;
  $ns1->setvar('varid', $data);

  # --- in process 2 ---
  my $ns2 = new Win32::MMF;
  $data = $ns2->getvar('varid');


  # ==== Tied Interface ====
  use Win32::MMF::Shareable;

  tie my $s1, "Win32::MMF::Shareable", "varid";
  $s1 = 'Hello world';

  tie my $s2, "Win32::MMF::Shareable", "varid";
  print "$s2\n";    # should print 'Hello world'


=head1 ABSTRACT

This module provides Windows' native Memory Mapped File Service
for shared memory support under Windows. The core of the module
is written in XS and is currently supported only under Windows
NT/2000/XP.

The current version 0.09 of Win32::MMF is available on CPAN at:

  http://search.cpan.org/search?query=Win32::MMF


=head1 DESCRIPTION

=head2 Programming Style

This module provides three types of interfaces - object-oriented,
functional, and tied interfaces (Via C<Win32::MMF::Shareable>).
The default access method is via objects. The functional interface
is not exported by default because it requires a detailed knowledge
of the Windows operating system internals to use properly.

There are many advantages of using the object oriented interface.
For example, the following is the amount of code required in
function-oriented style to create a namespace (a named block of
shared memory). It involves openning or creating a swap file,
creating a memory mapping and finally creating a view:

   use Win32::MMF qw/ ClaimNamespace UseNamespace MapViewOfFile /;

   my ($swap, $ns, $view) = (0, 0, 0);
   $ns = UseNamespace("MyDataShare");
   if (!ns) {
       ($swap, $ns) = ClaimNamespace("data.swp",
                                     "MyDataShare",
                                     2 * 1024 * 1024);
       die "Can not create swap file" if !$swap;
       die "Can not create namespace" if !$ns;
   }

   $view = MapViewOfFile($ns, 0, 1000);

   ...

   UnmapViewOfFile($view);
   ReleaseNamespace($swap, $ns);

The following is the amount of code required to achieve the same
result in object-oriented style:

   use Win32::MMF;

   my $ns = Win32::MMF->new( -swapfile => "data.swp",
                             -namespace => "MyDataShare",
                             -size => 2 * 1024 * 1024 )
       or die "Can not create namespace";

Note that there is no need to explicitly unmap the view, close the
namespace and close the swap file in object-oriented mode, the view,
namespace and swap file handles are automatically closed-off and
disposed of when the Win32::MMF object falls out of scope.

The following is the amount of code required in tied variable style,
which virtually eliminates all hassles dealing with shared memory
under Windows... :-)

    use Win32::MMF::Shareable;

    ...

    tie my $scalar, "Win32::MMF::Shareable", "scalar1",
                    { namespace => "MyDataShare" };
    $scalar = "Hello world";

    tie my %hash = "Win32::MMF::Shareable", "hash1";
    %hash = ( A => '1', B => '2', C => '3' );

    tie my @array = "Win32::MMF::Shareable", "array1";
    @array = qw/ A B C D E /;


=head1 REFERENCE

=head2 Memory Mapped File (MMF) Under Windows

Under Windows, code and data are both repesented by pages of memory
backed by files on disk - code by executable image an data by system
pagefile (swapfile). These are called memory mapped files. Memory
mapped files can be used to provide a mechanism for shared memory
between processes. Different processes are able to share data backed
by the same swapfile, whether it's the system pagefile or a
user-defined swapfile.

Windows has a tight security system that prevents processes from
directly sharing information among each other, but mapped memory files
provide a mechanism that works with the Windows security system - by
using a name that all processes use to open the swapfile.

A shared section of the swapfile is translated into pages of memory
that are addressable by more than one process, Windows uses a system
resource called a prototype page table entry (PPTE) to enable more
than one process to address the same physical page of memory, thus
multiple process can share the same data without violating the Windows
system security.

In short, MMF's provide shared memory under Windows.


=head2 What is a Namespace?

In Win32::MMF a namespace represents shared memory identified by a
unique name. The namespace must be unique system wide. A suggested
convention to follow is <[APPID].[VARID]>.

Example: 'MyApp.SharedMemory'.


=head2 Creating a Namespace Object

There are three ways to pass parameters into the Win32::MMF
object constructor: named parameters, a hashref of parameters
or a list of parameters.

=over 4

=item Using Named Parameters

 $ns = Win32::MMF->new(
              -swapfile => $swapfilename,
              -namespace => $namespace_id,
              -size => 1024,
              -reuse => 0,
              -autolock => 1,
              -timeout => 10 );

The parameter names begin with '-' and are case
insensitive. For example, -swapfile, -Swapfile
and -SwapFile are equivalent.

=item Passing Parameters in a Hashref

 $ns = Win32::MMF->new({
              swapfile => $swapfilename,
              namespace => $namespace_id,
              size => 1024,
              reuse => 0 });

The parameter names do not begin with '-' and
are case insensitive. This mode is good for working
with external configuration files.

=item Passing Parameters in a List

 $ns = Win32::MMF->new(
              $namespace_id,
              $size,
              $swapfile,
              $reuse_flag);

The I<$namespace_id> parameter is mandatory, other
parameters are optional.

=item Input Parameters

=over 4

=item -swapfile

Specify the name of the memory mapped file (swap file).
if it is omitted or undef then the system pagefile will
be used.

=item -namespace

A label that uniquely identifies the shared memory. The
namespace must be unique system wide. A suggested convention
to follow is <[APPID].[VARID]>. This option is mandatory.

=item -size

Specify the size of the memory mapped file in bytes.

=item -reuse

This option tells the constructor to check if the namespace
has already been declared by another process, and use the
existing namespace instead. It gurrantees that a namespace
is not created if it does not exist.

=item -autolock

Automatic read/write locking, turned on by default.

=item -timeout

Specify the number of seconds to wait before timing out
the lock. This value is set to 10 seconds by default. Set
timeout to 0 to wait forever.

=item -debug

Turn on/off the internal MMF debugger.

=back

=back


=head2 Locking a Namespace

All read and write accesses to a namespace are locked
by default. However if auto-locking is turned off, a
namespace can be explicitly locked with the B<lock> method.

$ns->lock($timeout);

=over 4

=item Input Parameters

=over 4

=item $timeout

Number of seconds before the lock attempt fails.

=back

=item Return Values

 undef    Namespace error
 0        Time out waiting for lock
 1        Success

=back


=head2 Unlock A Namespace Object

$ns->unlock();


=head2 Accessing a Namespace

All read and write accesses to a namespace are locked
by default to preserve data integrity across processes.
The L<Storeable> module is used for
data serialization for complex structures.

=head2 Variables inside a Namespace

Each data element written to a namespace is identified
by a unique label (variable name). Variable definitions
are held inside the namespace itself to be shared among
multiple processes. The B<debug> method can be used to
display current variable definitions within the namespace.

Note that variables defined inside a namespace are
considered global and will not be deleted unless the user
explicitly calls the B<deletevar> method or setting the
variable to undef.


=over 4

=item $ns->setvar('VarId', $data, ...);

Serialize all given data and then write the serialized
data into the variable inside the namespace. The variable
will be automatically created if it does not exist.

Because the variable definition table is held inside the
shared memory itself, variables created in one process
can be used by another process immediately.

Beware that setting a namespace variable to empty
string will free up the shared memory currently held by the
variable, but will not delete the variable from the namespace.
Setting the variable to undef will not only free up the
shared memory but also delete the variable from the namespace.

=item $data = $ns->getvar('VarId');

Retrieves the serialized data string from the namespace,
and deserializes back into perl variable(s). Please refer to
the L<Storeable> documentation on how to serialize (freeze) and
retrieve (thaw) data. Simple scalars are not serialized however to
maximize the access efficiency.

=item $ns->deletevar('VarId');

Delete the given variable from the namespace and free up
shared memory allocated to the variable. This is equivalent
to setting a variable to undef.

=item if ($ns->findvar('VarId')) { ... }

Test for the existance of a given variable inside the namespace.


=back

=head2 Debugging a Namespace

There is a built-in method B<debug> that will display as
much information as possible for a given namespace object.

=over 4

=item $ns->debug();

Dump the Memory Mapped File Descriptor (MMFD), shared memory
heap and variable definition table for the namespace.

=back

=head2 Using Tied Variable Interface

The Win32::MMF::Shareable module is modelled after C<IPC::Shareable>.
All options from C<IPC::Shareable> can be used in Win32::MMF::Shareable,
although they are mostly ignored except for the 'label' argument.
Because memory and variable management are managed internally by the
Win32::MMF module, you do not need to specify how much memory is
required by the variable.

All access to tied variables are automatically and exclusively locked
to preserve data integrity across multiple processes.

Win32::MMF::Shareable mimics the operation of C<IPC::Shareable>,
it allows you to tie a variable to a namespace (shared memory)
making it easy to share its content with other Perl processes.

Note that if you try to tie a variable without specifying the 
namespace, the default namespace 'shareable' will be used. If you
want to change how the default namespace is created, provide the
namespace, swapfile and size options when you tie the first variable.

 use Win32::MMF::Shareable;
 tie $scalar, "Win32::MMF::Shareable", "var_1",
              { namespace = 'MyNamespace', size = 1024 * 1024,
                swapfile = 'C:\private.swp' };

The options are exactly the same as the Win32::MMF constructor options.
For compatibility with IPC::Shareable, you can pass in IPC::Shareable
options, although they mostly get ignored, except for the 'key' option.

An alternative is to provide these options when the Win32::MMF::Shareable
module is imported:

 use Win32::MMF::Shareable { namespace = 'MyNamespace',
                             size = 1024 * 1024,
                             swapfile = 'C:\private.swp' };
 tie $scalar,"Win32::MMF::Shareable", "var_1";

Currently only scalars, arrays, and hashes can be tied, I am investigating
on the possibilities with tied file handles at the moment.

To tie a variable to the default namespace:

 tie $scalar, "Win32::MMF::Shareable", "var_1";
 tie @array,  "Win32::MMF::Shareable", "var_2";
 tie %hash,   "Win32::MMF::Shareable", "var_3";

And to use a tied variable:

 $scalar = 'Hello Perl';

 @array = qw/ A B C D E F G /;

 %hash = @array;

=back

=head1 EXAMPLE 1 - setvar, getvar and deletevar

 use strict;
 use warnings;
 use Win32::MMF;
 use Data::Dumper;

 my $ns = new Win32::MMF( -namespace => "MyNamespace" ) or die;

 # setting variables and getting them back
 my $var1 = "Hello world!";
 my $var2 = {
    'Name' => 'Roger',
    'Module' => 'Win32::MMF',
 };

 $ns->setvar('Hello', $var1);
 $ns->setvar('Hash', $var2);
 $ns->debug();

 my $r1 = $ns->getvar('Hello');
 my $r2 = $ns->getvar('Hash');
 print Dumper($r1), Dumper($r2), "\n";

 $ns->deletevar('Hello');
 $ns->setvar('Hash', undef);
 $ns->debug();


=head1 EXAMPLE 2 - inter-process signalling

 use strict;
 use warnings;
 use Win32::MMF::Shareable;

 defined(my $pid = fork()) or die "Can not fork a child process!";

 if (!$pid) {
    tie my $sig1, "Win32::MMF::Shareable", '$signal1';
    tie my $sig2, "Win32::MMF::Shareable", '$signal2';

    print "PROC1 WAIT SIGNAL 2\n";
    while (!$sig2) {};
    print "PROC1 SEND SIGNAL 1\n";

    $sig1 = 1;
 } else {
    tie my $sig1, "Win32::MMF::Shareable", '$signal1';
    tie my $sig2, "Win32::MMF::Shareable", '$signal2';

    print "PROC2 SEND SIGNAL 2\n";
    $sig2 = 1;
    print "PROC2 WAIT SIGNAL 1\n";
    while (!$sig1) {};

    print "PROC2 GOT SIGNAL 1\n";
 }


=head1 SEE ALSO

C<Win32::MMF::Shareable>, C<Storable>

=head1 CREDITS

Credits go to my wife Jenny and son Albert, and I love them forever.

=back


=head1 AUTHOR

Roger Lee <roger@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Roger Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

