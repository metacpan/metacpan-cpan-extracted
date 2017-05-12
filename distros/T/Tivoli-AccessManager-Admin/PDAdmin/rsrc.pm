package Tivoli::AccessManager::PDAdmin::rsrc;
$Tivoli::AccessManager::PDAdmin::rsrc::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my $key = shift || '';
    my @help = (
	"rsrc create <name> [description] -- creates a new GSO web resource",
	"rsrc delete <name> -- deletes the GSO web resource",
	"rsrc show <name> -- displays the GSO web resource",
	"rsrc list -- lists all GSO web resources",
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
    my ($tam, $action, $name, @desc) = @_;
    my ($resp,$desc,$web);

    $name = defined($name) ? $name : '';
    $desc = @desc ? join(" ", @desc) : "";

    unless ( $name ) {
	print "You must provide the web resource name\n";
	help($action);
	return 1;
    }

    $web = Tivoli::AccessManager::Admin::SSO::Web->new($tam,name=>$name,description=>$desc);
    if ( $action eq 'create' ) {
	if ( $web->exist ) {
	    print "Web resource \"$name\" already exists\n";
	    return 2;
	}
	else {
	    $resp = $web->create;
	}
    }
    else {
	if (! $web->exist ) {
	    print "Web resource \"$name\" doesn't exist\n";
	    return 3;
	}
	else {
	    $resp = $web->delete();
	}
    }

    if ( $resp->isok ) {
	return 0;
    }
    else {
	print "Error executing $action: " . $resp->messages;
	return 4;
    }
}

sub delete { create(@_) }

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

    $resp = Tivoli::AccessManager::Admin::SSO::Web->list($tam);
    if ( $resp->isok ) {
	for ( sort $resp->value ) {
	    print "    $_\n" if /^$name/;
	}
    }
    return $resp->isok;
}

sub show {
    my ($tam, $action, $name) = @_;
    my ($resp, $web, $desc);

    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "You must provide the web resource name\n";
	help('show');
	return 1;
    }
    $web  = Tivoli::AccessManager::Admin::SSO::Web->new( $tam, name => $name );

    # Collect the data I need for the display
    $desc = $web->description;

    print "    Web Resource Name: $name\n";
    print "    Description      : $desc\n";
    return 0;
}

1;

