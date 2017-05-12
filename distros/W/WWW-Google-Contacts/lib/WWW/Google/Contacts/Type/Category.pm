package WWW::Google::Contacts::Type::Category;
{
    $WWW::Google::Contacts::Type::Category::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has type => (
    isa       => Rel,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'scheme',
    predicate => 'has_type',
    coerce    => 1,
    required  => 1,
);

has term => (
    isa       => Rel,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'term',
    predicate => 'has_term',
    coerce    => 1,
    required  => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
