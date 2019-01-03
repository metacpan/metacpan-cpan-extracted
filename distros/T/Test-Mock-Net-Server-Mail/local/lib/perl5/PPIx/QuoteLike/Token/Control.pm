package PPIx::QuoteLike::Token::Control;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::QuoteLike::Token };

use PPIx::QuoteLike::Constant qw{ @CARP_NOT };

our $VERSION = '0.006';

{
    # TODO make this a state variable when we can require Perl 5.10.
    my $introduced = {
	'\\F'	=> '5.015008',
    };

    sub __perl_version_introduced {
	my ( $self ) = @_;
	return $introduced->{ $self->content() };
    }
}

1;

__END__

=head1 NAME

PPIx::QuoteLike::Token::Control - Represent case and quote control

=head1 SYNOPSIS

This class should not be instantiated by the user. See below for public
methods.

=head1 INHERITANCE

C<PPIx::QuoteLike::Token::Control> is a
L<PPIx::QuoteLike::Token|PPIx::QuoteLike::Token>.

C<PPIx::QuoteLike::Token::Control> has no descendants.

=head1 DESCRIPTION

This Perl class represents one of the case-control or quote-control
sequences in a quote-like string, That is, things like C<\Q>, C<\E>,
C<\U>, C<\u>, C<\L>, C<\l>, and C<\F>.

=head1 METHODS

This class supports no public methods in addition to those of its
superclass.

=head1 SEE ALSO

L<PPIx::QuoteLike::Token|PPIx::QuoteLike::Token>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
