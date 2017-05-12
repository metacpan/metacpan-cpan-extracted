package Text::Snippet::TabStop::Basic;
BEGIN {
  $Text::Snippet::TabStop::Basic::VERSION = '0.04';
}

# ABSTRACT: Basic TabStop

use strict;
use warnings;

use base qw(Text::Snippet::TabStop);


sub parse {
	my $class = shift;
	my $src = shift;
	if($src =~ m/^\$(\d+)$/ || $src =~ m/^\$\{(\d+)\}$/){
		return $class->_new( index => $1, src => $src );
	}
	return;
}

1;

__END__
=pod

=head1 NAME

Text::Snippet::TabStop::Basic - Basic TabStop

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This class provides basic tab stop functionality and inherits from
L<Text::Snippet::TabStop>.

=head1 CLASS METHODS

=head2 parse

The main entry point into this class.  It takes a single argument which
consists of the source of the tab stop within the snippet.

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

