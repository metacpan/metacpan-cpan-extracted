package Text::Snippet::TabStop::WithTransformer;
BEGIN {
  $Text::Snippet::TabStop::WithTransformer::VERSION = '0.04';
}

# ABSTRACT: Tab stop that modifies the replacement value supplied by the user

use strict;
use warnings;
use base qw(Text::Snippet::TabStop);
use Carp qw(croak);
use Class::XSAccessor getters => { transformer => 'transformer' };


sub to_string {
	my $self = shift;
	my $output = $self->SUPER::to_string;
	return $self->transformer->($output);
}
sub parse {
	my $class = shift;
	my $src   = shift;
	if ( $src =~ m{^\$\{(\d+)/([^/]+?)/([^/]*)/(.*?)\}$} ) {
		my ( $tab_index, $search, $replace, $flags ) = ( $1, $2, $3, $4 );
		$replace =~ s/\$0/\$&/g;
		if ( length($flags) ) {
			$search = "(?$flags$search)";
		}
		my $transformer = sub {
			my $out = shift;
			if ( $out =~ m/$search/ ) {
				eval "\$out =~ s{\$search}{$replace}g";
				die $@ if($@);
			}
			return $out;
		};
		return $class->_new( src => $src, index => $tab_index, transformer => $transformer );
	}
	return;
}

1;

__END__
=pod

=head1 NAME

Text::Snippet::TabStop::WithTransformer - Tab stop that modifies the replacement value supplied by the user

=head1 VERSION

version 0.04

=head1 EXAMPLE SYNTAX

=over 4

=item * simple search/replace

	${1/search/replace/}

=item * supports standard regex flags (global, case-insensitive in this example)

	${1/something/else/gi}

=item * supports captures (capitalizes first character of replacement)

	${1/^(.)/\U$1/}

=item * for TextMate compatibility, C<$0> returns the entire matched string (think C<$&>)

	# capitalize the entire replacement value
	${1/.+/\U$0/g}

=back

=head1 CLASS METHODS

=head2 parse

This method parses the index and transforming regular expression that
are specified in the tab stop.

=head1 INSTANCE METHODS

=over 4

=item * transformer

Returns a CodeRef that takes a single argument (a string) and returns
a modified version of that string after applying a transformation to
that string.

=item * to_string

Augments super-class' to_string method and returns the modified value
after applying the transformation specified in the tab stop.

=back

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

