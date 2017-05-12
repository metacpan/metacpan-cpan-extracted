package dtRdr::HTMLWidget::Shared;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


use MIME::Base64 ();

BEGIN { # naive traits implementation
  use Exporter;
  *{import} = \&Exporter::import;
  our @EXPORT_OK = qw(
    base64_images_filter
    absolute_images_filter
    get_scroll_pos
    set_scroll_pos
    scroll_page_down
    scroll_page_up
    jump_to_anchor
  );
}
=head1 NAME

dtRdr::HTMLWidget::Shared - selectively shared code

=head1 SYNOPSIS

=cut

=head2 base64_images_filter

  $html = $hw->base64_images_filter($html, $datahandle);

=cut

sub base64_images_filter {
  my $self = shift;
  my ($html, $dh) = @_;

  my $inline_image = sub {
    my ($imagepath, $ext) = @_;
    $imagepath =~ s#^file://##;
    if(-e $imagepath) {
      return(qq(<img src="file://$imagepath" />));
    }
    my $image = $dh->get_member_string($imagepath) or
      warn "couldn't get image '$!'";
    my $enc_image = MIME::Base64::encode($image);
    return qq(<img src="data:image/$ext;base64,$enc_image" />);
  };
  $html =~ s/<img[^>]+?src="([^"]+?\.(\w{3,4}))"[^>]+?>/
            $inline_image->($1,$2)/xige;
  return($html);
} # end subroutine base64_images_filter definition
########################################################################


=head2 absolute_images_filter

Converts relative image paths to absolute image paths
needed for widgets that do not support <base href>.

  $html = $hw->absolute_images_filter($html, $dh);

=cut

sub absolute_images_filter {
  my $self = shift;
  my ($source, $dh) = @_;

  my $base_dir = $dh->get_base_dir;
  my $filter = sub {
    my ($img_path) = @_;
    if(($img_path !~ /^\w{3,4}:/g) and ($img_path !~ /^$base_dir/g)) {
        $img_path = 'file://' . $base_dir.$img_path;
    }
    return $img_path;
  }; # $filter
  $source =~ s/(<img.*?src\s*=\s*)(["'])([^\2]+?)\2/
    $1.$2.$filter->($3).$2/xige;
  return($source);
} # end subroutine absolute_images_filter definition
########################################################################

=head2 base64_images_rewriter

Returns a subref that tranforms $src values into base64-encode images.

  my $sub = $hw->base64_images_rewriter

  $src = $sub->($was_src, $book);

=cut

sub base64_images_rewriter {
  my $subref = sub {
    my ($src, $dh) = @_;
    use URI;
    use URI::Escape;
    my $uri = URI->new($src);
    my $filename;
    my $scheme = $uri->scheme;
    if($scheme and ($scheme ne 'file')) {
      # guess it is okay
      return($src);
    }
    else {
      my $image;
      my $ext;
      if($scheme and $scheme eq 'file') {
        # guess that's absolute
        my $file = $uri->file;
        $ext = $file;
        open(my $fh, '<', $file) or
          die "cannot open $file $!";
        local $/;
        $image = <$fh>;
      }
      else {
        # assume that is relative to the book
        my $imagepath = uri_unescape($uri->path);
        $ext = $imagepath;
        $image = $dh->get_member_string($imagepath) or
          warn "couldn't get image '$!'";
      }
      $ext =~ s/.*(\.[^\.]+)$/$1/;
      my $enc_image = MIME::Base64::encode($image);
      return("data:image/$ext;base64,$enc_image");
    }
  };
  return($subref);
} # end subroutine base64_images_rewriter definition
########################################################################

=head1 Hacks

The following would be errors according to the base class, but we've
made them warnings here.  Really need to get the widgets whipped into
shape.

  get_scroll_pos
  jump_to_anchor
  scroll_page_down
  scroll_page_up
  set_scroll_pos

=cut

 sub get_scroll_pos { my $self = shift; $self->WARN_NOT_IMPLEMENTED; 0;}
 ########################################################################
 sub set_scroll_pos { my $self = shift; $self->WARN_NOT_IMPLEMENTED; 0;}
 ########################################################################
 sub scroll_page_down { my $self = shift; $self->WARN_NOT_IMPLEMENTED; 0;}
 ########################################################################
 sub scroll_page_up { my $self = shift; $self->WARN_NOT_IMPLEMENTED; 0;}
 ########################################################################
 sub jump_to_anchor { my $self = shift; $self->WARN_NOT_IMPLEMENTED; 0;}
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
