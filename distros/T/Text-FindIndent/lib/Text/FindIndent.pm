package Text::FindIndent;
# -*- mode: Perl -*-
# Emacs mode is necessary for https://github.com/github/linguist/issues/2458

use 5.00503;
use strict;

use vars qw{$VERSION};
BEGIN {
  $VERSION = '0.12';
}

use constant MAX_LINES => 500;

sub parse {
  my $class = shift;
  my $text  = shift;

  my %opts = @_;
  my $textref = ref($text) ? $text : \$text; # accept references, too

  my $skip_pod = $opts{skip_pod};
  my $first_level_indent_only = $opts{first_level_indent_only}?1:0;

  my %modeline_settings;

  my %indentdiffs;
  my $lines                 = 0;
  my $prev_indent           = undef;
  my $skip                  = 0;
  my $in_pod                = 0;

  # Do we have emacs smart comments?
  $class->_check_emacs_local_variables_at_file_end($textref, \%modeline_settings);
  if (exists $modeline_settings{softtabstop} and exists $modeline_settings{usetabs}) {
    $modeline_settings{mixedmode} = $modeline_settings{usetabs}
      if not defined $modeline_settings{mixedmode};
    return(
      ($modeline_settings{mixedmode} ? "m" : "s")
      . $modeline_settings{softtabstop}
    );
  }
  elsif (exists $modeline_settings{tabstop} and $modeline_settings{usetabs}) {
    return( ($modeline_settings{mixedmode} ? "m" : "t") . $modeline_settings{tabstop} );
  }
  elsif (exists $modeline_settings{tabstop} and exists $modeline_settings{usetabs}) {
    return( "s" . $modeline_settings{tabstop} );
  }

  my $next_line_braces_pos_plus_1;
  my $prev_indent_type = undef;
  while ($$textref =~ /\G([ \t]*)([^\r\n]*)[\r\n]+/cgs) {
    my $ws       = $1;
    my $rest     = $2;
    my $fullline = "$ws$rest";
    $lines++;
    
    # check emacs start line stuff with some slack (shebang)
    my $changed_modelines;
    if ($lines < 3) {
      $changed_modelines = $class->_check_emacs_local_variables_first_line($fullline, \%modeline_settings);
    }

    # Do we have emacs smart comments?
    # ==> Done once at start
    #$class->_check_emacs_local_variables($fullline, \%modeline_settings);

    # Do we have vim smart comments?
    if ($class->_check_vim_modeline($fullline, \%modeline_settings) || $changed_modelines) {
      if (exists $modeline_settings{softtabstop} and exists $modeline_settings{usetabs}) {
        $modeline_settings{mixedmode} = $modeline_settings{usetabs}
          if not defined $modeline_settings{mixedmode};
        return(
          ($modeline_settings{mixedmode} ? "m" : "s")
          . $modeline_settings{softtabstop}
        );
      }
      elsif (exists $modeline_settings{tabstop} and $modeline_settings{usetabs}) {
        return( ($modeline_settings{mixedmode} ? "m" : "t") . $modeline_settings{tabstop} );
      }
      elsif (exists $modeline_settings{tabstop} and exists $modeline_settings{usetabs}) {
        return( "s" . $modeline_settings{tabstop} );
      }
    }

    if ($lines > MAX_LINES) {
      next;
    }

    if ($skip) {
      $skip--;
      next;
    }

    if ($skip_pod and $ws eq '' and substr($rest, 0, 1) eq '=') {
      if (not $in_pod and $rest =~ /^=(?:head\d|over|item|back|pod|begin|for|end)/ ) {
        $in_pod = 1;
      }
      elsif ($in_pod and $rest =~ /^=cut/) {
        $in_pod = 0;
      }

    }
    next if $in_pod or $rest eq '';

    if ($ws eq '') {
      $prev_indent = $ws;
      next;
    }

    # skip next line if the last char is a backslash.
    # Doesn't matter for Perl, but let's be generous!
    $skip = 1 if $rest =~ /\\$/;
    
    # skip single-line comments
    next if $rest =~ /^(?:#|\/\/|\/\*)/; # TODO: parse /* ... */!

    if ($next_line_braces_pos_plus_1) {
      if ($next_line_braces_pos_plus_1==_length_with_tabs_converted($ws)) {
        next;
      }
      $next_line_braces_pos_plus_1=0;
    } else {
      if ($rest =~ /=> \{$/) { #handle case where hash keys and values are indented by braces pos + 1
        $next_line_braces_pos_plus_1=_length_with_tabs_converted($ws)+length($rest);
      }
    }

    if ($first_level_indent_only and $prev_indent ne '') {
      next;
    }

    if ($prev_indent eq $ws) {
      if ($prev_indent_type) {
        $indentdiffs{$prev_indent_type}+=0.01;
        #coefficient is not based on data, so change if you think it should be different
      }
      next;
    }

    # prefix-matching higher indentation level
    if ($ws =~ /^\Q$prev_indent\E(.+)$/) {
      my $diff = $1;
      my $indent_type=_analyse_indent_diff($diff);
      $indentdiffs{$indent_type}++;
      $prev_indent_type=$indent_type;
      $prev_indent = $ws;
      next;
    }

    # prefix-matching lower indentation level
    if ($prev_indent =~ /^\Q$ws\E(.+)$/) {
      my $diff = $1;
      #_grok_indent_diff($diff, \%indentdiffs);
      my $indent_type=_analyse_indent_diff($diff);
      $indentdiffs{$indent_type}++;
      $prev_indent_type=$indent_type;
      $prev_indent = $ws;
      next;
    }

    # at this point, we're desperate!
    my $prev_spaces = $prev_indent;
    $prev_spaces =~ s/[ ]{0,7}\t/        /g;
    my $spaces = $ws;
    $spaces =~ s/[ ]{0,7}\t/        /g;
    my $len_diff = length($spaces) - length($prev_spaces);
    if ($len_diff) {
      $len_diff = abs($len_diff);
      $indentdiffs{"m$len_diff"}++;
    }
    $prev_indent = $ws;
        
  } # end while lines

  # nothing found
  return 'u' if not keys %indentdiffs;

  my $max = 0;
  my $maxkey = undef;
  while (my ($key, $value) = each %indentdiffs) {
    $maxkey = $key, $max = $value if $value > $max;
  }

  if ($maxkey =~ /^s(\d+)$/) {
    my $mixedkey = "m" . $1;
    my $mixed = $indentdiffs{$mixedkey};
    if (defined($mixed) and $mixed >= $max * 0.2) {
      $maxkey = $mixedkey;
    }
  }

  # fallback to emacs styles which are guesses only
  foreach my $key (qw(softtabstop tabstop usetabs)) {
    if (not exists $modeline_settings{$key}
        and exists $modeline_settings{"style_$key"}) {
      $modeline_settings{$key} = $modeline_settings{"style_$key"};
    }
  }

  if (exists $modeline_settings{softtabstop}) {
    $maxkey =~ s/\d+/$modeline_settings{softtabstop}/;
  }
  elsif (exists $modeline_settings{tabstop}) {
    $maxkey =~ s/\d+/$modeline_settings{tabstop}/;
  }
  if (exists $modeline_settings{usetabs}) {
    if ($modeline_settings{usetabs}) {
      $maxkey =~ s/^(.)(\d+)$/$1 eq 'u' ? "t8" : ($2 == 8 ? "t8" : "m$2")/e;
    }
    else {
      $maxkey =~ s/^./m/;
    }
  }

  # mixedmode explicitly asked for
  if ($modeline_settings{mixedmode}) {
    $maxkey =~ s/^./m/;
  }

  return $maxkey;
}

sub _length_with_tabs_converted {
    my $str=shift;
    my $tablen=shift || 8;
    $str =~ s/( +)$//;
    my $trailing_spaces = $1||'';
    $str =~ s/ +//g; #  assume the spaces are all contained in tabs!
    return length($str)*$tablen+length($trailing_spaces);
}

sub _grok_indent_diff {
  my $diff = shift;
  my $indentdiffs = shift;

  if ($diff =~ /^ +$/) {
    $indentdiffs->{"s" . length($diff)}++;
  }
  elsif ($diff =~ /^\t+$/) {
    $indentdiffs->{"t8"}++; # we can't infer what a tab means. Or rather, we need smarter code to do it
  }
  else { # mixed!
    $indentdiffs->{"m" . _length_with_tabs_converted($diff)}++;
  }
}

sub _analyse_indent_diff {
  my $diff = shift;

  if ($diff =~ /^ +$/) {
    return "s" . length($diff);
  }
  elsif ($diff =~ /^\t+$/) {
    return "t8"; # we can't infer what a tab means. Or rather, we need smarter code to do it
  }
  else { # mixed!
    return "m" . _length_with_tabs_converted($diff);
  }
}

{
  # the vim modeline regexes
  my $VimTag = qr/(?:ex|vim?(?:[<=>]\d+)?):/;
  my $OptionArg = qr/[^\s\\]*(?:\\[\s\\][^\s\\]*)*/;
  my $VimOption = qr/
    \w+(?:=)?$OptionArg
  /xo;

  my $VimModeLineStart = qr/(?:^|\s+)$VimTag/o;

  # while technically, we match against $VimModeLineStart before,
  # IF there is a vim modeline, we don't need to optimize
  my $VimModelineTypeOne = qr/
    $VimModeLineStart
    \s*
    ($VimOption
      (?:
        (?:\s*:\s*|\s+)
        $VimOption
      )*
    )
    \s*$
  /xo;
  
  my $VimModelineTypeTwo = qr/
    $VimModeLineStart
    \s*
    set?\s+
    ($VimOption
      (?:\s+$VimOption)*
    )
    \s*
    :
  /xo;

  sub _check_vim_modeline {
    my $class = shift;
    my $line = shift;
    my $settings = shift;

# Quoting the vim docs:
# There are two forms of modelines.  The first form:
#	[text]{white}{vi:|vim:|ex:}[white]{options}
#
#[text]		any text or empty
#{white}		at least one blank character (<Space> or <Tab>)
#{vi:|vim:|ex:}	the string "vi:", "vim:" or "ex:"
#[white]		optional white space
#{options}	a list of option settings, separated with white space or ':',
#		where each part between ':' is the argument for a ":set"
#		command (can be empty)
#
#Example:
#   vi:noai:sw=3 ts=6 ~
#   The second form (this is compatible with some versions of Vi):
#
#	[text]{white}{vi:|vim:|ex:}[white]se[t] {options}:[text]
#
#[text]		any text or empty
#{white}		at least one blank character (<Space> or <Tab>)
#{vi:|vim:|ex:}	the string "vi:", "vim:" or "ex:"
#[white]		optional white space
#se[t]		the string "set " or "se " (note the space)
#{options}	a list of options, separated with white space, which is the
#		argument for a ":set" command
#:		a colon
#[text]		any text or empty
#
#Example:
#   /* vim: set ai tw=75: */ ~
#
   
    my @options;
    return if $line !~ $VimModeLineStart;

    if ($line =~ $VimModelineTypeOne) {
      push @options, split /(?!<\\)[:\s]+/, $1;
    }
    elsif ($line =~ $VimModelineTypeTwo) {
      push @options, split /(?!<\\)\s+/, $1;
    }
    else {
      return;
    }

    return if not @options;

    my $changed = 0;
    foreach (@options) {
      /s(?:ts|ofttabstop)=(\d+)/i and $settings->{softtabstop} = $1, $changed = 1, next;
      /t(?:s|abstop)=(\d+)/i and $settings->{tabstop} = $1, $changed = 1,  next;
      /((?:no)?)(?:expandtab|et)/i and $settings->{usetabs} = (defined $1 and $1 =~ /no/i ? 1 : 0), $changed = 1, next;
    }
    return $changed;
  }
}




{
# lookup for emacs tab modes
  my %tabmodelookup = (
   t   => sub {
     $_[0]->{mixedmode} = 1;
     $_[0]->{usetabs} = 1;
   },
   nil => sub {
     delete $_[0]->{mixedmode};
     $_[0]->{usetabs} = 0;
   },
  );

# lookup for emacs styles
  my %stylelookup = (
   kr => sub {
     $_[0]->{style_softtabstop} = 4;
     $_[0]->{style_tabstop} = 8;
     $_[0]->{style_usetabs} = 1;
   },
   linux => sub {
     $_[0]->{style_softtabstop} = 8;
     $_[0]->{style_tabstop} = 8;
     $_[0]->{style_usetabs} = 1;
   },
   'gnu' => sub {
     $_[0]->{style_softtabstop} = 2;
     $_[0]->{style_tabstop} = 8;
     $_[0]->{style_usetabs} = 1;
   },
   'bsd' => sub {
     $_[0]->{style_softtabstop} = 4;
     $_[0]->{style_tabstop} = 8;
     $_[0]->{style_usetabs} = 1;
   },
   'ellemtel' => sub {
     $_[0]->{style_softtabstop} = 3;
     $_[0]->{style_tabstop} = 3;
     $_[0]->{style_usetabs} = 0;
   },
   'java' => sub {
     $_[0]->{style_softtabstop} = 4;
     $_[0]->{style_tabstop} = 8;
   },
  );
  $stylelookup{'k&r'} = $stylelookup{kr};
  $stylelookup{'bsd'} = $stylelookup{kr};
  $stylelookup{'whitesmith'} = $stylelookup{kr};
  $stylelookup{'stroustrup'} = $stylelookup{kr};

  my $FirstLineVar = qr/[^\s:]+/;
  my $FirstLineValue = qr/[^;]+/; # dumb
  my $FirstLinePair = qr/\s*$FirstLineVar\s*:\s*$FirstLineValue;/o;
  my $FirstLineRegexp = qr/-\*-\s*mode:\s*[^\s;]+;\s*($FirstLinePair+)\s*-\*-/o;
  
  
  sub _check_emacs_local_variables_first_line {
    my $class = shift;
    my $line = shift;
    my $settings = shift;

# on first line (second if there is a shebang):
#     -*- mode: $MODENAME; $VARNAME: $VALUE; ... -*-
# ($FOO is not a literal)
# Example with a Lisp comment:
# ;; -*- mode: Lisp; fill-column: 75; comment-column: 50; -*-


    my $changed = 0;
    if ($line =~ $FirstLineRegexp) {
      my @pairs = split /\s*;\s*/, $1;
      foreach my $pair (@pairs) {
        my ($key, $value) = split /\s*:\s*/, $pair, 2;
        if ($key eq 'tab-width') {
          $settings->{tabstop} = $value;# FIXME: check var
          $changed = 1;
        }
        elsif ($key eq 'indent-tabs-mode') {
          $tabmodelookup{$value}->($settings), $changed = 1 if defined $tabmodelookup{$value};
        }
        elsif ($key eq 'c-basic-offset') {
          $settings->{tabstop} ||= $value; # tab-width takes precedence!?
          $changed = 1;
        }
        elsif ($key eq 'style') { # this is quite questionable practice...
          $stylelookup{$value}->($settings), $changed = 1 if defined $stylelookup{$value};
        }
      }
    }

    # do this only as a LAST resort!
    #$settings->{tabstop}     = $settings->{style_tabstop}     if not exists $settings->{tabstop};
    #$settings->{softtabstop} = $settings->{style_softtabstop} if not exists $settings->{softtabstop};
    #$settings->{usetabs}     = $settings->{style_usetabs}     if not exists $settings->{usetabs};

    return $changed;
  }

  sub _check_emacs_local_variables {
    my $class = shift;
    my $line = shift;
    my $settings = shift;

# A local variables list goes near the end of the file, in the last page.[...]
# The local variables list starts with a line containing the string `Local Variables:',
# and ends with a line containing the string `End:'. In between come the variable names
# and values, one set per line, as `variable: value'. The values are not evaluated;
# they are used literally. If a file has both a local variables list and a `-*-'
# line, Emacs processes everything in the `-*-' line first, and everything in the
# local variables list afterward.
# 
# Here is an example of a local variables list:
# 
#     ;; Local Variables: **
#     ;; mode:lisp **
#     ;; comment-column:0 **
#     ;; comment-start: ";; "  **
#     ;; comment-end:"**" **
#     ;; End: **
# 
# Each line starts with the prefix `;; ' and each line ends with the suffix ` **'.
# Emacs recognizes these as the prefix and suffix based on the first line of the
# list, by finding them surrounding the magic string `Local Variables:'; then it
# automatically discards them from the other lines of the list.
# 
# The usual reason for using a prefix and/or suffix is to embed the local variables
# list in a comment, so it won't confuse other programs that the file is intended as
# input for. The example above is for a language where comment lines start with `;; '
# and end with `**'; the local values for comment-start and comment-end customize the
# rest of Emacs for this unusual syntax. Don't use a prefix (or a suffix) if you don't need one. 
#
#
# Can it be any more annoying to parse? --Steffen

    if ($settings->{in_local_variables_section}) {
      my $prefix = $settings->{local_variable_prefix};
      $prefix = '' if not defined $prefix;
      $prefix = quotemeta($prefix);
      my $suffix = $settings->{local_variable_suffix};
      $suffix = '' if not defined $suffix;
      $suffix = quotemeta($suffix);

      if ($line =~ /^\s*$prefix\s*([^\s:]+):\s*(.+)$suffix\s*$/) {
        my $key = $1;
        my $value = $2;
        $value =~ s/\s+$//;
        if ($key eq 'tab-width') {
          $settings->{tabstop} = $value;
        }
        elsif ($key eq 'indent-tabs-mode') {
          $tabmodelookup{$value}->($settings) if defined $tabmodelookup{$value};
        }
        elsif ($key eq 'c-basic-offset') {
          $settings->{tabstop} ||= $value; # tab-width takes precedence!?
        }
        elsif ($key eq 'style') { # this is quite questionable practice...
          $stylelookup{$value}->($settings) if defined $stylelookup{$value};
        }
      } # end if variable line
      else {
        delete $settings->{in_local_variables_section};
        delete $settings->{local_variable_prefix};
        delete $settings->{local_variable_suffix};
      }
    }
    elsif ($line =~ /^\s*(\S*)\s*Local Variables:\s*(\S*)\s*$/) {
      $settings->{local_variable_prefix} = $1;
      $settings->{local_variable_suffix} = $2;
      $settings->{in_local_variables_section} = 1;
    }
  }

  sub _check_emacs_local_variables_at_file_end {
    my $class = shift;
    my $textref = shift;
    my $settings = shift;
    my $len = length($$textref);
    my $start = $len-3000;
    $start = 0 if $start < 0;
    my $text = substr($$textref, $start);

    while ($text =~ /\G[ \t]*([^\r\n]*)[\r\n]+/cgs) {
      $class->_check_emacs_local_variables($1, $settings);
    }
    return;
  }
} # end lexical block for emacs lookups


sub to_vim_commands {
  my $indent = shift;
  $indent = shift if $indent eq __PACKAGE__;
  $indent = __PACKAGE__->parse($indent) if ref($indent) or length($indent) > 5;

  my @cmd;
  if ( $indent =~ /^t(\d+)/ ) {
    my $chars = $1;
    push @cmd, ":set shiftwidth=$chars";
    push @cmd, ":set tabstop=$chars";
    push @cmd, ":set softtabstop=0";
    push @cmd, ":set noexpandtab";
  } elsif ( $indent =~ /^s(\d+)/ ) {
    my $spaces = $1;
    push @cmd, ":set shiftwidth=$spaces";
    push @cmd, ":set tabstop=8";
    push @cmd, ":set softtabstop=$spaces";
    push @cmd, ':set expandtab';
  } elsif ( $indent =~ /^m(\d+)/ ) {
    my $spaces = $1;
    push @cmd, ":set shiftwidth=$spaces";
    push @cmd, ":set tabstop=8";
    push @cmd, ":set softtabstop=$spaces";
    push @cmd, ':set noexpandtab';
  }
  return @cmd;
}

1;

__END__

=pod

=head1 NAME

Text::FindIndent - Heuristically determine the indent style

=head1 SYNOPSIS

  use Text::FindIndent;
  my $indentation_type = Text::FindIndent->parse($text, skip_pod => 1);
  if ($indentation_type =~ /^s(\d+)/) {
    print "Indentation with $1 spaces\n";
  }
  elsif ($indentation_type =~ /^t(\d+)/) {
    print "Indentation with tabs, a tab should indent by $1 characters\n";
  }
  elsif ($indentation_type =~ /^m(\d+)/) {
    print "Indentation with $1 characters in tab/space mixed mode\n";
  }
  else {
    print "Indentation style unknown\n";
  }

=head1 DESCRIPTION

This is a module that attempts to intuit the underlying
indent "policy" for a text file (most likely a source code file).

=head1 METHODS

=head2 parse

The class method C<parse> tries to determine the indentation style of the
given piece of text (which must start at a new line and can be passed in either
as a string or as a reference to a scalar containing the string).

Returns a letter followed by a number. If the letter is C<s>, then the
text is most likely indented with spaces. The number indicates the number
of spaces used for indentation. A C<t> indicates tabs. The number after the
C<t> indicates the number characters each level of indentation corresponds to.
A C<u> indicates that the
indenation style could not be determined.
Finally, an C<m> followed by a number means that this many characters are used
for each indentation level, but the indentation is an arbitrary number of
tabs followed by 0-7 spaces. This can happen if your editor is stupid enough
to do smart indentation/whitespace compression. (I.e. replaces all indentations
many tabs as possible but leaves the rest as spaces.)

The function supports parsing of C<vim> I<modelines>. Those settings
override the heuristics. The modeline's options that are recognized
are C<sts>/C<softtabstob>, C<et>/C<noet>/C<expandtabs>/C<noexpandtabs>,
and C<ts>/C<tabstop>.

Similarly, parsing of C<emacs> I<Local Variables> is somewhat supported.
C<parse> use explicit settings to override the heuristics but uses style settings
only as a fallback. The following options are recognized:
C<tab-width>, C<indent-tabs-mode>, C<c-basic-offset>, and C<style>.

There is one named option that you can pass to C<parse()>: C<skip_pod>.
When set to true, any section of POD (see L<perlpod>) will be ignored for
indentation finding. This is because verbatim paragraphs and examples
embedded in POD or quite often indented differently from normal Perl code
around the POD section. Defaults to false. Example:

  my $mode = Text::FindIndent->parse(\$text, skip_pod => 1);

=head2 to_vim_commands

A class method that converts the output of C<parse(\$text)>
into a series of vi(m) commands that will configure vim to use the detected
indentation setting. Returns zero (failure) or more
lines of text that are suitable for passing to
C<VIM::DoCommand()> one by one.

As a convenience, if the argument to C<to_vim_commands> doesn't look
like the output of C<parse>, it is redirected to C<parse> first.

To use this, you can put the following line in your F<.vimrc> if your vim has
Perl support. Suggestions on how to do this in a more elegant way are welcome.
The code should be on one line but is broken up for displaying:

  map <F5> <Esc> :perl use Text::FindIndent;VIM::DoCommand($_) for
  Text::FindIndent->to_vim_commands(join "\n", $curbuf->Get(1..$curbuf->Count()));<CR>

(Patches to implement the equivalent for emacs would be welcome as well.)

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-FindIndent>

For other issues, contact the author.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 REPOSITORY

L<https://github.com/tsee/p5-Text-FindIndent>

=head1 COPYRIGHT

Copyright 2008 - 2010 Steffen Mueller.

Copyright 2008 - 2010 Adam Kennedy,

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
