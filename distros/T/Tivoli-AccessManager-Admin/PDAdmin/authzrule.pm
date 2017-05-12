package Tivoli::AccessManager::PDAdmin::authzrule;
$Tivoli::AccessManager::PDAdmin::authzrule::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my @help = (
	"authzrule attach <object-name> <authzrule-name> -- Attaches <authzrule-name> to <object-name>",
	"authzrule detach <object-name> -- Detaches an authorization rule from <object-name>",
	"authzrule detach -all <authzrule-name> -- Detaches <authzrule-name> from every object",
	"authzrule create <authzrule-name> <-rulefile <filename> | ruletext> [-desc description] [-failreason <failreason>] -- Creates an authorization rule",
	"authzrule show <authzrule-name> -- Display <authzrule-name>, including attributes",
	"authzrule delete <authzrule-name> -- Deletes an authorization rule",
	"authzrule modify <authzrule-name> description <desc> -- Changes the authorization rule's description",
	"authzrule modify <authzrule-name> ruletext <-rulefile <filename> | ruletext> -- Sets unauthenticated users' access permissions to <perms>",
	"authzrule modify <authzrule-name> failreason <failreason> -- Sets the value of <attr> to <value> on the ACL",
	"authzrule list [<pattern>]  -- Lists all authorization rule.  If the <pattern> is provided, only those authorization rule matching the pattern will be returned.  The <pattern> can use perl's regex, but * and ? will become .* and .? and the pattern will be bound to the beginning (^)",
	"authzrule find <authzrule-name>   -- Finds every object to which the authorization rule is attached",
    );
    my $key = shift || '';
    print "$key\n";
    if ( $key ) {
	for my $line ( @help ) {
	    print(wrap("", "\t", $line),"\n") if $line =~ /^.+$key.+ --/;
	}
    }
    else {
	for my $line ( @help ) {
	    $line =~ s/--.+$//;
	    print "$line\n";
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

    $resp = Tivoli::AccessManager::Admin::AuthzRule->list($tam);
    if ( $resp->isok ) {
	for ( sort $resp->value ) {
	    print "    $_\n" if /^$name/;
	}
    }
    return $resp->isok;
}

sub create {
    my ($tam, $action, $name) = @_;
    # I just don't like 3 shifts in a row :)
    my @args = splice(@_,3);
    my %opts;

    my $resp;
    my $usage = "Usage: authzrule create <name> <-rulefile <filename> | ruletext> [-desc description] [-failreason reason]\n";

    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "No name provided\n$usage";
	return 1;
    }

    unless ( @args ) {
	print "Insufficient arguments\n$usage";
	return 1;
    }

    while ( @args ) {
	my $option = shift @args;
	if ( $option eq '-rulefile' ) {
	    $opts{file} = shift @args;
	}
	elsif ( $option =~ s/^-// ) {
	    $option =~ s/desc$/description/;
	    $opts{$option} = shift @args;
	}
	else {
	    if ( not defined( $opts{rule} ) ) {
		$opts{rule} = $option;
	    }
	    else {
		print "Invalid option ($option)\n$usage";
		return 2;
	    }
	}
    }

    my $arule  = Tivoli::AccessManager::Admin::AuthzRule->new( $tam, name => $name );
    if ( $arule->exist ) {
	print "AuthzRule \"$name\" already exists\n";
	return 3;
    }

    $resp = $arule->create( %opts );

    if ( $resp->isok ) {
	return 0;
    }
    else {
	print "Error executing $action: " . $resp->messages;
	return 1;
    }
}

sub delete {
    my ($tam, $action, @names) = @_;
    my ($error,$resp, @dne, @errors);

    unless ( @names ) {
	print "Usage: authzrule delete <name>";
	return 1;
    }

    $error = '';
    for my $name ( @names ) {
	my $arule  = Tivoli::AccessManager::Admin::AuthzRule->new( $tam, name => $name );
	if (! $arule->exist ) {
	    push @dne, $name;
	}
	else {
	    $resp = $arule->delete();
	    push(@errors, $resp->messages) unless $resp->isok;
	}
    }

    if ( @dne ) {
	my $plural = @dne > 1 ? "rules" : "rule";

	print "The following $plural did not exist: " . join(", ", @dne) . "\n";
    }

    if ( @errors ) {
	print "The following errors occured: ", join("\n", @errors);
	return 1;
    }

    return 0;
}

sub show {
    my ($tam, $action, $name) = @_;
    my ($resp, $arule, $desc, $text, $freason);
    
    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "Usage: authzrule show <name>\n";
	return 1;
    }
    $arule  = Tivoli::AccessManager::Admin::AuthzRule->new( $tam, name => $name );

    # Collect the data I need for the display
    $resp = $arule->description;
    unless ( $resp->isok ) {
	print "Error getting the description for \"$name\"\n";
	return 1;
    }
    $desc = $resp->value;

    $resp = $arule->ruletext;
    unless( $resp->isok ) {
	print "Error getting the ruletext for \"$name\"\n";
	return 1;
    }
    $text = $resp->value;

    $resp = $arule->failreason;
    unless( $resp->isok ) {
	print "Error getting the failreason for \"$name\"\n";
	return 1;
    }
    $freason = $resp->value;
    print "    Authorization Rule Name: $name\n";
    print "    Description            : $desc\n";
    print "    Fail Reason            : $freason\n";
    print "    Rule Text              :\n";
    print " ==== Cut Here ====\n";
    print "$text\n";
    print " ==== Cut Here ====\n";

    return 0;

}

sub find {
    my $tam  = shift;
    my $comm = shift;
    my $name = shift || '';

    unless ( $name ) {
	print "Usage: authzrule find <name>\n";
	return 1;
    }
    my $arule  = Tivoli::AccessManager::Admin::AuthzRule->new( $tam, name => $name );

    my $resp = $arule->find;
    unless ( $resp->isok ) {
	print "Error searching for $name: " . $resp->messages . "\n";
	return 1;
    }

    print "$_\n" for ($resp->value);

}

sub attach {
    my ($tam, $action, $object, $name) = @_;
    my $resp;

    unless ( defined($object) and defined($name) ) {
	print "Usage: authzrule attach <object> <authzrule>\n";
	return 1;
    }

    my $arule = Tivoli::AccessManager::Admin::AuthzRule->new( $tam, name => $name );
    $resp = $arule->attach($object);
    unless ( $resp->isok ) {
	print "Couldn't attach $name to $object: " . $resp->messages . "\n";
	return 1;
    }
    return 0;
}

sub detach {
    my ($tam, $action, $object, $name) = @_;
    my ($resp,@points,$arule,@errs);

    unless ( defined($object) and defined($name) ) {
	print "Usage: acl detach <-all | <object> <acl>>\n";
	return 1;
    }

    $arule = Tivoli::AccessManager::Admin::AuthzRule->new( $tam, name => $name );

    if ( $object eq '-all' ) {
	$resp = $arule->find;
	unless ( $resp->isok ) {
	    print "Error finding \"$name\": " . $resp->messages;
	    return 1;
	}
	@points = $resp->value;
    }
    else {
	push @points, $object;
    }

    for my $obj ( @points ) {
	$resp = $arule->detach( $obj );
	push @errs, $resp->messages unless $resp->isok;
    }
    
    if ( @errs ) {
	my $plural = @errs > 1 ? "errors" : "error";
	print "The following $plural occurred: " . join("\n", @errs);
	return 1;
    }
    return 0;
}

sub _description {
    my ($arule, $desc) = @_;
    my $resp;

    my $name = $arule->name;

    unless( defined($desc) ) {
	print "Usage: authzrule modify description <description>\n";
	return 1;
    }

    $resp = $arule->description( description => $desc );
    unless ( $resp->isok ) {
	print "Error changing description for $name: " . $resp->messages;
	return 3;
    }
    return 0;
}

sub _ruletext {
    my ($arule, $text, $fname) = @_;
    my $resp;
    my $name = $arule->name;

    if ( $text eq '-rulefile' ) {
	unless ( defined( $fname ) ) {
	    print "Usage: authzrule modify ruletext -rulefile <filename>\n";
	    return 1;
	}
	$resp = $arule->ruletext( file => $fname );
    }
    else {
	$resp = $arule->ruletext( rule => $text );
    }

    unless ( $resp->isok ) {
	print "Error changing the ruletext for $name: " . $resp->messages;
	return 2;
    }
    return 0;
}

sub _failreason {
    my ($arule, $freason) = @_;
    my $resp;
    my $name = $arule->name;

    unless( defined($freason) ) {
	print "Usage: authzrule modify failreason <reason>\n";
	return 1;
    }
    $resp = $arule->failreason( reason => $freason );
    unless ( $resp->isok ) {
	print "Error changing description for $name: " . $resp->messages;
	return 3;
    }
    return 0;
}

sub modify {
    my ($tam, $action, $name, $subcomm, @params) = @_;
    my $arule;
    my %dispatch = ( description => { help => '<desc>',
				      call => \&_description,
				  },
		  ruletext    => { help => '<-rulefile <filename> | ruletext>',
				   call => \&_ruletext,
			       },
		  failreason  => { help => '<failreason>',
				   call => \&_failreason
			       }
	      );

    unless ( defined($subcomm) ) {
	print "Usage:\n";
	for (keys %dispatch) {
	    print "  authzrule modify <name> $_ $dispatch{$_}{help}\n";
	}
	return 1;
    }
    unless ( defined($dispatch{$subcomm}) ) {
	print "Unrecognized command: $subcomm\nUsage:\n";
	for (keys %dispatch) {
	    print "  authzrule modify <name> $_ $dispatch{$_}{help}\n";
	}
	return 1;
    }

    unless ( $name ) {
	print "Usage: authzrule modify <name> $subcomm $dispatch{$subcomm}{help}\n";
	return 1;
    }

    $arule = Tivoli::AccessManager::Admin::AuthzRule->new($tam, name => $name);
    unless ( $arule->exist ) {
	print "AuthzRule $name doesn't exist\n";
	return 2;
    }


    return $dispatch{$subcomm}{call}->($arule, @params);
}

1;
