package Text::TOC::Types::Internal;
{
  $Text::TOC::Types::Internal::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Types -declare => [
    qw(
        Filter
        Node
        )
];

use MooseX::Types::Moose qw( CodeRef );

role_type Filter, { role => 'Text::TOC::Role::Filter' };

coerce Filter,
    from CodeRef,
    via { Text::TOC::Filter::Anon->new( code => $_ ) };

role_type Node, { role => 'Text::TOC::Role::Node' };

1;

# ABSTRACT: Defines types specific to Text::TOC


__END__
=pod

=head1 NAME

Text::TOC::Types::Internal - Defines types specific to Text::TOC

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This class defines several types used internally in Text::TOC.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

