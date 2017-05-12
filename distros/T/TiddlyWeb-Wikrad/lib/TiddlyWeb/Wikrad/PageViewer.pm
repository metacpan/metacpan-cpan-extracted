package TiddlyWeb::Wikrad::PageViewer;
use strict;
use warnings;
use Curses::UI::Common;
use base 'Curses::UI::TextEditor';
use Curses;
use TiddlyWeb::Wikrad qw/$App/; # XXX cyclic?

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        -vscrollbar => 1,
        -wrapping => 1,
        @_,
    );

    return $self;
}

sub next_link {
    my $self = shift;
    my $pos = $self->{-pos};
    my $text = $self->get;
    my $after_text = substr($text, $pos, -1);
    if ($after_text =~ m/(\[\[.|\b[A-Z][a-z]+[A-Z][a-z]+\b)/) {
        my $link_pos = $pos + $-[0] + 3;
        $self->{-pos} = $link_pos;
    }
}

sub prev_link {
    my $self = shift;
    my $pos = $self->{-pos};
    my $text = $self->get;
    my $before_text = reverse substr($text, 0, $pos);
    if ($before_text =~ m/(\]\].|\b[a-z]+[A-Z][a-z]+[A-Z]\b)/) {
        my $link_pos = $pos - $-[0] - 3;
        $self->{-pos} = $link_pos;
    }
}

sub viewer_enter {
    my $self = shift;
    my $pos = $self->{-pos};
    my $text = $self->get;
    my $before_pos = substr($text, 0, $pos);

    my @wikilink_types = (
        [ '\W' => '\W' ],
    );
    my @freelink_types = (
        [ '\[\[' => '\]\]' ],
    );
    my $link_text;
    for my $link (@freelink_types) {
        my ($pre, $post) = @$link;
        if ($before_pos =~ m/$pre([^$post]*)$/) {
            $link_text = $1;
            my $after_pos = substr($text, $pos, -1);
            if ($after_pos =~ m/([^$post]*)$post/) {
                $link_text .= $1;
            }
            else {
                $link_text = undef;
            }
        }
        if ($link_text) {
            if ($link_text =~ /[\w ]+\|([^]]+.*)/) {
                $link_text = $1;
            }
            return $App->set_page($link_text);
        }
    }
    for my $link (@wikilink_types) {
        my ($pre, $post) = @$link;
        if ($before_pos =~ m/$pre([^$post]*)$/) {
            $link_text = $1;
            my $after_pos = substr($text, $pos, -1);
            if ($after_pos =~ m/([^$post]*)$post/) {
                $link_text .= $1;
            } else {
                $link_text = undef;
            }
        }
        if ($link_text) {
            if ($link_text =~ /^[[:upper:]][[:lower:]]+[[:upper:]][[:lower:]]+$/) {
                return $App->set_page($link_text);
            }
        }
    }
    return;
}

sub readonly($;)
{   
    my $this = shift;
    my $readonly = shift;

    # setup key bindings with readonly set to true
    # so we can't edit this puppy
    $this->SUPER::readonly(1);
    $this->{-readonly} = $readonly;
    return $this;
}

sub draw_text(;$)
{
    my $this = shift;
    my $no_doupdate = shift || 0;
    return $this if $Curses::UI::screen_too_small;

    # Return immediately if this object is hidden.
    return $this if $this->hidden;

    # Draw the text.
    for my $id (0 .. $this->canvasheight - 1)
    {    
	# Let there be color
        my $co = $Curses::UI::color_object;
	if ($Curses::UI::color_support) {
            my $pair = $co->get_color_pair(
                                 $this->{-fg},
                                 $this->{-bg});

            $this->{-canvasscr}->attron(COLOR_PAIR($pair));
        }

        if (defined $this->{-search_highlight} 
            and $this->{-search_highlight} == ($id+$this->{-yscrpos})) {
            $this->{-canvasscr}->attron(A_REVERSE) if (not $this->{-reverse});
            $this->{-canvasscr}->attroff(A_REVERSE) if ($this->{-reverse});
        } else {
            $this->{-canvasscr}->attroff(A_REVERSE) if (not $this->{-reverse});
            $this->{-canvasscr}->attron(A_REVERSE) if ($this->{-reverse});
        }

        my $l = $this->{-scr_lines}->[$id + $this->{-yscrpos}];
        if (defined $l)
        {
            # Get the part of the line that is in view.
            my $inscreen = '';
            my $fromxscr = '';
            if ($this->{-xscrpos} < length($l))
            {
                $fromxscr = substr($l, $this->{-xscrpos}, length($l));
                $inscreen = ($this->text_wrap(
		    $fromxscr, 
		    $this->canvaswidth, 
		    NO_WORDWRAP))->[0];
            }

            # Clear line.
            $this->{-canvasscr}->addstr(
                $id, 0, 
		" "x$this->canvaswidth
	    );

            # Strip newline
            $inscreen =~ s/\n//;
            my @segments = (
                { text => $inscreen },
            );
            my $replace_segment = sub {
                my ($i, $pre, $new, $attr, $post) = @_;
                my $old_segment = $segments[$i];
                my $old_attr = $old_segment->{attr};
                my @new_segments;
                $attr = [$attr] unless ref($attr) eq 'ARRAY';
                push @new_segments, { 
                    attr => $old_attr,
                    text => $pre,
                } if $pre;
                push @new_segments, {
                    text => $new, 
                    attr => $attr,
                };
                push @new_segments, {
                    text => $post,
                    attr => $old_attr,
                } if $post;

                splice(@segments, $i, 1, @new_segments);
            };

            my $make_color = sub {
                return COLOR_PAIR($co->get_color_pair(shift, $this->{-bg}));
            };
            my $full_line = sub {
                my ($starting, $colour) = @_;
                return {
                    regex => qr/^($starting.+)/,
                    cb => sub {
                        my ($i, @matches) = @_;
                        $replace_segment->($i, '', $matches[0], 
                                           $make_color->($colour), '');
                    },
                };
            };
            my $inline = sub {
                my ($char, $attr) = @_;
                my $backchar = reverse $char;
                return {
                    regex => qr/^(.*?\s)?(\Q$char\E\S.+\S\Q$backchar\E\s?)(.*)/,
                    cb => sub {
                        my ($i, @matches) = @_;
                        $replace_segment->($i, @matches[0, 1], $attr, $matches[2]);
                    },
                };
            };
            my @wiki_syntax = (
                $full_line->('\!+ ', 'magenta'), # heading
                $full_line->('\*+ ', 'green'),   # list
                $inline->('**', A_BOLD), 
                $inline->('//', A_UNDERLINE), 
                $inline->('-', A_STANDOUT),
                $inline->('-----', [A_STANDOUT, $make_color->('yellow')]),
                { # link
                    regex => qr/(.*?)(\[\[[^\]]+\]\]|[A-Z][a-z]+[A-Z][a-z]+)(.*)/,
                    cb => sub {
                        my ($i, @matches) = @_;
                        return unless $matches[0] or $matches[1];
                        $replace_segment->($i, @matches[0, 1], 
                                           $make_color->('blue'), $matches[2]);
                    },
                },
            );
            for my $w (@wiki_syntax) {
                my $i = 0;
                while($i < @segments) {
                    my $s = $segments[$i];
                    my $text = $s->{text};
                    if ($text =~ $w->{regex}) {
                        $w->{cb}->($i, $1, $2, $3);
                    }
                    $i++;
                }
            }

            # Display the string
            my $len = 0;
            for my $s (@segments) {
                my $a = $s->{attr} || [];
                $this->{-canvasscr}->attron($_) for @$a;
                $this->{-canvasscr}->addstr($id, $len, $s->{text});
                $this->{-canvasscr}->attroff($_) for @$a;
                $len += length($s->{text});
            }
        } else {
            last;
        }
    }

    # Move the cursor.
    # Take care of TAB's    
    if ($this->{-readonly}) 
    {
        $this->{-canvasscr}->move(
            $this->canvasheight-1,
            $this->canvaswidth-1
        );
    } else {
        my $l = $this->{-scr_lines}->[$this->{-ypos}];
        my $precursor = substr(
            $l, 
            $this->{-xscrpos},
            $this->{-xpos} - $this->{-xscrpos}
        );

        my $realxpos = scrlength($precursor);
        $this->{-canvasscr}->move(
            $this->{-ypos} - $this->{-yscrpos}, 
            $realxpos
        );
    }
    
    $this->{-canvasscr}->attroff(A_UNDERLINE) if $this->{-showlines};
    $this->{-canvasscr}->attroff(A_REVERSE) if $this->{-reverse};
    $this->{-canvasscr}->noutrefresh();
    doupdate() unless $no_doupdate;
    return $this;
}

1;
