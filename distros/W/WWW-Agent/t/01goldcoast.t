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

use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

#== TESTS =====================================================================

#sub POE::Kernel::TRACE_DEFAULT  () { 1 }

close STDERR;
open (STDERR, '/dev/null');

use WWW::Agent;
use WWW::Agent::Plugins::GoldCoasting;
use POE;

{
    my $a = WWW::Agent->new (ua      => new TestUA,
			     plugins => [
					 new WWW::Agent::Plugins::GoldCoasting (wait  => 1,
										limit => 3),
					 ]);
    POE::Kernel->post ('agent', 'cycle_start', 'newtab', new HTTP::Request ('GET', 'http://www.rumsti.org/'));
    $a->run;
    ok (1, 'here we are');
}

close STDERR;

__END__

