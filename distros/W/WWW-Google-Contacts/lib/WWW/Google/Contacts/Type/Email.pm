package WWW::Google::Contacts::Type::Email;
{
    $WWW::Google::Contacts::Type::Email::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str Undef );
use WWW::Google::Contacts::InternalTypes qw( Rel XmlBool );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

with 'WWW::Google::Contacts::Roles::HasTypeAndLabel' => {
    valid_types  => [qw( work home other )],
    default_type => 'work',
};

has value => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'address',
    predicate => 'has_value',
    required  => 1,
);

has display_name => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'displayName',
    predicate => 'has_display_name',
);

has primary => (
    isa       => XmlBool,
    is        => 'rw',
    traits    => ['XmlField'],
    predicate => 'has_primary',
    xml_key   => 'primary',
    to_xml =>
      sub { my $val = shift; return "true" if $val == 1; return "false" },
    default => sub { 0 },
    coerce  => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
