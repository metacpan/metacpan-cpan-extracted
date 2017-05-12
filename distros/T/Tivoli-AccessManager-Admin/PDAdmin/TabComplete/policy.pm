package Tivoli::AccessManager::PDAdmin::TabComplete::policy;
$Tivoli::AccessManager::PDAdmin::TabComplete::policy::VERSION = '1.11';

use strict;
use warnings;

use Tivoli::AccessManager::PDAdmin::TabComplete::utils;

my %funcs = ( 
    'expiry-date' => [qw/unlimited unset <absolute-time>/],
    'disable-time-interval' => [qw/<seconds> unset disable/],
    'max-concurrent-web-sessions' => [qw/displace unlimited unset <number>/],
    'max-login-failures' => [qw/<count> unset/],
    'max-age' => [qw/unset <seconds>/],
    'max-repeated-chars' => [qw/<number> unset/],
    'min-alphas' => [qw/<number> unset/],
    'min-non-alphas' => [qw/<number> unset/],
    'min-length' => [qw/<number> unset/],
    'spaces' => [qw/yes no unset/],
    'tod' => [qw/anyday weekday <day-list> unset/],
);

my %map = ( 
	'account-expiry-date'         => 'expiry-date',
	'max-password-age'            => 'max-age',
	'max-password-repeated-chars' => 'max-repeated-chars',
	'min-password-alphas'         => 'min-alphas',
	'min-password-non-alphas'     => 'min-non-alphas',
	'min-password-length'         => 'min-length',
	'password-spaces'             => 'spaces',
	'tod-access'                  => 'tod',
	);

sub _tod {
    my ($tok_cnt,$tokref,$command,$word) = @_;

    if ( $tok_cnt == 4 ) {
	my @days = qw/unset monday tuesday wednesday thursday friday saturday sunday all/;
	if ( $word =~ /,(.*?)$/ ) {
	    $word = $1;
	}
	if ( $word =~ /any/ ) {
	    return 'any';
	}
	return grep /^$word/, @days;
    }
    elsif ( $tok_cnt == 5 ) {
	if ( $word =~ /[\d-]+/ ) {
	    return $word;
	}
	else {
	    return qw/anytime <timespec>-<timespec>/;
	}
    }
    elsif ( $tok_cnt == 6 ) {
	return grep /^$word/, qw/utc local/;
    }
    else {
	return ();
    }
}

sub complete {
    my ($tam, $tokref, $word, $buffer, $start) = @_;
    my ($command, $subcom,$resp, $tok_cnt);

    # There is some magic here.  Basically, I need to know if there is a word
    # under the cursor or not.  If there is, use the number of tokens as my
    # switch.  If there isn't, it means we are trying to complete an entire
    # sub command (e.g., acl show <tab>).  I am cheating and just adding one
    # to the token count if this case.  It *should* simplify the logic later

    $tok_cnt = @{$tokref} + (not $word);

    # I need to know what they are doing -- this is going to be the second
    # part of the command and will assume values like create, delete, etc.
    $command = $tokref->[1];

    if ( $tok_cnt == 3 ) {
	$funcs{all} = 1 if $command eq 'get';
	return grep /^$word/, keys %funcs;
    }

    $subcom = $tokref->[2];

    # Map the long names to the short names for the next sections
    $subcom = $map{$subcom} if defined $map{$subcom};

    if ($subcom eq 'tod' and $tok_cnt >= 4) {
	return _tod($tok_cnt,$tokref,$command,$word);
    }

    if (($tok_cnt == 5 and $command eq 'set') or 
        ($tok_cnt == 4 and $command eq 'get') ) {
	return '-user';
    }

    if ($tok_cnt == 4 and defined($funcs{$subcom})) {
	return grep /^$word/, @{$funcs{$subcom}};
    }


    if (($tok_cnt == 6 and $command eq 'set') or
        ($tok_cnt == 5 and $command eq 'get') ) {
	return _list_group_or_user($tam,'user',$word);
    }

    return ();
}

1;
