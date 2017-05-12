package WWW::Google::Contacts::Type::When;
{
    $WWW::Google::Contacts::Type::When::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

# TODO - these attributes should be dateTimes

has start_time => (
    isa      => Str,
    is       => 'rw',
    traits   => ['XmlField'],
    xml_key  => 'startTime',
    required => 1,
);

has end_time => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'endTime',
    predicate => 'has_end_time',
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
