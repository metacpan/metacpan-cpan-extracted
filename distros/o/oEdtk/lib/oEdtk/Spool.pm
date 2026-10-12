package oEdtk::Spool;

use strict;
use warnings;

use oEdtk::Main 0.42;

our $VERSION = 2.1109;

# The maximum number of characters we emit before inserting
# a newline.
my $LINE_CUTOFF = 85;

sub new {
	my ($class, $in, $out) = @_;

	my $self = {
		input   => ref($in) eq 'GLOB' ? $in : \*STDIN,
		output  => ref($out) eq 'GLOB' ? $out : \*STDOUT,
		emitted => 0
	};
	bless $self, $class;
	return $self;
}

# Input stream format, line by line.
#
# The first four characters of the line determine the case.
#
# case 1:
#   /^(\d{3}) (.*)$/
#
#   $1 = resource
#   $2 = data
#
# case 2, inside a resource:
#   /^   (\d)(.*)$/
#
#   $1 = channel jump
#   $2 = data 
sub parse {
	my $self = shift;
	my $processfn = shift;
	my $fh = $self->{'input'};

	$self->{'XCORP'} = oe_corporation_get();
	# Read the input file line by line.
	while (my $line=<$fh>) {
		chomp ($line);

		if (length $line == 0) {
			warn "INFO : line $. is empty\n";
			next;
		}

		# Get the first four characters.
		die "ERROR: unexpected line format: \"$line\" at line $.\n"
		    unless $line =~ /^(.{3})([0-9+\- ]?)(.*)$/;
		my ($header, $jump, $data) = ($1, $2, $3);
# PROBLEM, on 2 lines like the ones below
	#026   *** LAURIANE         20/09/1984 01 REFERENCES DECOMPTE: 07/01/2009RO181  0002*
	#   2  *** MAELENN          02/12/1993 11 REFERENCES DECOMPTE: 30/12/2008RO422  0002*
# jump must not be empty in the first case, otherwise $data has 1 more character the first time; in the second case it has one character less 
# which shifts the splitting in the main application

#	Introduce a technical prefix line, used only to populate state
#004              EDT XCORP M0001

		if ($header =~ /^[0-9a-zA-Z]{3}$/) { # Case number 1.
			$self->{'prev_inres'} = $self->{'inres'};
			$self->{'inres'} = $header;
			$self->{'jump'} = $jump;

			if ($data =~ /^\s{1,13}EDT XCORP/) {
				# warn "EDT XCORP >$data<\n";
				# Reinitialize the state. >             EDT XCORP M0001<
				$self->{'numln'} = 0;
				$self->{'jumpln'}= 0;
				# TODO: handle states in pairs:
				# EDT XCORP VALUE STATE2 VALUE2 STATE3 VALUE3 etc.
				$data =~ s/^(\s{1,13}EDT\s)(.*)/$2/;
				while ($data) {
					$data =~ s/^([\w\d]+)\s([\w\d]+)\s*(.*)/$3/;
					$self->{$1} = $2;
				}
				# warn "EDT XCORP >$data<\n " . $self->{'XCORP'}. "\n";
				next;
								
			} else {
				# Reinitialize the state.
				$self->{'numln'} = 1;
				$self->{'jumpln'}= 1;
			}
			# Reinitialize the state.
			$self->{'state'} = {};
			$processfn->($self, $data);

		} elsif ($header eq '   ') {
			$self->{'jump'} = $jump;
			if (!defined $self->{'inres'}) {
				die "ERROR: got seal while not in a resource at line $.\n";
			}
			$self->{'numln'}++;
			if (defined($jump) && $jump =~ /\d/) {
				$self->{'jumpln'} += $self->{'jump'};
			}
			$processfn->($self, $data);
		} else {
			die "ERROR: unexpected line header: \"$header$jump\" at line $.\n";
		}
	}
}

# Emit a Compuset tag.
sub emit {
	my ($self, $name, $val) = @_;
	my $fh = $self->{'output'};

	my $tag;
	if (defined $val) {
		$val =~ s/\s+/ /g;
		$tag = "<#$name=$val>";
	} else {
		$tag = "<$name>";
	}

	my $taglen = length $tag;
	if ($self->{'emitted'} + $taglen > $LINE_CUTOFF) {
		print $fh "\n" if $self->{'emitted'} > 0;
		$self->{'emitted'} = 0;
	}
	$self->{'emitted'} += $taglen;
	print $fh $tag;
}

1;

__END__

=head1 NAME

oEdtk::Spool - Helper module for parsing printer spool files

=head1 SYNOPSIS

  use oEdtk::Main;
  use oEdtk::Spool;

  oe_new_job($ARGV[0], $ARGV[1]);
  my $s = oEdtk::Spool->new(\*IN, \*OUT);
  $s->parse(\&process);

  ...

  oe_compo_link($ARGV[0], $ARGV[1]);

  sub process($$) {
    my ($s, $line) = @_;
    
    if ($s->{'inres'} eq 'XYZ') {
      ...
    } else {
      ...
    }
  }

=head1 DESCRIPTION

This module handles the repetitive tasks associated with the parsing of
spool files: it extracts the identifiers of the resource blocks,
the channel jumps, and passes this information along with the current line
to a callback function.  As a result, the first four characters of the original
line from the stream are stripped.

=head1 METHODS

=over 4

=item new

The C<new> method creates a Spool object given two filehandles: the first one
for input, and the second one for output.  However, the second filehandle is
currently unused since we now use the L<oEdtk::C7Doc|oEdtk::C7Doc> module for
handling output.

=item parse

The C<parse> method takes a function reference as a parameter, and calls this
function for each line of the input file, passing it the Spool object as the
parameter, and the current line as the second parameter.  The first four
characters of the original line from the stream are stripped.

=item emit

The C<emit> method is deprecated and should B<not> be used in new code.

=back

=head1 ATTRIBUTES

=over 4

=item $s->{'inres'}

The identifier of the current resource block.

=item $s->{'prev_inres'}

The identifier of the previous resource block.

=item $s->{'numln'}

The current line number (starting at 1) in the resource block.

=item $s->{'jump'}

The channel jump, if any.

=item $s->{'state'}

A hash reference used as a state within the scope of a resource block.  It will
be emptied before the callback function is called at the beginning of each
resource block.

=back

=head1 SEE ALSO

L<oEdtk::Main|oEdtk>, L<oEdtk::C7Doc|oEdtk::C7Doc>

=head1 COPYRIGHT

Copyright 2009 - Maxime Henrion <mhenrion@gmail.com>

