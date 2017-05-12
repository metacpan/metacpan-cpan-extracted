package UI::Dialog::Backend::CDialog;
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
use Config;
use FileHandle;
use Cwd qw( abs_path );
use Time::HiRes qw( sleep );
use UI::Dialog::Backend;

BEGIN {
  use vars qw( $VERSION @ISA );
  @ISA = qw( UI::Dialog::Backend );
  $VERSION = '1.21';
}

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
	my $path_sep = $Config::Config{path_sep};
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") {
      $self->{'PATHS'} = $CFG_PATH;
    }
		elsif ($CFG_PATH =~ m!$path_sep!) {
      $self->{'PATHS'} = [ split(/$path_sep/,$CFG_PATH) ];
    }
		elsif (-d $CFG_PATH) {
      $self->{'PATHS'} = [ $CFG_PATH ];
    }
	}
  elsif ($ENV{'PATH'}) {
    $self->{'PATHS'} = [ split(/$path_sep/,$ENV{'PATH'}) ];
  }
	else {
    $self->{'PATHS'} = '';
  }

	$self->{'_opts'}->{'literal'} = $cfg->{'literal'} || 0;
  $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
  $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
  $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
  $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();
  $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
  $self->{'_opts'}->{'backtitle'} = $cfg->{'backtitle'} || undef();
  $self->{'_opts'}->{'width'} = $cfg->{'width'} || 65;
  $self->{'_opts'}->{'height'} = $cfg->{'height'} || 10;
  $self->{'_opts'}->{'percentage'} = $cfg->{'percentage'} || 1;
  $self->{'_opts'}->{'colours'} = ($cfg->{'colours'} || $cfg->{'colors'}) ? 1 : 0;
  $self->{'_opts'}->{'bin'} ||= $self->_find_bin('dialog');
  $self->{'_opts'}->{'bin'} ||= $self->_find_bin('dialog.exe') if $^O =~ /win32/i;
  $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
  $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
  $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
  $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
  $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
  $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
  unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the dialog binary could not be found at: ".$self->{'_opts'}->{'bin'});
  }
  $self->{'_opts'}->{'DIALOGRC'} = $cfg->{'DIALOGRC'} || undef();
  my $beginref = $cfg->{'begin'};
  $self->{'_opts'}->{'begin'} = (ref($beginref) eq "ARRAY") ? $beginref : undef();
  $self->{'_opts'}->{'cancel-label'} = $cfg->{'cancel-label'} || undef();
  $self->{'_opts'}->{'defaultno'} = $cfg->{'defaultno'} || 0;
  $self->{'_opts'}->{'default-item'} = $cfg->{'default-item'} || undef();
  $self->{'_opts'}->{'exit-label'} = $cfg->{'exit-label'} || undef();
  $self->{'_opts'}->{'extra-button'} = $cfg->{'extra-button'} || 0;
  $self->{'_opts'}->{'extra-label'} = $cfg->{'extra-label'} || undef();
  $self->{'_opts'}->{'help-button'} = $cfg->{'help-button'} || 0;
  $self->{'_opts'}->{'help-label'} = $cfg->{'help-label'} || undef();
  $self->{'_opts'}->{'max-input'} = $cfg->{'max-input'} || 0;
  $self->{'_opts'}->{'no-cancel'} = $cfg->{'no-cancel'} || $cfg->{'nocancel'} || 0;
  $self->{'_opts'}->{'no-collapse'} = $cfg->{'no-collapse'} || 0;
  $self->{'_opts'}->{'no-shadow'} = $cfg->{'no-shadow'} || 0;
  $self->{'_opts'}->{'ok-label'} = $cfg->{'ok-label'} || undef();
  $self->{'_opts'}->{'shadow'} = $cfg->{'shadow'} || 0;
  $self->{'_opts'}->{'tab-correct'} = $cfg->{'tab-correct'} || 0;
  $self->{'_opts'}->{'tab-len'} = $cfg->{'tab-len'} || 0;
  $self->{'_opts'}->{'listheight'} = $cfg->{'listheight'} || $cfg->{'menuheight'} || 5;
  $self->{'_opts'}->{'formheight'} = $cfg->{'formheight'} || $cfg->{'listheight'} || 5;
  $self->{'_opts'}->{'yes-label'} = $cfg->{'yes-label'} || undef();
  $self->{'_opts'}->{'no-label'} = $cfg->{'no-label'} || undef();

  $self->{'_opts'}->{'trust-input'} = $cfg->{'trust-input'} || 0;

  $self->_determine_dialog_variant();

  $self->{'test_mode'} = $cfg->{'test_mode'} if exists $cfg->{'test_mode'};
  $self->{'test_mode_result'} = '';

  return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:
sub _determine_dialog_variant {
  my $self = $_[0];
  my $str = `$self->{'_opts'}->{'bin'} --help 2>&1`;
  if ($str =~ /version\s0\.[34]/m) {
		# this version does not support colours, so far just FreeBSD 4.8 has this
		# ancient binary. Bugreport from Jeroen Bulten indicates that he's
		# got a version 0.3 (patched to 0.4) installed. ugh...
		$self->{'_variant'} = "dialog";
		# the separate-output option seems to be the culprit of FreeBSD failure.
		$self->{'_opts'}->{'force-no-separate-output'} = 1;
	}
  elsif ($str =~ /cdialog\s\(ComeOn\sDialog\!\)\sversion\s(\d+\.\d+.+)/) {
		# We consider cdialog to be a colour supporting dialog variant all others
		# are non-colourized and support only the base functionality :(
		my $ver = $1;
    if ($ver =~ /-20(?:0[3-9]|\d\d)/) {
			$self->{'_variant'} = "cdialog";
			# these versions support colours :)
			$self->{'_opts'}->{'colours'} = 1;
		}
    else {
			$self->{'_variant'} = "dialog";
		}
  }
  else {
    $self->{'_variant'} = "dialog";
  }
  undef($str);
}

my $SIG_CODE = {};
sub _del_gauge {
  my $CODE = $SIG_CODE->{$$};
  unless (not ref($CODE)) {
		delete($CODE->{'_GAUGE'});
		$CODE->rv('1');
		$CODE->rs('null');
		$CODE->ra('null');
		$SIG_CODE->{$$} = "";
  }
}

sub append_format_base {
  my ($self,$args,$fmt) = @_;
  $ENV{'DIALOGRC'} ||= ($args->{'DIALOGRC'} && -r $args->{'DIALOGRC'}) ? $args->{'DIALOGRC'} : "";
  $ENV{'DIALOG_CANCEL'} = '1';
  $ENV{'DIALOG_ERROR'}  = '254';
  $ENV{'DIALOG_ESC'}    = '255';
  $ENV{'DIALOG_EXTRA'}  = '3';
  $ENV{'DIALOG_HELP'}   = '2';
  $ENV{'DIALOG_OK'}     = '0';
  $fmt = $self->append_format_check($args,$fmt,'backtitle','--backtitle {{backtitle}}');
  $fmt = $self->append_format_check($args,$fmt,"defaultno","--defaultno");
  $fmt = $self->append_format_check($args,$fmt,"extra-button","--extra-button");
  $fmt = $self->append_format_check($args,$fmt,"help-button","--help-button");
  $fmt = $self->append_format_check($args,$fmt,"no-cancel","--no-cancel");
  $fmt = $self->append_format_check($args,$fmt,"no-collapse","--no-collapse");
  $fmt = $self->append_format_check($args,$fmt,"no-shadow","--no-shadow");
  $fmt = $self->append_format_check($args,$fmt,"shadow","--shadow");
  $fmt = $self->append_format_check($args,$fmt,"tab-correct","--tab-correct");
  $fmt = $self->append_format_check($args,$fmt,"cancel-label","--cancel-label {{cancel-label}}");
  $fmt = $self->append_format_check($args,$fmt,"default-item","--default-item {{default-item}}");
  $fmt = $self->append_format_check($args,$fmt,"exit-label","--exit-label {{exit-label}}");
  $fmt = $self->append_format_check($args,$fmt,"extra-label","--extra-label {{extra-label}}");
  $fmt = $self->append_format_check($args,$fmt,"help-label","--help-label {{help-label}}");
  $fmt = $self->append_format_check($args,$fmt,"max-input","--max-input {{max-input}}");
  $fmt = $self->append_format_check($args,$fmt,"ok-label","--ok-label {{ok-label}}");
  $fmt = $self->append_format_check($args,$fmt,"tab-len","--tab-len {{tab-len}}");
  $fmt = $self->append_format_check($args,$fmt,"yes-label","--yes-label {{yes-label}}");
  $fmt = $self->append_format_check($args,$fmt,"no-label","--no-label {{no-label}}");

  if ($self->{'_opts'}->{'force-no-separate-output'}) {
    delete $args->{'separate-output'};
  } else {
    $fmt = $self->append_format_check($args,$fmt,"separate-output","--separate-output");
  }
  if ($self->is_cdialog()) {
    $fmt = $self->append_format($fmt,'--colors');
    $fmt = $self->append_format($fmt,'--cr-wrap');
    if (exists $args->{'begin'}) {
      my $begin = $args->{'begin'};
      if (ref($begin) eq "ARRAY") {
        $fmt = $self->append_format($fmt,'--begin '.$begin->[0].' '.$begin->[1]);
      }
    }
  }
  return $fmt;
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Override Inherited Methods
#:
sub _organize_text {
  my $self = $_[0];
  my $text = $_[1] || return();
  my $width = $_[2] || 65;
  my $trust = (exists $_[3] && defined $_[3]) ? $_[3] : '0';
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

  @array = $self->word_wrap($width,"","",@array);
  my $max = @array;
  for (my $i = 0; $i < $max; $i++) {
    $self->clean_format($trust,\$array[$i]);
  }

  if ($self->{'scale'}) {
		foreach my $line (@array) {
      my $s_line = $line; #$self->__TRANSLATE_CLEAN($line);
			$s_line =~ s!\[A\=\w+\]!!gi;
			$self->{'width'} = length($s_line) + 5
        if ($self->{'width'} - 5) < length($s_line)
			  && (length($s_line) <= $self->{'max-scale'});
		}
  }

  my $new_line = $^O =~ /win32/i ? '\n' : "\n";
  foreach my $line (@array) {
		my $pad;
    my $s_line = $self->_strip_text($line);
		if ($line =~ /\[A\=(\w+)\]/i) {
			my $align = $1;
			$line =~ s!\[A\=\w+\]!!gi;
			if (uc($align) eq "CENTER" || uc($align) eq "C") {
				$pad = ((($self->{'_opts'}->{'width'} - 5) - length($s_line)) / 2);
      }
      elsif (uc($align) eq "LEFT" || uc($align) eq "L") {
				$pad = 0;
			}
      elsif (uc($align) eq "RIGHT" || uc($align) eq "R") {
				$pad = (($self->{'_opts'}->{'width'} - 5) - length($s_line));
      }
		}
		if ($pad) {
      $text .= (" " x $pad).$new_line;
    }
		else {
      $text .= $line . $new_line;
    }
  }
  chomp($text);
  return($self->_filter_text($text));
}
sub _strip_text {
  my $self = shift();
  my $text = shift();
  $text =~ s!\\Z0!!gmi;
  $text =~ s!\\Z1!!gmi;
  $text =~ s!\\Z2!!gmi;
  $text =~ s!\\Z3!!gmi;
  $text =~ s!\\Z4!!gmi;
  $text =~ s!\\Z5!!gmi;
  $text =~ s!\\Z6!!gmi;
  $text =~ s!\\Z7!!gmi;
  $text =~ s!\\Zb!!gmi;
  $text =~ s!\\ZB!!gmi;
  $text =~ s!\\Zu!!gmi;
  $text =~ s!\\ZU!!gmi;
  $text =~ s!\\Zr!!gmi;
  $text =~ s!\\ZR!!gmi;
  $text =~ s!\\Zn!!gmi;
  $text =~ s!\[C=black\]!!gmi;
  $text =~ s!\[C=red\]!!gmi;
  $text =~ s!\[C=green\]!!gmi;
  $text =~ s!\[C=yellow\]!!gmi;
  $text =~ s!\[C=blue\]!!gmi;
  $text =~ s!\[C=magenta\]!!gmi;
  $text =~ s!\[C=cyan\]!!gmi;
  $text =~ s!\[C=white\]!!gmi;
  $text =~ s!\[B\]!!gmi;
  $text =~ s!\[/B\]!!gmi;
  $text =~ s!\[U\]!!gmi;
  $text =~ s!\[/U\]!!gmi;
  $text =~ s!\[R\]!!gmi;
  $text =~ s!\[/R\]!!gmi;
  $text =~ s!\[N\]!!gmi;
  $text =~ s!\[A=\w+\]!!gmi;
  return($text);
}
sub _filter_text {
  my $self = shift();
  my $text = shift() || return();
  if ($self->is_cdialog() && $self->{'_opts'}->{'colours'}) {
		$text =~ s!\[C=black\]!\\Z0!gmi;
		$text =~ s!\[C=red\]!\\Z1!gmi;
		$text =~ s!\[C=green\]!\\Z2!gmi;
		$text =~ s!\[C=yellow\]!\\Z3!gmi;
		$text =~ s!\[C=blue\]!\\Z4!gmi;
		$text =~ s!\[C=magenta\]!\\Z5!gmi;
		$text =~ s!\[C=cyan\]!\\Z6!gmi;
		$text =~ s!\[C=white\]!\\Z7!gmi;
		$text =~ s!\[B\]!\\Zb!gmi;
		$text =~ s!\[/B\]!\\ZB!gmi;
		$text =~ s!\[U\]!\\Zu!gmi;
		$text =~ s!\[/U\]!\\ZU!gmi;
		$text =~ s!\[R\]!\\Zr!gmi;
		$text =~ s!\[/R\]!\\ZR!gmi;
		$text =~ s!\[N\]!\\Zn!gmi;
		$text =~ s!\[A=\w+\]!!gmi;
		return($text);
  }
  else {
		return($self->_strip_text($text));
  }
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: test for the good stuff
sub is_cdialog {
  my $self = $_[0];
  return(1) if $self->{'_variant'} && $self->{'_variant'} eq "cdialog";
  return(0);
}

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

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--yesno {{text}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);
  if ($rv && $rv >= 1) {
		$self->ra("NO");
		$self->rs("NO");
		$self->rv($rv);
  }
  else {
		$self->ra("YES");
		$self->rs("YES");
    $self->rv('null');
  }
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
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

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  if ($args->{'password'}) {
    if ($args->{'entry'}) {
      $fmt = $self->append_format($fmt,'--insecure');
    } else {
      $fmt = $self->append_format_check($args,$fmt,'insecure','--insecure');
    }
    $fmt = $self->append_format($fmt,'--passwordbox');
  }
  else {
    $fmt = $self->append_format($fmt,'--inputbox');
  }
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{entry}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      entry => $self->make_kvl($args,($args->{'init'}||$args->{'entry'})),
    );

  my ($rv,$text) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $text : 0);
}
#: password boxes aren't supported by gdialog
sub password {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'password',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text box
sub msgbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'msgbox'} ||= 'msgbox';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  if ($args->{'infobox'}) {
    $fmt = $self->append_format($fmt,'--infobox');
  }
  else {
    $fmt = $self->append_format($fmt,'--msgbox');
  }
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);
  if ($args->{'infobox'}) {
    my $sec = 0;
    if ($args->{'timeout'}) {
      $sec = int($args->{'timeout'} ? ($args->{'timeout'} / 1000.0) : 1.0);
      $self->_debug("Will sleep for timeout=".$sec);
    } elsif ($args->{'wait'}) {
      $sec = int($args->{'wait'} ? $args->{'wait'} : 1);
      $self->_debug("Will sleep for wait=".$sec);
    }
    sleep($sec) if $sec;
  }
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}
sub infobox {
  my $self = shift();
  return($self->msgbox('caller',((caller(1))[3]||'main'),@_,'infobox',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: File box
sub textbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--scrolltext');
  $fmt = $self->append_format($fmt,'--textbox');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,($args->{'path'}||'.')),
    );

  my ($rv,$text) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: a simple menu
sub menu {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'listheight'} = $args->{'menuheight'}
    if exists $args->{'menuheight'};

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--menu');
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$selected) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $selected : 0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: a check list
sub checklist {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'listheight'} = $args->{'menuheight'}
    if exists $args->{'menuheight'};

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $args->{radiolist} ||= 0;
  if ($args->{radiolist}) {
    $fmt = $self->append_format($fmt,'--radiolist');
  }
  else {
    $fmt = $self->append_format($fmt,'--separate-output');
    $fmt = $self->append_format($fmt,'--checklist');
  }
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{listheight}} {{list}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  if ($args->{radiolist}) {
    my ($rv,$selected) = $self->command_string($command);
    return($rv == 0 ? $selected : 0);
  }
  my ($rv,$selected) = $self->command_array($command);
  return($rv == 0 ? @{$selected} : 0);
}
#: a radio button list
sub radiolist {
  my $self = shift();
  return($self->checklist('caller',((caller(1))[3]||'main'),@_,'radiolist',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: file select
sub fselect {
  my $self = shift();
  unless ($self->is_cdialog()) {
		return($self->SUPER::fselect(@_));
  }
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--fselect');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');

  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,($args->{'path'}||'.')),
    );

  my ($rv,$file) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $file : 0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: calendar

sub calendar {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  $args->{'day'}   ||= '1';
  $args->{'month'} ||= '1';
  $args->{'year'}  ||= '1970';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--calendar {{text}} {{listheight}} {{width}} {{day}} {{month}} {{year}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$date) = $self->command_string($command);
  if ($rv == 0) {
    $self->ra(split(m!/!,$date));
  }
  $self->_post($args);
  return($rv == 0 ? $date : 0) unless defined wantarray and wantarray;
  return($rv == 0 ? $self->ra() : (0,0,0));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: timebox

sub timebox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $args->{'hour'}   ||= $hour;
  $args->{'minute'} ||= $min;
  $args->{'second'} ||= $sec;

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--timebox {{text}} {{height}} {{width}} {{hour}} {{minute}} {{second}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$time) = $self->command_string($command);
  if ($rv == 0) {
    $self->ra(split(m!\:!,$time));
  }
  $self->_post($args);
  return($rv == 0 ? $time : 0) unless defined wantarray and wantarray;
  return($rv == 0 ? $self->ra() : (0,0,0));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: tailbox

sub tailbox {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--tailbox');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,($args->{'path'}||'.')),
    );

  my ($rv) = $self->command_state($command);
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: tailboxbg

sub tailboxbg {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--tailboxbg');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,($args->{'path'}||'.')),
    );

  my ($rv) = $self->command_state($command);
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: an editable form (wow is this useful! holy cripes!)
sub form {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'listheight'} = $args->{'menuheight'}
    if exists $args->{'menuheight'};
  $args->{'listheight'} = $args->{'formheight'}
    if exists $args->{'formheight'};

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--form');
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{listheight}} {{list}}');

  my $list = '';
  while (@{$args->{'list'}}) {
    my $item = shift(@{$args->{'list'}});
    my $info = shift(@{$args->{'list'}});
    $self->clean_format($args->{'trust-input'},\$item->[0]);
    $self->clean_format($args->{'trust-input'},\$item->[1]);
    $self->clean_format($args->{'trust-input'},\$item->[2]);
    $self->clean_format($args->{'trust-input'},\$info->[0]);
    $self->clean_format($args->{'trust-input'},\$info->[1]);
    $self->clean_format($args->{'trust-input'},\$info->[2]);
    $self->clean_format($args->{'trust-input'},\$info->[3]);
    $self->clean_format($args->{'trust-input'},\$info->[4]);
    $list .= ' "'.($item->[0]||' ').'" "'.$item->[1].'" "'.$item->[2].'" "'.($info->[0]||' ').'" "'.$info->[1].'" "'.$info->[2].'" "'.$info->[3].'" "'.$info->[4].'"';
  }
  delete $args->{'list'};
  $args->{'list'} = $list;

  my $command = $self->prepare_command
    ( $args, $fmt,
      list => $self->make_kvl($args,$args->{'list'}),
    );

  my ($rv,$selected) = $self->command_array($command);
  $self->_post($args);
  return($rv == 0 ? $selected : 0) unless defined wantarray and wantarray;
  return($rv == 0 ? $self->ra() : (0));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: progress meter
sub gauge_start {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $self->{'_GAUGE'} ||= {};
  $self->{'_GAUGE'}->{'ARGS'} = $args;

  if (defined $self->{'_GAUGE'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
  }

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--gauge');
  $fmt = $self->append_format($fmt,'{{text}} {{height}} {{width}} {{percentage}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      percentage => $self->make_kvl($args,$args->{'percentage'}||'0'),
    );

  $self->{'_GAUGE'}->{'PERCENT'} = ($args->{'percentage'} || '0');
  $self->{'_GAUGE'}->{'FH'} = new FileHandle;
  $self->{'_GAUGE'}->{'FH'}->open("| $command");
  my $rv = $? >> 8;
  $self->{'_GAUGE'}->{'FH'}->autoflush(1);
  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  return($rv && $rv >= 1);
}
sub gauge_inc {
  my $self = $_[0];
  my $incr = $_[1] || 1;

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $self->{'_GAUGE'}->{'PERCENT'} += $incr;
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_dec {
  my $self = $_[0];
  my $decr = $_[1] || 1;

  return(0) unless defined $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $self->{'_GAUGE'}->{'PERCENT'} -= $decr;
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_set {
  my $self = $_[0];
  my $perc = $_[1] || $self->{'_GAUGE'}->{'PERCENT'} || 1;

  return(0) unless $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $self->{'_GAUGE'}->{'PERCENT'} = $perc;
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh $self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
# funky flicker... grr
sub gauge_text {
  my $self = $_[0];
  my $mesg = $_[1] || return(0);

  return(0) unless $self->{'_GAUGE'}->{'FH'};

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  print $fh "\nXXX\n\n".$mesg."\n\nXXX\n\n".$self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}->{'FH'}) ? 1 : 0));
}
sub gauge_stop {
  my $self = $_[0];

  return(0) unless $self->{'_GAUGE'}->{'FH'};

  my $args = $self->{'_GAUGE'}->{'ARGS'};
  my $fh = $self->{'_GAUGE'}->{'FH'};
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  $self->{'_GAUGE'}->{'FH'}->close();
  delete($self->{'_GAUGE'}->{'FH'});
  delete($self->{'_GAUGE'}->{'ARGS'});
  delete($self->{'_GAUGE'}->{'PERCENT'});
  delete($self->{'_GAUGE'});
  $self->rv('null');
  $self->rs('null');
  $self->ra('null');
  $self->_post($args);
  return(1);
}


1;

