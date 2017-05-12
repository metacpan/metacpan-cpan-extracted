package WWW::Google::Contacts::Contact;
{
    $WWW::Google::Contacts::Contact::VERSION = '0.39';
}

use Moose;
use MooseX::Types::Moose qw( Str );
use WWW::Google::Contacts::Types qw(
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
);
use WWW::Google::Contacts::Meta::Attribute::Trait::XmlField;
use Carp;

sub create_url {
    my $self = shift;
    return sprintf( "%s://www.google.com/m8/feeds/contacts/default/full",
        $self->server->protocol );
}

extends 'WWW::Google::Contacts::Base';

with 'WWW::Google::Contacts::Roles::CRUD';

has id => (
    isa       => Str,
    is        => 'ro',
    writer    => '_set_id',
    predicate => 'has_id',
    traits    => ['XmlField'],
    xml_key   => 'id',
);

has etag => (
    isa            => Str,
    is             => 'ro',
    writer         => '_set_etag',
    predicate      => 'has_etag',
    traits         => ['XmlField'],
    xml_key        => 'gd:etag',
    include_in_xml => sub { 0 },      # This is set in HTTP headers
);

has link => (
    is             => 'rw',
    trigger        => \&_set_link,
    traits         => ['XmlField'],
    xml_key        => 'link',
    include_in_xml => sub { 0 },
);

# What to do with different link types
my $link_map = {
    'self' => sub { my ( $self, $link ) = @_; $self->_set_id( $link->{href} ) },
    'http://schemas.google.com/contacts/2008/rel#photo' => sub {
        my ( $self, $link ) = @_;
        $self->photo( { %$link, server => $self->server } );
    },
};

sub _set_link {
    my ( $self, $links ) = @_;
    foreach my $link ( @{$links} ) {
        next unless ( defined $link_map->{ $link->{rel} } );
        my $code = $link_map->{ $link->{rel} };
        $self->$code($link);
    }
}

has photo => (
    isa    => Photo,
    is     => 'rw',
    coerce => 1,
);

has category => (
    isa       => Category,
    is        => 'rw',
    predicate => 'has_category',
    traits    => ['XmlField'],
    xml_key   => 'category',
    default   => sub { undef },
    coerce    => 1,
);

has notes => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_notes',
    traits     => ['XmlField'],
    xml_key    => 'content',
    is_element => 1,
);

has name => (
    isa       => Name,
    is        => 'rw',
    predicate => 'has_name',
    traits    => ['XmlField'],
    xml_key   => 'gd:name',
    handles   => [
        qw( given_name additional_name family_name
          name_prefix name_suffix full_name )
    ],
    default => sub { undef },    # empty Name object, so handles will work
    coerce  => 1,
);

has phone_number => (
    isa       => ArrayRefOfPhoneNumber,
    is        => 'rw',
    predicate => 'has_phone_number',
    traits    => ['XmlField'],
    xml_key   => 'gd:phoneNumber',
    coerce    => 1,
);

has email => (
    isa       => ArrayRefOfEmail,
    is        => 'rw',
    predicate => 'has_email',
    traits    => ['XmlField'],
    xml_key   => 'gd:email',
    coerce    => 1,
);

has im => (
    isa       => ArrayRefOfIM,
    is        => 'rw',
    predicate => 'has_im',
    traits    => ['XmlField'],
    xml_key   => 'gd:im',
    coerce    => 1,
);

has organization => (
    isa       => ArrayRefOfOrganization,
    is        => 'rw',
    predicate => 'has_organization',
    traits    => ['XmlField'],
    xml_key   => 'gd:organization',
    coerce    => 1,
);

has postal_address => (
    isa       => ArrayRefOfPostalAddress,
    is        => 'rw',
    predicate => 'has_postal_address',
    traits    => ['XmlField'],
    xml_key   => 'gd:structuredPostalAddress',
    coerce    => 1,
);

has billing_information => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_billing_information',
    traits     => ['XmlField'],
    xml_key    => 'gContact:billingInformation',
    is_element => 1,
);

has birthday => (
    isa        => Birthday,
    is         => 'rw',
    predicate  => 'has_birthday',
    traits     => ['XmlField'],
    xml_key    => 'gContact:birthday',
    is_element => 1,
    coerce     => 1,
);

has calendar_link => (
    isa       => ArrayRefOfCalendarLink,
    is        => 'rw',
    predicate => 'has_calendar_link',
    traits    => ['XmlField'],
    xml_key   => 'gContact:calendarLink',
    coerce    => 1,
);

has directory_server => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_directory_server',
    traits     => ['XmlField'],
    xml_key    => 'gContact:directoryServer',
    is_element => 1,
);

has event => (
    isa       => ArrayRefOfContactEvent,
    is        => 'rw',
    predicate => 'has_event',
    traits    => ['XmlField'],
    xml_key   => 'gContact:event',
    coerce    => 1,
);

has external_id => (
    isa       => ArrayRefOfExternalId,
    is        => 'rw',
    predicate => 'has_external_id',
    traits    => ['XmlField'],
    xml_key   => 'gContact:excternalId',
    coerce    => 1,
);

has gender => (
    isa       => Gender,
    is        => 'rw',
    predicate => 'has_gender',
    traits    => ['XmlField'],
    xml_key   => 'gContact:gender',
    coerce    => 1,
);

has group_membership => (
    isa       => ArrayRefOfGroupMembership,
    is        => 'rw',
    predicate => 'has_group_membership',
    traits    => ['XmlField'],
    xml_key   => 'gContact:groupMembershipInfo',
    coerce    => 1,
);

has hobby => (
    isa       => ArrayRefOfHobby,
    is        => 'rw',
    predicate => 'has_hobby',
    traits    => ['XmlField'],
    xml_key   => 'gContact:hobby',
    coerce    => 1,
);

has initials => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_initials',
    traits     => ['XmlField'],
    xml_key    => 'gContact:initials',
    is_element => 1,
);

has jot => (
    isa       => ArrayRefOfJot,
    is        => 'rw',
    predicate => 'has_jot',
    traits    => ['XmlField'],
    xml_key   => 'gContact:jot',
    coerce    => 1,
);

has language => (
    isa       => ArrayRefOfLanguage,
    is        => 'rw',
    predicate => 'has_language',
    traits    => ['XmlField'],
    xml_key   => 'gContact:language',
    coerce    => 1,
);

has maiden_name => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_maiden_name',
    traits     => ['XmlField'],
    xml_key    => 'gContact:maidenName',
    is_element => 1,
);

has mileage => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_mileage',
    traits     => ['XmlField'],
    xml_key    => 'gContact:mileage',
    is_element => 1,
);

has nickname => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_nickname',
    traits     => ['XmlField'],
    xml_key    => 'gContact:nickname',
    is_element => 1,
);

has occupation => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_occupation',
    traits     => ['XmlField'],
    xml_key    => 'gContact:occupation',
    is_element => 1,
);

has priority => (
    isa       => Priority,
    is        => 'rw',
    predicate => 'has_priority',
    traits    => ['XmlField'],
    xml_key   => 'gContact:priority',
    coerce    => 1,
);

has relation => (
    isa       => ArrayRefOfRelation,
    is        => 'rw',
    predicate => 'has_relation',
    traits    => ['XmlField'],
    xml_key   => 'gContact:relation',
    coerce    => 1,
);

has sensitivity => (
    isa        => Sensitivity,
    is         => 'rw',
    predicate  => 'has_sensitivity',
    traits     => ['XmlField'],
    xml_key    => 'gContact:sensitivity',
    is_element => 1,
    coerce     => 1,
);

has shortname => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_shortname',
    traits     => ['XmlField'],
    xml_key    => 'gContact:shortname',
    is_element => 1,
);

has subject => (
    isa        => Str,
    is         => 'rw',
    predicate  => 'has_subject',
    traits     => ['XmlField'],
    xml_key    => 'gContact:subject',
    is_element => 1,
);

has user_defined => (
    isa       => ArrayRefOfUserDefined,
    is        => 'rw',
    predicate => 'has_user_defined',
    traits    => ['XmlField'],
    xml_key   => 'gContact:userDefinedField',
    coerce    => 1,
);

has website => (
    isa       => ArrayRefOfWebsite,
    is        => 'rw',
    predicate => 'has_website',
    traits    => ['XmlField'],
    xml_key   => 'gContact:website',
    coerce    => 1,
);

# Stolen from Meta/Attribute/Native/MethodProvider/Array.pm, need coercion
sub add_phone_number {
    my ( $self, $phone ) = @_;
    $self->phone_number( [] ) unless $self->has_phone_number;
    push @{ $self->phone_number }, to_PhoneNumber($phone);
}

sub add_email {
    my ( $self, $email ) = @_;
    $self->email( [] ) unless $self->has_email;
    push @{ $self->email }, to_Email($email);
}

sub add_user_defined {
    my ( $self, $user_def ) = @_;
    $self->user_defined( [] ) unless $self->has_user_defined;
    push @{ $self->user_defined }, to_UserDefined($user_def);
}

sub add_event {
    my ( $self, $event ) = @_;
    $self->event( [] ) unless $self->has_event;
    push @{ $self->event }, to_ContactEvent($event);
}

sub add_website {
    my ( $self, $website ) = @_;
    $self->website( [] ) unless $self->has_website;
    push @{ $self->website }, to_Website($website);
}

sub add_relation {
    my ( $self, $relation ) = @_;
    $self->relation( [] ) unless $self->has_relation;
    push @{ $self->relation }, to_Relation($relation);
}

sub add_group_membership {
    my ( $self, $group ) = @_;
    $self->group_membership( [] ) unless $self->has_group_membership;
    if ( not ref($group) and $group !~ m{^http} ) {

# It's probably a group name.
# As it stands right now, can't deal with this in the coercion, need access to server obj
        my @groups =
          WWW::Google::Contacts::GroupList->new( server => $self->server )
          ->search( { title => $group } );
        if ( scalar @groups == 0 ) {
            croak "Can not find a group with name: $group";
        }
        elsif ( scalar @groups > 1 ) {
            croak
"Can not add group membership. Found several groups with group name: $group";
        }
        $group = shift @groups;
    }
    push @{ $self->group_membership }, to_GroupMembership($group);
}

sub groups {
    my $self = shift;

    my $to_ret = [];
    my $membership = $self->group_membership || [];
    foreach my $member ( @{$membership} ) {
        push @{$to_ret},
          WWW::Google::Contacts::Group->new(
            id     => $member->href,
            server => $self->server
          )->retrieve;
    }
    return wantarray ? @{$to_ret} : $to_ret;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 SYNOPSIS

    use WWW::Google::Contacts;

    my $google = WWW::Google::Contacts->new( username => "your.username", password => "your.password" );

    my $contact = $google->new_contact;
    $contact->full_name("Emmett Brown");

A lot of fields, such as email, phone number and so on, are accessible as array refs.

    foreach my $email (@{ $contact->email }) {
       print "He got email address: " . $email->value . "\n";
    }

When you have made changes to your contact, you need to save them back to Google. This is done either
by a B<create> call (for new contacts) or an B<update> call (for existing contacts).

    $contact->create;

Alternatively, you can use the B<create_or_update> method, which will do the right thing.

    $contact->create_or_update;


=head1 METHODS

=head2 $contact->create

Writes the contact to your Google account.

=head2 $contact->retrieve

Fetches contact details from Google account.

=head2 $contact->update

Updates existing contact in your Google account.

=head2 $contact->delete

Deletes contact from your Google account.

=head2 $contact->create_or_update

Creates or updates contact, depending on if it already exists.

=head1 ATTRIBUTES

All these attributes are gettable and settable on Contact objects.

=head2 given_name

 $contact->given_name("Arnold");

=head2 additional_name

 $contact->additional_name("J");

=head2 family_name

 $contact->family_name("Rimmer");

=head2 name_prefix

 $contact->name_prefix("Mrs");

=head2 name_suffix

 $contact->name_suffix("III");

=head2 full_name

If this is set to what seems like "$given_name $family_name", those attributes will be automatically set.

=head2 email

$contact->email is, if defined, an array reference with 1 or more Email objects.
The Email objects have the following accessors;

=over 4

=item type

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

=item label

If you don't want to use the predefined types (defined by Google) you can set this label instead.

=item value

The email address.

=item display_name

An optional display name.

=item primary

A boolean stating whether this is the primary email address.

=back

Example code (set the first work email as the primary address):

 foreach my $email (@{ $contact->email }) {
   if ( $email->type->name eq 'work' ) {
     $email->primary(1);
     last;
   }
 }


Explicitly setting all email details:

 $contact->email({
   type => "work",
   value => 'shenanigans@example.com',
   display_name => 'Shenanigans',
   primary => 1,
 });

Note that this will overwrite any previous email addresses for the contact. To add rather than replace,
see I<add_email> below.

If you're just setting the email value, type will default to "work" and leave other fields empty.

 $contact->email( 'smeghead@reddwarf.net' );

To specify several email addresses, you could either;

=over 4

=item * provide them all in an array

 $contact->email([
    { type => "work", value => 'underpaid@bigcompany.com' },
    { type => "home", value => 'angryblogger@someblogsite.com' },
 ]);

=item * call add_email

 $contact->add_email( 'homer@simpson.name' );

=back

=head2 phone_number

$contact->phone_number is, if defined, an array reference with 1 or more PhoneNumber objects.
The PhoneNumber objects have the following accessors;

=over 4

=item type

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

=item label

If you don't want to use the predefined types (defined by Google) you can set this label instead.

=item value

The phone number

=back


Explicitly setting all phone details:

 $contact->phone_number({
   type => "mobile",
   value => "+449812323",
 });

Just setting the value will set type to default value "mobile".

 $contact->phone_number( "+1666666" );

To specify several phone numbers, you could either;

=over 4

=item * provide them all in an array

 $contact->phone_number([
    { type => "mobile", value => "12345" },
    { type => "home", value => "666" },
 ]);

=item * call add_phone_number

 $contact->add_phone_number({
    type => "home",
    value => "02078712345"
 });

=back

=head2 im (Instant Messaging)

$contact->im is, if defined, an array reference with 1 or more IM objects.
The IM objects have the following accessors;

=over 4

=item type

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

=item label

If you don't want to use the predefined types (defined by Google) you can set this label instead.

=item protocol

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

Which protocol is used for this IM address. Possible name values include AIM, MSN, YAHOO. SKYPE, QQ, GOOGLE_TALK, ICQ, JABBER.

=item value

Email address for the IM account.

=back

You can specify all IM details:

 $contact->im({
   type => "home",
   protocol => "MSN",
   value => 'some.email@example.com',
 });

Or you can just choose to give the IM address:

 $contact->im( 'some.email@example.com' );

=head2 organization

$contact->organization is, if defined, an array reference with 1 or more Organization objects.
The Organization objects have the following accessors;

=over 4

=item type

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

=item label

If you don't want to use the predefined types (defined by Google) you can set this label instead.

=item department

Specifies a department within the organization.

=item job_description

Description of a job within the organization.

=item name

The name of the organization.

=item symbol

Symbol of the organization.

=item title

The title of a person within the organization.

=item primary

Boolean. When multiple organizations extensions appear in a contact kind, indicates which is primary. At most one organization may be primary.

=item where

A place associated with the organization, e.g. office location.

=back

=head2 postal_address

$contact->postal_address is, if defined, an array reference with 1 or more PostalAddress objects.
The PostalAddress objects have the following accessors;

=over 4

=item type

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

=item label

If you don't want to use the predefined types (defined by Google) you can set this label instead.

=item mail_class

This is an object in itself, which has 2 accessors; B<name> and B<uri>.

Classes of mail accepted at the address. Possible name values are I<both>, I<letters>, I<parcels> and I<neither>. Unless specified I<both> is assumed.

=item usage

This is an object in itself, which has 2 accessors; B<name> and B<uri>

The context in which this addess can be used. Possible values are I<general> and I<local>. Local addresses may differ in layout from general addresses, and frequently use local script (as opposed to Latin script) as well, though local script is allowed in general addresses. Unless specified general usage is assumed.

=item primary

Boolean. Specifies the address as primary.

=item agent

The agent who actually receives the mail. Used in work addresses. Also for 'in care of' or 'c/o'.

=item house_name

Used in places where houses or buildings have names (and not necessarily numbers), eg. "The Pillars".

=item street

Can be street, avenue, road, etc. This element also includes the house number and room/apartment/flat/floor number.

=item pobox

Covers actual P.O. boxes, drawers, locked bags, etc. This is usually but not always mutually exclusive with street.

=item neighborhood

This is used to disambiguate a street address when a city contains more than one street with the same name, or to specify a small place whose mail is routed through a larger postal town. In China it could be a county or a minor city.

=item city

Can be city, village, town, borough, etc. This is the postal town and not necessarily the place of residence or place of business.

=item subregion

Handles administrative districts such as U.S. or U.K. counties that are not used for mail addressing purposes. Subregion is not intended for delivery addresses.

=item region

A state, province, county (in Ireland), Land (in Germany), departement (in France), etc.

=item postcode

Postal code. Usually country-wide, but sometimes specific to the city (e.g. "2" in "Dublin 2, Ireland" addresses).

=item country

An object with two accessors; B<name> and B<code>.

=item formatted

The full, unstructured postal address.

=back

=head2 billing_information

Specifies billing information of the entity represented by the contact.

=head2 notes

Arbitrary notes about your friend.

 $contact->notes( "He's a lumberjack, but he's ok" );

=head2 birthday

If defined, returns an object with one accessor;

=over 4

=item when

Birthday date, given in format YYYY-MM-DD (with the year), or --MM-DD (without the year).

=back

=head2 ...tba

Sorry, haven't documented all attributes yet :(

=head1 INTERACTION WITH GROUPS

Contacts can belong to 0 or more groups. This section describes how to get and set group memberships.

=head2 $contact->groups

Returns an array reference of all groups, as L<WWW::Google::Contacts::Group> objects.

=head2 $contact->add_group_membership( group )

The I<group> argument can either be:

=over 4

=item An L<WWW::Google::Contacts::Group> object

=item The ID of a group, as a URL

=item The name of a group

=back

Do note that the group has to exist on the Google servers before you can add this membership.

=head1 AUTHOR

 Magnus Erixzon <magnus@erixzon.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Magnus Erixzon.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
