# Copyright 2012, 2013, 2017 Kevin Ryde

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


package Wx::DemoModules::WxPerlPodBrowser;
use 5.008;
use strict;
use warnings;
use Wx;
use base 'Wx::Panel';

# uncomment this to run the ### lines
# use Smart::Comments;


our $VERSION = 15;

use constant title         => 'WxPerlPodBrowser';
use constant add_to_tags   => 'managed';

sub new {
  my ($class, $parent) = @_;
  my $self = $class->SUPER::new($parent);

  my $sizer = Wx::BoxSizer->new (Wx::wxVERTICAL());
  {
    my $create_button
      = $self->{'create_button'}
        = Wx::Button->new ($self, Wx::wxID_ANY(),
                           Wx::GetTranslation('Create'));
    Wx::Event::EVT_BUTTON ($self, $create_button, 'browser_create');
    my $line_height = $create_button->GetSize->GetHeight;
    $sizer->Add ($create_button, 0, 0, 0.5 * $line_height);
  }
  {
    my $destroy_button
      = $self->{'destroy_button'}
        = Wx::Button->new ($self, Wx::wxID_ANY(),
                           Wx::GetTranslation('Destroy'));
    $destroy_button->Enable(0);
    Wx::Event::EVT_BUTTON ($self, $destroy_button, 'browser_destroy');
    my $line_height = $destroy_button->GetSize->GetHeight;
    $sizer->Add ($destroy_button, 0, 0, 0.5 * $line_height);
  }
  {
    my $goto_demo_button
      = $self->{'goto_demo_button'}
        = Wx::Button->new ($self, Wx::wxID_ANY(),
                           Wx::GetTranslation('Goto Demo POD'));
    Wx::Event::EVT_BUTTON ($self, $goto_demo_button, 'browser_goto_demo_pod');
    my $line_height = $goto_demo_button->GetSize->GetHeight;
    $sizer->Add ($goto_demo_button, 0, 0, 0.5 * $line_height);
  }

  $self->SetSizerAndFit($sizer);
  return $self;
}

sub browser_create {
  my ($self) = @_;
  if ($self->{'browser'}) {
    Wx::LogMessage ('Raise existing PodBrowser window');
    $self->{'browser'}->Raise;

  } else {
    Wx::LogMessage ('Create PodBrowser window');

    require Wx::Perl::PodBrowser;
    my $browser = $self->{'browser'} = Wx::Perl::PodBrowser->new ($self);
    $browser->Show;
    Scalar::Util::weaken($self->{'browser'});

    $self->{'destroy_button'}->Enable(1);
  }
}

sub browser_destroy {
  my ($self) = @_;
  if (my $browser = delete $self->{'browser'}) {
    Wx::LogMessage ('Destroy PodBrowser window');
    $browser->Destroy;
  } else {
    Wx::LogMessage ('PodBrowser window already destroyed');
  }
  $self->{'create_button'}->Enable(1);
  $self->{'destroy_button'}->Enable(0);
  $self->{'goto_demo_button'}->Enable(0);
}

sub browser_goto_demo_pod {
  my ($self) = @_;
  if (! $self->{'browser'}) {
    $self->browser_create;
  }
  my $module = ref $self;
  Wx::LogMessage ("Go to $module");
  $self->{'browser'}->goto_pod (module => $module);
}

1;
__END__

=for stopwords Wx Wx-Perl-PodBrowser Ryde Goto

=head1 NAME

Wx::DemoModules::WxPerlPodBrowser -- demonstrate Wx::Perl::PodBrowser

=for test_synopsis sub wxperl_demo {}  sub pl {}

=head1 SYNOPSIS

 wxperl_demo.pl -s WxPerlPodBrowser

=head1 DESCRIPTION

This module runs L<Wx::Perl::PodBrowser> from within L<Wx::Demo>.
C<PodBrowser> is a top-level window so is in the menus under

    wxPerl
      Managed Windows
        wxPerlPodBrowser

In the source code of this demo the key part is the browser creation

    $browser = Wx::Perl::PodBrowser->new ($self);
    $browser->Show;

The "Goto Demo POD" button demonstrates C<goto_pod()> called from program
code.  In a real program it might go to the program's own POD or relevant
module.

=head1 SEE ALSO

L<Wx::Demo>,
L<Wx::Perl::PodBrowser>,
L<Wx>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/wx-perl-podbrowser/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2017 Kevin Ryde

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
# compile-command: "wxperl_demo.pl -s WxPerlPodBrowser"
# End:
