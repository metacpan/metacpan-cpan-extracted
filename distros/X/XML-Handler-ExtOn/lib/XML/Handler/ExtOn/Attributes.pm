package XML::Handler::ExtOn::Attributes;

#$Id: Attributes.pm 235 2007-11-29 12:37:07Z zag $

use Carp;
use Data::Dumper;
use XML::Handler::ExtOn::TieAttrs;
use XML::Handler::ExtOn::TieAttrsName;
for my $key (qw/ _context _a_stack/) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}
use strict;
use warnings;

sub new {
    my ( $class, %attr ) = @_;
    my $self = bless {}, $class;
    $self->_context( $attr{context} ) or die "not exists context parametr";
    my @a_stack = ();
    if ( my $sax2 = $attr{sax2} ) {

        #walk through sax2 attrs
        # and register namespaces
        for ( values %$sax2 ) {
            my ( $prefix, $ns_uri ) = ( $_->{Prefix}, $_->{NamespaceURI} );
            if ( defined $prefix && $prefix eq 'xmlns' ) {
                $self->_context->declare_prefix( $_->{LocalName}, $_->{Value} );
            }

            #set default namespace
            if ( $_->{Name} eq 'xmlns' ) {

                #warn "register deafault ns".$a->{Value};
                $self->_context->declare_prefix( '', $_->{Value} );
            }
        }

        #now set default namespaces
        # and
        my $default_uri = $self->_context->get_uri('');
        for ( values %$sax2 ) {

            #save original data from changes
            my %val = %{$_};
            $val{NamespaceURI} = $default_uri
              unless $val{Prefix} || $val{Name} eq 'xmlns';
            push @a_stack, \%val;
        }

    }
    $self->_a_stack( \@a_stack );
    return $self;
}

=head2 to_sax2

Export attributes to sax2 structures

=cut

sub to_sax2 {
    my $self  = shift;
    my $attrs = $self->_a_stack;
    my %res   = ();
    foreach my $rec (@$attrs) {
        my %val = %{$rec};

        #clean default uri
        $val{NamespaceURI} = undef unless $val{Prefix};

        my $key = "{" . ( $val{NamespaceURI} || '' ) . "}$val{LocalName}";
        $res{$key} = \%val

          #        warn Dumper $rec;
    }
    return \%res;
}

sub ns {
    return $_[0]->_context;
}

=head2 by_prefix $prefix

Create hash for attributes by prefix $prefix

=cut

sub by_prefix {
    my $self   = shift;
    my $prefix = shift;
    my %hash   = ();
    my $ns_uri = $self->ns->get_uri($prefix)
      or die "get_uri($prefix) return undef";
    tie %hash, 'XML::Handler::ExtOn::TieAttrs', $self->_a_stack,
      by       => 'Prefix',
      value    => $prefix,
      template => {
        Value        => '',
        NamespaceURI => $ns_uri,
        Name         => '',
        LocalName    => '',
        Prefix       => ''
      };
    return \%hash;
}

=head2 by_ns_uri $ns_uri

Create hash for attributes for namespace $ns_uri

=cut

sub by_ns_uri {
    my $self   = shift;
    my $ns_uri = shift;
    my %hash   = ();
    my $prefix = $self->ns->get_prefix($ns_uri);
    die "get_prefix($ns_uri) return undef" unless defined($prefix);
    tie %hash, 'XML::Handler::ExtOn::TieAttrs', $self->_a_stack,
      by       => 'NamespaceURI',
      value    => $ns_uri,
      template => {
        Value        => '',
        NamespaceURI => '',
        Name         => '',
        LocalName    => '',
        Prefix       => $prefix
      };
    return \%hash

}

=head2 by_name

Create hash for attributes by name

=cut

sub by_name {
    my $self = shift;
    my %hash = ();
    tie %hash, 'XML::Handler::ExtOn::TieAttrsName', $self->_a_stack,
      context => $self->_context;
    return \%hash;
}

1;
