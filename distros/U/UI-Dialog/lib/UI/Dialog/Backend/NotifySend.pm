package UI::Dialog::Backend::NotifySend;
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
use FileHandle;

#: Ideas:
# - implement debugging code...
# - what about tail("/file")?
# - and my $fh = tail_pipe() ?
#   (or pipe_start(), pipe_print() and pipe_close())
# - now here's a kicker, what about a "valid fonts" list and a
# suitable mechanism to use (and cache) `xlsfonts` to determine
# the font to use. Once the decision is made the decision should
# simply be enforced rather than revalidated again and again.

BEGIN {
    use vars qw( $VERSION @ISA );
    @ISA = qw( UI::Dialog::Backend );
    $VERSION = '1.21';
}

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = ((ref($_[0]) eq "HASH") ? $_[0] : (@_) ? { @_ } : {});
    my $self = {};
    bless($self, $class);
    $self->{'_opts'} = {};

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") { $self->{'PATHS'} = $CFG_PATH; }
		elsif ($CFG_PATH =~ m!:!) { $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ]; }
		elsif (-d $CFG_PATH) { $self->{'PATHS'} = [ $CFG_PATH ]; }
	} elsif ($ENV{'PATH'}) { $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ]; }
	else { $self->{'PATHS'} = ''; }

    $self->{'_opts'}->{'bin'} = $self->_find_bin('notify-send');
    unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the osd_cat binary could not be found at: ".$self->{'_opts'}->{'bin'});
    }

    $self->{'_opts'}->{'debug'} = $cfg->{'debug'} || undef;

    $self->{'_opts'}->{'urgency'} = $self->cfg_escape($cfg->{'urgency'});
    $self->{'_opts'}->{'expire-time'} = $self->cfg_escape($cfg->{'expire-time'});
    $self->{'_opts'}->{'app-name'} = $self->cfg_escape($cfg->{'app-name'});
    $self->{'_opts'}->{'icon'} = $self->cfg_escape($cfg->{'icon'});
    $self->{'_opts'}->{'category'} = $self->cfg_escape($cfg->{'category'});
    $self->{'_opts'}->{'hint'} = $self->cfg_escape($cfg->{'hint'});

    $self->{'_opts'}->{'trust-input'} =
      ( exists $cfg->{'trust-input'}
        && $cfg->{'trust-input'}==1
      ) ? 1 : 0;

    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Internal Methods
#:

my $SIG_CODE = {};
sub _del_display {
    my $CODE = $SIG_CODE->{$$};
    unless (not ref($CODE)) {
		delete($CODE->{'_DISPLAY'});
		$SIG_CODE->{$$} = "";
    }
}
sub _gen_opt_str {
    my $self = shift();
    my $args = shift();
    my $string = "";
    if ($args->{'urgency'}) {
		my $urgency = ($args->{'urgency'} =~ /^low|normal|critical$/i) ? lc($args->{'urgency'}) : undef;
		$string .= " --urgency='".$urgency."'" unless not defined $urgency;
    }
    if ($args->{'expire-time'}) {
		my $expire_time = ($args->{'expire-time'} =~ /^\d+$/i) ? $args->{'expire-time'} : undef;
		$string .= " --expire-time='".$expire_time."'" unless not defined $expire_time;
    }
    if ($args->{'app-name'}) {
        $string .= " --app-name=$args->{'app-name'}";
    }
    if ($args->{'icon'}) {
        $string .= " --icon=$args->{'icon'}";
    }
    if ($args->{'category'}) {
        $string .= " --category=$args->{'category'}";
    }
    if ($args->{'hint'}) {
        $string .= " --hint=$args->{'hint'}";
    }
    $self->_debug("notify-send: ".$string,3);
    return($string||" ");
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

sub notify_send {
    my $self = shift;
    my $args = $self->_merge_attrs(@_);

    my $cmnd = $self->{'_opts'}->{'bin'};
    $cmnd .= $self->_gen_opt_str($args);

    if (not exists $args->{'summary'} || not defined $args->{'summary'}) {
        croak("notify_send requires at least the summary text.");
    }

    if ($args->{'summary'}) {
        $cmnd .= " \"$args->{'summary'}\"";
    }
    if ($args->{'body'}) {
        $cmnd .= " \"$args->{'body'}\"";
    }
    $self->_debug("".$cmnd);
    system($cmnd." 2> /dev/null");
    return;
}

1;
