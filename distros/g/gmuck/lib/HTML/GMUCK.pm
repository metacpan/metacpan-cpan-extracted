package HTML::GMUCK;

# $Id: GMUCK.pm,v 1.24 2007/04/01 20:26:55 scop Exp $

use strict;

require 5.006;

use vars qw($VERSION $Tag_End $Tag_Start $Non_Tag_End
            $URI_Attrs $End_Omit $All_Elems
            $Min_Elems $Compat_Elems $Min_Attrs $MIME_Type @MIME_Attrs
            %Req_Attrs $All_Attrs $Depr_Elems @Depr_Attrs @Int_Attrs
            @Length_Attrs @Fixed_Attrs);

use Carp qw(carp);

no warnings 'utf8';

BEGIN
{

  $VERSION = sprintf("%d.%02d", q$Revision: 1.24 $ =~ /(\d+)\.(\d+)/);

  # --- Preload regexps.

  my $tmp = '';
  my %tmp = ();

  if (! do 'HTML/GMUCK/regexps.pl') {
    my $err = $! || $@;
    die "Error reading HTML/GMUCK/regexps.pl: $err";
  }

}

# ----- Constructors -------------------------------------------------------- #

sub new
{
  my ($class, %attr) = @_;

  my $this = bless({
                    _mode         => undef,
                    _xml          => undef,
                    _xhtml        => undef,
                    _html         => undef,
                    _tab_width    => undef,
                    _num_errors   => undef,
                    _num_warnings => undef,
                    _quote        => undef,
                    _min_attrs    => undef,
                   },
                   (ref($class) || $class));

  my $tab_width = delete($attr{tab_width});
  $tab_width = 4 unless defined($tab_width);
  $this->tab_width($tab_width) or $this->tab_width(4);

  my $mode = delete($attr{mode});
  $mode = 'XHTML' unless defined($mode);
  $this->mode($mode) or $this->mode('XHTML');

  my $quote = delete($attr{quote});
  $this->quote(defined($quote) ? $quote : '"');

  $this->min_attributes(delete($attr{min_attributes}));

  $this->reset();

  if (my @unknown = keys(%attr)) {
    carp("** Unrecognized attributes: " . join(',', sort(@unknown)));
  }

  return $this;
}

# ---------- Check: deprecated ---------------------------------------------- #

sub deprecated { return shift->_wrap('_deprecated', @_);}

sub _deprecated
{
  my ($this, $line) = @_;
  my @errors = ();

  while ($line =~ /\b(document\.location)\b/go) {
    push(@errors, { col  => $this->_pos($line, pos($line) - length($1)),
                    type => 'W',
                    mesg =>
                    'document.location is deprecated, use window.location ' .
                    'instead',
                  },
        );
  }

  # ---

  return @errors unless $this->{_html};

  # Optimization.
  return @errors unless $line =~ $Tag_Start;

  # ---

  while ($line =~ /
         <
         (\/?)
         (
          ($Depr_Elems)
          (?:$|$Tag_End|\s)
         )
         /giox) {
    push(@errors, { col  => $this->_pos($line, pos($line) - length($2)),
                    elem => $3,
                    mesg => 'deprecated element' . ($1 ? ' end' : ''),
                    type => 'W',
                  },
        );
  }

  # ---

  foreach my $re (@Depr_Attrs) {

    while ($line =~ /$re/g) {
      my ($m, $elem, $attr) = ($1, $2, $3);
      if ($attr) {
        push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                        elem => $elem,
                        attr => $attr,
                        type => 'W',
                        mesg => 'deprecated attribute for this element',
                      },
            );
      }
    }
  }

  return @errors;
}

# ----- Check: attributes --------------------------------------------------- #

sub attributes { return shift->_wrap('_attributes', @_); }

sub _attributes
{
  my ($this, $line) = @_;
  return () unless $this->{_html};

  my @errors = ();

  # ---

  my $type = $this->{_xhtml} ? 'E' : 'W';

  # BUG: Does not catch non-lowercase minimized attributes, like CHECKED.
  while ($line =~ /
         (?:^\s*|(?<=[\w\"\'])\s+)
         (
          ($All_Attrs)
          =
          (.\S?) # Would like to see ['"], possibly backslashed.
         )
         /giox) {

    my ($pos, $att, $q) = (pos($line) - length($1), $2, $3);

    if ($att ne lc($att)) {
      push(@errors, { col  => $this->_pos($line, $pos),
                      attr => $att,
                      type => $type,
                      mesg => 'non-lowercase attribute',
                    },
          );
    }

    if (my $tq = $this->{_quote}) {
      my $pos = $this->_pos($line, $pos + length($att) + 1);
      if ($q =~ /\\?([\"\'])/o) {
        if ($1 ne $tq) {
          push(@errors, { col  => $pos,
                          type => 'W',
                          attr => $att,
                          mesg => "quote attribute values with $tq",
                        },
              );
        }
      } else {
        push(@errors, { col  => $pos,
                        attr => $att,
                        type => 'W',
                        mesg => 'unquoted value',
                      },
            );
      }
    }
  }

  # ---

  # Optimization.
  return @errors unless $line =~ /$Tag_Start\w../o;

  # ---

  foreach my $re (@Int_Attrs) {

    my $msg = 'value should be an integer: "%s"';

    while ($line =~ /$re/g) {
      my ($m, $el, $att, $q, $val) = ($1, $2, $3, $4, $5);
      my $lel = lc($el);
      my $latt = lc($att);

      if ($val !~ /^\d+$/o &&
          $val !~ /[\\\$\(\[]/o   # bogus protection
         ) {

        # Special case: img->border only in HTML 4
        next if ($this->{_xhtml} && $lel eq 'img' && $latt eq 'border');

        push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                        type => 'E',
                        mesg => sprintf($msg, $val),
                        elem => $el,
                        attr => $att,
                      },
            );
      }
    }
  }

  # ---

  foreach my $re (@Length_Attrs) {

    my $msg = 'value should be an integer or a percentage: "%s"';

    while ($line =~ /$re/g) {

      my ($m, $el, $att, $q, $val) = ($1, $2, $3, $4, $5);

      if ($val !~ /^\d+%?$/o &&
          $val !~ /[\\\$\(\[]/o   # bogus protection
         ) {

        push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                        type => 'E',
                        mesg => sprintf($msg, $val),
                        elem => $el,
                        attr => $att,
                      },
            );
      }
    }
  }

  # ---

  foreach (@Fixed_Attrs) {

    my ($re, $vre, $vals) = @$_;
    $vre = $this->{_xml} ? qr/$vre/ : qr/$vre/i;
    my $msg = 'invalid value: "%s", should be %s"%s"';

    while ($line =~ /$re/g) {

      my ($m, $el, $att, $q, $val) = ($1, $2, $3, $4, $5);

      if ($val !~ $vre &&
          $val !~ /[\\\$\(\[]/o    # bogus protection
         ) {

        my $latt = lc($att);
        my $lel  = lc($el);

        # Special case: html->xmlns and pre,script,style->xml:space XHTML-only
        next if (! $this->{_xhtml} &&
                 (($lel eq 'html' && $latt eq 'xmlns') ||
                  ($latt eq 'xml:space' && $lel =~ /^(pre|s(cript|tyle))$/o)));

        push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                        type => 'E',
                        mesg => sprintf($msg, $val,
                                        ($vals =~ /\|/o) ? 'one of ' : '',
                                        $vals),
                        elem => $el,
                        attr => $att,
                      },
            );
      }
    }
  }

  # ---

  #
  # Note that minimized attributes are forbidden only in XHTML, but it
  # is legal to have them in HTML too.
  #
  # Not doing this check inside <>'s would result in too much bogus.
  #
  if ($this->{_min_attrs}) {
    while ($line =~ /
           <
           $Non_Tag_End+?
           \s
           (
            ($Min_Attrs)
            ([=\s]|$Tag_End)
           )
           /giox) {
      my ($m, $attr, $eq) = ($1, $2, $3);
      if ($eq ne '=') {
        push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                        attr => $attr,
                        type => $type,
                        mesg => 'minimized attribute',
                      },
            );
      }
    }
  }

  # ---

  while (my ($attr, $re) = each(%Req_Attrs)) {

    my $msg = 'missing required attribute: "%s"';

    # Parens: 1: for pos(), 2:element, 3: attribute (or undef if not found)
    while ($line =~ /$re/g) {

      my ($m, $el, $att) = ($1, $2, $3);

      if (! $att) {

        my $lel  = lc($el);

        # Special case: @name not required for input/@type's submit and reset
        next if ($lel eq 'input' && $attr eq 'name' &&
                 # TODO: this is crap
                 $line =~ /\stype=(\\?[\"\'])?(submi|rese)t\b/io);

        # Special case: map/@id required only in XHTML 1.0+
        next if ($lel eq 'map' && $attr eq 'id' && ! $this->{_xhtml});

        push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                        type => 'E',
                        mesg => sprintf($msg, $attr),
                        elem => $el,
                      },
            );
      }
    }
  }

  return @errors;
}

# ----- Check: MIME types --------------------------------------------------- #

sub mime_types { return shift->_wrap('_mime_types', @_); }

sub _mime_types
{
  my ($this, $line) = @_;
  return () unless $this->{_html};

  # Optimization. "<a type=" is the shortest we know nowadays.
  return () unless $line =~ /$Tag_Start.{6}/o;

  my @errors = ();
  my $msg = 'bad media type: "%s"';
  my $jsmsg =
    'not recommended media type: "%s", see RFC 4329 (and also CAVEATS in the HTML::GMUCK manual page)';

  foreach my $re (@MIME_Attrs) {

    while ($line =~ /$re/g) {

      my ($elem, $attr, $m, $mtype) = ($1, $2, $4, $5);
      my $pos = $this->_pos($line, pos($line) - length($m));

      if ($mtype !~ $MIME_Type) {
        push(@errors, { col  => $pos,
                        type => 'E',
                        elem => $elem,
                        attr => $attr,
                        mesg => sprintf($msg, $mtype),
                      },
            );
      } elsif (lc($elem) eq 'script' &&
               $mtype =~ /(ecm|jav)ascript/io &&
               lc($mtype) !~ '^application/(ecm|jav)ascript$') {
        push(@errors, { col  => $pos,
                        type => 'W',
                        elem => $elem,
                        attr => $attr,
                        mesg => sprintf($jsmsg, $mtype),
                      },
            );
      }
    }
  }

  return @errors;
}

# ----- Check: elements ----------------------------------------------------- #

sub elements { return shift->_wrap('_elements', @_); }

sub _elements
{
  my ($this, $line) = @_;
  return () unless $this->{_html};

  my @errors = ();

  # ---

  my $type = $this->{_xhtml} ? 'E' : 'W';
  my $msg = 'non-lowercase element%s';

  while ($line =~ /
         <
         (\/?)
         (
          ($All_Elems)
          (\s|$Tag_End|\Z)   # \Z) because $) would screw my indentation :)
         )
         /giox) {
    my ($slash, $pos, $elem) = ($1, pos($line) - length($2), $3);
    if ($elem ne lc($elem)) {
      push(@errors, { col  => $this->_pos($line, $pos),
                      type => $type,
                      elem => $elem,
                      mesg => sprintf($msg, ($slash ? ' end' : '')),
                    },
          );
    }
  }

  # ---

  $msg = 'missing end tag';

  while ($line =~ /
         <
         (
          ($End_Omit)
          .*?
          $Tag_End
          [^<]*
          <
          (.?)
          ($End_Omit)
         )
         /giox) {
    my ($m, $start, $slash, $end) = ($1, $2, $3, $4);
    if ((lc($start) eq lc($end) && $slash ne '/') ||
        # TODO: this needs tuning.  See t/002endtag.t, line 6.
        (lc($start) ne lc($end))) {
      push(@errors, { col  => $this->_pos($line, pos($line) - length($m)),
                      mesg => $msg,
                      elem => $start,
                      type => 'W',
                    },
          );
    }
  }

  # ---

  # We also allow a backslashed "/", they're common in eg. Perl regexps.
  # Consider
  #   $foo =~ s/bar/baz<br \/>/;
  while ($line =~ /
         <                # TODO: Do we really need to see a known
         ($All_Elems)     #       element here?
         .*?
         (\s?\\?\/?($Tag_End))
         /giox) {
    my ($el, $end, $m) = ($1, $2);
    my $pos = $this->_pos($line, pos($line) - length($3));
    if ($end =~ m|/>$|o) {
      if ($this->{_xhtml} &&
          $el !~ /^$Compat_Elems$/io &&   # These don't apply here, see later.
          $end !~ m|\s\\?/|o) {
        push(@errors, { col  => $pos,
                        type => 'W',
                        mesg => 'use space before "/>" for compatibility',
                        elem => $el,
                      },
            );
      } elsif (! $this->{_xml} && $end =~ m|/>$|o) {
        push(@errors, { col  => $pos,
                        type => 'E',
                        mesg => 'element end "/>" is allowed in X(HT)ML only',
                        elem => $el,
                      },
            );
      }
    }
  }

  # ---

  # Check for missing " />".
  if ($this->{_xhtml}) {

    while ($line =~ /
           <
           ($Min_Elems)
           .*?
           (\/?$Tag_End)
           /giox) {
      my ($el, $end) = ($1, $2);
      if ($end ne '/>') {
        push(@errors, { col  => $this->_pos($line, pos($line) - length($end)),
                        elem => $el,
                        mesg => 'missing " />"',
                        type => 'E',
                      },
            );
      }
    }

    while ($line =~ /
           <
           ($Compat_Elems)
           .*?
           (\s?.?$Tag_End)
           /giox) {
      my ($el, $end) = ($1, $2);
      $msg = 'use "<%s></%s>" instead of <%s for compatibility';
      if ($end =~ m|(\s?/>)$|o) {
        my $e = lc($el);
        push(@errors, { col  => $this->_pos($line, pos($line) - length($end)),
                        elem => $el,
                        mesg => sprintf($msg, $e, $e, $e . $1),
                        type => 'W',
                      },
            );
      }
    }
  }

  return @errors;
}

# ----- Check: entities ----------------------------------------------------- #

# Check for unterminated entities in URIs (usually & instead of &amp;).
sub entities { return shift->_wrap('_entities', @_);}

sub _entities
{
  my ($this, $line) = @_;
  return () unless $this->{_html};

  # Optimization. "src=&" is the shortest we know of.
  return () unless $line =~ /\w{3}=./;

  my @errors = ();
  my $msg = 'unterminated entity: %s';

  while ($line =~ /
         (?:^|\s)
         ($URI_Attrs)
         =
         (
          (.+?)
          (?:
           (?<!\[%) # Protect Template Toolkit's "[% ".
           \s       # A space terminates here.
           (?!%\])  # Protect Template Toolkit's " %]".
           |
           $Tag_End
          )
         )
         /giox) {

    my ($attr, $pos, $val) = ($1, pos($line) - length($2), $3);

    while ($val =~ /(&([^;]*?))[=\"\'\#\s]/go) {
      push(@errors, { col =>
                      $this->_pos($line, $pos + pos($val) - length($2) - 1),
                      type => 'E',
                      mesg => sprintf($msg, $1),
                      attr => $attr,
                    },
          );
    }
  }

  return @errors;
}

# ----- Check: DOCTYPE ------------------------------------------------------ #

# Check for doctype declaration errors.
sub doctype { return shift->_wrap('_doctype', @_); }

sub _doctype
{
  my ($this, $line) = @_;
  my @errors = ();

  while ($line =~ /<!((DOCTYPE)\s+($Non_Tag_End+)>)/gio) {
    my ($pos, $dt, $rest) = (pos($line) - length($1), $2, $3);
    if ($dt ne "DOCTYPE") {
      push(@errors, { col  => $this->_pos($line, $pos),
                      type => 'E',
                      mesg => "DOCTYPE must be uppercase: $dt",
                    },
          );

      $pos = pos($line) - length($rest) - 1;

      if ($this->{_html} &&
          (my ($p1, $html, $t) = ($rest =~ /^((html)\s+)(\w+)?/io))) {

        # TODO: better message, maybe this should not be XHTML-only.
        if ($this->{_xhtml} && $html ne 'html') {
          my $msg = "\"html\" in DOCTYPE should be lowercase in XHTML: $html";
          push(@errors, { col  => $this->_pos($line, $pos),
                          type => 'W',
                          mesg => $msg,
                        },
              );
        }

        $pos += length($p1);

        if ($t =~ /^(PUBLIC|SYSTEM)$/io) {
          if ($t ne uc($t)) {
            my $msg = uc($t) . " must be uppercase: \"$t\"";
            push(@errors, { col  => $this->_pos($line, $pos),
                            type => 'E',
                            mesg => $msg,
                          },
                );

            if ($this->{_xml} && uc($t) eq 'PUBLIC') {
              # TODO: In XML, you can't declare public ID without
              # system ID.  Check this.
            }
          }
        } else {
          my $msg = "PUBLIC or SYSTEM should follow root element name: \"$t\"";
          push(@errors, { col  => $this->_pos($line, $pos),
                          type => 'W',
                          mesg => $msg,
                        },
              );
        }
      }
    }
  }

  return @errors;
}


# ---------- Accessors and mutators ----------------------------------------- #

sub mode
{
  my ($this, $mode) = @_;
  if ($mode) {
    my $was_xml = $this->{_xml};
    if ($mode eq 'HTML') {
      $this->{_xhtml} = 0;
      $this->{_xml}   = 0;
      $this->{_html}  = 1;
      $this->{_mode}  = $mode;
    } elsif ($mode eq 'XML') {
      $this->{_xhtml} = 0;
      $this->{_xml}   = 1;
      $this->{_html}  = 0;
      $this->{_mode}  = $mode;
      $this->quote('"') unless $was_xml;
    } elsif ($mode eq 'XHTML') {
      $this->{_xhtml} = 1;
      $this->{_xml}   = 1;
      $this->{_html}  = 1;
      $this->{_mode}  = $mode;
      $this->quote('"') unless $was_xml;
    } else {
      carp("** Mode must be one of XHTML, HTML, XML (resetting to XHTML)");
      $this->mode('XHTML');
    }
  }
  return $this->{_mode};
}

sub tab_width
{
  my ($this, $tw) = @_;
  if (defined($tw)) {
    if ($tw > 0) {
      $this->{_tab_width} = sprintf("%.0f", $tw); # Uh. Integers please.
    } else {
      carp("** TAB width must be > 0");
    }
  }
  return $this->{_tab_width};
}

sub min_attributes
{
  my ($this, $minattr) = @_;
  if (defined($minattr)) {
    if (! $minattr && $this->{_xml}) {
      carp("** Will not disable minimized attribute checks in " .
           $this->mode() . " mode");
    } else {
      $this->{_min_attrs} = $minattr;
    }
  }
  return $this->{_min_attrs};
}

sub stats
{
  my $this = shift;
  return ($this->{_num_errors}, $this->{_num_warnings});
}

sub reset
{
  my $this = shift;
  my ($e, $w) = $this->stats();
  $this->{_num_errors} = 0;
  $this->{_num_warnings} = 0;
  return ($e, $w);
}

sub quote
{
  my ($this, $q) = @_;
  if (defined($q)) {
    # We always allow " and ', and empty when non-xml, refuse others.
    my $is_ok = ($q eq '"'       || $q eq "'"   );
    $is_ok  ||= (! $this->{_xml} && ! length($q));
    if ($is_ok) {
      $this->{_quote} = $q;
    } else {
      carp("** Refusing to set quote to ", ($q || '[none]'),
           " when in " . $this->mode() . " mode");
    }
  }
  return $this->{_quote};
}

sub full_version
{
  return "HTML::GMUCK $VERSION";
}

# ---------- Utility methods ------------------------------------------------ #

sub _pos
{
  my ($this, $line, $pos) = @_;
  $pos = 0 unless (defined($pos) && $pos > 0);
  if ($this->{_tab_width} > 1 && $pos > 0) {
    my $pre = substr($line, 0, $pos);
    while ($pre =~ /\t/g) {
      $pos += $this->{_tab_width} - 1;
    }
  }
  return $pos;
}

sub _wrap
{
  my ($this, $method, @lines) = @_;
  my @errors = ();
  my $ln = 0;

  for (my $ln = 0; $ln < scalar(@lines); $ln++) {
    foreach my $err ($this->$method($lines[$ln])) {
      $err->{line}   = $ln;
      if (! $err->{mesg}) {
        $err->{mesg} = "no error message, looks like you found a bug";
        carp("** " . ucfirst($err->{mesg}));
      }
      $err->{col}  ||= 0;
      if (! $err->{type}) {
        carp("** No error type, looks like you found a bug");
        $err->{type} = '?';
      }
      push(@errors, $err);
      if ($err->{type} eq 'W') {
        $this->{_num_warnings}++;
      } else {
        $this->{_num_errors}++;
      }
    }
  }

  return @errors;
}

1;
