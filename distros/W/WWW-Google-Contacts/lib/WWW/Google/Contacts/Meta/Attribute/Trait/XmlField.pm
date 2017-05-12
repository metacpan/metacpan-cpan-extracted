package WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;
{
    $WWW::Google::Contacts::Meta::Attribute::Trait::XmlField::VERSION = '0.39';
}

use Moose::Role;
use WWW::Google::Contacts::InternalTypes qw( Method );
use MooseX::Types::Moose qw( Str CodeRef Bool );

has xml_key => (
    isa      => Str,
    is       => 'ro',
    required => 1,
);

# Allow attributes to have custom code for transforming to xml
has to_xml => (
    isa       => CodeRef,
    is        => 'ro',
    predicate => 'has_to_xml',
);

has is_element => (
    isa     => Bool,
    is      => 'ro',
    default => sub { 0 },
);

has include_in_xml => (
    isa     => Method,
    is      => 'ro',
    default => sub {
        sub { 1 }
    },
    coerce => 1,
);

no Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::XmlField;
{
    $Moose::Meta::Attribute::Custom::Trait::XmlField::VERSION = '0.39';
}

sub register_implementation {
    'WWW::Google::Contacts::Meta::Attribute::Trait::XmlField';
}

1;
