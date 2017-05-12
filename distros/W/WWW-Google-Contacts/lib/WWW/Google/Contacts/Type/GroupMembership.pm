package WWW::Google::Contacts::Type::GroupMembership;
{
    $WWW::Google::Contacts::Type::GroupMembership::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has href => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'href',
    predicate => 'has_href',
    required  => 1,
);

sub search_field {
    return 'href';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
