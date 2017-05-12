package Tivoli::AccessManager::PDAdmin::user;
$Tivoli::AccessManager::PDAdmin::user::VERSION = '1.11';

use strict;
use warnings;

use Text::Wrap;
use Term::ReadKey;

sub help {
    my $key = shift || '';
    my @help = (
	"user create <user id> <dn> <cn> <sn> <password> [group[ group ...]] [-g] [-n] [-v] -- Creates a new TAM user.  The user id, dn, cn, sn and password are required.  The list of groups to add the user to is optional.  Use a comma-seperated list for multiple groups.  Specifying -g makes the user a GSO user.  Specifying -n removes any password policy for the user. -v sets the account-valid flag to 'true' automagically.",
	"user delete <user id> [-r] -- Deletes the user from TAM, optionally from the LDAP as well if the -r flag is given",
	"user import <user id> <dn> [group[,...]] [-g] -- Imports the specified user into TAM.  If the list of groups is provided, the user will be granted those memberships as well.  The -g flag makes the user a GSO user as well",
	"user list [<pattern> <max-return>] -- Lists all TAM users, optionally those that match pattern up to max-return.  By default, the pattern is * and the max-return is 0",
	"user list_dn [<pattern> <max-return>] -- Lists all users in the LDAP, optionally those that match pattern up to max-return.  By default, the pattern is * and the max-return is 0",
	"user modify <user id> account-valid <yes|no> -- Sets the account valid flag",
	"user modify <user id> description <desc> -- Changes the user's description",
	"user modify <user id> groups add <group name>[ ...] -- add the user to the listed groups",
	"user modify <user id> groups remove <group name>[ ...] -- removes the user to the listed groups",
	"user modify <user id> gsouser <yes|no> -- Enables or disables GSO for the user",
	"user modify <user id> password <string|?> -- Changes the user's password.  If you use a ?, you will be prompted for the password.",
	"user modify <user id> password-valid <yes|no> -- Sets the password valid flag",
	"user show <user id> -- Display the named TAM user, including attributes",
	"user show_dn <dn> -- Displays the user, regardless of its TAMification",
	"user show_groups <user id> -- Displays all of the groups to which the user belongs",
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
    my ($tam, $action, @params) = @_;
    my ($user, $resp, $finddn, $gso, $nopwdpol, $name, $dn, $cn, $sn, 
	$pswd, $valid, @groups);
    my $go = 1;

    $gso = $nopwdpol = $valid = 0;
    while ( $go ) {
	if ( $params[-1] =~ /^-/ ) {
	    my $flag = pop @params;
	    ($flag eq '-g') and $gso      = 1;
	    ($flag eq '-n') and $nopwdpol = 1;
	    ($flag eq '-v') and $valid    = 1;
	}
	else {
	    $go = 0;
	}
    }
    ($name, $dn, $cn, $sn, $pswd, @groups) = @params;

    unless ( defined $name ) {
	print "You must provide the user id\n";
	help('create');
	return 1;
    }

    unless ( defined $dn ) {
	print "You must provide the user's DN\n";
	help('create');
	return 2;
    }

    unless ( defined $cn ) {
	print "You must provide the user's CN\n";
	help('create');
	return 3;
    }

    unless ( defined $sn ) {
	print "You must provide the user's SN\n";
	help('create');
	return 3;
    }

    unless ( $dn =~ /=/ ) {
	print "I am not certain $dn is a real DN, but I will try anyway\n";
    }

    $user = Tivoli::AccessManager::Admin::User->new( $tam, name => $name );
    if ( $user->exist ) {
	print "User $name already exists\n";
	return 4;
    }

    ($finddn = $dn) =~ s/,.*$/*/;
    $finddn =~ s/^.+?=//;

    $resp = Tivoli::AccessManager::Admin::User->list($tam, pattern => $finddn, bydn => 1);
    if ( $resp->isok ) {
	for my $gdn ( $resp->value ) {
	    if ( $gdn eq $dn ) {
		print "Error creating user $name: the supplied DN ($dn) seems to already exist\n";
		return 5;
	    }
	}
    }

    $pswd = _getpswd() if $pswd eq '?';

    $resp = $user->create(dn => $dn, 
			  cn => $cn, 
			  sn => $sn, 
			  groups => \@groups, 
			  sso	 => $gso,
			  nopwdpolicy => $nopwdpol,
			  password => $pswd);
    unless ( $resp->isok ) {
	print "Error creating user $name: " . $resp->messages . "\n";
	return 6;
    }

    if ( $valid ) {
	$resp = $user->accountvalid(1);
	unless ( $resp->isok ) {
	    print "Error marking account valid ",$resp->messages,"\n";
	    return 7;
	}
    }

    return 0;
}

sub delete {
    my ($tam, $action, $name, $opt) = @_;
    my ($user,$resp);

    unless ( defined( $name ) ) {
	print "You must provide the user name\n";
	help('delete');
	return 1;
    }

    if ( defined($opt) and $opt ne '-r' ) {
	print "Unrecognized option $opt\n";
	help('delete');
	return 2;
    }

    $user = Tivoli::AccessManager::Admin::User->new($tam, name => $name);
    unless ( $user->exist ) {
	print "User $name doesn't exist\n";
	return 3;
    }
    $resp  = $user->delete( defined($opt) );
    unless ( $resp->isok ) {
	print "Error trying to delete user $name: " . $resp->messages . "\n";
	return 4;
    }
    return 0;
}

sub iport {
    my ($tam, $action, $name, $dn, @params) = @_;
    my ($user,$resp,$finddn,$found,@groups,$sso,$group);

    unless ( defined( $name ) ) {
	print "You must provide the user name\n";
	help('import');
	return 1;
    }

    unless ( defined( $dn ) ) {
	print "You must provide the user's DN\n";
	help('import');
	return 2;
    }

    unless ( $dn =~ /=/ ) {
	print "I am not certain $dn is a real DN, but I will try anyway\n";
    }

    $user = Tivoli::AccessManager::Admin::User->new( $tam, name => $name );
    if ( $user->exist ) {
	print "user $name apparently exists already\n";
	return 3;
    }

    ($finddn = $dn) =~ s/,.*$/*/;
    $finddn =~ s/^.+?=//;

    $found = 0;
    $resp = Tivoli::AccessManager::Admin::User->list($tam, pattern => $finddn, bydn => 1);
    if ($resp->isok) {
	for my $gdn ( $resp->value ) {
	    if ($gdn eq $dn) {
		$found = 1;
		last;
	    }
	}
    }
    unless ( $found ) {
	print "Error importing user $name: the supplied DN ($dn) doesn't seem to exist\n";
	return 4;
    }

    $sso = 0;
    for my $opt ( @params ) {
	if ($opt =~ /^-g/) {
	    $sso = 1;
	}
	else {
	    $group = $opt;
	}
    }
    @groups = defined($group) ? split /,/,$group : ();
    $resp = $user->userimport(dn => $dn, groups => \@groups, sso => $sso);

    unless ( $resp->isok ) {
	print "Error importing user $name: " . $resp->messages . "\n";
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

    $resp = Tivoli::AccessManager::Admin::User->list($tam, pattern => $pattern, maxreturn => $maxreturn, bydn => $bydn);
    unless ( $resp->isok ) {
	print "Error searching for users: " . $resp->messages . "\n";
	return 1;
    }

    unless ( $resp->value ) {
	print "No users found matching $pattern\n";
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
    my ($tam,$action,$name,$bydn) = @_;
    my ($resp,$cn,$dn,$desc,$user,$pswd_val,$acct_val);
    my $TAMified = "Yes";
    my $PWDvalid = "No";
    my $ACTvalid = "No";
    my $GSOuser  = "No";

    unless ( defined($name)) {
	print "You must provide the user name\n";
	help('show');
	return 1;
    }

   
    if ( $bydn ) {
	$user = Tivoli::AccessManager::Admin::User->new( $tam, dn => $name );
    }
    else {
	$user = Tivoli::AccessManager::Admin::User->new( $tam, name => $name );
    }

    unless ( $user ) {
	print "Cannot find TAM user \"$name\"\n";
	return 2;
    }

    if ($user->exist) {
	$resp = $user->passwordvalid;
	$PWDvalid = "Yes" if $resp->isok and $resp->value == 1;

	$resp = $user->accountvalid;
	$ACTvalid = "Yes" if $resp->isok and $resp->value == 1;

	$resp = $user->ssouser;
	$GSOuser = "Yes" if $resp->isok and $resp->value == 1;
    }
    else {
	$TAMified = "No";
    }


    $dn   = $user->dn;
    $cn   = $user->cn;
    $resp = $user->description;
    $desc = $resp->isok ? $resp->value : '';

    print "  user ID: " . $user->name . "\n";
    print "  Descript: $desc\n";
    print "  LDAP  DN: $dn\n";
    print "  LDAP  CN: $cn\n";
    print "  TAMified: $TAMified\n";
    print "  GSO User: $GSOuser\n";
    print "  Account Valid: $ACTvalid\n";
    print "  Passwd  Valid: $PWDvalid\n";
    return 0;
}

sub show_dn {
    show(@_, 1);
}

sub show_groups {
    my ($tam, $action, $name, $pattern) = @_;
    my ($resp,@members);

    unless ( defined($name)) {
	print "You must provide the user name\n";
	help('show_groups');
	return 1;
    }

    my $user = Tivoli::AccessManager::Admin::User->new( $tam, name => $name );
    unless ( $user->exist ) {
	print "Cannot find TAM user \"$name\"\n";
	return 2;
    }

    $resp = $user->groups;
    unless ( $resp->isok ) {
	print "Error listing groups for \"$name\": " . $resp->messages . "\n";
	return 3;
    }

    for my $peep ( $resp->value ) {
	print "$peep\n";
    }
}

sub _trans_flag {
    my $value = shift;

    if ( defined($value) and $value !~ /^\d+$/ ) {
	$value = lc $value;
	$value = $value eq 'yes';
    }
    elsif ( not defined($value) ) {
	$value = 1;
    }

    return $value;
}

sub _mod_accnt {
    my ($user,$value) = @_;
    my $resp;

    $resp = $user->accountvalid(_trans_flag($value));
    unless ( $resp->isok ) {
	print "Error changing the password for \"", $user->name, "\": ",$resp->messages,"\n";
    }
}

sub _mod_desc {
    my ($user,$value) = @_;
    my $resp = $user->description($value);

    unless ( $resp->isok ) {
	print "Error changing the description for \"", $user->name, "\": ",$resp->messages,"\n";
    }
}

sub _mod_gso {
    my ($user,$value) = @_;
    my $resp;

    $resp = $user->ssouser(_trans_flag($value));
    unless ( $resp->isok ) {
	print "Error changing GSO status for \"", $user->name, "\": ",$resp->messages,"\n";
    }
}

sub _mod_pwd_valid {
    my ($user,$value) = @_;
    my $resp;

    $resp = $user->passwordvalid(_trans_flag($value));
    unless ( $resp->isok ) {
	print "Error modifying the password valid flag for \"", $user->name, "\": ",$resp->messages,"\n";
    }
}

sub _getpswd {
    my $pswd = '0';
    my $pswd_repeat = '1';

    ReadMode 2;
    while ( $pswd ne $pswd_repeat ) {
	print "Enter new password: ";
	$pswd = <STDIN>;
	print "\nVerify password: ";
	$pswd_repeat = <STDIN>;
	chomp $pswd;
	chomp $pswd_repeat;
	print "\n";
    }
    ReadMode 0;

    return $pswd;
}

sub _mod_pswd {
    my ($user,$value) = @_;
    my ($resp);

    $value = _getpswd if $value eq '?';
    $resp = $user->password($value);
    unless ( $resp->isok ) {
	print "Error changing the password for \"", $user->name, "\": ",$resp->messages,"\n";
    }
    
}

sub _mod_group {
    my ($user,$comm,@groups) = @_;

    unless ( $comm eq 'add' or $comm eq 'remove' ) {
	print "Invalid group operation $comm\n";
	return 1;
    }

    return $user->groups( $comm => \@groups );
}

sub modify {
    my ($tam, $action, $name, $subact, @value) = @_;
    my $resp;

    my %dispatch = ( 'account-valid' => \&_mod_accnt,
		    description      => \&_mod_desc,
		    gsouser 	     => \&_mod_gso,
		    password 	     => \&_mod_pswd,
		    'password-valid' => \&_mod_pwd_valid,
		    groups	     => \&_mod_group,
		);

    unless ( defined($name) ) {
	print "You must provide the user name\n";
	help('modify');
	return 1;
    }

    unless ( defined( $subact ) ) {
	print "You need to specify how we are modifying user \"$name\"\n";
	help('modify');
	return 2;
    }

    unless ( defined( $dispatch{$subact} ) ) {
	print "Invalid subaction \"$subact\" -- it must be one of ",join(", ", keys(%dispatch)),"\n";
	help('modify');
	return 3;
    }

    my $user = Tivoli::AccessManager::Admin::User->new($tam,name => $name);
    unless ( $user->exist ) {
	print "User \"$name\" does not exist\n";
	return 4;
    }

    $dispatch{$subact}->($user,@value);

}
1;
