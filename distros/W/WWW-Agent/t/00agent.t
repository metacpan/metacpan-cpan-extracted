package main;

use Log::Log4perl;
Log::Log4perl->init("t/log.conf");
our $log = Log::Log4perl->get_logger("Agent");

1;

package TestUA;

sub new {
    return bless {}, 'TestUA';
}

sub request {
    my $self = shift;
    my $req  = shift;

    use HTTP::Response;
    my $resp = HTTP::Response->new( 200, 'OK', [ Rumsti => 'Ramsti' ], "Rumstis will rule" );
    $resp->request ($req);

    return $resp;
}

1;

package TestPlugin;

use Data::Dumper;
use POE;

sub new {
    return bless {
	hooks => {
	    'init' => sub {
		my ($kernel, $heap)  = (shift, shift);
		$heap->{test} = 0;
		POE::Kernel->post ('agent' => 'cycle_start', 'mytab', new HTTP::Request ('GET', 'http://rumsti'));
		return 1;
	    },
	    'cycle_pos_response' => sub {
		my ($kernel, $heap)  = (shift, shift);
		my ($tab, $response) = (shift, shift);
		$heap->{test}++;
		POE::Kernel->yield ('test_me');
		return $response;
	    },
	    'test_me' => sub {
		my ($heap) = $_[HEAP];
		ok ($heap->{test} == 1, 'Test plugin: called and data');
	    }
	},
	namespace => 'test',
    }, 'TestPlugin';
}

1;

use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

#== TESTS =====================================================================

#sub POE::Kernel::TRACE_DEFAULT  () { 1 }

require_ok ('WWW::Agent');

{
    my $a = WWW::Agent->new (ua => new TestUA);
    is (ref ($a), 'WWW::Agent', 'class');
    $a->run;
    ok (1, 'empty agent returns immediately');
}

{
    my $a = WWW::Agent->new (plugins => [
					 new TestPlugin
					 ],
			     ua => new TestUA);
    $a->run;
}

__END__

