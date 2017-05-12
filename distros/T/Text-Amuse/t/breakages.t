use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 10;

my $document =
  Text::Amuse->new(file => catfile(t => testfiles => 'breaklist.muse'),
                   debug => 0);

ok($document->as_latex);
ok($document->as_html);

$document =
  Text::Amuse->new(file => catfile(t => testfiles => 'images.muse'));
ok($document->as_latex);
ok($document->as_html);
ok($document->as_latex);
ok($document->as_html);
my @images = $document->attachments;
is(scalar(@images), 2, "Found 2 images");
is_deeply([ @images ], ["myimage.png", "other.png"]);

$document =
  Text::Amuse->new(file => catfile(t => testfiles => 'open-letter.muse'),
                   debug => 1);

ok($document->as_latex);
ok($document->as_html);

# print Dumper($document);

sub write_to_file {
    my ($file, @stuff) = @_;
    open (my $fh, ">:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    print $fh @stuff;
    close $fh;
}

sub read_file {
    my $file = shift;
    local $/ = undef;
    open (my $fh, "<:encoding(utf-8)", $file) or die "Couldn't open $file $!";
    my $string = <$fh>;
    close $fh;
    return $string;
}
