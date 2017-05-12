use 5.18.0;
use Modern::Perl;
use Moops;

class XML::Simple::Sugar 1.1.1 {
    our $AUTOLOAD;
    use XML::Simple;
    use UNIVERSAL::isa;
    use overload '""' => 'xml_write';

    has 'xml_index' => ( 'is' => 'ro', 'isa' => 'Int', default => 0 );
    has 'xml_node'  => ( 'is' => 'ro', 'isa' => Maybe[Str] );
    has 'xml_xs'    => (
        'is'      => 'rw',
        'isa'     => 'XML::Simple',
        'default' => sub { XML::Simple->new( XMLDecl => '<?xml version="1.0"?>' ); }
    );
    has 'xml_data' => (
        'is'      => 'rw',
        'isa'     => Maybe[HashRef|ArrayRef],
        'default' => method { $self->xml_data ? $self->xml_data : {}; }
    );
    has 'xml_parent' => ( 'is' => 'ro', 'isa' => InstanceOf['XML::Simple::Sugar'] );
    has 'xml_autovivify' => ( 'is' => 'rw', 'isa' => Bool, default => 1 );
    has 'xml' => (
        'is'      => 'rw',
        'isa'     => Str,
        'trigger' => method {
            $self->xml_data(
                XMLin(
                    $self->xml,
                    ForceContent => 1,
                    KeepRoot     => 1,
                    ForceArray   => 1,
                    ContentKey   => 'xml_content',
                )
            );
        }
    );

    method xml_write {
        return $self->xml_root->xml_xs->XMLout(
            $self->xml_root->xml_data,
            KeepRoot   => 1,
            ContentKey => 'xml_content',
        );
    }

    method xml_read (Str $xml) {
        $self->xml_data(
            $self->xml_xs->XMLin(
                $xml,
                ForceContent => 1,
                KeepRoot     => 1,
                ForceArray   => 1,
                ContentKey   => 'xml_content',
            )
        );
        return $self;
    }

    method xml_root {
        if ( defined( $self->xml_parent ) ) {
            return $self->xml_parent->xml_root;
        }
        else {
            return $self;
        }
    }

    multi method xml_attr (HashRef $attr) {
        foreach my $attribute (keys %$attr) {
            if (
                $self->xml_autovivify
                || grep( /^$attribute$/,
                    keys %{
                        $self->xml_parent->xml_data->{ $self->xml_node }
                          ->[ $self->xml_index ]
                    } )
              )
            {
                $self->xml_parent->xml_data->{ $self->xml_node }
                  ->[ $self->xml_index ]->{$attribute} =
                  $attr->{$attribute};
            }
            else {
                die qq|$attribute is not an attribute of | . $self->xml_node;
            }
        }
        return $self;
    }

    multi method xml_attr () {
        my %attr;
        foreach ( keys %{ $self->xml_data } ) {
            $attr{$_} = $self->xml_data->{$_}
              if ( !( UNIVERSAL::isa( $self->xml_data->{$_}, 'ARRAY' ) ) );
        }
        return \%attr;
    }

    method xml_rmattr (Str $attr) {
        delete $self->xml_parent->xml_data->{ $self->xml_node }
          ->[ $self->xml_index ]->{$attr};
        return $self;
    }

    method xml_content (Str $content?) {
        if ($content) {
            $self->xml_data->{xml_content} = $content;
            return $self;
        }
        else {
            $self->xml_data->{xml_content};
        }
    }

    method xml_nest (InstanceOf['XML::Simple::Sugar'] $xs) {
        $self->xml_parent->xml_data->{ $self->xml_node }->[ $self->xml_index ]
          = $xs->xml_data;
        return $self;
    }

    multi method xml_subnode (Str $node, InstanceOf['XML::Simple::Sugar'] $content) {
        $self->xml_data->{$node}->[ $self->xml_index ] = $content->xml_data;
    }

    multi method xml_subnode (Str $node, HashRef $content) {
        foreach my $attribute (keys %$content) {
            if ( UNIVERSAL::isa( $self->xml_data->{$node}, 'ARRAY' ) ) {
                if (
                    $self->xml_autovivify
                    || grep( /^$attribute$/,
                        keys %{
                            $self->xml_data->{$node}->[ $self->xml_index ]
                        } )
                  )
                {
                    $self->xml_data->{$node}->[ $self->xml_index ]
                      ->{$attribute} = $content->{$attribute};
                }
                else {
                    die qq|$attribute is not an attribute of $node|;
                }
            }
            else {
                if (
                    $self->xml_autovivify
                    || grep( /^$attribute$/,
                        keys %{ $self->xml_data->{$node} } )
                  )
                {
                    $self->xml_data->{$node}->{$attribute} =
                      { 'value' => $content->{$attribute} };
                }
                else {
                    die qq|$attribute is not an attribute of $node|;
                }
            }
        }
        return $self;
    }

    multi method xml_subnode (Str $node, ArrayRef $content) {
        if ( $content->[0] =~ m/^[0-9]+$/ )
        {
            if ( $self->xml_autovivify ) {
                unless ( $self->xml_data->{$node} ) {
                    $self->xml_data->{$node} = [];
                }
                unless (
                    UNIVERSAL::isa(
                        $self->xml_data->{$node}->[ $content->[0] ], 'HASH'
                    )
                  )
                {
                    $self->xml_data->{$node}->[ $content->[0] ] = {};
                }
            }
            else {
                unless ( $self->xml_data->{$node} ) {
                    die qq|$node is not a subnode of |
                      . $self->xml_parent->xml_node;
                }
                unless (
                    UNIVERSAL::isa(
                        $self->xml_data->{$node}->[ $content->[0] ], 'HASH'
                    )
                  )
                {
                    die qq|$content->[0] is not a subnode of |
                      . $self->xml_node;
                }
            }
            my $xs = XML::Simple::Sugar->new(
                {
                    xml_node => $node,
                    xml_data => $self->xml_data->{$node}->[ $content->[0] ],
                    xml_parent     => $self,
                    xml_autovivify => $self->xml_autovivify,
                    xml_index      => $content->[0]
                }
            );
            if ( defined( $content->[1] )
                && UNIVERSAL::isa( $content->[1], 'XML::Simple::Sugar' ) )
            {
                $xs->xml_nest( $content->[1] );
            }
            elsif ( defined( $content->[1] ) ) {
                $xs->xml_content( $content->[1] );
            }
            if ( defined( $content->[2] )
                && UNIVERSAL::isa( $content->[2], 'HASH' ) )
            {
                $xs->xml_attr( $content->[2] );
            }
            return $xs;
        }
        elsif ( $content->[0] =~ m/^all$/i )
        {
            if ( UNIVERSAL::isa( $self->xml_data->{$node}, 'ARRAY' ) ) {
                return map {
                    XML::Simple::Sugar->new(
                        {
                            xml_node   => $node,
                            xml_data   => $self->xml_data->{$node}->[$_],
                            xml_parent => $self,
                            xml_autovivify => $self->xml_autovivify,
                            xml_index      => $_
                        }
                    );
                } 0 .. scalar @{ $self->xml_data->{$node} } - 1;
            }
        }
        return;
    }
    
    multi method xml_subnode (Str $node, Str $content) {
        $self->xml_data->{$node}->[0]->{xml_content} = $content;
        return $self;
    }

    multi method xml_subnode (Str $node) {
        unless ( $self->xml_data->{$node} ) {
            if ( $self->xml_autovivify == 1 ) {
                $self->xml_data->{$node}->[0] = {};
            }
            else {
                die qq|$node is not a subnode of |
                  . $self->xml_node;
            }
        }

        if ( UNIVERSAL::isa( $self->xml_data->{$node}, 'ARRAY' ) ) {
            return XML::Simple::Sugar->new(
                {
                    xml_node       => $node,
                    xml_data       => $self->xml_data->{$node}->[0],
                    xml_parent     => $self,
                    xml_autovivify => $self->xml_autovivify,
                    xml_index      => $self->xml_index
                }
            );
        }
        else {
            return XML::Simple::Sugar->new(
                {
                    xml_node       => $node,
                    xml_data       => $self->xml_data->{$node},
                    xml_parent     => $self,
                    xml_autovivify => $self->xml_autovivify,
                    xml_index      => $self->xml_index
                }
            );
        }
    }

    method AUTOLOAD ($content?) {
        my ( $node ) = $AUTOLOAD =~ m/.*::(.+)$/;
        return if $node eq 'DESTROY';
        $content ? $self->xml_subnode($node, $content) : $self->xml_subnode($node);
    }
}

1;

# ABSTRACT: Sugar sprinkled on XML::Simple
# PODNAME: XML::Simple::Sugar

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Simple::Sugar - Sugar sprinkled on XML::Simple

=head1 VERSION

version v1.1.1

=head1 SYNOPSIS

    use Modern::Perl;
    use XML::Simple::Sugar;
    
    my $xs = XML::Simple::Sugar->new;
    
    # Autovivify some XML elements
    my $person = $xs->company->departments->department->person;
    
    # Set some content and attributes
    $person->first_name('John')
           ->last_name('Smith')
           ->email('jsmith@example.com')
           ->salary(60000);
    
    $person->xml_attr( { position => 'Engineer' } );
    
    say $xs->xml_write; 
    
    # <?xml version="1.0"?>
    # <company>
    #   <departments>
    #     <department>
    #       <person position="Engineer">
    #         <email>jsmith@example.com</email>
    #         <first_name>John</first_name>
    #         <last_name>Smith</last_name>
    #         <salary>60000</salary>
    #       </person>
    #     </department>
    #   </departments>
    # </company>

=head1 DESCRIPTION

This module is a wrapper around L<XML::Simple> to provide AUTOLOADed accessors to XML nodes in a given XML document.  All nodes of the XML document are XML::Simple::Sugar objects having the following attributes and methods.

=head1 ATTRIBUTES

=head2 xml (XML Str)

This readonly attribute is for use during instantiation (XML::Simple::Sugar->new({ xml => $xml_string })).  See also L</xml_read>.

=head2 xml_autovivify (Bool DEFAULT true)

This attribute determines on a per element basis whether new attributes or elements may be introduced.  Child elements inherit this setting from their parent.  Setting autovivify to false is useful when working with templates with a strict predefined XML structure. This attribute is true by default.

    my $xs = XML::Simple::Sugar->new(
      {
        xml => qq(
            <strict_document>
              <foo>bar</foo>
            </strict_document>
        ),
        xml_autovivify => 0,
      }
    );

    $xs->strict_document->foo('baz'); # Changes bar to baz.  Ok!
    $xs->strict_document->biz('a new element'); # Error!  Biz doesn't exist!

=head2 xml_data (XML::Simple compliant Perl representation of an XML document)

This is the Perl representation of the XML.  This is ugly to work with directly (hence this module), but in lieu of methods yet unwritten there may be a use case for having direct access to this structure.

=head2 xml_index

The index number of an element in a collection

=head2 xml_node

The name of the current node

=head2 xml_parent

The parent XML::Simple::Sugar object to the current element

=head2 xml_xs

This is underlying XML::Simple object.  If you need to adjust the XML declaration, you can do that by passing an an XML::Simple object with your preferred options to the C<new> constructor.  Be wary of setting other XML::Simple options as this module will happily overwrite anything that conflicts with its assumptions.

=head2 xml_root

Returns the root element XML::Simple::Sugar object

=head1 METHODS

=head2 xml_read (XML Str)

Parses an XML string and sets the data attribute

=head2 xml_write

Writes out an XML string

=head2 xml_content (Str)

Gets or sets the content of the element

    $xs->person->first_name->xml_content('Bob');

    # Which can be implicitly written
    $xs->person->first_name('Bob');

    # Or using [ index, content, attributes ] notation
    $xs->person->first_name([ 0, 'Bob', undef ]);

    say $xs->person->first_name->xml_content;
    # Bob

=head2 xml_attr (HashRef)

Gets or sets the attributes of the element.

    $xs->person->xml_attr( { position => 'Accountant' } );

    # Which can be implicitly written as...
    $xs->person( { position => 'Accountant' } );

    # Or using [ index, content, attributes ] notation
    $xs->person([ 0, undef, { position => 'Accountant' } ]);

    my $attributes = $xs->person->xml_attr;
    say $attributes->{'position'};
    # Accountant

=head2 xml_rmattr (Str)

This method removes the passed scalar argument from the element's list of attributes.

=head2 xml_nest (XML::Simple::Sugar)

Merges another XML::Simple::Sugar object as a child of the current node.

    my $first_name = XML::Simple::Sugar->new({ xml => '<first_name>Bob</first_name>' });
    $xs->person->xml_nest( $first_name );

    # Or using [ index, content, attributes ] notation
    $xs->person( [ 0, $first_name, undef ] );

=head1 Collections

When working with a collection of same-named elements, you can access a specific element by index by passing the collection's name an ArrayRef with the index number.  For example:

    my $person2 = $xs->people->person([1]); # Returns the second person element (index 1)

You can also work with the entire collection of individual elements by passing an ArrayRef with the string 'all'.

    my @people = $xs->people->person(['all']); # Returns an array of XML::Simple::Sugar objects

=head1 Using [ index, content, attributes ] Notation

When authoring even simple XML documents, using [ index, content, attributes ] notation allows you to implicitly invoke L</xml_content>, L</xml_attr>, and L</xml_nest> methods on nodes deep within a collection.  For example:

    # Sets the position attribute of the second person
    $xs->people->person([ 1, undef, { position => 'Engineer' } ]);

    # Sets the third person's second favorite color to orange
    # with a neon attribute
    $xs->people->person([ 2 ])->favorite_colors->color([ 1, 'orange', { neon => 1 } ]);

    # Composing large documents from smaller ones
    my $xs  = XML::Simple::Sugar->new( {
        xml_xs => XML::Simple->new( XMLDecl => '<!DOCTYPE html>' )
    } );
    my $xs2 = XML::Simple::Sugar->new;

    $xs2->table->tr->th([ 0, 'First Name', { style => 'text-align:left' } ]);
    $xs2->table->tr->th([ 1, 'Last Name' ]);

    $xs->html->body->div([0])->h1('Page Title');
    $xs->html->body->div([ 1, $xs2 ]);

    say $xs->xml_write;

    # <!DOCTYPE html>
    # <html>
    #   <body>
    #     <div>
    #       <h1>Page Title</h1>
    #     </div>
    #     <div>
    #       <table>
    #         <tr>
    #           <th style="text-align:left">First Name</th>
    #           <th>Last Name</th>
    #         </tr>
    #       </table>
    #     </div>
    #   </body>
    # </html>

=head1 PLEASE BE ADVISED

Most of the automagic happens with AUTOLOAD.  Accessors/mutators and method names in this package cannot be used as element names in the XML document.  XML naming rules prohibit the use of elements starting with the string "xml", so "xml_" is used as a prefix for all accessors/mutators/methods to avoid potential document conflicts.

=head1 REPOSITORY

L<https://github.com/Camspi/XML-Simple-Sugar>

=head1 MINIMUM PERL VERSION SUPPORTED

Perl 5.18.2 or later is required by this module.  Lesser Perl versions struggle with deep recursion.  Patches welcome.

=head1 VERSIONING

Semantic versioning is adopted by this module. See L<http://semver.org/>.

=head1 SEE ALSO

=over 4

=item 
* L<XML::Simple>

=back

=head1 CREDITS

=over 4

=item 
* Jonathan Cast for excellent critique.

=item 
* Kyle Bolton for peeking over my shoulder and giving me pro tips.

=item 
* eMortgage Logic, LLC., for allowing me to publish this module to CPAN

=back

=head1 AUTHOR

Chris Tijerina

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by eMortgage Logic LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
