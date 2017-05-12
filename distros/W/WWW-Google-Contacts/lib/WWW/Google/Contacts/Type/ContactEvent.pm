package WWW::Google::Contacts::Type::ContactEvent;
{
    $WWW::Google::Contacts::Type::ContactEvent::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel When );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has type => (
    isa       => Str,            # not a full url rel :-/
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'rel',
    predicate => 'has_type',
);

has label => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'label',
    predicate => 'has_label',
);

has when => (
    isa       => When,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'gd:when',
    predicate => 'has_when',
    coerce    => 1,
    required  => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
