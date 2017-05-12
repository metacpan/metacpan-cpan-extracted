package t::oEmbed;
use Test::Base -Base;

use JSON::XS;

our @EXPORT = qw( read_json );

sub read_json() {
    open my $fh, shift or die $!;
    my $json = join '', <$fh>;
    decode_json($json);
}


1;
