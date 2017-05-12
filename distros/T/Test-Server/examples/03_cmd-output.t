#!/usr/bin/perl

=head1 NAME

sites-ok.t - check web sites

=head SYNOPSIS

	cat >> test-server.yaml << __YAML_END__
	cmd-output:
	    -
	        cmd   : echo hell world!
	        desc  : hello printing
	        output: hello? world
	    -
	        cmd   : date
	        desc  : if date command is there
	        output: '[0-9]{2}:[0-9]{2}:[0-9]{2}'
	    -
	        cmd   : perl -e 'print "hi"; exit 1'
	        desc  : check perl exit 1 return value and hi
	        output: hi
	        exit  : 1
	    -
	        cmd   : perl -e 'exit 1'
	        desc  : check perl exit != 0
	        exit  : '!= 0'
	__YAML_END__

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use YAML::Syck 'LoadFile';
use FindBin '$Bin';


my $config = LoadFile($Bin.'/test-server.yaml');

plan 'skip_all' => "no configuration sections for 'cmd-output'"
	if (not $config or not $config->{'cmd-output'});

exit main();

sub main {
	my $tests = 0;
	foreach my $cmd (@{$config->{'cmd-output'}}) {
		$tests++;
		$tests++ if defined $cmd->{'output'};
		$tests++ if defined $cmd->{'exit'};
	}
	
	plan 'tests' => $tests;
	
	foreach my $cmd (@{$config->{'cmd-output'}}) {
		my $output     = `$cmd->{'cmd'}`;
		my $exit_value = $? >> 8;
		
		SKIP: {
			ok(defined $output, 'executing "'.$cmd->{'cmd'}.'"')
				or skip 'no output', 1;
			
			like($output, qr/$cmd->{'output'}/, $cmd->{'desc'})
				if defined $cmd->{'output'};
			
			my $expected_exit_value = $cmd->{'exit'};
			if (defined $expected_exit_value) {
				my $cmp_operator = '==';
				if ($expected_exit_value =~ m{^(!=|==|>|<|>=|<=)\s([0-9]+)$}) {
					$cmp_operator        = $1;
					$expected_exit_value = $2;
				}
				
				cmp_ok($exit_value, $cmp_operator, $expected_exit_value, $cmd->{'desc'});
			}
		}
	}
	
		
	return 0;
}


__END__

=head1 AUTHOR

Jozef Kutej

for the idea thanks to Aldo Calpini.

=cut
