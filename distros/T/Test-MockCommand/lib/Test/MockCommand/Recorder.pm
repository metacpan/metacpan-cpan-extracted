package Test::MockCommand::Recorder;
use strict;
use warnings;

use Cwd;
use Carp qw(croak);
use Symbol;

use Test::MockCommand::Result;
use Test::MockCommand::TiedFH;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub handle {
    my $self = shift;
        croak "odd number of parameters" if @_ % 2;
    my %args = @_;

    # check arguments
    for (qw(command function arguments caller)) {
	croak "no $_ parameter" unless exists $args{$_};
    }

    # check function is one we know
    croak "unknown function $args{function}"
      unless $args{function} =~ /^(open|readpipe|system|exec)$/;

    # do we want to handle recording this command?
    return undef unless $self->matches(%args);

    # capture data before running the command
    $args{result} = $self->pre_capture(%args);

    # emulate and record the appropriate function
    if ($args{function} eq 'open') {
	$args{return_value} = $self->record_open(%args);
    }
    elsif ($args{function} eq 'readpipe') {
	$args{return_value} = $self->record_readpipe(%args);
    }
    elsif ($args{function} eq 'system') {
	$args{return_value} = $self->record_system(%args);
    }
    elsif ($args{function} eq 'exec') {
	$args{return_value} = $self->record_exec(%args);
    }

    # capture data after running the command
    $self->post_capture(%args);

    # return the result object
    return $args{result};
}

sub matches {
    # always record commands
    return 1;
}

sub pre_capture {
    my $self = shift;

    # create result object
    my $result = Test::MockCommand::Result->new(@_);

    # set the current working directory
    $result->cwd(Cwd::cwd());

    # TODO: check command line to see if it's a shell invocation, and if so,
    # check if it uses an external source of input with the '<' operator

    return $result;
}

sub post_capture {
    my $self = shift;
    my %args = @_;

    $args{result}->return_value($args{return_value});

    $args{result}->exit_code($?);

    # TODO: check command line to see if it's a shell invocation, and if so,
    # check if it writes or appends to an external output file with the
    # '>', '>>', '2>', etc. operators
}

sub record_open {
    my $self = shift;
    my %all_args = @_;
    my $args = $all_args{arguments};

    # call the real open() using our own filehandle
    my $fh = undef;
    my $opened = (@{$args} < 3)
        ? CORE::open($fh, $args->[-1])
	: CORE::open($fh, $args->[1], $args->[2], splice(@{$args}, 3));
    return 0 unless $opened;

    # make our own filehandle and tie it to the open FH and result object
    my $our_fh = $self->create_tied_fh($fh, $all_args{result});

    # create the requested filehandle
    if (defined $args->[0]) {
	# file handle is a bareword symbol reference
	my $sym = Symbol::qualify($args->[0], $all_args{caller}->[0]);

	no strict 'refs';
	*$sym = $our_fh;
    }
    else {
	$args->[0] = $our_fh;
    }

    # return result of open
    return $opened;
}

sub create_tied_fh {
    my ($self, $real_open_fh, $result_object) = @_;
    my $fh = gensym();
    tie *$fh, 'Test::MockCommand::TiedFH', 1, $real_open_fh, $result_object;
    return $fh;
}

sub record_system {
    my $self = shift;
    my %args = @_;
    return CORE::system(@{$args{arguments}});
}

sub record_exec {
    my $self = shift;
    return $self->record_system(@_);
}

sub record_readpipe {
    my $self = shift;
    my %args = @_;
    # handle() will automatically split this according to $/
    # if needed, but we always return it as a scalar
    return join '', CORE::readpipe(@{$args{arguments}});
}

1;

__END__

=head1 NAME

Test::MockCommand::Recorder - emulates and records command output

=head1 SYNOPSIS

 # as called by Test::MockCommand
 my $recorder = Test::MockCommand::Recorder->new();
 my $result_object = $recorder->handle(
     command     => 'ls -l',
     function    => 'readpipe', # or 'exec', 'system' or 'open',
     arguments   => \@_,
     caller      => [ caller() ]
 );

=head1 DESCRIPTION

This class which is the default 'recorder' class for L<Test::MockCommand>.
It is automatically loaded, you don't need to add it yourself. 

It carries out the brunt of the recording work, including emulating
the system calls. However, it has been designed to be easy to
sub-class and override, so you can make your own recorder to collect
extra or different data while re-using as much of the system call
emulations as you want.

=head1 CONSTRUCTOR

=over

=item new()

Creates a new recorder object.

=back

=head1 METHODS

=over

=item $result = $recorder->handle(%args)

This is called by the main L<Test::MockCommand> framework in order to
handle recording and emulating a system call. It should return
C<undef> if it can't handle this particular call. It should return a
result object (either L<Test::MockCommand::Result> or something with
the same methods), encapsulating the entire call. The framework passes
a hashlist of arguments, these are:

=over

=item command

A string with roughly the command being run. Don't use this as the
command to run, rather use the C<function> and C<arguments> parameters
to make an precise emulation.

=item function

A string with the function you need to emulate. This will be C<exec>,
C<open>, C<readpipe> or C<system>.

=item arguments

An arrayref to the original arguments of the function. Be careful to
use them by reference rather than copying them, for example if the
first argument to open() is C<undef> because open() should be filling
it in.

=item caller

An arrayref containing the results of caller(), collected at the start
of the emulated function. This lets you see who called open(),
system(), etc.

=back

In order to make it easy to build your own recording objects, the
implementation of handle() calls out to other methods on the object to
do the work of handling.

First it calls C<matches(%args)> to see if it should record this
command, or just return C<undef> immediately.

Next, it calls C<pre_capture(%args)> and expects to get back a result
object. It puts this object in C<$args{result}>.

It then calls record_open(), record_system(), record_readpipe() or
record_exec(), based on the function being emulated. It puts the
result of this call into C<$args{return_value}>.

Finally, it calls C<post_capture(%args)>.

It returns the result object created by pre_capture().

=item $should_handle = $recorder->matches(%args)

This should return non-zero if the recorder can handle this command,
or zero if it cannot.

=item $result = $recorder->pre_capture(%args)

This gets called before any matched command. It should return an
object that will be used to store command results. Whatever it returns
will be added to the C<%args> hash with the key C<result>. It's B<not>
possible to stop the capture by returning C<undef> here, use the
matches() method for that.

=item $return_value = $recorder->record_open(%args)

This should emulate a call to open(), but instead of letting open()
create the filehandle specified by the caller, it should create a
intermediary "fake" tied filehandle that passes on reads and writes to
the real filehandle. If all you want to change is the code
implementing this fake filehandle, override the create_tied_fh()
method instead of this method.

The returned value will be added to the C<%args> hash with the key
C<return_value>.

=item $new_fh = $recorder->create_tied_fh($real_fh, $result_object)

Creates a L<Test::MockCommand::TiedFH> filehandle attached to this object.

=item $return_value = $recorder->record_system(%args)

This should emulate a call to system(). The returned value will be
added to the C<%args> hash with the key C<return_value>.

=item $return_value = $recorder->record_readpipe(%args)

This should emulate a call to readpipe(). It should always return a
scalar. If an array is wanted, the Test::MockCommand framework will
split it up according to C<$/>. The returned value will be added to
the C<%args> hash with the key C<return_value>.

=item $recorder->record_exec(%args)

This should emulate a call to exec(), except it shouldn't exit Perl
after running the command, as exec() would. Just return as normal -
the return value is stored, but is unimportant - and the
Test::MockCommand framework will exit Perl with the appropriate exit
code after saving the database.

=item $recorder->post_capture(%args)

This gets called after emulating the command. It can add any extra
data only known after running the command, for example the command's
exit code or the contents of any files that the command is known to
have created.

=back

=cut
