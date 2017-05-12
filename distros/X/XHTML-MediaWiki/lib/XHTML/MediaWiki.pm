use warnings;
use strict;

package XHTML::MediaWiki;
#XHTML::MediaWiki::

=head1 NAME

XHTML::MediaWiki - Translate Wiki markup into xhtml

=cut

our $VERSION = '0.11';
$VERSION = eval $VERSION;

our $DEBUG = 0;

=head1 SYNOPSIS

	use XHTML::MediaWiki;
	my $mediawiki = XHTML::MediaWiki->new( link_path => "http://example.com/base/" );
	my $xhtm = $mediawiki->format($text);

=head1 DESCRIPTION

L<http://www.mediawiki.org/> and its sister projects use the PHP
Mediawiki to format their pages. This module attempts to duplicate the
Mediawiki formatting rules. Those formatting rules can be simple and
easy to use, while providing more advanced options for the power user.

=cut

use Carp qw(carp confess croak);
use CGI qw(:standard);
use Scalar::Util qw(blessed);

use HTML::Parser;

=head2 Constructors

=over 4

=item * new( link_path => 'base path' )

Create a new XHTML:;MediaWiki object.  C<link_path> is used as the base
for hyperlinks.

=back

=cut

sub new
{
    my $class = shift;

    bless {
        link_path => '',
	@_
    }, $class;
}

=head2 Methods

=over 4

=item * format()

The format method is the only method that needs to be called for the
normal operation of this object.  You call format() with the raw I<wikitext> and
it returns the xhtml representation of that I<wikitext>.

=cut

sub format
{
    my $self = shift;
    my $raw = shift;

    my $cooked = $self->_format($raw);

    return $cooked;
}

=item * reset_counters()

Call this method to reset the footnote counter.

=back

=cut

sub reset_counters
{
    my $self = shift;

    $self->{footnote} = 0;
}

=head2 Overridable Methods

The following methods can be overridden to change the functionality of
the object.

=over 4

=item * get_block()

If you would like to override the Block objects you can override this method.

=cut

sub get_block
{
    my $self = shift;
    my $type = shift;

    my $ret = 'XHTML::MediaWiki::Block::' . ucfirst($type || 'special');
}

# This sub recognizes three states:
#
#   1.  undef
#       Normal wiki processing will be done on this line.
#
#   2.  html
#       Links and phrasal processing will be done, but formatting should be
#       ignored.
#
#   3.  nowiki
#       No further wiki processing should be done.
#
# Each state may override the lower ones if already set on a given line.
#

{
    package XHTML::MediaWiki::Parser::Block::Line;

    use Params::Validate qw (validate);

    sub new
    {
        my $class = shift;
        my %p = validate(@_, {
            state => 1,
            text => {
                default => '',
            },
            eol => 0,
        });

        my $self = bless { %p }, $class;

        return $self;
    }

    sub state
    {
        shift->{state};
    }

    sub append
    {
        my $self = shift;
        my $text = shift;
        $self->{text} .= $text;
    }

}
{
    package XHTML::MediaWiki::Parser::Block;

    use Params::Validate qw (validate);
    use Carp qw(croak);

    sub new
    {
        my $class = shift;
        my %p = validate(@_, {
            type => 1,
            level => 0,
        });
        croak("internal error") if ($p{type} eq 'unordered' && !$p{level});
        my $self =
            bless {
                lines => [],
                %p,
            }, $class;

        return $self;
    }

    sub block_type
    {
        shift->{type};
    }

    sub args
    {
        my $self = shift;
        push(@{$self->{lines}}, $self->{line}) if $self->{line};
        return (
            lines => $self->{lines},
            (level => $self->{level}) x!!  $self->{level},
        );
    }

    sub get_line
    {
        my $self = shift;

        $self->{line} ||= XHTML::MediaWiki::Parser::Block::Line->new( state => 'wiki');
    }

    sub get_state
    {
        my $self = shift;

        $self->{type};
    }

    sub in_nowiki
    {
        my $self = shift;
        my $line = $self->{line};

        if ($line) {
            return $line->state eq 'nowiki';
        } else {
            return 0;
        }
    }

    sub append_text
    {
        my $self = shift;
        my $text = shift;
        die "extra arguments" if @_;

        my $line = $self->get_line();
        $line->append($text);
    }

    sub set_nowiki
    {
        my $self = shift;

        push(@{$self->{lines}}, $self->{line}) if $self->{line};
        $self->{line} = XHTML::MediaWiki::Parser::Block::Line->new(state => 'nowiki');
    }

    sub set_wiki
    {
        my $self = shift;

        push(@{$self->{lines}}, $self->{line}) if $self->{line};
        $self->{line} = XHTML::MediaWiki::Parser::Block::Line->new(state => 'wiki');
    }

    sub is_paragraph
    {
        my $self = shift;

        return $self->{type} eq 'paragraph';
    }

    sub is_prewiki
    {
        my $self = shift;

        return $self->{type} eq 'prewiki';
    }

    sub set_end_line
    {
        my $self = shift;
        my $cnt = shift or croak "need count";

        my $line = $self->{line};
        if (!defined $line) {
            $line = $self->{lines}[-1] || XHTML::MediaWiki::Parser::Block::Line->new(state => 'dummy');
            $line->{eol} = $cnt;
        }
        for (my $x = 0; $x < $cnt; $x++) {
            $line->append("\n");;
        }
        $self;
    }
}

=item * encode()

You can override the encode function if you would like to change
what is encoded.  Currently only &, <, and > are encoded.

=cut

sub encode
{
    my $text = shift;
    if (defined $text) {
        $text =~ s{&}{&amp;}gso;
        $text =~ s{<}{&lt;}gso;
        $text =~ s{>}{&gt;}gso;
    }
    return $text;
}

sub _close_to
{
    my $parser = shift;
    my $tag = shift;
    my $tagstack = $parser->{tag_stack};
    my $text = '';

    if (!@$tagstack) {
        $text .= "<!-- extra closing $tag -->" if $DEBUG;
        # ignore extra closing tags
    } else {
        while (my $toptag = pop @$tagstack) {
            $text .= "</$toptag>";
            last if $tag eq $toptag;
        }
    }

    return $text;
}

sub _html_tag
{
    my ($parser, $type, $tagname, $orig, $attr) = @_;
    $tagname =~ s|/$||;

    if ($parser->in_nowiki && ($type ne 'E' || $tagname ne 'nowiki')) {
        $parser->append_text(encode($orig));
        return;
    }
    if ($parser->in_state('pre') && ($type ne 'E' || $tagname ne 'pre')) {
        $parser->append_text(encode($orig));
        return;
    }
    if (my $info = $parser->{tags}{$tagname}) {
        my $tagstack = $parser->{tag_stack};
        if ($type eq 'E') {
            if ($info->{empty}) {
warn "empty tags";
#skip empty tags;
            } elsif ($info->{nowiki}) {
#               my $text = _close_to($parser, $tagname);
                $parser->end_nowiki();
            } elsif ($info->{block}) {
                $parser->close_block();
            } elsif ($info->{phrase}) {
                my $text = _close_to($parser, $tagname);
                $parser->append_text($text);
            } elsif ($info->{special}) {
                $parser->close_block();
                my $text = _close_to($parser, $tagname);
                $parser->add_block($text);
            } else {
die "helpme $tagname";
            }
        } else {
            if ($info->{empty}) {
                $parser->append_text("<$tagname/>");
            } elsif ($info->{nowiki}) {
                $parser->start_nowiki();
#               push @$tagstack, $tagname;
            } elsif (my $blockname = $info->{block}) {
                $parser->close_block( new_state => $blockname );

#               $parser->{state} = $blockname;
                unless ($info->{notag}) {
                    $parser->append_text("<$tagname>");
                }
                push @$tagstack, $tagname;
            } elsif ($info->{phrase}) { 
                push(@$tagstack, $tagname);
                my $text = "<$tagname>";
                $parser->append_text($text);
            } elsif ($info->{special}) { 
                $parser->close_block();
                push(@$tagstack, $tagname);
                my $text = "<$tagname>";
                $parser->add_block($text);
            } else {
die "helpme $tagname";
                push @$tagstack, $tagname;
            }
        }
    } else {
        $parser->append_text($parser, encode($orig));
    }

    return;
}

sub _html_comment
{
#    warn "_html_comment: " . join(' ', @_);
}

sub _html_text
{
    my ($parser, $dtext, $skipped_text, $is_cdata) = @_;
    my @tagstack = @{$parser->{tag_stack}};
    my ($newtext, $newstate);

    if (my ($leading) = ($dtext =~ /^(\n+)/m)) {
        my $x = length($leading);
        $parser->end_line($x);
        $dtext = substr($dtext, $x);
    }

    if ($is_cdata && $parser->can_cdata) {
        $newtext = $dtext;
    } else {
        $newtext = encode($dtext);
    }

    $parser->append_text($newtext);

#    warn "Got skipped_text: `$skipped_text'\n[$dtext]\n" if $skipped_text;
}

{
    package XHTML::MediaWiki::Parser;

    use base 'HTML::Parser';

    use Params::Validate qw (validate);

    sub can_cdata
    {
        my $self = shift;
        if (my $current = $self->check_current_block) {
            return $self->{tags}{$current->{type}}{can_cdata};
        }
        return 0;
    }

    sub end_line
    {
        my $self = shift;

        my $block = $self->get_last_line_block;

        $block->set_end_line(@_);;
    }

    sub state
    {
        my $self = shift;

        my $block = $self->check_current_block;
        return "none" unless $block;
        return $block->get_state;
    }

    sub in_state
    {
        my $self = shift;
        my $state = shift;
        die if @_;
        my $cstate = $self->state;

        $cstate && $cstate eq $state;
    }

    sub in_paragraph
    {
        my $self = shift;
        my $ret = 0;
        if (my $block = $self->check_current_block) {
            $ret = $block->is_paragraph;
        }
        return $ret;
    }

    sub in_prewiki
    {
        my $self = shift;
        my $ret = 0;
        if (my $block = $self->check_current_block) {
            $ret = $block->is_prewiki;
        }
        return $ret;
    }

    sub noformat
    {
        my $self = shift;

        $self->in_state('pre') or $self->in_nowiki();
    }

    sub add_block
    {
        my $self = shift;

        if ($self->{current_block}) {
            push(@{$self->{blocks}},
                $self->{current_block}
            );
die "This should have been handled by close_block";
        }
        my $block = $self->{current_block} = XHTML::MediaWiki::Parser::Block->new(type => 'special');
        $block->append_text(join('', @_));
        push(@{$self->{blocks}},
            $self->{current_block}
        );
        $self->{current_block} = undef;
    }

    sub close_block
    {
        my $self = shift;
        my %p = validate(@_, {
            new_state => {
                optional => 1,
            },
            indent => {
                optional => 1,
            },
            auto_merge => {
                optional => 1,
            },
        });

        my $tagstack = $self->{tag_stack};
        my $find = undef;
        my $text = '';
        if (!@$tagstack) {
# nothing to close;
        } else {
            for my $tagname (@$tagstack) {
                my $info = $self->{tags}{$tagname};
                if ($info->{block}) {
                    $find = $tagname;
                }
            }
        }
        if ($find) {
            $text = $self->close_to($find);
            if ($text) {
                $self->append_text($text);
            }
        }

        if (my $current = $self->{current_block}) {
            if ($p{auto_merge} && $p{new_state} eq $self->{current_block}->block_type) {
                push(@{$current->{lines}}, $current->{line}) if ($current->{line});
                $current->{line} = undef;
            } else {
                push(@{$self->{blocks}},
                    $self->{current_block}
                );
                $self->{current_block} = undef;
                if (my $state = $p{new_state}) {
                    if ($state eq 'ordered' || $state eq 'unordered') {
                        die "Need indent" unless exists $p{indent};
                        $self->{indent} = $p{indent};
                    }
                    $self->{current_block} = XHTML::MediaWiki::Parser::Block->new(
                        type => $state,
                        level => $p{indent},
                    );
                }
            }
        } elsif (my $state = $p{new_state}) {
            $self->{current_block} = XHTML::MediaWiki::Parser::Block->new(
                type => $state,
                level => $p{indent},
            );
        }

        return $self;
    }

    sub close_to
    {
        my $parser = shift;
        my $tag = shift;
        my $tagstack = $parser->{tag_stack};
        my $text = '';

        if (!@$tagstack) {
            $text .= "<!-- extra closing $tag -->" if $DEBUG;
            # ignore extra closing tags
        } else {
            while (my $toptag = pop @$tagstack) {
                if (!  $parser->{tags}{$toptag}{notag}) {
                    $text .= "</$toptag>";
                }
                last if $tag eq $toptag;
            }
        }
        return $text;
    }

    sub start_nowiki
    {
        my $self = shift;
        my $block = $self->get_current_block;

        $block->set_nowiki;
    }

    sub end_nowiki
    {
        my $self = shift;
        my $block = $self->get_current_block;

        $block->set_wiki;
    }

    sub in_nowiki
    {
        my $self = shift;

        if (my $block = $self->check_current_block) {
            return $block->in_nowiki;
        } else {
            return 0;
        }
    }

    sub check_current_block
    {
        my $self = shift;

        $self->{current_block};
    }

    sub get_current_block
    {
        my $self = shift;

        if (!$self->{current_block}) {
            my $tagstack = $self->{tag_stack};
            my $new_state = $self->{state} || 'paragraph';
            delete $self->{state};
            croak() if $new_state eq 'unordered';
            $self->{current_block} = XHTML::MediaWiki::Parser::Block->new(type => $new_state);
            push @{$self->{tag_stack}}, 'paragraph';
        }
        return $self->{current_block};
    }

    sub get_last_line_block
    {
        my $self = shift;
        my $block = $self->get_current_block;

        if (! defined $block) {
            $block = $self->{blocks}[-1];
        }
        return $block;
    }

    sub append_text
    {
        my $self = shift;
        my $text = shift;

        my $block = $self->get_current_block;

        $block->append_text($text);
    }

    sub get_blocks
    {
        my $self = shift;
        my @blocks;

        for my $block (@{$self->{blocks}}) {
            next unless $block;
            if ($block->{type} eq 'paragraph' && 0 == @{$block->{lines}} && !$block->{line}) {
warn "fix";
                next;
            }
            push @blocks, $block;
        }
        @blocks;
    }

    sub eof
    {
        my $self = shift;
        $self->close_block();
        for my $tag (@{$self->{tag_stack}}) {
            $self->append_text("</$tag>\n");
        }
        $self->SUPER::eof(@_);
    }
}

sub _find_blocks_in_html
{
    my $self = shift;
    my $text = shift || "";
    die if @_;

    my $parser = XHTML::MediaWiki::Parser->new
        (start_h   => [\&_html_tag, 'self, "S", tagname, text, attr'],
         end_h     => [\&_html_tag, 'self, "E", tagname, text'],
         comment_h => [\&_html_comment, 'self, text'],
         text_h    => [\&_html_text, 'self, dtext, skipped_text, is_cdata'],
         marked_sections => 1,
         boolean_attribute_value => '__TEXT_MEDIAWIKIFORMAT_BOOL__',
        );
    $parser->{opts} = {},
    $parser->{tags} = {
        b => { phrase => 1 },
        big => { phrase => 1 },
        blockquote => { phrase => 1 },
        br => { empty => 1 },
        caption => {},
        center => {},
        cite => {},
        code => { phrase => 1 },
        dd => {},
        div => {
            special => 1,
        },
        dl => {},
        dt => {},
        em => {},
        font => {},

        h1 => { block => 'header' },
        h2 => { block => 'header' },
        h3 => { block => 'header' },
        h4 => { block => 'header' },
        h5 => { block => 'header' },
        h6 => { block => 'header' },

        hr => { empty => 1 },
        i => { },
        li => { },
        nowiki => { 
            nowiki => 1, 
            notag => 1,
        },
        ol => { },
        p => { block => 'p' },
        paragraph => {
            block => 'paragraph',
            notag => 1 
        },
        pre => { 
            block => 'pre',
#           nowiki => 1,
        },
        rb => {},
        rp => {},
        rt => {},
        ruby => { 
            block => 'ruby',
            can_cdata => 1,
        },
        s => {},
        samp => {},
        small => {},
        strike => {},
        strong => {},
        sub => {},
        sup => {},
        table => {},
        td => {},
        th => {},
        tr => {},
        tt => {},
        u => {},
        ul => {},
        var => {},
    };
    $parser->{tag_stack} = [];
    $parser->{blocks} = [];
    $parser->{current_block} = undef;

    my @lines = split(/\r?\n/, $text);

    for my $line (@lines) {
        my $close = 0;
        die if chomp $line;
        if ($parser->noformat) {
# we are in nowiki or pre block
        } else {
            if ($parser->in_prewiki && $line && $line !~ m/^\s+/) {
                $parser->close_block();
            }
            if ($line =~ qr/^(={1,6})\s*(.+?)\s*\1$/) {
                my $x = length $1;
                $line = sprintf("<h%d>%s</h%d>\n", $x, $2, $x);
                $parser->{last} = 'header';
            } elsif ($line =~ /^$/) {
                if ($parser->check_current_block) {
                    if ($parser->in_paragraph) {
                        $parser->close_block();
                    } elsif ($parser->in_prewiki) {
                        $parser->close_block();
                    } else {
                    }
                } else {
                    unless ({header => 1, prewiki => 1}->{$parser->{last} || ''}) {
                        $line = "<br/>";
                    }
                }
            } elsif ($line =~ m/^\s(\s*.*)$/) {
                $line = $1;
                $parser->close_block( new_state => 'prewiki', auto_merge => 1 );

                $parser->{last} = 'prewiki';
            } elsif ($line =~ m/^(#+)\s*(.*)\s*$/) {
                my $x = length $1;
                $parser->close_block( new_state => 'ordered', indent => $x );
                $close = 1;
                $line = $2;
                $parser->{last} = 'nested';
            } elsif ($line =~ m/^(\*+)\s*(.*)\s*$/) {
                my $x = length $1;
                $parser->close_block( new_state => 'unordered', indent => $x );
                $close = 1;
                $line = $2;
                $parser->{last} = 'nested';
            } else {
            }
        }
        next unless $line;
        $parser->parse($line);
        $parser->parse("\n");

        $parser->{empty_lines} = 0;

        $parser->close_block() if $close;
    }
    $parser->eof();
    my @blocks;

    for my $block ($parser->get_blocks) {
        next unless defined $block;
        my $type = $block->block_type;
        my $class = $self->get_block($type);

        my $new_block =
            $class->new (
                type  => $type,
                $block->args,
                formater => $self,
            );
        push @blocks, $new_block;
    }

    return @blocks;
}

sub _find_blocks
{
    my $self = shift;
    my $text = shift;

    my @blocks;

    @blocks = $self->_find_blocks_in_html($text);

    return @blocks;
}

sub _nest_blocks
{
    my $self = shift;
    my @blocks = @_;
    return unless @blocks;

    my @processed = shift @blocks;
    for my $block (@blocks)
    {
        my @x = $processed[-1]->nest( $block );
        push @processed, @x;
    }

    return @processed;
}

sub _process_blocks
{
    my $self = shift;
    my @blocks = @_;
    my @open;
    for my $block (@blocks)
    {
        push @open, $self->_process_block($block);
    }
    return join '', @open ;
}

sub _process_block
{
    my $self = shift;
    my ($block, $tags, $opts) = @_;
    my $type = $block->type();

    my ($start, $end, $start_line, $end_line, $between);
    if ($tags->{$type})
    {
        ($start, $end, $start_line, $end_line, $between) = @{$tags->{$type}};
    }
    else
    {
        ($start, $end, $start_line, $end_line) = ('', '', '', '');
    }

    my @text = ();
    for my $line (grep (/^\Q$type\E$/, @{$tags->{unformatted_blocks}})
                  ? $block->text()
                  : $block->formatted_text())
    {
        if (blessed $line)
        {
                my $prev_end = pop @text || ();
                push @text, _process_block ($line, $tags, $opts), $prev_end;
                next;
        }

        my @triplets;
        if ((ref ($start_line) || '') eq 'CODE')
        {
            @triplets = $start_line->($line, $block->level(),
                                      $block->shift_args(), $tags, $opts);
        }
        else
        {
            @triplets = ($start_line, $line, $end_line);
        }
        push @text, @triplets;
    }

    pop @text if $between;
    return join '', $start, @text, $end;
}

sub _format
{
    my $self = shift;
    my $text = shift;

    my @blocks = $self->_find_blocks($text);

    @blocks = $self->_nest_blocks(@blocks);
    my $ret = $self->_process_blocks(@blocks);

    return $ret;
}

sub _strong
{
    "<strong>$_[1]</strong>";
}

=item * emphasized()

emphasized controls the output of "<em>" tags.

=cut

sub emphasized
{
    "<em>$_[1]</em>";
}

=item * link()

The link method is often overridden to modify the display and 
operation of links.

link takes 3 arguments the Link, any extra_text, and the type of the link;

The type is true for footnotes.

=cut

sub link
{
   my $self = shift;
   my $link = shift || '';
   my $extra = shift || '';
   my $type = shift;
   my $text = $link;
   if ($type) {
       $text = ++$self->{footnote};
   } else {
       $link = $self->{link_path} . $link;
   }
   qq|<a href='$link'>$text$extra</a>|;
}

=item * find_links()

The C<find_links> method is also often overridden in order to change the way 
links are detected.

=cut

sub find_links
{
    my $self = shift;
    my $text = shift;

    return '' unless defined $text;

    $text =~ s/\[\[([^\]]*)\]\]([A-Za-z0-9]*)/$self->link($1, $2, 0)/ge;
    $text =~ s/\[([a-zA-Z]+:[^\]]*)\]/$self->link($1, '', 1)/ge;

    return $text;
}

=item * template_text()

Override this method to control the text that is generated for an unknown template ({{word}}).

=cut

sub template_text
{
    my $self = shift;
    my $text = shift;
    die if @_;
    '<b style="color: red;">No template for: ' . $text . '</b>';
}

=item * format_line()

Override this method to extend or modify line level parsing.

=cut

sub format_line
{
    my $self = shift;
    my $text = shift;

    return '' unless defined $text;

    my $strong_tag = qr/'''(.+?)'''/;
    my $emphasized_tag = qr/''(.+?)''/;

    $text =~ s!$strong_tag!$self->_strong($1)!eg;
    $text =~ s!$emphasized_tag!$self->emphasized($1)!eg;

    $text = $self->find_links($text);

    my $template_tag = qr/{{\s*([a-zA-Z0-9][a-z0-9|]*)\s*}}/;
    $text =~ s!$template_tag!$self->template_text($1)!eg;
   
    return $text;
}

# BLOCK code is below here and needs to be moved.

{
    package XHTML::MediaWiki::Block::Start;

    use base "XHTML::MediaWiki::Block";
    sub formatted_text
    {
        "<!-- start wiki -->\n";
    }
}
{
    package XHTML::MediaWiki::Block::Header;

    use base "XHTML::MediaWiki::Block";

    sub formatted_text
    {
        my $self = shift;
        my $formatter = $self->formatter;
        my $text = $self->SUPER::formatted_text();

        my $newtext = $text;
        $newtext =~ s/<[^>]+>//g;
        $newtext =~ s/\s/_/g;
        qq|<a name="$newtext"></a>| .  $text;
    }
}

{
    package XHTML::MediaWiki::Block::Special;
    use base "XHTML::MediaWiki::Block";

    sub formatted_text
    {
        my $self = shift;
        my $formatter = $self->formatter;
        my $ret_text = '';
        for my $line (@{$self->{lines}}) {
            die("internal error") unless $line;

            my $text .= $line->{text};
            if ($line->{state} eq 'nowiki') {
                $ret_text .= $text;
            } else {
                $ret_text .= $formatter->format_line($text);
            }
        }
        $ret_text;
    }
}
{
    package XHTML::MediaWiki::Block::P;
    use base "XHTML::MediaWiki::Block";

    sub formatted_text
    {
        my $self = shift;
        $self->SUPER::formatted_text(@_) . "\n";
    }
}
{
    package XHTML::MediaWiki::Block::Paragraph;
    use base "XHTML::MediaWiki::Block";

    use Carp qw(croak);

    sub formatted_text
    {
        my $self = shift;
        my $formater = $self->{formater};
        my $ret_text = '';

        for my $line (@{$self->{lines}}) {
use Data::Dumper;
warn Dumper $self unless $line;
            die("internal error") unless $line;

            my $text .= $line->{text};
            if ($line->{state} eq 'nowiki') {
                $ret_text .= $text;
            } else {
                $ret_text .= $formater->format_line($text);
            }
        }
        if ($ret_text =~ m/^\s*$/) {
#           return "<!-- skip -->\n";
        } else {
            return '<p>' . $ret_text . "</p>\n";
        }
    }
}

{
    package XHTML::MediaWiki::Block::Nested;
    use base "XHTML::MediaWiki::Block";

    sub new
    {
        my $class = shift;
        my $self = $class->SUPER::new(@_);

        die caller unless $self->{level};
        return $self;
    }

    sub formatted_text
    {
        my $self = shift;

        my $formatter = $self->formatter;
        my $text = $self->SUPER::formatted_text(@_);

        my $indent = $self->{level};
        my $ret = $self->start_block;

        $ret .= '<li>' . $text;
        if ($self->{block}) {
            $ret .= $self->{block}->formatted_text();
        }
        $ret .= "</li>\n";

        for my $x (@{$self->{added}}) {
            $ret .= '<li>' . $x->SUPER::formatted_text();
            if ($x->{block}) {
                $ret .= $x->{block}->formatted_text();
            }
            $ret .= "</li>";
            $ret .= "\n";
        }
        $ret .= $self->end_block;

        return $ret;
    }

    sub level
    {
        my $self = shift;

        return $self->{level};
    }

    sub cmp
    {
        my $self = shift;
        my $cmp_block = shift;
        my $ret = 0;

        if (ref($self) eq ref($cmp_block) && $self->level == $cmp_block->level) {
            $ret = 1;
        }
        return $ret;
    }

    sub nests
    {
        1;
    }

    sub nest_block
    {
        my $self = shift;
        my $current = $self->{added}->[-1] || $self;
        for my $block (@_) {
            my $index = $block->level - $self->level;
            die 'internal error' if $index <= 0;
            if ($index == 1) {
                if (my $x = $current->{block}) {
                    $x->nest($block);
                } else {
                    $current->{block} = $block;
                }
            } else {
                $current->{block} ||= ref($block)->new(
                    formater => $current->{formater},
                    type => $current->type,
                    level => $current->level + 1,
                );
                $current->{block}->nest($block);
            }
        }
    }
}

{
    package XHTML::MediaWiki::Block::Ordered;
    use base "XHTML::MediaWiki::Block::Nested";
    sub start_block { "<ol>\n" }
    sub end_block { "</ol>\n" }
}
{
    package XHTML::MediaWiki::Block::Unordered;
    use base "XHTML::MediaWiki::Block::Nested";
    sub start_block { "<ul>\n" }
    sub end_block { "</ul>\n" }
}
{
    package XHTML::MediaWiki::Block::Pre;
    use base "XHTML::MediaWiki::Block";

    sub formatted_text {
        my $self = shift;
        my $text = $self->unformatted_text;

        return $text;
    }
}
{
    package XHTML::MediaWiki::Block::Prewiki;
    use base "XHTML::MediaWiki::Block";

    sub formatted_text
    {
        my $self = shift;
        my $text = $self->SUPER::formatted_text(@_);
        $text =~ s/^\s*//;

        return "\n" . '<pre>' . $text . "\n</pre>";
    }
}
{
    package XHTML::MediaWiki::Block::Ruby;
    use base "XHTML::MediaWiki::Block";

    sub formatted_text
    {
        my $self = shift;
        my $text = $self->SUPER::unformatted_text(@_);

        return "Ruby Data";
    }
}
{
    package XHTML::MediaWiki::Block;
    use Params::Validate qw (validate ARRAYREF);

    sub new
    {
        my $class = shift;
        my %p = validate(@_, {
            formater => 1,
            type => 1,
            indent => 0,
            level => 0,
            lines => ARRAYREF,
            args => 0,
        });

        bless { %p }, $class
    }

    sub merge_block
    {
        my $self = shift;

        push(@{$self->{added}}, @_);
    }

    sub cmp
    {
        0;
    }

    sub merge
    {
        my $self = shift;
        my @ret = @_;

        while (my $block = pop @ret) {
            if ($self->cmp($block)) {
                $self->merge_block($block);
            } else {
                push(@ret, $block);
                last;
            }
        }

        @ret;
    }

    sub nests
    {
        return 0;
    }

    sub nest
    {
        my $self = shift;
        my @next_blocks = @_;

        @next_blocks = $self->merge(@next_blocks);
        while (@next_blocks) {
            my $next = $next_blocks[0];
            if ($self->nests && $next->nests) {
                $self->nest_block(pop @next_blocks);
            } else {
                last;
            }
        }

        return @next_blocks;
    }

    sub level
    {
       my $x = shift;
       warn $x;
       0;
    }

    sub type
    {
       my $self = shift;

       $self->{type};
    }

    sub formatter
    {
        shift->{formater};
    }

    sub unformatted_text {
        my $self = shift;
        my $formater = $self->{formater};
        my $text = '';

        for my $line (@{$self->{lines}}) {
            die("internal error") unless $line;

            $text .= $line->{text};
        }
        return $text;
    }

    sub formatted_text {
        my $self = shift;
        my $formater = $self->{formater};
        my $text = '';

        for my $line (@{$self->{lines}}) {
            die("internal error") unless $line;

            if ($line->{state} eq 'nowiki') {
                $text .= $line->{text};
            } else {
                $text .= $formater->format_line($line->{text});
            }
        }
        return $text;
    }
}

1;
__END__

=back

=head1 ACKNOWLEDGEMENTS

This module is derived from L<Text::WikiFormat|Text::WikiFormat>, written by chromatic.

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT

Copyright (C) 2008-2010 G. Allen Morris III, all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
