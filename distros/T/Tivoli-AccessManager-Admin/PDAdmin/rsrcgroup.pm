package Tivoli::AccessManager::PDAdmin::rsrcgroup;
$Tivoli::AccessManager::PDAdmin::rsrcgroup::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my $key = shift || '';
    my @help = (
	"rsrcgroup create <name> [description] -- creates a new GSO resource group",
	"rsrcgroup delete <name> -- deletes the GSO resource group",
	"rsrcgroup show <name> -- displays the GSO resource group",
	"rsrcgroup list -- lists all GSO resource groups",
	"rsrcgroup modify <group> add <name> -- adds the resource to the group",
	"rsrcgroup modify <group> remove <name> -- removes the resource from the group",
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
    my ($resp,$desc,$grp);

    $name = defined($name) ? $name : '';
    $desc = @desc ? join(" ", @desc) : "";

    unless ( $name ) {
	print "You must provide the resource group name\n";
	help($action);
	return 1;
    }

    $grp = Tivoli::AccessManager::Admin::SSO::Group->new($tam,name=>$name,description=>$desc);
    if ( $action eq 'create' ) {
	if ( $grp->exist ) {
	    print "Resource group \"$name\" already exists\n";
	    return 2;
	}
	else {
	    $resp = $grp->create;
	}
    }
    else {
	if (! $grp->exist ) {
	    print "Resource group \"$name\" doesn't exist\n";
	    return 3;
	}
	else {
	    $resp = $grp->delete();
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

    $resp = Tivoli::AccessManager::Admin::SSO::Group->list($tam);
    if ( $resp->isok ) {
	for ( sort $resp->value ) {
	    print "    $_\n" if /^$name/;
	}
    }
    return $resp->isok;
}

sub show {
    my ($tam, $action, $name) = @_;
    my ($resp, $grp, $desc,@resources);

    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "You must provide the resource group name\n";
	help('show');
	return 1;
    }
    $grp  = Tivoli::AccessManager::Admin::SSO::Group->new( $tam, name => $name );

    # Collect the data I need for the display
    $desc = $grp->description;

    $resp = $grp->resources();
    unless ( $resp->isok ) {
	print "Error retrieving resource information for $name\n";
	return 2;
    }
    @resources = $resp->value;

    print "    Resource Group Name: $name\n";
    print "    Description        : $desc\n";
    print "    Resource Members   :\n";
    print "      $_\n" for (@resources);
    return 0;
}

sub modify {
    my ($tam, $action, $name, $subact, @resources) = @_;
    my ($resp, $grp);

    $name = defined($name) ? $name : '';
    unless ( $name ) {
	print "You must provide the resource group's name\n";
	help('modify');
	return 1;
    }
    $grp  = Tivoli::AccessManager::Admin::SSO::Group->new( $tam, name => $name );

    unless ( $subact eq 'add' or $subact eq 'remove' ) {
	print "Unknown modify action \"$subact\"\n";
	return 2;
    }

    $resp = $grp->resources( $subact => \@resources );
    unless ( $resp->isok ) {
	print "Error modify resource group $name: ", $resp->messages, "\n";
	return 3;
    }
    return 0;
}

1;

