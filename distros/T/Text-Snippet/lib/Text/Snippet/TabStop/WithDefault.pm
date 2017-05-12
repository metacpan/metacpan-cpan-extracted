package Text::Snippet::TabStop::WithDefault;
BEGIN {
  $Text::Snippet::TabStop::WithDefault::VERSION = '0.04';
}

# ABSTRACT: Tab stop that specifies a default value for the user

use strict;
use warnings;
use base qw(Text::Snippet::TabStop);
use Carp qw(croak);
use Class::XSAccessor getters => { default => 'default' };


sub replacement {
	my $self = shift;
	return $self->has_replacement ? $self->SUPER::replacement : $self->default;
}

sub parse {
	my $class = shift;
	my $src = shift;
	if($src =~ m/\$\{(\d+):(.*)\}/){
		return $class->_new( index => $1, src => $src, default => $2 || '' );
	}
	return;
}

1;

__END__
=pod

=head1 NAME

Text::Snippet::TabStop::WithDefault - Tab stop that specifies a default value for the user

=head1 VERSION

version 0.04

=head1 EXAMPLE SYNTAX

	${1:default value here}

=head1 CLASS METHODS

=head2 parse

This method parses the index and default value from the source that is
passed in.

=head1 INSTANCE METHODS

=over 4

=item * default

Returns the default value as parsed from the original source of the tab stop.

=item * replacement

Augments super-class' replacement method an returns the default value if no
replacement has been specified.

=back

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

