package Text::Amuse::Compile::Utils;

use utf8;
use strict;
use warnings;

=head1 NAME

Text::Amuse::Compile::Utils - Common routines used

=head1 FILE READING/WRITING/APPENDING

These functions are replacements for L<File::Slurp>, which has deemed
deprecated. Candidate modules are L<File::Slurp::Tiny> and
L<Path::Tiny>. But given that we always use utf8, and don't need all
the L<Path::Tiny> features (which are cool, but would make sense to
use them everywhere instead of L<File::Spec> etc, let's cook our own
in the meanwhile.

The following functions always use the binmode C<encoding(UTF-8)> on
the files, so they takes and return decoded strings.

The purpose of this module is just to save some typing.

=head2 read_file($file)

=head2 write_file($file, @strings)

=head2 append_file($file, @strings)

=head1 EXPORTS

None by default, only on demand.

=cut

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/append_file
                    write_file
                    read_file
                   /;


sub read_file {
    my $file = shift;
    die "Missing file" unless $file;
    die "File $file doesn't exist" unless -f $file;
    open (my $fh, '<:encoding(UTF-8)', $file) or die "Couldn't open $file $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Couldn't close $file $!";
    return $content;
}

sub write_file {
    my $file = shift;
    open (my $fh, '>:encoding(UTF-8)', $file) or die "Couldn't open $file $!";
    print $fh @_;
    close $fh or die "Couldn't close $file $!";
    return;
}

sub append_file {
    my $file = shift;
    open (my $fh, '>>:encoding(UTF-8)', $file) or die "Couldn't open $file $!";
    print $fh @_;
    close $fh or die "Couldn't close $file $!";
    return;
}
