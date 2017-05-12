package Test::MockCommand;
use warnings;
use strict;

use Carp qw(carp croak);
use Data::Dumper;
use Symbol;

# Not all systems implement the WIFEXITED/WEXITSTATUS macros
use POSIX qw(WIFEXITED WEXITSTATUS);
eval { WIFEXITED(0); };
if ($@ =~ /not (?:defined|a valid|implemented)/) {
    no warnings 'redefine';
    *WIFEXITED   = sub { not $_[0] & 0xff };
    *WEXITSTATUS = sub { $_[0] >> 8  };
}

use Test::MockCommand::Recorder;
use Test::MockCommand::Result;
use Test::MockCommand::ScalarReadline qw(scalar_readline);

our $VERSION = '0.03';
our $CLASS = __PACKAGE__;
our $OPEN_HANDLER = undef; # this gets set to _default_open_handler
our $RECORDING = 0;        # are we recording commands or playing them back?
our $RECORDING_TO = undef; # where to save results when the program ends
our %COMMANDS;             # results db: $COMMANDS{$cmd} = [ $result, ... ]
our @RECORDERS = ( Test::MockCommand::Recorder->new() );

#carp "WARNING: need perl v5.9.5 or better to mock qx// and backticks"
#    if $] < 5.009005;

$CLASS->open_handler(undef); # set up _default_open_handler
$CLASS->_hook_core_functions();

sub import {
    if (@_ >= 3 && $_[1] eq 'record') {
	$CLASS->auto_save($_[2]);
	$CLASS->recording(1);
    }
    elsif (@_ >= 3 && $_[1] eq 'playback') {
        $CLASS->load($_[2]);
    }
}

END { $CLASS->_do_autosave(); }

sub _do_autosave {
    my $class = shift;
    $class->save($RECORDING_TO) if defined $RECORDING_TO;

}

# hook into core functions that can execute external commands
sub _hook_core_functions {
    my $class = shift;

    *CORE::GLOBAL::system = sub {
	my $cmd = join(' ', @_);
	return $class->_handle('system', $cmd, \@_, [caller()]);
    };

    *CORE::GLOBAL::exec = sub {
	my $cmd = join(' ', @_);
	return $class->_handle('exec', $cmd, \@_, [caller()]);
    };

    *CORE::GLOBAL::readpipe = sub {
	my $cmd = $_[-1];
	return $class->_handle('readpipe', $cmd, \@_, [caller()]);
    };

    *CORE::GLOBAL::open = sub (*;$@) {
	croak "Not enough arguments for open()" unless @_ > 0;
	# handle open()s that invoke a command
	if (@_ < 3) {
	    # 1/2-arg open()
	    my $file = $_[-1];
	    croak "Can't open bidirectional pipe" if $file =~/^\s*\|(.+)\|\s*$/;
	    return $class->_handle('open', $1, \@_, [caller()])
	        if $file =~ /^\s*\|\s*(.+?)\s*$/;
	    return $class->_handle('open', $1, \@_, [caller()])
	        if $file =~ /^\s*(.+?)\s*\|\s*$/;
	}
	else {
	    # 3-arg open()
	    return $class->_handle('open', join(' ', splice(@_, 2)), \@_,
				  [caller()])
	        if $_[1] =~ /^\s*-\|/;
	    return $class->_handle('open', join(' ', splice(@_, 2)), \@_,
				  [caller()])
	        if $_[1] =~ /^\s*\|-/;
	}

	# pass through the rest
	return $OPEN_HANDLER->(\@_, caller());
    };
}

sub _handle {
    my ($class, $func, $cmd, $args, $caller) = @_;

    my %args = (
        command     => $cmd,
	function    => $func,
	arguments   => $args,
	caller      => $caller,
    );

    my $result = undef;
    my $return = undef;

    if ($RECORDING) {
	# recording mode: find a capable recorder
	for my $recorder (@RECORDERS) {
	    $result = $recorder->handle(%args);
	    last if defined $result;
	}

	if ($result) {
	    # save result in database
	    $COMMANDS{"$func:$cmd"} ||= [];
	    push @{$COMMANDS{"$func:$cmd"}}, $result;
	    $return = $result->return_value();
	}
    }
    else {
	# not in recording mode; look up results database instead.
	my @possible = $class->find(%args);
	if (@possible) {
	    $result = $possible[0];
	    $return = $result->handle(%args, all_results => \@possible);
	}
    }

    # warn and pass through if no matching commands
    if (! defined $result) {
	carp "can't mock $func() command \"$cmd\", passing through";
	return $OPEN_HANDLER->($args, $caller->[0]) if $func eq 'open';
	return CORE::readpipe(@{$args})             if $func eq 'readpipe';
	return CORE::system(@{$args})               if $func eq 'system';
	return CORE::exec(@{$args})                 if $func eq 'exec';
    }

    # if exec() was called, save the db and exit
    if ($func eq 'exec') {
	$class->_do_autosave();
	my $code = $result->exit_code();
	exit(WIFEXITED($code) ? WEXITSTATUS($code) : $code);
    }

    # readpipe() emulation should always return a scalar, so
    # emulation of $/ behaviour is used in list context
    return scalar_readline($return) if $func eq 'readpipe' && wantarray();

    # return with the function's result
    return $return;
}

# this is the default $OPEN_HANDLER, use for any non-command-executing
# open(), also for command-executing open()s when there's no matching
# recorder or result
sub _default_open_handler {
    my ($args, $pkg) = @_;

    # we might need to use a bareword symbol reference in the open() call
    no strict 'refs';

    # if defined, open()'s file handle is a bareword symbol reference which
    # should be qualified as being in the calling package's namespace.
    my $ref = defined($args->[0]) ? Symbol::qualify($args->[0], $pkg) : undef;

    # open() is finicky about its arguments, it doesn't like just @{$args}.
    # If the file handle is undefined, we refer directly to it so that open()
    # can use the pass-by-reference to assign a new value into it.
    return CORE::open($ref || $args->[0]) if @{$args} == 1;
    return CORE::open($ref || $args->[0], $args->[1]) if @{$args} == 2;
    return CORE::open($ref || $args->[0], $args->[1], splice(@{$args}, 2));
}

sub clear {
    %COMMANDS = ();
}

sub load {
    my $class = shift;
    my $file = shift;
    croak "no file specified" unless defined $file;

    $class->clear();
    $class->merge($file);
}

sub merge {
    my $class = shift;
    my $file = shift;
    croak "no file specified" unless defined $file;
    croak "$file is a directory" if -d $file;

    # read and evaluate file, which should set up $VAR1
    my $VAR1 = undef;
    local $/; # enable slurp mode
    open(my $fh, '<', $file) or croak "can't open $file: $!";
    eval <$fh>;
    close $fh;
    croak "failure loading $file: $@" if $@;
    croak "failure loading $file: \$VAR1 not defined" unless defined $VAR1;

    # merge $VAR1 into %COMMANDS
    for my $cmd (keys %{$VAR1}) {
	$COMMANDS{$cmd} ||= [];
	push @{$COMMANDS{$cmd}}, @{$VAR1->{$cmd}};
    }
}

sub save {
    my $class = shift;
    my $file = shift;

    # use auto-save file if no file specified
    $file = $RECORDING_TO unless defined $file;
    croak "no file specified and auto-save not enabled" unless defined $file;

    open FH, ">$file" or croak "can't save to $file: $!";
    print FH Dumper(\%COMMANDS) or croak "can't write results to $file: $!";
    close FH or croak "can't close $file: $!";
}

sub add_recorder {
    my $class = shift;
    my $recorder = shift || croak 'no recorder provided';
    croak "recorder has no handle() method"
        unless UNIVERSAL::can($recorder, 'handle');
    unshift @RECORDERS, $recorder;
}

sub remove_recorder {
    my $class = shift;
    my $recorder = shift || croak 'no recorder provided';
    @RECORDERS = grep { $_ != $recorder } @RECORDERS;
}

sub recorders {
    return @RECORDERS;
}

sub find {
    my $class = shift;
    croak "odd number of parameters" if @_ % 2;
    my %args = @_;

    my @keys;
    if (exists $args{command}) {
	if (ref $args{command} eq 'Regexp') {
	    my $re = exists $args{function}
	        ? qr/^\Q$args{function}\E:(.+)/
	        : qr/^(?:exec|open|readpipe|system):(.+)/;
	    @keys = grep { $_ =~ $re && $1 =~ $args{command} } keys %COMMANDS;
	}
	else {
	    @keys = grep {exists $COMMANDS{$_}} map {"$_:$args{command}"}
	        (exists $args{function}
		 ? ($args{function})
		 : qw(exec open readpipe system));
	}
    }
    else {
	@keys = keys %COMMANDS;
	@keys = grep {/^\Q$args{function}\E:/} @keys if exists $args{function};
    }

    # we can't just return sort{} grep{}... as the expression gives
    # undef when the caller wants a scalar context... why?
    my %score;
    my @results = sort { $score{$b} <=> $score{$a} }
                  grep { $score{$_} = $_->matches(%args) }
		  map  { @{$COMMANDS{$_}} }
		  @keys;
    return @results;
}

sub all_commands {
    return map { @{$_} } values %COMMANDS;
}

sub recording {
    my $class = shift;
    if (@_ >= 1) {
	croak 'value to recording() not valid' unless defined $_[0];
	$RECORDING = shift;
    }
    return $RECORDING;
}

sub auto_save {
    my $class = shift;
    $RECORDING_TO = shift if @_ >= 1;
    return $RECORDING_TO;
}

sub open_handler {
    my $class = shift;
    croak 'wrong number of parameters' unless @_ == 1;
    if (defined $_[0]) {
	croak 'parameter must be coderef' unless ref $_[0] eq 'CODE';
	$OPEN_HANDLER = $_[0];
    }
    else {
	$OPEN_HANDLER = \&_default_open_handler;
    }
}

1;

__END__

=head1 NAME

Test::MockCommand - provide mock results for external commands

=head1 SYNOPSIS

 use Test::Simple tests => 1;
 use Test::MockCommand record => 'commands.db';

 # run 'ls -l', secretly storing its output
 unlink 'testfile.dat';
 my $list = `ls -l`;

 # look up stored command and test its output
 my ($cmd) = Test::MockCommand->find(command => 'ls -l');
 ok $cmd->return_value() eq $list;

 # go into playback mode
 Test::MockCommand->record(0);

 # run 'ls -l' again while extra file is in the directory
 # should pull result from store, not real life,
 # thus should not see the extra file
 open(my $fh, '>testfile.dat') && close $fh;
 my $again = `ls -l`;
 ok $list eq $again;

=head1 DESCRIPTION

Test::MockCommand is a module for recording the output of external
commands that are invoked by a perl program, and allowing them to be
"played back" later. The module hooks into Perl's core routines, so
you simply need to load the module and everything after that is
automatic.

=head2 Recording command output

Recording is enabled by loading the module with the C<record> parameter:

 use Test::MockCommand record => 'output_filename';

You can also achieve this without module parameters:

 Test::MockCommand->auto_save('output_filename');
 Test::MockCommand->recording(1);

External commands are captured if invoked via `backticks`, C<qx//>,
readpipe(), system() or via open() reading or writing to a pipe.
2-way and 3-way IPC is currently unsupported.

Along with the command string itself, the command's input, output,
return code and current working directory are recorded.

All commands run will be captured and collected in a database. When
the perl script ends, the database will be saved to the given output
filename.

You can temporarily turn recording off with C<<
Test::MockCommand->recording(0) >>, and turn it back on with C<<
Test::MockCommand->recording(1) >>. This only stops new commands being
captured. If any commands have already been captured, they will be
still be saved when the program ends, regardless of whether recording
is stopped.

If you want to avoid saving altogether, use C<<
Test::MockCommand->auto_save(undef) >>. If you want to save early, use
C<< Test::MockCommand->save() >>.

=head2 Defining special handling for commands

In case the default recording is not be enough, you can override the
default behaviour with the add_recorder() method. This allows you to
add to a chain of recording objects. When a command is being recorded,
each recorder is invoked in turn, until one returns a valid result.

The default recorder object is L<Test::MockCommand::Recorder>, which
is also designed to be easy to sub-class, saving you from
reimplementing core recording functionality. See that class's
documentation for further details.

=head2 Playing back command output

To play back commands rather than record them, simply load the module
without turning on recording mode, and load in a database of
previously recorded commands. You can then use backticks, C<qx//>,
readpipe(), system(), exec() or open() to a pipe as you normally
would. If the command being executed appears in the database, it will
be simulated rather than actually run.

You can load a database at the same time you load the module with the
C<playback> module parameter:

 use Test::MockCommand playback => 'input_filename';

If no appropriate command is found in the database, a warning is
issued and the function acts as normal, running real external
commands.

=head2 How are commands distinguished?

Commands are stored in the database by a single string, which is
composed from the method of invocation, the command being executed and
any arguments. For example, C<`ls -l`> becomes the string
C<"readpipe:ls -l"> and C<system('rm', 'file')> becomes the string
C<"system:rm file">.

In most cases, this is unique. However, you may want to run commands
more than once, and the results are different because the environment
they run in is different. C<dir> produces different output depending
on the directory you are in. C<date> produces different output
depending on the time of day. C<whoami> depends on the current user.

To allow for this, multiple command results can be stored under the
same string. Each result object is asked in turn if it's the correct
object via the matches() method, and a list is collected of objects
that say "yes" by returning non-zero values. If more than one object
says "yes". the list is sorted by the numeric value of each "yes", and
the first object in the sorted list is used as a result.  See
L<Test::MockCommand::Result/matches> for more information.

=head1 CLASS METHODS

=over

=item Test::MockCommand->clear()

Clears the database of stored command results.

=item Test::MockCommand->merge($filename)

Adds the command results saved in C<$filename> to the current
database.

=item Test::MockCommand->load($filename)

Loads the command results saved in C<$filename>, overwriting any
existing results. You can also do this using 'playback' on the import line:

 use Test::MockCommand playback => 'filename.dat';

=item Test::MockCommand->save()

=item Test::MockCommand->save($filename)

Saves the current database of command results to the file
C<$filename>. If no filename parameter is provided, the auto-save
filename is used, should that be set. Will throw an error if no
filename is given and there's no auto-save filename set.

=item Test::MockCommand->add_recorder($recorder)

Registers a recorder object. It will be asked to record commands by
having its C<handle> method called. See
L<Test::MockCommand::Recorder/handle> for more details.

=item Test::MockCommand->remove_recorder($recorder)

Unregisters a recorder. It will no longer be asked to record commands.

=item @list = Test::MockCommand->recorders()

Returns a list of all registered recorder objects.

=item @list = Test::MockCommand->find(%criteria)

Finds command(s) matching the criteria given as parameters. These can
be anything the objects implementing the command results know
about. The function looks at all relevant command results and calls
their matches() method, to see if they think they match your
critera. See L<Test::MockCommand::Result/matches> for more
information.  In order to search quickly, the find() function also
directly uses the criteria C<function> and C<command> (if you supply
them) to cut down the potential list of commands to scan.

=item @list = Test::MockCommand->all_commands()

Returns a list of all commands in the database.

=item $is_recording = Test::MockCommand->recording()

Returns non-zero if we're currently recording commands, or zero if
we're not.

=item Test::MockCommand->recording(1)

Starts recording mode. External commands will now be run and their
results added to the database.

=item Test::MockCommand->recording(0)

Stops recording mode. External commands will be played back from the
database if possible.

=item $filename = Test::MockCommand->auto_save()

Returns the auto-save filename, or C<undef> if there is none set.

=item Test::MockCommand->auto_save($filename)

Sets the filename where the database will automatically written to
when the program ends. This will also be the default filename if
save() is called without a parameter.

=item Test::MockCommand->auto_save(undef)

Cancels auto save, nothing will be saved will happen when the program
ends.

=item Test::MockCommand->open_handler($coderef)

As Test::MockCommand globally overrides the L<open> function, this
method allows you to set up your own function to handle all the open()
calls that I<don't> execute a command. The coderef should take two
arguments; the first is an arrayref of arguments to open(), the second
is the package name of the calling function. The second parameter
should be used in order to qualify the first parameter to open(), if
it's a bareword file reference.

As an example, here is a handler that does nothing, simply passing
open() calls through to the real open().

 my $passthough_handler = sub {
     my ($args, $pkg) = @_;
     no strict 'refs';
     my $ref = defined($args->[0]) ? Symbol::qualify($args->[0], $pkg) : undef;
     return CORE::open($ref || $args->[0]) if @{$args} == 1;
     return CORE::open($ref || $args->[0], $args->[1]) if @{$args} == 2;
     return CORE::open($ref || $args->[0], $args->[1], splice(@{$args}, 2));
 };
 Test::MockCommand->open_handler($passthrough_handler);

=item Test::MockCommand->open_handler(undef)

This removes any open() handler. All open() calls will go straight to
the real open().

=back

=head1 REQUIREMENTS

In order to mock backticks and C<qx//> (both special forms of
readpipe()), you need at least Perl version 5.9.5. The ability to
override these special operations was only added in this version. See
Perl change #29168.

=head1 TODO

This module doesn't support mocking L<IPC::Open2> and L<IPC::Open3>.

If it's detected that a shell is being invoked, rather than just a raw
command, and it contains shell redirects (e.g. C<system("cat
</tmp/blah >>/tmp/foo");> that external file should be stored in the
results too, and either used as identifying material (if it's an input
file) or recreated when replayed if it's an output file. The module doesn't
currently do this.

Calls to system() can still print output on stdout and stderr, even if
this is invisible to perl itself. This should be collected and
replicated.

=head1 AUTHOR

Stuart Caie, E<lt>kyzer@4u.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2012 by Stuart Caie

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
