package WWW::Google::Contacts::Type::Where;
{
    $WWW::Google::Contacts::Type::Where::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has value => (
    isa      => Str,
    is       => 'rw',
    traits   => ['XmlField'],
    xml_key  => 'valueString',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
