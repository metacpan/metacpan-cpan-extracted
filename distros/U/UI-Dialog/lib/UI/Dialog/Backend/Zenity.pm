package UI::Dialog::Backend::Zenity;
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
use FileHandle;
use Cwd qw( abs_path );
use UI::Dialog::Backend;
use File::Slurp;
use String::ShellQuote;

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

	$self->{'_opts'}->{'literal'} = $cfg->{'literal'} || 0;
  $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();
  $self->{'_opts'}->{'window-icon'} = $cfg->{'window-icon'} || undef();
  $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
  $self->{'_opts'}->{'width'} = $cfg->{'width'} || 65;
  $self->{'_opts'}->{'height'} = $cfg->{'height'} || 10;
  $self->{'_opts'}->{'display'} = $cfg->{'display'} || undef();
  $self->{'_opts'}->{'name'} = $cfg->{'name'} || undef();
  $self->{'_opts'}->{'class'} = $cfg->{'class'} || undef();
  $self->{'_opts'}->{'bin'} = $self->_find_bin('zenity');
  $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
  $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
  $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
  $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
  $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
  $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
  $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
  $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
  $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
  unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the zenity binary could not be found at: ".$self->{'_opts'}->{'bin'});
  }

  $self->{'_opts'}->{'trust-input'} = $cfg->{'trust-input'} || 0;

  my $command = $self->{'_opts'}->{'bin'}." --version";
  my $version = `$command 2>&1`;
  chomp( $version );
  $self->{'ZENITY_VERSION'} = $version || '1';

  $self->{'test_mode'} = $cfg->{'test_mode'} if exists $cfg->{'test_mode'};
  $self->{'test_mode_result'} = '';

  return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

my $SIG_CODE = {};
sub _del_gauge {
  #: this is beyond self...
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
  $ENV{'ZENITY_CANCEL'} = '1';
  $ENV{'ZENITY_ERROR'}  = '254';
  $ENV{'ZENITY_ESC'}    = '255';
  $ENV{'ZENITY_EXTRA'}  = '3';
  $ENV{'ZENITY_HELP'}   = '2';
  $ENV{'ZENITY_OK'}     = '0';
  $fmt = $self->append_format_check($args,$fmt,'window-icon','--window-icon {{window-icon}}');
  $fmt = $self->append_format_check($args,$fmt,'width','--width {{width}}');
  $fmt = $self->append_format_check($args,$fmt,'height','--height {{height}}');
  $fmt = $self->append_format_check($args,$fmt,'display','--display {{display}}');
  $fmt = $self->append_format_check($args,$fmt,'name','--name {{name}}');
  $fmt = $self->append_format_check($args,$fmt,'class','--class {{class}}');

  return $fmt;
}

sub _is_bad_version {
  # my $self = shift();
  # my ($d_maj, $d_min, $d_mac) = ( 1, 4, 0 );
  # my ($z_maj, $z_min, $z_mac) = ( 0, 0, 0 );
  # my $zenity_version = $self->{'ZENITY_VERSION'} || '0.0.0';
  # if ( $zenity_version =~ m!^(\d+)\.(\d+)\.(\d+)$! ) {
  #     ($z_maj, $z_min, $z_mac) = ( $1, $2, $3 );
  # }
  # if ( ( $d_maj <  $z_maj                                        ) ||
  #      ( $d_maj == $z_maj && $d_min <  $z_min                    ) ||
  #      ( $d_maj == $z_maj && $d_min == $z_min && $d_mac < $z_mac )
  #    ) {
  #     return(0);
  # }
  return(1);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Override Inherited Methods
#:

# May want to override Backend::perform_command(). Not sure.
#: run command and return the rv and any text output from stderr
sub perform_command {
  my $self = $_[0];
  my $cmnd = $_[1];
  if ($self->is_unit_test_mode()) {
    $self->{'test_mode_result'} = $cmnd;
    return (0,'test_mode_result');
  }
  $self->_debug("perform_command: ".$cmnd.";");
  my $null_dev = $^O =~ /win32/i ? 'NUL:' : '/dev/null';
  my $tmp_stderr = $self->gen_tempfile_name();
  system($cmnd." 2> $null_dev > ".$tmp_stderr);
  my $rv = $? >> 8;
  my $text = read_file($tmp_stderr);
  unlink($tmp_stderr) if -f $tmp_stderr;
  $self->_debug("perform_command: stderr=".shell_quote($text),2);
  return ($rv,$text);
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Ask a binary question (Yes/No)
sub question {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--question --text {{text}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);
  if ($rv && $rv >= 1) {
		$self->ra("NO");
		$self->rs("NO");
  }
  else {
		$self->ra("YES");
		$self->rs("YES");
  }
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}
#: Zenity doesn't support alternation of the buttons like gdialog et al.
#: so here we just wrap for compliance.
sub yesno {
  my $self = shift();
  return($self->question('caller',((caller(1))[3]||'main'),@_));
}
sub noyes {
  my $self = shift();
  return($self->question('caller',((caller(1))[3]||'main'),@_));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text entry
sub entry {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'entry'} ||= ($args->{'init'} || $args->{'entry'});

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--entry');
  $fmt = $self->append_format_check($args,$fmt,'hide-text','--hide-text');
  $fmt = $self->append_format_check($args,$fmt,'entry','--entry-text {{entry}}');
  $fmt = $self->append_format($fmt,'--text {{text}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my ($rv,$text) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $text : 0);
}
sub inputbox {
  my $self = shift();
  return($self->entry('caller',((caller(1))[3]||'main'),@_));
}
sub password {
  my $self = shift();
  return($self->entry('caller',((caller(1))[3]||'main'),@_,'hide-text',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Text box
sub info {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  if ($args->{'error'}) {
    $fmt = $self->append_format($fmt,'--error');
  }
  elsif ($args->{'warning'}) {
    $fmt = $self->append_format($fmt,'--warning');
  }
  else {
    $fmt = $self->append_format($fmt,'--info');
  }
  $fmt = $self->append_format($fmt,'--text {{text}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}
sub infobox {
  my $self = shift();
  return($self->info('caller',((caller(1))[3]||'main'),@_));
}
sub msgbox {
  my $self = shift();
  return($self->info('caller',((caller(1))[3]||'main'),@_));
}
sub error {
  my $self = shift();
  return($self->info('caller',((caller(1))[3]||'main'),@_,'error',1));
}
sub warning {
  my $self = shift();
  return($self->info('caller',((caller(1))[3]||'main'),@_,'warning',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: File box
sub text_info {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $filename = $args->{'path'} || $args->{'filename'};
  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--text-info');
  $fmt = $self->append_format_check($args,$fmt,'editable','--editable');
  $fmt = $self->append_format($fmt,'--filename {{filename}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      filename => $self->make_kvl($args,$filename)
    );

  my ($rv,$text) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $text : 0);
}
sub textbox {
  my $self = shift();
  return($self->text_info('caller',((caller(1))[3]||'main'),@_));
}
sub editbox {
  my $self = shift();
  return($self->text_info('caller',((caller(1))[3]||'main'),@_,'editable',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: Lists
sub list {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--list');
  $args->{'checklist'} ||= 0;
  $args->{'radiolist'} ||= 0;
  if ($args->{'checklist'}) {
    $fmt = $self->append_format($fmt,'--checklist');
  }
  elsif ($args->{'radiolist'}) {
    $fmt = $self->append_format($fmt,'--radiolist');
  }
  $fmt = $self->append_format($fmt,"--separator '\\n'");

  if (ref($args->{'list'}) eq "ARRAY") {
    if ($args->{'checklist'}||$args->{'radiolist'}) {
      $fmt = $self->append_format($fmt,'--column " " --column " " --column " "');
    } else {
      $fmt = $self->append_format($fmt,'--column " " --column " "');
    }
    while (@{$args->{'list'}}) {
      my $item = shift(@{$args->{'list'}});
      $self->clean_format($args->{'trust-input'},\$item);
      my $info = shift(@{$args->{'list'}});
      if (ref($info) eq "ARRAY") {
        $self->clean_format($args->{'trust-input'},\$info->[0]);
        $fmt = $self->append_format($fmt,'"'.(($info->[1]) ? 'TRUE' : 'FALSE').'"');
        $fmt = $self->append_format($fmt,'"'.$item.'"');
        $fmt = $self->append_format($fmt,'"'.$info->[0].'"');
      }
      else {
        $self->clean_format($args->{'trust-input'},\$info);
        $fmt = $self->append_format($fmt,'"'.$item.'"');
        $fmt = $self->append_format($fmt,'"'.$info.'"');
      }
    }
  } else {
    croak("Programmer error. list argument missing or not an array.")
  }

  my $command = $self->prepare_command( $args, $fmt );

  if ($args->{'checklist'}) {
    my ($rv,$selected) = $self->command_array($command);
    $self->_post($args);
    return($rv == 0 ? $selected : 0) unless defined wantarray and wantarray;
    return($rv == 0 ? $self->ra() : (0));
  }
  my ($rv,$selected) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $selected : 0);
}
sub menu {
  my $self = shift();
  return($self->list('caller',((caller(1))[3]||'main'),@_));
}
sub checklist {
  my $self = shift();
  return($self->list('caller',((caller(1))[3]||'main'),@_,'checklist',1));
}
sub radiolist {
  my $self = shift();
  return($self->list('caller',((caller(1))[3]||'main'),@_,'radiolist',1));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: file select
sub fselect {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $filename = $args->{'path'} || $args->{'filename'} || abs_path();
  $args->{'path'} = $filename;
  $args->{'path'} = (-d $args->{'path'}) ? $args->{'path'}."/" : $args->{'path'};
  $args->{'path'} =~ s!/+!/!g;

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--file-selection');
  $fmt = $self->append_format($fmt,'--filename {{filename}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      filename => $self->make_kvl($args,$filename)
    );

  $self->_debug("fselect: ".$args->{'path'});
  my ($rv,$file) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $file : 0);
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: directory select
sub dselect {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  my $filename = $args->{'path'} || $args->{'filename'} || abs_path();
  $args->{'path'} = $filename;
  $args->{'path'} = (-d $args->{'path'}) ? $args->{'path'}."/" : $args->{'path'};
  $args->{'path'} =~ s!/+!/!g;

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--file-selection --directory');
  $fmt = $self->append_format($fmt,'--filename {{filename}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      filename => $self->make_kvl($args,$filename)
    );

  $self->_debug("fselect: ".$args->{'path'});
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

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--calendar');
  $fmt = $self->append_format_check($args,$fmt,'text','--text {{text}}');
  $fmt = $self->append_format_check($args,$fmt,'date-format','--date-format {{date-format}}');
  $fmt = $self->append_format_check($args,$fmt,'day','--day {{day}}');
  $fmt = $self->append_format_check($args,$fmt,'month','--month {{month}}');
  $fmt = $self->append_format_check($args,$fmt,'year','--year {{year}}');
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
#: progress

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
  $fmt = $self->append_format($fmt,'--progress');
  $fmt = $self->append_format_check($args,$fmt,'pulsate','--pulsate');
  $fmt = $self->append_format_check($args,$fmt,'text','--text {{text}}');
  $fmt = $self->append_format($fmt,'--percentage {{percentage}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      percentage => $self->make_kvl($args,$args->{'percentage'}||'0'),
    );

  $self->{'_GAUGE'}->{'PERCENT'} = ($args->{'percentage'} || '0');
  $self->{'_GAUGE'}->{'FH'} = new FileHandle;
  $self->{'_GAUGE'}->{'FH'}->open("| $command");
  my $rv = ($? >> 8);
  $self->{'_GAUGE'}->{'FH'}->autoflush(1);
  $self->rv($rv||'null');
  $self->ra('null');
  $self->rs('null');
  return($rv == 0 ? 1 : 0);
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
#: Textual updates are not supported by Zenity...
sub gauge_text {
  my $self = $_[0];
  my $mesg = $_[1] || return(0);

  my $fh = $self->{'_GAUGE'};
  return(0) unless $self->{'_GAUGE'};

	#    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
	#    print $fh "\nXXX\n\n".$mesg."\n\nXXX\n\n".$self->{'_GAUGE'}->{'PERCENT'}."\n";
  return(((defined $self->{'_GAUGE'}) ? 1 : 0));
}
sub gauge_stop {
  my $self = $_[0];
  my $args = $self->{'_GUAGE'}->{'ARGS'} ||
    $self->_merge_attrs( title => 'gauge_stop',
                         'caller' => ((caller(1))[3]||'main') );

  unless ($self->{'_GAUGE'}->{'FH'}) {
		$self->rv(129);
		$self->_post($args);
		return(0);
  }

  my $fh = $self->{'_GAUGE'}->{'FH'};
  $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
  $self->{'_GAUGE'}->{'FH'}->close();
  delete($self->{'_GAUGE'}->{'ARGS'});
  delete($self->{'_GAUGE'}->{'FH'});
  delete($self->{'_GAUGE'}->{'PERCENT'});
  delete($self->{'_GAUGE'});
  $self->rv('null');
  $self->rs('null');
  $self->ra('null');
  $self->_post($args);
  return(1);
}

1;

