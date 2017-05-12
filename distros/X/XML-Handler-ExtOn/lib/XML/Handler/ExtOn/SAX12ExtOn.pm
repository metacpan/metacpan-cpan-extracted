package XML::Handler::ExtOn::SAX12ExtOn;
#$Id: SAX12ExtOn.pm 316 2008-09-14 14:25:23Z zag $

use XML::Filter::SAX1toSAX2;
use XML::Handler::ExtOn;

#use base qw/   XML::Handler::ExtOn XML::Filter::SAX1toSAX2/;
use base qw/   XML::Handler::ExtOn/;
use strict;
use warnings;
use Data::Dumper;

sub _scan_namespaces {
    my $self = shift;
    my ( $elem, $attributes ) = @_;
    while ( my ( $attr_name, $value ) = each %$attributes ) {
        if ( $attr_name =~ /^xmlns(:(.*))?$/ ) {
            my $prefix = $2 || '';
            $elem->ns->declare_prefix( $prefix, $value );
        }
    }
}

sub process_a_name {
    my $self = shift;
    my $elem = shift;
    my $key  = shift;
    my ( $lname, $prefix ) = reverse split( /:/, $key );
    my $ns = $elem->ns->get_uri($prefix);
#    warn "key: $key  prefix: $prefix ns_iri: $ns ";
    unless ( defined $ns ) {
        $prefix = undef;
    }
    #for attributes !
    $ns = undef unless defined $prefix;
    return ( $lname, $ns, $prefix );
}

sub start_element {
    my ( $self, $element ) = @_;
    my $elem    = $self->mk_element( $element->{Name} );
    my $attr    = $element->{Attributes};
    my %by_name = ();
    $self->_scan_namespaces( $elem, $attr );
    while ( my ( $key, $val ) = each %$attr ) {
        my ( $lname, $uri, $prefix, ) = $self->process_a_name( $elem, $key );
        # delete attribute if unknown prefix
        if ( ! defined $prefix and $key =~/:/) {
           next
        }
        unless ( defined $prefix ) {
            $elem->attrs_by_name->{$lname} = $val;
        }
        else {
            $elem->attrs_by_ns_uri($uri)->{$lname} = $val;
        }
    }
    return $self->SUPER::start_element($elem);
}
1;
