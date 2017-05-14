package Tic::Bindings;

use strict;
use Tic::Common;
use vars ('@ISA', '@EXPORT');
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(DEFAULT_BINDINGS DEFAULT_MAPPINGS);

# Default key -> sub bindings
use constant DEFAULT_BINDINGS => {
	"LEFT"        =>    "backward-char",
	"RIGHT"       =>    "forward-char",

	"^I"          =>    "complete-word",
	"TAB"         =>    "complete-word",

	"BACKSPACE"   =>    "delete-char-backward",
	"^H"          =>    "delete-char-backward",
	"^?"          =>    "delete-char-backward",
	"^U"          =>    "kill-line",
};

# Default "string" -> sub binding.
use constant DEFAULT_MAPPINGS => {
	"backward-char"           => \&backward_char,
	"forward-char"            => \&forward_char,
	"complete-word"           => \&complete_word,
	"delete-char-backward"    => \&delete_char_backward,
	"kill-line"               => \&kill_line,

};

my $state;

sub import {
	#debug("Importing from Tic::Bindings");
	Tic::Bindings->export_to_level(1,@_);
}

sub set_state {
	$state = shift;
}

sub forward_char {
	my $state = shift;
	my $ret;
	if ($state->{"input_position"} < length($state->{"input_line"})) {
		$state->{"input_position"}++;
		#my $pos = length($state->{"input_line"});
		$ret->{-print} = "\e[C";
	}

	return ($state->{"input_string"}, undef, $ret);
}

sub backward_char {
	my $state = shift;
	my $ret;
	if ($state->{"input_position"} > 0) {
		$state->{"input_position"}--;
		$ret->{-print} = "\e[D";
	}

	return ($state->{"input_string"}, undef, $ret);
}

sub kill_line {
	my $state = shift;
	my $ret;
	$ret->{-print} = "\e[2K\r";
	my ($line) = $state->{"input_line"};
	$line = ""; # not undef...
	$state->{"input_position"} = 0;
	$state->{"input_line"} = undef;
	return (undef, undef, { -print => "\r\e[2K" } );  # Not undef!
}

sub complete_word {
	my $state = shift;
	my $line = $state->{"input_line"};
	my $pos = $state->{"input_position"};
	my $ret;
	my $string;
	#print STDERR "bind_complete called.\n";

	# Try completing a command.
	# Find the word the cursor is on.
	my ($b,$e); # beginning and end
	$pos-- if (substr($line,$pos,1) eq ' ');

	for (my $x = 0; $x < length($line); $x++) {
		unless (defined($b)) { # Look for the beginning of the word
			my $p = $pos - $x;
			#print STDERR "B: $p / '" . substr($line,$p,1) . "'\n";
			$b = $p if (($p <= 0) || (substr($line,$p,1) =~ m/^\s/));
			$b++ if ($b > 0);
		}
		unless (defined($e)) { # Look for the end of the word
			my $p = $pos + $x;
			#print STDERR "F: $p / '" . substr($line,$p,1) . "'\n";
			$e = $p if (($p >= length($line)) || (substr($line,$p,1) =~ m/^\s/));
		}
		last if (defined($b) && defined($e));
	}
	$b ||= 0;
	$e ||= length($line);

	#print STDERR "Init: $pos / Beginning: $b / End: $e == '" . substr($line,$b,$e) . "'\n";

	$string = substr($line,$b,($e - $b));
	my $comp = do_complete($state, $string, $b, $e);
	if ($comp ne $string) {
		substr($line,$b,($e - $b)) = $comp;
		$state->{"input_position"} += length($comp) - length($string);

	}

	#print STDERR "Line: $line\n";

	return ($line, undef);
}

sub do_complete {
	my ($state,$string,$b,$e) = @_;
	print STDERR "To complete: '$string'\n";
	if ($b eq '0') {
		if ($string =~ m!^/(.*)$!) {
			$string = do_complete_command($state,$string);
		}
	} else {
		# This isn't the first word, and maybe isn't a command.
		return if ($string eq '');
		my $line = $state->{"input_line"};
		my @words = split(/\s+/,$line);

		# Complete commands for /alias
		if ($words[0] =~ m!^/alias!) {
			if ($string eq $words[2]) {
				$string = do_complete_command($state,$1) if ($string =~ m!^/(.*)$!);
			}
		}
	}
	return $string;
}

sub do_complete_command {
	my ($state, $partial) = @_;
	#$partial =~ s!^/!!;
	my @coms = grep(m/^$1/,keys(%{$state->{"commands"}}));
	push(@coms,grep(m/^$1/,keys(%{$state->{"aliases"}})));
	@coms = sort(@coms);
	$partial  = "/" . $coms[0] . " " if (scalar(@coms) > 0);
	return $partial;
}

sub delete_char_backward {
	my $state = shift;
	my $ret;
	my ($line) = $state->{"input_line"};
	if ($state->{"input_position"} > 0) {
		my ($pos,$pos2) = (length($line), $state->{input_position});
		#$line = substr($line, 0, $state->{"input_position"} - 1) .
				  #substr($line, $state->{"input_position"});

		substr($line,$state->{input_position} - 1,1) = "";

		$state->{"input_position"}--;

		# go from pos -> end of string + 1, print a space, jump back to pos.
		$ret->{-print} =  "\e[".($pos - $pos2 - 2)."C \e[".($pos-$pos2-1)."D";
	} 
	return ($line,undef,$ret);
}

1;
