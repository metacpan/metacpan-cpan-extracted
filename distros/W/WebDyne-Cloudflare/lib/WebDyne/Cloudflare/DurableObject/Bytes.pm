package WebDyne::Cloudflare::DurableObject::Bytes;

use 5.020;
use strict;
use warnings;
our $VERSION='0.001';

sub new {
    my ($class, $value)=@_;
    die "Expected one byte string\n" unless ((@_==2)&&defined($value)&&!ref($value));
    die "Byte value contains wide characters\n" unless utf8::downgrade($value, 1);
    die "Byte value exceeds 1 MiB\n" if (length($value)>1048576);
    return bless({value => $value}, $class);
}

sub value { return shift()->{'value'}; }

1;
