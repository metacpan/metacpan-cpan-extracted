#!/usr/bin/perl
# vim:ts=4:sw=4

package Text::Flowed;

$VERSION = '0.14';

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(reformat quote quote_fixed);

use strict;
use vars qw($MAX_LENGTH $OPT_LENGTH);

# MAX_LENGTH: This is the maximum length that a line is allowed to be
# (unless faced with a word that is unreasonably long). This module will
# re-wrap a line if it exceeds this length.
$MAX_LENGTH = 79;

# OPT_LENGTH: When this module wraps a line, the newly created lines
# will be split at this length.
$OPT_LENGTH = 72;

# reformat($text, [\%args])
# Reformats $text, where $text is format=flowed plain text as described
# in RFC 2646.
#
# $args->{quote}: Add a level of quoting to the beginning of each line.
# $args->{fixed}: Interpret unquoted/all lines as format=fixed.
# $args->{max_length}: The maximum length of any line.
# $args->{opt_length}: The maximum length of wrapped lines.
sub reformat {
	my @input = split("\n", $_[0]);
	my $args = $_[1];
	$args->{max_length} ||= $MAX_LENGTH;
	$args->{opt_length} ||= $OPT_LENGTH;
	my @output = ();

	# Process message line by line
	while (@input) {
		# Count and strip quote levels
		my $line = shift(@input);
		my $num_quotes = _num_quotes($line);
		$line = _unquote($line);

		# Should we interpret this line as flowed?
		if (!$args->{fixed} ||
		    ($args->{fixed} == 1 && $num_quotes)) {
			$line = _unstuff($line);
			# While line is flowed, and there is a next line, and the
			# next line has the same quote depth
			while (_flowed($line) && @input &&
			       _num_quotes($input[0]) == $num_quotes) {
				# Join the next line
				$line .= _unstuff(_unquote(shift(@input)));
			}
		}
		# Ensure line is fixed, since we joined all flowed lines
		$line = _trim($line);

		# Increment quote depth if we're quoting
		$num_quotes++ if $args->{quote};

		if (!$line) {
			# Line is empty
			push(@output, '>' x $num_quotes);
		} elsif (length($line) + $num_quotes <= $args->{max_length} - 1) {
			# Line does not require rewrapping
			push(@output, '>' x $num_quotes . _stuff($line, $num_quotes));
		} else {
			# Rewrap this paragraph
			while ($line) {
				# Stuff and re-quote the line
				$line = '>' x $num_quotes . _stuff($line, $num_quotes);

				# Set variables used in regexps
				my $min = $num_quotes + 1;
				my $opt1 = $args->{opt_length} - 1;
				my $max1 = $args->{max_length} - 1;
				if (length($line) <= $args->{opt_length}) {
					# Remaining section of line is short enough
					push(@output, $line);
					last;
				} elsif ($line =~ /^(.{$min,$opt1}) (.*)/ ||
						 $line =~ /^(.{$min,$max1}) (.*)/ ||
				         $line =~ /^(.{$min,})? (.*)/) {
					# 1. Try to find a string as long as opt_length.
					# 2. Try to find a string as long as max_length.
					# 3. Take the first word.
					push(@output, "$1 ");
					$line = $2;
				} else {
					# One excessively long word left on line
					push(@output, $line);
					last;
				}
			}
		}
	}

	return join("\n", @output)."\n";
}

# quote(<text>)
# A convenience wrapper for reformat(<text>, {quote => 1}).
sub quote {
	return reformat($_[0], {quote => 1});
}

# quote_fixed(<text>)
# A convenience wrapper for reformat(<text>, {quote => 1, fixed => 1}).
sub quote_fixed {
	return reformat($_[0], {quote => 1, fixed => 1});
}

# _num_quotes(<text>)
# Returns the number of leading '>' characters in <text>.
sub _num_quotes {
	$_[0] =~ /^(>*)/;
	return length($1);
}

# _unquote(<text>)
# Removes all leading '>' characters from <text>.
sub _unquote {
	my $line = shift;
	$line =~ s/^(>+)//g;
	return $line;
}

# _flowed(<text>)
# Returns 1 if <text> is flowed; 0 otherwise.
sub _flowed {
	my $line = shift;
	# Lines with only spaces in them are not considered flowed
	# (heuristic to recover from sloppy user input)
	return 0 if $line =~ /^ *$/;
	return $line =~ / $/;
}

# _trim(<text>)
# Removes all trailing ' ' characters from <text>.
sub _trim {
	$_ = shift;
	$_ =~ s/ +$//g;
	return $_;
}

# _stuff(<text>, <num_quotes>)
# Space-stuffs <text> if it starts with " " or ">" or "From ", or if
# quote depth is non-zero (for aesthetic reasons so that there is a
# space after the ">").
sub _stuff {
	my ($text, $num_quotes) = @_;
	if ($text =~ /^ / || $text =~ /^>/ || $text =~ /^From / ||
		$num_quotes > 0) {
		return " $text";
	}
	return $text;
}

# _unstuff(<text>)
# If <text> starts with a space, remove it.
sub _unstuff {
	$_ = shift;
	$_ =~ s/^ //;
	return $_;
}

1;

__END__

=head1 NAME

Text::Flowed - text formatting routines for RFC2646 format=flowed

=head1 SYNOPSIS

 use Text::Flowed qw(reformat quote quote_fixed);

 print reformat($text, {
     quote => 1,
     fixed => 1,
     opt_length => 72,
     max_length => 79
 });

 print quote($text);      # alias for quote => 1
 print quote_fixed(text); # alias for quote => 1, fixed => 1

=head1 DESCRIPTION

This module provides functions that deals with formatting data with
Content-Type 'text/plain; format=flowed' as described in RFC2646
(F<http://www.rfc-editor.org/rfc/rfc2646.txt>). In a nutshell,
format=flowed text solves the problem in plain text files where it is
not known which lines can be considered a logical paragraph, enabling
lines to be automatically flowed (wrapped and/or joined) as appropriate
when displaying.

In format=flowed, a soft newline is expressed as " \n", while hard
newlines are expressed as "\n". Soft newlines can be automatically
deleted or inserted as appropriate when the text is reformatted.

=over 4

=item B<reformat>($text [, \%args])

The reformat() function takes some format=flowed text as input, and
reformats it. Paragraphs will be rewrapped to the optimum width, with
lines being split or combined as necessary.

    my $formatted_text = reformat($text, \%args);

If B<$args-E<gt>{quote}> is true, a level of quoting will be added to
the beginning of every line.

If B<$args-E<gt>{fixed}> is true, unquoted lines in $text will be
interpreted as format=fixed (i.e. leading spaces are interpreted
literally, and lines will not be joined together). (Set it to 2 to make
all lines interpreted as format=fixed.) This is useful for processing
messages posted in web-based forums, which are not format=flowed, but
preserve paragraph structure due to paragraphs not having internal line
breaks.

B<$args-E<gt>{max_length}> (default 79) is the maximum length of line
that reformat() or quote() will generate. Any lines longer than this
length will be rewrapped, unless there is an excessively long word that
makes this impossible, in which case it will generate a long line
containing only that word.

B<$args-E<gt>{opt_length}> (default 72) is the optimum line length. When
reformat() or quote() rewraps a paragraph, the resulting lines will not
exceed this length (except perhaps for excessively long words).

If a line exceeds opt_length but does not exceed max_length, it might
not be rewrapped.

=item B<quote>($text)

quote($text) is an alias for reformat($text, {quote => 1}).

    my $quoted_text = quote($text);

=item B<quote_fixed>($text)

quote_fixed($text) is an alias for reformat($text, {quote => 1, fixed =>
1}).

    my $quoted_text = quote_fixed($text);

=back

=head1 COPYRIGHT

Copyright 2002-2003, Philip Mak

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
