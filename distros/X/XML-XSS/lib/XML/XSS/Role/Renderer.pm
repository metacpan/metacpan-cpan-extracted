package XML::XSS::Role::Renderer;
BEGIN {
  $XML::XSS::Role::Renderer::AUTHORITY = 'cpan:YANICK';
}
{
  $XML::XSS::Role::Renderer::VERSION = '0.3.4';
}
# ABSTRACT: XML::XSS role for rendering rule

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Scalar::Util qw/ refaddr /;

has stylesheet => (
    isa      => 'XML::XSS',
    weak_ref => 1,
    is       => 'ro',
    required => 1,
    handles  => [qw/ render stash /],
);

has _within_apply => ( is => 'rw', );

has is_detached => (
    is      => 'rw',
    default => 0,
);

requires 'apply';

sub detach_from_stylesheet {
    my $self = shift;

    $self->stylesheet->detach($self) unless $self->is_detached;
}

before apply => sub {
    $_[0]->_set_within_apply(1);
};

after apply => sub {
    $_[0]->_set_within_apply(0);
};

sub set {
    my ( $self, %attrs ) = @_;

    while ( my ( $k, $v ) = each %attrs ) {
        my $setter = "set_$k";
        $self->$setter($v);
    }
}

sub _render {
    my ( $self, $attr, $node, $args ) = @_;

    return $self->$attr->render( $self, $node, $args );
}


# http://use.perl.org/~tokuhirom/journal/36582
__PACKAGE__->meta->add_package_symbol( '&()' => sub { } );    # dummy
__PACKAGE__->meta->add_package_symbol( '&(""' => sub { shift->stringify } );
__PACKAGE__->meta->add_package_symbol( '&(%=' => sub { shift->_assign_attrs(shift) } );
__PACKAGE__->meta->add_package_symbol( '&(.' => sub { shift->_concat_overload(shift) } );
__PACKAGE__->meta->add_package_symbol( '&(bool' => sub { 1 } );
__PACKAGE__->meta->add_package_symbol( '&(eq' => sub { shift->_equal_overload(shift) } );
__PACKAGE__->meta->add_package_symbol( '&(==' => sub { shift->_equal_overload(shift) } );
#__PACKAGE__->meta->add_package_symbol( '&(<<=' => sub { shift->_assign_content(shift) } );
__PACKAGE__->meta->add_package_symbol( '&(=' => sub { shift } );


sub stringify {
    my $self = shift;
    return 'XML::XSS::Element::' . refaddr $self;
}

sub _assign_content {
    $_[0]->set_content( $_[1] );
    $_[0];
}

sub _assign_content_xsst {
    $_[0]->set_content( XML::XSS::xsst( $_[1] ) );
    $_[0];
}

sub _assign_attrs {
    my ( $self, $attrs ) = @_;
    for ( keys %$attrs ) {
        my $m = "set_$_";
        $self->$m( $attrs->{$_} );
    }
    $self;
}

sub _equal_overload {
    my ( $a, $b ) = @_;

    return refaddr($a) == refaddr($b);
}

sub _concat_overload {
    my ( $self, $attr ) = @_;

    return $self if $attr eq 'style';

    return $self->$attr;
}



sub style_attributes {
    my $self = shift;

    return 
        sort
        map { $_->name }
        grep { 'XML::XSS::Role::StyleAttribute' ~~ @{ $_->applied_traits } }
        grep { $_->has_applied_traits }
        map { $self->meta->get_attribute( $_ ) }
        $self->meta->get_attribute_list
}

sub style_attribute_hash {
    my $self = shift;
    my %opt = @_;

    my %hash;

    for my $attr ( $self->style_attributes ) {
        next unless $opt{all} or $self->$attr->has_value;
        $hash{$attr} = $self->$attr->value;
    }

    return %hash;
   
}

1;

__END__

=pod

=head1 NAME

XML::XSS::Role::Renderer - XML::XSS role for rendering rule

=head1 VERSION

version 0.3.4

=head1 OVERLOADING

=head2 Concatenation (.)

Shortcut to get the style attributes.

    my $pre = $xss.'chapter'.'pre';

is equivalent to 

    my $pre = $xss->get('chapter')->pre;

In addition of the usual style attributes, the special keyword 'style' can
also be used, which returns the object itself. Which is useful to use the 
other overloaded operators, which don't work without it. :-(

    # will work
    $xss.'chapter'.'style' %= {
        pre  => '<div class="chapter">',
        post => '</div>',
    };

    # will work too
    my $chapter = $xss.'chapter';
    $chapter %= {
        pre  => '<div class="chapter">',
        post => '</div>',
    };

    # won't work!
    $xss.'chapter' %= {
        pre  => '<div class="chapter">',
        post => '</div>',
    };

=head2 %=

Assigns a set of style attributes.

    $xss.'chapter'.'style' %= {
        pre  => '<div class="chapter">',
        post => '</div>',
    };

is equivalent to

    $xss->set( chapter => {
        pre  => '<div class="chapter">',
        post => '</div>',
    } );

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
