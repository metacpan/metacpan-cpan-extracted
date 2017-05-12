#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


# killall -9 olvwm olwm tvtwm miwm vtwm aewm
# xwit -iconify -id $WINDOWID; sleep 2; xwit -raise -id $WINDOWID


use strict;
use FindBin;
use File::Spec;
my $script = File::Spec->catfile($FindBin::Bin,$FindBin::Script);
use X11::Protocol;
use X11::AtomConstants;
use X11::Protocol::WM;

if (@ARGV) {
  open STDOUT, '>>', '/tmp/wm-state-exercise.out' or die;
  open STDERR, '>>&', \*STDOUT;
  $| = 1;
  print "\n\n\n-------------------------------------------------------------\n";

  my $wm = $ARGV[0];
  my $pid = fork();
  if ($pid) {
    # parent
    sleep 5;
  } else {
    exec $wm or die $!;
  }

  my $display = $ENV{"DISPLAY"};
  my $window = $ENV{"WINDOWID"};
  my $X = X11::Protocol->new($display);
  my $root = $X->root;
  print "\n$wm $display window=$window\n";
  # system("xprop -root >>/tmp/wm-state-exercise.out");

  if (0) {
    require IPC::Run;
    IPC::Run::run (['perl', '-w', '-I','lib', 't/WM.t']);
  }

  if (1) {
    # WM_STATE

    my $print_wm_state = sub {
      my ($reason) = @_;
      if (my ($state, $icon_window) = X11::Protocol::WM::get_wm_state($X,$window)) {
        $state //= '[undef]';
        print "$reason: $state  (icon window: $icon_window)\n";
        return $state;
      } else {
        print "$reason: WM_STATE not set\n";
        return '';
      }
    };

    $print_wm_state->('initial state');

    print "iconify()\n";
    X11::Protocol::WM::iconify ($X, $window, $root);
    $X->flush;
    sleep 2;
    { my $state = $print_wm_state->('after iconify');
      if ($state ne 'IconicState') {
        print "  oops, expected IconicState\n";
      }
    }

    print "MapWindow()\n";
    $X->MapWindow($window);
    $X->flush;
    sleep 2;
    { my $state = $print_wm_state->('after un-iconify');
      if ($state ne 'NormalState') {
        print "  oops, expected NormalState\n";
      }
    }
  }

  if (1) {
    # _NET_WM_STATE

    my @supported_atoms;
    my %supported_atoms;
    {
      my ($value, $type, $format, $bytes_after)
        = $X->GetProperty ($root,
                           $X->atom('_NET_SUPPORTED'),   # property
                           X11::AtomConstants::ATOM(),  # type
                           0,    # offset
                           999,  # length limit
                           0);   # delete
      if ($format == 32) {
        @supported_atoms = unpack('L*', $value);
        foreach my $atom (@supported_atoms) {
          $supported_atoms{$atom} = 1;
        }
      } else {
        print "no _NET_SUPPORTED\n";
      }
    }
    print "supported count ",scalar(@supported_atoms),"\n";
    print "supported: ",join(', ',map{$X->atom_name($_)} @supported_atoms),"\n";

    # _NET_WM_STATE_HIDDEN
    foreach my $state (qw(
                           _NET_WM_STATE_BELOW
                           _NET_WM_STATE_ABOVE
                           _NET_WM_STATE_MODAL
                           _NET_WM_STATE_STICKY
                           _NET_WM_STATE_MAXIMIZED_VERT
                           _NET_WM_STATE_MAXIMIZED_HORZ
                           _NET_WM_STATE_SHADED
                           _NET_WM_STATE_SKIP_TASKBAR
                           _NET_WM_STATE_SKIP_PAGER
                           _NET_WM_STATE_FULLSCREEN
                           _NET_WM_STATE_DEMANDS_ATTENTION
                        )) {
      print "$state\n";
      my $state_atom = $X->atom($state);
      if (! $supported_atoms{$state_atom}) {
        print "  not supported\n";
        next;
      }

      X11::Protocol::WM::change_net_wm_state ($X, $window, 'add', $state_atom);
      $X->flush;
      sleep 1;
      {
        my @states = X11::Protocol::WM::get_net_wm_state_atoms($X,$window);
        my $found = grep {$_==$state_atom} @states;
        if ($found) {
          print "  add ok\n";
        } else {
          print "  bad, add not set\n";
          print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
        }
      }

      X11::Protocol::WM::change_net_wm_state ($X, $window, 'remove', $state_atom);
      $X->flush;
      sleep 1;
      {
        my @states = X11::Protocol::WM::get_net_wm_state_atoms($X,$window);
        my $found = grep {$_==$state_atom} @states;
        if ($found) {
          print "  bad, remove still set\n";
          print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
        } else {
          print "  remove ok\n";
        }
      }

      X11::Protocol::WM::change_net_wm_state ($X, $window, 'toggle', $state_atom);
      $X->flush;
      sleep 1;
      {
        my @states = X11::Protocol::WM::get_net_wm_state_atoms($X,$window);
        my $found = grep {$_==$state_atom} @states;
        if ($found) {
          print "  toggle-on ok\n";
        } else {
          print "  bad, toggle-on not set\n";
          print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
        }
      }

      X11::Protocol::WM::change_net_wm_state ($X, $window, 'toggle', $state_atom);
      $X->flush;
      sleep 1;
      {
        my @states = X11::Protocol::WM::get_net_wm_state_atoms($X,$window);
        my $found = grep {$_==$state_atom} @states;
        if ($found) {
          print "  bad, toggle-off still set\n";
          print "  have: ",join(' ',map{$X->atom_name($_)}@states),"\n";
        } else {
          print "  toggle-off ok\n";
        }
      }
    }
  }
  # kill $pid;
  print "exit\n";
  exit 0;
}


unlink '/tmp/wm-state-exercise.out';

foreach my $wm (
                # /usr/share/doc/python-plwm/examples/README.examplewm
                '/usr/share/doc/python-plwm/examples/petliwm.py',
                # 'startfluxbox',
                # 'i3',
                # 'subtle',     # no iconic
                # 'aewm',
                # 'matchbox-window-manager',
                # 'tinywm',
                # 'notion',     # no iconic
                # 'ratpoison',
                # 'tritium',    # no NET_WM
                # 'fvwm2',
                # 'evilwm',     # no iconic
                # 'jwm',
                # 'metacity',
                # 'wmii',
                #     'icewm',
                #     'mwm',
                #     'olwm',
                #     'olvwm',
                #     'pekwm',
                # 
                #     'spectrwm',
                #     'windowlab',
                # 
                #     'awesome',
                #     'openbox',
                #     'tvtwm',
                #     '9wm',
                #     'w9wm',
                #     'xfwm4',
                # 
                #     'ctwm',
                #     'flwm',
                #     'herbstluftwm',
                #     'larswm',
                #     'miwm',
                #     'oroborus',
                # 'sapphire',
                # 'dwm',
                # 'wm2',
                # 'xmonad',
                # 'twm',
                # 'vtwm',
                # 'amiwm',  # no NET_WM
                # '/so/swm/sWM-1.3.6/bin/sWM',
               ) {
  # my $command = "xvfb-run -a xterm -e 'echo $wm >>/tmp/xx'";
  my $command = "xvfb-run -a xterm -e 'perl $script $wm'";
  print "$command\n";
  system ($command);
}



# MapWindow to NormalState
# jwm -
# matchbox-window-manager - dodginess
# amiwm - MapRequest looks at WMHints but doesn't notice IconicState
# flwm - MapRequest handler only does initial map
# tritium - /usr/share/pyshared/plwm/wmanager.py deiconify()


# no iconify
# dwm, evilwm, i3, sapphire, subtle, wmii, xmonad

# bad shutdowns:
# aewm
# olvwm
# olwm
# miwm
# vtwm  100% cpu on SIGTERM
# tvtwm [my packaged]
