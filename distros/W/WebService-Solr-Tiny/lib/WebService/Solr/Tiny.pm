package WebService::Solr::Tiny 0.001;

use strict;
use warnings;

use URI::Query::FromHash 0.003;

sub import {
    no strict 'refs';

    *{ caller . '::solr_escape' }
        = sub { $_[0] =~ s/([\Q+-&|!(){}[]^"~*?:\\\E])/\\$1/gr }
        if grep $_ eq 'solr_escape', @_;
}

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;

    unless ( exists $self->{agent} ) {
        require HTTP::Tiny;

        $self->{agent} = HTTP::Tiny->new( keep_alive => 1 );
    }

    unless ( exists $self->{decoder} ) {
        require JSON::PP;

        $self->{decoder} = \&JSON::PP::decode_json;
    }

    $self->{default_args} //= {};
    $self->{url}          //= 'http://localhost:8983/solr/select';

    $self;
}

sub search {
    my $self = shift;
    my %args = ( %{ $self->{default_args} }, 'q' => @_ ? @_ : '' );

    my $reply = $self->{agent}->get( $self->{url} . '?' . hash2query %args );

    unless ( $reply->{success} ) {
        require Carp;

        Carp::croak("Solr request failed - $reply->{content}");
    }

    $self->{decoder}( $reply->{content} );
}

no URI::Query::FromHash;

1;
