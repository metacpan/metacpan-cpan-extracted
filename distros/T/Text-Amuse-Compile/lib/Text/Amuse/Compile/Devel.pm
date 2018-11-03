package Text::Amuse::Compile::Devel;

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Text::Amuse::Compile::Fonts;
use Text::Amuse::Compile::Fonts::Selected;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );


our @ISA = qw(Exporter);
our @EXPORT_OK = qw/explode_epub create_font_object/;


=head1 NAME

Text::Amuse::Compile::Utils - Common routines used for developmetn

=head1 FUNCTIONS

=head2 explode_epub

Return the HTML content of an epub

=head2 create_font_object

Return a valid Text::Amuse::Compile::Fonts::Selected object.

=cut

sub explode_epub {
    my $epub = shift;
    my $zip = Archive::Zip->new;
    die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
    my $tmpdir = File::Temp->newdir(CLEANUP => 1);
    $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
      or die "Cannot extract $epub OPS into $tmpdir";
    opendir (my $dh, $tmpdir->dirname) or die $!;
    my @pieces = sort grep { /\Apiece\d+\.xhtml\z/ } readdir($dh);
    closedir $dh;
    my @html;
    foreach my $piece ('toc.ncx', 'titlepage.xhtml', @pieces) {
        push @html, "<!-- $piece -->",
          read_file(File::Spec->catfile($tmpdir->dirname, $piece));
    }
    return join('', @html);
}

sub create_font_object {
    my $fonts = Text::Amuse::Compile::Fonts->new;
    return Text::Amuse::Compile::Fonts::Selected->new(size => 12,
                                                      sans => ($fonts->sans_fonts)[0],
                                                      main => ($fonts->serif_fonts)[0],
                                                      mono => ($fonts->mono_fonts)[0]);
}
