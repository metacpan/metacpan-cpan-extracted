package Text::HTML::Turndown::Node 0.10;
use 5.020;
use Moo;
use experimental 'signatures';
use stable 'postderef';

our @blockElements = (
  'ADDRESS', 'ARTICLE', 'ASIDE', 'AUDIO', 'BLOCKQUOTE', 'BODY', 'CANVAS',
  'CENTER', 'DD', 'DIR', 'DIV', 'DL', 'DT', 'FIELDSET', 'FIGCAPTION', 'FIGURE',
  'FOOTER', 'FORM', 'FRAMESET', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'HEADER',
  'HGROUP', 'HR', 'HTML', 'ISINDEX', 'LI', 'MAIN', 'MENU', 'NAV', 'NOFRAMES',
  'NOSCRIPT', 'OL', 'OUTPUT', 'P', 'PRE', 'SECTION', 'TABLE', 'TBODY', 'TD',
  'TFOOT', 'TH', 'THEAD', 'TR', 'UL'
);
our %blockElements = map { $_ => 1, lc $_ => 1 } @blockElements;

sub _isBlock ($self) {
  $blockElements{ $self->nodeName }
};

our @voidElements = (
  'AREA', 'BASE', 'BR', 'COL', 'COMMAND', 'EMBED', 'HR', 'IMG', 'INPUT',
  'KEYGEN', 'LINK', 'META', 'PARAM', 'SOURCE', 'TRACK', 'WBR'
);
our %voidElements = map { $_ => 1, lc $_ => 1 } @voidElements;


has '_node' => (
    is => 'ro',
    required => 1,
    handles => [qw[
        parentNode
        firstChild
        previousSibling
        nextSibling
        childNodes
        lastChild
        nodeName
        nodeValue
        nodeType
        textContent
        getAttribute
        isEqual

        toString

        find
    ]],
);

sub _isVoid( $self ) {
    $voidElements{ $self->nodeName }
}

sub _hasVoid( $self ) {
    return _has($self, \%voidElements)
}

has ['isVoid', 'hasVoid', 'isBlock', 'isMeaningfulWhenBlank', 'hasMeaningfulWhenBlank',
     'isCode'] => (
    is => 'ro',
    required => 1,
);

sub className( $self ) {
    $self->getAttribute('class');
}

sub _isCode( $self ) {
    return 1 if uc $self->nodeName eq 'CODE';
    my $p = $self->parentNode;
    if( $p and $p->can('nodeName')) {
        return _isCode($self->parentNode)
    };
}

our @meaningfulWhenBlankElements = (
  'A', 'TABLE', 'THEAD', 'TBODY', 'TFOOT', 'TH', 'TD', 'IFRAME', 'SCRIPT',
  'AUDIO', 'VIDEO'
);
our %meaningfulWhenBlankElements = map { $_ => 1, lc $_ => 1 } @meaningfulWhenBlankElements;

sub _isMeaningfulWhenBlank( $self ) {
    $meaningfulWhenBlankElements{ $self->nodeName }
}

sub _hasMeaningfulWhenBlank( $self ) {
    _has( $self, \%meaningfulWhenBlankElements )
}

sub _has( $self, $nodeNames ) {
    return if ! $self->can('getElementsByTagName');
    for my $tag (sort keys $nodeNames->%*) {
        return 1 if $self->getElementsByTagName($tag)
    }
}

sub firstNonBlankChild( $self ) {
    return ([$self->_node->nonBlankChildNodes]->[0]);
}

sub isBlank( $self ) {
       !$self->isVoid
    && !$self->isMeaningfulWhenBlank
    && $self->textContent =~ /^\s*$/
    && !$self->hasVoid
    && !$self->hasMeaningfulWhenBlank()
}

around BUILDARGS => sub( $orig, $class, %args ) {
    my $node = $args{ _node };
    if( ! exists $args{ isVoid } ) {
        $args{ isVoid } = _isVoid( $node );
    };
    if( ! exists $args{ hasVoid } ) {
        $args{ hasVoid } = _hasVoid( $node );
    };
    if( ! exists $args{ isMeaningfulWhenBlank } ) {
        $args{ isMeaningfulWhenBlank } = _isMeaningfulWhenBlank( $node );
    };
    if( ! exists $args{ hasMeaningfulWhenBlank } ) {
        $args{ hasMeaningfulWhenBlank } = _hasMeaningfulWhenBlank( $node );
    };
    if( ! exists $args{ isCode } ) {
        $args{ isCode } = _isCode( $node );
    };
    if( ! exists $args{ isBlock } ) {
        $args{ isBlock } = _isBlock( $node );
    };

    return $class->$orig(\%args);
};


sub flankingWhitespace( $node, $options ) {
    if( _isBlock($node) || ($options->{ preformattedCode } && isCode($node) )) {
        return { leading => '', trailing => '' };
    }

    my $edges = edgeWhitespace( $node->textContent );

    # abandon leading ASCII WS if left-flanked by ASCII WS
    if ($edges->{leadingAscii} && isFlankedByWhitespace('left', $node, $options)) {
        $edges->{leading} = $edges->{leadingNonAscii};
    }

    # abandon trailing ASCII WS if right-flanked by ASCII WS
    if ($edges->{trailingAscii} && isFlankedByWhitespace('right', $node, $options)) {
      $edges->{trailing} = $edges->{trailingNonAscii}
    }

    return { leading => $edges->{leading}, trailing => $edges->{trailing}, }
}


sub edgeWhitespace ($string) {
    $string =~ /^(([ \t\r\n]*)(\s*))(?:(?=\S)[\s\S]*\S)?((\s*?)([ \t\r\n]*))$/;
    return {
        leading          => $1, # whole string for whitespace-only strings
        leadingAscii     => $2,
        leadingNonAscii  => $3,
        trailing         => $4, # empty for whitespace-only strings
        trailingNonAscii => $5,
        trailingAscii    => $6,
    }
}

sub isFlankedByWhitespace( $side, $node, $options) {
    my $sibling;
    my $regExp;
    my $isFlanked;

    if ($side eq 'left') {
        $sibling = $node->previousSibling;
        $regExp = qr/ $/;
    } else {
        $sibling = $node->nextSibling;
        $regExp = qr/^ /;
    }

    if ($sibling) {
        if ($sibling->nodeType == 3) {
            $isFlanked = $sibling->nodeValue =~ /$regExp/;
        } elsif ($options->{preformattedCode} && $sibling->nodeName eq 'CODE') {
            $isFlanked = undef;
        } elsif ($sibling->nodeType == 1 && !_isBlock($sibling)) {
            $isFlanked = $sibling->textContent =~ /$regExp/;
        }
    }
    return $isFlanked
}

1;
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
