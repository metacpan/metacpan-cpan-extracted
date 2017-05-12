package WWW::Google::Contacts::Types;
{
    $WWW::Google::Contacts::Types::VERSION = '0.39';
}

use MooseX::Types -declare => [
    qw(
      Category
      Name
      PhoneNumber     ArrayRefOfPhoneNumber
      Email           ArrayRefOfEmail
      IM              ArrayRefOfIM
      Organization    ArrayRefOfOrganization
      PostalAddress   ArrayRefOfPostalAddress
      CalendarLink    ArrayRefOfCalendarLink
      Birthday
      ContactEvent    ArrayRefOfContactEvent
      ExternalId      ArrayRefOfExternalId
      Gender
      GroupMembership ArrayRefOfGroupMembership
      Hobby           ArrayRefOfHobby
      Jot             ArrayRefOfJot
      Language        ArrayRefOfLanguage
      Priority
      Sensitivity
      Relation        ArrayRefOfRelation
      UserDefined     ArrayRefOfUserDefined
      Website         ArrayRefOfWebsite
      Photo
      Group
      )
];

use MooseX::Types::Moose qw(Str HashRef ArrayRef Any Undef Bool);

use WWW::Google::Contacts::Type::Category;
use WWW::Google::Contacts::Type::Name;
use WWW::Google::Contacts::Type::PhoneNumber;
use WWW::Google::Contacts::Type::PhoneNumber;
use WWW::Google::Contacts::Type::Email;
use WWW::Google::Contacts::Type::Email;
use WWW::Google::Contacts::Type::IM;
use WWW::Google::Contacts::Type::Organization;
use WWW::Google::Contacts::Type::PostalAddress;
use WWW::Google::Contacts::Type::Birthday;
use WWW::Google::Contacts::Type::CalendarLink;

use WWW::Google::Contacts::Type::ContactEvent;
use WWW::Google::Contacts::Type::ExternalId;
use WWW::Google::Contacts::Type::Gender;
use WWW::Google::Contacts::Type::GroupMembership;
use WWW::Google::Contacts::Type::Hobby;
use WWW::Google::Contacts::Type::Jot;
use WWW::Google::Contacts::Type::Language;
use WWW::Google::Contacts::Type::Priority;
use WWW::Google::Contacts::Type::Relation;
use WWW::Google::Contacts::Type::UserDefined;
use WWW::Google::Contacts::Type::Website;
use WWW::Google::Contacts::Type::Sensitivity;

class_type Group, { class => 'WWW::Google::Contacts::Group' };

coerce Group, from HashRef, via {
    require WWW::Google::Contacts::Group;
    WWW::Google::Contacts::Group->new($_)
};

class_type Category, { class => 'WWW::Google::Contacts::Type::Category' };

coerce Category, from Any, via {
    WWW::Google::Contacts::Type::Category->new(
        type => 'http://schemas.google.com/g/2005#kind',
        term => 'http://schemas.google.com/contact/2008#contact'
    );
};

class_type Name, { class => 'WWW::Google::Contacts::Type::Name' };

coerce Name,
  from Str,
  via { WWW::Google::Contacts::Type::Name->new( full_name => $_ ) },
  from Any,
  via { WWW::Google::Contacts::Type::Name->new( $_ || {} ) };

class_type PhoneNumber, { class => 'WWW::Google::Contacts::Type::PhoneNumber' };

coerce PhoneNumber,
  from HashRef,
  via { WWW::Google::Contacts::Type::PhoneNumber->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::PhoneNumber->new( value => $_ ) };

subtype ArrayRefOfPhoneNumber, as ArrayRef [PhoneNumber];

coerce ArrayRefOfPhoneNumber, from ArrayRef, via {
    return [ map { to_PhoneNumber($_) } @{$_} ]
}, from Any, via { return [ to_PhoneNumber($_) ] };

class_type Email, { class => 'WWW::Google::Contacts::Type::Email' };

coerce Email,
  from HashRef,
  via { WWW::Google::Contacts::Type::Email->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::Email->new( value => $_ ) };

subtype ArrayRefOfEmail, as ArrayRef [Email];

coerce ArrayRefOfEmail, from ArrayRef, via {
    [ map { to_Email($_) } @{$_} ]
}, from Any, via { [ to_Email($_) ] };

class_type IM, { class => 'WWW::Google::Contacts::Type::IM' };

coerce IM,
  from HashRef,
  via { WWW::Google::Contacts::Type::IM->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::IM->new( value => $_ ) };

subtype ArrayRefOfIM, as ArrayRef [IM];

coerce ArrayRefOfIM, from ArrayRef, via {
    [ map { to_IM($_) } @{$_} ]
}, from Any, via { [ to_IM($_) ] };

class_type Organization,
  { class => 'WWW::Google::Contacts::Type::Organization' };

coerce Organization,
  from HashRef,
  via { WWW::Google::Contacts::Type::Organization->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::Organization->new( name => $_ ) };

subtype ArrayRefOfOrganization, as ArrayRef [Organization];

coerce ArrayRefOfOrganization, from ArrayRef, via {
    [ map { to_Organization($_) } @{$_} ]
}, from Any, via { [ to_Organization($_) ] };

class_type PostalAddress,
  { class => 'WWW::Google::Contacts::Type::PostalAddress' };

coerce PostalAddress,
  from HashRef,
  via { WWW::Google::Contacts::Type::PostalAddress->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::PostalAddress->new( formatted => $_ ) };

subtype ArrayRefOfPostalAddress, as ArrayRef [PostalAddress];

coerce ArrayRefOfPostalAddress, from ArrayRef, via {
    [ map { to_PostalAddress($_) } @{$_} ]
}, from Any, via { [ to_PostalAddress($_) ] };

class_type Birthday, { class => 'WWW::Google::Contacts::Type::Birthday' };

coerce Birthday,
  from Str,
  via { WWW::Google::Contacts::Type::Birthday->new( when => $_ ) },
  from HashRef,
  via { WWW::Google::Contacts::Type::Birthday->new($_) };

class_type CalendarLink,
  { class => 'WWW::Google::Contacts::Type::CalendarLink' };

coerce CalendarLink,
  from HashRef,
  via { WWW::Google::Contacts::Type::CalendarLink->new($_) }, from Str, via {
    WWW::Google::Contacts::Type::CalendarLink->new(
        type => "home",
        href => $_
      )
  };

subtype ArrayRefOfCalendarLink, as ArrayRef [CalendarLink];

coerce ArrayRefOfCalendarLink, from ArrayRef, via {
    [ map { to_CalendarLink($_) } @{$_} ]
}, from Any, via { [ to_CalendarLink($_) ] };

class_type ContactEvent,
  { class => 'WWW::Google::Contacts::Type::ContactEvent' };

coerce ContactEvent,
  from HashRef,
  via { WWW::Google::Contacts::Type::ContactEvent->new($_) };

subtype ArrayRefOfContactEvent, as ArrayRef [ContactEvent];

coerce ArrayRefOfContactEvent, from ArrayRef, via {
    [ map { to_ContactEvent($_) } @{$_} ]
}, from Any, via { [ to_ContactEvent($_) ] };

class_type ExternalId, { class => 'WWW::Google::Contacts::Type::ExternalId' };

coerce ExternalId,
  from HashRef,
  via { WWW::Google::Contacts::Type::ExternalId->new($_) };

subtype ArrayRefOfExternalId, as ArrayRef [ExternalId];

coerce ArrayRefOfExternalId, from ArrayRef, via {
    [ map { to_ExternalId($_) } @{$_} ]
}, from Any, via { [ to_ExternalId($_) ] };

class_type Gender, { class => 'WWW::Google::Contacts::Type::Gender' };

coerce Gender,
  from Str,
  via { WWW::Google::Contacts::Type::Gender->new( value => $_ ) },
  from HashRef,
  via { WWW::Google::Contacts::Type::Gender->new($_) };

class_type GroupMembership,
  { class => 'WWW::Google::Contacts::Type::GroupMembership' };

coerce GroupMembership,
  from HashRef,
  via { WWW::Google::Contacts::Type::GroupMembership->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::GroupMembership->new( href => $_ ) },
  from Group,
  via { WWW::Google::Contacts::Type::GroupMembership->new( href => $_->id ) };

subtype ArrayRefOfGroupMembership, as ArrayRef [GroupMembership];

coerce ArrayRefOfGroupMembership, from ArrayRef, via {
    [ map { to_GroupMembership($_) } @{$_} ]
}, from Any, via { [ to_GroupMembership($_) ] };

class_type Hobby, { class => 'WWW::Google::Contacts::Type::Hobby' };

coerce Hobby,
  from HashRef,
  via { WWW::Google::Contacts::Type::Hobby->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::Hobby->new( value => $_ ) };

subtype ArrayRefOfHobby, as ArrayRef [Hobby];

coerce ArrayRefOfHobby, from ArrayRef, via {
    [ map { to_Hobby($_) } @{$_} ]
}, from Any, via { [ to_Hobby($_) ] };

class_type Jot, { class => 'WWW::Google::Contacts::Type::Jot' };

coerce Jot,
  from HashRef,
  via { WWW::Google::Contacts::Type::Jot->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::Jot->new( type => "home", value => $_ ) };

subtype ArrayRefOfJot, as ArrayRef [Jot];

coerce ArrayRefOfJot, from ArrayRef, via {
    [ map { to_Jot($_) } @{$_} ]
}, from Any, via { [ to_Jot($_) ] };

class_type Language, { class => 'WWW::Google::Contacts::Type::Language' };

coerce Language,
  from HashRef,
  via { WWW::Google::Contacts::Type::Language->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::Language->new( value => $_ ) };

subtype ArrayRefOfLanguage, as ArrayRef [Language];

coerce ArrayRefOfLanguage, from ArrayRef, via {
    [ map { to_Language($_) } @{$_} ]
}, from Any, via { [ to_Language($_) ] };

class_type Priority, { class => 'WWW::Google::Contacts::Type::Priority' };

coerce Priority,
  from Str,
  via { WWW::Google::Contacts::Type::Priority->new( type => $_ ) },
  from Undef,
  via { WWW::Google::Contacts::Type::Priority->new( type => "normal" ) },
  from HashRef,
  via { WWW::Google::Contacts::Type::Priority->new( type => $_->{rel} ) };

class_type Relation, { class => 'WWW::Google::Contacts::Type::Relation' };

coerce Relation,
  from HashRef,
  via { WWW::Google::Contacts::Type::Relation->new($_) };

subtype ArrayRefOfRelation, as ArrayRef [Relation];

coerce ArrayRefOfRelation, from ArrayRef, via {
    [ map { to_Relation($_) } @{$_} ]
}, from Any, via { [ to_Relation($_) ] };

class_type UserDefined, { class => 'WWW::Google::Contacts::Type::UserDefined' };

coerce UserDefined,
  from HashRef,
  via { WWW::Google::Contacts::Type::UserDefined->new($_) };

subtype ArrayRefOfUserDefined, as ArrayRef [UserDefined];

coerce ArrayRefOfUserDefined, from ArrayRef, via {
    [ map { to_UserDefined($_) } @{$_} ]
}, from HashRef, via {
    my $ref = $_;
    return [ to_UserDefined($ref) ] if ( defined $ref->{key} );
    [ map { to_UserDefined( { key => $_, value => $ref->{$_}{value} } ) }
          keys %{$ref} ]
}, from Any, via { [ to_UserDefined($_) ] };

class_type Website, { class => 'WWW::Google::Contacts::Type::Website' };

coerce Website,
  from HashRef,
  via { WWW::Google::Contacts::Type::Website->new($_) }, from Str, via {
    WWW::Google::Contacts::Type::Website->new( type => "home", value => $_ )
  };

subtype ArrayRefOfWebsite, as ArrayRef [Website];

coerce ArrayRefOfWebsite, from ArrayRef, via {
    [ map { to_Website($_) } @{$_} ]
}, from Any, via { [ to_Website($_) ] };

class_type Sensitivity, { class => 'WWW::Google::Contacts::Type::Sensitivity' };

coerce Sensitivity,
  from HashRef,
  via { WWW::Google::Contacts::Type::Sensitivity->new($_) },
  from Str,
  via { WWW::Google::Contacts::Type::Sensitivity->new( type => $_ ) };

class_type Photo, { class => 'WWW::Google::Contacts::Photo' };

coerce Photo, from HashRef, via {
    require WWW::Google::Contacts::Photo;
    WWW::Google::Contacts::Photo->new($_)
};
