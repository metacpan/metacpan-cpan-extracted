#!/usr/bin/perl

=head1 NAME

running-processes - check running processes

=head2 SYNOPSIS

	cat >> test-server.yaml << __YAML_END__	
	running-processes:
	    should-run:
	        - dhclient3
	        - /usr/sbin/sshd
	        - /usr/sbin/cron
	__YAML_END__	


=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use List::MoreUtils 'any';
use Carp::Clan 'croak';
use FindBin '$Bin';
use YAML::Syck 'LoadFile';

eval "use Proc::ProcessTable";
plan 'skip_all' => "need Proc::ProcessTable to run processes tests" if $@;

my $config = LoadFile($Bin.'/test-server.yaml');
plan 'skip_all' => "no configuration sections for 'running-processes'"
	if (not $config or not $config->{'running-processes'});


exit main();

sub main {
	plan 'tests' => 1;
	
	my $process_table = Proc::ProcessTable->new;
	
	SKIP: {
		skip 'no should-run section, not checking running processes', 1
			if ref $config->{'running-processes'}->{'should-run'} ne 'ARRAY';
		my @should_run = @{$config->{'running-processes'}->{'should-run'}};	
		eq_or_diff(
			[ map { $process_table->is_running($_) ? $_ : undef } @should_run ],
			[ @should_run ],
			'check if all processes are running',
		);
	}
	
	return 0;
}

sub Proc::ProcessTable::is_running {
	my $self           = shift;
	my $process_string = shift;
	
	croak 'pass process name'
		if not defined $process_string;
	
	return any { $_->cmndline =~ $process_string } @{$self->table};
}


__END__

=head1 NOTE

Process listing depends on L<Proc::ProcessTable>.

=head1 AUTHOR

Jozef Kutej

=cut
