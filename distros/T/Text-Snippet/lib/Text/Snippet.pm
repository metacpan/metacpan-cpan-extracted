package Text::Snippet;
BEGIN {
  $Text::Snippet::VERSION = '0.04';
}

# ABSTRACT: TextMate-like snippet functionality

use warnings;
use strict;
use Text::Balanced qw(extract_bracketed extract_multiple);
use Text::Snippet::TabStop::Parser;
use Text::Snippet::TabStop::Cursor;
use Scalar::Util qw(blessed);
use Carp qw(croak);


sub _new {
	my $class = shift;
	my $args = ref($_[0]) ? shift : {@_};
	my $self = {
		chunks    => [],
		tab_stops => [],
		%$args
	};
	croak "no src attribute specified" unless defined($self->{src});
	return bless $self, $class;
}
sub parse {
	my $class  = shift;
	my $source = shift;
	my @raw    = extract_multiple( $source, [ { Simple => qr/\$\d+/ },
			{ Curly  => sub { extract_bracketed( $_[0], '{}', '\$(?=\{\d)' ) } },
			{ Plain  => qr/[^\$]+/ },
	], undef, 1); 

	my %tab_stop_cache;
	my @chunks;
	foreach my $c (@raw) {
		if ( ref($c) eq 'Plain' ) {
			push( @chunks, $$c );
		} else {

			# the leading $ gets stripped on these by extract_bracketed...
			$$c = '$' . $$c if(ref($c) eq 'Curly');

			my $t = Text::Snippet::TabStop::Parser->parse( $$c );

			if ( exists( $tab_stop_cache{ $t->index } ) ) {
				$t->parent($tab_stop_cache{ $t->index });
			} else {
				$tab_stop_cache{ $t->index } = $t;
			}
			push( @chunks, $t );
		}
	}

	my @tab_stops = map { $tab_stop_cache{$_} } sort { $a <=> $b } keys %tab_stop_cache;

	if ( exists( $tab_stop_cache{'0'} ) ) {
		# put the zero-th tab stop on the end of the array
		push( @tab_stops, shift(@tab_stops) );
	} else {
		# append the implicit zero-th tab stop on the end of the array
		my $implicit = Text::Snippet::TabStop::Parser->parse( '$0' );
		push( @tab_stops, $implicit );
		push( @chunks,       $implicit );
	}

	my %params = (
		src       => $source,
		chunks    => \@chunks,
		tab_stops => \@tab_stops,
	);
	return $class->_new(%params);
}



use overload '""' => sub { shift->to_string }, fallback => 1;

sub to_string {
	my $self = shift;
	return join( '', @{ $self->chunks } ) || '';
}

use Class::XSAccessor getters => { src => 'src', tab_stops => 'tab_stops', chunks => 'chunks' };


sub cursor {
	my $self = shift;
	return Text::Snippet::TabStop::Cursor->new( snippet => $self );
}


1;

__END__
=pod

=head1 NAME

Text::Snippet - TextMate-like snippet functionality

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This module provides TextMate-like snippet functionality via an
editor-agnostic API.  The snippet syntax is modeled after the
snippets provided by TextMate.

    use Text::Snippet;

    my $snippet = Text::Snippet->parse($snippet_content);

	my @tabstops = $snippet->tab_stops;
	foreach my $t (@tabstops) {
		my $replacement = get_user_input();    # get user input somehow
		$t->replace($replacement) if ($user_input);
	}
	print $snippet;                           # stringify and write to STDOUT
	
	# alternate "cursor" interface

	my $cursor = $snippet->cursor;
	while ( my $direction = get_user_tab_direction() ) {    # forward or backward
		my $t;
		if ( $direction == 1 ) {          # tab
			$t = $cursor->next;
		} elsif ( $direction == -1 ) {    # shift-tab
			$t = $cursor->prev;
		} else {
			last;                         # bail
		}
		next if ( !$t );

		# get (zero-based) cursor position relative to the beginning of the snippet
		my($line, $column) = $cursor->current_position;

		my $replacement = get_user_input();
		$t->replace($replacement);
	}
	print $snippet; # stringify snippet and write to STDOUT

=head1 SUPPORTED SNIPPET SYNTAX

=over 4

=item * Plain text

The simplest snippet is just plain text with no tab stops and is returned
verbatim to the caller.

=item * Simple tab stops

Tab stops are indications for where the cursor should be placed after
the user inserts a snippet.  Simple tab stops are simply a dollar sign
followed by a digit.  The special C<$0> tab stop is terminal and is where
the cursor will end up when the user has progressed through all other
tab stops defined by the snippet.  If no C<$0> tab stop is indicated,
one is added by default right after the final character of the snippet.
A simple "if" snippet (two explicit tab stops plus an implicit terminal
after the closing brace of the C<if> block):

	if ($1) {
		$2
	}

=item * Tab stops with defaults

Sometimes a snippet may provide a default value to the user to make the
snippet easier to flesh out.  These types of tab stops look like so:

	while( my(\$${1:key}, \$${2:value}) = each(%${3:hash}) {
		$0
	}

While navigating through the tab stops, the first three positions
will provide default values ("key", "value" and "hash" respectively).
The terminal tab stop will leave the cursor in the body of the C<while>
block.

=item * Tab stops with mirroring

Sometimes you may want the value the user entered in one tab stop to be
copied to another.  This (in TextMate lingo) is called mirroring.  This is
very simple to do, just use the same index on more than one tab stop and
the content entered in the first will automatically be used in the others.
A rather contrived example:

	foreach my \$${1:item} (@${2:array}) {
		print "$${1}\n";
	}

All occurences of the first tab stop (the loop variable and in the C<print>
statement) will have the same value (defaulting to "item").

=item * Transforming tab stops

The most advanced type of tab stop allows you to modify the entered
value on the fly using a regular expression.  For instance, if you like
to use C<getFoo> and C<setFoo> accessors with Moose, you might use the
following snippet:

	has ${1:propertyName} => (
		is => '${2:rw}',
		isa => '${3:Str}',
		reader => 'get${1/./\u$0/}),
		writer => 'set${1/./\u$0}),
	);

If the user leaves all the defaults, the output of this snippet would be:

	has propertyName => (
		is => 'rw',
		isa => 'Str',
		reader => 'getPropertyName',
		writer => 'setPropertyName'
	);

Another example would be a helper snippet for creating simple HTML tags:

	<${1:a}>${2}</${1/\s.*//}>

The transformer on the mirrored tab stop essentially will truncate
anything starting with the first whitespace character entered by the
user.  If the user enters C<a href="http://search.cpan.org"> as the 
first replacement value, the mirrored tab stop will have a replacement
of just C<a>.

=back

=head1 CLASS METHODS

=head2 parse

This is the main entry point into this module's functionality.  It takes
a single argument, the content of the snippet that conforms to the syntax
described above.

=head1 INSTANCE METHODS

=head2 to_string

Obviously, gets the full content of the snippet as it currently exists.
This object is overloaded as well so simply printing the object or
including it inside double quotes will have the same effect.

=head2 chunks

Returns an ArrayRef that makes up the entire content of the
snippet. Depending on the source of the snippet, some of these items
may be literal scalars (representing static content) and others may
be L<Text::Snippet::TabStop> objects that represent the user-enterable
portions of the snippet.

=head2 src

This returns the original source as it was passed to "parse"

=head2 tab_stops

This returns an ArrayRef of L<Text::Snippet::TabStop> objects that
represent the user-enterable portions of the snippet.  These are ordered
by the tab stop's index with the zero-th index coming last.

=head2 cursor

This method creates a L<Text::Snippet::TabStop::Cursor> object for
you which allows the caller to traverse a series of tab stops in a
convenient fashion.

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-snippet at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Snippet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Snippet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Snippet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Snippet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Snippet>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Snippet/>

=back

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

