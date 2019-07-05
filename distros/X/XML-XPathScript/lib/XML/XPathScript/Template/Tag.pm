package XML::XPathScript::Template::Tag;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: XPathScript Template Element 
$XML::XPathScript::Template::Tag::VERSION = '2.00';
use strict;
use warnings;

use Carp;
use Scalar::Util qw/ reftype /;

use overload '&{}'  => \&_overload_func,
             q{""}  => \&_overload_quote;

our @ALLOWED_ATTRIBUTES = qw{
  pre post
  intro extro
  prechildren postchildren
  prechild testcode
  showtag
  postchild
  action
  rename
  content contents
};

sub new {
   return bless {}, shift;
}

sub get {
    my $self = shift;
    return wantarray ? map { $self->{$_} } @_
                     : $self->{$_[0]}
                     ;
}

sub set {
	my( $self, $attribute_ref ) = @_;

	for my $key ( keys %{$attribute_ref} ) {
        croak "attribute $key not allowed"
            if ! grep { $key eq $_ } @ALLOWED_ATTRIBUTES;

        $self->{$key} = $attribute_ref->{$key};

        # renaming implies showing the tag
        $self->{showtag} = 1 if $key eq 'rename';
	}

	return;
}

sub _overload_func {
    my $self = shift;
    return sub { $self->set( @_ ) }
}

sub _overload_quote {
    my $self = shift;
    return $self;
    return sub { print $self };
}

'end of XML::XPathScript::Template::Tag';

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XPathScript::Template::Tag - XPathScript Template Element 

=head1 VERSION

version 2.00

=head1 SYNOPSIS

    <%
        $tag->set( 'foo' => { testcode => \&frumble  } );

        sub frumble {
            my( $n, $t ) = @_;

            $t->set({ 'pre' =>  '<bar>' });

            return DO_SELF_AND_CHILDREN();

        }
     %>
     <%= apply_templates() %>

=head1 DESCRIPTION

The XML::XPathScript::Tag class is used to represent tags 
within an XPathScript template. 

=head1 CALLED AS ARGUMENT TO THE TESTCODE FUNCTIONS

Typically, the only time you'll be exposed to those objects is
via the testcode functions, which receive as arguments a reference
to the current node and its associated template entry. 

Note that changing any of the tag's attributes only impacts the current
node and doesn't change the tag entry in the template. To modify the 
template, you'll have to access I<$template> directly.

Example:

    <%
        $template->set( 'foo' => { testcode => \&frumble  } );

        sub frumble {
            my( $n, $t ) = @_;

            if( $n->findvalue( './@bar' ) eq 'whonk' ) {
                # we've been whonk'ed! This foo must
                # blink
                $t->set({ 
                    'pre' => '<blink>', 'post' => '</blink>' 
                });

                # and the next foos will be in italic
                $template->set( foo => { 
                    pre => '<i>', post => '</i>' 
                } );
            }
            return DO_SELF_AND_CHILDREN();
        }
    %>

=head1 METHODS

=head2 new

    $tag = XML::XPathScript::Template::Tag->new

Creates a new, empty tag.

=head2 set

    $t->set( \%attributes )

Updates the tag's attributes with the values given in \%attributes

Thanks to the magic of overloading, using I<$t> as a function 
reference acts as a shortcut to I<set>.

Example:

    $t->set({ pre => '<a>', post => '</a>' });
    # or, equivalently,
    $t->({ pre => '<a>', post => '</a>' });

=head2 get

    @values = $tag->get( @attributes )

Returns the values of @attributes.

Example:

    @values = $tag->get( 'pre', 'post' );

=head1 BACKWARD COMPATIBILITY

As for XML::XPathScript::Template, prior to release 1.0 of XPathScript, 
the tags within the template of a
stylesheet were not objects but simple hash references. Modifications
to the tag attributes were done by manipulating the hash directly.

    <%
        $t->{foo}{testcode} = sub {  
            my( $n, $t ) = @_;

            $t->{pre} = '<a>';
            $t->{post} = '</a>';

            return DO_SELF_AND_CHILDREN;
        };
    %>

Don't tell anyone, but as an XML::XPathScript::Template::Tag is
a blessed hash reference this way of doing things will 
still work. However, direct manipulation of the tag's hash
is deprecated. Instead, it is recommended to use the object's 
access methods.

    <%
        $template->set( foo => { testcode => \&tc_foo } );
        sub tc_foo {  
            my( $n, $t ) = @_;
           
            $t->set({ 
                pre => '<a>', post => '</a>' 
            });
            
            return DO_SELF_AND_CHILDREN;
        };
    %>

=head1 AUTHORS

=over 4

=item *

Yanick Champoux <yanick@cpan.org>

=item *

Dominique Quatravaux <domq@cpan.org>

=item *

Matt Sergeant <matt@sergeant.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2008, 2007 by Matt Sergeant.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
