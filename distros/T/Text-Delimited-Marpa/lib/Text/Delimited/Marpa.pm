package Text::Delimited::Marpa;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	nothing_is_fatal    =>  0, # The default.
	print_errors        =>  1,
	print_warnings      =>  2,
	print_debugs        =>  4,
	mismatch_is_fatal   =>  8,
	ambiguity_is_fatal  => 16,
	exhaustion_is_fatal => 32,
];

use Marpa::R2;

use Moo;

use Tree;

use Types::Standard qw/Any ArrayRef HashRef Int ScalarRef Str/;

use Try::Tiny;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has close =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has delimiter_action =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has delimiter_frequency =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has delimiter_stack =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has error_message =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has error_number =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has escape_char =>
(
	default  => sub{return '\\'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has known_events =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has length =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has matching_delimiter =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has next_few_limit =>
(
	default  => sub{return 20},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has node_stack =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has open =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has options =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has pos =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has tree =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has text =>
(
	default  => sub{return \''},	# Use ' in comment for UltraEdit.
	is       => 'rw',
	isa      => ScalarRef[Str],
	required => 0,
);

has uid =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

our $VERSION = '1.01';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Policy: Event names are always the same as the name of the corresponding lexeme.
	#
	# Note:   Tokens of the form '_xxx_' are replaced just below, with values returned
	#			by the call to validate_open_close().

	my($bnf) = <<'END_OF_GRAMMAR';

:default				::= action => [values]

lexeme default			= latm => 1

:start					::= input_text

input_text				::= input_string*

input_string			::= quoted_text
							| unquoted_text

quoted_text				::= open_delim input_text close_delim

unquoted_text			::= text

# Lexemes in alphabetical order.

delimiter_char			~ [_delimiter_]

:lexeme					~ close_delim		pause => before		event => close_delim
_close_

escaped_char			~ '_escape_char_' delimiter_char	# Use ' in comment for UltraEdit.

# Warning: Do not add '+' to this set, even though it speeds up things.
# The problem is that the set then gobbles up any '\', so the following
# character is no longer recognized as being escaped.
# Trapping the exception then generated would be possible.

non_quote_char			~ [^_delimiter_]	# Use " in comment for UltraEdit.

:lexeme					~ open_delim		pause => before		event => open_delim
_open_

:lexeme					~ text				pause => before		event => text
text					~ escaped_char
							| non_quote_char
END_OF_GRAMMAR

	my($hashref)     = $self -> _validate_open_close;
	$bnf             =~ s/_open_/$$hashref{_open_}/;
	$bnf             =~ s/_close_/$$hashref{_close_}/;
	$bnf             =~ s/_delimiter_/$$hashref{_delimiter_}/g;
	my($escape_char) = $self -> escape_char;

	if ($escape_char eq "'")
	{
		my($message) = 'Single-quote is forbidden as an escape character';

		$self -> error_message($message);
		$self -> error_number(7);

		# This 'die' is not inside try{}catch{}, so we add the prefix 'Error: '.

		die "Error: $message\n";
	}

	$bnf =~ s/_escape_char_/$escape_char/g;

	$self -> bnf($bnf);
	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

	# This hash does not contain the key "'exhausted" because the exhaustion
	# event is everywhere handled explicitly. Yes, it has a leading quote.

	my(%event);

	for my $line (split(/\n/, $self -> bnf) )
	{
		$event{$1} = 1 if ($line =~ /event\s+=>\s+(\w+)/);
	}

	$self -> known_events(\%event);

} # End of BUILD.

# ------------------------------------------------

sub _add_daughter
{
	my($self, $name, $attributes) = @_;
	$attributes = {%$attributes, uid => $self -> uid($self -> uid + 1)};
	my($stack)  = $self -> node_stack;
	my($node)   = Tree -> new($name);

	$node -> meta($attributes);

	$$stack[$#$stack] -> add_child({}, $node);

} # End of _add_daughter.

# ------------------------------------------------

sub next_few_chars
{
	my($self, $stringref, $offset) = @_;
	my($s) = substr($$stringref, $offset, $self -> next_few_limit);
	$s     =~ tr/\n/ /;
	$s     =~ s/^\s+//;
	$s     =~ s/\s+$//;

	return $s;

} # End of next_few_chars.

# ------------------------------------------------

sub parse
{
	my($self, %opts) = @_;

	# Emulate parts of new(), which makes things a bit earier for the caller.

	$self -> options($opts{options}) if (defined $opts{options});
	$self -> text($opts{text})       if (defined $opts{text});
	$self -> pos($opts{pos})         if (defined $opts{pos});
	$self -> length($opts{length})   if (defined $opts{length});

	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			exhaustion => 'event',
			grammar    => $self -> grammar,
		})
	);

	# Since $self -> node_stack has not been initialized yet,
	# we can't call _add_daughter() until after this statement.

	$self -> uid(0);
	$self -> tree(Tree -> new('root') );
	$self -> tree -> meta({end => 0, length => 0, start => 0, text => '', uid => $self -> uid});
	$self -> node_stack([$self -> tree -> root]);
	$self -> delimiter_stack([]);

	# Return 0 for success and 1 for failure.

	my($result) = 0;

	my($message);

	try
	{
		if (defined (my $value = $self -> _process) )
		{
			$self -> _post_process;
		}
		else
		{
			$result = 1;

			print "Error: Parse failed\n" if ($self -> options & print_errors);
		}
	}
	catch
	{
		$result = 1;

		print "Error: Parse failed. ${_}" if ($self -> options & print_errors);
	};

	# Return 0 for success and 1 for failure.

	return $result;

} # End of parse.

# ------------------------------------------------

sub _pop_node_stack
{
	my($self)  = @_;
	my($stack) = $self -> node_stack;

	pop @$stack;

	$self -> node_stack($stack);

} # End of _pop_node_stack.

# ------------------------------------------------

sub _process
{
	my($self)               = @_;
	my($stringref)          = $self -> text || \''; # Allow for undef. Use ' in comment for UltraEdit.
	my($pos)                = $self -> pos;
	my($first_pos)          = $pos;
	my($total_length)       = length($$stringref);
	my($length)             = $self -> length || $total_length;
	my($text)               = '';
	my($format)             = "%-20s    %5s    %5s    %5s    %-20s    %-20s\n";
	my($last_event)         = '';
	my($matching_delimiter) = $self -> matching_delimiter;

	if ($self -> options & print_debugs)
	{
		print "Length of input: $length. Input |$$stringref|\n";
		print sprintf($format, 'Event', 'Start', 'Span', 'Pos', 'Lexeme', 'Comment');
	}

	my($delimiter_frequency, $delimiter_stack);
	my($event_name);
	my($lexeme);
	my($message);
	my($original_lexeme);
	my($span, $start);
	my($tos);

	# We use read()/lexeme_read()/resume() because we pause at each lexeme.
	# Also, in read(), we use $pos and $length to avoid reading Ruby Slippers tokens (if any).
	# For the latter, see scripts/match.parentheses.02.pl in MarpaX::Demo::SampleScripts.

	for
	(
		$pos = $self -> recce -> read($stringref, $pos, $length);
		($pos < $total_length) && ( ($pos - $first_pos) <= $length);
		$pos = $self -> recce -> resume($pos)
	)
	{
		$delimiter_frequency       = $self -> delimiter_frequency;
		$delimiter_stack           = $self -> delimiter_stack;
		($start, $span)            = $self -> recce -> pause_span;
		($event_name, $span, $pos) = $self -> _validate_event($stringref, $start, $span, $pos, $delimiter_frequency);

		# If the input is exhausted, we exit immediately so we don't try to use
		# the values of $start, $span or $pos. They are ignored upon exit.

		last if ($event_name eq "'exhausted"); # Yes, it has a leading quote.

		$lexeme          = $self -> recce -> literal($start, $span);
		$original_lexeme = $lexeme;
		$pos             = $self -> recce -> lexeme_read($event_name);

		die "lexeme_read($event_name) rejected lexeme |$lexeme|\n" if (! defined $pos);

		print sprintf($format, $event_name, $start, $span, $pos, $lexeme, '-') if ($self -> options & print_debugs);

		if ($event_name eq 'close_delim')
		{
			push @$delimiter_stack,
				{
					event_name => $event_name,
					frequency  => $$delimiter_frequency{$lexeme},
					lexeme     => $lexeme,
					offset     => $start - 1, # Do not use length($lexeme)!
				};

			$$delimiter_frequency{$lexeme}--;

			$self -> delimiter_frequency($delimiter_frequency);
			$self -> delimiter_stack($delimiter_stack);
		}
		elsif ($event_name eq 'open_delim')
		{
			# The reason for using the matching delimiter here, is that problems arise when
			# the caller is using a mixture of symmetrical delimiters (open, close) = (", ")
			# and non-matching ones (open, close) = (<:, :>). The problem becomes visible in
			# the test 'if ($$delimiter_frequency{$lexeme} != 0)' in the loop just below.

			$$delimiter_frequency{$$matching_delimiter{$lexeme} }++;

			push @$delimiter_stack,
				{
					event_name => $event_name,
					frequency  => $$delimiter_frequency{$$matching_delimiter{$lexeme} },
					lexeme     => $lexeme,
					offset     => $start + length($lexeme),
				};

			$self -> delimiter_frequency($delimiter_frequency);
			$self -> delimiter_stack($delimiter_stack);
		}
		elsif ($event_name eq 'text')
		{
			$text .= $lexeme;
		}

		$last_event = $event_name;
    }

	# Cross-check the # of open/close delimiter pairs.

	for $lexeme (keys %$delimiter_frequency)
	{
		if ($$delimiter_frequency{$lexeme} != 0)
		{
			$message = "The # of open delimiters ($lexeme) does not match the # of close delimiters. Left over: $$delimiter_frequency{$lexeme}";

			$self -> error_message($message);
			$self -> error_number(1);

			if ($self -> options & $self -> options & mismatch_is_fatal)
			{
				# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

				die "$message\n";
			}
			else
			{
				$self -> error_number(-1);

				print "Warning: $message\n" if ($self -> options & print_warnings);
			}
		}
	}

	if ($self -> recce -> exhausted)
	{
		$message = 'Parse exhausted';

		$self -> error_message($message);
		$self -> error_number(6);

		if ($self -> options & exhaustion_is_fatal)
		{
			# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

			die "$message\n";
		}
		else
		{
			$self -> error_number(-6);

			print "Warning: $message\n" if ($self -> options & print_warnings);
		}
	}
	elsif (my $status = $self -> recce -> ambiguous)
	{
		my($terminals) = $self -> recce -> terminals_expected;
		$terminals     = ['(None)'] if ($#$terminals < 0);
		$message       = "Ambiguous parse. Status: $status. Terminals expected: " . join(', ', @$terminals);

		$self -> error_message($message);
		$self -> error_number(3);

		if ($self -> options & ambiguity_is_fatal)
		{
			# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

			die "$message\n";
		}
		elsif ($self -> options & print_warnings)
		{
			$self -> error_number(-3);

			print "Warning: $message\n";
		}
	}

	# Return a defined value for success and undef for failure.

	return $self -> recce -> value;

} # End of _process.

# ------------------------------------------------

sub _post_process
{
	my($self) = @_;

	# We scan the stack, looking for (open, close) delimiter events.

	my($stack)      = $self -> delimiter_stack;
	my($stringref)  = $self -> text;
	my($offset)     = 0;
	my($span_count) = 0;

	my($end_item);
	my($j);
	my($node_stack);
	my($start_item, $span, @span);
	my($text);

	for (my $i = 0; $i <= $#$stack; $i++)
	{
		$start_item = $$stack[$i];

		# Ignore everything but the next open delimiter event.

		next if ($$start_item{event_name} ne 'open_delim');

		$j = $i + 1;

		while ($j <= $#$stack)
		{
			$end_item = $$stack[$j];

			$j++;

			# Ignore everything but the corresponding close delimiter event.

			next if ($$end_item{event_name} ne 'close_delim');
			next if ($$start_item{frequency} != $$end_item{frequency});

			if ($#span < 0)
			{
				# First entry.
			}
			elsif ($$start_item{offset} <= $span[$#span])
			{
				# This start delimiter is within the span of the current delimiter pair,
				# so this span must be a child of the previous span.

				$self -> _push_node_stack;
			}
			else
			{
				# This start delimiter is after the span of the current delimiter pair,
				# so it's a new span, and is a sibling of the previous (just-closed) span.

				pop @span;

				# We only pop the node stack if it hash anything besides the root in it.

				$node_stack = $self -> node_stack;

				$self -> _pop_node_stack if ($#$node_stack > 0);
			}

			$span = $$end_item{offset} - $$start_item{offset} + 1;
			$text = substr($$stringref, $$start_item{offset}, $span);

			$self -> _add_daughter('span', {end => $$end_item{offset}, length => $span, start => $$start_item{offset}, text => $text});

			push @span, $$end_item{offset};

			last;
		}
	}

} # End of _post_process.

# ------------------------------------------------

sub _push_node_stack
{
	my($self)      = @_;
	my($stack)     = $self -> node_stack;
	my(@daughters) = $$stack[$#$stack] -> children;

	push @$stack, $daughters[$#daughters];

	$self -> node_stack($stack);

} # End of _push_node_stack.


# ------------------------------------------------

sub _validate_event
{
	my($self, $stringref, $start, $span, $pos, $delimiter_frequency) = @_;
	my(@event)       = @{$self -> recce -> events};
	my($event_count) = scalar @event;
	my(@event_name)  = sort map{$$_[0]} @event;
	my($event_name)  = $event_name[0]; # Default.

	# If the input is exhausted, we return immediately so we don't try to use
	# the values of $start, $span or $pos. They are ignored upon return.

	if ($event_name eq "'exhausted") # Yes, it has a leading quote.
	{
		return ($event_name, $span, $pos);
	}

	my($lexeme)        = substr($$stringref, $start, $span);
	my($line, $column) = $self -> recce -> line_column($start);
	my($literal)       = $self -> next_few_chars($stringref, $start + $span);
	my($message)       = "Location: ($line, $column). Lexeme: |$lexeme|. Next few chars: |$literal|";
	$message           = "$message. Events: $event_count. Names: ";

	print $message, join(', ', @event_name), "\n" if ($self -> options & print_debugs);

	my(%event_name);

	@event_name{@event_name} = (1) x @event_name;

	for (@event_name)
	{
		if (! ${$self -> known_events}{$_})
		{
			$message = "Unexpected event name '$_'";

			$self -> error_message($message);
			$self -> error_number(10);

			# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

			die "$message\n";
		}
	}

	if ($event_count > 1)
	{
		# We get here for single and double quotes because an open s. or d. quote is
		# indistinguishable from a close s. or d. quote, and that leads to ambiguity.

		if ( ($lexeme =~ /["']/) && (join(', ', @event_name) eq 'close_delim, open_delim') ) # ".
		{
			# At the time _validate_event() is called, the quote count has not yet been bumped.
			# If this is the 1st quote, then it's an open_delim.
			# If this is the 2nd quote, them it's a close delim.

			if ($$delimiter_frequency{$lexeme} % 2 == 0)
			{
				$event_name = 'open_delim';

				print "Disambiguated lexeme |$lexeme| as '$event_name'\n" if ($self -> options & print_debugs);
			}
			else
			{
				$event_name = 'close_delim';

				print "Disambiguated lexeme |$lexeme| as '$event_name'\n" if ($self -> options & print_debugs);
			}
		}
		else
		{
			$message = join(', ', @event_name);
			$message = "The code does not handle these events simultaneously: $message";

			$self -> error_message($message);
			$self -> error_number(11);

			# This 'die' is inside try{}catch{}, which adds the prefix 'Error: '.

			die "$message\n";
		}
	}

	return ($event_name, $span, $pos);

} # End of _validate_event.

# ------------------------------------------------

sub _validate_open_close
{
	my($self)  = @_;
	my($open)  = $self -> open;
	my($close) = $self -> close;

	my($message);

	if ( ($open eq '') || ($close eq '') )
	{
		$message = 'You must specify a pair of open/close delimiters';

		$self -> error_message($message);
		$self -> error_number(8);

		# This 'die' is not inside try{}catch{}, so we add the prefix 'Error: '.

		die "Error: $message\n";
	}

	my(%substitute)         = (_close_ => '', _delimiter_ => '', _open_ => '');
	my($matching_delimiter) = {};
	my(%seen)               = (close => {}, open => {});

	my($close_quote);
	my(%delimiter_action);
	my($open_quote);
	my($prefix, %prefix);

	if ( ($open =~ /\\/) || ($close =~ /\\/) )
	{
		$message = 'Backslash is forbidden as a delimiter character';

		$self -> error_message($message);
		$self -> error_number(4);

		# This 'die' is not inside try{}catch{}, so we add the prefix 'Error: '.

		die "Error: $message\n";
	}

	if ( ( (length($open) > 1) && ($open =~ /'/) ) || ( (length($close) > 1) && ($close =~ /'/) ) )
	{
		$message = 'Single-quotes are forbidden in multi-character delimiters';

		$self -> error_message($message);
		$self -> error_number(5);

		# This 'die' is not inside try{}catch{}, so we add the prefix 'Error: '.

		die "Error: $message\n";
	}

	$seen{open}{$open}   = 0 if (! $seen{open}{$open});
	$seen{close}{$close} = 0 if (! $seen{close}{$close});

	$seen{open}{$open}++;
	$seen{close}{$close}++;

	$delimiter_action{$open}    = 'open';
	$delimiter_action{$close}   = 'close';
	$$matching_delimiter{$open} = $close;

	if (length($open) == 1)
	{
		$open_quote = $open eq '[' ? "[\\$open]" : "[$open]";
	}
	else
	{
		# This fails if length > 1 and open contains a single quote.

		$open_quote = "'$open'";
	}

	if (length($close) == 1)
	{
		$close_quote = $close eq ']' ? "[\\$close]" : "[$close]";
	}
	else
	{
		# This fails if length > 1 and close contains a single quote.

		$close_quote = "'$close'";
	}

	$substitute{_open_}  .= "open_delim\t\t\t\~ $open_quote\n"   if ($seen{open}{$open} <= 1);
	$substitute{_close_} .= "close_delim\t\t\t\~ $close_quote\n" if ($seen{close}{$close} <= 1);
	$prefix              = substr($open, 0, 1);
	$prefix              = "\\$prefix" if ($prefix =~ /[\[\]]/);
	$prefix{$prefix}     = 0 if (! $prefix{$prefix});

	$prefix{$prefix}++;

	$substitute{_delimiter_} .= $prefix if ($prefix{$prefix} == 1);
	$prefix                  = substr($close, 0, 1);
	$prefix                  = "\\$prefix" if ($prefix =~ /[\[\]]/);
	$prefix{$prefix}         = 0 if (! $prefix{$prefix});

	$prefix{$prefix}++;

	$substitute{_delimiter_} .= $prefix if ($prefix{$prefix} == 1);

	$self -> delimiter_action(\%delimiter_action);
	$self -> matching_delimiter($matching_delimiter);

	return \%substitute;

} # End of _validate_open_close.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Text::Delimited::Marpa> - Extract delimited text sequences from strings

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Text::Delimited::Marpa ':constants';

	# -----------

	my(%count)  = (fail => 0, success => 0, total => 0);
	my($parser) = Text::Delimited::Marpa -> new
	(
		open    => '/*',
		close   => '*/',
		options => print_errors | print_warnings | mismatch_is_fatal,
	);
	my(@text) =
	(
		q|Start /* One /* Two /* Three */ Four */ Five */ Finish|,
	);

	my($result);
	my($text);

	for my $i (0 .. $#text)
	{
		$count{total}++;

		$text = $text[$i];

		print "Parsing |$text|. pos: ", $parser -> pos, '. length: ', $parser -> length, "\n";

		$result = $parser -> parse(text => \$text);

		print "Parse result: $result (0 is success)\n";

		if ($result == 0)
		{
			$count{success}++;

			print join("\n", @{$parser -> tree -> tree2string}), "\n";
		}
	}

	$count{fail} = $count{total} - $count{success};

	print "\n";
	print 'Statistics: ', join(', ', map{"$_ => $count{$_}"} sort keys %count), ". \n";

This is the output of synopsis.pl:

	Parsing |Start /* One /* Two /* Three */ Four */ Five */ Finish|. pos: 0. length: 0
	Parse result: 0 (0 is success)
	root. Attributes: {end => "0", length => "0", start => "0", text => "", uid => "0"}
	    |--- span. Attributes: {end => "44", length => "37", start => "8", text => " One /* Two /* Three */ Four */ Five ", uid => "1"}
	         |--- span. Attributes: {end => "36", length => "22", start => "15", text => " Two /* Three */ Four ", uid => "2"}
	              |--- span. Attributes: {end => "28", length => "7", start => "22", text => " Three ", uid => "3"}

	Statistics: fail => 0, success => 1, total => 1.

See also scripts/tiny.pl and scripts/traverse.pl.

=head1 Description

L<Text::Delimited::Marpa> provides a L<Marpa::R2>-based parser for extracting delimited text
sequences from strings. The text between the delimiters is stored as nodes in a tree managed by
L<Tree>. The delimiters, and the text outside the delimiters, is not saved in the tree.

Nested strings with the same delimiters are saved as daughters of their enclosing strings' tree
nodes. As you can see from the output just above, this nesting process is repeated as many times as
the delimiters themselves are nested.

You can ignore the nested, delimited, strings by just processing the daughters of the tree's root
node.

This module is a companion to L<Text::Balanced::Marpa>. The differences are discussed in the L</FAQ>
below.

See the L</FAQ> for various topics, including:

=over 4

=item o UFT8 handling

See t/utf8.t.

=item o Escaping delimiters within the text

See t/escapes.t.

=item o Options to make mismatched delimiters fatal errors

See t/escapes.t and t/perl.delimiters.

=item o Processing the tree-structured output

See scripts/traverse.pl.

=item o Emulating L<Text::Xslate>'s use of '<:' and ':>

See t/colons.t and t/percents.t.

=item o Skipping (leading) characters in the input string

See t/skip.prefix.t.

=item o Implementing hard-to-read text strings as delimiters

See t/silly.delimiters.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Text::Delimited::Marpa> as you would any C<Perl> module:

Run:

	cpanm Text::Delimited::Marpa

or run:

	sudo cpan Text::Delimited::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Text::Delimited::Marpa -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Text::Delimited::Marpa>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</text([$stringref])>]):

=over 4

=item o close => $string

The closing delimiter.

A value for this option is mandatory.

Default: None.

=item o length => $integer

The maximum length of the input string to process.

This parameter works in conjunction with the C<pos> parameter.

C<length> can also be used as a key in the hash passed to L</parse([%hash])>.

See the L</FAQ> for details.

Default: Calls Perl's length() function on the input string.

=item o next_few_limit => $integer

This controls how many characters are printed when displaying 'the next few chars'.

It only affects debug output.

Default: 20.

=item o open => $string

The opening delimiter.

See the L</FAQ> for details and warnings.

A value for this option is mandatory.

Default: None.

=item o options => $bit_string

This allows you to turn on various options.

C<options> can also be used as a key in the hash passed to L</parse([%hash])>.

Default: 0 (nothing is fatal).

See the L</FAQ> for details.

=item o pos => $integer

The offset within the input string at which to start processing.

This parameter works in conjunction with the C<length> parameter.

C<pos> can also be used as a key in the hash passed to L</parse([%hash])>.

See the L</FAQ> for details.

Note: The first character in the input string is at pos == 0.

Default: 0.

=item o text => $stringref

This is a reference to the string to be parsed. A stringref is used to avoid copying what could
potentially be a very long string.

C<text> can also be used as a key in the hash passed to L</parse([%hash])>.

Default: \''.

=back

=head1 Methods

=head2 bnf()

Returns a string containing the grammar constructed based on user input.

=head2 close()

Get the closing delimiter.

See also L</open()>.

See the L</FAQ> for details and warnings.

'close' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 delimiter_action()

Returns a hashref, where the keys are delimiters and the values are either 'open' or 'close'.

=head2 error_message()

Returns the last error or warning message set.

Error messages always start with 'Error: '. Messages never end with "\n".

Parsing error strings is not a good idea, ever though this module's format for them is fixed.

See L</error_number()>.

=head2 error_number()

Returns the last error or warning number set.

Warnings have values < 0, and errors have values > 0.

If the value is > 0, the message has the prefix 'Error: ', and if the value is < 0, it has the
prefix 'Warning: '. If this is not the case, it's a reportable bug.

Possible values for error_number() and error_message():

=over 4

=item o 0 => ""

This is the default value.

=item o 1/-1 => "The # of open delimiters ($lexeme) does not match the # of close delimiters. Left over: $integer"

If L</error_number()> returns 1 it's an error, and if it returns -1 it's a warning.

You can set the option C<overlap_is_fatal> to make it fatal.

=item o 2/-2 => (Not used)

=item o 3/-3 => "Ambiguous parse. Status: $status. Terminals expected: a, b, ..."

This message is only produced when the parse is ambiguous.

If L</error_number()> returns 3 it's an error, and if it returns -3 it's a warning.

You can set the option C<ambiguity_is_fatal> to make it fatal.

=item o 4 => "Backslash is forbidden as a delimiter character"

The check which triggers this preempts some types of sabotage.

This message always indicates an error, never a warning.

=item o 5 => "Single-quotes are forbidden in multi-character delimiters"

This limitation is due to the syntax of
L<Marpa's DSL|https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod>.

This message always indicates an error, never a warning.

=item o 6/-6 => "Parse exhausted"

If L</error_number()> returns 6 it's an error, and if it returns -6 it's a warning.

You can set the option C<exhaustion_is_fatal> to make it fatal.

=item o 7 => 'Single-quote is forbidden as an escape character'

This limitation is due to the syntax of
L<Marpa's DSL|https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/DSL.pod>.

This message always indicates an error, never a warning.

=item o 8 => "There must be at least 1 pair of open/close delimiters"

This message always indicates an error, never a warning.

=item o 10 => "Unexpected event name 'xyz'"

Marpa has triggered an event and it's name is not in the hash of event names derived from the BNF.

This message always indicates an error, never a warning.

=item o 11 => "The code does not handle these events simultaneously: a, b, ..."

The code is written to handle single events at a time, or in rare cases, 2 events at the same time.
But here, multiple events have been triggered and the code cannot handle the given combination.

This message always indicates an error, never a warning.

=back

See L</error_message()>.

=head2 escape_char()

Get the escape char.

=head2 known_events()

Returns a hashref where the keys are event names and the values are 1.

=head2 length([$integer])

Here, the [] indicate an optional parameter.

Get or set the length of the input string to process.

See also the L</FAQ> and L</pos([$integer])>.

'length' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 matching_delimiter()

Returns a hashref where the keys are opening delimiters and the values are the corresponding closing
delimiters.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 next_few_chars($stringref, $offset)

Returns a substring of $s, starting at $offset, for use in debug messages.

See L<next_few_limit([$integer])>.

=head2 next_few_limit([$integer])

Here, the [] indicate an optional parameter.

Get or set the number of characters called 'the next few chars', which are printed during debugging.

'next_few_limit' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 open()

Get the opening delimiter.

See also L</close()>.

See the L</FAQ> for details and warnings.

'open' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 options([$bit_string])

Here, the [] indicate an optional parameter.

Get or set the option flags.

For typical usage, see scripts/synopsis.pl.

See the L</FAQ> for details.

'options' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 parse([%hash])

Here, the [] indicate an optional parameter.

This is the only method the user needs to call. All data can be supplied when calling L</new()>.

You can of course call other methods (e.g. L</text([$stringref])> ) after calling L</new()> but
before calling C<parse()>.

The optional hash takes these ($key => $value) pairs (exactly the same as for L</new()>):

=over 4

=item o length => $integer

=item o options => $bit_string

=item o pos => $integer

=item o text => $stringref

=back

Note: If a value is passed to C<parse()>, it takes precedence over any value with the same
key passed to L</new()>, and over any value previously passed to the method whose name is $key.
Further, the value passed to C<parse()> is always passed to the corresponding method (i.e. whose
name is $key), meaning any subsequent call to that method returns the value passed to C<parse()>.

Returns 0 for success and 1 for failure.

If the value is 1, you should call L</error_number()> to find out what happened.

=head2 pos([$integer])

Here, the [] indicate an optional parameter.

Get or set the offset within the input string at which to start processing.

See also the L</FAQ> and L</length([$integer])>.

'pos' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 text([$stringref])

Here, the [] indicate an optional parameter.

Get or set a reference to the string to be parsed.

'text' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 tree()

Returns an object of type L<Tree>, which holds the parsed data.

Obviously, it only makes sense to call C<tree()> after calling C<parse()>.

See scripts/traverse.pl for sample code which processes this tree's nodes.

=head1 FAQ

=head2 What are the differences between Text::Balanced::Marpa and Text::Delimited::Marpa?

I think this is shown most clearly by getting the 2 modules to process the same string. So,
using this as input:

	'a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k'

Output from Text::Balanced::Marpa's scripts/tiny.pl:

	(#   2) |          1         2         3         4         5         6         7         8         9
	        |0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	Parsing |Skip me ->a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|. pos: 10. length: 42
	Parse result: 0 (0 is success)
	root. Attributes: {text => "", uid => "0"}
	    |--- text. Attributes: {text => "a ", uid => "1"}
	    |--- open. Attributes: {text => "<:", uid => "2"}
	    |    |--- text. Attributes: {text => "b ", uid => "3"}
	    |    |--- open. Attributes: {text => "<:", uid => "4"}
	    |    |    |--- text. Attributes: {text => "c", uid => "5"}
	    |    |--- close. Attributes: {text => ":>", uid => "6"}
	    |    |--- text. Attributes: {text => " d", uid => "7"}
	    |--- close. Attributes: {text => ":>", uid => "8"}
	    |--- text. Attributes: {text => " e ", uid => "9"}
	    |--- open. Attributes: {text => "<:", uid => "10"}
	    |    |--- text. Attributes: {text => "f ", uid => "11"}
	    |    |--- open. Attributes: {text => "<:", uid => "12"}
	    |    |    |--- text. Attributes: {text => " g ", uid => "13"}
	    |    |    |--- open. Attributes: {text => "<:", uid => "14"}
	    |    |    |    |--- text. Attributes: {text => "h", uid => "15"}
	    |    |    |--- close. Attributes: {text => ":>", uid => "16"}
	    |    |    |--- text. Attributes: {text => " i", uid => "17"}
	    |    |--- close. Attributes: {text => ":>", uid => "18"}
	    |    |--- text. Attributes: {text => " j", uid => "19"}
	    |--- close. Attributes: {text => ":>", uid => "20"}
	    |--- text. Attributes: {text => " k", uid => "21"}

Output from Text::Delimited::Marpa's scripts/tiny.pl:

	(#   2) |          1         2         3         4         5         6         7         8         9
	        |0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
	Parsing |Skip me ->a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|. pos: 10. length: 42
	Parse result: 0 (0 is success)
	root. Attributes: {end => "0", length => "0", start => "0", text => "", uid => "0"}
	    |--- span. Attributes: {end => "22", length => "9", start => "14", text => "b <:c:> d", uid => "1"}
	    |    |--- span. Attributes: {end => "18", length => "1", start => "18", text => "c", uid => "2"}
	    |--- span. Attributes: {end => "47", length => "18", start => "30", text => "f <: g <:h:> i:> j", uid => "3"}
	         |--- span. Attributes: {end => "43", length => "10", start => "34", text => " g <:h:> i", uid => "4"}
	              |--- span. Attributes: {end => "39", length => "1", start => "39", text => "h", uid => "5"}

Another example, using the same input string, but manually processing the tree nodes.
Parent-daughter relationships are here represented by indentation.

Output from Text::Balanced::Marpa's scripts/traverse.pl:

	        |          1         2         3         4         5
	        |012345678901234567890123456789012345678901234567890
	Parsing |a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|.
	Span  Text
	   1  |a |
	   2  |<:|
	   3    |b |
	   4    |<:|
	   5      |c|
	   6    |:>|
	   7    | d|
	   8  |:>|
	   9  | e |
	  10  |<:|
	  11    |f |
	  12    |<:|
	  13      | g |
	  14      |<:|
	  15        |h|
	  16      |:>|
	  17      | i|
	  18    |:>|
	  19    | j|
	  20  |:>|
	  21  | k|

Output from Text::Delimited::Marpa's scripts/traverse.pl:

	        |          1         2         3         4         5
	        |012345678901234567890123456789012345678901234567890
	Parsing |a <:b <:c:> d:> e <:f <: g <:h:> i:> j:> k|.
	Span  Start  End  Length  Text
	   1      4   12       9  |b <:c:> d|
	   2      8    8       1    |c|
	   3     20   37      18  |f <: g <:h:> i:> j|
	   4     24   33      10    | g <:h:> i|
	   5     29   29       1      |h|

=head2 How do I ignore embedded strings which have the same delimiters as their containing strings?

You can ignore the nested, delimited, strings by just processing the daughters of the tree's root
node.

=head2 Where are the error messages and numbers described?

See L</error_message()> and L</error_number()>.

=head2 How do I escape delimiters?

By backslash-escaping the first character of all open and close delimiters which appear in the
text.

As an example, if the delimiters are '<:' and ':>', this means you have to escape I<all> the '<'
chars and I<all> the colons in the text.

The backslash is preserved in the output.

If you don't want to use backslash for escaping, or can't, you can pass a different escape character
to L</new()>.

See t/escapes.t.

=head2 How do the length and pos parameters to new() work?

The recognizer - an object of type Marpa::R2::Scanless::R - is called in a loop, like this:

	for
	(
		$pos = $self -> recce -> read($stringref, $pos, $length);
		$pos < $length;
		$pos = $self -> recce -> resume($pos)
	)

L</pos([$integer])> and L</length([$integer])> can be used to initialize $pos and $length.

Note: The first character in the input string is at pos == 0.

See L<https://metacpan.org/pod/distribution/Marpa-R2/pod/Scanless/R.pod#read> for details.

=head2 Does this package support Unicode/UTF8?

Yes. See t/escapes.t and t/utf8.t.

=head2 Does this package handler Perl delimiters (e.g. q|..|, qq|..|, qr/../, qw/../)?

See t/perl.delimiters.t.

=head2 Warning: Calling mutators after calling new()

The only mutator which works after calling new() is L</text([$stringref])>.

In particular, you can't call L</escape_char()>, L</open()> or L</close()> after calling L</new()>.
This is because parameters passed to C<new()> are interpolated into the grammar before parsing
begins. And that's why the docs for those methods all say 'Get the...' and not 'Get and set the...'.

To make the code work, you would have to manually call _validate_open_close(). But even then
a lot of things would have to be re-initialized to give the code any hope of working.

=head2 What is the format of the 'open' and 'close' parameters to new()?

Each of these parameters takes a string as a value, and these are used as the opening and closing
delimiter pair.

See scripts/synopsis.pl and scripts/tiny.pl.

=head2 What are the possible values for the 'options' parameter to new()?

Firstly, to make these constants available, you must say:

	use Text::Delimited::Marpa ':constants';

Secondly, more detail on errors and warnings can be found at L</error_number()>.

Thirdly, for usage of these option flags, see t/angle.brackets.t, t/colons.t, t/escapes.t,
t/percents.t and scripts/tiny.pl.

Now the flags themselves:

=over 4

=item o nothing_is_fatal

This is the default.

C<nothing_is_fatal> has the value of 0.

=item o print_errors

Print errors if this flag is set.

C<print_errors> has the value of 1.

=item o print_warnings

Print various warnings if this flag is set:

=over 4

=item o The ambiguity status and terminals expected, if the parse is ambiguous

=item o See L</error_number()> for other warnings which might be printed

Ambiguity is not, in and of itself, an error. But see the C<ambiguity_is_fatal> option, below.

=back

It's tempting to call this option C<warnings>, but Perl already has C<use warnings>, so I didn't.

C<print_warnings> has the value of 2.

=item o print_debugs

Print extra stuff if this flag is set.

C<print_debugs> has the value of 4.

=item o mismatch_is_fatal

This means a fatal error occurs when the number of open delimiters does not match the number of
close delimiters.

C<overlap_is_fatal> has the value of 8.

=item o ambiguity_is_fatal

This makes L</error_number()> return 3 rather than -3.

C<ambiguity_is_fatal> has the value of 16.

=item o exhaustion_is_fatal

This makes L</error_number()> return 6 rather than -6.

C<exhaustion_is_fatal> has the value of 32.

=back

=head2 How do I print the tree built by the parser?

See L</Synopsis>.

=head2 How do I make use of the tree built by the parser?

See scripts/traverse.pl.

=head2 How is the parsed data held in RAM?

The parsed output is held in a tree managed by L<Tree>.

The tree always has a root node, which has nothing to do with the input data. So, even an empty
input string will produce a tree with 1 node. This root has an empty hashref associated with it.

Nodes have a name and a hashref of attributes.

The name indicates the type of node. Names are one of these literals:

=over 4

=item o root

=item o span

=back

The (key => value) pairs in the hashref are:

=over 4

=item o end => $integer

The offset into the original stringref at which the current span of text ends.

=item o length => $integer

The number of characters in the current span.

=item o start => $integer

The offset into the original stringref at which the current span of text starts.

=item o text => $string

If the node name is 'text', $string is the verbatim text from the document.

Verbatim means, for example, that backslashes in the input are preserved.

=back

=head2 What is the homepage of Marpa?

L<http://savage.net.au/Marpa.html>.

That page has a long list of links.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o Advanced error reporting

See L<https://jeffreykegler.github.io/Ocean-of-Awareness-blog/individual/2014/11/delimiter.html>.

Perhaps this could be a sub-class?

=item o I8N support for error messages

=item o An explicit test program for parse exhaustion

=back

=head1 See Also

L<Text::Balanced::Marpa>.

L<Tree> and L<Tree::Persist>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Thanks

Thanks to Jeffrey Kegler, who wrote Marpa and L<Marpa::R2>.

And thanks to rns (Ruslan Shvedov) for writing the grammar for double-quoted strings used in
L<MarpaX::Demo::SampleScripts>'s scripts/quoted.strings.02.pl. I adapted it to HTML (see
scripts/quoted.strings.05.pl in that module), and then incorporated the grammar into
L<GraphViz2::Marpa>, and - after more extensions - into this module.

Lastly, thanks to Robert Rothenberg for L<Const::Exporter>, a module which works the same way
Perl does.

=head1 Repository

L<https://github.com/ronsavage/Text-Delimited-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text::Delimited::Marpa>.

=head1 Author

L<Text::Delimited::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
