package Tivoli::AccessManager::PDAdmin::policy;
$Tivoli::AccessManager::PDAdmin::policy::VERSION = '1.11';

use strict;
use warnings;
use Text::Wrap;

sub help {
    my $key = shift || '';
    my @help = (
	'policy [set|get] expiry-date {unlimited|<absolute-time>|unset} [-user <user-name>] -- set/get the expiration date',
	'policy [set|get] disable-time-interval {<number>|unset|disable} [-user <user-name>] -- set/get the disable time interval',
	'policy [set|get] max-concurrent-web-sessions {<number>|displace|unlimited|unset} [-user <user-name>] -- set/get the maximum number of concurrent sessions',
	'policy [set|get] max-login-failures <number|unset> [-user <user-name>] -- set/get the maximum number of login failures before the account is locked/disabled',
	'policy [set|get] max-age {unset|<relative-time>} [-user <user-name>] -- set/get the maximum password age',
	'policy [set|get] max-repeated-chars <number|unset> [-user <user-name>] -- set/get the maximum number of repeated characters allowed in a password',
	'policy [set|get] min-alphas {unset|<number>} [-user <user-name>] -- set/get the minimum number of alpha chars in a password',
	'policy [set|get] min-length {unset|<number>} [-user <user-name>] -- set/get the minimum password length',
	'policy [set|get] min-non-alphas {unset|<number>} [-user <user-name>] -- set the minimum number of non-alpha characters in a password',
	'policy [set|get] spaces {yes|no|unset} [-user <user-name>] -- allow/disallow spaces in passwords',
	'policy [set|get] tod {<{all|weekday|<day-list>}> <{anytime|<time-spec>-<time-spec>}>[ {utc|local}]|unset} [-user <user-name>]  -- set/get time-of-day access',
	'policy get all [-user <user-name>] -- Display all of the password policies',
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

sub _accexpdate {
    my ($object, $value) = @_;
    return $object->accexpdate( seconds => $value );
}

sub _disabletimeint {
    my ($object, $value) = @_;
    return $object->disabletimeint( seconds => $value );
}

sub _maxlgnfails {
    my ($object, $value) = @_;
    return $object->maxlgnfails(failures => $value);
}

sub _maxpwdage {
    my ($object, $value) = @_;
    return $object->maxpwdage( seconds => $value );
}

sub _maxpwdrepchars {
    my ($object, $value) = @_;
    return $object->maxpwdrepchars( chars => $value );
}

sub _minpwdalphas {
    my ($object, $value) = @_;
    return $object->minpwdalphas( chars => $value );
}

sub _minpwdnonalphas {
    my ($object, $value) = @_;
    return $object->minpwdnonalphas( chars => $value );
}

sub _minpwdlen {
    my ($object, $value) = @_;
    return $object->minpwdlen( chars => $value );
}

sub _pwdspaces {
    my ($object, $value) = @_;
    return $object->pwdspaces( chars => $value );
}

sub _tod {
    my ($object, %values) = @_;
    return $object->tod( %values );
}

sub _max_concur_session {
    my ($object, $value) = @_;
    return $object->max_concur_session($value);
}

sub _display {
    my $object = shift;
    my $resp;
    my ($expire,$disable,$fail,$age,$repeats,$alphas,$nonalphas);
    my ($length,$spaces,%tod,$days,$hours,$maxsession,$temp);

    # Collect all the data
    $resp = $object->accexpdate;
    printf "Account Expiration Date:      %-20s\n", $resp->value || 'unset';

    $resp = $object->disabletimeint;
    $disable = $resp->value || 'unset';
    if ( $disable =~ /^\d+$/ ) {
	$disable .= " seconds";
    }
    printf "Disable Time Interval:        %-20s\n", $disable;

    $resp       = $object->max_concur_session;
    $maxsession = $resp->value || 'unset';
    printf "Maximum concurrent sessions:  %-20s\n", $maxsession;

    $resp = $object->maxlgnfails;
    $fail = $resp->value || 'unset';
    printf "Maximum login failures:       %-20s\n", $fail;

    $resp = $object->maxpwdage;
    $temp = $resp->value;
    if ( $temp =~ /^\d+$/ ) {
	$days = ($temp - $temp%86400)/86400;
	$temp %= 86400;
	$hours = ($temp - $temp%3600)/3600;
	printf "Maximum Password Age:         %d days, %d hours (%d seconds)\n", 
		    $days, $hours, scalar($resp->value);
    }
    else {
	printf "Maximum Password Age:         %-20s\n", $temp;
    }

    $resp = $object->maxpwdrepchars;
    $repeats = $resp->value || 'unset';
    printf "Maximum repeated characters:  %-20s\n", $repeats;

    $resp = $object->minpwdalphas;
    $alphas = $resp->value || 'unset';
    printf "Minimum alpha characters:     %-20s\n", $alphas;

    $resp = $object->minpwdnonalphas;
    $nonalphas = $resp->value || 'unset';
    printf "Minimum non-alpha characters: %-20s\n", $nonalphas;

    $resp = $object->minpwdlen;
    $length = $resp->value || 'unset';
    printf "Minimum length:               %-20s\n", $length;

    $resp = $object->pwdspaces;
    printf "Allow spaces in passwords:    %s\n", $resp->value ? "Yes" : "No";

    $resp = $object->tod;
    %tod  = $resp->value;

    # Now print it pretty
    print "Time of day access";
    if ( defined $tod{days} ) {
	print ":\n";
	printf "\tDays: %s\n", @{$tod{days}} ? join(",", @{$tod{days}} ) : "unset";
	printf "\tStart: %s\n", $tod{start} || 'unset';
	printf "\tStop:  $tod{stop}\n", $tod{stop} || 'unset';
	printf "\tReference: $tod{reference}\n";
    }
    else {
	print ": unset\n";
    }
}

sub set {
    my ($tam, $action, $attr, @values) = @_;
    my ($flag,$name,$object,$resp);

    my $msgstr;
    # The longer versions are included for compatibility with IBM's pdadmin,
    # but are not documented.  I am setting *password* policies.  Why do I
    # need to keep saying "password"?
    my %dispatch = ( 
	'account-expiry-date'         => \&_accexpdate,
	'expiry-date'                 => \&_accexpdate,
	'disable-time-interval'       => \&_disabletimeint,
	'max-login-failures' 	      => \&_maxlgnfails,
	'max-password-age'            => \&_maxpwdage,
	'max-age'            	      => \&_maxpwdage,
	'max-password-repeated-chars' => \&_maxpwdrepchars,
	'max-repeated-chars'          => \&_maxpwdrepchars,
	'min-password-alphas'         => \&_minpwdalphas,
	'min-alphas'                  => \&_minpwdalphas,
	'min-password-non-alphas'     => \&_minpwdalphas,
	'min-non-alphas'              => \&_minpwdalphas,
	'min-password-length'         => \&_minpwdlen,
	'min-length'                  => \&_minpwdlen,
	'password-spaces'             => \&_pwdspaces,
	'spaces'                      => \&_pwdspaces,
	'tod-access'                  => \&_tod,
	'tod'                         => \&_tod,
	'max-concurrent-web-sessions' => \&_max_concur_session,
	'all'			      => \&_display,
    );


    if ( defined($values[-2]) and $values[-2] eq '-user' ) {
	($flag,$name) = splice(@values,-2,2);

	$object = Tivoli::AccessManager::Admin::User->new($tam, name => $name);

	unless ( $object->exist ) {
	    print "Warning:  Could not find user $name\n";
	    return 1;
	}
	$msgstr = "Current $attr for user $name: ";
    }
    else {
	$object = $tam;
	$msgstr = "Current global for $attr: ";
    }

    if ( $attr eq 'all' ) {
	if ( $action eq 'get' ) {
	    return _display($object);
	}
	else {
	    print "Error: You cannot set 'all'\n";
	    return 4;
	}
    }

    if ( defined( $dispatch{$attr} ) ) {
	$resp = $dispatch{$attr}->($object,@values);
	unless ( $resp->isok ) {
	    print "Error modifying $attr: " . $resp->messages . "\n";
	    return 2;
	}
    }
    else {
	print "Unknown policy $attr\n";
	return 3;
    }

    print $msgstr . $resp->value . "\n";
    return 0;
}

sub get {
    return set(@_);
}

1;
