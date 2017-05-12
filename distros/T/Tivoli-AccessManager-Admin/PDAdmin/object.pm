package Tivoli::AccessManager::PDAdmin::object;
$Tivoli::AccessManager::PDAdmin::object::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my $key = shift || '';
    my @help = (
	"object create <object-name> <description> <type> ispolicyattachable <yes|no> -- Creates an object",
	"object delete <object> -- Deletes an object",
	"object exists <object> -- Does the object exist",
	"object list <object> [<pattern>]  -- List all objects beneath <object>.  If the <pattern> is provided, only those objects matching the pattern will be returned.  The <pattern> can use perl's regex, but * and ? will become .* and .? and the pattern will be bound to the beginning (^)",
	"object list <object> attribute -- Show's all extended attributes on <object>",
	"object listandshow <object> -- Lists all subobjects for <object> and shows them.",
	"object modify <object> delete attribute <attr-name> -- Deletes extended attribute <attr-name>",
	"object modify <object> delete attribute <attr-name> <attr-value> -- Deletes extended attribute value <attr-value>",
	"object modify <object> set attribute <attr-name> <attr-value> -- Sets extended attribute <attr-name> to value <attr-value>",
	"object modify <object> set description <desc> -- Changes the object's description",
	"object modify <object> set ispolicyattachable <yes|no> -- Sets is policy attachable attribute on <object>",
	"object modify <object> set type <type> -- Sets the object's type to <type>",
	"object show <object> -- Display <object>, including attributes",
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
	print "You must provide a name for the object\n";
	help('create');
	return 1;
    }

    my $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam, 
					   name => $name, 
					   type => $type || 0, 
					   description => $desc );
    if ( $pobj->exist ) {
	print "Object $name already exists\n";
	return 2;
    }

    my $resp = $pobj->create();
    print $resp->messages unless $resp->isok;

    return $resp->isok;
}

sub delete {
    my ($tam, $action, $name) = @_;

    unless ( defined($name) ) {
	print "You must provide a name for the object\n";
	help('delete');
	return 1;
    }

    my $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam, name => $name);
    unless ( $pobj->exist ) {
	print "Object $name does not exist\n";
	return 2;
    }

    my $resp = $pobj->delete();
    print $resp->messages unless $resp->isok;

    return $resp->isok;
}

sub list {
    my ($tam, $action, $name, $attr) = @_;
    my ($pobj, $resp);

    unless ( defined($name) ) {
	print "You must provide a name for the object\n";
	help('list');
	return 1;
    }

    $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam, name => $name);
    unless ($pobj->exist) {
	print "Object $name does not exist\n";
	help('list');
	return 2;
    }

    if ( defined($attr) and $attr eq 'attributes' ) {
	$resp = $pobj->attributes;
	unless ( $resp->isok ) {
	    print "Error: " . $resp->messages . "\n";
	    return 3;
	}

	my $href = $resp->value;
	for my $att ( sort keys %{$href} ) {
	    print "  $att: " . join(", ", @{$href->{$att}});
	}
    }
    else {
	$resp = $pobj->list;
	unless ( $resp->isok ) {
	    print "Error: " . $resp->messages . "\n";
	    return 4;
	}
	print "  $_\n" for ( $resp->value );
    }
}

sub listandshow {
    my ($tam, $action, $name) = @_;
    unless ( defined($name) ) {
	print "You must provide a name for the object\n";
	help('listandshow');
	return 1;
    }

    my $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam, name => $name);
    unless ( $pobj->exist ) {
	print "Object $name doesn't exist\n";
	return 2;
    }

    my $resp = $pobj->list;
    unless ( $resp->isok ) {
	print "\n" . $resp->messages . "\n";
	return 3;
    }

    for my $objname ( $resp->value ) {
	show($tam, 'show', $objname);
    }

}

sub _delete {
    my ($pobj, $attr, $valref) = @_;
    my $resp;

    unless ( defined($attr) ) {
	print "What attribute am I deleting?\n";
	help('delete attr');
	return 1;
    }

    if ( defined($valref) and @{$valref} ) {
	$resp = $pobj->attributes( remove => { $attr => $valref } );
    }
    else {
	$resp = $pobj->attributes( removekey => $attr );
    }

    unless ( $resp->isok ) {
	print "\nError removing key/attributes\n";
	return 2;
    }
}

sub modify {
    my ($tam,$action,$name,$subact,$comm,$attr,@val) = @_;
    my ($pobj,$resp);

    unless ( defined($name) ) {
	print "You must provide a name for the object\n";
	help('modify');
	return 1;
    }

    unless ( defined($subact) ) {
	print "How am I modifying $name?\n";
	help('modify');
	return 2;
    }

    $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam,name => $name);
    unless ( $pobj->exist ) {
	print "Object $name doesn't exist\n";
	return 3;
    }

    return _delete($pobj,$attr,\@val) if $subact eq 'delete';

    unless ( $subact eq 'set' ) {
	print "Unrecognized subcommand $subact\n";
	return 4;
    }

    unless ( defined($comm) ) {
	print "What am I setting on $name?\n";
	help('modify');
	return 5;
    }

    if ( $comm eq 'description' ) {
	$resp = $pobj->description( description => $attr || '' );
    }
    elsif ( $comm eq 'ispolicyattachable' ) {
	$resp = $pobj->policy_attachable( attachable => $attr );
    }
    elsif ( $comm eq 'type' ) {
	$resp = $pobj->type( type => $attr );
    }
    elsif ( $comm eq 'attribute' ) {
	$resp = $pobj->attributes( add => { $attr => \@val } );
    }
    else {
	print "Unrecognized set command $comm\n";
	help('modify');
	return 6;
    }

    unless ( $resp->isok ) {
	print "Error modifying $name -- " . $resp->messages . "\n";
	return 7;
    }
    return 0;
}

sub show {
    my ($tam, $action, $name) = @_;
    my ($pobj,$resp,$acl,$pop,$arule);
    unless ( defined($name) ) {
	print "You must provide a name for the object\n";
	help('show');
	return 1;
    }

    my @types = ( 'Unknown', 'Secure domain', 'File',
		  'Executable Program', 'Directory', 'Junction',
		  'WebSEAL server', 'unused', 'unused',
		  'HTTP server', 'Nonexistant object', 'Container object',
		  'Leaf object', 'Port', 'Application container object',
		  'Application leaf object', 'Management object', 'unused' );

    $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam, name => $name);
    unless ( $pobj->exist ) {
	print "Object $name doesn't exist\n";
	return 2;
    }

    print "\n  Name: $name\n";

    $resp = $pobj->description;
    unless ( $resp->isok ) {
	print "Error retrieving description for $name: " . $resp->messages .  "\n";
	return 3;
    }
    print "    Description: " . $resp->value . "\n";

    $resp = $pobj->type;
    unless ( $resp->isok ) {
	print "Error retrieving type for $name: " . $resp->messages .  "\n";
	return 4;
    }
    my $val = $resp->value;
    $val = 17 if $val > 17;
    print "    Type: $val ($types[$val])\n";

    $resp = $pobj->policy_attachable;
    unless ( $resp->isok ) {
	print "Error retrieving policy attachable attribute for $name: " . $resp->messages .  "\n";
	return 4;
    }
    print "    Is Policy Attachable: " . $resp->value . "\n";

    $resp = $pobj->acl;
    unless ( $resp->isok ) {
	print "Error retrieving ACL's attached to $name: " . $resp->messages .  "\n";
	return 5;
    }
    $acl = $resp->value;

    $resp = $pobj->pop;
    unless ( $resp->isok ) {
	print "Error retrieving POP's attached to $name: " . $resp->messages .  "\n";
	return 6;
    }
    $pop = $resp->value;

    $resp = $pobj->authzrule;
    unless ( $resp->isok ) {
	print "Error retrieving AuthzRule's attached to $name: " . $resp->messages .  "\n";
	return 7;
    }
    $arule = $resp->value;

    print "\n    Attached ACL: $acl->{attached}\n";
    print "    Attached POP: $pop->{attached}\n";
    print "    Attached AuthzRule: $arule->{attached}\n";

    print "\n    Effective ACL: $acl->{effective}\n";
    print "    Effective POP: $pop->{effective}\n";
    print "    Effective AuthzRule: $arule->{effective}\n";

    $resp = $pobj->attributes;
    unless ( $resp->isok ) {
	print "Error retrieving attributes attached to $name: " . $resp->messages .  "\n";
	return 8;
    }

    if ( keys %{$resp->value} ) {
	print "\n    Attributes:\n";
	for my $attr ( sort keys %{$resp->value} ) {
	    print "      $attr : " . join(", ", sort @{$resp->value->{$attr}}) . "\n";
	}
    }
}

sub exists {
    my ($tam,$action,$name) = @_;
    my $answer;

    unless ( defined($name) ) {
	print "You must provide a name for the object\n";
	help('list');
	return 1;
    }

    my $pobj = Tivoli::AccessManager::Admin::ProtObject->new($tam, name => $name);

    $answer = $pobj->exist ? "Yes" : "No";
    print "$answer\n";
}

1;
