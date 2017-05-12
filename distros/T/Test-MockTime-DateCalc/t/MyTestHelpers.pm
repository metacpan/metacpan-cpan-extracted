# MyTestHelpers.pm -- my shared test script helpers

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# MyTestHelpers.pm is shared by several distributions.
#
# MyTestHelpers.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyTestHelpers.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyTestHelpers;
use strict;
use Exporter;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

@ISA = ('Exporter');
@EXPORT_OK = qw(findrefs
                main_iterations
                warn_suppress_gtk_icon
                glib_gtk_versions
                any_signal_connections
                nowarnings);
%EXPORT_TAGS = (all => \@EXPORT_OK);

sub DEBUG { 0 }


#-----------------------------------------------------------------------------

{
  my $warning_count;
  my $stacktraces;
  my $stacktraces_count = 0;
  sub nowarnings_handler {
    $warning_count++;
    if ($stacktraces_count < 3 && eval { require Devel::StackTrace }) {
      $stacktraces_count++;
      $stacktraces .= "\n" . Devel::StackTrace->new->as_string() . "\n";
    }
    warn @_;
  }
  sub nowarnings {
    $SIG{'__WARN__'} = \&nowarnings_handler;
  }
  END {
    if ($warning_count) {
      diag("Saw $warning_count warning(s):");
      if (defined $stacktraces) {
        diag($stacktraces);
      } else {
        diag('(Devel::StackTrace not available for backtrace)');
      }
      diag("Exit code 1 for warnings");
      $? = 1;
    }
  }
}

sub diag {
  if (Test::More->can('diag')) {
    Test::More::diag (@_);
  } else {
    my $msg = join('', map {defined($_)?$_:'[undef]'} @_)."\n";
    $msg =~ s/^/# /mg;
    print STDERR $msg;
  }
}

sub dump {
  my ($thing) = @_;
  if (eval { require Data::Dumper; 1 }) {
    diag (Data::Dumper::Dumper ($thing));
  } else {
    diag ("Data::Dumper not available");
  }    
}

#-----------------------------------------------------------------------------
# Test::Weaken and other weaking

sub findrefs {
  my ($obj) = @_;
  require Test::More;
  defined $obj or return;
  require Scalar::Util;
  if (ref $obj && Scalar::Util::reftype($obj) eq 'HASH') {
    Test::More::diag ("Keys: ",
                      join(' ',
                           map {"$_=$obj->{$_}"} keys %$obj));
  }
  if (eval { require Devel::FindRef }) {
    Test::More::diag (Devel::FindRef::track($obj, 8));
  } else {
    Test::More::diag ("Devel::FindRef not available -- $@\n");
  }
}

sub test_weaken_show_leaks {
  my ($leaks) = @_;
  $leaks || return;
  eval { # explain new in 0.82
    Test::More::diag ("Test-Weaken ",Test::More::explain($leaks));
  };

  my $unfreed = $leaks->unfreed_proberefs;
  foreach my $proberef (@$unfreed) {
    Test::More::diag ("  unfreed $proberef");
  }
  foreach my $proberef (@$unfreed) {
    Test::More::diag ("search $proberef");
    MyTestHelpers::findrefs($proberef);
  }
}

#-----------------------------------------------------------------------------
# Gtk/Glib helpers

# Gtk 2.16 can go into a hard loop on events_pending() / main_iteration_do()
# if dbus is not running, or something like that.  In any case limiting the
# iterations is good for test safety.
#
sub main_iterations {
  require Test::More;
  my $count = 0;
  if (DEBUG) { Test::More::diag ("main_iterations() ..."); }
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);

    if ($count >= 500) {
      Test::More::diag ("main_iterations(): oops, bailed out after $count events/iterations");
      return;
    }
  }
  Test::More::diag ("main_iterations(): ran $count events/iterations");
}

# warn_suppress_gtk_icon() is a $SIG{__WARN__} handler which suppresses spam
# from Gtk trying to make you buy the hi-colour icon theme.  Eg,
#
#     {
#       local $SIG{'__WARN__'} = \&MyTestHelpers::warn_suppress_gtk_icon;
#       $something = SomeThing->new;
#     }
#
sub warn_suppress_gtk_icon {
  my ($message) = @_;
  unless ($message =~ /Gtk-WARNING.*icon/) {
    warn @_;
  }
}

sub glib_gtk_versions {
  require Test::More;
  my $gtk2_loaded = Gtk2->can('init');
  my $glib_loaded = Glib->can('get_home_dir');

  if ($gtk2_loaded) {
    Test::More::diag ("Perl-Gtk2    version ",Gtk2->VERSION);
  }
  if ($glib_loaded) { # when loaded
    Test::More::diag ("Perl-Glib    version ",Glib->VERSION);
    Test::More::diag ("Compiled against Glib version ",
                      Glib::MAJOR_VERSION(), ".",
                      Glib::MINOR_VERSION(), ".",
                      Glib::MICRO_VERSION(), ".");
    Test::More::diag ("Running on       Glib version ",
                      Glib::major_version(), ".",
                      Glib::minor_version(), ".",
                      Glib::micro_version(), ".");
  }
  if ($gtk2_loaded) {
    Test::More::diag ("Compiled against Gtk version ",
                      Gtk2::MAJOR_VERSION(), ".",
                      Gtk2::MINOR_VERSION(), ".",
                      Gtk2::MICRO_VERSION(), ".");
    Test::More::diag ("Running on       Gtk version ",
                      Gtk2::major_version(), ".",
                      Gtk2::minor_version(), ".",
                      Gtk2::micro_version(), ".");
  }
}

# Return true if there's any signal handlers connected to $obj.
#
# Signal IDs are from 1 up, don't pass 0 to signal_handler_is_connected()
# since in Glib 2.4.1 it spits out a g_log() error.
#
sub any_signal_connections {
  my ($obj) = @_;
  my @connected = grep {$obj->signal_handler_is_connected ($_)} (1 .. 500);
  if (@connected) {
    my $connected = join(',',@connected);
    Test::More::diag ("$obj signal handlers connected: $connected");
    return $connected;
  }
  return undef;
}

# wait for $signame to be emitted on $widget, with a timeout
sub wait_for_event {
  my ($widget, $signame) = @_;
  require Test::More;
  if (DEBUG) { Test::More::diag ("wait_for_event() $signame on $widget"); }
  my $done = 0;
  my $got_event = 0;
  my $sig_id = $widget->signal_connect
    ($signame => sub {
       if (DEBUG) { Test::More::diag ("wait_for_event()   $signame received"); }
       $done = 1;
       return 0; # Gtk2::EVENT_PROPAGATE (new in Gtk2 1.220)
     });
  my $timer_id = Glib::Timeout->add
    (30_000, # 30 seconds
     sub {
       $done = 1;
       Test::More::diag ("wait_for_event() oops, timeout waiting for $signame on $widget");
       return 1; # Glib::SOURCE_CONTINUE (new in Glib 1.220)
     });
  if ($widget->can('get_display')) {
    # GdkDisplay new in Gtk 2.2
    $widget->get_display->sync;
  } else {
    # in Gtk 2.0 gdk_flush() is a sync actually
    Gtk2::Gdk->flush;
  }

  my $count = 0;
  while (! $done) {
    if (DEBUG >= 2) { Test::More::diag ("wait_for_event()   iteration $count"); }
    Gtk2->main_iteration;
    $count++;
  }
  Test::More::diag ("wait_for_event(): '$signame' ran $count events/iterations\n");

  $widget->signal_handler_disconnect ($sig_id);
  Glib::Source->remove ($timer_id);
}

1;
__END__
