package WWW::WTF::Helpers::QRCode;
use common::sense;

use URI;
use Test2::V0 '!meta';
use Export::Attrs;
use WWW::WTF::Helpers::ExternalCommand qw/ run_external_command /;

sub get_uri_from_qr_code_image_path :Export {
    my ($path) = @_;

    unless (-e $path) {
        fail("get_uri_from_qr_code_image_path(): file doesn't exist " . $path);
        return;
    }

    my $out = eval {
        return run_external_command({
            command => 'zbarimg',
            args    => [ $path, '--quiet', '--nodbus' ],
        });
    };

    return unless $out;

    unless ($out =~ m/^QR\-Code:/) {
        fail("get_uri_from_qr_code_image_path(): zbarimg did not return a qr code");
        return;
    }

    $out =~ s/^QR\-Code://;

    return URI->new($out);
}

sub get_uri_from_qr_code_data_uri :Export {
    my ($string) = @_;

    my $uri = URI->new($string);

    unless (ref($uri) eq 'URI::data') {
        fail("get_uri_from_qr_code_data_uri(): expected a data URI but got " . ref($uri));
        return;
    }

    my $out = run_external_command({
        command => 'zbarimg',
        input   => $uri->data,
        args    => [ '-', '--quiet', '--nodbus' ],
    });

    unless ($out =~ m/^QR\-Code:/) {
        fail("get_uri_from_qr_code_data_uri(): zbarimg did not return a qr code");
        return;
    }

    $out =~ s/^QR\-Code://;

    return URI->new($out);
}

1;
