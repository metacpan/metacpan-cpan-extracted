package WWW::Google::Contacts::Type::Relation;
{
    $WWW::Google::Contacts::Type::Relation::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

with 'WWW::Google::Contacts::Roles::HasTypeAndLabel' => {
    valid_types => [
        qw(
          assistant brother child domestic-partner father friend manager
          mother parent partner referred-by relative sister spouse
          )
    ],
    default_type => '',
};

has value => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'content',
    predicate => 'has_value',
    required  => 1,
);

# 'rel' XML key must not have contain a full url, only the value
before to_xml_hashref => sub {
    my $self = shift;
    my $type = $self->type->uri;
    $type =~ s{^.*\#}{};
    $self->type->uri($type);
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
