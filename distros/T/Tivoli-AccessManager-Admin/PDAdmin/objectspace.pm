package Tivoli::AccessManager::PDAdmin::objectspace;
$Tivoli::AccessManager::PDAdmin::objectspace::VERSION = '1.11';

use strict;
use warnings;

sub help {
    my $key = shift || '';
    my @help = (
	"objectspace create <object> -- Creates a new objectspace",
	"objectspace delete <object> -- Deletes an objectspace",
	"objectspace list -- Lists all objectspaces",
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

sub create {
    my ($tam, $action, $name, $desc, $type) = @_;

    unless ( defined($name) ) {
	print "You must provide a name for the objectspace\n";
	help('space create');
	return 1;
    }

    my $ospace = Tivoli::AccessManager::Admin::Objectspace->new($tam, 
					      name => $name, 
					      type => $type || 0, 
					      description => $desc );
    my $resp = $ospace->create;
    unless ( $resp->isok ) {
	print "Error creating objectspace: " . $resp->messages . "\n";
	return 3;
    }

    return $resp->isok;
}

sub delete {
    my ($tam, $action, $name) = @_;

    unless ( defined($name) ) {
	print "You must provide a name for the objectspace\n";
	help('space delete');
	return 1;
    }

    my $ospace = Tivoli::AccessManager::Admin::Objectspace->new($tam, name => $name);
    my $resp = $ospace->delete();
    unless ( $resp->isok ) {
	print "Error deleting objectspace: " . $resp->messages . "\n";
	return 3;
    }

    return $resp->isok;
}

sub list {
    my ($tam) = @_;

    my $resp = Tivoli::AccessManager::Admin::Objectspace->list($tam);
    unless ( $resp->isok ) {
	print "Error listing objectspaces: " . $resp->messages . "\n";
	return 1;
    }
    for ( $resp->value ) {
	print "  $_\n" 
    }
}

1;
