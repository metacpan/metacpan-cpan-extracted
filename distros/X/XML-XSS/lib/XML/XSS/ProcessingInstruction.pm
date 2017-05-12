package XML::XSS::ProcessingInstruction;
BEGIN {
  $XML::XSS::ProcessingInstruction::AUTHORITY = 'cpan:YANICK';
}
{
  $XML::XSS::ProcessingInstruction::VERSION = '0.3.4';
}
# ABSTRACT: XML::XSS processing instruction stylesheet rule

use 5.10.0;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Clone;

with 'XML::XSS::Role::Renderer', 'MooseX::Clone';

has [ qw/ pre post process / ] =>(
    traits => [ qw/ XML::XSS::Role::StyleAttribute Clone / ] 
);

no warnings qw/ uninitialized /;

sub apply {
    my ( $self, $node, $args ) = @_;
    $args ||= {};

    return if $self->has_process and !$self->_render( 'process', $node,
        $args);

    my $output;
    $output .= $self->_render( 'pre', $node, $args );
    $output .= $node->toString;
    $output .= $self->_render( 'post', $node, $args );

    return $output;
}

1;

__END__

=pod

=head1 NAME

XML::XSS::ProcessingInstruction - XML::XSS processing instruction stylesheet rule

=head1 VERSION

version 0.3.4

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
