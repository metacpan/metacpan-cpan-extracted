#! perl -Iblib/arch -Iblib/lib
use Tuxedo;

sub TOUPPER {
    my ($tpsvcinfo) = @_;
    my ($inbuf) = $tpsvcinfo->data;
    $inbuf->value( ($newval = uc($inbuf->value)) );
    return ( TPSUCCESS, 0, $inbuf, $tpsvcinfo->len, 0 );
}

sub REVERSE {
    my ($tpsvcinfo) = @_;
    my ($buf) = $tpsvcinfo->data;
    $buf->value( ($newval = reverse($buf->value)) );
    return ( TPSUCCESS, 0, $buf, $tpsvcinfo->len, 0 );
}

tpadvertise( "TOUPPER", \&TOUPPER );
tpadvertise( "REVERSE", \&REVERSE );
