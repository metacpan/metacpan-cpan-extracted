package Text::Snippet::TabStop::Parser;
BEGIN {
  $Text::Snippet::TabStop::Parser::VERSION = '0.04';
}

# ABSTRACT: Parses an individual tab stop

use strict;
use warnings;
use List::Util qw(first);
use Carp qw(croak);

my @types;
BEGIN {
	@types = map { "Text::Snippet::TabStop::$_" } qw( Basic WithDefault WithTransformer );
	for(@types){
		eval "require $_";
		croak $@ if $@;
	}
}


sub parse {
    my $class = shift;
    my $src = shift;
	foreach my $t(@types){
		my $p = $t->parse($src);
		return $p if defined $p;
	}
	croak "unable to find parser for tab stop source: [$src]";
}

1;

__END__
=pod

=head1 NAME

Text::Snippet::TabStop::Parser - Parses an individual tab stop

=head1 VERSION

version 0.04

=head1 CLASS METHODS

=head2 parse

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

