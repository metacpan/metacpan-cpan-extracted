package WWW::Google::Contacts::Type::IM;
{
    $WWW::Google::Contacts::Type::IM::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

with 'WWW::Google::Contacts::Roles::HasTypeAndLabel' => {
    valid_types  => [qw( work home netmeeting other )],
    default_type => 'other',
};

has protocol => (
    isa       => Rel,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'protocol',
    predicate => 'has_protocol',
    coerce    => 1,
);

has value => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'address',
    predicate => 'has_value',
    required  => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
