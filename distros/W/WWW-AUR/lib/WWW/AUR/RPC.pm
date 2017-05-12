package WWW::AUR::RPC;

use warnings 'FATAL' => 'all';
use strict;

use JSON qw();
use Carp qw();

use WWW::AUR::URI qw( rpc_uri );
use WWW::AUR qw( _category_name _useragent );

my %_RENAME_FOR = ( 'Description' => 'desc',
                    'NumVotes'    => 'votes',
                    'CategoryID'  => 'category',
                    'OutOfDate'   => 'outdated',
                    'FirstSubmitted' => 'ctime',
                    'LastModified' => 'mtime',
                   );

#---HELPER FUNCTION---
# Purpose: Map JSON package info keys to their new names...
sub _munge_result
{
    my ($info_ref) = @_;

    my %result;
    for my $key ( keys %$info_ref ) {
        my $newkey         = $_RENAME_FOR{ $key } || lc $key;
        $result{ $newkey } = $info_ref->{ $key };
    }

    $result{category} = _category_name( $result{category} );

    return \%result;
}

#---CLASS/OBJECT METHOD---
sub info
{
    my ($name) = @_;

    my $uri = rpc_uri( "info", $name );
    my $ua = _useragent();
	$ua->InitTLS;
    my $resp = $ua->get( $uri );

    Carp::croak 'Failed to call info AUR RPC: ' . $resp->status_line
        unless $resp->is_success;

    my $json = JSON->new;
    my $data = $json->decode( $resp->content );

    if ( $data->{type} eq "error" ) {
        Carp::croak "Remote error: $data->{results}";
    } elsif ( $data->{resultcount} == 0 ) {
        return undef;
    } else {
        return _munge_result( $data->{results} );
    }
}

sub multiinfo
{
    my (@names) = @_;

    my $uri = rpc_uri( "multiinfo", @names );
    my $ua = _useragent();
	$ua->InitTLS;
    my $resp = $ua->get( $uri );

    Carp::croak 'Failed to call multiinfo AUR RPC: ' . $resp->status_line
        unless $resp->is_success;

    my $json = JSON->new;
    my $data = $json->decode( $resp->content );

    if ( $data->{type} eq "error" ) {
        Carp::croak "Remote error: $data->{results}";
    }

    return map { _munge_result($_) } @{$data->{results}};
}

sub search
{
    my ($query) = @_;

    my $regexp;
    if ( $query =~ /\A\^/ || $query =~ /\$\z/ ) {
        $regexp = eval { qr/$query/ };
        if ( $@ ) {
            Carp::croak qq{Failed to compile "$query" into regexp:\n$@};
        }

        $query  =~ s/\A\^//;
        $query  =~ s/\$\z//;
    }

    my $uri = rpc_uri( 'search', $query );
    my $ua = _useragent();
 	$ua->InitTLS;
    my $resp = $ua->get( $uri );
    Carp::croak 'Failed to search AUR using RPC: ' . $resp->status_line
        unless $resp->is_success;

    my $json = JSON->new;
    my $data = $json->decode( $resp->content );

    if ( $data->{type} eq 'error' ) {
        Carp::croak "Remote error: $data->{results}";
    }

    my $results = [ map { _munge_result( $_ ) } @{ $data->{results} } ];

    if ( $regexp ) {
        $results = [ grep { $_->{name} =~ /$regexp/ } @$results ];
    }

    return $results;
}

sub msearch
{
    my ($name) = @_;

    my $aururi = rpc_uri( 'msearch', $name );
    my $ua = _useragent();
	$ua->InitTLS;
    my $resp = $ua->get( $aururi );
    Carp::croak qq{Failed to lookup maintainer using RPC:\n}
        . $resp->status_line unless $resp->is_success;

    my $json = JSON->new;
    my $json_ref = $json->decode( $resp->content );

    if ( $json_ref->{type} eq 'error' ) {
        Carp::croak "Remote error: $json_ref->{results}";
    }

    return [ map { _munge_result( $_ ) } @{ $json_ref->{results} } ];
}

1;
