package XML::Liberal::Remedy::NotUTF8;
use strict;

use Encode;
use Encode::Guess;

sub apply {
    my $class = shift;
    my($driver, $error, $xml_ref) = @_;

    return 0 if $error->message !~
        /^parser error : Input is not proper UTF-8, indicate encoding !/;

    my @suspects = @{ $driver->guess_encodings || [ qw(euc-jp shift_jis utf-8) ] };
    my $enc = guess_encoding($$xml_ref, @suspects);
    if (ref($enc)) {
        Encode::from_to($$xml_ref, $enc->name, "UTF-8");
        return 1;
    } else {
        # fallback to UTF-8 and do roundtrip conversion
        my $old = $$xml_ref;
        my $xml = Encode::encode("utf-8", Encode::decode("utf-8", $$xml_ref));
        $$xml_ref = $xml;
        return $$xml_ref ne $old;
    }
}

1;
