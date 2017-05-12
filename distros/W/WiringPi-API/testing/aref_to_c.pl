use warnings;
use strict;

use Inline 'C';

my $channel = 0;
my @bytes = (0x00, 0x01, 0x02, 0x03);

testing($channel, \@bytes, 4);

__END__
__C__

int testing(int channel, SV* byte_ref, int len){

    if (channel != 0 && channel != 1){
        croak("channel param must be 0 or 1\n");
    }

    if (! SvROK(byte_ref) || SvTYPE(SvRV(byte_ref)) != SVt_PVAV){
        croak("not an aref\n");
    }

    AV* bytes = (AV*)SvRV(byte_ref);

    int num_bytes = av_len(bytes) + 1;

    if (len != num_bytes){
        croak("$len param != elem count\n");
    }

    unsigned char buf[num_bytes];

    int i;

    for (i=0; i<len; i++){
        SV** elem = av_fetch(bytes, i, 0);
        buf[i] = (int)SvNV(*elem);
    }

    /*
     * here, I'll be passing the char buffer and len
     * to an external C function. For display, I'll
     * just print the elements
     *
     *  if ((spiDataRW(channel, buf, len) < 0){
     *      croak("failed to write to the SPI bus\n");
     *  }
     */

    int x;

    for (x=0; x<len; x++){
        printf("%d\n", buf[x]);
    }
}
