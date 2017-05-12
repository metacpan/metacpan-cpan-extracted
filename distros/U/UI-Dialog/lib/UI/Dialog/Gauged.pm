package UI::Dialog::Gauged;
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

BEGIN {
    use vars qw($VERSION);
    $VERSION = '1.21';
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = {@_} || {};
    my $self = {};
    bless($self, $class);

    $self->{'debug'} = $cfg->{'debug'} || 0;

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") { $self->{'PATHS'} = $CFG_PATH; }
		elsif ($CFG_PATH =~ m!:!) { $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ]; }
		elsif (-d $CFG_PATH) { $self->{'PATHS'} = [ $CFG_PATH ]; }
	} elsif ($ENV{'PATH'}) { $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ]; }
	else { $self->{'PATHS'} = ''; }

    if (not $cfg->{'order'} and ($ENV{'DISPLAY'} && length($ENV{'DISPLAY'}) > 0)) {
		#: Pick a GUI mode 'cause a DISPLAY was detected
		if ($ENV{'TERM'} =~ /^dumb$/i) {
			# we're running free of a terminal
			$cfg->{'order'} = [ 'zenity', 'xdialog' ];
		} else {
			# we're running in a terminal
			$cfg->{'order'} = [ 'zenity', 'xdialog', 'cdialog', 'whiptail' ];
		}
    }
    # verify and repair the order
    $cfg->{'order'} = ((ref($cfg->{'order'}) eq "ARRAY") ? $cfg->{'order'} :
					   ($cfg->{'order'}) ? [ $cfg->{'order'} ] :
					   [ 'cdialog', 'whiptail' ]);

    $self->_debug("ENV->UI_DIALOGS: ".($ENV{'UI_DIALOGS'}||'NULL'),2);
    $cfg->{'order'} = [ split(/\:/,$ENV{'UI_DIALOGS'}) ] if $ENV{'UI_DIALOGS'};

    $self->_debug("ENV->UI_DIALOG: ".($ENV{'UI_DIALOG'}||'NULL'),2);
    unshift(@{$cfg->{'order'}},$ENV{'UI_DIALOG'}) if $ENV{'UI_DIALOG'};

    $cfg->{'trust-input'} =
      ( exists $cfg->{'trust-input'}
        && $cfg->{'trust-input'}==1
      ) ? 1 : 0;

    my @opts = ();
    foreach my $opt (keys(%$cfg)) { push(@opts,$opt,$cfg->{$opt}); }

    $self->_debug("order: @{$cfg->{'order'}}",2);

    if (ref($cfg->{'order'}) eq "ARRAY") {
		foreach my $try (@{$cfg->{'order'}}) {
			if ($try =~ /^zenity$/i) {
				$self->_debug("trying zenity",2);
				if (eval "require UI::Dialog::Backend::Zenity; 1" && $self->_has_variant('zenity')) {
					require UI::Dialog::Backend::Zenity;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::Zenity (@opts);
					$self->_debug("using zenity",2);
					last;
				} else { next; }
			} elsif ($try =~ /^(?:xdialog|X)$/i) {
				$self->_debug("trying xdialog",2);
				if (eval "require UI::Dialog::Backend::XDialog; 1" && $self->_has_variant('Xdialog')) {
					require UI::Dialog::Backend::XDialog;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::XDialog (@opts,'XDIALOG_HIGH_DIALOG_COMPAT',1);
					$self->_debug("using xdialog",2);
					last;
				} else { next; }
			} elsif ($try =~ /^(?:dialog|cdialog)$/i) {
				$self->_debug("trying cdialog",2);
				if (eval "require UI::Dialog::Backend::CDialog; 1" && $self->_has_variant('dialog')) {
					require UI::Dialog::Backend::CDialog;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::CDialog (@opts);
					$self->_debug("using cdialog",2);
					last;
				} else { next; }
			} elsif ($try =~ /^whiptail$/i) {
				$self->_debug("trying whiptail",2);
				if (eval "require UI::Dialog::Backend::Whiptail; 1" && $self->_has_variant('whiptail')) {
					require UI::Dialog::Backend::Whiptail;
					$self->{'_ui_dialog'} = new UI::Dialog::Backend::Whiptail (@opts);
					$self->_debug("using whiptail",2);
					last;
				} else { next; }
			} else {
				# we don't know what they're asking for... try UI::Dialog...
				if (eval "require UI::Dialog; 1") {
					require UI::Dialog;
					$self->{'_ui_dialog'} = new UI::Dialog (@opts);
					$self->_debug(ref($self)." unknown backend: '".$try."', using UI::Dialog instead.",2);
					last;
				} else { next; }
			}
		}
    } else {
		carp("Failed to load any suitable dialog variant backend.");
    }

    ref($self->{'_ui_dialog'}) or croak("unable to load suitable backend.");
    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Private Methods
#:

#: purely internal usage
sub _debug {
    my $self = $_[0];
    my $mesg = $_[1] || 'null error message given!';
    my $rate = $_[2] || 1;
    return() unless $self->{'debug'} and $self->{'debug'} >= $rate;
    chomp($mesg);
    print STDERR "Debug: ".$mesg."\n";
}

sub _has_variant {
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

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

#: dialog variant state methods:
sub state     { return(shift()->{'_ui_dialog'}->state(@_));     }
sub ra        { return(shift()->{'_ui_dialog'}->ra(@_));        }
sub rs        { return(shift()->{'_ui_dialog'}->rs(@_));        }
sub rv        { return(shift()->{'_ui_dialog'}->rv(@_));        }

#: Frills
#:    all backends support nautilus scripts.
sub nautilus  { return(shift()->{'_ui_dialog'}->nautilus(@_));  }
#:    same with osd_cat (aka: xosd).
sub xosd      { return(shift()->{'_ui_dialog'}->xosd(@_));  }
#:    Beep & Clear may have no affect when using GUI backends
sub beep      { return(shift()->{'_ui_dialog'}->beep(@_));      }
sub clear     { return(shift()->{'_ui_dialog'}->clear(@_));     }

#: widget methods:
sub yesno     { return(shift()->{'_ui_dialog'}->yesno(@_));     }
sub msgbox    { return(shift()->{'_ui_dialog'}->msgbox(@_));    }
sub inputbox  { return(shift()->{'_ui_dialog'}->inputbox(@_));  }
sub password  { return(shift()->{'_ui_dialog'}->password(@_));  }
sub textbox   { return(shift()->{'_ui_dialog'}->textbox(@_));   }
sub menu      { return(shift()->{'_ui_dialog'}->menu(@_));      }
sub checklist { return(shift()->{'_ui_dialog'}->checklist(@_)); }
sub radiolist { return(shift()->{'_ui_dialog'}->radiolist(@_)); }
sub fselect   { return(shift()->{'_ui_dialog'}->fselect(@_));   }
sub dselect   { return(shift()->{'_ui_dialog'}->dselect(@_));   }

# gauge methods
sub gauge_start { return(shift()->{'_ui_dialog'}->gauge_start(@_)); }
sub gauge_stop  { return(shift()->{'_ui_dialog'}->gauge_stop(@_));  }
sub gauge_inc   { return(shift()->{'_ui_dialog'}->gauge_inc(@_));   }
sub gauge_dec   { return(shift()->{'_ui_dialog'}->gauge_dec(@_));   }
sub gauge_set   { return(shift()->{'_ui_dialog'}->gauge_set(@_));   }
sub gauge_text  { return(shift()->{'_ui_dialog'}->gauge_text(@_));  }


1;
