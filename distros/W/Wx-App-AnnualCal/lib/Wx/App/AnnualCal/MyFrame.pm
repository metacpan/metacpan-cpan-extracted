package Wx::App::AnnualCal::MyFrame;

use strict;
use warnings;
use feature qw(switch);

use Wx 0.990 qw(wxICON_ERROR wxTheApp wxID_OK
                :font :sizer :dialog :textctrl :button);
use Wx::Event qw(EVT_BUTTON);
use base qw(Wx::Frame);

use Date::Calc 6.3 qw(Today Month_to_Text);
use Readonly 1.03;

use lib qw(../../../../lib);
use Wx::App::AnnualCal::MonthSizer;

          ##################################################

sub new
  {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  my $panel = Wx::Panel->new($self);
  $panel->SetBackgroundColour(Wx::Colour->new('black'));

  my ($yr, $mon, $day) = Today(0);
  my $current = {'day' => $day, 'month' => Month_to_Text($mon), 'year' => $yr};

  my $day_names = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  my $fonts = {'norm' => Wx::Font->new(9, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL),
               'ital' => Wx::Font->new(9, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_ITALIC, wxFONTWEIGHT_BOLD),
               'emph' => Wx::Font->new(10, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_ITALIC, wxFONTWEIGHT_BOLD),
               'bold' => Wx::Font->new(12, wxFONTFAMILY_MODERN,
                           wxFONTSTYLE_NORMAL, wxFONTWEIGHT_BOLD),
              };

  my $colors = {'gold' => Wx::Colour->new(255,215,0),
                'gray' => Wx::Colour->new(100,100,100)};

  my $year = $ARGV[0] || $current->{year};
  if ($year =~ /\A[0-9]+\Z/x and 1 <= $year and $year <= 32767)
    {
    chomp($year);
    }
  else
    {
    Wx::MessageBox('Enter a year between 1 and 32767.', 'ERROR',
                   wxICON_ERROR|wxOK);
    exit(0);
    }

  $self->{param} = {'current' => $current, 'day_names' => $day_names,
                    'fonts' => $fonts, 'panel' => $panel, 'year' => $year,
                    'colors' => $colors};

  Readonly my %IDS => (PRIOR_BUTTON => 1001,
                       NEXT_BUTTON  => 1002,
                       ANY_BUTTON   => 1003,
                       EXIT_BUTTON  => 1004,
                      );

  my $priorbtn = Wx::Button->new($panel,            # parent window
                                 $IDS{PRIOR_BUTTON},   # id
                                 ' < ',             # label
                                 [-1,-1],           # default location
                                 [-1,-1],           # default size
                                 wxBU_EXACTFIT,     # minimum size
                                );
  $self->{priorbtn} = $priorbtn;
  $priorbtn->SetFont($fonts->{bold});
  $priorbtn->SetForegroundColour(Wx::Colour->new('green'));
  $priorbtn->SetBackgroundColour($colors->{'gray'});
  ($year == 1) ? $priorbtn->Enable(0) : $priorbtn->Enable(1);
  EVT_BUTTON($self, $IDS{PRIOR_BUTTON}, \&ClickPRIOR);

  my $yeartxt = Wx::TextCtrl->new($panel,
                                  -1,
                                  $year,
                                  [-1,-1],
                                  [-1,-1],
                                  wxTE_CENTRE|wxTE_READONLY,
                                 );
  $yeartxt->SetFont($fonts->{bold});
  $yeartxt->SetForegroundColour(Wx::Colour->new('black'));
  $yeartxt->SetBackgroundColour($colors->{'gold'});
  $self->{yeartxt} = $yeartxt;

  my $nextbtn = Wx::Button->new($panel,             # parent window
                                $IDS{NEXT_BUTTON},     # id
                                ' > ',              # label
                                 [-1,-1],           # default location
                                 [-1,-1],           # default size
                                 wxBU_EXACTFIT,     # minimum size
                               );
  $self->{nextbtn} = $nextbtn;
  $nextbtn->SetFont($fonts->{bold});
  $nextbtn->SetForegroundColour(Wx::Colour->new('green'));
  $nextbtn->SetBackgroundColour($colors->{'gray'});
  ($year == 32767) ? $nextbtn->Enable(0) : $nextbtn->Enable(1);
  EVT_BUTTON($self, $IDS{NEXT_BUTTON}, \&ClickNEXT);

  my $anybtn = Wx::Button->new($panel,              # parent window
                               $IDS{ANY_BUTTON},       # id
                               'ANY YEAR',          # label
                              );
  $anybtn->SetFont($fonts->{bold});
  $anybtn->SetForegroundColour(Wx::Colour->new('green'));
  $anybtn->SetBackgroundColour($colors->{'gray'});
  EVT_BUTTON($self, $IDS{ANY_BUTTON}, \&ClickANY);

  my $exitbtn = Wx::Button->new($panel,           # parent window
                                $IDS{EXIT_BUTTON},   # id
                                'EXIT'            # label
                               );
  $exitbtn->SetFont($fonts->{bold});
  $exitbtn->SetForegroundColour(Wx::Colour->new('white'));
  $exitbtn->SetBackgroundColour(Wx::Colour->new('red'));
  EVT_BUTTON($self, $IDS{EXIT_BUTTON}, sub {wxTheApp->ExitMainLoop()});

  my $lowersizer = Wx::BoxSizer->new(wxHORIZONTAL);
  $lowersizer->AddSpacer(20);
  $lowersizer->Add($anybtn,             # button control
                   1,                   # unit length
                   wxBOTTOM|            # bottom border
                   wxALIGN_CENTER,      # central alignment
                   20,                  # border width
                  );
  $lowersizer->AddSpacer(30);
  $lowersizer->Add($priorbtn,           # button control
                   0,                   # exact fit
                   wxBOTTOM|            # bottom border
                   wxALIGN_CENTER,      # central alignment
                   20,                  # border width
                  );
  $lowersizer->Add($yeartxt,            # text control
                   1.5,                 # proportional length
                   wxBOTTOM|            # bottom border
                   wxALIGN_CENTER,      # central alignment
                   20,                  # border width
                  );
  $lowersizer->Add($nextbtn,            # button control
                   0,                   # exact fit
                   wxBOTTOM|            # bottom border
                   wxALIGN_CENTER,      # central alignment
                   20,                  # border width
                  );
  $lowersizer->AddSpacer(30);
  $lowersizer->Add($exitbtn,            # button control
                   1,                   # unit length
                   wxBOTTOM|            # bottom border
                   wxALIGN_CENTER,      # central alignment
                   20,                  # border width
                  );
  $lowersizer->AddSpacer(20);

  $self->{lowersizer} = $lowersizer;

  return($self);
  }

          ##################################################

sub build
  {
  my $self = shift;
  my $panel = $self->{param}->{panel};
  my $year = $self->{param}->{year};

  my $ms = Wx::App::AnnualCal::MonthSizer->new($self->{param});

  my $gridsizer = Wx::GridSizer->new(3,4,0,0);
  map { $gridsizer->Add($ms->getmonthsizer($_)) } (0..11);
  $self->{gridsizer} = $gridsizer;

  my $margin = Wx::Panel->new($self, -1, [-1,-1], [13,-1]);
  $margin->SetBackgroundColour(Wx::Colour->new('black'));
  $self->{margin} = $margin;

  my $uppersizer = Wx::BoxSizer->new(wxHORIZONTAL);
  $uppersizer->Add($margin);
  $uppersizer->Add($gridsizer);
  $self->{uppersizer} = $uppersizer;

  my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
  $panelsizer->Add($uppersizer);
  $panelsizer->Add($self->{lowersizer},1,wxGROW);

  $panel->SetSizer($panelsizer);

  my $framesizer = Wx::BoxSizer->new(wxVERTICAL);
  $framesizer->Add($panel);
  $self->SetSizerAndFit($framesizer);

  return(1);
  }

          ##################################################

sub update
  {
  my $self = shift;

  my $ms = Wx::App::AnnualCal::MonthSizer->new($self->{param});

  my $gridsizer = Wx::GridSizer->new(3,4,0,0);
  map { $gridsizer->Add($ms->getmonthsizer($_)) } (0..11);

  my $uppersizer = $self->{uppersizer};
  $uppersizer->Detach(1);
  $uppersizer->Add($gridsizer);
  $uppersizer->Layout();

  my $yeartxt = $self->{yeartxt};
  $yeartxt->Clear();
  $yeartxt->ChangeValue($self->{param}->{year});

  return(1);
  }

          ##################################################

sub ClickPRIOR
  {
  my $self = shift;
  my $year = $self->{param}->{year} - 1;
  $self->{param}->{year} = $year;

  $self->{nextbtn}->Enable(1);
  ($year == 1) ? $self->{priorbtn}->Enable(0) : $self->{priorbtn}->Enable(1);

  $self->update();
  return;
  }

          ##################################################

sub ClickNEXT
  {
  my $self = shift;
  my $year = $self->{param}->{year} + 1;
  $self->{param}->{year} = $year;

  $self->{priorbtn}->Enable(1);
  ($year == 32767) ? $self->{nextbtn}->Enable(0) : $self->{nextbtn}->Enable(1);

  $self->update();
  return;
  }

          ##################################################

sub ClickANY
  {
  my $self = shift;
  my $dlg = Wx::TextEntryDialog->new($self, 'Enter a year between 1 and 32767.',
                                    'USER INPUT', '', wxOK|wxCANCEL);
  my $ans = $dlg->ShowModal();
  if ($ans == wxID_OK)
    {
    my $year = $dlg->GetValue();
    if ($year =~ /\A[0-9]+\Z/x and 1 <= $year and $year <= 32767)
      {
      $self->{param}->{year} = $year;
      }
    else
      {
      $dlg->Destroy();
      Wx::MessageBox("$year is invalid.", 'ERROR', wxICON_ERROR|wxOK);
      }
    }
  else
    {
    $dlg->Destroy();
    }

  my $year = $self->{param}->{year};
  given ($year)
    {
    when (1)
      {
      $self->{priorbtn}->Enable(0);
      $self->{nextbtn}->Enable(1);
      }
    when (32767)
      {
      $self->{priorbtn}->Enable(1);
      $self->{nextbtn}->Enable(0);
      }
    default
      {
      $self->{nextbtn}->Enable(1);
      $self->{priorbtn}->Enable(1);
      }
    }
  $self->update();
  return;
  }

# * * *
#
#  Input for Dist::Zilla::Pod::Weaver plugin to create POD documentation.
#
# * * *

#ABSTRACT: a module in the AnnualCal distribution

1;

__END__
=pod

=head1 NAME

Wx::App::AnnualCal::MyFrame - a module in the AnnualCal distribution

=head1 VERSION

version 0.92

=head1 SYNOPSIS

Package which defines, lays out, and maintains the widgets in the GUI.

=head1 METHODS

=head2 new

Constructor defining all the GUI parameters and basic widgets,
and builds the 'lower sizer' (see L<Wx::App::AnnualCal/DESIGN>).

=head2 build

Method which gets and/or builds the higher-order widgets which are ultimately
inserted into the panel and frame for display.

=head2 update

Method which responds to a user request for a new year
by getting a new 'upper sizer' (see L<Wx::App::AnnualCal/DESIGN>),
and replacing the old one.
Also, the display of the numeric new year is updated in the 'lower sizer'.

=head2 ClickPRIOR

PRIOR Button callback which resets the 'year' parameter to the prior year
and calls the 'update' method.

=head2 ClickNEXT

NEXT Button callback which resets the 'year' parameter to the next year
and calls the 'update' method.

=head2 ClickANY

ANY Button callback which fetches the input year from the TextEntryDialog
popup and calls the 'update' method.

=head1 AUTHOR

Elliot Winston <exw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Elliot Winston.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

