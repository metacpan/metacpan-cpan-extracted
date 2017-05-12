package Text::XML;
use strict;
use warnings;
use Types;
use Text::Pretty qw(:all !text);
use Exporter;
use base qw/Exporter/;

our $VERSION = '0.1';

sub pptext ($) { Text::Pretty::text(shift) }

our @EXPORT_OK = qw(elem ielem attr text comment cdata);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

newtype Text::XML::Attribute;
newtype Text::XML::Element;
newtype Text::XML::Text;
newtype Text::XML::Comment, sub{ shift !~ qr{-->}   };
newtype Text::XML::CData,   sub{ shift !~ qr{]]>}   };
newtype Text::XML::Name,    sub{ shift =~ qr{^[\w:-]*$} };

uniontype Text::XML::XML, qw(Text::XML::Element
                             Text::XML::Attribute
                             Text::XML::Text
                             Text::XML::Comment
                             Text::XML::CData
                             Text::XML::Name);

# element( name, [element|Text|CData|Comment] )
sub elem (*;$$) { Element( Name(shift), shift() || [], shift() || [] ) }
# inline-element( name, [element|Text|CData|Comment] )
sub ielem (*;$$){ Element( Name(shift), shift() || [], shift() || [], 1 ) }
sub attr   ($$) { Attribute( Name(shift), shift ) }
sub text    ($) { Text(shift)            }
sub comment ($) { Comment(shift)         }
sub cdata   ($) { CData(shift)           }

instance Text::Pretty::Print, Text::XML::XML,
pretty => sub
{ my( $doc, %opts ) = @_
; $opts{encoding} = 'UTF-8' unless defined $opts{encoding}
; $opts{indent}   = 4       unless defined $opts{indent}
; $doc = pretty_proc($doc, $opts{indent})
; $opts{doctype}
? $doc = vcat [ hcat [ pptext '<!DOCTYPE'
                     , (nest 10, hsep [ (map {pptext $_} @{$opts{doctype}}) ])
                     , pptext '>'
                     ]
              , $doc
              ]
: undef
; $opts{prolog}
? $doc = vcat [ hcat [ pptext '<?xml'
                     , (nest 6, hsep [ pretty_proc( attr( version => '1.0' )
                                                  , $opts{indent}         )
                                     , pretty_proc( attr( 'encoding'
                                                        , $opts{encoding} )
                                                  , $opts{indent}          )
                                     ])
                     , pptext '?>'
                     ]
              , $doc
              ]
: undef
; $doc->pretty(%opts)
};

sub pretty_proc ($$)
{ no strict
; my($doc,$i)=@_
; asserttype Text::XML::XML, $doc
; match $doc
=> Text::XML::Name
           => sub{ pptext shift }
=> Text::XML::Element
           => sub{ my( $n, $as, $cs, $inline ) = @_
             ; $inline
             ? hcat [ langle
                    , pretty_proc($n,$i)
                    , ( @$as ? ( space
                               , hsep [map {onel pretty_proc($_,$i)} @$as]
                               )
                            : () )
                    , ( @$cs ? rangle
                             : pptext ' />' )
                    , ( @$cs ? ( nest($i, hcat [(map {pretty_proc($_,$i)} @$cs)
                                               , pptext '</'
                                               , pretty_proc($n,$i)
                                               , rangle
                                               ])
                                )
                            : () )
                    ]
            : vcat [ hcat [ langle
                          , pretty_proc($n,$i)
                          , ( @$as ? ( space
                                     , (nest 2+length $n->[0]
                                           , hsep [map {pretty_proc($_,$i)}
                                                       @$as                 ])
                                     )
                                  : () )
                          , ( @$cs ? rangle
                                   : pptext ' />' )
                          ]
                    , ( @$cs ? ( nest($i, vcat [map {pretty_proc($_,$i)} @$cs])
                                , hcat [ pptext '</'
                                       , pretty_proc($n,$i)
                                       , rangle
                                       ]
                                )
                            : () )
                    ]
                   }
=> Text::XML::Attribute => sub{ my($n,$v) = @_
                   ; defined $v
                        ? do{ $v =~ s{&}{&amp;}gsm
                            ; $v =~ s{"}{&quot;}gsm
                            ; onel hcat [ pretty_proc($n,$i)
                                        , equals
                                        , qquotes pptext $v
                                        ]
                            }
                        : pretty_proc($n,$i)
                   }
=> Text::XML::Text
             => sub{ my $t = shift
                   ; $t =~ s{&}{&amp;}gsm
                   ; $t =~ s{<}{&lt;}gsm
                   ; $t =~ s{>}{&gt;}gsm
                   ; words $t
                   }
=> Text::XML::Comment
             => sub{ hsep [ pptext '<!--'
                          , nest(5, words shift)
                          , pptext '-->'
                          ]
                   }
=> Text::XML::CData
             => sub{ onel hcat [ pptext '<![CDATA['
                               , pptext shift
                               , pptext ']]>'
                               ]
                   }
}

1;

__END__

=head1 NAME

Text::XML - The great new Text::XML!

=head1 VERSION

Version 0.1


=head1 SYNOPSIS

XML combinators and pretty printer.
More documentation is coming.

=head1 EXPORT

elem ielem attr text comment cdata

=head1 AUTHOR

Eugene Grigoriev, C<< <eugene.grigoriev at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-xml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-XML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::XML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-XML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-XML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-XML>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-XML>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Eugene Grigoriev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


