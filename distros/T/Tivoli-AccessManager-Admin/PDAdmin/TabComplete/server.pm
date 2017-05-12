package Tivoli::AccessManager::PDAdmin::TabComplete::server;
$Tivoli::AccessManager::PDAdmin::TabComplete::server::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;
use Data::Dumper;

my %commands;

sub _listServer {
    my $tam = shift;
    my $word = shift;
    my @retval = ();

    my $resp = Tivoli::AccessManager::Admin::Server->list($tam);
    unless ( $resp->isok ) {
	print "Error retrieving server list: ", $resp->messages, "\n";
	return 1;
    }

    for ($resp->value) {
	push @retval, $_ if /^$word/;
    }
    return @retval;
}

sub _listTask {
    my ($tam,$sname,$word) = @_;

    unless ( defined( $commands{$sname} ) ) {
	my $server = Tivoli::AccessManager::Admin::Server->new($tam,name => $sname);
	my $resp = $server->tasklist;
	unless ( $resp->isok ) {
	    print "Error retrieving task list for $sname: ", $resp->messages,"\n";
	    return 1;
	}

	$commands{$sname} = [@{$resp->value->{tasks}}];
    }

    return map { (split)[0] } grep {/^$word/} @{$commands{$sname}};

}

sub complete {
    my ($tam, $tokref, $word, $buffer, $start) = @_;
    my ($command, $subcom,$resp, $tok_cnt);

    $tok_cnt = @{$tokref} + (not $word);
    $command = $tokref->[1];

    return if $command eq 'list';
    if ( $command eq 'task' ) {
	if ( $tok_cnt == 4 ) {
	    return _listTask($tam,$tokref->[2],$word);
	}
    }

    return _listServer($tam,$word) if $tok_cnt == 3;
    return ();

}
1;
