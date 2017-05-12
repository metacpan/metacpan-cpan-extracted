package WWW::Google::Contacts::InternalTypes;
{
    $WWW::Google::Contacts::InternalTypes::VERSION = '0.39';
}

use MooseX::Types -declare => [
    qw(
      XmlBool
      Rel
      When
      Where
      Method
      Country
      YomiStr
      )
];

use MooseX::Types::Moose qw(Str Bool HashRef CodeRef Any);

subtype Method, as CodeRef;

coerce Method, from Any, via {
    sub { return $_ }
};

class_type Rel, { class => 'WWW::Google::Contacts::Type::Rel' };

coerce Rel, from Str, via {
    require WWW::Google::Contacts::Type::Rel;
    WWW::Google::Contacts::Type::Rel->new( ( $_ =~ m{^http} )
        ? ( uri => $_ )
        : ( name => $_ ),
    );
};

subtype XmlBool, as Bool;

coerce XmlBool, from Str, via {
    return 1 if ( $_ =~ m{^true$}i );
    return 0;
};

class_type When, { class => 'WWW::Google::Contacts::Type::When' };

coerce When, from Str, via {
    require WWW::Google::Contacts::Type::When;
    WWW::Google::Contacts::Type::When->new( start_time => $_ );
}, from HashRef, via {
    return undef unless defined $_->{startTime};
    require WWW::Google::Contacts::Type::When;
    WWW::Google::Contacts::Type::When->new(
        start_time => $_->{startTime},
        defined $_->{endTime} ? ( end_time => $_->{endTime} ) : (),
    );
};

class_type Where, { class => 'WWW::Google::Contacts::Type::Where' };

coerce Where, from Str, via {
    require WWW::Google::Contacts::Type::Where;
    WWW::Google::Contacts::Type::Where->new( value => $_ );
}, from HashRef, via {
    require WWW::Google::Contacts::Type::Where;
    WWW::Google::Contacts::Type::Where->new( value => $_->{valueString} );
};

class_type Country, { class => 'WWW::Google::Contacts::Type::Country' };

coerce Country, from Str, via {
    require WWW::Google::Contacts::Type::Country;
    WWW::Google::Contacts::Type::Country->new( name => $_ );
}, from HashRef, via {
    require WWW::Google::Contacts::Type::Country;
    WWW::Google::Contacts::Type::Country->new($_);
};

subtype YomiStr, as Str;

coerce YomiStr, from HashRef, via {
    $_->{content};
};
