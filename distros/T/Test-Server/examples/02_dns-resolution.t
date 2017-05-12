#!/usr/bin/perl

=head1 NAME

dns-resolution.t - query dns server and check for the answers

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
	dns-resolution:
	    domains:
	        somedomain.org:
	        someother.com:
	            A: 192.168.100.6
	        thirdomaine.com:
	            A: 192.168.100.5
	            CNAME: ip2-somedomain.com
	            
	            count: 100
	            max-time: 50
	            failed: 1
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
#use Test::More tests => 1;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';

eval "use Net::DNS::Resolver";
plan 'skip_all' => "need Net::DNS::Resolver to run dns tests" if $@;

my $config = LoadFile($Bin.'/test-server.yaml');
plan 'skip_all' => "no configuration sections for 'dns-resolution'"
	if (not $config or not $config->{'dns-resolution'});


exit main();

sub main {
	plan 'no_plan';
	
	my $domains    = $config->{'dns-resolution'}->{'domains'}  || {};
	my $res = Net::DNS::Resolver->new;
	
	# loop through domains that need to be checked
	foreach my $domain (keys %$domains) {
		# lookup domain, if fail skip the rest of the tests for it
		my $answer = $res->search($domain);
		ok($answer, 'lookup '.$domain) or next;
		
		# what rrs need to be tested
		my $expected_rrs = $domains->{$domain};
		next if not defined $expected_rrs;
		
		# remove the timing paramters from the hash
		my $count       = delete $expected_rrs->{'count'} || 0;
		my $max_time    = delete $expected_rrs->{'max-time'}     || 100;
		my $time_failed = delete $expected_rrs->{'time-failed'};
		
		# loop through the rrs and test them
		while (my ($rr_type, $rr_value) = each %{$expected_rrs}) {
			# make array of the expected value
			my @rr_values = (
				ref $rr_value ne 'ARRAY'
				? $rr_value
				: @$rr_value
			);
			
			eq_or_diff(
				[ $answer->rr_with_type($rr_type) ],
				[ sort @rr_values ],
				'check dns '.$rr_type.' answer for '.$domain,
			);
		}
		
		# time dns responses
		if ($count) {
			eval "use Time::HiRes qw( gettimeofday tv_interval )";
			SKIP: {
				skip 'missing Time::HiRes', 1 if $@;
				
				my @response_times;
				foreach (1..$count) {
					my $domain_to_time = $domain;
					$domain_to_time = int(rand(1_000_000)).'.'.$domain
						if $time_failed;
					
					my $t0 = [ gettimeofday() ];
					$res->search($domain_to_time);
					push @response_times, tv_interval($t0)*1000;		
				}
				
				eq_or_diff(
					[ @response_times ],
					[ map { ($_ < $max_time ? $_ : 'longer than limit '.$max_time.'ms' ) } @response_times ],
					'... domain lookup response times below '.$max_time.'ms'
				);
			}
		}
	}
	
	return 0;
}


sub Net::DNS::Packet::rr_with_type {
	my $self    = shift;
	my $rr_type = shift;
	
	my @rrs_answer;
	foreach my $rr ($self->answer) {
		next if $rr->type ne $rr_type;
		
		push @rrs_answer, (
			$rr_type eq 'A'     ? $rr->address  :
			$rr_type eq 'CNAME' ? $rr->cname    :
			$rr_type eq 'PTR'   ? $rr->ptrdname :
			$rr->string,
		);
	}
	
	return (wantarray ? sort @rrs_answer : shift @rrs_answer);
}


__END__

=head1 NOTE

DNS resolution depends on L<Net::DNS::Resolver>.

=head1 AUTHOR

Jozef Kutej

=cut
