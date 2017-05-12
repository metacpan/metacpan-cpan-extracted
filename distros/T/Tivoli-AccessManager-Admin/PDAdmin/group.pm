package Tivoli::AccessManager::PDAdmin::group;
$Tivoli::AccessManager::PDAdmin::group::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my $key = shift || '';
    my @help = (
	"group create <group-name> <dn> [<cn>] [<groupcontainer>] -- Creates a new group, optionally in the named group container.  If the <cn> is not provided, create will use the group-name.  Alas, if you want to name a group container, you must name the cn.",
	"group delete <group-name> [-r] -- Deletes group, optionally deleting everything from the LDAP as well",
	"group import <group-name> <dn> [<groupcontainer>] -- Imports an existing group, optionally into the named group container",
	"group list [<pattern> <max-return>] -- Lists all TAM groups, optionally those that match pattern up to max-return.  By default, the pattern is * and the max-return is 0",
	"group list_dn [<pattern> <max-return>] -- Lists all groups in the LDAP, optionally those that match pattern up to max-return.  By default, the pattern is * and the max-return is 0",
	"group modify <group-name> add [-f] <userlist> -- Adds the named users to the group.  If adding multiple users, <userlist> should be space seperated.  If the -f option is provided, only those listed users that are not in the group already will be added",
	"group modify <group-name> description <desc> -- Changes the group's description",
	"group modify <group-name> remove [-f] <userlist> -- Removes the listed users from the group.  <userlist> should be space seperated.  The -f option will only remove those users that are in group already",
	"group show <group-name> -- Display the named TAM group, including attributes",
	"group show_dn <dn> -- Displays the group, regardless of its TAMification",
	"group show_members <groupname> [pattern]-- Displays the members of the named TAM group.  If the pattern is provided, only those members matching the pattern will be displayed.  This can be a full blown perl regex, but * and ? will become .* and .?",
	
    );
    if ( $key ) {
	for my $line ( @help ) {
	    print("  ", wrap("", "\t", $line),"\n") if $line =~ /^.+$key.+ --/;
	}
    }
    else {
	for my $line ( @help ) {
	    $line =~ s/--.+$//;
	    print "  $line\n";
	}
    }
}

sub create {
    my ($tam, $action, $name, $dn, $cn, $container) = @_;
    my ($group,$resp,$finddn);

    unless ( defined( $name ) ) {
	print "You must provide the group name\n";
	help('create');
	return 1;
    }

    unless ( defined( $dn ) ) {
	print "You must provide the group's DN\n";
	help('create');
	return 2;
    }

    unless ( $dn =~ /=/ ) {
	print "I am not certain $dn is a real DN, but I will try anyway\n";
    }

    ($finddn = $dn) =~ s/,.*$/*/;
    $finddn =~ s/^.+?=//;

    $resp = Tivoli::AccessManager::Admin::Group->list($tam, pattern => $finddn, bydn => 1);
    if ( $resp->isok ) {
	for my $gdn ( $resp->value ) {
	    if ( $gdn eq $dn ) {
		print "Error creating group $name: the supplied DN ($dn) seems to already exist\n";
		return 3;
	    }
	}
    }

    $group = Tivoli::AccessManager::Admin::Group->new( $tam, name => $name );
    if ( $group->exist ) {
	print "Group $name already exists\n";
	return 4;
    }

    $resp = $group->create(dn => $dn, cn => $cn || '', container => $container || '');
    unless ( $resp->isok ) {
	print "Error creating group $name: " . $resp->messages . "\n";
	return 5;
    }

    return 0;
}

sub delete {
    my ($tam, $action, $name, $opt) = @_;
    my ($group,$resp);

    unless ( defined( $name ) ) {
	print "You must provide the group name\n";
	help('delete');
	return 1;
    }

    if ( defined($opt) and $opt ne '-r' ) {
	print "Unrecognized option $opt\n";
	help('delete');
	return 2;
    }

    $group = Tivoli::AccessManager::Admin::Group->new($tam, name => $name);
    unless ( $group->exist ) {
	print "Group $name doesn't exist\n";
	return 3;
    }
    $resp  = $group->delete( registry => defined($opt) );
    unless ( $resp->isok ) {
	print "Error trying to delete group $name: " . $resp->messages . "\n";
	return 4;
    }
    return 0;
}

sub iport {
    my ($tam, $action, $name, $dn, $container) = @_;
    my ($group,$resp,$finddn,$found);

    unless ( defined( $name ) ) {
	print "You must provide the group name\n";
	help('import');
	return 1;
    }

    unless ( defined( $dn ) ) {
	print "You must provide the group's DN\n";
	help('import');
	return 2;
    }

    unless ( $dn =~ /=/ ) {
	print "I am not certain $dn is a real DN, but I will try anyway\n";
    }

    $group = Tivoli::AccessManager::Admin::Group->new( $tam, name => $name );
    if ( $group->exist ) {
	print "Group $name apparently exists already\n";
	return 3;
    }

    ($finddn = $dn) =~ s/,.*$/*/;
    $finddn =~ s/^.+?=//;

    $found = 0;
    $resp = Tivoli::AccessManager::Admin::Group->list($tam, pattern => $finddn, bydn => 1);
    if ($resp->isok) {
	for my $gdn ( $resp->value ) {
	    if ($gdn eq $dn) {
		$found = 1;
		last;
	    }
	}
    }
    unless ( $found ) {
	print "Error importing group $name: the supplied DN ($dn) doesn't seem to exist\n";
	return 4;
    }

    $resp = $group->groupimport( dn => $dn, container => $container || '' );
    unless ( $resp->isok ) {
	print "Error importing group $name: " . $resp->messages . "\n";
	return 5;
    }

    return 0;
}

sub list {
    my ($tam, $action, $pattern, $maxreturn, $bydn) = @_;
    my ($resp);

    $pattern     = defined($pattern) ? $pattern : '*';
    $maxreturn ||= 0;
    $bydn      ||= 0;

    $resp = Tivoli::AccessManager::Admin::Group->list($tam, pattern => $pattern, maxreturn => $maxreturn, bydn => $bydn);
    unless ( $resp->isok ) {
	print "Error searching for groups: " . $resp->messages . "\n";
	return 1;
    }

    unless ( $resp->value ) {
	print "No groups found matching $pattern\n";
	return 0;
    }

    print "  $_\n" for ( $resp->value );
    return 0;
}

sub list_dn {
    my ($tam, $action, $pattern, $maxreturn) = @_;

    $pattern     = defined($pattern) ? $pattern : '*';
    $maxreturn ||= 0;
    list($tam, $action, $pattern, $maxreturn, 1);

}

sub show {
    my ($tam, $action, $name, $bydn) = @_;
    my ($resp, $cn, $dn, $desc, $grp);
    my $TAMified = "Yes";

    unless ( defined($name)) {
	print "You must provide the group name\n";
	help('show');
	return 1;
    }

   
    if ( $bydn ) {
	$grp = Tivoli::AccessManager::Admin::Group->new( $tam, dn => $name );
    }
    else {
	$grp = Tivoli::AccessManager::Admin::Group->new( $tam, name => $name );
    }

    $resp = $grp->cn;
    unless ( $resp->isok ) {
	print "Cannot find TAM group \"$name\"\n";
	return 2;
    }

    $TAMified = "No" unless $grp->exist;

    $resp = $grp->dn;
    $dn   = $resp->isok ? $resp->value : '';
    $resp = $grp->cn;
    $cn   = $resp->isok ? $resp->value : '';
    $resp = $grp->description;
    $desc = $resp->isok ? $resp->value : '';

    print "  Group ID: " . $grp->name . "\n";
    print "  Descript: $desc\n";
    print "  LDAP  DN: $dn\n";
    print "  LDAP  CN: $cn\n";
    print "  TAMified: $TAMified\n";
    return 0;
}

sub show_dn {
    show(@_, 1);
}

sub show_members {
    my ($tam, $action, $name, $pattern) = @_;
    my ($resp,@members);

    unless ( defined($name)) {
	print "You must provide the group name\n";
	help('show-members');
	return 1;
    }

    my $grp = Tivoli::AccessManager::Admin::Group->new( $tam, name => $name );
    unless ( $grp->exist ) {
	print "Cannot find TAM group \"$name\"\n";
	return 2;
    }

    $resp = $grp->members;
    unless ( $resp->isok ) {
	print "Error listing members of \"$name\": " . $resp->messages . "\n";
	return 3;
    }

    for my $peep ( $resp->value ) {
	print "$peep\n";
    }
}

sub modify {
    my ($tam, $action, $name, $subact, @list) = @_;
    my $force = 0;
    my $resp;

    unless ( defined($name) ) {
	print "You must provide the group name\n";
	help('modify');
	return 1;
    }

    unless ( defined( $subact ) ) {
	print "You need to specify how we are modifying group \"$name\"\n";
	help('modify');
	return 2;
    }

    unless ( $subact eq 'add' or $subact eq 'remove' or $subact eq 'description' ) {
	print "Invalid subaction \"$subact\" -- it must be one of add, remove or description\n";
	help('modify');
	return 3;
    }

    my $grp = Tivoli::AccessManager::Admin::Group->new($tam,name => $name);
    unless ( $grp->exist ) {
	print "Group \"$name\" does not exist\n";
	return 4;
    }

    if ( $subact eq 'description' ) {
	$resp = $grp->description( description => $list[0] );
	unless ( $resp->isok ) {
	    print "Error changing the description for \"$name\": " . $resp->messages . "\n";
	    return 5;
	}
    }
    else {
	if ( @list == 0 or ( @list == 1 and $list[0] eq '-f' ) ) {
	    print "Invalid user list\n";
	    help('modify');
	    return 6;
	}

	if ( $list[0] eq '-f' ) {
	    shift @list;
	    $force = 1;
	}

	$resp = $grp->members( $subact => \@list, force => $force );
	unless ( $resp->isok ) {
	    print "Error changing the membership for \"$name\": " . $resp->messages . "\n";
	    return 7;
	}

	if ( $resp->iswarning ) {
	    print "Warning while changing membership for \"$name\" : " .  $resp->messages . "\n";
	}
    }
}
1;
