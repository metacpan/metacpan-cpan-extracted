package dtRdr::GUI::Wx::TextViewer;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use XML::Twig;

use Wx::DND; # clipboard+drag-n-drop support
use Wx qw(
  :dnd
  wxTheClipboard
);

use base 'dtRdr::GUI::Wx::TextViewer0';

use Wx::Event ();

use dtRdr::Logger;

use dtRdr::Accessor;
# TODO AUTOACCESSORS {{{
dtRdr::Accessor->ro qw(
  button_close
  button_copy_all
  html_widget
);
# TODO AUTOACCESSORS }}}

dtRdr::Accessor->rw qw(
  content
);

=head1 NAME

dtRdr::GUI::Wx::TextViewer - popup text viewer with clipboard

=head1 SYNOPSIS

=cut

=head2 init

  $viewer->init;

=cut

sub init {
  my $self = shift;

  $self->html_widget->init($self);

  my @bmap = (
    [qw(close    Close)],
    [qw(copy_all copy_all)],
  );
  foreach my $row (@bmap) {
    my ($att, $method) = @$row;
    $att = 'button_' . $att;
    Wx::Event::EVT_BUTTON(
      $self, $self->$att->GetId, sub {$self->$method();}
    );
  }
} # end subroutine init definition
########################################################################

=head2 set_content

  $viewer->set_content($content);

=cut

sub set_content {
  my $self = shift;
  my ($content) = @_;

  # remember content so we can respond to copy_all, etc
  $self->SUPER::set_content($content);
  $self->html_widget->SetPage($content);

} # end subroutine set_content definition
########################################################################

=head2 copy_all

  $viewer->copy_all;

=cut

sub copy_all {
  my $self = shift;
  my $content = $self->get_content;
  my $text = $content;
  if(0) { # oh boy! workaround segfault
    $text =~ s/\015\012/\n/g;
    $text =~ s/<[^>]+>//g;
    $text =~ s/^\s+(\n[ \t]*)/$1/;
    $text =~ s/(\n)*\s+$/$1/;
  }
  else { # I would much rather do it with twig, but segfault!
    my $twig = XML::Twig->new(
      keep_spaces => 0,
      keep_encoding => 1,
    );
    $twig->parse($content);
    $text = $twig->root->text;
    # eek! this regex fixes the segfault????
    $text =~ s/(\n)*\s+$/$1/;
    # as does anything else?
    #$text .= " ";
  }
  #WARN("|$text|");
  # clipboard
  {
    my $copy = $text;
    my $cb = wxTheClipboard;
    my $data = Wx::TextDataObject->new($copy);
    $cb->UsePrimarySelection(1);
    if($cb->Open) {
      $cb->SetData($data) or warn "nope!";
      $cb->Close;
    }
    else {
      L->warn("could not open the clipboard");
    }
  }
  return($text);
} # end subroutine copy_all definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
