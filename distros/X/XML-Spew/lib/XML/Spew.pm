package XML::Spew;

use warnings;
use strict;

our $VERSION = '0.02';

use Carp;

sub _new { 
    my $class = shift;

    return bless { stack => [ ] }, ref( $class ) || $class;
}

sub _tags { 
    my $class = shift;

    croak "_tags must be passed at least one argument" unless @_;
    my @tags = @_;

    foreach my $tag( @tags ) {
        # install methods
        { 
            no strict 'refs';
            *{ $class . '::'       . $tag } = $class->__m_meth( $tag );
            *{ $class . '::start_' . $tag } = $class->__s_meth( $tag );
            *{ $class . '::end_'   . $tag } = $class->__e_meth( $tag );
        }
    }
}

# returns a coderef for the main tag method
sub __m_meth { 
    my $class = shift;
    my $tag = shift;

    return sub { 
        my $self = shift;
        my $r = '<' . $tag;
        
        # check for attributes
        if( ref( $_[0] ) eq 'HASH' ) { 
            $r .= $self->__attributes( shift );
        }
        
        # check if we have an arrayref to distribute over
        if( ref( $_[0] ) eq 'ARRAY' ) { 
            $r .= '>';
            my $e = '</' . $tag . '>';
            return map { $r . $_ . $e } @{ $_[0] };
        }

        # check if we have child data
        if( @_ ) { 
            $r .= '>' . join '', @_;
            $r .= '</' . $tag . '>';
        } else { 
            $r .= ' />';
        }
        
        return $r;
    };
} 

# returns a coderef for the start tag method
sub __s_meth { 
    my $class = shift;
    my $tag = shift;

    return sub { 
        my $self = shift;
        my $r = '<' . $tag;

        # push this tag onto the tag stack
        push @{ $self->{stack} }, $tag;

        # check for attributes
        if( ref( $_[0] ) eq 'HASH' ) { 
            $r .= $self->__attributes( shift );
        }

        # check for erroneous data
        if( @_ ) { 
            carp "Ignoring extra arguments to start_$tag(). You might want $tag().";
        }

        $r .= '>';

        return $r;
    };
}

# returns a coderef for the end tag method
sub __e_meth { 
    my $class = shift;
    my $tag = shift;

    return sub { 
        my $self = shift;
        
        # fatal error if this tag is not on top of the stack
        my $top = $self->{stack}[-1];
        unless( $top eq $tag ) { 
            croak "Invalid nesting: can not close <$tag> while <$top> still open";
        }

        # pop this tag off the stack and close it
        pop @{ $self->{stack} };

        return '</' . $tag . '>';
    };
}


sub __attributes { 
    my $self = shift;
    my $attr_ref = shift;

    my $r;
    while( my( $k, $v ) = each %$attr_ref ) { 
        $r .= " $k=\"$v\"";
    }

    return $r;
}

1;

__END__


=head1 NAME

XML::Spew - Spew small chunks of XML

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package My::Spew;

    use base 'XML::Spew';

    __PACKAGE__->_tags(qw/foo bar baz narf poit/);


    package main;

    my $spew = My::Spew->_new;

    print $spew->foo( $spew->bar( { id => 1 } ), 
                      $spew->bar( { id => 2 }, $spew->baz( "Hi-diddly-ho, neighborino." ) ) );


=head1 DESCRIPTION

Sometimes you just need to quickly output a small chunk of XML and you don't need
a big DOM API or XML framework. At the same time, you don't want to assemble tedious
C<print> statements or HERE-docs. You can subclass XML::Spew to create objects for easily
generating well-formed XML element trees with a minimum of fuss. Spew does not guarantee
document validity; you must take care to properly encode any special characters and ensure
that your tags make sense.

=head1 INTERFACE

XML::Spew is a base class. To make any use of it, you will need to write a subclass.
An example class, L<XML::Spew::XHTML|XML::Spew::XHTML>, is included in this distribution.

First, declare your package and make it a subclass of XML::Spew.

    package What::Ever;
    use base 'XML::Spew';

Your subclass will inherrit a number of class methods which will be used to
auto-magically create the instance methods for your XML spewing needs. In order to 
avoid collisions with the names of XML tags, all the built-in XML::Spew methods
begin with an underscore ('_'). 

To set up your tags, call the C<_tags> method:

    __PACKAGE__->_tags( qw/foo bar baz narf poit/ );

That's it! You can now use your class to spew out chunks of XML.

    my $spew = What::Ever->_new;
    print $spew->start_foo;
    print $spew->bar( $spew->baz( { id => 1 }, "some text\n" ),
                      $spew->baz( { id => 2 }, "some other text\n" ) );
    print $spew->end_foo;

This produces the output:

    <foo><bar><baz id="1">some text
    </baz><baz id="2">some other text
    </baz></bar></foo>

Each tag that you configure with the C<_tags> method actually gets three
methods made, the "main" method, whose name is identical to the tag, the
"start" method (C<start_$tag>) and the "end" method (C<end_$tag>). Spew
keeps track of calls to start and end methods in an internal stack to ensure
proper nesting of elements. The following generates a fatal error:

    print $spew->start_foo, $spew->start_bar, $spew->end_foo;

In this case, the C<< <bar> >> tag was not closed before the C<< <foo> >> tag.

A tag's main method always guarantees proper closure. If no child data is 
passed, it will generate a self-closing tag. 

    print $spew->foo;              # prints '<foo />'

If child data is passed, it will generate a tag pair around it. 

    print $spew->foo( "blah" );    # prints '<foo>blah</foo>'

If the first parameter to a main or start method is a hashref, the keys 
and values of the hashref will be used as attributes for the tag. 

    print $spew->foo( { id => 1, a => "q" } );   # prints <foo id="1" a="q" />
    print $spew->foo( { id => 2 }, "blah" );     # prints <foo id="2">blah</foo>

Attribute hashrefs can also be passed to start methods. 

If the child consists of an arrayref, the tag will be "distributed" over each
element in the array. Any attributes will also be distributed.

    print $spew->foo( { quux => 42 }, [qw/red green blue/] );

    # prints:
    # <foo quux="42">red</foo><foo quux="42">green</foo><foo quux="42">blue</foo>

    print $spew->bar( [qw/tom dick harry/] );

    # prints:
    # <bar>tom</bar><bar>dick</bar><bar>harry</bar>

For tags to be distributed, the first child data item must be the arrayref. 
(Meaning either the first argument or the first argument after the attribute
hashref.) Any child data after the arrayref will be ignored.

=head1 CAVEATS

XML::Spew is designed to be quick and dirty. It is not a substitute for a full
XML framework if you need to construct large, complex XML documents. Spew is 
for when you need to spew small chunks of XML quickly.

The functional nature of the main method interface and the internal tag stack
will do its best to guarantee that your XML chunk is well-formed. Spew does not
do any checking to ensure that a given tag is allowed inside another, nor does
it inspect child data for things that need encoding or escaping. 


=head1 THANKS

Thanks to Lincoln Stein for inspiring the interface with his ubiquitous L<CGI|CGI>
module.

=head1 AUTHOR

Mike Friedman, C<< <friedo@friedo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-spew@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Spew>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mike Friedman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
