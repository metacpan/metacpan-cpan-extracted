package Webservice::OVH::Me::Contact;

=encoding utf-8

=head1 NAME

Webservice::OVH::Me::Contact

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $contacts = $ovh->me->contacts;
    
    foreach my $contact (@$contact) {
        
        print $contact->birth_city;
    }

=head1 DESCRIPTION

Propvides access to contact properties.
No managing methods are available at the moment.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.43;

=head2 _new_existing

Internal Method to create the Contact object.
This method is not ment to be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $contact_id - api id

=item * Return: L<Webservice::OVH::Me::Contact>

=item * Synopsis: Webservice::OVH::Me::Contact->_new($ovh_api_wrapper, $contact_id, $module);

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;
    
    die "Missing module"    unless $params{module};
    die "Missing wrapper"   unless $params{wrapper};
    die "Missing id"        unless $params{id};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $contact_id     = $params{id};

    my $response = $api_wrapper->rawCall( method => 'get', path => "/me/contact/$contact_id", noSignature => 0 );
    croak $response->error if $response->error;

    my $id         = $response->content->{id};
    my $porperties = $response->content;

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _id => $id, _properties => $porperties }, $class;

    return $self;
}

=head2 id

Returns the api id.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $contact->id;

=back

=cut

sub id {

    my ($self) = @_;

    return $self->{_id};
}

=head2 properties

Retrieves properties.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $contact->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api        = $self->{_api_wrapper};
    my $contact_id = $self->{_id};
    my $response   = $api->rawCall( method => 'get', path => "/me/contact/$contact_id", noSignature => 0 );
    croak $response->error if $response->error;
    $self->{_properties} = $response->content;

    return $self->{_properties};
}

=head2 address

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $address = $contact->address;

=back

=cut

sub address {

    my ($self) = @_;

    return $self->{_properties}->{address};
}

=head2 birth_city

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $birth_city = $contact->birth_city;

=back

=cut

sub birth_city {

    my ($self) = @_;

    return $self->{_properties}->{birthCity};
}

=head2 birth_country

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $birth_country = $contact->birth_country;

=back

=cut

sub birth_country {

    my ($self) = @_;

    return $self->{_properties}->{birthCountry};
}

=head2 birth_day

Exposed property value. 

=over

=item * Return: DateTime

=item * Synopsis: my $birth_day = $contact->birth_day;

=back

=cut

sub birth_day {

    my ($self) = @_;

    my $str_datetime = $self->{_properties}->{birthDay} . "T00:00:00+0000";
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 birth_zip

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $birth_zip = $contact->birth_zip;

=back

=cut

sub birth_zip {

    my ($self) = @_;

    return $self->{_properties}->{birthZip};
}

=head2 cell_phone

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $cell_phone = $contact->cell_phone;

=back

=cut

sub cell_phone {

    my ($self) = @_;

    return $self->{_properties}->{cellPhone};
}

=head2 company_national_identification_number

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $company_national_identification_number = $contact->company_national_identification_number;

=back

=cut

sub company_national_identification_number {

    my ($self) = @_;

    return $self->{_properties}->{companyNationalIdentificationNumber};
}

=head2 email

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $email = $contact->email;

=back

=cut

sub email {

    my ($self) = @_;

    return $self->{_properties}->{email};
}

=head2 fax

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $fax = $contact->fax;

=back

=cut

sub fax {

    my ($self) = @_;

    return $self->{_properties}->{fax};
}

=head2 first_name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $first_name = $contact->first_name;

=back

=cut

sub first_name {

    my ($self) = @_;

    return $self->{_properties}->{firstName};
}

=head2 gender

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $gender = $contact->gender;

=back

=cut

sub gender {

    my ($self) = @_;

    return $self->{_properties}->{gender};
}

=head2 language

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $language = $contact->language;

=back

=cut

sub language {

    my ($self) = @_;

    return $self->{_properties}->{language};
}

=head2 last_name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $last_name = $contact->last_name;

=back

=cut

sub last_name {

    my ($self) = @_;

    return $self->{_properties}->{lastName};
}

=head2 legal_form

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $legal_form = $contact->legal_form;

=back

=cut

sub legal_form {

    my ($self) = @_;

    return $self->{_properties}->{legalForm};
}

=head2 national_identification_number

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $national_identification_number = $contact->national_identification_number;

=back

=cut

sub national_identification_number {

    my ($self) = @_;

    return $self->{_properties}->{nationalIdentificationNumber};
}

=head2 nationality

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $nationality = $contact->nationality;

=back

=cut

sub nationality {

    my ($self) = @_;

    return $self->{_properties}->{nationality};
}

=head2 organisation_name

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $organisation_name = $contact->organisation_name;

=back

=cut

sub organisation_name {

    my ($self) = @_;

    return $self->{_properties}->{organisationName};
}

=head2 organisation_type

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $organisation_type = $contact->organisation_type;

=back

=cut

sub organisation_type {

    my ($self) = @_;

    return $self->{_properties}->{organisationType};
}

=head2 phone

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $phone = $contact->phone;

=back

=cut

sub phone {

    my ($self) = @_;

    return $self->{_properties}->{phone};
}

=head2 vat

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $vat = $contact->vat;

=back

=cut

sub vat {

    my ($self) = @_;

    return $self->{_properties}->{vat};
}

1;
