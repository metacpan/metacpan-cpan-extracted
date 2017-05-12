#perl
#
# The new EtText list-processing engine; totally rewritten from
# scratch given a set of datafiles.  Works a hell of lot better than
# the old regexp-based system!

package Text::EtText::Lists;

use Carp;
use strict;
use locale;

use Text::EtText;

use vars qw{
	@ISA
	$LIST_ROOT $LIST_NONE $LIST_UL $LIST_OL $LIST_DL $LIST_PRE $LIST_BQ 
};

@ISA = qw();

$LIST_ROOT	= 100;
$LIST_NONE	= 101;
$LIST_UL	= 102;
$LIST_OL	= 103;
$LIST_DL	= 104;
$LIST_PRE	= 105;
$LIST_BQ	= 106;

# each LI (list item) can have 2 indentation types; its "indent"
# and its "subindent".  These are as follows:
#
#      - this is
#        a demo
#      ^A^B        (A = indent, B = subindent)
#
#      - this is
#      a demo
#      ^AB         (A = indent, B = subindent, A == B)

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = { };

  bless ($self, $class);
  $self;
}

sub run {
  my ($self, @lines) = @_;
  local ($_);

  $self->{list_html} = [ ];
  $self->{LI_closed} = 1;			# starts off closed
  $self->set_list_stack_empty ();

  my $lastindent = 0;
  my $lastsubindent = 0;
  my $lasttype = '';		# not a list -- yet!
  my $lastblock = $LIST_NONE;
  my $lastlinewasblank = 0;
  my $lastlinewasshort = 0;

  foreach $_ (@lines) {
    my $indent = 0;

    s/\t/        /g;			# expand tabs
    s/^(\s+)// and $indent = length($1);

    my $ispbreak = 0;
    if (s/^\s*$/<\/p><p>/) {
      $indent = $lastindent;		# inherit from before
      $ispbreak = 1;
    }

    my $listtype = undef;
    my $listblock = $lastblock;
    my $subindent = $indent;
    my $isnewLI = 0;

    if (s/^([-\*\+o])(\s+)//) {
      $listtype = $1;
      $listblock = $LIST_UL;
      $subindent += length($2)+1;
      $isnewLI = 1;
    }
    elsif (s/^(\d+)([\.\)\]:])(\s+)(\S+)/$4/) {
      $listtype = '1'.$2;
      $listblock = $LIST_OL;
      $subindent += length($1)+length($2)+length($3);
      $isnewLI = 1;
    }
    elsif (s/^([A-Z])([\.\)\]:])(\s+)//) {
      $listtype = 'A'.$2;
      $listblock = $LIST_OL;
      $subindent += length($1)+length($2)+length($3);
      $isnewLI = 1;
    }
    elsif (s/^([a-z])([\.\)\]:])(\s+)//) {
      $listtype = 'a'.$2;
      $listblock = $LIST_OL;
      $subindent += length($1)+length($2)+length($3);
      $isnewLI = 1;
    }
    elsif (s/^([>\]]+)(\s*)//) {
      $listtype = '>'.$1.$2;
      $listblock = $LIST_BQ;
    }
    elsif (($indent == 1 && !$ispbreak) || ($indent == 0 && s/^::(\s)/$1/)) {
      $listtype = 'pre';
      $listblock = $LIST_PRE;
      $subindent = $indent = 1;
    }
    elsif (s/^\s*(\S.+?):\s{8,}/<dt>$1<\/dt>/) {           # definition lists.
      $listtype = 'dl';
      $listblock = $LIST_DL;
      # push (@{$self->{list_html}}, "<dt>$1</dt>");
      $isnewLI = 1;
    }
    elsif ($indent == 0 && s/^([-_A-Za-z0-9]+: )(\S.+)$/<em>$1<\/em>$2 <br \/>/) {
      # mail-style headers
      $listtype = '';
      $listblock = $LIST_NONE;
    }
    else {
      # no list-item-start marker, just text.

      # first, check to see if it's an indented start to a paragraph
      if ($lastblock == $LIST_NONE && !$lastlinewasblank && $indent > 0) {
	$indent = 0;
	s/^/<\/p><p>/g;
      }

      if ($indent == $lastindent || $indent == $lastsubindent) {
	# the next part of the prev list item, probably.
	$listtype = $lasttype;
	if ($self->{LI_contains_p_break}) {
	  $self->{LI_contains_multi_ps} = 1;
	}

      } elsif ($indent != 0 && $lastlinewasblank) {
	$listtype = 'blockquote';
	$listblock = $LIST_BQ;

      } else {
	$listtype = '';
      }

      if (!$ispbreak && !$lastlinewasblank && $lastlinewasshort) {
	# avoid putting <br>'s into HTML tags!
	if ($self->{LI_text} !~ /<[^>]+>?$/s) {
	  $_ = '<br />'.$_;		# line breaks
	}
      }
    }

    if ($ispbreak) {
      $self->{LI_contains_p_break} = 1;
      $lastlinewasshort = 0;

    } else {
      if (/\S/ && length ($_) < 50) {
	$lastlinewasshort = 1;
      } else {
	$lastlinewasshort = 0;
      }
    }

    # ok, figure out list-openings and list-closings.
    my $isnewlist = 0;
    my $iscloselist = 0;

    # list-closings:
    if ($indent < $lastindent) {
      if ($isnewLI && $listtype ne $lasttype) { $iscloselist = 1; }
      if ($isnewLI && $indent < $lastindent) { $iscloselist = 1; }

      # not sure this should be the case:
      # if (!$isnewLI && $indent < $lastsubindent) { $iscloselist = 1; }

      if (!$isnewLI && $indent == 0) {
	if ($listblock == $LIST_BQ && !$lastlinewasblank) {
	  # oops, it was a traditional-style paragraph, indented a
	  # few spaces on the first line, but back to normal for
	  # following lines. change from a BQ to a normal paragraph.
	  $listblock = $lastblock = $self->{listblock} = $LIST_NONE;
	  $listtype = $lasttype = $self->{listtype} = '';
	  $indent = $lastindent = 0;
	  $subindent = $lastsubindent = 0;
	  
	} else {
	  $iscloselist = 1;
	}
      }
    }

    if ($indent > $lastindent) {
      if ($isnewLI && $listtype ne $lasttype) { $isnewlist = 1; }
      if ($isnewLI && $indent > $lastindent) { $isnewlist = 1; }
    }

    # if the list items start in column 0, we need to disallow continuation
    # for normal text without a 'li-start' char in column 0, so we can
    # escape from such lists.
    if (!$isnewLI && $indent == 0 &&
		  ($lastblock == $LIST_UL || $lastblock == $LIST_OL))
    {
      $listtype = '';
      $listblock = $LIST_NONE;
      $iscloselist = 1;
    }

    if (!$isnewLI && $indent > $lastsubindent) { $isnewlist = 1; }

    if ($isnewlist && $iscloselist) {
      warn "assert failed: ($isnewlist && $iscloselist) should be false";
    }

    # if a list starts in column 0, we have no way of getting out of it!
    # make sure that column-0 lists can be returned from, by only
    # allowing additional paragraphs to start in columns > 0.
    if (($listblock == $LIST_UL || $listblock == $LIST_OL) && $indent == 0) {
      $indent = $subindent;
    } 

    if ($isnewlist) {
      $self->finish_LI_without_closing();
      $self->push_list_state();
      $self->new_list($listtype, $listblock, $indent, $subindent);
      $lastindent = $indent;
      $lastsubindent = $subindent;

    } elsif ($iscloselist) {
      while ($indent < $self->{list_indent} && $indent != $self->{list_sub_indent})
      {
	$self->close_LI();
	$self->close_list();
      }

      # if the new block is not the same as the current list level, we
      # need to close this one and create a new list to hold it.
      if ($listtype ne $self->{listtype}) {
	$self->push_list_state();
	$self->new_list($listtype, $listblock, $indent, $subindent);
      } else {
	$self->new_LI();
      }

      $lastindent = $indent;
      $lastsubindent = $subindent;

    } elsif ($listtype ne $lasttype) {
      $self->close_LI();
      $self->push_list_state();
      $self->new_list($listtype, $listblock, $indent, $subindent);

    } elsif ($isnewLI) {
      $self->close_LI();
      $self->new_LI();
    }

    $self->{LI_text} .= $_;

    $lasttype = $listtype;
    $lastblock = $listblock;
    $lastlinewasblank = $ispbreak;
  }

  $self->close_LI();
  while (@{$self->{list_stack}} > 0) {
    $self->close_LI();
    $self->close_list();
  }

  return $self->output_list_html();
}

sub new_list {
  my ($self, $listtype, $listblock, $ind, $subind) = @_;

  # warn stack()." new_list t=$listtype bl=$listblock ind=$ind subind=$subind";

  $self->{listtype} = $listtype;
  $self->{listblock} = $listblock;
  $self->{list_indent} = $ind;
  $self->{list_sub_indent} = $subind;
  $self->{deferred_LI_close} = '';

  if (!defined $self->{list_html}) {
    $self->{list_html} = [ ];
  }

  $self->new_LI();
}

sub push_list_state {
  my ($self) = @_;

  $self->close_LI();

  my $liststate = {
	'listtype' => $self->{listtype},
	'listblock' => $self->{listblock},
	'list_html' => $self->{list_html},
	'list_indent' => $self->{list_indent},
	'list_sub_indent' => $self->{list_sub_indent},
	'LI_text' => $self->{LI_text},
	'LI_closed' => $self->{LI_closed},
	'LI_contains_p_break' => $self->{LI_contains_p_break},
	'LI_contains_multi_ps' => $self->{LI_contains_multi_ps},
	'deferred_LI_close' => $self->{deferred_LI_close},
  };

  push (@{$self->{list_stack}}, $liststate);
  $self->{list_html} = [ ];

  # warn "push_list_state: pushed listblock=".
  # $liststate->{listblock}." stack=".
  # (scalar @{$self->{list_stack}})."\n";
}

sub pop_list_state {
  my ($self) = @_;

  if ($self->{listblock} == $LIST_ROOT) {
    warn "pop_list_state: popping at ROOT";
    return;		# cannot go any lower
  }

  my $liststate = pop (@{$self->{list_stack}});
  $self->{listblock} = $liststate->{listblock};

  $self->{listtype} = $liststate->{listtype};
  $self->{list_html} = $liststate->{list_html};
  $self->{list_indent} = $liststate->{list_indent};
  $self->{list_sub_indent} = $liststate->{list_sub_indent};
  $self->{LI_text} = $liststate->{LI_text};
  $self->{LI_closed} = $liststate->{LI_closed};
  $self->{LI_contains_p_break} = $liststate->{LI_contains_p_break};
  $self->{LI_contains_multi_ps} = $liststate->{LI_contains_multi_ps};
  $self->{deferred_LI_close} = $liststate->{deferred_LI_close};

  # warn "pop_list_state: popped listblock=".$self->{listblock}."\n";
}

# return to zero state -- ie. no lists at all, just normal paragraphs
sub set_list_stack_empty {
  my ($self) = @_;
  $self->{list_stack} = [ ];
  $self->new_list ('', $LIST_ROOT, 0, 0);
}

sub new_LI {
  my ($self) = @_;

  # warn stack()." new_LI";
  $self->close_LI();
  $self->{LI_text} = '';
  $self->{LI_contains_p_break} = 0;
  $self->{LI_contains_multi_ps} = 0;
  $self->{deferred_LI_close} = 0;
  $self->{LI_closed} = 0;
}

sub _close_LI_impl {
  my ($self, $fullyclose) = @_;

  if ($self->{LI_closed}) { return; }
  $self->{LI_closed} = 1;

  if ($self->{LI_text} eq '') {
    # warn "close_LI: empty text at ".stack();
    return;
  }

  # warn stack()." close_LI: '".$self->{LI_text}."'\n";
  my $start = '';
  my $end = '';
  if ($self->{listblock} == $LIST_NONE || $self->{listblock} == $LIST_ROOT) {
    $start = '<p>'; $end = '</p>';	# not a list
  } elsif ($self->{listblock} == $LIST_UL) {
    $start = '<li>'; $end = '</li>';
  } elsif ($self->{listblock} == $LIST_OL) {
    $start = '<li>'; $end = '</li>';

  } elsif ($self->{listblock} == $LIST_DL) {
    $self->{LI_text} =~ s/^(<dt>.*?<\/dt>)//s;
    $start = $1.'<dd>'; $end = '</dd>';

  } elsif ($self->{listblock} == $LIST_PRE) {
    $start = '<pre>'; $end = '</pre>';
  } elsif ($self->{listblock} == $LIST_BQ && $self->{listtype} =~ /^>/) {
    # looks good in Netscape ;)
    $start = '<blockquote type="cite">'; $end = '</blockquote>';
  } elsif ($self->{listblock} == $LIST_BQ) {
    $start = '<blockquote>'; $end = '</blockquote>';
  }

  my $pstart = '';
  my $pend = '';
  if ($self->{LI_contains_p_break} && $self->{LI_contains_multi_ps}) {
    $pstart = '<p>'; $pend = '</p>';
  } else {
  }

  $self->{LI_text} =~ s/^\s*<\/p><p>//gs;
  $self->{LI_text} =~ s/<\/p><p>\s*$//gs;

  push (@{$self->{list_html}}, $start, $pstart, $self->{LI_text}, $pend);

  # LIST_NONE == normal paragraphs; don't want to embed the list into
  # the <p>...</p> block, unlike when embedding lists into <li>..</li>
  if ($fullyclose || $self->{listblock} == $LIST_NONE
  		|| $self->{listblock} == $LIST_ROOT)
  {
    push (@{$self->{list_html}}, $end);
  } else {
    $self->{deferred_LI_close} = $end;
  }
}

sub finish_LI_without_closing {
  my ($self) = @_;
  $self->_close_LI_impl (0);
}
sub close_LI {
  my ($self) = @_;
  $self->_close_LI_impl (1);
}

sub close_list {
  my ($self) = @_;

  # warn stack()." close_list: block=".$self->{listblock};

  my $start = '';
  my $end = '';
  if ($self->{listblock} == $LIST_NONE || $self->{listblock} == $LIST_ROOT) {
    # not a list
    $start = '<p>'; $end = '</p>';
  } elsif ($self->{listblock} == $LIST_UL) {
    $start = '<ul>'; $end = '</ul>';
  } elsif ($self->{listblock} == $LIST_OL) {
    $self->{listtype} =~ /^(.)/;
    my $attrs = "type=\"$1\"";
    $start = '<ol '.$attrs.'>'; $end = '</ol>';

  } elsif ($self->{listblock} == $LIST_DL) {
    $start = '<dl>'; $end = '</dl>';
  } elsif ($self->{listblock} == $LIST_PRE) {
    # not start and end tags needed, just item tags
  } elsif ($self->{listblock} == $LIST_BQ) {
    # not start and end tags needed, just item tags
  }

  my @output = ($start, @{$self->{list_html}}, $end);
  $self->pop_list_state();
  push (@{$self->{list_html}}, @output);
  # warn "after list close: html='".join ('', @{$self->{list_html}})."'\n";

  if ($self->{deferred_LI_close}) {
    push (@{$self->{list_html}}, $self->{deferred_LI_close});
    $self->{deferred_LI_close} = '';
  }
}

sub output_list_html {
  my ($self) = @_;
  $_ = join ('', @{$self->{list_html}});
  s/<p><\/p>//gs;
  s/<p><p>/<p>/gs;
  s/(?:<p>)+\s*<(table|blockquote)>/<$1>/gis;
  s/<\/(table|blockquote)>\s*(?:<\/p>)+/<\/$1>/gis;
  s/<\/p><\/p>/<\/p>/gs;

  # oops, don't wrap headings in P tags
  s/<p>([^\n]+<h\d+>[^\n]+<\/h\d+>[^\n]+\n)<\/p>/$1/gs;

  $_;
}

sub stack {
  my ($package, $filename, $line) = caller (1);
  return "$filename:$line";
}
