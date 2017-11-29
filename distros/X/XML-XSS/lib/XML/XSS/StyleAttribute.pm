package XML::XSS::StyleAttribute;
our $AUTHORITY = 'cpan:YANICK';
$XML::XSS::StyleAttribute::VERSION = '0.3.5';
# ABSTRACT: Style attribute for XML::XSS stylesheet rule


use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Clone;

with 'MooseX::Clone';

use Scalar::Util qw/ refaddr /;

no warnings qw/ uninitialized /;


use overload
  'bool' => sub { $_[0]->value },
  '""'   => sub { $_[0]->value },
  '+'    => sub { $_[0]->value + $_[1] },
  '0+'   => sub { $_[0]->value },
  '*='   => sub { $_[0]->set_value( $_[1] ) },
  'x='   => sub { $_[0]->set_value( XML::XSS::xsst( $_[1] ) ) },
  '='    => sub { shift },
  'eq'   => sub {
    my ( $a, $b ) = @_;
    return( ref($a) eq ref($b) and refaddr($a) == refaddr($b) );
  };


has 'value' => (
    is        => 'rw',
    clearer   => 'clear_value',
    predicate => 'has_value',
    traits    => [qw/ Clone /],
);

after 'set_value' => sub {
    my $self = shift;

    $self->clear_value unless defined $self->value;
};

#sub clone {
#    return XML::XSS::StyleAttribute->new(
#        value => $_[0]->value
#    );
#}

sub render {
    my ( $self, $r, $node, $args ) = @_;

    return unless $self->has_value;

    my $value = $self->value;

    return ref $value ? $value->( $r, $node, $args ) : $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XSS::StyleAttribute - Style attribute for XML::XSS stylesheet rule

=head1 VERSION

version 0.3.5

=head1 SYNOPSIS

    use XML::XSS;

    my $xss = XML::XSS->new;
    my $attribute = $xss->get('chapter')->pre;

    $attribute->set_value( '<div class="chapter">' );

=head1 DESCRIPTION

The C<XML::XSS::StyleAttribute> objects are the building blocks 
of the document transformation.  They can be assigned a string,
which is inserted verbatim in the rendered document

    $xss->get('chapter')->set_pre( '<div class="chapter">' );

or a sub reference, which return value is inserted in the rendered document

    $xss->get('clock')->set_pre( sub { return "date and time are: " .  localtime } );

Upon execution, the sub references will be passed three parameters: the invoking rule, 
the L<XML::LibXML::Node> object currently rendered and the arguments ref given
to C<render()>.

    $xss->set( 'div' => {
        intro => sub {
            my ( $self, $node, $args ) = @_;
            my @para = $node->findnodes( '@para' );
            return "<p>node has " . @para . " para child nodes.</p>";
        }
    } );

=head1 OVERLOADING

=head2 *=

Assigns the right value to the attribue.

    $xss.'chapter'.'pre' *= "<div class='chapter'>";

is equivalent to

    $xss->set( chapter => { pre => "<div class='chapter'>" } );

=head2 x= 

Similar to '*=', but considers the right side as a template and converts it
via C<xsst>.

    $xss.'chapter'.'pre' x= q{
        <div class="chapter">
            <% $r->stylesheet->stash{chapter_nbr}++ %>
    };

is equivalent to

    $xss->set( 'chapter' => { pre => xsst( <<'END_TEMPLATE' ) } );
        <div class="chapter">
            <% $r->stylesheet->stash{chapter_nbr}++ %>
    END_TEMPLATE

=head1 ATTRIBUTES

=head2 value

The string or sub reference used by the style attribute.

    # long way
    $xss->get('chapter')->pre->set_value( '<div class="chapter">' );

    # short way
    $xss->set( chapter => { pre => '<div class="chapter">' } );

    # shortest way
    $xss.'chapter'.'pre' *= '<div class="chapter">';

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2011, 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
