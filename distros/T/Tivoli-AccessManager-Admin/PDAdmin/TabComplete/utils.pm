package Tivoli::AccessManager::PDAdmin::TabComplete::utils;
$Tivoli::AccessManager::PDAdmin::TabComplete::utils::VERSION = '1.11';

use strict;
use warnings;


my %guessDN;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/_list_group_or_user _listObj _guessDN _list_gso/;

sub _list_group_or_user {
    my ($tam,$func,$word) = @_;
    my $resp;

    $resp = $func eq 'group' ? Tivoli::AccessManager::Admin::Group->list($tam) : Tivoli::AccessManager::Admin::User->list($tam);
    if ( $resp->isok ) {
	return grep { /^$word/ } $resp->value;
    }
    else {
	return ($resp->messages);
    }
}

sub _listObj {
    my ($tam,$word) = @_;
    my $prefix  = substr( $word,0,rindex($word,"/") );
    my @returns;

    $prefix = "/" if length($prefix) == 0;

    my $protobj = Tivoli::AccessManager::Admin::ProtObject->new( $tam, name => $prefix );

    my $resp = $protobj->list;

    if ( $resp->isok ) {
	for my $sublink ( grep { m#^$word# } $resp->value ) {
	    my $subobj = Tivoli::AccessManager::Admin::ProtObject->new( $tam, name => $sublink );
	    $resp = $subobj->type;
	    $sublink .= "/" unless ( $resp->value == 16 );
	    push @returns, $sublink;
	}
	return @returns;
    }
    else {
	print $resp->messages . "\n";
    }
}

sub _guessDN {
    my ($tam, $type, $word, $name) = @_;
    my ($rdn,$pdn,@ret);

    if ($word) {
	$word =~ /^(cn=.+),(.*)$/;
	$rdn = $1;
	$pdn = $2 || '';

    }
    else {
	return "cn=$name,";
    }

    unless ( keys %{$guessDN{$type}} ) {
	my $resp = $type eq 'group' ? Tivoli::AccessManager::Admin::Group->list($tam, bydn => 1 ) :
				      Tivoli::AccessManager::Admin::User->list($tam, bydn => 1 );
	return $resp->messages unless $resp->isok;

	for my $dn ( $resp->value ) {
	    next if $dn =~ /secAuthority=Default$/;
	    if ( $dn =~ /$pdn/i ) {
		$guessDN{$type}{substr($dn, index($dn,",")+1)} = 1;
	    }
	}
    }

    for ( keys %{$guessDN{$type}} ) {
	push @ret, "$rdn,$_" if /$pdn/;
    }

    return @ret;
}

sub _list_gso {
    my ($tam,$func,$word) = @_;
    my $resp;

    $resp = $func eq 'web' ? Tivoli::AccessManager::Admin::SSO::Web->list($tam) :
			     Tivoli::AccessManager::Admin::SSO::Group->list($tam);
#    $resp = Tivoli::AccessManager::Admin::SSO::Group->list($tam);
    if ( $resp->isok ) {
	return grep { /^$word/ } $resp->value;
    }
    else {
	return ($resp->messages);
    }
}

1;
