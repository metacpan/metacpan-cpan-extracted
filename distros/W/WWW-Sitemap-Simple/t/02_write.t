use strict;
use warnings;
use Test::More;
use File::Temp qw/ tempfile tempdir /;
use IO::File;
use IO::Zlib;
use Compress::Zlib;

use WWW::Sitemap::Simple;

my $EXPECTED = <<'_XML_';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>http://rebuild.fm/</loc>
	</url>
</urlset>
_XML_

{
    my ($tmpfh, $tmp_filename) = tempfile('tempfile_XXXXXXXX', UNLINK => 1);
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    $sm->write($tmp_filename);

    open my $fh, '<', $tmp_filename or die $!;
    my $xml = do { local $/; <$fh> };
    close $fh;
    is $xml, $EXPECTED, 'file'; 
}

{
    my $tmp_filename = tempdir(CLEANUP => 1). "sitemap.gz";
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    $sm->write($tmp_filename);

    open my $fh, '<', $tmp_filename or die $!;
    my $xml = do { local $/; <$fh> };
    close $fh;
    is $xml, Compress::Zlib::memGzip($EXPECTED), 'file gz'; 
}

{
    my ($tmpfh, $tmp_filename) = tempfile(UNLINK => 1);
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    $sm->write($tmpfh);
    close $tmpfh;

    open my $fh, '<', $tmp_filename or die $!;
    my $xml = do { local $/; <$fh> };
    close $fh;
    is $xml, $EXPECTED, 'file glob'; 
}

{
    my ($tmpfh, $tmp_filename) = tempfile(UNLINK => 1);
    $tmpfh = IO::File->new($tmp_filename => 'w');
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    $sm->write($tmpfh);
    $tmpfh->close;

    open my $fh, '<', $tmp_filename or die $!;
    my $xml = do { local $/; <$fh> };
    close $fh;
    is $xml, $EXPECTED, 'file handle';
}

{
    my ($tmpfh, $tmp_filename) = tempfile(UNLINK => 1);
    $tmpfh = IO::Zlib->new($tmp_filename => 'wb9');
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    $sm->write($tmpfh);
    $tmpfh->close;

    open my $fh, '<', $tmp_filename or die $!;
    my $xml = do { local $/; <$fh> };
    close $fh;
    is $xml, Compress::Zlib::memGzip($EXPECTED), 'file handle gz';
}

done_testing;
