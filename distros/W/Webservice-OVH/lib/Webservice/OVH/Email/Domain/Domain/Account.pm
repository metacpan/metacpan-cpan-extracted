package Webservice::OVH::Email::Domain::Domain::Account;

=encoding utf-8

=head1 NAME

Webservice::OVH::Email::Domain::Domain::Account

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $email_domain = $ovh->email->domain->domain('testdomain.de');
    
    my $account = $email_domain->new_account( account_name => 'testaccount', password => $password, description => 'a test account', size => 50000000 );

=head1 DESCRIPTION

Provides access to email accounts.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.46;

use Webservice::OVH::Helper;

=head2 _new_existing

Internal Method to create an Account object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $domain - parent domain Objekt, $account_name => unique name

=item * Return: L<Webservice::OVH::Email::Domain::Domain::Account>

=item * Synopsis: Webservice::OVH::Email::Domain::Domain::Account->_new_existing($ovh_api_wrapper, $domain, $account_name, $module);

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};
    die "Missing domain"  unless $params{domain};

    my $module       = $params{module};
    my $api_wrapper  = $params{wrapper};
    my $account_name = $params{id};
    my $domain       = $params{domain};

    $account_name = lc $account_name;

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _name => $account_name, _properties => undef, _domain => $domain }, $class;

    return $self;

}

=head2 _new

Internal Method to create the Account object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $domain - parent domain, %params - key => value

=item * Return: L<Webservice::OVH::Email::Domain::Domain::Account>

=item * Synopsis: Webservice::OVH::Email::Domain::Domain::Account->_new($ovh_api_wrapper, $domain, $module, account_name => $account_name, password => $password, description => $description, size => $size  );

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing domain"  unless $params{domain};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $domain      = $params{domain};

    my @keys_needed = qw{ account_name password };
    if ( my @missing_parameters = grep { not $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $domain_name = $domain->name;
    my $body        = {};
    $body->{accountName} = Webservice::OVH::Helper->trim($params{account_name});
    $body->{password}    = $params{password};
    $body->{description} = $params{description} if exists $params{description};
    $body->{size}        = $params{size} if exists $params{size};
    my $response = $api_wrapper->rawCall( method => 'post', path => "/email/domain/$domain_name/account", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Account->_new_existing( wrapper => $api_wrapper, domain => $domain, id => $task_id, module => $module );

    my $self = bless { _module => $module, _valid => 1, _api_wrapper => $api_wrapper, _name => $params{account_name}, _properties => undef, _domain => $domain }, $class;

    return ( $self, $task );

}

=head2 is_valid

When this account is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $account->is_valid;

=back

=cut

sub is_valid {

    my ($self) = @_;

    $self->properties;

    return $self->{_valid};
}

=head2 name

Unique identifier.

=over

=item * Return: VALUE

=item * Synopsis: my $name = $account->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_name};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $account->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->{_valid};

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $response     = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account/$account_name", noSignature => 0 );
    carp $response->error if $response->error;

    if ( $response->error ) {

        $self->{_valid}      = 0;
        $self->{_properties} = undef;
        return;

    } else {

        $self->{_properties} = $response->content;
        return $self->{_properties};
    }

}

=head2 is_blocked

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $is_blocked = $account->is_blocked;

=back

=cut

sub is_blocked {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{isBlocked} ? 1 : 0;

}

=head2 email

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $email = $account->email;

=back

=cut

sub email {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{email};

}

=head2 domain

Returns the email-domain this account is attached to. 

=over

=item * Return: L<Webservice::Email::Domain::Domain>

=item * Synopsis: my $email_domain = $account->domain;

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

=head2 description

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $description = $account->description;

=back

=cut

sub description {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{description};
}

=head2 size

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $size = $account->size;

=back

=cut

sub size {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{size};
}

=head2 change

Changes the account

=over

=item * Parameter: %params - key => value description size

=item * Synopsis: $account->change(description => 'authors account', size => 2000000 );

=back

=cut

sub change {

    my ( $self, %params ) = @_;

    croak "Objet is invalid" unless $self->{_valid};

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $body         = {};
    $body->{description} = $params{description} if exists $params{description};
    $body->{size}        = $params{size}        if exists $params{size};
    my $response = $api->rawCall( method => 'put', path => "/email/domain/$domain_name/account/$account_name", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    $self->properties;

}

=head2 delete

Deletes the account api sided and sets this object invalid.

=over

=item * Synopsis: $account->delete;

=back

=cut

sub delete {

    my ( $self, %params ) = @_;

    croak "Objet is invalid" unless $self->{_valid};

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $response     = $api->rawCall( method => 'delete', path => "/email/domain/$domain_name/account/$account_name", noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Account->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    $self->{_valid} = 0;

    return $task;
}

=head2 delete

Deletes the account api sided and sets this object invalid.

=over

=item * Parameter: $password - new password

=item * Synopsis: $account->change_password($password);

=back

=cut

sub change_password {

    my ( $self, $password ) = @_;

    croak "Objet is invalid" unless $self->{_valid};

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $body         = { password => $password };
    my $response     = $api->rawCall( method => 'post', path => "/email/domain/$domain_name/account/$account_name/changePassword", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Account->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    return $task;

}

=head2 usage

Deletes the account api sided and sets this object invalid.

=over

=item * Return: HASH

=item * Synopsis: $account->usage;

=back

=cut

sub usage {

    my ($self) = @_;

    croak "Objet is invalid" unless $self->{_valid};

    my $api          = $self->{_api_wrapper};
    my $domain_name  = $self->domain->name;
    my $account_name = $self->name;
    my $response     = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account/$account_name/usage", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;

}

=head2 tasks

Get all associated tasks

=over

=item * Return: HASH

=item * Synopsis: $account->tasks;

=back

=cut

sub tasks {

    my ($self) = @_;

    croak "Objet is invalid" unless $self->{_valid};

    my $domain_name = $self->domain->name;
    my $api         = $self->{_api_wrapper};
    my $name        = $self->name;

    my $response = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/task/account?name=%s", $name ), noSignature => 0 );
    croak $response->error if $response->error;

    my $taks = $response->content || [];

    return unless scalar @$taks;

    return $taks;

}

1;
