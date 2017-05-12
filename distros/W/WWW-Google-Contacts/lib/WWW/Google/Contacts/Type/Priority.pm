package WWW::Google::Contacts::Type::Priority;
{
    $WWW::Google::Contacts::Type::Priority::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has type => (
    isa      => Str,
    is       => 'rw',
    traits   => ['XmlField'],
    xml_key  => 'rel',
    required => 1,
);

sub value { $_[0]->type }

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
