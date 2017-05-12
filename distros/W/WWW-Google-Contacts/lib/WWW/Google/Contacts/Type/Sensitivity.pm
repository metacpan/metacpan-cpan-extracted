package WWW::Google::Contacts::Type::Sensitivity;
{
    $WWW::Google::Contacts::Type::Sensitivity::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has type => (
    isa       => Str,            # not a full url rel :-/
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'rel',
    predicate => 'has_type',
    required  => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
