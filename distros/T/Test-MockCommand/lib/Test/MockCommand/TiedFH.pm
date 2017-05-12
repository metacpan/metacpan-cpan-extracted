package Test::MockCommand::TiedFH;
use strict;
use warnings;
use Errno qw(ESPIPE);

use Test::MockCommand::ScalarReadline qw(scalar_readline);

require Tie::Handle;
our @ISA = qw(Tie::Handle);

sub TIEHANDLE {
    my $class = shift;

    my $self = {
        recording => $_[0], # 1 if recording, 0 if playing back
	fh        => $_[1], # real filehandle to open() [record mode only]
        result    => $_[2], # object to store/retrieve results
	offset    => 0,     # offset in command output [playback only]
        unique    => 0,     # have we found a unique result? [playback only]
        input     => '',    # input data collected [playback only]
    };
    return bless $self, $class;
}

# WRITE($buffer, $length, $offset)
sub WRITE {
    my $self = shift;
    # recording mode: append this data as input, pass it on to the command
    if ($self->{recording}) {
	$self->{result}->append_input_data(substr($_[0], $_[2], $_[1]));
	return syswrite($self->{fh}, $_[0], $_[1], $_[2]);
    }

    # playback mode

    # if we haven't pinned down a result yet, collect the input
    # written to us and look through all possible results
    if (! $self->{unique}) {
	$self->{input} .= substr($_[0], $_[2], $_[1]);
	my $count = 0;
	my $matched = undef;
	for my $result (@{$self->{result}->all_results()}) {
	    next unless substr($result->input_data(), 0,
			       length $self->{input}) eq $self->{input};
	    $matched = $result;
	    $count++;
	}

	# if what we have for input so far uniquely matches the input
	# of one of the results, switch over to using that result.
	if ($count == 1) {
	    $self->{result} = $matched;
	    $self->{unique} = 1;
	}

	# if none of the results match the input we have so far, trouble
	if ($count == 0) {
	    my $cmd = $self->{result}->command();
	    warn "current input to \"$cmd\" doesn't match any previous result";
	    $self->{unique} = 1;
	}
    }
    
    # return number of bytes 'written' (e.g. the length)
    return $_[1];
}

# READ($buffer, $length, $offset)
sub READ {
    my $self = shift;

    # recording mode
    if ($self->{recording}) {
	my $read = sysread($self->{fh}, $_[0], $_[1], $_[2]);
	return undef unless defined $read;
	$self->{result}->append_output_data(substr($_[0], $_[2], $read));
	return $read;
    }

    # playback mode

    # determine how many bytes are requested vs how many are available
    my $avail = length($self->{result}->output_data()) - $self->{offset};
    my $len = ($_[1] < $avail) ? $_[1] : $avail;

    # write the output data into the requested buffer
    substr($_[0], $_[2], $len, substr($self->{result}->output_data(),
				      $self->{offset}, $len));
    $self->{offset} += $len;
    return $len;
}

sub READLINE {
    my $self = shift;

    # recording mode
    if ($self->{recording}) {
	if (wantarray()) {
	    my @lines = readline $self->{fh};
	    $self->{result}->append_output_data(join '', @lines);
	    return @lines;
	}
	else {
	    my $line = readline $self->{fh};
	    $self->{result}->append_output_data($line) if defined $line;
	    return $line;
	}
    }

    # playback mode
    if (wantarray()) {
	my @lines = scalar_readline(substr($self->{result}->output_data(),
					   $self->{offset}));
	# everything now read; move the offset to the end of the output data
	$self->{offset} = length $self->{result}->output_data();
	return @lines;
    }
    else {
	my $length = undef;
	my $line = scalar_readline(substr($self->{result}->output_data(),
					  $self->{offset}), $length);
	$self->{offset} += $length;
	return $line;
    }
}

sub CLOSE {
    my $self = shift;
    return $self->{recording} ? close($self->{fh}) : 1;
}

sub EOF {
    my $self = shift;
    return eof $self->{fh} if $self->{recording};
    return $self->{offset} >= length($self->{result}->output_data());
}

sub TELL {
    $! = ESPIPE;
    return -1;
}

sub SEEK {
    $! = ESPIPE;
    return '';
}

sub FILENO {
    my $self = shift;
    return $self->{recording} ? fileno($self->{fh}) : -1;
}

sub BINMODE {
    my $self = shift;
    binmode($self->{fh}) if $self->{recording};
}

1;

__END__

=head1 NAME

Test::MockCommand::TiedFH - emulate open() filehandle

=head1 SYNOPSIS

This class pretends to be an open() filehandle to and/or from a
pipe. It is either in recording mode or playback mode. It acts on a
result object, and in recording mode it also uses an open filehandle
to the real command.

In recording mode, it passes through read/write requests to the
filehandle and appends the result to the result object before
returning to the calling code.

In playback mode, it returns data exclusively from the result object
and emulates the results the real file operations would give.

=head2 Finding unique results based on input

In some situations, two commands will be identical in invocation
except for their input and output. The MockCommand framework handles
this by passing control to the first result in the database, but
giving it a list of all the other results.

If input is provided, we use all input we currently have and compare
it to all the other results. If we find a unique match, we switch to
using this result object.

=cut
