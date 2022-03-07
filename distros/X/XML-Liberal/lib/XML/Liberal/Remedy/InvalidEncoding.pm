package XML::Liberal::Remedy::InvalidEncoding;
use strict;

use Encode;
use Encode::Guess;

my $RX = qr/^(<\?xml\s+version\s*=\s*["']1\.[01]["']\s+encoding\s*=\s*["'])([^"']+)/;

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^\s*(?:(?:i18n |encoding )?error : )?input conversion failed due to input error/;

    my (undef, $encoding) = $$xml_ref =~ $RX;
    unless ($encoding) {
        my @suspects = @{ $driver->guess_encodings || [ qw(euc-jp shift_jis utf-8) ] };
        my $enc = guess_encoding($$xml_ref, @suspects);
        $encoding = $enc->name;
    }

    if ($encoding) {
        Encode::from_to($$xml_ref, $encoding, "UTF-8"), return 1
            if $$xml_ref =~ s/$RX/$1utf-8/;
    }

    Carp::carp("Can't find encoding from XML declaration: ", substr($$xml_ref, 0, 128));
    return 0;
}

1;
