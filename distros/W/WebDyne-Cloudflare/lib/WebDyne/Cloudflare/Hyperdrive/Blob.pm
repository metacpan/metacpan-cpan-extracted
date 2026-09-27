package WebDyne::Cloudflare::Hyperdrive::Blob;

use 5.020;
use strict;
use warnings;

our $VERSION='0.001';

sub new {
    my ($class, $bytes)=@_;
    die "Hyperdrive blob requires bytes\n"
        unless (defined($bytes)&&!ref($bytes)&&utf8::downgrade($bytes, 1));
    return bless({ bytes => $bytes }, $class);
}


sub bytes { return shift()->{'bytes'}; }

1;
