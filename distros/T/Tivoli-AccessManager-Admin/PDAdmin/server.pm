package Tivoli::AccessManager::PDAdmin::server;
$Tivoli::AccessManager::PDAdmin::server::VERSION = '1.11';

use strict;
use warnings;

use Text::Wrap;
use Data::Dumper;

sub help {
    my $key = shift || '';
    my @help = (
	"server list [<pattern>]  -- Lists all servers.  If the <pattern> is provided, only those servers matching the pattern will be returned.  The <pattern> can use perl's regex, but * and ? will become .* and .? and the pattern will be bound to the beginning (^)",
	"server listtask <server-name> -- Asks the server for all the tasks it can do",
	"server task <server-name> <task> -- Executes the specified task on the server", 
	"server show <server-name> -- NOT IMPLEMENTED BECAUSE IBM WILL NOT EXPOSE THE API TO THE C LIBRARIES",
    );
    if ( $key ) {
	for my $line ( @help ) {
	    print("  ", wrap("", "\t", $line),"\n") if $line =~ /^.+$key.+ --/;
	}
    }
    else {
	for my $line ( @help ) {
	    $line =~ s/--.+$//;
	    print "   $line\n";
	}
    }
}

sub list {
    my ($tam, $action, $name) = @_;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( defined($name) ) {
	$name =~ s/\*/.*/g;
	$name =~ s/\?/.?/g;
    }
    else {
	$name = ".";
    }

    $resp = Tivoli::AccessManager::Admin::Server->list($tam);
    if ( $resp->isok ) {
	for ( sort $resp->value ) {
	    print "    $_\n" if /^$name/;
	}
    }
    return $resp->isok;
}

sub task {
    my ($tam,$action,$name,@task) = @_;
    my ($server,$resp); 

    $server = Tivoli::AccessManager::Admin::Server->new($tam,name => $name);
    $resp   = $server->task(join(" ",@task));

    if ($resp->isok) {
	print "  $_","\n" for ($resp->value);
    }
    else {
	print $resp->messages,"\n";
    }
}

sub listtask {
    my ($tam,$action,$name,$task) = @_;
    my ($server,$resp); 

    $server = Tivoli::AccessManager::Admin::Server->new($tam,name => $name);
    $resp   = $server->tasklist();

    if ($resp->isok) {
	print "  $_","\n" for (sort @{$resp->value->{tasks}});
    }
    else {
	print $resp->messages,"\n";
    }
}

1;

