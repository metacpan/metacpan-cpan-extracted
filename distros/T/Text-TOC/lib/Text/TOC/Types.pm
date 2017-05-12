package Text::TOC::Types;
{
  $Text::TOC::Types::VERSION = '0.10';
}

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        Text::TOC::Types::Internal
        MooseX::Types::Moose
        MooseX::Types::Path::Class
        )
);

require Text::TOC::Filter::Anon;

1;

# ABSTRACT: Provides types for use in Text::TOC


__END__
=pod

=head1 NAME

Text::TOC::Types - Provides types for use in Text::TOC

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This class exports the types from L<Text::TOC::Types::Internal>,
L<MooseX::Types::Moose> , and L<MooseX::Types::Path::Class>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

