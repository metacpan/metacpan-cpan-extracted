package Text::Pretty;
use strict;
use warnings;
use Types;
use Exporter;
use base qw/Exporter/;

our $VERSION = '0.1.0';

our %EXPORT_TAGS = (
    prims  => [qw(empty text space endl nest indent hcat onel)            ]
  , simple => [qw(semi comma colon dot equals quote bquote qquote
                  lparen rparen lbrack rbrack lbrace rbrace langle rangle)]
  , struct => [qw(parents brackets braces quotes qquotes bquotes)         ]
);

$EXPORT_TAGS{combinators} = [ @{$EXPORT_TAGS{prims}}
                            , qw(vcat hsep punctuate surround)
                            ];

our @EXPORT_OK = ( qw(is_empty words)
                 , @{$EXPORT_TAGS{combinators}}
                 , @{$EXPORT_TAGS{simple}}
                 , @{$EXPORT_TAGS{struct}}
                 );

$EXPORT_TAGS{all} = \@EXPORT_OK;

# document types
newtype Text::Pretty::Empty;
newtype Text::Pretty::Text;
newtype Text::Pretty::Space;
newtype Text::Pretty::Endl;
newtype Text::Pretty::Nest;
newtype Text::Pretty::HCat;
newtype Text::Pretty::Onel;

uniontype Text::Pretty::Doc, qw(Text::Pretty::Empty
                                Text::Pretty::Text
                                Text::Pretty::Space
                                Text::Pretty::Endl
                                Text::Pretty::Nest
                                Text::Pretty::HCat
                                Text::Pretty::Onel);

typeclass Text::Pretty::Print,
    pretty => undef;

# rendering method
# returns a string of the rendered document
#   - document to render
#   - options: document width and indent
instance Text::Pretty::Print, Text::Pretty::Doc,
    pretty => sub { my( $doc, %opts ) = @_
                  ; my $w = $opts{width}  || 80
                  ; my $ls = render_proc($doc,0,$w,[''])
                  ; join qq{\n}, @$ls
                  };

# primitive documents
sub empty ()   { Empty()           }
sub text  ($)  { Text(shift)       }
sub space ()   { Space()           }
sub endl  ()   { Endl()            }
sub nest  ($$) { Nest(shift,shift) }
sub hcat  ($)  { HCat(shift)       }
sub onel  ($)  { Onel(shift)       }

# document predicates
sub is_empty ($) { shift->isa('Empty') }

# simple documents
sub semi   () { text ';'  }
sub comma  () { text ','  }
sub colon  () { text ':'  }
sub dot    () { text '.'  }
sub equals () { text '='  }
sub quote  () { text q{'} }
sub bquote () { text q{`} }
sub qquote () { text q{"} }
sub lparen () { text '('  }
sub rparen () { text ')'  }
sub lbrack () { text '['  }
sub rbrack () { text ']'  }
sub lbrace () { text '{'  }
sub rbrace () { text '}'  }
sub langle () { text '<'  }
sub rangle () { text '>'  }

# generic document combinators
sub punctuate ($$) { my($p,$l)=@_;
                     hcat [do{ my @r = map {$_,$p} @{$l}; pop @r; @r} ] }
sub surround ($$$) { my($a,$v,$b)=@_; my $l = length $a->pretty;
                     hcat [ $a, (nest $l, hcat [$v, $b]) ] }

# derived document combinators
sub vcat     ($) { punctuate endl,  [grep {not is_empty $_} @{shift()}]  }
sub hsep     ($) { punctuate space, [grep {not is_empty $_} @{shift()}]  }
sub parents  ($) { surround lparen,     shift(), rparen }
sub brackets ($) { surround lbrack,     shift(), rbrack }
sub braces   ($) { surround lbrace,     shift(), rbrace }
sub quotes   ($) { surround quote,      shift(), quote  }
sub qquotes  ($) { surround qquote,     shift(), qquote }
sub bquotes  ($) { surround text q{``}, shift(), text q{''} }
sub words    ($) { my $s = shift
                 ; hcat [ hsep [map {text $_} split qr{\s+}, $s]
                        , $s =~ /\s$/sm
                        ? space
                        : () ]  }

sub render_proc
{ no strict
; my( $doc, $i, $w, $ls ) = @_
; asserttype Text::Pretty::Doc, $doc
; match $doc
=> Text::Pretty::Text
         => sub{ my $s = shift
               ; length($ls->[$#{$ls}])+length($s) >= $w
              && length($ls->[$#{$ls}]) != $i
               ? do{ my $l = (q{ }x$i).$s
                   ; push @$ls, $l
                   }
               : do{ my $l = pop @$ls
                   ; $l .= (q{ }x($i - length $l)) . $s
                   ; push @$ls, $l
                   }
               ; $ls
               }
=> Text::Pretty::Space
         => sub{ length($ls->[$#{$ls}]) >= $w
               ? push @$ls, q{ }x$i
               : do{ my $l = pop @$ls
                   ; $l .= q{ }
                   ; push @$ls, $l
                   }
               ; $ls
               }
=> Text::Pretty::Endl
         => sub{ push @$ls, q{ }x$i
               ; $ls
               }
=> Text::Pretty::HCat
         => sub{ $ls = render_proc($_,$i,$w,$ls) for @{shift()}
               ; $ls
               }
=> Text::Pretty::Nest
         => sub{ render_proc(pop, $i + shift, $w, $ls) }
=> Text::Pretty::Onel
         => sub{ my $e = text render_proc(shift, 0, 1_000_000, [''])->[0]
               ; render_proc($e, $i, $w, $ls)
               }
=> Text::Pretty::Empty
         => sub{ $ls }
}

1;

=head1 NAME

Text::Pretty - The great new Text::Pretty!

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

A generic pretty printing combinators.
More documentation is coming soon.

=head1 EXPORT

empty text space endl nest indent hcat onel
semi comma colon dot equals quote bquote qquote
lparen rparen lbrack rbrack lbrace rbrace langle rangle
parents brackets braces quotes qquotes bquotes
vcat hsep punctuate surround is_empty words

=head1 AUTHOR

Eugene Grigoriev, C<< <eugene.grigoriev at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-pretty at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Pretty>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Pretty


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Pretty>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Pretty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Pretty>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Pretty>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Eugene Grigoriev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


