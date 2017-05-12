package XML::Handler::ExtOn::TieAttrs;

=head1 NAME

 XML::PSAX::TieAttrs

=head1 SYNOPSIS

   use XML::PSAX::TieAttrs;

   tie %hasha, 'XML::PSAX::TieAttrs', \%hash1, default=><value>;

=head1 DESCRIPTION

 
 
=cut

use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
require Tie::Hash;
@XML::Handler::ExtOn::TieAttrs::ISA     = qw(Tie::StdHash);
$XML::Handler::ExtOn::TieAttrs::VERSION = '0.01';

sub attr_from_sax2 {
    my $sax_attr = shift || {};
    my %res = ();
    while ( my ( $key, $value ) = each %$sax_attr ) {
        my ( $prefix, $name, $ns_uri ) =
          @{$value}{qw/ Prefix LocalName NamespaceURI/};
        $prefix = '' unless defined $prefix;
        $ns_uri = '' unless defined $ns_uri;
        $res{qq/{$ns_uri}$name/} = {%$value};
    }
    return \%res;
}

my $attrs = {
    __temp_array => [],
    _orig_hash   => {},
    _default     => undef,
    _template    => {},

};

### install get/set accessors for this object.
for my $key ( keys %$attrs ) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

=head2 new

   tie %hasha, 'XML::PSAX::TieAttrs', \%hash1, default=><value>;

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $orig_hash = shift || {};
    my %props     = @_;
    my $self      = bless( \%props, $class );
    $self->_orig_hash($orig_hash);

    #set filters by
    my $field_name = $props{by}    || 'Name';
    my $value      = $props{value} || '';
    $self->_default( [ $field_name, $value ] );

    #setup template
    $self->_template( $props{template} || {} );
    return $self;
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
        next unless defined( $val->{$field_name} );
        next unless $val->{$field_name} eq $value;
        next if defined $flocal_name && $val->{LocalName} ne $flocal_name;
        $res{$i} = $val;
    }
    return \%res;
}

sub create_attr {
    my $self     = shift;
    my $key      = shift;
    my %template =
      ( %{ $self->_template() }, @{ $self->_default() }, LocalName => $key );
    my $prefix     = $template{Prefix};
    my $local_name = $template{LocalName};
    $template{Name} = $prefix ? "$prefix:$local_name" : $local_name;
    return attr_from_sax2( { 1 => \%template } );
}

sub DELETE {
    my ( $self, $key )   = @_;
    my ( $fkey, $fhash ) = %{ $self->get_by_filter($key) };
    return unless $fhash;
    my $val   = $fhash->{Value};
    my $ahash = $self->_orig_hash;
    delete $ahash->[$fkey];
    @{$ahash} = grep { defined } @{$ahash};
    return $val;
}

sub STORE {
    my ( $self, $key, $val ) = @_;
#    warn " store: $key, $val ";
    my ( $pkey, $fhash ) = %{ $self->get_by_filter($key) };
    if ($fhash) {
        $fhash->{Value} = $val;
    }
    else {
        my $new_add_to_hash = $self->create_attr($key);
        my $ahash           = $self->_orig_hash;
        while ( my ( $pkey, $pval ) = each %$new_add_to_hash ) {
        push @{$ahash}, $pval;
        }
        $self->STORE( $key, $val );
    }
    return $val;
}

sub FETCH {
    my ( $self, $key ) = @_;
    my $res;
    my ( $pkey, $pval ) = %{ $self->get_by_filter($key) };
    $res = $pval->{Value} if $pval;
    return $res;
}

sub GetKeys {
    my $self = shift;
    return [ map { $_->{LocalName} } values %{ $self->get_by_filter } ];
}

sub TIEHASH {    #shift;
    return &new(@_);
}

sub FIRSTKEY {
    my ($self) = @_;
    $self->__temp_array( [ sort { $a cmp $b } @{ $self->GetKeys() } ] );
    shift( @{ $self->__temp_array() } );
}

sub NEXTKEY {
    my ( $self, $key ) = @_;
    shift( @{ $self->__temp_array() } );
}

sub EXISTS {
    my ( $self, $key )  = @_;
    my ( $pkey, $pval ) = %{ $self->get_by_filter($key) };
    return defined $pval;
}

sub CLEAR {
    my $self = shift;
    foreach my $key ( @{ $self->GetKeys } ) {
        $self->DELETE($key);
    }
}

1;
__END__


=head1 SEE ALSO

Tie::StdHash

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

