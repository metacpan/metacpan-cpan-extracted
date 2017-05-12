####!perl -T

use Test::More tests => 23;
use Test::Deep;
use Data::Dumper;

use XDI;
use XDI::Message;

use Log::Log4perl qw(get_logger :levels);
Log::Log4perl->easy_init($INFO);


BEGIN {
	my $logger = get_logger();
	my $description;
	#Log::Log4perl->easy_init($DEBUG);
    use_ok( 'XDI' ) || print "Bail out!\n";
    
    my $xdi = new XDI;
    isa_ok($xdi,XDI);
    
    $xdi = XDI->new();
    isa_ok($xdi,XDI);
    
    # initialize tests
    my $iname = '=tester';
    $description = "Init with an iname";
    
    $xdi = XDI->new($iname);
    cmp_deeply($xdi->from,$iname,$description);
    
    $description = "Also initializes from-graph";
    cmp_deeply($xdi->from_graph,$iname,$description);
    
    my $alternate = '=mcTest';    
    $xdi->from($alternate);
    $description = "Setter/Getter";
    cmp_deeply($xdi->from,$alternate,$description);
    
    
	# XDI::Connection
	my $target = "=test";
	my $hash = {
		target => $target
	};
    $description = "Create connection";
    my $c = $xdi->connect($hash);
    isa_ok($c,XDI::Connection);
    
    $description = "Check graph target";
    cmp_deeply($c->target,$target,$description);
    
    $description = "Resolve an XDI inumber";
	$lookup = '@!3436.F6A6.3644.4D74';
    $result = XDI::Connection::inumber_lookup($lookup);
    cmp_deeply($result->[1],$lookup,$description);
    #print Dumper($result);
    
    $description = "Resolve an XDI iname";
	$lookup = '@xdi';
    $result = XDI::Connection::iname_lookup($lookup);
    cmp_deeply($result->[1],'@!3D12.8C35.6FB3.E89C',$description);
    
   
    $description = "Get the XDI server URL for an iname";
    my $xdi_url = '@kynetx';
    $regx = qr/https:..xdi.fullxri.com/;
    $result = XDI::Connection::lookup($xdi_url);
    #print Dumper($result);
    cmp_deeply($result->[2],re($regx),$description);

    $description = "Get the XDI server URL for an inumber";
    $xdi_url = '@!3436.F6A6.3644.4D74';
    $regx = qr/https:..xdi.fullxri.com/;
    $result = XDI::Connection::lookup($xdi_url);
    cmp_deeply($result->[2],re($regx),$description);
    
    
    # XDI::Message
    my $msg = XDI::Message->new();
    isa_ok($msg,XDI::Message);
    
    my @marry = ();
    
    $description = "Start building message with from_graph, from";
    my $from_graph = '@example';
    $msg->from_graph($from_graph);
    $msg->from($from_graph);
    my $regx = qr/^\($from_graph\)/;
    my $result = $msg->_local_requestor;
    cmp_deeply($result,re($regx),$description   );
    push(@marry,$result);
    
    $description = "Configure message target";
    $msg->target($target);
    $regx = qr/^$from_graph.+\/\$is\(\)\/\($target\)$/;
    $result = $msg->_destination;
    cmp_deeply($result,re($regx),$description);
    push(@marry,$result);
    
    $description = "Check timestamp";
    $regx = qr/\(data:,\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ\)$/;
    $result= $msg->_timestamp_statement;
    cmp_deeply($result,re($regx),$description);
    push(@marry,$result);
    
    $description = "Check message link contract";
    my $lc = '()';
    $msg->link_contract($lc);
    $regx = qr/$lc\$do$/;
    $result = $msg->_link_contract;
    cmp_deeply($result,re($regx),$description);
    
    $description = "Check op statement";
    my $op = '$get';
    my $otarget = $target;
    $regx = qr/\/$otarget$/;
    $result = $msg->_operation($op,$otarget);
    cmp_deeply($result,re($regx),$description);
    
    $description = "add \$get statement to message";
    $result = $msg->get($otarget);
    cmp_deeply($result,1,$description);
    
    $description = "Check operation statements";
    $result = $msg->operations;
    my $expected = [$otarget];
    cmp_deeply($result,$expected,$description);
    
	$description = "Try to mix ops in a message";
	$result = $msg->add($target);
	cmp_deeply($result,0,$description);
	
	$description = 'Check message type';
	$result = $msg->type;
	cmp_deeply($result,$op,$description);
	
	$description = "check auth statement";
	my $secret = "Mxyzplkt";
	$regx = qr/\$secret\$!\(\$token\)\/!\/\(data:,$secret\)$/;
	$msg->secret($secret);
	$result = $msg->_auth_statement;
	cmp_deeply($result,re($regx), $description);
		
	$logger->debug("Text: ",$msg->to_string);
}

diag( "Testing XDI $XDI::VERSION, Perl $], $^X" );
