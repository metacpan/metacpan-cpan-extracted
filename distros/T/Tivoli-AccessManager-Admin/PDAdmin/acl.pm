package Tivoli::AccessManager::PDAdmin::acl;
$Tivoli::AccessManager::PDAdmin::acl::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my $key = shift || '';
    my @help = (
	"acl create <acl-name> -- Creates an ACL",
	"acl delete <acl-name> -- Deletes an ACL",
	"acl find <acl-name>   -- Finds every object to which the ACL is attached",
	"acl list [<pattern>]  -- Lists all ACLs.  If the <pattern> is provided, only those ACLs matching the pattern will be returned.  The <pattern> can use perl's regex, but * and ? will become .* and .? and the pattern will be bound to the beginning (^)",
	"acl modify <acl-name> description <desc> -- Changes the ACL's description",
	"acl modify <acl-name> remove any-other -- Removes any authenticated users' access from the ACL",
	"acl modify <acl-name> remove group <group> -- Removes <group>'s access from the ACL",
	"acl modify <acl-name> remove unauthenticated -- Removes unauthenticated user's access from the ACL",
	"acl modify <acl-name> remove user <user> -- Removes <user>'s access from the ACL",
	"acl modify <acl-name> set any-other <perms> -- Sets any authenticated user's access permissions to <perms>",
	"acl modify <acl-name> set description <desc> -- Changes the ACL's description",
	"acl modify <acl-name> set group <group> <perms> -- Sets <group>'s access permissions to <perms>",
	"acl modify <acl-name> set user <user> <perms> -- Sets <user>'s access permissions to <perms>",
	"acl modify <acl-name> set unauthenticated <perms> -- Sets unauthenticated users' access permissions to <perms>",
	"acl modify <acl-name> set attribute <attr> <value> -- Sets the value of <attr> to <value> on the ACL",
	"acl modify <acl-name> delete attribute <attr> <value> -- Deletes the <value> from the attribute <attr> on the ACL",
	"acl modify <acl-name> set attribute <attr> -- Deletes the attribute <attr> from the ACL",
	"acl show <acl-name> -- Display <acl-name>, including attributes",
	"acl attach <object-name> <acl-name> -- Attaches <acl-name> to <object-name>",
	"acl detach <object-name> <acl-name> -- Detaches <acl-name> from <object-name>",
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
    my ($tam, $action, $name) = @_;
    my $resp;

    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "You must provide the ACL name\n";
	help($action);
	return 1;
    }

    my $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );
    if ( $action eq 'create' ) {
	if ( $acl->exist ) {
	    print "ACL \"$name\" already exists\n";
	    return 2;
	}
	else {
	    $resp = $acl->create( name => $name );
	}
    }
    else {
	if (! $acl->exist ) {
	    print "ACL \"$name\" doesn't exist\n";
	    return 3;
	}
	else {
	    $resp = $acl->delete();
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

sub find {
    my $tam  = shift;
    my $comm = shift;
    my $name = shift || '';

    unless ( $name ) {
	print "You must provide the ACL name\n";
	help('find');
	return 1;
    }

    my $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );

    my $resp = $acl->find;
    unless ( $resp->isok ) {
	print "Error searching for $name: " . $resp->messages . "\n";
	return 2;
    }

    print "$_\n" for ($resp->value);

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

    $resp = Tivoli::AccessManager::Admin::ACL->list($tam);
    if ( $resp->isok ) {
	for ( sort $resp->value ) {
	    print "    $_\n" if /^$name/;
	}
    }
    return $resp->isok;
}

sub _get_info {
    my ($acl, $request) = @_;
    my ($resp, @stuff);

    if ( $request eq 'group' ) {
	$resp = $acl->listgroups;
    }
    elsif ( $request eq 'user' ) {
	$resp = $acl->listusers;
    }

    unless ( $resp->isok ) {
	print "Error getting the $request for \"" . $acl->name . "\"\n";
	return 1;
    }
    for my $unit ( $resp->value ) {
	if ( $request eq 'group' ) {
	    $resp = $acl->group( group => $unit );
	}
	elsif ( $request eq 'user' ) {
	    $resp = $acl->user( user => $unit );
	}

	unless ( $resp->isok ) {
	    print "Error getting the permissions for \"$unit\"\n";
	    next;
	}
	if ( $resp->value ) {
	    push @stuff, $request . " $unit : " . $resp->value;
	}
    }
    return sort @stuff;
}

sub show {
    my ($tam, $action, $name) = @_;
    my ($resp, $acl, $desc, @groups, @users);
    my ($anyother, $unauth) = ('', '');
    my %attrs = ();
    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "You must provide the ACL name\n";
	help('show');
	return 1;
    }
    $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );

    # Collect the data I need for the display
    $resp = $acl->description;
    unless ( $resp->isok ) {
	print "Error getting the description for \"$name\"\n";
	return 2;
    }
    $desc = $resp->value;

    @groups = _get_info($acl,'group');
    @users = _get_info($acl,'user');

    $resp = $acl->anyother;
    unless ( $resp->isok ) {
	print "Error getting the any other users permissions for \"$name\"\n";
	return 3;
    }
    $anyother = "Any-Other : " . $resp->value if $resp->value;

    $resp = $acl->unauth;
    unless ( $resp->isok ) {
	print "Error getting the unauthenticated users permissions for \"$name\"\n";
	return 4;
    }
    $unauth = "Unauth : " . $resp->value if $resp->value;

    $resp = $acl->attributes;
    unless ( $resp->isok ) {
	print "Error retrieving attributes for \"$name\"\n";
	return 5;
    }
    my $href = $resp->value;
    for my $key ( keys %{$href} ) {
	$attrs{$key} = join(", ", @{$href->{$key}});
    }

    print "    ACL Name: $name\n";
    print "    Description: $desc\n";
    print "    Entries:\n";
    print "\t$_\n" for @groups;
    print "\t$_\n" for @users;
    print "\t$anyother\n" if $anyother;
    print "\t$unauth\n" if $unauth;
    if ( keys %attrs ) {
	print "    Attributes:\n";
	print "\t$_ : $attrs{$_}\n" for ( keys %attrs );
    }
    return 0;
}

sub _description {
    my ($tam, $action, $name, $comm, $target, $tname, $tvalue) = @_;
    my $resp;
    my $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );

    if ( $comm eq 'description' ) {
	$resp = $acl->description($target);
	unless ( $resp->isok ) {
	    print "Couldn't set description: " . $resp->messages;
	    return 1;
	}
	return 0;
    }
}

sub _remove {
    my ($tam, $action, $name, $comm, $target, $tname, $tvalue) = @_;
    my $resp;
    my $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );

    if ( $target eq 'group' or $target eq 'user' ) {
	unless ( defined($tname) ) {
	    print "You must provide the $target name\n";
	    help('modify');
	    return 1;
	}
	if ( $target eq 'user' ) {
	    $resp = Tivoli::AccessManager::Admin::User->list( $tam, pattern => $tname );
	    unless ( $resp->isok and $resp->value ) {
		print "Unknown user: $tname\n";
		return 2;
	    }
	    $resp = $acl->user( user => $tname, perms => 'remove' );
	}
	else {
	    $resp = Tivoli::AccessManager::Admin::Group->list( $tam, pattern => $tname );
	    unless ( $resp->isok and $resp->value ) {
		print "Unknown group: $tname\n";
		return 3;
	    }
	    $resp = $acl->group( group => $tname, perms => 'remove' );
	}
    }
    elsif ( $target eq 'any-other' ) {
	$resp = $acl->anyother( perms => 'remove' );
    }
    elsif ( $target eq 'unauthenticated' ) {
	$resp = $acl->unauth( perms => 'remove' );
    }

    unless ( $resp->isok ) {
	print "Couldn't remove $target access for $name: " .  $resp->messages . "\n";
	return 1;
    }
    return 0;
}

sub _set {
    my ($tam, $action, $name, $comm, $target, $tname, $tvalue) = @_;
    my $resp;
    my $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );

    $tname  = defined($tname)  ? $tname : "";
    $tvalue = defined($tvalue) ? $tvalue : "";

    if ( $target eq 'any-other' ) {
	$resp = $acl->anyother( perms => $tname );
    }
    elsif ( $target eq 'description' ) {
	$resp = $acl->description(description => $tname);
    }
    elsif ( $target eq 'group' ) {
	unless ( defined($tname) ) {
	    print "You must provide the $target name\n";
	    help('modify');
	    return 1;
	}
	$resp = Tivoli::AccessManager::Admin::Group->list( $tam, pattern => $tname );
	unless ( $resp->isok and $resp->value ) {
	    print "Unknown group: $tname\n";
	    return 2;
	}
	$resp = $acl->group( group => $tname, perms => $tvalue );
    }
    elsif ( $target eq 'unauthenticated' ) {
	$resp = $acl->unauth( perms => $tname );
    }
    elsif ( $target eq 'user' ) {
	unless ( $tname ) {
	    print "Usage: acl modify $name set user <user> <perms>\n";
	    return 3;
	}
	$resp = Tivoli::AccessManager::Admin::User->list( $tam, pattern => $tname );
	unless ( $resp->isok and $resp->value ) {
	    print "Unknown user: $tname\n";
	    return 4;
	}
	$resp = $acl->user( user => $tname, perms => $tvalue );
    }
    elsif ( $target eq 'attribute' ) {
	$resp = $acl->attributes( add => { $tname => $tvalue } );
    }
    unless ( $resp->isok ) {
	print "Error setting $tname: " . $resp->messages;
	return 5;
    }
}

sub _delete {
    my ($tam, $action, $name, $comm, $target, $tname, $tvalue) = @_;
    my $resp;
    my $acl  = Tivoli::AccessManager::Admin::ACL->new( $tam, name => $name );

    if ( defined( $tvalue ) ) {
	$resp = $acl->attributes( remove => { $tname => $tvalue } );
    }
    else {
	$resp = $acl->attributes( removekey => [ $tname ] );
    }
    unless ( $resp->isok ) {
	print "Error removing attribute $tname: ", $resp->messages, "\n";
	return 1;
    }
    else {
	return 0;
    }
}

sub modify {
    my ($tam, $action, $name, $comm, $target, $tname, $tvalue) = @_;
    my $resp;
    $name = defined($name) ? $name : '';
    my %mod_dispatch = (
	description => \&_description,
	remove      => \&_remove,
	set         => \&_set,
	'delete'    => \&_delete,
    );

    unless ( $name ) {
	print "You must provide the ACL name\n";
	help('modify');
	return 1;
    }

    if ( defined( $mod_dispatch{$comm} ) ) {
	return $mod_dispatch{$comm}->(@_);
    }
    else {
	print "Unknown ACL action: $comm\n";
	return 1;
    }
}

sub attach {
    my ($tam, $action, $object, $name) = @_;
    my $resp;

    unless ( defined($object) and defined($name) ) {
	print "You must provide the ACL name and the object\n";
	help('attach');
	return 1;
    }
    my $obj = Tivoli::AccessManager::Admin::ProtObject->new( $tam, name => $object );
    $resp = $obj->acl( attach => $name );
    unless ( $resp->isok ) {
	print "Couldn't attach $name to $object: " . $resp->messages . "\n";
	return 1;
    }
    return 0;
}

sub detach {
    my ($tam, $action, $object) = @_;
    my $resp;

    unless ( defined($object) ) {
	print "You must provide the object's name\n";
	help('detach');
	return 1;
    }

    my $obj = Tivoli::AccessManager::Admin::ProtObject->new( $tam, name => $object );
    $resp = $obj->acl( detach => 1 );
    unless ( $resp->isok ) {
	print "Couldn't detach ACL from $object: " . $resp->messages . "\n";
	return 1;
    }
    return 0;
}

1;

