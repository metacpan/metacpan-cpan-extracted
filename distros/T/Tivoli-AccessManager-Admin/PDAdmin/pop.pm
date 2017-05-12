package Tivoli::AccessManager::PDAdmin::pop;
$Tivoli::AccessManager::PDAdmin::pop::VERSION = '1.11';

use strict;
use warnings;

use Text::Wrap;
use Data::Dumper;

sub help {
    my $key = shift || '';
    my @help = (
	"pop attach <object-name> <pop-name> -- Attaches <pop-name> to <object-name>",
	"pop create <pop-name> -- Creates an POP",
	"pop delete <pop-name> -- Deletes an POP",
	"pop detach <object-name> <pop-name> -- Detaches <pop-name> from <object-name>",
	"pop find <pop-name>   -- Finds every object to which the POP is attached",
	"pop list [<pattern>]  -- Lists all POPs.  If the <pattern> is provided, only those POPs matching the pattern will be returned.  The <pattern> can use perl's regex, but * and ? will become .* and .? and the pattern will be bound to the beginning (^)",
	"pop modify <pop-name> set audit-level {all|none|<audit-level-list>} -- set the audit level on the POP",
	"pop modify <pop-name> set description <desc> -- Changes the POP's description",
	"pop modify <pop-name> set ipauth add <network> <netmask> <auth level> -- set the authentication level for the specificed network",
	"pop modify <pop-name> set ipauth forbidden <network> <netmask> -- forbid access from the given network",
	"pop modify <pop-name> set ipauth anyothernw {<auth level>|forbidden} -- set the authentication level for any other network",
	"pop modify <pop-name> set ipauth remove <network> <netmask> -- remove an IP authentication rule",
	"pop modify <pop-name> set qop {none|integrity|privacy} -- Set the quality of protection POP",
	"pop modify <pop-name> set tod-access <{anyday|weekday|<day-list>}>:<anytime|<start time>-<stop time>>:[:utc|local] -- define the time of day access for the POP",
	"pop modify <pop-name> set warning <yes|no> -- enable or disable warnings",
	"pop modify <pop-name> set attribute <attr> <value> -- Sets the value of <attr> to <value> on the POP",
	"pop modify <pop-name> delete attribute <attr> -- Deletes the attribute <attr> from the POP",
	"pop modify <pop-name> delete attribute <attr> <value> -- Deletes the <value> from the attribute <attr> on the POP",
	"pop show <pop-name> -- Display <pop-name>, including attributes",
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
	print "You must provide the POP name\n";
	help($action);
	return 1;
    }

    my $pop  = Tivoli::AccessManager::Admin::POP->new( $tam, name => $name );
    if ( $action eq 'create' ) {
	if ( $pop->exist ) {
	    print "POP \"$name\" already exists\n";
	    return 2;
	}
	else {
	    $resp = $pop->create( name => $name );
	}
    }
    else {
	if (! $pop->exist ) {
	    print "POP \"$name\" doesn't exist\n";
	    return 3;
	}
	else {
	    $resp = $pop->delete();
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
	print "You must provide the POP name\n";
	help('find');
	return 1;
    }

    my $pop  = Tivoli::AccessManager::Admin::POP->new( $tam, name => $name );

    my $resp = $pop->find;
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

    $resp = Tivoli::AccessManager::Admin::POP->list($tam);
    if ( $resp->isok ) {
	for ( sort $resp->value ) {
	    print "    $_\n" if /^$name/;
	}
    }
    return $resp->isok;
}

sub show {
    my ($tam, $action, $name) = @_;
    my ($resp, $pop, $desc, $warning, $audlevel, $qop);
    my ($anyother,%tod, %ipauth,%attrs);
    $name = defined($name) ? $name : '';

    unless ( $name ) {
	print "You must provide the POP name\n";
	help('show');
	return 1;
    }
    $pop  = Tivoli::AccessManager::Admin::POP->new( $tam, name => $name );

    # Collect the data I need for the display
    $resp = $pop->description;
    unless ( $resp->isok ) {
	print "Error getting the description for \"$name\"\n";
	return 2;
    }
    $desc = $resp->value;

    $resp = $pop->warnmode;
    unless ( $resp->isok ) {
	print "Error getting the warn mode for \"$name\"\n";
	return 3;
    }
    $warning = $resp->value;

    $resp = $pop->audit;
    unless ( $resp->isok ) {
	print "error getting the audit level for \"$name\"\n";
	return 4;
    }
    $audlevel = $resp->value;

    $resp = $pop->qop;
    unless ( $resp->isok ) {
	print "error getting the qop for \"$name\"\n";
	return 5;
    }
    $qop = $resp->value;

    $resp = $pop->tod;
    unless ( $resp->isok ) {
	print "error getting the time of day access for \"$name\"\n";
	return 6;
    }
    %tod  = %{$resp->value};

    $resp = $pop->ipauth;
    unless ( $resp->isok ) {
	print "error getting the ip authentication for \"$name\"\n";
	return 7;
    }
    %ipauth  = %{$resp->value};

    $resp = $pop->anyothernw;
    unless ( $resp->isok ) {
	print "error getting the any other networkd IP auth for \"$name\"\n";
	return 8;
    }
    $anyother  = $resp->value;

    $resp = $pop->attributes;
    unless ( $resp->isok ) {
	print "error getting the attributes for $name\n";
	return 9;
    }
    %attrs  = %{$resp->value};

    print "    POP Name   : $name\n";
    print "    Description: $desc\n";
    print "    Warning    : ", $warning ? "Yes" : "No", "\n";
    print "    Audit Level: ", $audlevel ? $audlevel : "None", "\n";
    print "    QOP        : $qop\n";
    print "    Time of Day:\n";
    printf "      Days : %s\n", $tod{days} ? join( ", ", @{$tod{days}}) : "All";
    printf "      Start : %-8s\tStop: %-8s\tReference: %-6s\n", 
		$tod{start} =~ /^0+$/ ? "NA" : $tod{start},
		$tod{stop}      ? $tod{stop}  : "NA",
		$tod{reference} ? $tod{reference} : "local";


    print "    IP Auth Policy:\n";
    if ( keys %ipauth ) {
	for ( keys %ipauth ) {
	    printf "       Auth Level: %-9s Network: %s/%s\n", $ipauth{$_}{AUTHLEVEL}, $_, $ipauth{$_}{NETMASK};
	}
    }
    printf "       Auth Level: %-9s Network: Any Other Network\n", $anyother;


    if ( keys %attrs ) {
	print "    Attributes:\n";
	for ( keys %attrs ) {
	    print "\t$_ :", join(" ",@{$attrs{$_}}),"\n";
	}
    }
    return 0;
}

sub _audit {
    my ($pop,@levels) = @_;

    return $pop->audit(level => \@levels);
}

sub _tod {
    my ($pop, $tname) = @_;
    my (@foo,@dlist,$start,$end) = ((),(),"","");

    @foo = split /:/, $tname;
    @dlist = split /,/, $foo[0];
    ($start,$end) = split(/-/, $foo[1]) if defined($foo[1]) and $foo[1] =~ /-/;

    return $pop->tod( days      => \@dlist, 
		      start     => $start, 
		      end       => $end, 
		      reference => $foo[-1] || '',
		     );
}

sub _warnmode {
    my ($pop, $tname) = @_;
    return $pop->warnmode( lc $tname eq 'yes' );
}

sub _ipauth {
    my ($pop, $action, $network, $netmask, $level) = @_;

    if ( $action eq 'add' ) {
	return $pop->ipauth( add => { $network => { NETMASK   => $netmask,
						    AUTHLEVEL => $level,
						  },
				     }
			   );
    }
    elsif ( $action eq 'remove' or $action eq 'forbidden') {
	return $pop->ipauth($action => {$network => {NETMASK => $netmask }});
    }
    elsif ( $action eq 'anyothernw' ) {
	# the name of the parameter doesn't really match.  Bite me.
	return $pop->anyothernw($network);
    }
    else {
	my $resp = Tivoli::AccessManager::Admin::Response->new;
	$resp->set_message("Unknown ipauth operation $action");
	$resp->set_isok(0);
	return $resp;
    }
}

sub modify {
    my ($tam, $action, $name, $comm, $target, @values) = @_;
    my $resp;

    my %mod_dispatch = (
	description   => \&Tivoli::AccessManager::Admin::POP::description,
	qop	      => \&Tivoli::AccessManager::Admin::POP::qop,
	'audit-level' => \&_audit,
	'tod-access'  => \&_tod,
	warning       => \&_warnmode,
	ipauth	      => \&_ipauth,
    );

    unless (defined($name) && $name) {
	print "You must provide the POP name\n";
	help('modify');
	return 1;
    }

    my $pop = Tivoli::AccessManager::Admin::POP->new( $tam, name => $name );
    unless ( $pop->exist ) {
	print "Cannot modify a POP which doesn't exist\n";
	return 2;
    }

    # Some special processing, then the catch all of the dispatcher
    if ( $comm eq 'delete' ) {
	if ( defined( $values[1] ) )  {
	    $resp = $pop->attributes( remove => { $values[0] => $values[1] } );
	}
	else {
	    $resp = $pop->attributes( removekey => $values[0] );
	}
    }
    elsif ( $target eq 'attribute' ) {
	unless ( defined( $values[1] ) ) {
	    print "You must provide a value\n";
	    help('modify');
	    return 3;
	}
	$resp = $pop->attributes( add => { $values[0] => $values[1] } );
    }
    elsif ( defined( $mod_dispatch{$target} ) ) {
	$resp =  $mod_dispatch{$target}->($pop,@values);
	unless ( $resp->isok ) {
	    print "Error modifying pop $name: ", $resp->messages, "\n";
	    return 4;
	}
    }
    else {
	print "Unknown POP action: $comm $target\n";
	return 5;
    }
}

sub attach {
    my ($tam, $action, $object, $name) = @_;
    my $resp;

    unless ( defined($object) and defined($name) ) {
	print "You must provide the POP name and the object\n";
	help('attach');
	return 1;
    }
    my $pop = Tivoli::AccessManager::Admin::POP->new( $tam, name => $name );
    $resp = $pop->attach( $object );
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

    # I want to find out which pop is attached to the named object
    $resp = $obj->pop;
    if ( $resp->value->{attached} ) {
	my $pop = Tivoli::AccessManager::Admin::POP->new($tam, name => $resp->value->{attached});
	$resp = $pop->detach( $object );
	unless ( $resp->isok ) {
	    print "Couldn't detach POP from $object: " . $resp->messages . "\n";
	    return 1;
	}
    }
    else {
	print "There is no POP attached to $object\n";
    }
    return 0;
}

1;

