package WWW::ASN::Downloader;
use strict;
use warnings;
use Moo;

use File::Slurp qw(read_file write_file);
use LWP::Simple qw(get);

sub _get_url {
    my ($self, $url) = @_;
    my $content = get($url);
    die "Unable to download $url" unless defined $content;
    return $content;
}

sub _read_or_download {
    my ($self, $cache_file, $url) = @_;

    my $content;

    if (defined $cache_file && -e $cache_file) {
        $content = read_file($cache_file);
    }

    unless (defined $content && length $content) {
        $content = $self->_get_url($url);

        if (defined $cache_file) {
            write_file($cache_file, { binmode => ':utf8' }, $content);
        }
    }

    return $content;
}


1;
