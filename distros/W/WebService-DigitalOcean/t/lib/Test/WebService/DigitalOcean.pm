package
    # hide from PAUSE
    Test::WebService::DigitalOcean;
use warnings;
use strict;
use utf8;
use Exporter qw/import/;
use WebService::DigitalOcean;
use Carp qw/confess/;
use HTTP::Response;
use FindBin '$Bin';

my ($Current_Object, $Expected_Response, $Last_Request);

our @EXPORT = qw/get_last_request set_expected_response/;

{
    no warnings 'redefine', 'once';
    no strict 'refs';

    *WebService::DigitalOcean::_send_request = \&_mocked_send_request;
}

sub new {
    my $class = shift;

    $Current_Object = WebService::DigitalOcean->new(@_);

    return $Current_Object;
}

sub get_last_request {
    return $Last_Request;
}

sub set_expected_response {
    my ($filename) = @_;

    my $slurped = _slurp("$Bin/responses/$filename");

    $Expected_Response = HTTP::Response->parse($slurped);
    return;
}

sub _mocked_send_request {
    my ( $self, $request ) = @_;

    $Last_Request = $request;

    if ( !defined $Expected_Response ) {
        confess "Test implemented with errors: "
              . "please define the response before making request";
    }

    return $Expected_Response;
}

sub _slurp {
    my ($path) = @_;

    open my $fh, '<', $path or die $!;
    my $slurped = do { local $/; <$fh> };
    close $fh or die $!;

    return $slurped;
}

1;
