package UI::Dialog::Backend;
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
use File::Basename;
use Text::Wrap qw( wrap );
use String::ShellQuote;
use File::Slurp;

BEGIN {
  use vars qw($VERSION);
  $VERSION = '1.21';
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

#: not even really necessary as this class is inherited, and the constructor is
#: more often than not overridden by the backend inheriting it.
sub new {
  my $proto = shift();
  my $class = ref($proto) || $proto;
  my $cfg = ((ref($_[0]) eq "HASH") ? $_[0] : (@_) ? { @_ } : {});
  my $self = { '_opts' => $cfg };
  $self->{'test_mode'} = $cfg->{'test_mode'} if exists $cfg->{'test_mode'};
  $self->{'test_mode_result'} = '';
  bless($self, $class);
  return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Accessory Methods
#:

#: Return the path to the dialog variant binary
sub get_bin {
  return $_[0]->{'_opts'}{'bin'} if defined $_[0]->{'_opts'}{'bin'};
  return undef;
}

#: Provide the API interface to nautilus
sub nautilus {
  my $self = $_[0];
  my $nautilus = $self->{'_nautilus'} || {};
  unless (ref($nautilus) eq "UI::Dialog::Backend::Nautilus") {
		if ($self->_find_bin('nautilus')) {
			if (eval "require UI::Dialog::Backend::Nautilus; 1") {
				require UI::Dialog::Backend::Nautilus;
				$self->{'_nautilus'} = new UI::Dialog::Backend::Nautilus;
			}
		}
  }
  return($self->{'_nautilus'});
}

#: Provide the API interface to osd_cat (aka: xosd)
sub xosd {
  my $self = shift();
  my @args = (@_ %2 == 0) ? (@_) : ();
  my $xosd = $self->{'_xosd'} || {};
  unless (ref($xosd) eq "UI::Dialog::Backend::XOSD") {
		if ($self->_find_bin('osd_cat')) {
			if (eval "require UI::Dialog::Backend::XOSD; 1") {
				require UI::Dialog::Backend::XOSD;
				$self->{'_xosd'} = new UI::Dialog::Backend::XOSD (@args);
			}
		}
  }
  return($self->{'_xosd'});
}

#: Provide the API interface to notify-send
sub notify_send {
  my $self = shift();
  my @args = (@_ %2 == 0) ? (@_) : ();
  my $notify_send = $self->{'_notify_send'} || {};
  unless (ref($notify_send) eq "UI::Dialog::Backend::NotifySend") {
		if ($self->_find_bin('notify-send')) {
			if (eval "require UI::Dialog::Backend::NotifySend; 1") {
				require UI::Dialog::Backend::NotifySend;
				$self->{'_notify_send'} = new UI::Dialog::Backend::NotifySend (@args);
			}
		}
  }
  return($self->{'_notify_send'});
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: State Methods
#:

#: enable altering of attributes
sub attr {
  my $self = $_[0];
  my $name = $_[1];
  unless ($_[2]) {
		return($self->{'_opts'}->{$name}) unless not $self->{'_opts'}->{$name};
		return(undef());
  }
  if ($_[2] == 0 || $_[2] =~ /^NULL$/i) {
		$self->{'_opts'}->{$name} = 0;
  }
  else {
		$self->{'_opts'}->{$name} = $_[2];
  }
  return($self->{'_opts'}->{$name});
}

#: return the last response data as an ARRAY
sub ra {
  my $self = shift();
  my (@argv) = @_;
  if (@argv) {
    if (defined $argv[0] && $argv[0] =~ m!^null$!i) {
      $self->{'_state'}{'ra'} = [];
    } else {
      $self->{'_state'}{'ra'} = \@argv;
    }
  } else {
    $self->{'_state'}->{'ra'} ||= [];
  }
  return(@{ $self->{'_state'}->{'ra'} });
}

#: return the last response data as a SCALAR
sub rs {
  my $self = shift();
  my (@argv) = @_;
  if (@argv) {
    if (defined $argv[0] && $argv[0] =~ m!^null$!i) {
      $self->{'_state'}{'rs'} = '';
    } else {
      $self->{'_state'}{'rs'} = $argv[0];
    }
  }
  return($self->{'_state'}->{'rs'});
}

#: return the last exit code as a SCALAR
sub rv {
  my $self = shift();
  my (@argv) = @_;
  if (@argv) {
    if (defined $argv[0] && $argv[0] =~ m!^null$!i) {
      $self->{'_state'}{'rv'} = 0;
    } else {
      $self->{'_state'}{'rv'} = $argv[0];
    }
  }
  return($self->{'_state'}->{'rv'});
}

#: report on the state of the last dialog variant execution.
sub state {
  my $self = shift();
  my $rv = $self->rv() || 0;
  $self->_debug((join(" | ",(caller())))." > state() > is: ".($rv||'NULL'),2);
  if ($rv == 1 or $rv == 129) {
		return("CANCEL");
  }
  elsif ($rv == 2) {
		return("HELP");
  }
  elsif ($rv == 3) {
		return("EXTRA");
  }
  elsif ($rv == 254) {
		return("ERROR");
  }
  elsif ($rv == 255) {
		return("ESC");
  }
  elsif (not $rv or $rv =~ /^null$/i) {
		return("OK");
  }
  else {
		return("UNKNOWN(".$rv.")");
  }
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Preparation Methods
#

#: construct a HASHREF for command {{tag}} substitutions
sub make_kvt {
  my ($self,$args,$value) = @_;
  return
    {
     literal => ($args->{'literal'} || 0),
     width => ($args->{'width'}||'65'),
     trust => ($args->{'trust-input'} || 0),
     value => ($value || '')
    };
}
sub make_kvl {
  my ($self,$args,$value) = @_;
  return
    {
     literal => 1,
     width => ($args->{'width'}||'65'),
     trust => ($args->{'trust-input'} || 0),
     value => ($value || '')
    };
}

#: Helper method to generate a base format string, accepts additional
#: strings which are considered trusted programmer template input.
sub prepare_format {
  my $self = shift(@_);
  my $args = shift(@_);
  # start with our binary path
  my $fmt = $self->{'_opts'}{'bin'};
  $fmt = $self->append_format_check($args,$fmt,'title','--title {{title}}');
  return $fmt;
}

sub append_format {
  my ($self,$fmt,$value) = @_;
  if (ref($fmt) eq "SCALAR") {
    $$fmt .= ' '.$value;
  }
  else {
    $fmt .= ' '.$value;
  }
  return $fmt;
}

#: simple test and if true; append value to format
sub append_format_check {
  my ($self,$args,$fmt,$key,$value) = @_;
  if (exists $args->{$key} and defined $args->{$key} and $args->{$key}) {
    $fmt = $self->append_format($fmt,$value);
  }
  return $fmt;
}

sub clean_format {
  my ($self,$trust,$sref) = @_;
  unless (ref($sref) eq "SCALAR") {
    die("Programmer error. clean_format requires a SCALAR ref, found: ".ref($sref));
  }
  $$sref =~ s!\x00!!mg; # remove nulls
  #unless ($trust) {
    #$$sref =~ s!\`!'!mg;
    #$$sref =~ s!\$\(!\(!mg;
    #$$sref =~ s!\$!\\\$!mg;
  #}
  #$$sref =~ s!"!\\"!mg;       # escape double-quotes
  return $sref;
}

sub trust_quote {
  my ($self,$kv,$string) = @_;
  if ($kv->{trust}) {
    return '"'.$string.'"';
  }
  return shell_quote($string);
}

#: Given a command string "format" and any key/value replacement pairs,
#: construct the exec'able command string.
sub prepare_command {
  my $self = shift(@_);
  my $args = shift(@_);
  my $format = shift(@_);
  my (%rpl_add) = @_;
  my %rpl = ();
  foreach my $key (keys %{$args}) {
    $rpl{$key} = $self->make_kvl($args,$args->{$key}||'');
  }
  foreach my $key (keys %rpl_add) {
    $rpl{$key} = $rpl_add{$key};
  }
  foreach my $key (keys %rpl) {
    my $value = $rpl{$key}->{value}||'';
    if (ref($value) eq "ARRAY") {
      #: menu, checklist, radiolist...
      my $list = '';
      foreach my $item (@{$value}) {
        if (ref($item) eq "ARRAY") {
          # checklist, radiolist...
          if (@{$item} == 2) {
            $list .= ' '.$self->trust_quote($rpl{$key},$item->[0]);
            $list .= ' '.($item->[1] ? 'on' : 'off');
            next;
          }
          elsif (@{$item} == 3) {
            $list .= ' '.$self->trust_quote($rpl{$key},$item->[0]);
            $list .= ' '.($item->[1] ? 'on' : 'off');
            $list .= ' '.($self->trust_quote($rpl{$key},$item->[2])||1);
            next;
          }
          elsif (@{$item} == 4) {
            $list .= ' ' . $self->trust_quote($rpl{$key},$item->[0]);
            $list .= ' '.($item->[1] ? 'on' : 'off');
            $list .= ' '.($self->trust_quote($rpl{$key},$item->[2])||1);
            $list .= ' '.$self->trust_quote($rpl{$key},$item->[3]);
            next;
          }
        }
        # menu...
        $list .= ' '.$self->trust_quote($rpl{$key},$item);
      }
      $format =~ s!\{\{\Q${key}\E\}\}!${list}!mg;
    } # if (ref($value) eq "ARRAY")
    elsif ($key eq "list") {
      # assume this has been manipulated already?
      $format =~ s!\{\{\Q${key}\E\}\}!${value}!mg;
    }
    else {
      $value ||= '' unless defined $value;
      $value = "$1" if $value =~ m!^(\d+)$!;
      if (ref(\$value) eq "SCALAR") {
        unless ($rpl{$key}->{'trust'}||$rpl{$key}->{literal}) {
          $value = $self->_organize_text
            ( $value, $rpl{$key}->{width}, $rpl{$key}->{'trust'} );
        }
        $value = $self->trust_quote($rpl{$key},$value);
        $format =~ s!\{\{\Q${key}\E\}\}!${value}!mg;
      }
    }
  }
  return $format;
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Execution Methods
#:

sub is_unit_test_mode {
  my ($self) = @_;
  return 1
    if ( exists $self->{'test_mode'}
         &&
         defined $self->{'test_mode'}
         &&
         $self->{'test_mode'}
       );
  return 0;
}
sub get_unit_test_result {
  my ($self) = @_;
  return $self->{'test_mode_result'};
}

#: run command and return the rv and any text output from stderr
sub perform_command {
  my $self = $_[0];
  my $cmnd = $_[1];
  if ($self->is_unit_test_mode()) {
    $self->{'test_mode_result'} = $cmnd;
    return (0,'test_mode_result');
  }
  $self->_debug("perform_command: ".$cmnd.";");
  my $tmp_stderr = $self->gen_tempfile_name();
  system($cmnd." 2> ".$tmp_stderr);
  my $rv = $? >> 8;
  my $text = read_file($tmp_stderr);
  unlink($tmp_stderr) if -f $tmp_stderr;
  $self->_debug("perform_command: stderr=".shell_quote($text),2);
  return ($rv,$text);
}

#: execute a simple command (return the exit code only);
sub command_state {
  my $self = $_[0];
  my $cmnd = $_[1];
  if ($self->is_unit_test_mode()) {
    $self->{'test_mode_result'} = $cmnd;
    return 0;
  }
  my ($rv,$text) = $self->perform_command($cmnd);
  $self->_debug("command_state: rv=".$rv,1);
  $self->rv($rv);
  $self->rs('null');
  $self->ra('null');
  return($rv);
}

#: execute a command and return the exit code and one-line SCALAR
sub command_string {
  my $self = $_[0];
  my $cmnd = $_[1];
  if ($self->is_unit_test_mode()) {
    $self->{'test_mode_result'} = $cmnd;
    return (wantarray) ? (0,'') : '';
  }
  my ($rv,$text) = $self->perform_command($cmnd);
  chomp($text);
  $self->_debug("command_string: rv=".$rv.", rs=".shell_quote($text),1);
  $self->rv($rv);
  $self->rs($text);
  $self->ra('null');
  return($text) unless defined wantarray;
  return (wantarray) ? ($rv,$text) : $text;
}

#: execute a command and return the exit code and ARRAY of data
sub command_array {
  my $self = $_[0];
  my $cmnd = $_[1];
  if ($self->is_unit_test_mode()) {
    $self->{'test_mode_result'} = $cmnd;
    return (wantarray) ? (0,[]) : [];
  }
  my ($rv,$text) = $self->perform_command($cmnd);
  $self->_debug("command_array: rv=".$rv.", rs=".shell_quote($text),1);
  $self->rv($rv);
  $self->rs($text);
  # this is so hackish that it may just work
  my $alt_text = $text;
  $alt_text =~ s!\r??\n!__\\n!mg; #: replace newlines with "a symbol"
  my @alt_items = split(/_\\n/,$alt_text); #: split on "part symbol"
  my @alt_final = ();
  foreach my $alt_item (@alt_items) {
    my $i = $alt_item;
    $i =~ s!_$!!; #: remove the trailing bit of symbol
    push(@alt_final,$i);
  }
  $self->ra(@alt_final); #: final array can now contain blanks
  return([$self->ra()]) unless defined wantarray and wantarray;
  return (wantarray) ? ($rv,[$self->ra()]) : [$self->ra()];
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Utility Methods
#:

#: make some noise
sub beep {
  my $self = $_[0];
  return($self->_beep(1));
}

#: Clear terminal screen.
sub clear {
  my $self = $_[0];
  return($self->_clear(1));
}

# word-wrap a line
sub word_wrap {
  my $self = shift();
  my $width = shift() || 65;
  my $indent = shift() || "";
  my $sub_indent = shift() || "";
  $Text::Wrap::columns = $width - 3;
  my $raw = join("\n",@_);
  my $string = wrap($indent, $sub_indent, $raw);
  return(split(m!\n!,$string));
}

# generate a temporary file name
sub gen_tempfile_name {
  my $self = $_[0];
  my $template = $self->{'_opts'}->{'tempfiletemplate'} || "UI_Dialog_tempfile_XXXXX";
  if (eval("require File::Temp; 1")) {
		use File::Temp qw( tempfile );
		my ($fh,$filename) = tempfile( UNLINK => 1 ) or croak( "Can't create tempfile: $!" );
    if (wantarray) {
      return($fh,$filename);
    }
    else {
      close($fh); # actually required on win32
      return($filename);
    }
    return($fh,$filename);
  }
  else {
		my $mktemp = $self->_find_bin('mktemp');
		if ($mktemp && -x $mktemp) {
			chomp(my $tempfile = `$mktemp "$template"`);
			return($tempfile);
		}
    else {
			#pseudo-random filename coming up!
			my $tempdir = "/tmp";
			unless (-d $tempdir) {
				if (-d "/var/tmp") {
					$tempdir = "/var/tmp";
				}
        else {
					$tempdir = ".";
				}
			}
			$self->gen_random_string(5);
			my $tempfile = "UI_Dialog_tempfile_".$self->gen_random_string(5);
			while (-e $tempdir."/".$tempfile) {
				$self->gen_random_string(5);
				$tempfile = "UI_Dialog_tempfile_".$self->gen_random_string(5);
			}
			return($tempdir."/".$tempfile);
		}
  }
}

# generate a random string as a (possibly) suitable failover option in the
# event that File::Temp is not installed and the 'mktemp' program does not
# exist in the path.
sub gen_random_string {
  my $self = $_[0];
  my $length = $_[1] || 5;
  my $string = "";
  my $counter = 0;
  while ($counter < $length) {
		# 33 - 127
		my $num = rand(128);
		while ($num < 33 or $num > 127) {
      $num = rand(128);
    }
		$string .= chr($num);
		$counter++;
  }
  return($string);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Widget Wrapping Methods
#:

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

  $self->rv('NULL');
  $self->rs('NULL');
  $self->ra('NULL');

  $self->_beep($args->{'beepbefore'});

  my $cwd = abs_path();
  $args->{'path'} ||= abs_path();
  my $pre_selection = $args->{'path'};
  my $path = $args->{'path'};
  if (-f $pre_selection) {
    $path = dirname($path);
  }
  if (!$path || $path =~ /^(\.|\.\/)$/) {
    $path = $cwd;
  }
  my $user_selection = $pre_selection;
  my ($menu,$list) = ([],[]);
 FSEL: while ($self->state() ne "ESC" && $self->state() ne "CANCEL") {
    my $entries = ($args->{'dselect'}) ? ['[new directory]'] :  ['[new file]'];
    ($menu, $list) = $self->_list_dir($path, $entries, $args->{'dselect'});
    $user_selection = $self->menu
      ( height=>$args->{'height'},
        width=>$args->{'width'},
        listheight=>($args->{'listheight'}||$args->{'menuheight'}),
        title=>$args->{'title'},
        backtitle=>$args->{'backtitle'},
        text=>"Select a ".($args->{'dselect'}?'path':'file').": ".$path,
        list=>$menu
      );
		if ($self->state() eq "CANCEL") {
			$self->rv(1);
			$self->rs('NULL');
			$self->ra('NULL');
			last FSEL;
		}
    elsif ($user_selection ne "") {
      if ($list->[($user_selection - 1 || 0)] =~ /^\[(new\sdirectory|new\sfile)\]$/) {
				my $nfn;
				while (!$nfn || -e $path."/".$nfn) {
          $nfn = $self->inputbox
            ( height=>$args->{'height'},
              width=>$args->{'width'},
              title=>$args->{'title'},
              text=>'Enter a name (will have a base directory of: '.$path.')'
            );
					next FSEL if $self->state() eq "ESC" or $self->state() eq "CANCEL";
					if (-e $path."/".$nfn) {
            $self->msgbox
              ( title=>'error',
                text=>$path."/".$nfn.' exists. Choose another name please.');
          }
				}
        $user_selection = $path."/".$nfn;
        $user_selection =~ s!/$!! unless $user_selection =~ m!^/$!;
        $user_selection =~ s!/\./!/!g; $user_selection =~ s!/+!/!g;
				last FSEL;
			}
      elsif ($list->[($user_selection - 1 || 0)] eq "../") {
				$path = dirname($path);
			}
      elsif ($list->[($user_selection - 1 || 0)] eq "./") {
        $user_selection = $path;
        $user_selection =~ s!/$!! unless $user_selection =~ m!^/$!;
        $user_selection =~ s!/\./!/!g; $user_selection =~ s!/+!/!g;
				last FSEL;
			}
      elsif (-d $path."/".$list->[($user_selection - 1 || 0)]) {
        $path = $path."/".$list->[($user_selection - 1 || 0)];
			}
      elsif (-e $path."/".$list->[($user_selection - 1 || 0)]) {
        $user_selection = $path."/".$list->[($user_selection - 1 || 0)];
        $user_selection =~ s!/$!! unless $user_selection =~ m!^/$!;
        $user_selection =~ s!/\./!/!g; $user_selection =~ s!/+!/!g;
				last FSEL;
			}
		}
    $user_selection = undef();
		$path =~ s!(/*)!/!; $path =~ s!/\./!/!g;
  }
  $self->_beep($args->{'beepafter'});
  my $rv = $self->rv();
  $self->ra('NULL');
  if ($rv && $rv >= 1) {
		$self->rs('NULL');
		return(0);
  }
  else {
    $self->rs($user_selection);
    return($user_selection);
  }
}

#:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#: directory selection
sub dselect {
  my $self = shift();
  my $caller = (caller(1))[3] || 'main';
  $caller = ($caller =~ /^UI\:\:Dialog\:\:Backend\:\:/) ? ((caller(2))[3]||'main') : $caller;
  if ($_[0] && $_[0] eq 'caller') {
    shift(); $caller = shift();
  }
  my $args = $self->_pre($caller,@_);
  my $dirname;
  $self->rv('NULL');
  $self->rs('NULL');
  $self->ra('NULL');
  while (not $dirname && $self->state() !~ /^(CANCEL|ESC|ERROR)$/) {
		$dirname = $self->fselect(@_,'dselect',1);
		if ($self->state() =~ /^(CANCEL|ESC|ERROR)$/) {
			return(0);
		}
		unless (not $dirname) {
			# if it's a directory or not exist (assume new dir)
			unless (-d $dirname || not -e $dirname) {
				$self->msgbox( text => $dirname . " is not a directory.\nPlease select a directory." );
				$dirname = undef();
			}
		}
  }
  return($dirname||'');
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Backend Methods
#:

sub _pre {
  my $self = shift();
  my $caller = shift();
  my $args = $self->_merge_attrs(@_);
  $args->{'caller'} = $caller;
  my $class = ref($self);

  my $CODEREFS = $args->{'callbacks'};
  if (ref($CODEREFS) eq "HASH") {
		my $PRECODE = $CODEREFS->{'PRE'};
		if (ref($PRECODE) eq "CODE") {
			&$PRECODE($args,$self->state());
		}
  }

  $self->_beep($args->{'beepbefore'});
  $self->_clear($args->{'clearbefore'});
  return($args);
}

sub _post {
  my $self = shift();
  my $args = shift() || {};
  my $class = ref($self);

  $self->_beep($args->{'beepafter'});
  $self->_clear($args->{'clearafter'});

  my $CODEREFS = $args->{'callbacks'};
  if (ref($CODEREFS) eq "HASH") {
		my $state = $self->state();
		if ($state eq "OK") {
			my $OKCODE = $CODEREFS->{'OK'};
			if (ref($OKCODE) eq "CODE") {
				&$OKCODE($args);
			}
		}
    elsif ($state eq "ESC") {
			my $ESCCODE = $CODEREFS->{'ESC'};
			if (ref($ESCCODE) eq "CODE") {
				&$ESCCODE($args);
			}
		}
    elsif ($state eq "CANCEL") {
			my $CANCELCODE = $CODEREFS->{'CANCEL'};
			if (ref($CANCELCODE) eq "CODE") {
				&$CANCELCODE($args);
			}
		}
		my $POSTCODE = $CODEREFS->{'POST'};
		if (ref($POSTCODE) eq "CODE") {
			&$POSTCODE($args,$state);
		}
  }

  return(1);
}


#: indent and organize the text argument
sub _organize_text {
  my $self = $_[0];
  my $text = $_[1];
  my $width = $_[2] || 65;
  my $trust = (exists $_[3] && defined $_[3]) ? $_[3] : '0';
  $width -= 4; # take account of borders?
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
  $text = undef;

  @array = $self->word_wrap($width,"","",@array);

  if ($self->{'scale'}) {
    foreach my $line (@array) {
      my $s_line = $line;#$self->__TRANSLATE_CLEAN($line);
      $s_line =~ s!\[A\=\w+\]!!gi;
      $self->{'width'} = length($s_line) + 5
        if ($self->{'width'} - 5) < length($s_line)
        && (length($s_line) <= $self->{'max-scale'});
    }
  }

  foreach my $line (@array) {
    my $pad;
    $self->clean_format( $trust, \$line );
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
      $text .= (" " x $pad).$line."\n";
    }
    else {
      $text .= $line."\n";
    }
  }
  $text = $self->_strip_text($text);
  chomp($text) if $text;
  return($text);
}

#: merge the arguments with the default attributes, and arguments override defaults.
sub _merge_attrs {
  my $self = shift();
  my $args = (@_ % 2) ? { @_, '_odd' } : { @_ };
  my $defs = $self->{'_opts'};

  foreach my $def (keys(%$defs)) {
    # default unless exists
    $args->{$def} = $defs->{$def} unless exists $args->{$def};
  }

  # alias 'filename' and 'file' to path
  $args->{'path'} = (($args->{'filename'}) ? $args->{'filename'} :
                     ($args->{'file'}) ? $args->{'file'} :
                     ($args->{'path'}) ? $args->{'path'} : "");

  $args->{'clear'} = $args->{'clearbefore'} || $args->{'clearafter'} || $args->{'autoclear'} || 0;
  $args->{'beep'} = $args->{'beepbefore'} || $args->{'beepafter'} || $args->{'autobeep'} || 0;
  return($args);
}

#: search through the given paths for a specific variant
sub _find_bin {
  my $self = $_[0];
  my $variant = $_[1];
  $self->{'PATHS'} = ((ref($self->{'PATHS'}) eq "ARRAY") ? $self->{'PATHS'} :
                      ($self->{'PATHS'}) ? [ $self->{'PATHS'} ] :
                      [ '/bin', '/usr/bin', '/usr/local/bin', '/opt/bin' ]);
  foreach my $PATH (@{$self->{'PATHS'}}) {
		return($PATH . '/' . $variant)
      unless not -x $PATH . '/' . $variant;
  }
  return(0);
}

#: clean the text arguments of all colour codes, alignments and attributes.
sub _strip_text {
  my $self = $_[0];
  my $text = $_[1];
  $text ||= '';
  $text =~ s!\\Z[0-7bBuUrRn]!!gmi;
  $text =~ s!\[[AC]=\w+\]!!gmi;
  $text =~ s!\[/?[BURN]\]!!gmi;
  return($text);
}

#: is this a BSD system?
sub _is_bsd {
  my $self = shift();
  return(1) if $^O =~ /bsd/i;
  return(0);
}

#: gather a list of the contents of a directory and return it in
#: two forms, one is the "simple" list of all the filenames and the
#: other is a 'menu' list corresponding to the simple list.
sub _list_dir {
  my $self = shift();
  my $path = shift() || return();
  my $pref = shift();
  my $paths_only = (@_ == 1 && $_[0] == 1) ? 1 : 0;
  my (@listing,@list);
  if (opendir(GETDIR,$path)) {
		my @dir_data = readdir(GETDIR);
		closedir(GETDIR);
		if ($pref) {
      push(@listing,@{$pref});
    }
		foreach my $dir (sort(grep { -d $path."/".$_ } @dir_data)) {
      push(@listing,$dir."/");
    }
    unless ($paths_only) {
      foreach my $item (sort(grep { !-d $path."/".$_ } @dir_data)) {
        push(@listing,$item);
      }
    }
		my $c = 1;
    foreach my $item (@listing) {
      push(@list,"$c",$item); $c++;
    }
		return(\@list,\@listing);
  }
  else {
		return("failed to read directory: ".$path);
  }
}

sub _debug {
  my $self = $_[0];
  my $mesg = $_[1] || 'null debug message given!';
  my $rate = $_[2] || 1;
  return() unless $self->{'_opts'}->{'debug'} and $self->{'_opts'}->{'debug'} >= $rate;
  chomp($mesg);
  print STDERR "Debug: ".$mesg."\n";
}
sub _error {
  my $self = $_[0];
  my $mesg = $_[1] || 'null error message given!';
  chomp($mesg);
  print STDERR "Error: ".$mesg."\n";
}

#: really make some noise
sub _beep {
  my $self = $_[0];
  my $beep = $_[1];
  unless (not $beep) {
		if (-x $self->{'_opts'}->{'beepbin'}) {
			return(eval { system($self->{'_opts'}->{'beepbin'}); 1; });
		}
    else {
			return (1) unless $ENV{'TERM'} && $ENV{'TERM'} ne "dumb";
			print STDERR "\a";
		}
  }
  return(1);
}

#: The actual clear action.
sub _clear {
  my $self = $_[0];
  my $clear = $_[1] || 0;
  # Useless with GUI based variants so we return here.
  # Is the use of the "dumb" TERM appropriate? need feedback.
  return (1) unless $ENV{'TERM'} && $ENV{'TERM'} ne "dumb";
  unless (not $clear and not $self->{'_opts'}->{'autoclear'}) {
		$self->{'_clear'} ||= `clear`;
		print STDOUT $self->{'_clear'};
  }
  return(1);
}



1;
