package WWW::Google::Contacts::Type::Organization;
{
    $WWW::Google::Contacts::Type::Organization::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel XmlBool Where );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

with 'WWW::Google::Contacts::Roles::HasTypeAndLabel' => {
    valid_types  => [qw( work other )],
    default_type => 'work',
};

has department => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:orgDepartment',
    predicate  => 'has_department',
    is_element => 1,
);

has job_description => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:orgJobDescription',
    predicate  => 'has_job_description',
    is_element => 1,
);

has name => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:orgName',
    predicate  => 'has_name',
    is_element => 1,
);

has symbol => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:orgSymbol',
    predicate  => 'has_symbol',
    is_element => 1,
);

has title => (
    isa        => Str,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:orgTitle',
    predicate  => 'has_title',
    is_element => 1,
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

has where => (
    isa        => Where,
    is         => 'rw',
    traits     => ['XmlField'],
    xml_key    => 'gd:where',
    predicate  => 'has_where',
    is_element => 1,
    coerce     => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
