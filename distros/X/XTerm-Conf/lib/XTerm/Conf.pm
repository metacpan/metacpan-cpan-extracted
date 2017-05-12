# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2006,2008,2009,2012,2014,2015,2017 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de/eserte/
#

package XTerm::Conf;

use 5.006; # qr, autovivified filehandles

# Plethora of xterm control sequences:
# http://rtfm.etla.org/xterm/ctlseq.html

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION = '0.11';

require Exporter;
@ISA = qw(Exporter);
@EXPORT    = qw(xterm_conf);
@EXPORT_OK = qw(xterm_conf_string terminal_is_supported);

use Getopt::Long 2.24; # OO interface

use constant BEL => "";
use constant ESC => "";

use constant IND   => ESC . "D"; # Index
use constant IND_8   => chr 0x84;
use constant NEL   => ESC . "E"; # Next Line
use constant NEL_8   => chr 0x85;
use constant HTS   => ESC . "H"; # Tab Set
use constant HTS_8   => chr 0x88;
use constant RI    => ESC . "M"; # Reverse Index
use constant RI_8    => chr 0x8d;
use constant SS2   => ESC . "N"; # Single Shift Select of G2 Character Set: affects next character only
use constant SS2_8   => chr 0x8e;
use constant SS3   => ESC . "O"; # Single Shift Select of G3 Character Set: affects next character only
use constant SS3_8   => chr 0x8f;
use constant DCS   => ESC . "P"; # Device Control String
use constant DCS_8   => chr 0x90;
use constant SPA   => ESC . "V"; # Start of Guarded Area
use constant SPA_8   => chr 0x96;
use constant EPA   => ESC . "W"; # End of Guarded Area
use constant EPA_8   => chr 0x97;
use constant SOS   => ESC . "X"; # Start of String
use constant SOS_8   => chr 0x98;
use constant DECID => ESC . "Z"; # Return Terminal ID Obsolete form of CSI c (DA).
use constant DECID_8 => chr 0x9a;
use constant CSI   => ESC . "["; # Control Sequence Introducer
use constant CSI_8   => chr 0x9b;
use constant ST    => ESC . "\\"; # String Terminator
use constant ST_8    => chr 0x9c;
use constant OSC   => ESC . "]";
use constant OSC_8   => chr 0x9d;
use constant PM    => ESC . "^"; # Privacy Message
use constant PM_8    => chr 0x9e;
use constant APC   => ESC . "_"; # Application Program Command
use constant APC_8   => chr 0x9f;

my %o;
my $need_reset_terminal;

sub xterm_conf_string {
    local @ARGV = @_;

    %o = ();

    my $p = Getopt::Long::Parser->new;
    $p->configure('no_ignore_case');
    $p->getoptions(\%o,
	       "iconname|n=s",
	       "title|T=s",
	       "fg|foreground=s",
	       "bg|background=s",
	       "textcursor|cr=s",
	       "mousefg|mouseforeground|ms=s",
	       "mousebg|mousebackground=s",
	       "tekfg|tekforeground=s",
	       "tekbg|tekbackground=s",
	       "highlightcolor|hc=s",
	       "bell",
	       "cs=s",
	       "fullreset",
	       "softreset",
	       "smoothscroll!", # no visual effect
	       "reverse|reversevideo!",
	       "origin!",
	       "wraparound!",
	       "autorepeat!",
	       "formfeed!",
	       "showcursor!",
	       "showscrollbar!", # rxvt
	       "tektronix!",
	       "marginbell!",
	       "reversewraparound!",
	       "backsendsdelete!",
	       "bottomscrolltty!", # rxvt
	       "bottomscrollkey!", # rxvt
	       "metasendsesc|metasendsescape!",
	       "scrollregion=s",
	       "deiconify",
	       "iconify",
	       "geometry=s",
	       "raise",
	       "lower",
	       "refresh|x11refresh",
	       "maximize",
	       "unmaximize",
	       "xproperty|x11property=s",
	       "font=s",
	       "nextfont",
	       "prevfont",
	       "report=s",
	       "debugreport",
	       "resize=i",
	      )
	or _usage();
    die _usage() if (@ARGV);

    my $rv = "";

    $rv .= BEL if $o{bell};

 CS_SWITCH: {
	if (defined $o{cs}) {
	    $rv .= (ESC . '%G'), last if $o{cs} =~ m{^utf-?8$}i;
	    $rv .= (ESC . '%@'), last if $o{cs} =~ m{^(latin-?1|iso-?8859-?1)$}i;
	    warn "Unhandled -cs parameter $o{cs}\n";
	}
    }

    $rv .= ESC . "c" if $o{fullreset};

    {
	my %DECSET = qw(smoothscroll 4
			reverse 5
			origin 6
			wraparound 7
			autorepeat 8
			formfeed 18
			showcursor 25
			showscrollbar 30
			tektronix 38
			marginbell 44
			reversewraparound 45
			backsendsdelete 67
			bottomscrolltty 1010
			bottomscrollkey 1011
			metasendsesc 1036
		      );
	while(my($optname, $Pm) = each %DECSET) {
	    if (defined $o{$optname}) {
		my $onoff = $o{$optname} ? 'h' : 'l';
		$rv .= CSI . '?' . $Pm . $onoff;
	    }
	}
    }

    $rv .= CSI . '!p' if $o{softreset};

    if (defined $o{scrollregion}) {
	if ($o{scrollregion} eq '' || $o{scrollregion} eq 'default') {
	    $rv .= CSI . 'r';
	} else {
	    my($top,$bottom) = split /,/, $o{scrollregion};
	    for ($top, $bottom) {
		die "Not a number: $_\n" if !/^\d*$/;
	    }
	    $rv .=  CSI . $top . ";" . $bottom . "r";
	}
    }

    $rv .= CSI . "1t" if $o{deiconify};
    $rv .= CSI . "2t" if $o{iconify};

    if (defined $o{geometry}) {
	if (my($w,$h,$wc,$hc,$x,$y) = $o{geometry} =~ m{^(?:(\d+)x(\d+)|(\d+)cx(\d+)c)?(?:\+(\d+)\+(\d+))?$}) {
	    $rv .=  CSI."3;".$x.";".$y."t" if defined $x;
	    $rv .=  CSI."4;".$h.";".$w."t" if defined $h; # does not work?
	    $rv .=  CSI."8;".$hc.";".$wc."t" if defined $hc; # does not work?
	} else {
	    die "Cannot parse geometry string, must be width x height+x+y\n";
	}
    }

    $rv .= CSI . "5t" if $o{raise};
    $rv .= CSI . "6t" if $o{lower};
    $rv .= CSI . "7t" if $o{refresh};
    $rv .= CSI . "9;0t" if $o{unmaximize}; # does not work?
    $rv .= CSI . "9;1t" if $o{maximize}; # does not work?
    if ($o{resize}) {
	die "-resize parameter must be at least 24\n"
	    if $o{resize} < 24 || $o{resize} !~ /^\d+$/;
	$rv .= CSI . $o{resize} . 't';
    }

    $rv .= OSC .  "1;$o{iconname}" . BEL if defined $o{iconname};
    $rv .= OSC .  "2;$o{title}" . BEL if defined $o{title};
    $rv .= OSC .  "3;$o{xproperty}" . BEL if defined $o{xproperty};    
    $rv .= OSC . "10;$o{fg}" . BEL if defined $o{fg};
    $rv .= OSC . "11;$o{bg}" . BEL if defined $o{bg};
    $rv .= OSC . "12;$o{textcursor}" . BEL if defined $o{textcursor};
    $rv .= OSC . "13;$o{mousefg}" . BEL if defined $o{mousefg};
    $rv .= OSC . "14;$o{mousebg}" . BEL if defined $o{mousebg};
    $rv .= OSC . "15;$o{tekfg}" . BEL if defined $o{tekfg};
    $rv .= OSC . "16;$o{tekbg}" . BEL if defined $o{tekbg};
    $rv .= OSC . "17;$o{highlightcolor}" . BEL if defined $o{highlightcolor};
    $rv .= OSC . "50;#$o{font}" . BEL if defined $o{font};
    $rv .= OSC . "50;#-" . BEL if $o{prevfont};
    $rv .= OSC . "50;#+" . BEL if $o{nextfont};

    if ($o{report}) {
	if ($o{report} eq 'cgeometry') {
	    my($h,$w) = _report_cgeometry();
	    $rv .= $w."x".$h."\n";
	} else {
	    my $sub = "_report_" . $o{report};
	    no strict 'refs';
	    my(@args) = &$sub;
	    $rv .= join(" ", @args) . "\n";
	}
    }

    $rv;
}

sub xterm_conf {
    # always call xterm_conf_string(), so option validation is done
    my $rv = xterm_conf_string(@_);
    if (terminal_is_supported()) {
	local $| = 1;
	print $rv;
    }
}

sub terminal_is_supported {
    my($term) = @_;
    $term = $ENV{TERM} if !defined $term;
    if (!$ENV{TERM}) {
	0;
    } elsif ($ENV{TERM} !~ m{^(xterm|rxvt)}) {
	0;
    } else {
	1;
    }
}

sub _report ($$) {
    my($cmd, $rx) = @_;

    require Term::ReadKey;
    Term::ReadKey::ReadMode(5);

    my @args;

    eval {
	require IO::Select;

	my $debug = $o{debugreport};

	open my $TTY, "+< /dev/tty" or die "Cannot open terminal /dev/tty: $!";
	syswrite $TTY, $cmd;

	my $sel = IO::Select->new;
	$sel->add($TTY);

	my $res = "";
	while() {
	    my(@ready) = $sel->can_read(5);
	    if (!@ready) {
		die "Cannot report, maybe allowWindowOps is set to false?";
		last;
	    }
	    sysread $TTY, my $ch, 1 or die "Cannot sysread: $!";
	    print STDERR ord($ch)." " if $debug;
	    $res .= $ch;
	    last if (@args = $res =~ $rx);
	}

	1;
    };
    my $err = $@;

    Term::ReadKey::ReadMode(0);

    if ($err) {
	die "$err\n";
    }
    @args;
}

sub _report_status      { _report CSI.'5n', qr{0n} }
sub _report_cursorpos   { _report CSI.'6n', qr{(\d+);(\d+)R} }
sub _report_windowpos   { _report CSI.'13t', qr{;(\d+);(\d+)t} }
sub _report_geometry    { _report CSI.'14t', qr{;(\d+);(\d+)t} }
sub _report_cgeometry   { _report CSI.'18t', qr{;(\d+);(\d+)t} }
sub _report_cscreengeom { _report CSI.'19t', qr{;(\d+);(\d+)t} }
sub _report_iconname    { _report CSI.'20t', qr{L(.*?)(?:\Q@{[ST]}\E|\Q@{[ST_8]}\E)} }
sub _report_title       { _report CSI.'21t', qr{l(.*?)(?:\Q@{[ST]}\E|\Q@{[ST_8]}\E)} }

sub _usage {
    die <<EOF;
usage: $0 [-n|iconname string] [-T|title string] [-cr|textcursor color]
        [-fg|-foreground color] [-bg|-background color color]
        [-ms|mousefg|-mouseforeground color] [-mousebg|-mousebackground color]
        [-tekfg|-tekforeground color] [-tekbg|-tekbackground color]
        [-hc|highlightcolor color] [-bell] [-cs ...] [-fullreset] [-softreset]
	[-[no]smoothscroll] [-[no]reverse|reversevideo], [-[no]origin]
	[-[no]wraparound] [-[no]autorepeat] [-[no]formfeed] [-[no]showcursor]
        [-[no]showscrollbar] [-[no]tektronix] [-[no]marginbell]
	[-[no]reversewraparound] [-[no]backsendsdelete]
        [-[no]bottomscrolltty] [-[no]bottomscrollkey]
	[-[no]metasendsesc|metasendsescape] [-scrollregion ...]
	[-deiconify] [-iconify] [-geometry x11geom] [-raise] [-lower]
	[-refresh|x11refresh] [-maximize] [-unmaximize]
	[-xproperty|x11property ...] [-font ...] [-nextfont] [-prevfont]
	[-report ...] [-debugreport] [-resize ...]

EOF
}

return 1 if caller;

xterm_conf(@ARGV);

__END__

=head1 NAME

XTerm::Conf - change configuration of a running xterm

=head1 SYNOPSIS

    use XTerm::Conf;
    xterm_conf(-fg => "white", -bg => "black", -title => "Hello, world", ...);

=head1 DESCRIPTION

XTerm::Conf provides functions to change some aspects of a running
L<xterm> and compatible terminal emulators (e.g. L<rxvt> or L<urxvt>).

=head2 xterm_conf(I<options ...>)

The xterm_conf function (exported by default) checks first if the
current terminal looks like an xterm, rxvt or urxvt (by looking at the
C<TERM> environment variable) and prints the escape sequences for the
following options:

=over

=item C<-n I<string>>

=item C<-iconname I<string>>

Change name of the associated X11 icon.

=item C<-T I<string>>

=item C<-title I<string>>

Change xterm's title name.

=item C<-fg I<color>>

=item C<-foreground I<color>>

Change text color. You can use either X11 named colors or the
C<#I<rrggbb>> notation.

=item C<-bg I<color>>

=item C<-background I<color>>

Change background color.

=item C<-cr I<color>>

=item C<-textcursor I<color>>

Change cursor color.

=item C<-ms I<color>>

=item C<-mousefg I<color>>

=item C<-mouseforeground I<color>>

Change the foreground color of the mouse pointer.

=item C<-mousebg I<color>>

=item C<-mousebackground I<color>>

Change the background/border color of the mouse pointer.

=item C<-tekfg I<color>>

=item C<-tekforeground I<color>>

Change foreground color of Tek window.

=item C<-tekbg I<color>>

=item C<-tekbackground I<color>>

Change background color of Tek window.

=item C<-highlightcolor I<color>>

Change selection background color.

=item C<-bell>

Ring the bell (may be visual or audible, depending on configuration).

=item C<-cs utf-8|iso-8859-1>

Switch charset. Valid values are C<utf-8> and C<iso-8859-1>.

=item C<-fullreset>

Perform a full reset.

=item C<-softreset>

Perform a soft reset.

=item C<-[no]smoothscroll>

Turn smooth scrolling on or off (which is probably the opposite of
jump scroll, see L<xterm(1)>).

=item C<-[no]reverse>

=item C<-[no]reversevideo>

Turn reverse video on or off.

=item C<-[no]origin>

???

=item C<-[no]wraparound>

???

=item C<-[no]autorepeat>

Turn auto repeat on or off.

=item C<-[no]formfeed>

???

=item C<-[no]showcursor>

Show or hide the cursor.

=item C<-[no]showscrollbar>

rxvt only?

=item C<-[no]tektronix>

Show the Tek window and switch to Tek mode (XXX C<-notektronix> does not
seem to work).

=item C<-[no]marginbell>

???

=item C<-[no]reversewraparound>

???

=item C<-[no]backsendsdelete>

???

=item C<-[no]bottomscrolltty>

rxvt only?

=item C<-[no]bottomscrollkey>

rxvt only?

=item C<-[no]metasendsesc>

=item C<-[no]metasendsescape>

???

=item C<-scrollregion I<...>>

???

=item C<-deiconify>

Deiconify an iconified xterm window.

=item C<-iconify>

Iconify the xterm window.

=item C<-geometry I<geometry>>

Change the geometry of the xterm window. The geometry is in the usual
X11 notation I<width>xI<height>+I<left>+I<top>. The numbers are in
pixels. The width and height may be suffixed with a C<c>, which means
that the numbers are interpreted as characters.

=item C<-raise>

Raise the xterm window.

=item C<-lower>

Lower the xterm window

=item C<-refresh>

=item C<-x11refresh>

Force a X11 refresh.

=item C<-maximize>

Maximize the xterm window.

=item C<-unmaximize>

Restore to the state before maximization.

=item C<-xproperty I<...>>

=item C<-x11property I<...>>

???

=item C<-font I<number>>

Change font. Number may be from 0 (default font) to 6 (usually the
largest font, but this could be changed using Xdefaults).

=item C<-nextfont>

Use the next font in list.

=item C<-prevfont>

Use the previous font in list.

=item C<-report I<what>>

Report to C<STDOUT>:

=over

=item C<status>

Return 1.

=item C<cursorpos>

The cursor position (I<line column>).

=item C<windowpos>

The XTerm window position (I<x y>).

=item C<geometry>

The geometry of the window in pixels (I<width> I<height>).

=item C<cgeometry>

The geometry of the window in characters (I<width>C<x>I<height>).

=item C<cscreengeom>

???

=item C<iconname>

The icon name. This may only be available if the allowWindowOps
resource is set to true (e.g. using

    xterm -xrm "*allowWindowOps:true"

). On some operating systems and some terminal emulators (most notable
C<rxvt> on Debian/Ubuntu systems) this operation may be forbidden
completely.

=item C<title>

The title name. See L</iconname> for possible restrictions on
availability.

=back

=item C<-debugreport>

If set together with a C<-report ...> option, then print the returned
escape sequence as numbers to C<STDOUT> (as an debugging aid).

=item C<-resize I<integer>>

???

=back

=head2 xterm_conf_string(I<options ...>)

xterm_conf_string just returns a string with the escape sequences for
the given options (same as in xterm_conf). No terminal check will be
performed here.

xterm_conf_string may be exported.

=head2 terminal_is_supported(I<term>)

Return a true value if the given I<term>, or if missing, the current
terminal as given by C<$ENV{TERM}>, is supported.

This function may be exported.

=head1 AUTHOR

Slaven ReziE<0x107>

=head1 SEE ALSO

L<xterm-conf>, L<xterm(1)>, L<rxvt(1)>, L<Term::Title>.

=cut
