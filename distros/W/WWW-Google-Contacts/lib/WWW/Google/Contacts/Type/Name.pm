package WWW::Google::Contacts::Type::Name;
{
    $WWW::Google::Contacts::Type::Name::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( YomiStr );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

has given_name => (
    isa        => YomiStr,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:givenName',
    predicate  => 'has_given_name',
    is_element => 1,
    coerce     => 1,
);

has additional_name => (
    isa        => YomiStr,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:additionalName',
    predicate  => 'has_additional_name',
    is_element => 1,
    coerce     => 1,
);

has family_name => (
    isa        => YomiStr,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:familyName',
    predicate  => 'has_family_name',
    is_element => 1,
    coerce     => 1,
);

has name_prefix => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:namePrefix',
    predicate  => 'has_name_prefix',
    is_element => 1,
);

has name_suffix => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:nameSuffix',
    predicate  => 'has_name_suffix',
    is_element => 1,
);

has full_name => (
    isa        => YomiStr,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:fullName',
    predicate  => 'has_full_name',
    trigger    => \&_full_name_set,
    is_element => 1,
    coerce     => 1,
);

sub _full_name_set {
    my ( $self, $full_name ) = @_;

    # Try to be clever..
    if ( $full_name =~ m{^([\w\-]+)\s+([\w\-]+)$} ) {
        $self->given_name($1);
        $self->family_name($2);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
