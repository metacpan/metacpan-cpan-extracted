package WWW::Agent::Plugins::GoldCoasting;

use strict;
use Data::Dumper;
use POE;

sub new {
    my $class   = shift;
    my %options = @_;
    return bless { 
	hooks => {
	    'init' => sub {
		my ($kernel, $heap)  = (shift, shift);
		$heap->{laziness}->{wait}       = $options{wait}  || 10;
		$heap->{laziness}->{limit}      = $options{limit} ||  3;
		return 1;
	    },
	    'cycle_pos_response' => sub {
                my ($kernel, $heap) = (shift, shift);
                my ($tab, $response) = (shift, shift);
                my $url  = $response->request->uri;

		warn "# before $url: working very hard for some secs";
		sleep $heap->{laziness}->{wait}; # you should not use blocking...
		$heap->{laziness}->{counter}++; # we do not care which tab it is
		if ($heap->{laziness}->{counter} < $heap->{laziness}->{limit}) {
		    $kernel->yield ('cycle_start', $tab, $response->request);
		} else {
		    $kernel->yield ('laziness_end', $tab);
		}
                return $response;
            },
	    'laziness_end' => sub {
		my ($heap) = $_[HEAP];
		warn "# we call it a life-style to stop after ".$heap->{laziness}->{limit}." requests";
	    },
	},
	namespace => 'laziness',
    }, $class;
}

our $VERSION = '0.01';
our $REVISION = '$Id: GoldCoasting.pm,v 1.2 2005/03/19 10:04:00 rho Exp $';

1;

__END__

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
