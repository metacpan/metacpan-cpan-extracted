package UI::Dialog::Backend::KDialog;
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
use Cwd qw( abs_path );
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
  $self->{'_opts'}->{'callbacks'} = $cfg->{'callbacks'} || undef();
  $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef();
  $self->{'_opts'}->{'caption'} = $cfg->{'caption'} || undef();
  $self->{'_opts'}->{'icon'} = $cfg->{'icon'} || undef();
  $self->{'_opts'}->{'miniicon'} = $cfg->{'miniicon'} || undef();
  $self->{'_opts'}->{'title'} = $cfg->{'title'} || undef();
  $self->{'_opts'}->{'width'} = $cfg->{'width'} || 65;
  $self->{'_opts'}->{'height'} = $cfg->{'height'} || 10;
  $self->{'_opts'}->{'bin'} ||= $self->_find_bin('kdialog');
  $self->{'_opts'}->{'autoclear'} = $cfg->{'autoclear'} || 0;
  $self->{'_opts'}->{'clearbefore'} = $cfg->{'clearbefore'} || 0;
  $self->{'_opts'}->{'clearafter'} = $cfg->{'clearafter'} || 0;
  $self->{'_opts'}->{'beepbin'} = $cfg->{'beepbin'} || $self->_find_bin('beep') || '/usr/bin/beep';
  $self->{'_opts'}->{'beepbefore'} = $cfg->{'beepbefore'} || 0;
  $self->{'_opts'}->{'beepafter'} = $cfg->{'beepafter'} || 0;
  $self->{'_opts'}->{'timeout'} = $cfg->{'timeout'} || 0;
  $self->{'_opts'}->{'wait'} = $cfg->{'wait'} || 0;
  unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the kdialog binary could not be found at: ".$self->{'_opts'}->{'bin'});
  }

  $self->{'_opts'}->{'trust-input'} = $cfg->{'trust-input'} || 0;

  $self->{'test_mode'} = $cfg->{'test_mode'} if exists $cfg->{'test_mode'};
  $self->{'test_mode_result'} = '';

  return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

sub append_format_base {
  my ($self,$args,$fmt) = @_;
  $fmt = $self->append_format_check($args,$fmt,'caption','--caption {{caption}}');
  $fmt = $self->append_format_check($args,$fmt,'icon','--icon {{icon}}');
  $fmt = $self->append_format_check($args,$fmt,'miniicon','--miniicon {{miniicon}}');
  if ($self->{'_opts'}->{'force-no-separate-output'}) {
    delete $args->{'separate-output'};
  }
  else {
    $fmt = $self->append_format_check($args,$fmt,"separate-output","--separate-output");
  }
  return $fmt;
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

  $args->{'yesno'} ||= "yesno";

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--'.$args->{'yesno'}.' {{text}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);
  if ($rv && $rv >= 1) {
    $self->ra("NO");
    $self->rs("NO");
    $self->rv($rv);
  } else {
    $self->ra("YES");
    $self->rs("YES");
    $self->rv('null');
  }
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}
sub yesnocancel {
  my $self = shift();
  return($self->yesno('caller',((caller(1))[3]||'main'),@_,'yesno','yesnocancel'));
}
sub warningyesno {
  my $self = shift();
  return($self->yesno('caller',((caller(1))[3]||'main'),@_,'yesno','warningyesno'));
}
sub warningyesnocancel {
  my $self = shift();
  return($self->yesno('caller',((caller(1))[3]||'main'),@_,'yesno','warningyesnocancel'));
}
#: Broken documented "feature"
# sub warningcontinuecancel {
#     my $self = shift();
#     return($self->yesno(@_,'yesno','warningcontinuecancel'));
# }
sub noyes {
  my $self = shift();
  return($self->yesno('caller',((caller(1))[3]||'main'),@_));
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

  $args->{'inputbox'} ||= 'inputbox';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--'.$args->{'inputbox'}.' {{text}} {{entry}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
      entry => $self->make_kvl($args,($args->{'init'}||$args->{'entry'})),
    );

  my ($rv,$text) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $text : 0);
}
sub password {
  my $self = shift();
  return($self->inputbox('caller',((caller(1))[3]||'main'),@_,'inputbox','password'));
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
  $fmt = $self->append_format($fmt,'--'.$args->{'msgbox'}.' {{text}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      text => $self->make_kvt($args,$args->{'text'}),
    );

  my $rv = $self->command_state($command);
  $self->_post($args);
  return($rv == 0 ? 1 : 0);
}
sub error {
  my $self = shift();
  return($self->msgbox('caller',((caller(1))[3]||'main'),@_,'msgbox','error'));
}
sub sorry {
  my $self = shift();
  return($self->msgbox('caller',((caller(1))[3]||'main'),@_,'msgbox','sorry'));
}
sub infobox {
  my $self = shift();
  return($self->msgbox('caller',((caller(1))[3]||'main'),@_,'msgbox','msgbox'));
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
  $fmt = $self->append_format($fmt,'--textbox');
  $fmt = $self->append_format($fmt,'{{path}} {{height}} {{width}}');
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,($args->{'filename'}||$args->{'path'}||'.')),
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

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output');
  $fmt = $self->append_format($fmt,'--menu');
  $fmt = $self->append_format($fmt,'{{text}} {{list}}');
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
  $fmt = $self->append_format($fmt,'{{text}} {{list}}');
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
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);

  $args->{'fselect'} ||= 'getopenfilename';

  my $fmt = $self->prepare_format($args);
  $fmt = $self->append_format_base($args,$fmt);
  $fmt = $self->append_format($fmt,'--separate-output');
  $fmt = $self->append_format($fmt,'--'.$args->{'fselect'});
  if ($args->{'getexistingdirectory'}) {
    $fmt = $self->append_format($fmt,'{{path}}');
  } else {
    $fmt = $self->append_format($fmt,'{{path}} {{filter}}');
  }
  my $command = $self->prepare_command
    ( $args, $fmt,
      path => $self->make_kvl($args,($args->{'path'}||abs_path())),
      filter => $self->make_kvl($args,($args->{'filter'}||'*'))
    );

  my ($rv,$selected) = $self->command_string($command);
  $self->_post($args);
  return($rv == 0 ? $selected : 0);
}
sub getopenfilename {
  my $self = shift();
  return($self->fselect('caller',((caller(1))[3]||'main'),@_,'fselect','getopenfilename'));
}
sub getsavefilename {
  my $self = shift();
  return($self->fselect('caller',((caller(1))[3]||'main'),@_,'fselect','getsavefilename'));
}
sub getopenurl {
  my $self = shift();
  return($self->fselect('caller',((caller(1))[3]||'main'),@_,'fselect','getopenurl'));
}
sub getsaveurl {
  my $self = shift();
  return($self->fselect('caller',((caller(1))[3]||'main'),@_,'fselect','getsaveurl'));
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: directory select
sub dselect {
  my $self = shift();
  return($self->fselect('caller',((caller(1))[3]||'main'),@_,'fselect','getexistingdirectory'));
}
sub getexistingdirectory {
  my $self = shift();
  return($self->fselect('caller',((caller(1))[3]||'main'),@_,'fselect','getexistingdirectory'));
}


1;
