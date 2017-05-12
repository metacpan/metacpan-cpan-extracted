use strict;
use warnings;
use Plack::Test;
use Test::More tests => 2;
use HTTP::Request;
use HTTP::Request::Common;
use Data::Dumper;
{
    package CalculatorImplementation;
    use Moo;
    use XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation;
    with 'XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation';

    sub soapaction_add {
        my ( $self, $soap, $data, $dsl ) = @_;
        return +{
            Result => $data->{parameters}->{x} + $data->{parameters}->{y},
        };
    }

    no Moo;
}

{
    package Custom1;
    use Dancer2;
    use XML::Compile::SOAP::Daemon::Dancer2;;

    wsdl_endpoint '/calculator', {
        wsdl                    => 'calculator11.wsdl',
        xsd                     => [],
        implementation_class    => 'CalculatorImplementation',
    };
}

{
    package Custom2;
    use Dancer2;
    use XML::Compile::SOAP::Daemon::Dancer2;;

    wsdl_endpoint '/calculator', {
        wsdl                    => 'calculator12.wsdl',
        xsd                     => [],
        implementation_class    => 'CalculatorImplementation',
    };
}

subtest 'SOAP 1.1 Test' => sub
{
    my $app = Custom1->to_app;
    my $test = Plack::Test->create($app);

    open my $fh, '<', "t/wsdl/calculator11.wsdl"  or die;
    $/ = undef;
    my $data = <$fh>;
    close $fh;
    my $response = $test->request( GET "/calculator?wsdl" );
    is $response->content, $data, "Wsdl retrieved correclty";

    my $request = HTTP::Request->parse( <<EOR );
POST /calculator
Content-Type: text/xml; charset=utf-8
SOAPAction: "add"

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Body>
    <tns:add xmlns:tns="http://www.parasoft.com/wsdl/calculator/">
      <tns:x>4</tns:x>
      <tns:y>5</tns:y>
    </tns:add>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOR
    $response = $test->request( $request );
    is $response->content, <<EOResponse, "Response is correct SOAP1.1";
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Body><tns:addResponse xmlns:tns="http://www.parasoft.com/wsdl/calculator/"><tns:Result>9</tns:Result></tns:addResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
EOResponse

    is $response->content_type, 'text/xml';
    is $response->headers->{'content-type'}, 'text/xml; charset="utf-8"';

};

subtest 'SOAP1.2 test' => sub
{
    my $app = Custom2->to_app;
    my $test = Plack::Test->create($app);

    open my $fh, '<', "t/wsdl/calculator12.wsdl"  or die;
    $/ = undef;
    my $data = <$fh>;
    close $fh;
    my $response = $test->request( GET "/calculator?wsdl" );
    is $response->content, $data, "Wsdl retrieved correclty";

    my $request = HTTP::Request->parse( <<EOR );
POST /calculator
Content-Type: application/soap+xml; charset=utf-8
Action: "add"

<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
  <SOAP-ENV:Body>
    <tns:add xmlns:tns="http://www.parasoft.com/wsdl/calculator/">
      <tns:x>4</tns:x>
      <tns:y>5</tns:y>
    </tns:add>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOR

    $response = $test->request( $request );
    is $response->content, <<EOResponse, "Response is correct SOAP1.2";
<?xml version="1.0" encoding="UTF-8"?>
<env12:Envelope xmlns:env12="http://www.w3.org/2003/05/soap-envelope"><env12:Body><tns:addResponse xmlns:tns="http://www.parasoft.com/wsdl/calculator/"><tns:Result>9</tns:Result></tns:addResponse></env12:Body></env12:Envelope>
EOResponse
    is $response->content_type, "application/soap+xml";
    is $response->headers->{'content-type'}, "application/soap+xml; charset=utf-8";
};