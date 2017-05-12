package Text::XHTML;
use strict;
use warnings;
use Types;
use Text::XML qw(:all);
use Carp;
use Exporter;
use base qw/Exporter/;

our $VERSION = '0.1';

our %EXPORT_TAGS = (
elements => [qw(abbr acronym address anchor area bdo big blockquote body bold
                button br caption cite col colgroup ddef define del dlist dterm
                emphasize fieldset form h1 h2 h3 h4 h5 h6 head hr image input
                ins italics keyboard label legend li meta noscript object olist
                optgroup option paragraph param pre quote sample script select
                small strong thestyle subscript superscript table tbody td
                textarea tfoot th thead thebase code div html span thetitle
                trow tt ulist variable)],
attributes => [qw(action align alt altcode archive base border bordercolor
                  cellpadding checked codebase cols colspan content coords
                  disabled enctype height href httpequiv identifier ismap lang
                  maxlength method multiple name nohref rel rev rows rowspan
                  rules selected shape size src class afor style type title
                  usemap valign value width)]
);

our @EXPORT_OK = ( qw(text comment attr cdata)
                 , @{$EXPORT_TAGS{elements}}
                 , @{$EXPORT_TAGS{attributes}}
                 );

$EXPORT_TAGS{all} = \@EXPORT_OK;

our $CHECKS = 1;

our %CTXT =
( 'Text::XHTML::CtxText'
        => { _text => 1 }
, 'Text::XHTML::CtxHead'
        => {map {$_=>1} qw(base link meta title stype script)}
, 'Text::XHTML::CtxOption'
        => {map {$_=>1} qw(option optgroup)}
, 'Text::XHTML::CtxDList'
        => {map {$_=>1} qw(dt dd)}
, 'Text::XHTML::CtxList'
        => { li => 1 }
, 'Text::XHTML::CtxTable'
        => {map {$_=>1} qw(caption col colgroup thead tfoot tbody tr)}
, 'Text::XHTML::CtxBlock'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl fieldset
                           form h1 h2 h3 h4 h5 h6 hr ol p pre table ul script)}
, 'Text::XHTML::CtxForm'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl fieldset
                           form h1 h2 h3 h4 h5 h6 hr ol p pre table ul script
                           fieldset)}
, 'Text::XHTML::CtxMap'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl fieldset
                           form h1 h2 h3 h4 h5 h6 hr ol p pre table ul script
                           map)}
, 'Text::XHTML::CtxInline'
        => {map {$_=>1} qw(ins del noscript abbr acronym a bdo big b button
                           br cite dfn em img input i kbd label legend object
                           q sample select small strong sub sup
                           textarea code span tt var _text)}
, 'Text::XHTML::CtxAnchor'
        => {map {$_=>1} qw(ins del noscript abbr acronym bdo big b button
                           br cite dfn em img input i kbd label legend object
                           q sample select small strong sub sup
                           textarea code span tt var _text)}
, 'Text::XHTML::CtxInlineBlock'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl fieldset
                           form h1 h2 h3 h4 h5 h6 hr ol p pre table ul script
                           abbr acronym a bdo big b button
                           br cite dfn em img input i kbd label legend object
                           q sample select small strong sub sup
                           textarea code span tt var _text)}
, 'Text::XHTML::CtxFieldSet'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl fieldset
                           form h1 h2 h3 h4 h5 h6 hr ol p pre table ul script
                           abbr acronym a bdo big b button
                           br cite dfn em img input i kbd label legend object
                           q sample select small strong sub sup
                           textarea code span tt var _text legend)}
, 'Text::XHTML::CtxObject'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl fieldset
                           form h1 h2 h3 h4 h5 h6 hr ol p pre table ul script
                           abbr acronym a bdo big b button
                           br cite dfn em img input i kbd label legend object
                           q sample select small strong sub sup
                           textarea code span tt var _text object)}
, 'Text::XHTML::CtxButton'
        => {map {$_=>1} qw(ins del noscript address blockquote div dl
                           h1 h2 h3 h4 h5 h6 hr ol p pre table ul script
                           abbr acronym a bdo big b
                           br cite dfn em img i kbd legend object
                           q sample small strong sub sup
                           code span tt var _text)}
);

newtype Text::XHTML::HTML;

# Element context
newtype Text::XHTML::CtxHead;
newtype Text::XHTML::CtxBlock;
newtype Text::XHTML::CtxInline;
newtype Text::XHTML::CtxInlineBlock;
newtype Text::XHTML::CtxOption;
newtype Text::XHTML::CtxDList;
newtype Text::XHTML::CtxList;
newtype Text::XHTML::CtxForm;
newtype Text::XHTML::CtxFieldSet;
newtype Text::XHTML::CtxTable;
newtype Text::XHTML::CtxMap;
newtype Text::XHTML::CtxObject;
newtype Text::XHTML::CtxAnchor;
newtype Text::XHTML::CtxButton;
newtype Text::XHTML::CtxText;

uniontype Text::XHTML::Inline, qw(Text::XHTML::CtxInline
                                  Text::XHTML::CtxText
                                  Text::XHTML::CtxAnchor);

instance Text::Pretty::Print, Text::XHTML::HTML,
    pretty => sub { my( $doc, %opts ) = @_
                  ; ($doc) = @{$doc}
                  ; $opts{prolog} = 1
                  ; $opts{doctype} =
                      [ q{html}
                      , q{PUBLIC}
                      , q{"-//W3C//DTD XHTML 1.0 Strict//EN"}
                      , q{"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"}
                      ]
                  ; $doc->pretty(%opts) };

sub el (*$$) { my( $e, $c, $ctx ) = @_
; my( $a, $o )
; $CHECKS
? do{ assertlisttype Text::XML::XML, $c
    ; ( $a, $o ) = separatetype Text::XML::Attribute, $c
    ; for my $b (@$o) { $b->isa('Text::XML::Element')
                      ? exists $CTXT{ref($ctx)}->{$b->[0]->[0]}
                      ? next
                      : confess q{Element <}.$b->[0]->[0]
                               .q{> cannot be in a }.ref($ctx).' context'
                      : $b->isa('Text::XML::Text')
                      ? exists $CTXT{ref($ctx)}->{'_text'}
                      ? next
                      : confess q{Text cannot be in a }.ref($ctx).' context'
                      : next
                      }
    }
: do {( $a, $o ) = separatetype Text::XML::Attribute, $c}
; $ctx->isa('Text::XHTML::Inline')
? ielem $e, $a, $o
: elem $e, $a, $o
}

sub ele (*;$) { my( $e, $c ) = @_
; assertlisttype Text::XML::Attribute, $c if $CHECKS
; elem $e, $c, []
}

# root element
sub html      ($$$) { my($a,$h,$b)=@_
                    ; assertlisttype Text::XML::Attribute, $a if $CHECKS
                    ; confess 'No Head element' unless $h->[0]->[0] eq 'head'
                    ; confess 'No Body element' unless $b->[0]->[0] eq 'body'
                    ; unshift @$a, attr xmlns => 'http://www.w3.org/1999/xhtml'
                    ; HTML(elem html, $a, [$h,$b])   }

# root children elements
sub head        ($) { el  head,       shift, CtxHead()  }
sub body        ($) { el  body,       shift, CtxBlock() }

###############################################################################
# header elements
# takes a string
sub thebase     ($) { elem base, [attr href => shift], [] }
# takes an attribute listref
sub thelink     ($) { ele 'link',     shift               }
# takes an attribute listref
sub meta        ($) { ele meta,       shift               }
# takes an attribute listref, element can have 'lang' and 'dir' attributes.
sub thetitle    ($) { el  title,      shift, CtxText()    }
sub thestyle    ($) { el  style,      shift, CtxText()    }
sub script      ($) { el  script,     shift, CtxText()    }

###############################################################################
# block and inline elements
sub del         ($) { el  del,        shift, CtxInlineBlock() }
sub ins         ($) { el  ins,        shift, CtxInlineBlock() }
sub noscript    ($) { el  noscript,   shift, CtxBlock()       }

###############################################################################
# block elements
sub address     ($) { el  address,    shift, CtxInline()      }
sub blockquote  ($) { el  blockquote, shift, CtxBlock()       }
sub div         ($) { el  div,        shift, CtxInlineBlock() }
sub dlist       ($) { el  dl,         shift, CtxDList()       }
sub fieldset    ($) { el  fieldset,   shift, CtxFieldSet()    }
sub form        ($) { el  form,       shift, CtxForm()        }
sub h1          ($) { el  h1,         shift, CtxInline()      }
sub h2          ($) { el  h2,         shift, CtxInline()      }
sub h3          ($) { el  h3,         shift, CtxInline()      }
sub h4          ($) { el  h4,         shift, CtxInline()      }
sub h5          ($) { el  h5,         shift, CtxInline()      }
sub h6          ($) { el  h6,         shift, CtxInline()      }
sub hr         (;$) { ele hr,         shift                   }
sub olist       ($) { el  ol,         shift, CtxList()        }
sub paragraph   ($) { el  p,          shift, CtxInline()      }
sub pre         ($) { el  pre,        shift, CtxInline()      } # care
sub table       ($) { el  table,      shift, CtxTable()       } # care
sub ulist       ($) { el  ul,         shift, CtxList()        }

###############################################################################
# inline elements
sub abbr        ($) { el  abbr,       shift, CtxInline()      }
sub acronym     ($) { el  acronym,    shift, CtxInline()      }
sub anchor      ($) { el  a,          shift, CtxAnchor()      } # care
sub bdo         ($) { el  bdo,        shift, CtxInline()      }
sub big         ($) { el  big,        shift, CtxInline()      }
sub bold        ($) { el  b,          shift, CtxInline()      }
sub button      ($) { el  button,     shift, CtxButton()      }
sub br         (;$) { ele br,         shift                   }
sub cite        ($) { el  cite,       shift, CtxInline()      }
sub code        ($) { el  code,       shift, CtxInline()      }
sub define      ($) { el  dfn,        shift, CtxInline()      }
sub emphasize   ($) { el  em,         shift, CtxInline()      }
sub image       ($) { ele img,        shift                   }
sub input       ($) { ele input,      shift                   }
sub italics     ($) { el  i,          shift, CtxInline()      }
sub keyboard    ($) { el  kbd,        shift, CtxInline()      }
sub label       ($) { el  label,      shift, CtxInline()      }
sub object      ($) { el  object,     shift, CtxObject()      }
sub quote       ($) { el  'q',        shift, CtxInline()      }
sub sample      ($) { el  sample,     shift, CtxInline()      }
sub select      ($) { el  'select',   shift, CtxOption()      }
sub small       ($) { el  small,      shift, CtxInline()      }
sub strong      ($) { el  strong,     shift, CtxInline()      }
sub subscript   ($) { el  'sub',      shift, CtxInline()      }
sub superscript ($) { el  sup,        shift, CtxInline()      }
sub textarea    ($) { el  textarea,   shift, CtxText()        }
sub themap      ($) { el  'map',      shift, CtxMap()         }
sub span        ($) { el  span,       shift, CtxInline()      }
sub tt          ($) { el  tt,         shift, CtxInline()      }
sub variable    ($) { el  var,        shift, CtxInline()      }

###############################################################################
# table elements
sub caption     ($) { el  caption,    shift, CtxInline() }
sub col         ($) { el  col,        shift, CtxInline() }
sub colgroup    ($) { el  colgroup,   shift, CtxInline() }
sub tbody       ($) { el  tbody,      shift, CtxInline() }
sub td          ($) { el  td,         shift, CtxInline() }
sub tfoot       ($) { el  tfoot,      shift, CtxInline() }
sub th          ($) { el  th,         shift, CtxInline() }
sub thead       ($) { el  thead,      shift, CtxInline() }
sub trow        ($) { el  'tr',       shift, CtxInline() }

###############################################################################
# list elements
sub li          ($) { el  li,         shift, CtxInlineBlock() }
sub dterm       ($) { el  dt,         shift, CtxInline()      }
sub ddef        ($) { el  dd,         shift, CtxInlineBlock() }

###############################################################################
# form menu options elements
sub optgroup    ($) { el  optgroup,   shift, CtxInline() }
sub option      ($) { el  option,     shift, CtxInline() }

###############################################################################
# other elements
sub area        ($) { ele area,       shift              }
sub legend      ($) { el  legend,     shift, CtxInline() }
sub param       ($) { ele param,      shift              }

###############################################################################
# attributes
sub action      ($) { attr action       => shift }
sub align       ($) { attr align        => shift }
sub alt         ($) { attr alt          => shift }
sub altcode     ($) { attr altcode      => shift }
sub archive     ($) { attr archive      => shift }
sub base        ($) { attr base         => shift }
sub border      ($) { attr border       => shift }
sub bordercolor ($) { attr bordercolor  => shift }
sub cellpadding ($) { attr cellpadding  => shift }
sub checked      () { attr checked      => 'true'}
sub codebase    ($) { attr codebase     => shift }
sub cols        ($) { attr cols         => shift }
sub colspan     ($) { attr colspan      => shift }
sub content     ($) { attr content      => shift }
sub coords      ($) { attr coords       => shift }
sub disabled     () { attr disabled     => 'true'}
sub enctype     ($) { attr enctype      => shift }
sub height      ($) { attr height       => shift }
sub href        ($) { attr href         => shift }
sub httpequiv   ($) { attr 'http-equiv' => shift }
sub identifier  ($) { attr id           => shift }
sub ismap        () { attr action       => 'true'}
sub lang        ($) { my $l=shift; attr(lang=>$l), attr('xml:lang',$l) }
sub maxlength   ($) { attr maxlength    => shift }
sub method      ($) { attr method       => shift }
sub multiple     () { attr multiple     => 'true'}
sub name        ($) { attr name         => shift }
sub nohref       () { attr nohref       => 'true'}
sub rel         ($) { attr rel          => shift }
sub rev         ($) { attr rev          => shift }
sub rows        ($) { attr rows         => shift }
sub rowspan     ($) { attr rowspan      => shift }
sub rules       ($) { attr rules        => shift }
sub selected     () { attr selected     => 'true'}
sub shape       ($) { attr shape        => shift }
sub size        ($) { attr size         => shift }
sub src         ($) { attr src          => shift }
sub class       ($) { attr class        => shift }
sub afor        ($) { attr 'for'        => shift }
sub style       ($) { attr style        => shift }
sub type        ($) { attr type         => shift }
sub title       ($) { attr title        => shift }
sub usemap      ($) { attr usemap       => shift }
sub valign      ($) { attr valign       => shift }
sub value       ($) { attr value        => shift }
sub width       ($) { attr width        => shift }

1;

__END__

=head1 NAME

Text::XHTML - The great new Text::XHTML!

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

XHTML combinators and pretty printer.
More documentation coming soon.

=head1 EXPORT

abbr acronym address anchor area bdo big blockquote body bold
button br caption cite col colgroup ddef define del dlist dterm
emphasize fieldset form h1 h2 h3 h4 h5 h6 head hr image input
ins italics keyboard label legend li meta noscript object olist
optgroup option paragraph param pre quote sample script select
small strong thestyle subscript superscript table tbody td
textarea tfoot th thead thebase code div html span thetitle
trow tt ulist variable
action align alt altcode archive base border bordercolor
cellpadding checked codebase cols colspan content coords
disabled enctype height href httpequiv identifier ismap lang
maxlength method multiple name nohref rel rev rows rowspan
rules selected shape size src class afor style type title
usemap valign value width
text comment attr cdata

=head1 AUTHOR

Eugene Grigoriev, C<< <eugene.grigoriev at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-xhtml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-XHTML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::XHTML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-XHTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-XHTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-XHTML>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-XHTML>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Eugene Grigoriev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

