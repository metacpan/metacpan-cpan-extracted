package Text::HTML::Turndown 0.03;
use 5.020;
use experimental 'signatures';
use stable 'postderef';
use Moo 2;
use XML::LibXML;
use List::Util 'reduce', 'max';
use List::MoreUtils 'first_index';
use Carp 'croak';
use Module::Load 'load';

use Text::HTML::Turndown::Rules;
use Text::HTML::Turndown::Node;
use Text::HTML::CollapseWhitespace 'collapseWhitespace';

=head1 NAME

Text::HTML::Turndown - convert HTML to Markdown

=head1 SYNOPSIS

  use Text::HTML::Turndown;
  my $convert = Text::HTML::Turndown->new();
  my $markdown = $convert->turndown(<<'HTML');
    <h1>Hello world!</h1>
  HTML
  # Hello world!
  # ------------

This is an adapation of the C<turndown> libraries.

=cut

our %COMMONMARK_RULES = (
    paragraph => {
        filter => 'p',
        replacement => sub( $content, $node, $options, $context ) {
            return "\n\n" . $content . "\n\n"
        },
    },

    lineBreak => {
        filter => 'br',

        replacement => sub( $content, $node, $options, $context ) {
          return $options->{br} . "\n"
        }
    },

    heading => {
        filter => ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],

        replacement => sub( $content, $node, $options, $context ) {
            if( $node->nodeName !~ /\AH(\d)\z/i ) {
                croak sprintf "Unknown node name '%s' for heading", $node->nodeName;
            }
            my $hLevel = $1;

            if (($options->{headingStyle} // '') eq 'setext' && $hLevel < 3) {
                my $underline = ($hLevel == 1 ? '=' : '-') x length($content);
                return (
                    "\n\n" . $content . "\n" . $underline . "\n\n"
                )
            } else {
                return "\n\n" . ('#'x $hLevel) . ' ' . $content . "\n\n"
            }
        }
    },

    blockquote => {
        filter => 'blockquote',

        replacement => sub( $content, $node, $options, $context ) {
          $content =~ s/^\n+|\n+$//g;
          $content =~ s/^/> /gm;
          return "\n\n" . $content . "\n\n"
        }
    },


    list => {
        filter => ['ul', 'ol'],

        replacement => sub( $content, $node, $options, $context ) {
            my $parent = $node->parentNode;
            if (uc $parent->nodeName eq 'LI' && $parent->lastChild->isEqual($node->_node)) {
              return "\n" . $content
            } else {
              return "\n\n" . $content . "\n\n"
            }
        }
    },

    listItem => {
      filter => 'li',

        replacement => sub( $content, $node, $options, $context ) {
        $content =~ s/^\n+//;       # remove leading newlines
        $content =~ s/\n+$/\n/;     # replace trailing newlines with just a single one
        $content =~ s/\n/\n    /gm; # indent
        my $prefix = $options->{bulletListMarker} . '   ';
        my $parent = $node->parentNode;
        if (uc $parent->nodeName eq 'OL') {
          my $start = $parent->getAttribute('start');
          my @ch = grep { $_->nodeType == 1 } $parent->childNodes;
          #my @ch = $parent->childNodes;
          my $index = first_index { $_->isEqual($node->_node) } @ch;
          $prefix = ($start ? $start + $index : $index + 1) . '.  '
        }
        return (
          $prefix . $content . ($node->nextSibling && $content !~ /\n$/ ? "\n" : '')
        )
      }
    },

    indentedCodeBlock => {
        filter => sub ($rule, $node, $options) {
            return (
              $options->{codeBlockStyle} eq 'indented' &&
              uc $node->nodeName eq 'PRE' &&
              $node->firstChild &&
              uc $node->firstChild->nodeName eq 'CODE'
            )
        },
        replacement => sub( $content, $node, $options, $context ) {
            return (
                "\n\n    " .
                ($node->firstChild->textContent =~ s/\n/\n    /gr) .
                "\n\n"
            )
        },
    },

    fencedCodeBlock => {
        filter => sub($rule, $node, $options) {
            return (
              $options->{codeBlockStyle} eq 'fenced' &&
              uc $node->nodeName eq 'PRE' &&
              $node->firstChild &&
              uc $node->firstChild->nodeName eq 'CODE'
            )
        },

        replacement => sub( $content, $node, $options, $context ) {
            my $className = $node->firstChild->getAttribute('class') || '';
            (my $language) = ($className =~ /language-(\S+)/);
            $language //= '';
            my $code = $node->firstChild->textContent;

            my $fenceChar = substr( $options->{fence}, 0, 1 );
            my $fenceSize = 3;
            my $fenceInCodeRegex = qr{^${fenceChar}{$fenceSize,}};
            for ($code =~ /($fenceInCodeRegex)/gm) {
                if (length( $_ ) >= $fenceSize) {
                    $fenceSize = length( $_ ) + 1
                }
            }

            my $fence = $fenceChar x $fenceSize;
            return (
              "\n\n" . $fence . $language . "\n" .
              ($code =~ s/\n$//r ) .
              "\n" . $fence . "\n\n"
            )
          }
    },
    horizontalRule => {
      filter => 'hr',

        replacement => sub( $content, $node, $options, $context ) {
        return "\n\n" . $options->{hr} . "\n\n"
      }
    },

    inlineLink => {
        filter => sub ($rule, $node, $options) {
            return (
              $options->{linkStyle} eq 'inlined' &&
              uc $node->nodeName eq 'A' &&
              $node->getAttribute('href')
            )
        },

        replacement => sub( $content, $node, $options, $context ) {
            my $href = $node->getAttribute('href');
            if ($href) { $href =~s/([()])/\\$1/g };
            my $title = cleanAttribute($node->getAttribute('title'));
            if ($title) { $title = ' "' . ( $title =~ s/"/\\"/gr ) . '"'; };
            return "[$content]($href$title)"
        }
    },

    referenceLink => {
        filter => sub ($rule, $node, $options) {
            return (
              $options->{linkStyle} eq 'referenced' &&
              uc $node->nodeName eq 'A' &&
              $node->getAttribute('href')
            )
        },

        replacement => sub( $content, $node, $options, $context ) {
            my $href = $node->getAttribute('href');
            my $title = cleanAttribute($node->getAttribute('title'));
            if ($title) { $title = ' "$title"' };
            my $replacement;
            my $reference;

            if( $options->{linkReferenceStyle} eq 'collapsed' ) {
                $replacement = '[' . $content . '][]';
                $reference = '[' . $content . ']: ' . $href .$title;

            } elsif( $options->{linkReferenceStyle} eq 'shortcut' ) {
                $replacement = '[' . $content . ']';
                $reference = '[' . $content . ']: ' . $href .$title;

            } else {
                my $id = scalar $context->{references}->@* + 1;
                $replacement = '[' . $content . '][' . $id . ']';
                $reference = '[' . $id . ']: ' . $href . $title;
            }

            push $context->{references}->@*, $reference;
            return $replacement
        },

        append => sub ($options, $context) {
            my $references = '';
            if ($context->{references}->@*) {
                $references = "\n\n" . join( "\n", $context->{references}->@* ) . "\n\n";
                $context->{references} = []; # Reset references
            }
            return $references
        }
    },


    emphasis => {
      filter => ['em', 'i'],

        replacement => sub( $content, $node, $options, $context ) {
          if ($content !~ /\S/) { return '' };
          return $options->{emDelimiter} . $content . $options->{emDelimiter}
      }
    },

    strong => {
      filter => ['strong', 'b'],

        replacement => sub( $content, $node, $options, $context ) {
          if ($content !~ /\S/) { return '' };
          return $options->{strongDelimiter} . $content . $options->{strongDelimiter}
      }
    },

    code => {
        filter => sub ($rule, $node, $options) {
            my $hasSiblings = $node->previousSibling || $node->nextSibling;
            my $isCodeBlock = (uc $node->parentNode->nodeName eq 'PRE') && !$hasSiblings;

            return ((uc $node->nodeName eq 'CODE') && !$isCodeBlock)
        },

        replacement => sub( $content, $node, $options, $context ) {
            if (!$content) { return '' };
            $content =~ s/\r?\n|\r/ /g;

            my $extraSpace = $content =~ /^`|^ .*?[^ ].* $|`$/ ? ' ' : '';
            my $delimiter = '`';
            my @matches = $content =~ /`+/gm;
            while (grep { $_ eq $delimiter } @matches) {
                $delimiter .= '`';
            }

            return $delimiter . $extraSpace . $content . $extraSpace . $delimiter;
        }
    },

    image => {
        filter => 'img',

        replacement => sub( $content, $node, $options, $context ) {
          my $alt = cleanAttribute($node->getAttribute('alt'));
          my $src = $node->getAttribute('src') || '';
          my $title = cleanAttribute($node->getAttribute('title'));
          my $titlePart = $title ? ' "' . $title . '"' : '';
          return $src ? "![$alt]($src$titlePart)" : "";
        }
    },
);

has 'rules' => (
    is => 'ro',
    required => 1,
);

has 'options' => (
    is => 'lazy',
    default => sub { {} },
);

has 'html_parser' => (
    is => 'lazy',
    default => sub {
        return XML::LibXML->new();
    },
);

our %defaults = (
    rules => \%COMMONMARK_RULES,
    headingStyle => 'setext',
    hr => '* * *',
    bulletListMarker => '*',
    codeBlockStyle => 'indented',
    fence => '```',
    emDelimiter => '_',
    strongDelimiter => '**',
    linkStyle => 'inlined',
    linkReferenceStyle => 'full',
    br => '  ',
    preformattedCode => undef,
    blankReplacement => sub ($content, $node, $options, $context ) {
      return $node->isBlock ? "\n\n" : ""
    },
    keepReplacement => sub ($content, $node, $options, $context) {
      return $node->isBlock ? "\n\n" . $node->toString . "\n\n" : $node->toString
    },
    defaultReplacement => sub ($content, $node, $options, $context) {
      return $node->isBlock ? "\n\n" . $content . "\n\n" : $content
    }
);

around BUILDARGS => sub( $orig, $class, %args ) {

    my %options;

    for my $k (sort keys %defaults) {
        $options{ $k } = exists $args{ $k } ? delete $args{ $k } : $defaults{ $k };
    };
    $args{ options } = \%options;
    $args{ rules } = Text::HTML::Turndown::Rules->new( options => \%options, rules => $options{ rules } );

    $args{ rules }->preprocess(sub($tree) {
        return collapseWhitespace(
            element => $tree,
            isBlock => \&Text::HTML::Turndown::Node::_isBlock,
            isVoid  => \&Text::HTML::Turndown::Node::_isVoid,
            (isPre   => $options{preformattedCode} ? \&isPreOrCode : undef),
        );
    });

    return $class->$orig(\%args);
};

our @escapes = (
  [qr/\\/, 'q{\\\\\\\\}'],
  [qr/\*/, 'q{\\\\*}'],
  [qr/^-/, 'q{\\\\-}'],
  [qr/^\+ /, 'q{\\\\+ }'],
  [qr/^(=+)/, 'q{\\\\}.$1'],
  [qr/^(#{1,6}) /, 'q{\\\\}.$1.q{ }'],
  [qr/`/, 'q{\\\\`}'],
  [qr/^~~~/, 'q{\\\\~~~}'],
  [qr/\[/, 'q{\\\\[}'],
  [qr/\]/, 'q{\\\\]}'],
  [qr/^>/, 'q{\\\\>}'],
  [qr/_/, 'q{\\\\_}'],
  # Joplin uses this, but I wonder why there are underscores in the source HTML
  # that should not be escaped?!
  #[qr/(^|\p{Punctuation}|\p{Separator}|\p{Symbol})_(\P{Separator})/, '$1.q{\\\\_}.$2'],
  [qr/^(\d+)\. /, '$1.q{\\. }']
);

sub keep( $self, $filter ) {
    $self->rules->keep($filter);
    return $self
}

sub preprocess( $self, $proc ) {
    $self->rules->preprocess($proc);
    return $self
}

sub addRule( $self, $name, $rule ) {
    $self->rules->add( $name, $rule );
    return $self
}

sub escape( $self, $str ) {
    return reduce( sub {
        $a =~ s/$b->[0]/$b->[1]/gee;
        $a
    }, $str, @escapes );
}

sub process( $self, $parentNode, $context ) {
    return reduce( sub {
        my( $output ) = $a;
        my $node = Text::HTML::Turndown::Node->new( _node => $b, options => $self->options );

        my $replacement = '';
        if( $node->nodeType == 3 ) {
            #say sprintf '%s %s', $node->nodeName, ($node->isCode ? '1' : '0');

            $replacement = $node->isCode ? $node->nodeValue : $self->escape($node->nodeValue);

        } elsif( $node->nodeType == 1 ) {
            $replacement = $self->replacementForNode($node, $context);
        }

        return _join( $output, $replacement )
    }, '', $parentNode->childNodes->@* );
}


sub isPreOrCode ($node) {
  return uc($node->nodeName) eq 'PRE' || uc( $node->nodeName ) eq 'CODE'
}

sub turndown( $self, $input ) {
    if( ! ref $input ) {
        if( $input eq '' ) {
            return ''
        }
        $input = $self->html_parser->parse_html_string( $input, { recover => 2, encoding => 'UTF-8' });
    };

    for my $proc ($self->rules->_preprocess->@*) {
        $input = $proc->($input);
    }

    my $context = {
        references => [],
    };
    my $output = $self->process( $input, $context );
    return $self->postProcess( $output, $context );
}

sub postProcess( $self, $output, $context ) {
    $self->rules->forEach(sub($rule) {
        if( ref $rule eq 'HASH' ) {
            my $r = $rule->{append};
            if(    $r
                && ref $r
                && ref $r eq 'CODE' ) {
                    $output = _join( $output, $r->($self->options, $context));
            }
        }
    });

    $output =~ s/^[\t\r\n]+//;
    $output =~ s/[\t\r\n\s]+$//;

    return $output;
}

sub replacementForNode( $self, $node, $context ) {
    my $rule = $self->rules->forNode( $node );
    my $content = $self->process( $node, $context );
    my $whitespace = Text::HTML::Turndown::Node::flankingWhitespace($node, $self->options);

    if( $whitespace->{leading} || $whitespace->{trailing}) {
        $content =~s/^\s+//;
        $content =~s/\s+$//;
    }

    my $res = (
          $whitespace->{leading}
        . $rule->{replacement}->($content, $node, $self->options, $context)
        . $whitespace->{trailing}
    );

    $res
}

sub _join ($output, $replacement) {
  my $s1 = trimTrailingNewlines($output);
  my $s2 = trimLeadingNewlines($replacement);
  my $nls = max(length($output) - length($s1), length($replacement)- length($s2));
  my $separator = substr( "\n\n", 0, $nls);

  return "$s1$separator$s2";
}

sub cleanAttribute( $attribute ) {
  (defined $attribute) ? $attribute =~ s/(\n+\s*)+/\n/gr : ''
}

sub trimLeadingNewlines ($string) {
    $string =~ s/^\n*//r;
}

sub trimTrailingNewlines ($string) {
  # avoid match-at-end regexp bottleneck, see #370
  my $indexEnd = length($string);
  while ($indexEnd > 0 && substr( $string, $indexEnd-1, 1 ) eq "\n") { $indexEnd-- };
  return substr( $string, 0, $indexEnd )
}

sub use( $self, $plugin ) {
    if( ref $plugin and ref $plugin eq 'ARRAY' ) {
        $self->use( $_ ) for $plugin->@*
    } else {
        load $plugin;
        $plugin->install( $self );
    }
}

1;

=head1 MARKDOWN FLAVOURS / FEATURES



=head1 COMPATIBILITY

This port aims to be compatible with the Javascript code and uses the same
test suite. But the original library does not pass its tests and the Joplin
part does not use the original tests.

=over 4

=item Table headers

For Github flavoured markdown, Joplin aims to always force table headers in
markdown. This libary does not (yet).

=back

=head1 SEE ALSO

The original library (unmaintained):

L<https://github.com/mixmark-io/turndown/>

The Joplin library (maintained):

L<https://github.com/laurent22/joplin/tree/dev/packages/turndown>

L<https://github.com/laurent22/joplin/tree/dev/packages/turndown-plugin-gfm>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Text-HTML-Turndown>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Text-HTML-Turndown/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2025- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut
