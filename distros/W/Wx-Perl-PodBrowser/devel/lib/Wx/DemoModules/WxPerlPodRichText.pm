#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.


package Wx::DemoModules::WxPerlPodRichText;
use 5.008;
use strict;
use Wx;
use Wx::Perl::PodRichText;

use base 'Wx::DemoModules::lib::BaseModule';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant title         => 'WxPerlPodRichText';
use constant add_to_tags   => 'controls';
use constant expandinsizer => 1;

sub commands {
  my( $self ) = @_;

  return ({ with_value  => 1,
            label       => 'Goto Module',
            action => sub {
              my ($module) = @_;
              $self->{'podtext'}->goto_pod (module => $module);
            },
          },
          # { with_value  => 1,
          #   label       => 'Goto Line',
          #   action => sub {
          #     my ($linenum) = @_;
          #     $self->{'podtext'}->goto_pod(line => $linenum);
          #   },
          # },
         );
}

sub create_control {
  my ($self) = @_;

  my $panel = $self->{'panel'} = Wx::Panel->new ($self, Wx::wxID_ANY());

  my $heading_label = Wx::StaticText->new ($panel, Wx::wxID_ANY(),
                                           'Headings');
  my $line_height = $heading_label->GetSize->GetHeight;

  my $heading_listbox
    = $self->{'heading_listbox'}
      = Wx::ListBox->new ($panel,
                          Wx::wxID_ANY(),
                          Wx::wxDefaultPosition(),
                          Wx::wxDefaultSize(),
                          [], # initial list
                          Wx::wxLB_SINGLE());
  Wx::Event::EVT_LISTBOX($self, $heading_listbox, '_do_listbox');

  my $podtext
    = $self->{'podtext'}
      = Wx::Perl::PodRichText->new($panel, Wx::wxID_ANY());
  # Note: EVT_PERL_PODRICHTEXT_CHANGED() not yet a documented feature, might
  # change
  Wx::Perl::PodRichText::EVT_PERL_PODRICHTEXT_CHANGED
      ($self, $podtext, \&_do_pod_changed);

  my $heading_sizer = Wx::BoxSizer->new (Wx::wxVERTICAL());
  $heading_sizer->Add ($heading_label,
                       0);                # proportion, no stretch
  $heading_sizer->AddSpacer (0.3 * $line_height);
  $heading_sizer->Add ($heading_listbox,
                       1,                 # proportion, stretch
                       (Wx::wxGROW()
                        | Wx::wxALL()));  # border all sides

  my $sizer = $self->{'sizer'} = Wx::BoxSizer->new (Wx::wxHORIZONTAL());
  $sizer->Add ($heading_sizer,
               1,                    # proportion
               (Wx::wxGROW()
                | Wx::wxALL()),      # border all sides
               0.5 * $line_height);  # border width
  $sizer->Add ($podtext,
               3,                    # proportion
               (Wx::wxGROW()
                | Wx::wxALL()),      # border all sides
               0.5 * $line_height);  # border width
  $panel->SetSizerAndFit($sizer);

  $podtext->goto_pod (module => ref $self);
  return $panel;
}

sub _do_pod_changed {
  my ($self, $event) = @_;
  my $what = $event->GetWhat;

  ### _do_pod_changed() ...
  ### $what

  if ($what eq 'heading_list') {
    my $podtext = $self->{'podtext'};
    my $heading_listbox = $self->{'heading_listbox'};
    ### heading_list: $podtext->get_heading_list
    $heading_listbox->Clear;
    $heading_listbox->InsertItems([$podtext->get_heading_list], 0);
  }
}

sub _do_listbox {
  my ($self, $event) = @_;
  ### _do_listbox(): $self->{'heading_listbox'}->GetStringSelection

  my $heading_listbox = $self->{'heading_listbox'};
  my $podtext = $self->{'podtext'};
  $podtext->goto_pod (section => $heading_listbox->GetStringSelection);
}

1;
__END__

=for stopwords Wx Wx-Perl-PodBrowser Ryde

=head1 NAME

Wx::DemoModules::WxPerlPodRichText -- sample of Wx::Perl::PodRichText

=for test_synopsis sub wxperl_demo {}  sub pl {}

=head1 SYNOPSIS

 wxperl_demo.pl --show WxPerlPodRichText

=head1 DESCRIPTION

This is a sample L<Wx::Perl::PodRichText> widget for L<Wx::Demo>.

This code in this module is slightly complicated by displaying a headings
list as well as the PodRichText.  

=head1 SEE ALSO

L<Wx::Demo>,
L<Wx::Perl::PodRichText>,
L<Wx>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/wx-perl-podbrowser/index.html>

=head1 LICENSE

Copyright 2012, 2014 Kevin Ryde

Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Wx-Perl-PodBrowser.  If not, see L<http://www.gnu.org/licenses/>.

=cut

# Local variables:
# compile-command: "perl -I ../.. /usr/bin/wxperl_demo.pl -s WxPerlPodRichText"
# End:
