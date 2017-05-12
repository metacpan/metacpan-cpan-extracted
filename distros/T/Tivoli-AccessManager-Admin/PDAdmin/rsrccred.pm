package Tivoli::AccessManager::PDAdmin::rsrccred;
$Tivoli::AccessManager::PDAdmin::rsrccred::VERSION = '1.11';

use strict;
use warnings;

use Text::Wrap;
use Term::ReadKey;
use Data::Dumper;

sub help {
    my $key = shift || '';
    my @help = (
	"rsrccred list user <user>-- lists all GSO resource creds for the specified user",
	"rsrccred show <cred> user <user id> -- displays the GSO resource cred.",
	"rsrccred create <cred> user <TAM user id> id <resource user id> pswd <resource password|?> [-group] -- creates a new GSO cred.  A ? for the password will cause you to be prompted for it.  You only need to specify the -group option if you have both a resource group and a web resource of the same name and you are trying to work on the group",
	"rsrccred delete <cred> user <TAM user id> [-group] -- deletes the GSO resource cred.  You only need to specify the -group option if you have both a resource group and a web resource of the same name and you are trying to work on the group",
	"rsrccred modify <cred> user <TAM user id> [id <resource user id>] [pswd <resource-password|?>] [-group] -- changes the resource ID and/or password for the specified user.  A ? for the password will cause you to be prompted for it.  You only need to specify the -group option if you have both a resource group and a web resource of the same name and you are trying to work on the group",
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

sub _parse_opts {
    my ($in,$req,$opts) = @_;

    $opts->{type} = '';
    while ( @$in ) {
	my $field = shift @$in; 
	if ( $field eq '-group' ) {
	    $opts->{type} = 'group'
	}
	else {
	    $opts->{$field} = shift @$in;
	}
    }

    for ( @$req ) {
	return $_ unless defined $opts->{$_};
    }

    return 0;
}

sub create {
    my ($tam, $action, $cred, @params) = @_;
    my ($resp,%opts,$rc);

    $cred = defined($cred) ? $cred : '';

    unless ( $cred ) {
	print "You must provide the resource cred's name\n";
	help('create');
	return 1;
    }

    $rc = _parse_opts(\@params,[qw/id pswd user/],\%opts);
    if ( $rc ) {
	print "The $rc parameter is required.\n";
	return 2;
    }

    # Get the password if we have to
    $opts{pswd} = _getpswd if $opts{pswd} eq '?';

    my $gso = Tivoli::AccessManager::Admin::SSO::Cred->new($tam,
				      resource => $cred,
				      uid  => $opts{user},
				      type => $opts{type},
				      ssouid => $opts{id},
				      ssopwd => $opts{pswd}
				  );

    if ( $gso->exist ) {
	print "The cred already exists\n";
	return 6;
    }
    else {
	$resp = $gso->create;
    }

    if ( $resp->isok ) {
	return 0;
    }
    else {
	print "Error adding cred $cred to user $opts{user}: ",$resp->messages,"\n";
	return 4;
    }
}

sub delete { 
    my ($tam, $action, $cred, @params) = @_;
    my ($resp,%opts,$rc);

    $cred = defined($cred) ? $cred : '';

    unless ( $cred ) {
	print "You must provide the resource cred's name\n";
	help('create');
	return 1;
    }

    $rc = _parse_opts(\@params,[qw/user/],\%opts);
    if ( $rc ) {
	print "The $rc parameter is required.\n";
	return 2;
    }

    my $gso = Tivoli::AccessManager::Admin::SSO::Cred->new($tam,
				      resource => $cred,
				      uid  => $opts{user},
				      type => $opts{type},
				  );
    unless ( $gso->exist ) {
	print "The cred doesn't exist\n";
	return 3;
    }
    else {
	$resp = $gso->delete;
    }

    if ( $resp->isok ) {
	return 0;
    }
    else {
	print "Error deleting the cred: " . $resp->messages;
	return 4;
    }
}

sub list {
    my ($tam, $action, @params) = @_;
    my (%opts,$rc);
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    $rc = _parse_opts(\@params,[qw/user/],\%opts);
    if ( $rc ) {
	print "The $rc parameter is required.\n";
	return 2;
    }

    $resp = Tivoli::AccessManager::Admin::SSO::Cred->list($tam,$opts{user});
    if ( $resp->isok ) {
	for my $gso ( sort $resp->value ) {
	    my ($type,$rname);

	    $resp = $gso->resource;
	    unless ( $resp->isok ) {
		print "Error retrieving resource name\n";
		return 2;
	    }
	    $rname = $resp->value;


	    $resp = $gso->type;
	    unless ( $resp->isok ) {
		print "Error retrieving resource type for $rname\n";
		return 3;
	    }
	    $type = $resp->value;


	    print "    Resource Name: $rname    Resource Type: $type\n";
	}
	return 0;
    }
    else {
	print "Error listing GSO creds for $opts{user}: ", $resp->messages,"\n";
	return 2;
    }
}

sub show {
    my ($tam, $action, $cred, @params) = @_;
    my ($resp, %ret,%opts,$rc);

    $rc = _parse_opts(\@params,[qw/user/],\%opts);
    if ( $rc ) {
	print "The $rc parameter is required.\n";
	return 1;
    }

    $resp  = Tivoli::AccessManager::Admin::SSO::Cred->list($tam, $opts{user});
    unless ( $resp->isok ) {
	print "Error retrieving GSO credentials for $opts{user}: ", $resp->messages, "\n";
	return 2;
    }

    for ( $resp->value ) {
	my ($type,$rname,$gsouid);

	$resp = $_->resource;
	unless ( $resp->isok ) {
	    print "Error retrieving resource name\n";
	    return 2;
	}
	$rname = $resp->value;


	$resp = $_->type;
	unless ( $resp->isok ) {
	    print "Error retrieving resource type for $rname\n";
	    return 3;
	}
	$type = $resp->value;

	$resp = $_->ssouid;
	unless ( $resp->isok ) {
	    print "Error retrieving GSO UID for user $opts{user}, resource $rname\n";
	    return 4;
	}
	$gsouid = $resp->value;

	print "    Resource Name  : $rname\n";
	print "      Resource Type  : $type\n";
	print "      Resource UserID: $gsouid\n";
    }
    return 0;
}

sub modify {
    my ($tam, $action, $cred, @params) = @_;
    my ($resp, $grp,%opts,$rc);


    $cred = defined($cred) ? $cred : '';

    unless ( $cred ) {
	print "You must provide the resource cred's name\n";
	help('create');
	return 1;
    }

    $rc = _parse_opts(\@params,[qw/user/],\%opts);
    if ( $rc ) {
	print "The $rc parameter is required.\n";
	return 2;
    }

    unless ( defined $opts{id} or defined $opts{pswd} ) {
	print "You must provide either the GSO ID or password to change\n";
	return 3;
    }

    my $gso = Tivoli::AccessManager::Admin::SSO::Cred->new( $tam,
				          resource => $cred,
					  type	   => $opts{type},
					  uid      => $opts{user} );
    unless ( $gso->exist ) {
	print "The specified credential $cred does not exist for user $opts{user}\n";
	return 4;
    }
    if ( defined( $opts{id} ) ) {
	$resp = $gso->ssouid($opts{id});
	unless ( $resp->isok ) {
	    print "Error modifying the GSO user ID for $opts{name}: ", $resp->messages, "\n";
	    return 5;
	}
    }

    if ( defined( $opts{pswd} ) ) {
	$resp = $gso->ssopwd($opts{pswd});
	unless ( $resp->isok ) {
	    print "Error modifying the GSO password for $opts{name}: ", $resp->messages, "\n";
	    return 6;
	}
    }
}

1;
