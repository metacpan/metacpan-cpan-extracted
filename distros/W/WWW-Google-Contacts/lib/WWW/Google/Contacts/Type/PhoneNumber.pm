package WWW::Google::Contacts::Type::PhoneNumber;
{
    $WWW::Google::Contacts::Type::PhoneNumber::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::InternalTypes qw( Rel );
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;

extends 'WWW::Google::Contacts::Type::Base';

with 'WWW::Google::Contacts::Roles::HasTypeAndLabel' => {
    valid_types => [
        qw( assistant callback car company_main fax home home_fax
          isdn main mobile other_fax pager radio telex tty_tdd
          work work_fax work_mobile work_pager
          )
    ],
    default_type => 'mobile',
};

has value => (
    isa       => Str,
    is        => 'rw',
    traits    => ['XmlField'],
    xml_key   => 'content',
    predicate => 'has_content',
    required  => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
