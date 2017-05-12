package XML::XSH2::Map;
use XML::XSH2;
use Test;
plan tests => 4;


xsh << 'end.';
    $doc := open t/host.xml ;
end.
ok($doc);


xsh << 'end.';
    register-namespace u urn:jboss:domain:2.0 ;
    $socket = //u:socket[@port='\${jboss.management.native.port:9999}'] ;
end.
ok($socket);


xsh << 'end.';
    my $port = "\${jboss.management.native.port:9999}" ;
    $socket = //u:socket[@port=$port] ;
end.
ok($socket);


xsh << 'end.';
    $e := echo '#' '\${jboss.management.native.port:9999}';
end.
ok($e);
