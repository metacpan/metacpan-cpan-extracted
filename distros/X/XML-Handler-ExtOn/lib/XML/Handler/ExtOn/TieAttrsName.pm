package XML::Handler::ExtOn::TieAttrsName;

#$id$

use strict;
use warnings;
use XML::Handler::ExtOn::TieAttrs;
use base 'XML::Handler::ExtOn::TieAttrs';

sub GetKeys {
    my $self = shift;
    return [ map { $_->{Name} } values %{ $self->get_by_filter } ];
}

sub create_attr {
    my $self     = shift;
    my $key      = shift;
    my %template =
      ( %{ $self->_template() }, @{ $self->_default() }, LocalName => $key );
    my ( $prefix )    = $key =~ /([^:]+):/;
    my $local_name = $key;
    $template{Name} = $prefix ? "$prefix:$local_name" : $local_name;
    $template{NamespaceURI} = $self->{context}->get_uri($prefix);
    return &XML::Handler::ExtOn::TieAttrs::attr_from_sax2( { 1 => \%template } );
}

sub get_by_filter {
    my $self        = shift;
    my $flocal_name = shift;
    my $ahash       = $self->_orig_hash;
    my %res         = ();
    my ( $field_name, $value ) = @{ $self->_default() };
    my $i = -1;
    foreach my $val (@$ahash) {
        $i++;
        if ( defined $flocal_name ) {
            next unless $val->{Name} eq $flocal_name;
        }
        $res{$i} = $val;
    }
    return \%res;
}
1;
