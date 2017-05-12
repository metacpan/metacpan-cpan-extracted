#!/usr/bin/perl

package MainApp;

use warnings;
use strict;

use dtRdr::0;
use Time::HiRes ();
########################################################################
# END PRELUDE
########################################################################
my $splash;
use Wx ();
BEGIN {
  # our own little splashfast

  dtRdr->program_dir(__FILE__); # seed for data_dir

  unless($ENV{DOTREADER_NOSPLASH}) {
    Wx::Image::AddHandler(Wx::PNGHandler->new);
    $splash = Wx::SplashScreen->new(
      Wx::Bitmap->new(
        dtRdr->data_dir . 'gui_default/images/splash.png',
        &Wx::wxBITMAP_TYPE_PNG
      ),
      Wx::wxSPLASH_CENTRE_ON_SCREEN(), 0, undef , -1
    );
    #Wx::Yield();
    my $now = Time::HiRes::time();
    #warn "splash is out in ", $now - dtRdr->start_time, " seconds\n";
  }
}

#### PAR_LOADS_DEPS_HERE # don't mess with this, it is a token

use dtRdr;
dtRdr->init_app_dir(__FILE__); # requires us to be next to data/

use base 'dtRdr::GUI::Wx';

use dtRdr::GUI::Wx::Frame;
use Wx ();
use Wx::DND (); # clipboard+drag-n-drop support


# testing accessor:
my $frame_main;
sub _main_frame {$frame_main};

{
  my $on_first_idle;
  sub _on_first_idle {$on_first_idle};
  sub _set_on_first_idle {$on_first_idle = $_[1]};
}
sub OnInit {
  my $self = shift;

  ######################################################################
  dtRdr->init; # ***** MUST CALL ** dtRdr->init ** EARLY *****
  ######################################################################

  Wx::InitAllImageHandlers();
  # XXX wish I could: Wx::Image::RemoveHandler('wxPCXHandler');

  $frame_main = dtRdr::GUI::Wx::Frame->new();
  $splash and $frame_main->set_splash_screen($splash);
  $self->SetTopWindow($frame_main);

  $self->init($frame_main);
  $frame_main->init;

  # setting the the "on-load-done" to happen at idle gets all of the
  # focus and fun to work correctly
  my $did_idle = 0;
  if(my $on_first_idle = $self->_on_first_idle) {
    $self->Connect(-1, -1, &Wx::wxEVT_IDLE, sub {
      #$_[1]->Skip; # makes macs mad?
      (++$did_idle > 1) and return(); # eek
      dtRdr::Logger::RL('#idle')->info("run startup idle");
      $on_first_idle->();
      $self->Disconnect(-1, -1, &Wx::wxEVT_IDLE);
      if($ENV{DOTREADER_TEST}) {
        my $exit = 1;
        eval($ENV{DOTREADER_TEST});
        $@ and die;
        if($exit) {
          $frame_main->Close; $self->ExitMainLoop;
        }
        else {
          warn "skipped exit";
        }
      }
    });
  }

  $frame_main->Show(1);
  return 1;
} # end subroutine OnInit definition
########################################################################


=head2 OnExit

  $app->OnExit;

=cut

sub OnExit {
  my $self = shift;
  #wxTheClipboard->Open;
  ## this seems to achieve nothing:
  #wxTheClipboard->Clear;
  ##wxTheClipboard->Flush;
  #wxTheClipboard->Close;
} # end subroutine OnExit definition
########################################################################

# end of class MainApp

package main;

use dtRdr::Logger;
unless($ENV{JUST_DIE}) {
  $SIG{__DIE__} = sub {
    die @_ if $^S; # get out if we're in an eval
    my @error = @_;

    RL('#caught')->error(@error);
    my $dialog = Wx::MessageDialog->new(
      MainApp->_main_frame,
      "Exception caught:\n\n  @error\n\n      Would you like to continue?",
      'Oops!',
      &Wx::wxICON_ERROR|&Wx::wxSTAY_ON_TOP|&Wx::wxYES_NO,
    ) or die("Could not create Wx::MessageDialog");
    if(&Wx::wxID_YES == $dialog->ShowModal) {
      goto &recover; # only way to break out of a die handler
    }
  };
}

=head2 recover

Where we go when we die.

  recover();

=cut

{ # closure for $app
my $app;
sub recover {
  unless($app) {
    local($SIG{__DIE__});
    die "cannot recover from this context";
  }
  $app->MainLoop();
} # end subroutine recover definition
########################################################################

# macs are too special to pass a meaningful argv, so the MacMaker main.c
# is going to call this directly
sub main {
  my @args = @_;

  if(@args) { # XXX no, not pretty TODO actual GetOpt
    my $do;
    if($args[0] =~ m/-url/) {
      $do = sub {shift->bv_manager->load_url($args[1])};
    }
    else {
      $do = sub {shift->backend_file_open($args[0])};
    }
    MainApp->_set_on_first_idle(sub {$do->(MainApp->_main_frame)});
  }
  else {
    # unfortunately, we have to run this as a deferred sub because we
    # won't have an environment until later
    MainApp->_set_on_first_idle(sub {
      dtRdr->first_time and MainApp->_main_frame->_open_first_book;
    });
  }
  $app = MainApp->new();

  $app->MainLoop;
}
} # end $app closure

# tell perlwrapper we want to handle SIG{__DIE__}
eval {PerlWrapper->NoEval(1)};

main(@ARGV)
  if($0 eq (
    (($^O eq 'MSWin32') ? $ENV{PAR_PROGNAME} : $ENV{PAR_ARGV_0}) ||
    __FILE__)
);
#print STDERR "trace ", __LINE__, "\n";

# vim:ts=2:sw=2:et:sta
my $package = 'MainApp';
