package Text::ASCIIPipe;
# See POD below.

# TODO: sanitize line end from handlers!

use strict;
# major.minor.bugfix, the latter two with 3 digits each
# or major.minor_alpha
our $VERSION = '1.001000';
$VERSION = eval $VERSION;


# State codes. The numerocal values are important for the code in this module (used as array indices).
our $funky  = 0;
our $line   = 1;
our $begin  = 2; # From here identical to ASCII code
our $end    = 3;
our $allend = 4;

# The actualy control characters.
my %control = (stx=>"\002", eot=>"\003", etx=>"\004");

# Map plain character codes to state codes.
# I do not really care about codes 0 and 1.
my @codemap = ($funky, $funky, $begin, $end, $allend);

sub fetch
{
	my $fh = shift;
	$fh = \*STDIN unless defined $fh;

	# Note to self: MAC style line endings will only work here for an old-style MAC Perl. All others see one big line with CRs in it.
	$_[0] = <$fh>;
	return undef unless defined $_[0];
	my $code = ord($_[0]);
	return $line if $code > 4;
	return $codemap[$code];
}

# plain text means: first byte does not qualify as control code
sub plaintext
{
	my $code = ord($_[0]);
	return ($code > 4);
}

sub process
{
	my %arg = @_;

	my $fline;
	my $lend = undef;
	my $in  = $arg{in};
	my $out = $arg{out};
	$out = \*STDOUT unless defined $out;
	$arg{flush} = 1 unless defined $arg{flush};

	# The begin function is special because we ensure that the output gets flushed to prevent stalling of the pipe readers.
	# Function table according to numerical value of state codes.
	# A handler gets the current line as first in/output argument and the detected line end as second.
	my $prefilter = defined $arg{pre} ? $arg{pre} : sub {};
	my @handlers =
	(
		 sub {} # 0 is some unknown crap. Ignore.
		,defined $arg{line}  ? $arg{line}  : sub {}
		,sub
		{
			# That flush may be better placed after $arg{end} ...
			if($arg{flush})
			{
				my $old = select($out);
				$|=1;
				select($old);
			}
			&{$arg{begin}}(@_) if defined $arg{begin};
		}
		,defined $arg{end}    ? $arg{end}      : sub {}
		,defined $arg{allend} ? $arg{allend}   : sub {}
	);

	my @gotcode; # Need to check if control codes were actually present.
	my @prearg;
	push(@prearg, $arg{handle}) if defined $arg{handle};
	while(defined (my $state = fetch($in, $fline)))
	{
		# Store first encountered line end to be used for constructed lines.
		unless(defined $lend)
		{
			$fline =~ m/([\012\015]*)$/;
			$lend = $1;
		}
		$gotcode[$state] = 1;
		if(not $gotcode[$begin])
		{
			my $extraline = '';
			# Trigger begin hook implicitly when just encountering data.
			&{$handlers[$begin]}(@prearg, $extraline, $lend);
			print $out $extraline;
			$gotcode[$begin] = 1;
		}
		if($state == $line)
		{
			next if &{$prefilter}(@prearg, $fline, $lend);
			# A line handler shall modify the line.
			&{$handlers[$state]}(@prearg, $fline, $lend);
			print $out $fline if $fline ne '';
		}
		else
		{
			# Other handlers could generate something.
			my $extraline = '';
			&{$handlers[$state]}(@prearg, $extraline, $lend);
			print $out ($state == $begin ? $fline.$extraline : $extraline.$fline);
		}

		return if($state == $allend);
		# If we got proper end code, clear records for next file.
		@gotcode = () if($state == $end);
	}

	# Make sure that handlers get called even for empty file, or partial transfer with missing end markers.
	# I wonder if $lend should be simply guessed to "\n".
	for my $c ($begin,$end,$allend)
	{
		next if $gotcode[$c];
		# The handlers are allowed to generate some output.
		my $extraline = '';
		&{$handlers[$c]}(@prearg, $extraline, $lend);
		print $out $extraline;
	}
}

# Simple shortcut to pull a full file from pipe handle into an output file.
# Returns indication if this was not the last file (so you can loop until it returns a non-true value).
# return value:
# <0: Pull was invalid, no data for file (not even an empty one).
#  0: Pull successful, but this was it, no more files to expect.
# >0: Pull successful and no indication that there is not more to come.

sub pull_file
{
	my ($from, $to) = @_;
	$from = \*STDIN  unless defined $from;
	$to   = \*STDOUT unless defined $to;
	my $payload;
	my $state;
	while(defined ($state = fetch($from, $payload)))
	{
		next if $state == $begin;
		last if $state != $line;
		print $to $payload;
	}

	# All fine: Loop ended with orderly file end marker.
	return  1 if(defined $state and $state != $allend);
	# Ended on EOF (or some esoteric error we still treat as such),
	# as there was no allend or error before that, just assume normal end of things.
	return  0 if(not defined $state);
	# If we hit allend, we did not stop with an orderly file end,
	# so must assume we got nothing at all.
	return -1; # if($state == allend) is already implied
}

# The senders.

sub push_file
{
	my ($from, $to) = @_;
	$from = \*STDIN  unless defined $from;
	$to   = \*STDOUT unless defined $to;

	file_begin($to);
	while(<$from>)
	{
		print $to $_;
	}
	file_end($to);
	return 1; # Should it return something special?
}

sub file_begin
{
	my $to = shift;
	$to = \*STDOUT unless defined $to;

	print $to $control{stx}."\n";
}

sub file_lines
{
	my $to = shift;
	$to = \*STDOUT unless defined $to;

	for(@_){ print $to $_; }
}

sub file_end
{
	my $to = shift;
	$to = \*STDOUT unless defined $to;

	print $to $control{eot}."\n";
}

sub done
{
	my $to = shift;
	$to = \*STDOUT unless defined $to;

	print $to $control{etx}."\n";	
}

1;

__END__

=head1 NAME

Text::ASCIIPipe - helper for processing multiple text files in a stream (through a pipe, usually)

=head1 SYNOPSIS

	use Text::ASCIIPipe;

	# The hooks get the current line as argument $_[0].
	# This is printed by Text::ASCIIPipe::process after the hook returns.
	# Change it to your liking, including setting to '' for suppressing output.
	sub line_hook
	{
		$_[0] = "A line: ".$_[0];
	}

	# For the delimiter hooks, the line consists of the control character,
	# so the final output may want to suppress it -- but not so if the output
	# goes to another pipe processor.
	sub begin_hook  { $_[0] = "New file began here!\n"; }
	sub end_hook    { $_[0] = "A file ended.\n";        }
	sub allend_hook { $_[0] = "End of transmission\n";  }

	my $line;
	# Bare usage without callback hooks, using STDIN.
	while(defined (my $state = Text::ASCIIPipe::fetch(undef, $line)))
	{
		if ($state == $Text::ASCIIPipe::line)
		{
			next if prefilter_hook($line);
			line_hook($line);
		}
		else
		{
			begin_hook($line)  if ($state == $Text::ASCIIPipe::begin);
			end_hook($line)    if ($state == $Text::ASCIIPipe::end);
			allend_hook($line) if ($state == $Text::ASCIIPipe::allend);
		}
		print $line;
		# End of transmission is not exactly the same as stream end.
		# But mostly so.
		last if ($state == $Text::ASCIIPipe::allend);
	}

	# Processes STDIN to STDOUT, very similar to the above code.
	# You can set any hook to undef to disable it.
	Text::ASCIIPipe::process
	(
		 begin  => \&begin_hook
		,line   => \&line_hook
		,end    => \&end_hook
		,allend => \&allend_hook
	);

	# Processes given file handle.
	my $fh;
	open($fh, '<', $dump_of_a_text_data_stream);
	Text::ASCIIPipe::process
	(
		 in     => $fh
		,out    => \*STDOUT # or undef, or some other file
		,pre    => \&prefilter_hook
		,begin  => \&begin_hook
		,line   => \&line_hook
		,end    => \&end_hook
		,allend => \&allend_hook
		,flush  => 0  # Default is 1 (see below).
	);

	# The other side of the pipe can push serveral files...
	# Per default to STDOUT.

	# Just shove one whole file through (default: STDIN -> STDOUT).
	my $from
	my $to;
	open($from, '<', $some_filename);
	open($to, '|-', $some_command); # A pipe is what makes most sense...
	# Remember: $to can always be undef for STDOUT.
	Text::ASCIIPipe::push_file($from, $to);

	# Pull a file from Pipe (STDIN in this case) into given handle.
	open(my $out_fh, '>', $some_filename);
	my $fetch_count = Text::ASCIIPipe::pull_file(undef, $out_fh);
	print "Seems like something came through.\n" if($fetch_count > 0);

	# Detailed API.
	Text::ASCIIPipe::file_begin($to); # Send begin marker.
	# Send line(s) of file.
	Text::ASCIIPipe::file_lines($to, "#header\n", "1 2 3\n");
	Text::ASCIIPipe::file_end($to);   # Send end marker.

	# After sending all files, send total end marker (allend).
	# Just closing the sink does the  trick, too.
	Text::ASCIIPipe::done($to);

	# If you wrap your stuff into an objet, you can provide its instance
	# as context and have the handlers work as methods on this.
	Text::ASCIIPipe::process
	(
		,handle => $my_object_instance
		# The hooks are methods of the above!
		# (or just any sub that wants it as first argument)
		,begin  => \&begin_hook
		,line   => \&line_hook
		,end    => \&end_hook
		,allend => \&allend_hook
	);

=head1 DESCRIPTION

A lot of the speed penalty of Perl when processing multiple smallish data sets from/to text form in a shell loop consists of the repeated perl compiler startup / script compilation, which accumulates when looping over a set of files. This process can be sped up a lot by keeping the pipe alive and streaming the whole file set through it once. This module helps you with that. Of course, a pipe of several scripts parsing/producing text will still be slower than a custom C program that does the job, but with this trick of avoiding repeated script interpretation/compilation, the margin is a lot smaller.

When dealing with ASCII-based text files (or UTF-8, if you please), there are some control characters that just make sense for pushing several files as a stream, separated by these characters. These are character codes 2 (STX, start of text), 3 (EOT, end of text) and 4 (ETX, end of transmission).
All this module does is provide a wrapper for inserting these control characters for the sender and parsing them for the receiver. Nothing fancy, really. I just got fed up writing the same loop over and over again. It works with all textual data that does not contain control characters below decimal code 5.

The process() function itself tries to employ a bit of smartness regarding buffering of the output. Since the actual operation of multiple ASCIIPipe-using programs in a, well, pipe, might conflict with the default buffering of the output stream (STDOUT), process() disables buffering on the output whenever it encounters the first STX. This mirrors the code this module has been pulled from: It made sense there, enabling the last consumer in the pipe to get the end of a file in time and act on that information. This behaviour can be turned off by giving flush=>0 as parameter.

The callback hooks get handed in the optional configured handle and, as primary argument, the current line to process. Also, the current line end is given as following argument to help constructing additional lines properly, if you wish to do so:

	sub hook
	{
		$_[0] .= 'appended another line with proper ending'.$_[1];
	}

=head1 FUNCTIONS

This module offers a simple procedural interface built by the following stateless functions:

=over 4

=item B<fetch>

	$state = Text::ASCIIPipe::fetch($in_handle, $line);

Tries to fetch a line of text from given input handle (STDIN if undef), storing data in $line. Return value corresponds to one of those states: undef for no data being there (unannounced EOF), $Text::ASCIIPipe::begin for file begin marker, $Text::ASCIIPipe::end for file end marker, $Text::ASCIIPipe::allend for final end marker and, finally, $Text::ASCIIPipe::line if you actually fetched a line of content.

=item B<plaintext>

	$not_special = Text::ASCIIPipe::plaintext($line);

Returns 1 if the given data does not start with one of the control codes that Text::ASCIIPipe interprets (could contain other control codes, though).

=item B<process>

Proccess a text file pipe, slurping through a stream of files. See SYNOPSYS for usage.

=item B<pull_file>

Pull a single file from the pipe. See SYNOPSYS for usage.

=item B<push_file>

Push a single file to the pipe. See SYNOPSYS for usage.

=item B<file_begin>

Send file begin marker. See SYNOPSYS for usage.

=item B<file_lines>

Send file contents. See SYNOPSYS for usage.

=item B<file_end>

Send file end marker. See SYNOPSYS for usage.

=item B<done>

Send overall end marker.  See SYNOPSYS for usage.

=back


=head1 TODO

Got to figure out if the business about autoflushing is right, and improve it.

=head1 SEE ALSO

This idea is too obvious. This must have been implemented a number of times already. Yet, I did not find an instance of this on CPAN.

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut
