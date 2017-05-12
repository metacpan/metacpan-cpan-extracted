# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


package App::MathImage::Tk::About;
use 5.008;
use strict;
use warnings;
use Tk;
use Locale::TextDomain 1.19 ('App-MathImage');

use base 'Tk::Derived', 'Tk::Dialog';
Tk::Widget->Construct('AppMathImageTkAbout');

our $VERSION = 110;

# uncomment this to run the ### lines
# use Smart::Comments;


sub Populate {
  my ($self, $args) = @_;
  ### Populate(): $args
  $self->SUPER::Populate($args);
  $self->configure (-title   => __('Math-Image: About'),
                    -bitmap  => 'info',
                    -text    => $self->text,
                   );
  my $button = $self->Subwidget('B_OK');
  $button->configure (-command => sub { $self->destroy });
  $button->focus;
}

sub text {
  my ($self) = @_;
  return (__x('Math Image version {version}',
              version => $VERSION)
          . "\n\n"
          . __x('Running under Perl {perl_version} and Perl-Tk {perl_tk_version} (Tk version {tk_version})',
                perl_version    => $^V,
                perl_tk_version => Tk->VERSION,
                tk_version      => $Tk::version));
}

1;
__END__

# =for stopwords Ryde Tk
# 
# =head1 NAME
# 
# App::MathImage::Tk::About -- math-image Tk about dialog
# 
# =head1 SYNOPSIS
# 
#  use App::MathImage::Tk::About;
#  my $about = App::MathImage::Tk::About->new ($parent_widget);
#  $about->Show;
# 
# =head1 CLASS HIERARCHY
# 
# C<App::MathImage::Tk::About> is a subclass of C<Tk::Dialog>.
# 
#     Tk::Widget
#       Tk::Frame
#       Tk::Wm
#         Tk::TopLevel
#           Tk::DialogBox
#             Tk::Dialog
#               App::MathImage::Tk::About
# 
# =head1 DESCRIPTION
# 
# This is the about dialog for the math-image program Tk interface.
# 
#     +--------------------------------------------+
#     |                                            |
#     |  ---     Math-Image version 109            |
#     | | i |                                      |
#     |  ---     Running under Perl v5.14.2 and    |
#     |          Perl-Tk 8004.03 (Tk version 8.4)  |
#     |                                            |
#     +--------------------------------------------+
#     |                     OK                     |
#     +--------------------------------------------+
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< $main = App::MathImage::Tk::About->new () >>
# 
# =item C<< $main = App::MathImage::Tk::About->new ($parent) >>
# 
# Create and return a new about dialog.
# 
# The optional C<$parent> is per C<Tk::Dialog>.  Usually it should be the
# application main window.
# 
# =head1 SEE ALSO
# 
# L<App::MathImage::Tk::Main>,
# L<App::MathImage::Tk::Diagnostics>
# L<math-image>,
# L<Tk>
# 
# =head1 HOME PAGE
# 
# L<http://user42.tuxfamily.org/math-image/index.html>
# 
# =head1 LICENSE
# 
# Copyright 2011, 2012, 2013 Kevin Ryde
# 
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
# 
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
# 
# You should have received a copy of the GNU General Public License along with
# Math-Image.  If not, see L<http://www.gnu.org/licenses/>.
# 
# =cut
