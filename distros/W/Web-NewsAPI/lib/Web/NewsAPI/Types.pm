package Web::NewsAPI::Types;

use Moose::Util::TypeConstraints;

subtype 'NewsDateTime', as 'DateTime';
subtype 'NewsURI', as 'Maybe[URI]';

coerce 'NewsDateTime',
    from 'Str',
    via { DateTime::Format::ISO8601->parse_datetime( $_ ) };

coerce 'NewsURI',
    from 'Str',
    via { URI->new( $_ ) };


1;
