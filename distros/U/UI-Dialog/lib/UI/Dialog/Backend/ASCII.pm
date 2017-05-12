package UI::Dialog::Backend::ASCII;
###############################################################################
#  Copyright (C) 2004-2016  Kevin C. Krinke <kevin@krinke.ca>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
###############################################################################
use 5.006;
use strict;
use warnings;
use Carp;
use UI::Dialog::Backend;
use Time::HiRes qw( sleep );

BEGIN {
  use vars qw( $VERSION @ISA );
  @ISA = qw( UI::Dialog::Backend );
  $VERSION = '1.21';
}

$| = 1; # turn on autoflush

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

sub new {
  my $proto = shift();
  my $class = ref($proto) || $proto;
  my $cfg = ((ref($_[0]) eq "HASH") ? $_[0] : (@_) ? { @_ } : {});
  my $self = {};
  bless($self, $class);
  $self->{'_state'} = {};
  $self->{'_opts'} = {};

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") {
      $self->{'PATHS'} = $CFG_PATH;
    }
		elsif ($CFG_PATH =~ m!:!) {
      $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ];
    }
		elsif (-d $CFG_PATH) {
      $self->{'PATHS'} = [ $CFG_PATH ];
    }
	}
  elsif ($ENV{'PATH'}) {
    $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ];
  }
	else {
    $self->{'PATHS'} = '';
  }

  $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
  $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
  $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
  $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();
  $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
  $self->{'_opts'}->{'backtitle'} = $cfg->{'backtitle'} || undef();
  $self->{'_opts'}->{'usestderr'} = $cfg->{'usestderr'} || 0;
  $self->{'_opts'}->{'extra-button'} = $cfg->{'extra-button'} || 0;
  $self->{'_opts'}->{'extra-label'} = $cfg->{'extra-label'} || undef();
  $self->{'_opts'}->{'help-button'} = $cfg->{'help-button'} || 0;
  $self->{'_opts'}->{'help-label'} = $cfg->{'help-label'} || undef();
  $self->{'_opts'}->{'nocancel'} = $cfg->{'nocancel'} || 0;
  $self->{'_opts'}->{'maxinput'} = $cfg->{'maxinput'} || 0;
  $self->{'_opts'}->{'defaultno'} = $cfg->{'defaultno'} || 0;
  $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
  $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
  $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
  $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
  $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
  $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
  $self->{'_opts'}->{'pager'} = ( $cfg->{'pager'}           ||
                                  $self->_find_bin('pager') ||
                                  $self->_find_bin('less')  ||
                                  $self->_find_bin('more')  );
  $self->{'_opts'}->{'stty'} = $cfg->{'stty'} || $self->_find_bin('stty');

  $self->{'_opts'}->{'trust-input'} =
    ( exists $cfg->{'trust-input'}
      && $cfg->{'trust-input'}==1
    ) ? 1 : 0;

  $self->{'_state'} = {'rv'=>0};

  return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Iherited Overrides
#:

sub _organize_text {
  my $self = shift();
  my $text = shift() || return();
  my @array;
  if (ref($text) eq "ARRAY") {
    push(@array,@{$text});
  }
  elsif ($text =~ /\\n/) {
    @array = split(/\\n/,$text);
  }
  else {
    @array = split(/\n/,$text);
  }
  $text = undef();
  $text = join("\n",@array);
  return($self->_strip_text($text));
}
sub _merge_attrs {
  my $self = shift();
  my $args = (@_ % 2) ? { @_, '_odd' } : { @_ };
  my $defs = $self->{'_opts'};
  foreach my $def (keys(%$defs)) {
		$args->{$def} = $defs->{$def} unless $args->{$def};
  }
  # alias 'filename' and 'file' to path
  $args->{'path'} = (($args->{'filename'}) ? $args->{'filename'} :
                     ($args->{'file'}) ? $args->{'file'} :
                     ($args->{'path'}) ? $args->{'path'} : "");
  $args->{'clear'} = $args->{'clearbefore'} || $args->{'clearafter'} || $args->{'autoclear'} || 0;
  $args->{'beep'} = $args->{'beepbefore'} || $args->{'beepafter'} || $args->{'autobeep'} || 0;
  return($args);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

#: this is the dynamic 'Colon Command Help'
sub _WRITE_HELP_TEXT {
  my $self = shift();
  my ($head,$foot);
  my $body = "
Colon Commands: [':?' (This help message)], [':pg <N>' (Go to page 'N')],
 [':n'|':next' (Go to the next page)], [':p'|':prev' (Go to the previous page)],
 [':esc'|':escape' (Send the [Esc] signal)].
";
	#    $head .= ("~" x 79);
  if ($self->{'_opts'}->{'extra-button'} || $self->{'_opts'}->{'extra-label'}) {
		$foot .= "[':e'|':extra' (Send the [Extra] signal)]\n";
  }
  if (!$self->{'_opts'}->{'nocancel'}) {
		$foot .= "[':c'|':cancel' (Send the [Cancel] signal)]\n";
  }
  if ($self->{'_opts'}->{'help-button'} || $self->{'_opts'}->{'help-label'}) {
		$foot .= "[':h'|':help' (Send the [Help] signal)]\n";
  }
	#    $foot .= ("~" x 79)."\n";
	#    $self->msgbox(title=>'Colon Command Help',text=>$head.$body.$foot);
  $self->msgbox(title=>'Colon Command Help',text=>$body.$foot);
}

#: this returns the labels (or ' ') for the "extra", "help" and
#: "cancel" buttons.
sub _BUTTONS {
  my $self = shift();
  my $cfg = $self->_merge_attrs(@_);
  my ($help,$cancel,$extra) = (' ',' ',' ');
  $extra = "Extra" if $cfg->{'extra-button'};
  $extra = $cfg->{'extra-label'} if $cfg->{'extra-label'};
  $extra = "':e'=[".$extra."]" if $extra and $extra ne ' ';
  $help = "Help" if $cfg->{'help-button'};
  $help = $self->{'help-label'} if $cfg->{'help-label'};
  $help = "':h'=[".$help."]" if $help and $help ne ' ';
  $cancel = "Cancel" unless $cfg->{'nocancel'};
  $cancel = $cfg->{'cancellabel'} if $cfg->{'cancellabel'};
  $cancel = "':c'=[".$cancel."]" if $cancel and $cancel ne ' ';
  return($help,$cancel,$extra);
}


#: this writes a standard ascii interface to STDOUT. This is intended for use
#: with any non-list native ascii mode widgets.
sub _WRITE_TEXT {
  my $self = shift();
  my $cfg = $self->_merge_attrs(@_);
  my $text = "";
  if ($cfg->{'literal'}) {
    $text = $cfg->{'text'} || '';
  }
  else {
    $text = $self->_organize_text($cfg->{'text'}) || "";
  }
  $self->clean_format($cfg->{'trust-input'},\$text);
  my $backtitle = $cfg->{'backtitle'} || " ";
  my $title = $cfg->{'title'} || " ";
  format ASCIIPGTXT =
+-----------------------------------------------------------------------------+
| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |
$backtitle
+-----------------------------------------------------------------------------+
|                                                                             |
| +-------------------------------------------------------------------------+ |
| | @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| | |
$title
| +-------------------------------------------------------------------------+ |
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| +-------------------------------------------------------------------------+ |
|                                                                             |
+-----------------------------------------------------------------------------+
.
  no strict 'subs';
  my $_fh = select();
  select(STDERR) unless not $cfg->{'usestderr'};
  my $LFMT = $~;
  $~ = ASCIIPGTXT;
  write();
  $~= $LFMT;
  select($_fh) unless not $cfg->{'usestderr'};
  use strict 'subs';
}

#: very much like _WRITE_TEXT() except that this is specifically for
#: the menu() widget only.
sub _WRITE_MENU {
  my $self = shift();
  my $cfg = $self->_merge_attrs(@_);
  my $text = "";
  if ($cfg->{'literal'}) {
    $text = $cfg->{'text'} || '';
  }
  else {
    $text = $self->_organize_text($cfg->{'text'}) || "";
  }
  $self->clean_format($cfg->{'trust-input'},\$text);
  my $backtitle = $cfg->{'backtitle'} || " ";
  my $title = $cfg->{'title'} || " ";
  my $menu = $cfg->{'menu'} || [];
  my ($help,$cancel,$extra) = $self->_BUTTONS(@_);
  for (my $i=0;$i<@{$menu};$i++) {
    $self->clean_format($cfg->{'trust-input'},\$menu->[$i]);
  }
  format ASCIIPGMNU =
+-----------------------------------------------------------------------------+
| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |
$backtitle
+-----------------------------------------------------------------------------+
|                                                                             |
| +-------------------------------------------------------------------------+ |
| | @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| | |
$title
| +-------------------------------------------------------------------------+ |
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| +-------------------------------------------------------------------------+ |
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[0]||' '),($menu->[1]||' '),($menu->[2]||' '),($menu->[3]||' '),($menu->[4]||' '),($menu->[5]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[6]||' '),($menu->[7]||' '),($menu->[8]||' '),($menu->[9]||' '),($menu->[10]||' '),($menu->[11]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[12]||' '),($menu->[13]||' '),($menu->[14]||' '),($menu->[15]||' '),($menu->[16]||' '),($menu->[17]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[18]||' '),($menu->[19]||' '),($menu->[20]||' '),($menu->[21]||' '),($menu->[22]||' '),($menu->[23]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[24]||' '),($menu->[25]||' '),($menu->[26]||' '),($menu->[27]||' '),($menu->[28]||' '),($menu->[29]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[30]||' '),($menu->[31]||' '),($menu->[32]||' '),($menu->[33]||' '),($menu->[34]||' '),($menu->[35]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[36]||' '),($menu->[37]||' '),($menu->[38]||' '),($menu->[39]||' '),($menu->[42]||' '),($menu->[43]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[42]||' '),($menu->[43]||' '),($menu->[44]||' '),($menu->[45]||' '),($menu->[46]||' '),($menu->[47]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[48]||' '),($menu->[49]||' '),($menu->[50]||' '),($menu->[51]||' '),($menu->[52]||' '),($menu->[53]||' ')
|      @||||||||||||||||||||  @|||||||||||||||||||  @|||||||||||||||||||      |
$extra,$cancel,$help
|                        ':?' = [Colon Command Help]                          |
+-----------------------------------------------------------------------------+
.
  no strict 'subs';
  my $_fh = select();
  select(STDERR) unless not $cfg->{'usestderr'};
  my $LFMT = $~;
  $~ = ASCIIPGMNU;
  write();
  $~= $LFMT;
  select($_fh) unless not $cfg->{'usestderr'};
  use strict 'subs';
}

#: very much like _WRITE_MENU() except that this is specifically for
#: the radiolist() and checklist() widgets only.
sub _WRITE_LIST {
  my $self = shift();
  my $cfg = $self->_merge_attrs(@_);
  my $text = "";
  if ($cfg->{'literal'}) {
    $text = $cfg->{'text'} || '';
  }
  else {
    $text = $self->_organize_text($cfg->{'text'}) || "";
  }
  $self->clean_format($cfg->{'trust-input'},\$text);

  my $backtitle = $cfg->{'backtitle'} || " ";
  my $title = $cfg->{'title'} || " ";
  my $menu = [];
  push(@{$menu},@{$cfg->{'menu'}});
  my ($help,$cancel,$extra) = $self->_BUTTONS(@_);
  my $m = @{$menu};

  if ($cfg->{'wm'}) {
		for (my $i = 2; $i < $m; $i += 3) {
			if ($menu->[$i] && $menu->[$i] =~ /on/i) {
        $menu->[$i] = '->';
      }
			else {
        $menu->[$i] = ' ';
      }
		}
  }
  else {
		my $mark;
		for (my $i = 2; $i < $m; $i += 3) {
			if (!$mark && $menu->[$i] && $menu->[$i] =~ /on/i) {
        $menu->[$i] = '->'; $mark = 1;
      }
			else {
        $menu->[$i] = ' ';
      }
		}
  }

  format ASCIIPGLST =
+-----------------------------------------------------------------------------+
| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |
$backtitle
+-----------------------------------------------------------------------------+
|                                                                             |
| +-------------------------------------------------------------------------+ |
| | @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| | |
$title
| +-------------------------------------------------------------------------+ |
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| +-------------------------------------------------------------------------+ |
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[2]||' '),($menu->[0]||' '),($menu->[1]||' '), ($menu->[5]||' '),($menu->[3]||' '),($menu->[4]||' '), ($menu->[8]||' '),($menu->[6]||' '),($menu->[7]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[11]||' '),($menu->[9]||' '),($menu->[10]||' '), ($menu->[14]||' '),($menu->[12]||' '),($menu->[13]||' '), ($menu->[17]||' '),($menu->[15]||' '),($menu->[16]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[20]||' '),($menu->[18]||' '),($menu->[19]||' '), ($menu->[23]||' '),($menu->[21]||' '),($menu->[22]||' '), ($menu->[26]||' '),($menu->[24]||' '),($menu->[25]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[29]||' '),($menu->[27]||' '),($menu->[28]||' '), ($menu->[32]||' '),($menu->[30]||' '),($menu->[31]||' '), ($menu->[35]||' '),($menu->[33]||' '),($menu->[34]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[38]||' '),($menu->[36]||' '),($menu->[37]||' '), ($menu->[41]||' '),($menu->[39]||' '),($menu->[40]||' '), ($menu->[44]||' '),($menu->[42]||' '),($menu->[43]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[47]||' '),($menu->[45]||' '),($menu->[46]||' '), ($menu->[50]||' '),($menu->[48]||' '),($menu->[49]||' '), ($menu->[53]||' '),($menu->[51]||' '),($menu->[52]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[56]||' '),($menu->[54]||' '),($menu->[55]||' '), ($menu->[59]||' '),($menu->[57]||' '),($menu->[58]||' '), ($menu->[62]||' '),($menu->[60]||' '),($menu->[61]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[65]||' '),($menu->[63]||' '),($menu->[64]||' '), ($menu->[68]||' '),($menu->[66]||' '),($menu->[67]||' '), ($menu->[71]||' '),($menu->[69]||' '),($menu->[70]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[74]||' '),($menu->[72]||' '),($menu->[73]||' '), ($menu->[77]||' '),($menu->[75]||' '),($menu->[76]||' '), ($menu->[80]||' '),($menu->[78]||' '),($menu->[79]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[83]||' '),($menu->[81]||' '),($menu->[82]||' '), ($menu->[86]||' '),($menu->[84]||' '),($menu->[85]||' '), ($menu->[89]||' '),($menu->[87]||' '),($menu->[88]||' ')
|      @||||||||||||||||||||  @|||||||||||||||||||  @|||||||||||||||||||      |
$extra,$cancel,$help
|                        ':?' = [Colon Command Help]                          |
+-----------------------------------------------------------------------------+
.
  no strict 'subs';
  my $_fh = select();
  select(STDERR) unless not $cfg->{'usestderr'};
  my $LFMT = $~;
  $~ = ASCIIPGLST;
  write();
  $~= $LFMT;
  select($_fh) unless not $cfg->{'usestderr'};
  use strict 'subs';
}

sub _PRINT {
  my $self = shift();
  my $stderr = shift();
  if ($stderr) {
		print STDERR @_;
  }
  else {
		print STDOUT @_;
  }
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Ask a binary question (Yes/No)
sub yesno {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my ($YN,$RESP) = ('Yes|no','YES_OR_NO');
  $YN = "yes|No" if $self->{'defaultno'};
  while ($RESP !~ /^(y|yes|n|no)$/i) {
		$self->_clear($args->{'clear'});
		$self->_WRITE_TEXT(@_,text=>$args->{'text'});
		$self->_PRINT($args->{'usestderr'},"(".$YN."): ");
		chomp($RESP = <STDIN>);
		if (!$RESP && $args->{'defaultno'}) {
      $RESP = "no";
    }
		elsif (!$RESP && !$args->{'defaultno'}) {
      $RESP = "yes";
    }
		if ($RESP =~ /^(y|yes)$/i) {
			$self->ra("YES");
			$self->rs("YES");
			$self->rv('null');
		}
    else {
			$self->ra("NO");
			$self->rs("NO");
			$self->rv(1);
		}
  }
  $self->_post($args);
  return(1) if $self->state() eq "OK";
  return(0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text entry
sub inputbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my $length = $args->{'maxinput'} + 1;
  my $text = $args->{'text'};
  my $string;
  chomp($text);
  while ($length > $args->{'maxinput'}) {
		$self->_clear($args->{'clear'});
		$self->_WRITE_TEXT(@_,'text'=>$args->{'text'});
		$self->_PRINT($args->{'usestderr'},"input: ");
		chomp($string = <STDIN>);
		if ($args->{'maxinput'}) {
			$length = length($string);
		}
    else {
			$length = 0;
		}
		if ($length > $args->{'maxinput'}) {
			$self->_PRINT($args->{'usestderr'},"error: too many charaters input,".
                    " the maximum is: ".$args->{'maxinput'}."\n");
		}
  }
  $self->rv('null');
  $self->ra($string);
  $self->rs($string);
  $self->_post($args);
  return($string);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Password entry
sub password {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  croak("The UI::Dialog::Backend::ASCII password widget depends on the stty ".
        "binary. This was not found or is not executable.")
    unless -x $args->{'stty'};
  my ($length,$key) = ($args->{'maxinput'} + 1,'');
  my $string;
  my $text = $args->{'text'};
  chomp($text);
  my $ENV_PATH = $ENV{'PATH'};
  $ENV{'PATH'} = "";
  while ($length > $args->{'maxinput'}) {
		$self->_clear($args->{'clear'});
		$self->_WRITE_TEXT(@_,'text'=>$args->{'text'});
		$self->_PRINT($args->{'usestderr'},"input: ");
		if ($self->_is_bsd()) {
      system "$args->{'stty'} cbreak </dev/tty >/dev/tty 2>&1";
    }
		else {
      system $args->{'stty'}, '-icanon', 'eol', "\001";
    }
		while ($key = getc(STDIN)) {
			last if $key =~ /\n/;
			if ($key =~ /^\x1b$/) {
				#this could be the DELETE key (not BS or ^H)
				# ^[[3~ or \x1b\x5b\x33\x7e (aka: ESC + [ + 3 + ~)
				my $key2 = getc(STDIN);
				if ($key2 =~ /^\x5b$/) {
					my $key3 = getc(STDIN);
					if ($key3 =~ /^\x33$/) {
						my $key4 = getc(STDIN);
						if ($key4 =~ /^\x7e$/) {
							chop($string);
							# go back five spaces and print five spaces (erase ^[[3~)
							# go back five spaces again (backtrack),
							# go back one space, print a space and go back (erase *)
							if ($args->{'usestderr'}) {
								print STDERR "\b\b\b\b\b"."     "."\b\b\b\b\b"."\b \b";
							}
              else {
								print STDOUT "\b\b\b\b\b"."     "."\b\b\b\b\b"."\b \b";
							}
						}
            else {
							$key = $key.$key2.$key3.$key4;
						}
					}
          else {
						$key = $key.$key2.$key3;
					}
				}
        else {
					$key = $key.$key2;
				}
			}
      elsif ($key =~ /^(?:\x08|\x7f)$/) {
				# this is either a BS or ^H
				chop($string);
				# go back two spaces and print two spaces (erase ^H)
				# go back two spaces again (backtrack),
				# go back one space, print a space and go back (erase *)
				if ($args->{'usestderr'}) {
					print STDERR "\b\b"."  "."\b\b"."\b \b";
				}
        else {
					print STDOUT "\b\b"."  "."\b\b"."\b \b";
				}
			}
      else {
				if ($args->{'usestderr'}) {
					print STDERR "\b*";
				}
        else {
					print STDOUT "\b*";
				}
				$string .= $key;
			}
		}
		if ($self->_is_bsd()) {
      system "$args->{'stty'} -cbreak </dev/tty >/dev/tty 2>&1";
    }
		else {
      system $args->{'stty'}, 'icanon', 'eol', '^@';
    }
		if ($args->{'maxinput'}) {
      $length = length($string);
    }
		else {
      $length = 0;
    }
		if ($length > $args->{'maxinput'}) {
			$self->_PRINT($args->{'usestderr'},"error: too many charaters input,".
                    " the maximum is: ".$args->{'maxinput'}."\n");
		}
  }
  $ENV{'PATH'} = $ENV_PATH;
  $self->rv('null');
  $self->ra($string);
  $self->rs($string);
  $self->_post($args);
  return($string);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Information box
sub infobox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $self->_WRITE_TEXT(@_,'text'=>$args->{'text'});
  $self->_PRINT($args->{'usestderr'});
  my $s = int(($args->{'wait'}) ? $args->{'wait'} :
              ($args->{'timeout'}) ? ($args->{'timeout'} / 1000.0) : 1.0);
  sleep($s);
  $self->rv('null');
  $self->ra('null');
  $self->rs('null');
  $self->_post($args);
  return(1);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Message box
sub msgbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $self->_WRITE_TEXT(@_,'text'=>$args->{'text'});
  $self->_PRINT($args->{'usestderr'},(" " x 25)."[ Press Enter to Continue ]");
  my $junk = <STDIN>;
  $self->rv('null');
  $self->ra('null');
  $self->rs('null');
  $self->_post($args);
  return(1);
}


#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text box
sub textbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my $rv = 0;
  if (-r $args->{'path'}) {
		my $ENV_PATH = $ENV{'PATH'};
		$ENV{'PATH'} = "";
		if ($ENV{'PAGER'} && -x $ENV{'PAGER'}) {
			system($ENV{'PAGER'}." ".$args->{'path'});
			$rv = $? >> 8;
		}
    elsif (-x $args->{'pager'}) {
			system($args->{'pager'}." ".$args->{'path'});
			$rv = $? >> 8;
		}
    else {
			open(ATBFILE,"<".$args->{'path'});
			local $/;
			my $data = <ATBFILE>;
			close(ATBFILE);
			$self->_PRINT($args->{'usestderr'},$data);
		}
		$ENV{'PATH'} = $ENV_PATH;
  }
  else {
		return($self->msgbox('title'=>'error','text'=>$args->{'path'}.' is not a readable text file.'));
  }
  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  $self->_post($args);
  return($rv);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: A simple menu
sub menu {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $args->{'menu'} ||= ref($args->{'list'}) ? $args->{'list'} : [$args->{'list'}];
  $args->{'menu'} ||= [];
  my $string;
  my $rs = '';
  my $m = 0;
  $m = @{$args->{'menu'}};
  my ($valid,$menu,$realm) = ([],[],[]);
  push(@{$menu},@{$args->{'menu'}}) if ref($args->{'menu'}) eq "ARRAY";

  for (my $i = 0; $i < $m; $i += 2) {
    push(@{$valid},$menu->[$i]);
  }

  if (@{$menu} >= 60) {
		my $c = 0;
		while (@{$menu}) {
			$realm->[$c] = [];
			for (my $i = 0; $i < 60; $i++) {
				push(@{$realm->[$c]},shift(@{$menu}));
			}
			$c++;
		}
  }
  else {
		$realm->[0] = [];
		push(@{$realm->[0]},@{$menu});
  }
  my $pg = 1;
  while (!$rs) {
		$self->_WRITE_MENU(@_,'text'=>$args->{'text'},
                       'menu'=>$realm->[($pg - 1||0)]);
		$self->_PRINT($args->{'usestderr'},"(".$pg."/".@{$realm}."): ");
		chomp($rs = <STDIN>);
		if ($rs =~ /^:\?$/i) {
			$self->_clear($args->{'clear'});
			$self->_WRITE_HELP_TEXT();
			undef($rs);
			next;
		}
    elsif ($rs =~ /^:(esc|escape)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(255);
			return(0);
		}
    elsif (($args->{'extra-button'} || $args->{'extra-label'}) && $rs =~ /^:(e|extra)$/i) {
			$self->rv(3);
			return('EXTRA');
		}
    elsif ($args->{'help-button'} && $rs =~ /^:(h|help)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(2);
			return($self->state());
		}
    elsif (!$args->{'nocancel'} && $rs =~ /^:(c|cancel)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(1);
			return($self->state());
		}
    elsif ($rs =~ /^:pg\s*(\d+)$/i) {
			my $p = $1;
			if ($p <= @{$realm} && $p > 0) {
        $pg = $p;
      }
			undef($rs);
		}
    elsif ($rs =~ /^:(n|next)$/i) {
			if ($pg < @{$realm}) {
        $pg++;
      }
			else {
        $pg = 1;
      }
			undef($rs);
		}
    elsif ($rs =~ /^:(p|prev)$/i) {
			if ($pg > 1) {
        $pg--;
      }
			else {
        $pg = @{$realm};
      }
			undef($rs);
		}
    else {
			if (@_ = grep { /^\Q$rs\E$/i } @{$valid}) {
        $rs = $_[0];
      }
			else {
        undef($rs);
      }
		}
		$self->_clear($args->{'clear'});
  }

  $self->rv('null');
  $self->ra($rs);
  $self->rs($rs);
  $self->_post($args);
  return($rs);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: A multi-selectable list
sub checklist {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my $menulist = ($args->{'menu'} || $args->{'list'});
  my $menufix = [];
  if (ref($menulist) eq "ARRAY") {
		#: flatten our multidimensional array
		foreach my $item (@$menulist) {
			if (ref($item) eq "ARRAY") {
				pop(@{$item}) if @$item == 3;
				push(@$menufix,@{$item});
			}
      else {
				push(@$menufix,$item);
			}
		}
  }
  $args->{'menu'} = $menufix;

  my $ra = [];
  my $rs = '';
  my $m;
  $m = @{$args->{'menu'}} if ref($args->{'menu'}) eq "ARRAY";
  my ($valid,$menu,$realm) = ([],[],[]);
  push(@{$menu},@{$args->{'menu'}}) if ref($args->{'menu'}) eq "ARRAY";

  for (my $i = 0; $i < $m; $i += 3) {
    push(@{$valid},$menu->[$i]);
  }

  if (@{$menu} >= 90) {
		my $c = 0;
		while (@{$menu}) {
			$realm->[$c] = [];
			for (my $i = 0; $i < 90; $i++) {
				push(@{$realm->[$c]},shift(@{$menu}));
			}
			$c++;
		}
  }
  else {
		$realm->[0] = [];
		push(@{$realm->[0]},@{$menu});
  }
  my $go = "GO";
  my $pg = 1;
  while ($go) {
		$self->_WRITE_LIST(@_,'wm'=>'check','text'=>$args->{'text'},'menu'=>$realm->[($pg - 1||0)]);
		$self->_PRINT($args->{'usestderr'},"(".$pg."/".@{$realm}."): ");
		chomp($rs = <STDIN>);
		if ($rs =~ /^:\?$/i) {
			$self->_clear($args->{'clear'});
			$self->_WRITE_HELP_TEXT();
			undef($rs);
			next;
		}
    elsif ($rs =~ /^:(esc|escape)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(255);
			return($self->state());
		}
    elsif (($args->{'extra-button'} || $args->{'extra-label'}) && $rs =~ /^:(e|extra)$/i) {
			$self->_clear($args->{'clear'});
			$self->rv(3);
			return($self->state());
		}
    elsif (($args->{'help-button'} || $args->{'help-label'}) && $rs =~ /^:(h|help)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(2);
			return($self->rv());
		}
    elsif (!$args->{'nocancel'} && $rs =~ /^:(c|cancel)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(1);
			return($self->state());
		}
    elsif ($rs =~ /^:pg\s*(\d+)$/i) {
			my $p = $1;
			if ($p <= @{$realm} && $p > 0) {
        $pg = $p;
      }
		}
    elsif ($rs =~ /^:(n|next)$/i) {
			if ($pg < @{$realm}) {
        $pg++;
      }
			else {
        $pg = 1;
      }
		}
    elsif ($rs =~ /^:(p|prev)$/i) {
			if ($pg > 1) {
        $pg--;
      }
			else {
        $pg = @{$realm};
      }
		}
    else {
			my @opts = split(/\,\s|\,|\s/,$rs);
			my @good;
			foreach my $opt (@opts) {
				if (@_ = grep { /^\Q$opt\E$/i } @{$valid}) {
          push(@good,$_[0]);
        }
			}
			if (@opts == @good) {
				undef($go);
				$ra = [];
				push(@{$ra},@good);
			}
		}
		$self->_clear($args->{'clear'});
		undef($rs);
  }

  $self->rv('null');
  $self->ra($ra);
  $self->rs(join("\n",@$ra));
  $self->_post($args);
  return(@{$ra});
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: A radio button based list. very much like the menu widget.
sub radiolist {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my $menulist = ($args->{'menu'} || $args->{'list'});
  my $menufix = [];
  if (ref($menulist) eq "ARRAY") {
		#: flatten our multidimensional array
		foreach my $item (@$menulist) {
			if (ref($item) eq "ARRAY") {
				pop(@{$item}) if @$item == 3;
				push(@$menufix,@{$item});
			}
      else {
				push(@$menufix,$item);
			}
		}
  }
  $args->{'menu'} = $menufix;
  my $rs = '';
  my $m;
  $m = @{$args->{'menu'}} if ref($args->{'menu'}) eq "ARRAY";
  my ($valid,$menu,$realm) = ([],[],[]);
  push(@{$menu},@{$args->{'menu'}}) if ref($args->{'menu'}) eq "ARRAY";

  for (my $i = 0; $i < $m; $i += 3) {
    push(@{$valid},$menu->[$i]);
  }

  if (@{$menu} >= 90) {
		my $c = 0;
		while (@{$menu}) {
			$realm->[$c] = [];
			for (my $i = 0; $i < 90; $i++) {
				push(@{$realm->[$c]},shift(@{$menu}));
			}
			$c++;
		}
  }
  else {
		$realm->[0] = [];
		push(@{$realm->[0]},@{$menu});
  }
  my $pg = 1;
  while (!$rs) {
		$self->_WRITE_LIST(@_,'text'=>$args->{'text'},'menu'=>$realm->[($pg - 1||0)]);
		$self->_PRINT($args->{'usestderr'},"(".$pg."/".@{$realm}."): ");
		chomp($rs = <STDIN>);
		if ($rs =~ /^:\?$/i) {
			$self->_clear($args->{'clear'});
			$self->_WRITE_HELP_TEXT();
			undef($rs);
			next;
		}
    elsif ($rs =~ /^:(esc|escape)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(255);
			return($self->rv());
		}
    elsif (($args->{'extra-button'} || $args->{'extra-label'}) && $rs =~ /^:(e|extra)$/i) {
			$self->rv(3);
			return($self->state());
		}
    elsif (($args->{'help-button'} || $args->{'help-label'}) && $rs =~ /^:(h|help)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(2);
			return($self->state());
		}
    elsif (!$args->{'nocancel'} && $rs =~ /^:(c|cancel)$/i) {
			$self->_clear($args->{'clear'});
			undef($rs);
			$self->rv(1);
			return($self->state());
		}
    elsif ($rs =~ /^:pg\s*(\d+)$/i) {
			my $p = $1;
			if ($p <= @{$realm} && $p > 0) {
        $pg = $p;
      }
			undef($rs);
		}
    elsif ($rs =~ /^:(n|next)$/i) {
			if ($pg < @{$realm}) {
        $pg++;
      }
			else {
        $pg = 1;
      }
			undef($rs);
		}
    elsif ($rs =~ /^:(p|prev)$/i) {
			if ($pg > 1) {
        $pg--;
      }
			else {
        $pg = @{$realm};
      }
			undef($rs);
		}
    else {
			if (@_ = grep { /^\Q$rs\E$/i } @{$valid}) {
        $rs = $_[0];
      }
			else {
        undef($rs);
      }
		}
		$self->_clear($args->{'clear'});
  }

  $self->rv('null');
  $self->ra($rs);
  $self->rs($rs);
  $self->_post($args);
  return($rs);
}


#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Simple ASCII progress indicator :)
sub spinner {
	my $self = shift();
	if (!$self->{'__SPIN'} || $self->{'__SPIN'} == 1) {
    $self->{'__SPIN'} = 2; return("\b|");
  }
	elsif ($self->{'__SPIN'} == 2) {
    $self->{'__SPIN'} = 3; return("\b/");
  }
	elsif ($self->{'__SPIN'} == 3) {
    $self->{'__SPIN'} = 4; return("\b-");
  }
	elsif ($self->{'__SPIN'} == 4) {
    $self->{'__SPIN'} = 1; return("\b\\");
  }
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Simple ASCII meter bar
# the idea of a "true" dialog like gauge widget with ASCII is not that bad and
# as such, I've named these methods differently so as to keep the namespace
# open for gauge_*() widgets.
sub draw_gauge {
  my $self = shift();
  my $args = $self->_merge_attrs(@_);
  my $length = $args->{'length'} || $args->{'width'} || 74;
  my $bar = ($args->{'bar'} || "-") x $length;
  my $current = $args->{'current'} || 0;
  my $total = $args->{'total'} || 0;
  my $percent = (($current && $total) ? int($current / ($total / 100)) :
                 ($args->{'percent'} || '0'));
  $percent = int(($percent <= 100 && $percent >= 0) ? $percent : 0 );
  my $perc = int((($length / 100) * $percent));
  substr($bar,($perc||0),1,($args->{'mark'}||"|"));
  my $text = (($percent =~ /^\d$/) ? "  " :
              ($percent =~ /^\d\d$/) ? " " : "").$percent."% ".$bar;
  $self->_PRINT($args->{'usestderr'},(($args->{'noCR'} && not $args->{'CR'}) ? "" : "\x0D").$text);
  return($percent||1);
}
sub end_gauge {
  my $self = shift();
  my $args = $self->_merge_attrs(@_);
  $self->_PRINT($args->{'usestderr'},"\n");
}

1;
