package WWW::Google::Contacts::Roles::List;
{
    $WWW::Google::Contacts::Roles::List::VERSION = '0.39';
}

use Moose::Role;
use MooseX::Types::Moose qw( ArrayRef Int );
use Carp qw( croak );
use URI::Escape;
use Perl6::Junction qw( any );
use WWW::Google::Contacts::Data;

requires 'baseurl', 'element_class';

has elements => (
    isa        => ArrayRef,
    is         => 'rw',
    lazy_build => 1,
);

has server => (
    is       => 'ro',
    required => 1,
);

has pointer => (
    isa      => Int,
    is       => 'rw',
    default  => 0,
    init_arg => undef,
);

sub search {
    my ( $self, $search ) = @_;

    my $class = $self->element_class;

# TODO - make something clever to match XML keys without having to bless all the objects for comparison
# this could be a start;
#
#my $element = $class->new( server => $self->server );
#my $search_params = [];
#foreach my $key ( keys %{ $search } ) {
#    my $xml_key = $element->get_xml_key( $key );
#    if ( $xml_key ) {
#        push @{ $search_params },
#            {
#                xml_key => $xml_key,
#                value   => $search->{ $key },
#            };
#    }
#    else {
#        croak "Can't find XML key for [$key]";
#    }
#}

    # This doesn't scale well.... SLOW
    my $to_ret = [];
  ELEM:
    foreach my $elem ( @{ $self->elements } ) {
        my $obj = $class->new( server => $self->server );
        $obj->set_from_server($elem);
        foreach my $key ( keys %{$search} ) {
            next ELEM unless ( defined $obj->$key );
            if ( ref( $obj->$key ) and ref( $obj->$key ) eq 'ARRAY' ) {
                my $search_field = $obj->$key->[0]->search_field;
                next ELEM unless ( defined $search_field );
                my @values = map { $_->$search_field } @{ $obj->$key };
                my $search_key = $search->{$key};

                # protocol might not match, that doesn't matter
                if ( $search_key =~ s{^http.?:}{} ) {
                    $_ =~ s{^http.?:}{} foreach (@values);
                }
                next ELEM unless ( any(@values) eq $search_key );
            }
            else {
                my $search_key = $search->{$key};
                my $obj_key    = $obj->$key;

                # protocol might not match, that doesn't matter
                if ( $search_key =~ s{^http.?:}{} ) {
                    $obj_key =~ s{^http.?:}{};
                }
                next ELEM unless ( $obj_key eq $search_key );
            }
        }
        push @{$to_ret}, $obj;
    }
    return wantarray ? @{$to_ret} : $to_ret;
}

sub next {
    my $self = shift;
    return undef unless ( $self->elements->[ $self->pointer ] );
    my $next = $self->elements->[ $self->pointer ];
    $self->pointer( $self->pointer + 1 );
    my $class = $self->element_class;
    return $class->new( server => $self->server )->set_from_server($next);
}

sub _build_elements {
    my $self = shift;

    my $args = {};
    $args->{'alt'} = 'atom';    # must be atom
    $args->{'max-results'} ||= 9999;
    my $group = delete $args->{group} || 'full';
    my $url = sprintf( '%s/%s?v=3.0', $self->baseurl, uri_escape($group) );
    foreach my $key ( keys %$args ) {
        $url .= '&' . uri_escape($key) . '=' . uri_escape( $args->{$key} );
    }
    my $res     = $self->server->get($url);
    my $content = $res->content;
    my $data    = WWW::Google::Contacts::Data->decode_xml($content);
    my $array   = $data->{entry} || [];

    if ( ref($array) eq 'HASH' ) {
        $array = [$array];
    }

# ..lots of overhead to bless them all now.
#my $class = $self->element_class;
#$array = [ map { $class->new( server => $self->server )->set_from_server( $_ ) } @{ $array } ];
    return $array;
}

1;
