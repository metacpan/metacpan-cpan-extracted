package Text::TWikiFormat::SAX;
use base 'XML::SAX::Base';

$VERSION = '0.03';

use strict;
use XML::SAX::DocumentLocator;

sub new {
    my ($class, %params) = @_;
    my $self = $class->SUPER::new(%params);

    $self->{_onlink} = $params{onlink};
    return $self;
}

sub _parse_bytestream {
    my ($self, $fh) = @_;
    my $parser = TWiki::SAX::Parser->new($self->{_onlink});
    $parser->set_parent($self);
    local $/;
    my $text = <$fh>;
    $parser->parse($text);
}

sub _parse_characterstream {
    my ($self, $fh) = @_;
    die "parse_characterstream not supported";
}

sub _parse_string {
    my ($self, $str) = @_;
    my $parser = TWiki::SAX::Parser->new($self->{_onlink});
    $parser->set_parent($self);
    $parser->parse($str);
}

sub _parse_systemid {
    my ($self, $sysid) = @_;
    my $parser = TWiki::SAX::Parser->new($self->{_onlink});
    $parser->set_parent($self);
    open(FILE, $sysid) || die "Can't open $sysid: $!";
    local $/;
    my $text = <FILE>;
    $parser->parse($text);
}


package TWiki::SAX::Parser;
use XML::SAX::Writer;
use HTML::Parser;
use strict;
use vars qw(@ENDING_WITH_EOL @AUTO_CLOSED $p $s $e $f $LAST_HTML_TAG);

@ENDING_WITH_EOL = qw(h1 h2 h3 h4 h5 h6 li);
@AUTO_CLOSED = qw(nop br hr);

$b = qr/.*?(?:\n|\A)/s;              # beginning of line

$p = qr/.*?[ \(]|\A/s;               # prefix, wikitags start with,
$f = qr/[\s\,\.\;\:\!\?\)]|\Z/;      # finalizer, wikitags end with

$s = qr/[#\[\%\<\&\?A-Za-z0-9]/;                # start, words start with
$e = qr/.*?[A-Za-z0-9\:\]\%\>\;\?]/s;            # end, words end with

sub new {
    my ($class, $onlink) = @_;
    my $self = bless { _onlink => $onlink }, $class;
    $self->{html_parser} = HTML::Parser->new(
                                api_version => 3,
                                start_h => [\&_html_tag, "self, tagname, attr, text"],
                                end_h   => [\&_html_tag, "self, tagname, text"],
                                marked_sections => 1,
                                            );
    return $self;
}

sub _html_tag {
    my $parser = shift;
    $LAST_HTML_TAG = [@_];
    $parser->eof();
}

sub set_parent {
    my $self = shift;
    $self->{parent} = shift;
}

sub parent {
    my $self = shift;
    return $self->{parent};
}

sub parse {
    my $self = shift;

    my $sysid = $self->parent->{ParserOptions}->{Source}{SystemId};
    $self->parent->set_document_locator(
         XML::SAX::DocumentLocator->new(
            sub { "" },
            sub { $sysid },
            sub { $self->{line_number} },
            sub { 0 },
        ),
    );
    $self->parent->start_document({});
    $self->parent->start_element(_element('wiki'));

    $self->parse_wiki(shift);

    $self->parent->end_element(_element('wiki', 1));
    $self->parent->end_document({});
}

sub _open_element {
    my($self, $element) = @_;
    $self->parent->start_element(UNIVERSAL::isa($element, 'HASH') ? $element : _element($element));
    push @{ $self->{stack} }, UNIVERSAL::isa($element, 'HASH') ? $element->{Name} : $element;
}

sub _close_element {
    my($self, $element) = @_;

    if (!$element) {
        my $exists;
        foreach my $ewe (@ENDING_WITH_EOL) { $exists += grep { $_ eq $ewe } @{ $self->{stack} } }
        return unless $exists;
    }

    while(@{ $self->{stack} }) {
        my $s_element = pop @{ $self->{stack} };
        $self->parent->end_element(_element($s_element), 1);

        if ($element) {
            return 1 if ($s_element eq $element);
        } elsif (grep {$s_element eq $_} @ENDING_WITH_EOL) {
            return 1;
        }
    }
}

sub _open_list {
    my($self, $ident, $type) = @_;
    my $element = _get_list_element($type);

    my $prev_ident = $self->{list}->[-1]->[0] || 0;
    my $prev_element = $self->{list}->[-1]->[1] || '';

    if ($ident == $prev_ident) {
        if ($element ne $prev_element) {
            if ($prev_element) {
                $self->_close_element($prev_element);
                pop @{ $self->{list} };
            }
            $self->_open_element($element);
            push @{ $self->{list} }, [$ident, $element];
        }
    }
    # opening new <*l>
    elsif ($ident > $prev_ident) {
        $self->_open_element($element);
        push @{ $self->{list} }, [$ident, $element];
    }
    #
    elsif ($ident < $prev_ident) {
        while ($ident < $prev_ident) {
            $self->_close_element($prev_element);
            pop @{ $self->{list} };
            $self->_open_list($ident, _get_list_type($element));
            $prev_ident = $self->{list}->[-1]->[0] || 0;
            $prev_element = $self->{list}->[-1]->[1] || '';
        } ;
    }
}

sub _close_list {
    my $self = shift;

    # getting first occurence of 'ul', 'ol'
    my $pos = 0;
    foreach (0..@{$self->{stack}}) {
        if ($self->{stack}->[$_] && $self->{stack}->[$_] =~ /^[ou]l$/) {
            $pos = $_;
            last ;
        }
    }

    my $result;
    while(@{ $self->{stack} } > $pos) {
        my $s_element = pop @{ $self->{stack} };
        pop @{ $self->{list} } if ($s_element eq $self->{list}->[-1]->[1]);
        $self->parent->end_element(_element($s_element), 1);
        $result++;
    }
    return $result;
}

sub _get_list_element {
    my ($type) = @_;
    return ('ul') if $type eq '*';
    return ('ol') if $type =~ /^\w+$/;
    die sprintf "unknow list element : \'%s\'", $type;
}

sub _get_list_type {
    my ($element) = @_;
    return ('*') if $element eq 'ul';
    return ('1') if $element eq 'ol';
    die sprintf "unknow list element : \'%s\'", $element;
}

sub _handle_found {
    my ($self, $pre, $post, $element, $type) = @_;

    $self->format_text($pre);
    my @elements = (UNIVERSAL::isa($element, 'ARRAY'))  ? @$element : ($element);
    foreach (@elements) {
        if ($type eq 'open') {
            $self->_open_element($_);
        } else {
            $self->_close_element($_);
        }
    }
    $self->format_text($post);
}

sub parse_wiki {
    my $self = shift;

    $self->{stack}    = [];
    $self->{list}     = [[]];
    $self->{in_table} = 0;
    $self->{'in_tr'}  = 0;
    $self->{in_td}    = 0;
    $self->{parse_wiki} = 1;
    $self->{parse_html} = 1;

    my ($text) = @_;
    $text =~ s/\r//g;    # Remove \r
    $text =~ s/\\\n//g;  # Join lines ending in "\"

    $self->format_text($text);
    $self->_close_element('__default');
}

sub format_text {
    my($self, $text) = @_;

if ($text) {
    # <verbatim>
    if ($text =~ s/(.*?)<verbatim>//s) {
        $self->format_text($1);
        $self->_open_element('pre');
        $self->{parse_wiki} = 0;
        $self->{parse_html} = 0;
        $self->format_text($text);
    }
    # <pre>
    elsif ($self->{parse_html} && $text =~ s/(.*?)<pre>//s) {
        $self->format_text($1);
        $self->_open_element('pre');
        $self->{parse_wiki} = 0;
        $self->format_text($text);
    }
    # horizontal line
    elsif ($self->{parse_wiki} && $text =~ s/($b)-{3,}(\s)/$2/s) {
        $self->format_text($1);
        $self->parent->start_element(_element('hr'));
        $self->parent->end_element(_element('hr'), 1);
        $self->format_text($text);
    }

    # openening tags
    # <li>
    elsif ($self->{parse_wiki} && $text =~ s/($b)(\t+| {3,})(\*|\w)[\.\) ]+([^\n]+)//s) {
        my($f1, $f2, $f3, $f4, $f5) = ($1,$2,$3,$4,$5);
        $self->format_text($f1);
        $self->_open_list(length($f2), $f3);
        $self->_open_element('li');
        $self->format_text($f4);

        if ($text !~ /^\n(\t+| {3,})(\*|\w+)[\.\) ]/) {
            $self->_close_list();
            $text =~ s/^\n//;
        }

        $self->format_text($text);
    }
    # table handling
    elsif ($self->{parse_wiki} && $text =~ s/($b)\|([^\n\|]+)(\|+)/\|/s) {
        my($cell, $finalizer) = ($2,$3);
        $self->format_text($1);

        unless ($self->{in_table}) {
            my $el = _element('table');
            $self->_open_element($el);
            $self->{in_table} = 1;
        }

        unless ($self->{'in_tr'}) {
            $self->_open_element('tr');
            $self->{'in_tr'} = 1;
        }

        my $el = _element('td');
        _add_attrib($el, 'colspan', length($finalizer)) if (length($finalizer) > 1);

        # aligning text inside cell
        $cell =~ /^(\s*).*?(\s*)$/;
        my $l1 = length( $1 || '' );
        my $l2 = length( $2 || '' );
        if( $l1 >= 2 ) {
            if( $l2 <= 1 ) {
                _add_attrib($el, 'align', 'right');
            } else {
                _add_attrib($el, 'align', 'center');
            }
        }
        $self->_open_element($el);
        $self->format_text($cell);
        $self->_close_element('td');
        if ($self->{'in_tr'} && $text =~ s/^\|\n//) {
            $self->{'in_tr'} = 0;
            $self->_close_element('tr');
            if ($self->{'in_table'} && $text !~ /^\|/) {
                $self->{'in_table'} = 0;
                $self->_close_element('table');
            }
        }
        $self->format_text($text);
    }
    # openening tags
    # <h1>..<hN>
    # handles pre, post
    elsif ($self->{parse_wiki} && $text =~ s/($b)---(\+{1,6})\s*//s) {
        $self->_handle_found($1, $text, 'h'.length($2), 'open');
    }
    # <strong>
    elsif ($self->{parse_wiki} && $text =~ s/($p)\*($s)/$2/s) {
        $self->_handle_found($1, $text, 'strong', 'open');
    }
    # <em>
    elsif ($self->{parse_wiki} && $text =~ s/($p)\_($s)/$2/s) {
        $self->_handle_found($1, $text, 'em', 'open');
    }
    # <strong><em>
    elsif ($self->{parse_wiki} && $text =~ s/($p)\_\_($s)/$2/s) {
        $self->_handle_found($1, $text, ['strong', 'em'], 'open');
    }
    # <code>
    elsif ($self->{parse_wiki} && $text =~ s/($p)\=($s)/$2/s) {
        $self->_handle_found($1, $text, 'code', 'open');
    }
    # <strong><code>
    elsif ($self->{parse_wiki} && $text =~ s/($p)\=\=($s)/$2/s) {
        $self->_handle_found($1, $text, ['strong', 'code'], 'open');
    }
    # <a>
    elsif ($self->{parse_wiki} && $text =~ s/(.*)\[\[([^\]]+)\](?:\[([\w\t \-]+)\])?\]//s) {
        my ($link, $label) = ($2,$3);
        $self->format_text($1);
        $label ||= $link;
        $label =~ s/([^\/])\/[^\/].*$/$1/;
        ($link, $label) = $self->{_onlink}->($link, $label) if $self->{_onlink};
        my $el = _element('a');
        _add_attrib($el, 'href', $link);
        $self->_open_element($el);
        $self->parent->characters({Data => $label});
        $self->_close_element('a');
        $self->format_text($text);
    }
    elsif ($self->{parse_html} && $text =~ s/^([^<]*)(<[^\/])/$2/) {
        $self->format_text($1);
        $self->{html_parser}->parse($text);

        my $tag = $LAST_HTML_TAG->[0];
        my $el = _element($tag);
        foreach my $attrib (keys %{ $LAST_HTML_TAG->[1] }) {
            _add_attrib($el, $attrib, $LAST_HTML_TAG->[1]->{$attrib});
        }
        $self->_open_element($el);
        $self->_close_element($tag) if (grep $_ eq $tag, @AUTO_CLOSED);

        my $tag_text = quotemeta($LAST_HTML_TAG->[2]);
        $text =~ s/^.*?$tag_text\n*//;
        $self->format_text($text);
    }

    # closing tags
    # </verbatim>
    elsif ($text =~ s/(.*?)<\/verbatim>//s) {
        $self->format_text($1);
        $self->_close_element('pre');
        $self->{parse_wiki} = 1;
        $self->{parse_html} = 1;
        $self->format_text($text);
    }
    # </pre>
    elsif ($self->{parse_html} && $text =~ s/(.*?)<\/pre>//s) {
        $self->format_text($1);
        $self->_close_element('pre');
        $self->{parse_wiki} = 1;
        $self->format_text($text);
    }
    # table
    elsif ($self->{parse_wiki} && $text =~ s/\|(\n|\Z)//s) {
        if ($self->{in_td}) {
            $self->_close_element('td');
            $self->{in_td} = 0;
        }
        if ($self->{'in_tr'}) {
            $self->_close_element('tr');
            $self->{'in_tr'} = 0;
        }
        $self->format_text($text);
    }
    # </strong>
    elsif ($self->{parse_wiki} && $text =~ s/($e)\*($f)/$2/s) {
        $self->_handle_found($1, $text, 'strong', 'close');
    }
    # </em>
    elsif ($self->{parse_wiki} && $text =~ s/($e)\_($f)/$2/s) {
        $self->_handle_found($1, $text, 'em', 'close');
    }
    # </em></strong>
    elsif ($self->{parse_wiki} && $text =~ s/($e)\_\_($f)/$2/s) {
        $self->_handle_found($1, $text, ['em', 'strong'], 'close');
    }
    # </code>
    elsif ($self->{parse_wiki} && $text =~ s/($e)\=($f)/$2/s) {
        $self->_handle_found($1, $text, 'code', 'close');
    }
    # </code></strong>
    elsif ($self->{parse_wiki} && $text =~ s/($e)\=\=([\s\,\.\;\:\!\?\)]|\Z)/$2/s) {
        $self->_handle_found($1, $text, ['code', 'strong'], 'close');
    }
    # other html
    elsif ($self->{parse_html} && $text =~ s/^([^<]*)(<\/)/$2/) {
        $self->format_text($1);
        $self->{html_parser}->parse($text);
        my ($tag, $tag_text) = @{ $LAST_HTML_TAG };
        $self->_close_element($tag);
        $text =~ s/^.*?$tag_text\n*//;
        $self->format_text($text);
    }

    # default text handling
    elsif ($text =~ s/^([^\n]+)//) {
        my $t = $self->{parse_html} ? $self->deescape($1) : $1;
        $self->parent->characters({Data => $t});
        $self->format_text($text);
    }
    elsif ($text =~ s/^\n//) {
        my $closed += $self->_close_element() || 0;
        if ($self->{parse_wiki} && !$closed) {
            $self->parent->start_element(_element('br'));
            $self->parent->end_element(_element('br'), 1);
        }
        elsif (!$self->{parse_wiki}) {
            $self->parent->characters({Data => "\n"});
        }
        $self->format_text($text);
    }
}
}

sub setDeEscaperRegex {
    my $self = shift;
    my $writer = $self->parent->{Handler}->{Handler};
    my %escape = reverse %{ $writer->{Escape} };

    $self->{DeEscaperRegex} = eval 'qr/' .
                            join( '|', map { $_ = "\Q$_\E" } keys %escape) .
                            '/;';
    $self->{DeEscape} = \%escape;
    return $self;
}

sub deescape {
    my $self = shift;
    my $str  = shift;
    $self->setDeEscaperRegex unless defined $self->{DeEscaperRegex};

    $str =~ s/($self->{DeEscaperRegex})/$self->{DeEscape}->{$1}/oge;
    return $str;
}

sub _element {
    my ($name, $end) = @_;
    return {
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;

    $el->{Attributes}{"{}$name"} =
      {
	  Name => $name,
	    LocalName => $name,
	    Prefix => "",
	    NamespaceURI => "",
	    Value => $value,
      };
}

1;
__END__

=head1 NAME

Text::WikiFormat::SAX - a SAX parser for Wiki text

=head1 SYNOPSIS

  use Text::WikiFormat::SAX;
  use XML::SAX::Writer;

  my $output = '';

  my $parser = Text::WikiFormat::SAX->new(
       Handler => XML::SAX::Writer->new(
         Output => \$output
       )
     );
  $parser->parse_string($wiki_text);
  print $output;

=head1 DESCRIPTION

This module implements a SAX parser for WikiWiki text. The code is
based on Text::WikiFormat, and so only supports the formatting that
module supports.

=cut
