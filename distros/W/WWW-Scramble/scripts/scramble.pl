#!perl
use utf8;
use WWW::Scramble;
use HTML::FormatText;
binmode (STDOUT, ':utf8');

my $s = WWW::Scramble->new();
my $file = $ARGV[0];
my $e;

if ($file !~ m/^http:/) {
#    my %attr = (
#        xtitle => '//title',
#        xcontent => '//div[@class="postbody"]',
#    );
    $e = $s->fetchfile($file, \%attr);
} else {
    $e = $s->fetchnews($file);
}

my $f = HTML::FormatText->new();
print "Title: ".$f->format( $e->title );
print "content: ".$f->format($e->content);
