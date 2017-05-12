package Test::MockCommand::Result;
use strict;
use warnings;

use Carp qw(croak);
use Symbol;

use Test::MockCommand::TiedFH;

# create some accessor subroutines on the fly
my @ACCESSORS = qw(command function arguments return_value cwd
		   input_data output_data exit_code all_results);
no strict 'refs';
for my $attrib (@ACCESSORS) {
    my $method = __PACKAGE__ . '::' . $attrib;
    next if *$method{CODE};
    *$method = sub {
	$_[0]->{$attrib} = $_[1] if @_ > 1;
	return $_[0]->{$attrib};
    };
}
use strict 'refs';

sub new {
    my $class = shift;
    croak "odd number of parameters" if @_ % 2;
    my %args = @_;
    my $self = {
        command   => $args{command},
	function  => $args{function},
        arguments => [ @{$args{arguments}} ] # copy rather than reference
    };

    # turn the first argument to open() to undef, always
    $self->{arguments}->[0] = undef if $self->{function} eq 'open';

    return bless $self, $class;
}

sub matches {
    my $self = shift;
    croak "odd number of parameters" if @_ % 2;
    my %args = @_;

    # function and command have already been matched

    # check the arguments match exactly
    if (exists $args{arguments}) {
	return 0 if @{$args{arguments}} != @{$self->{arguments}};
	for (my $i = 0; $i < @{$args{arguments}}; $i++) {
	    next if not defined $args{arguments}->[$i] and
	            not defined $self->{arguments}->[$i];
	    return 0 if not defined $args{arguments}->[$i] or
	                 not defined $self->{arguments}->[$i];
	    return 0 if $args{arguments}->[$i] ne $self->{arguments}->[$i];
	}
    }

    # result matches. award more points if cwd matches too
    my $cwd = defined $args{cwd} ? $args{cwd} : Cwd::cwd();
    return $self->cwd() eq $cwd ? 2 : 1;
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

    # set the list of all results
    $self->all_results($args{all_results});

    # handle open() emulation
    if ($args{function} eq 'open' && $self->return_value()) {

	# make our own filehandle and tie it to ourselves
	my $fh = $self->create_tied_fh();

	# create the requested filehandle
	if (defined $args{arguments}->[0]) {
	    no strict 'refs';
	    # file handle is a bareword symbol reference
	    my $sym = Symbol::qualify($args{arguments}->[0], $args{caller}->[0]);
	    *$sym = $fh;
	}
	else {
	    $args{arguments}->[0] = $fh;
	}
    }

    # set the exit code
    $? = $self->exit_code();

    # return the result
    return $self->return_value();
}

sub create_tied_fh {
    my $self = shift;
    my $fh = gensym();
    tie *$fh, 'Test::MockCommand::TiedFH', 0, undef, $self;
    return $fh;
}

sub append_input_data {
    my $self = shift;
    $self->{input_data} ||= '';
    $self->{input_data} .= $_[0];
}

sub append_output_data {
    my $self = shift;
    $self->{output_data} ||= '';
    $self->{output_data} .= $_[0];
}

1;

__END__

=head1 NAME

Test::MockCommand::Result - stores and emulates commands

=head1 SYNOPSIS

 # as called by Test::MockCommand::Recorder
 my %args = (
     command     => 'ls -l',
     function    => 'readpipe', # or 'exec', 'system' or 'open',
     arguments   => \@_,
     caller      => [ caller() ]
 );
 my $result = Test::MockCommand::Result->new(%args);

 # as called by Test::MockCommand
 my $matches = $result->matches(%args);
 my $return_value = $result->handle(
     %args,
     all_results => [ $all, $results, $matched, $including, $yourself ]
 );

=head1 DESCRIPTION

This class which is the 'result' class used, created by
L<Test::MockCommand::Recorder> and queried by L<Test::MockCommand>. It
stores and replays the results of commands.

A result class should support any special features of the recorder
class that creates it.

=head1 CONSTRUCTOR

=over

=item new(%args)

This is called by L<Test::MockCommand::Recorder> as part of its
C<handle> method. It passes on all the same arguments it was given by
the main L<Test::MockCommand> framework. See
L<Test::MockCommand::Recorder/handle> for details of each argument.

=back

=head1 METHODS

=over

=item $match_score = $result->matches(%args)

This method takes a list of criteria and returns a score of how well
this object matches those critera. It's called by
L<Test::MockCommand>, both as part of its search for the right command
to emulate, and also via the front-end C<find> method. As such it may
contain zero or more criteria. If no criteria are provided, the result
should always be "this matches".

Return 0 to indicate no match, 1 to indicate a match, and higher
numbers mean the result "matches better". If more than one result
matches the given criteria, they will be sorted by this match score,
highest first, and in the case of picking a result to emulate a
command, the first in the list will be chosen.

The criteria are the same as listed in
L<Test::MockCommand::Recorder/handle>, however you can presume that
the criteria C<function> and C<command>, if they are present, have
been used to filter out results which don't match.

=item $return_value = $result->handle(%args)

This should emulate the function detailed in the arguments and return
the value that the function itself is expected to return. The
arguments are the same as listed in
L<Test::MockCommand::Recorder/handle>, and as with that method, any
results for C<readpipe> should be returned as a scalar, not a list, as
the framework will break them into a list if needed.

=item $result->append_input_data($string)

Appends more text to the C<input_data> attribute. Called by the tied
filehandle's C<WRITE> method while emulating an C<open> call.

=item $result->append_output_data($string)

Appends more text to the C<output_data> attribute. Called by the tied
filehandle's C<WRITE> method while emulating an C<open> call.

=item $result->create_tied_fh()

Creates a L<Test::MockCommand::TiedFH> filehandle attached to this object.

=back

=head1 ATTRIBUTES

 $attribute_value = $result->attribute_name()
 $result->attribute_name($new_attribute_value)

Each result object can store a number of attributes, which you can get
and set via accessor methods as shown above. The attributes are as follows:

=over

=item command

Roughly the command being run. Use the C<function> and C<arguments>
attributes for a completely accurate version. For example
C<system('ls', 'foo', 'bar');> and C<system('ls', 'foo bar')> will
generate the same command attribute, "ls foo bar".

=item function

The function that generated this result. This will be C<exec>, C<open>,
C<readpipe> or C<system>.

=item arguments

An arrayref to the original arguments of the function. However, the
first argument to open() is always turned to undef, to allow for the
result to be saved and loaded into another program where a named
filehandle reference might not exist.

=item return_value

The return value originally captured from this function

=item cwd

The current working directory at the time this function was called.

=item input_data

Any input data sent into the command. (C<open> only)


=item output_data

The output generated by the command (C<open> only)

=item exit_code

The value of C<$?> after running the command.

=item all_results

Available only while C<handle> is being called. It's a list of all
possible candidates for execution, including this result.

=back

=cut
