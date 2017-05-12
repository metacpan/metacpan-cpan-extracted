package WWW::Google::Contacts::Type::Country;
{
    $WWW::Google::Contacts::Type::Country::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

use constant SCHEME => 'http://schemas.google.com/g/2005';

has code => (
    isa       => Str,
    is        => 'ro',
    traits    => ['XmlField'],
    xml_key   => 'code',
    predicate => 'has_code',
);

has name => (
    isa     => Str,
    is      => 'ro',
    traits  => ['XmlField'],
    xml_key => 'content',
);

sub to_xml_hashref {
    my $self = shift;
    return { $self->has_code ? ( code => $self->code ) : (),
        content => $self->name };
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
