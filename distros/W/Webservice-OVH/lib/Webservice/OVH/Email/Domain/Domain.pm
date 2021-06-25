package Webservice::OVH::Email::Domain::Domain;

=encoding utf-8

=head1 NAME

Webservice::OVH::Email::Domain::Domain

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $email_domain = $ovh->email->domain->domain('testdomain.de');

=head1 DESCRIPTION

Provides access to api email-domain methods like mailinglists, accounts and redirections.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.46;

use Webservice::OVH::Email::Domain::Domain::Redirection;
use Webservice::OVH::Email::Domain::Domain::Account;
use Webservice::OVH::Email::Domain::Domain::MailingList;
use Webservice::OVH::Email::Domain::Domain::Task;
use Webservice::OVH::Helper;

=head2 _new

Internal Method to create the domain object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Email::Domain>

=item * Synopsis: Webservice::OVH::Email::Domain->_new($ovh_api_wrapper, $zone_name, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    my $domain      = $params{id};

    croak "Missing domain name" unless $domain;

    my $self = bless {
        _module        => $module,
        _api_wrapper   => $api_wrapper,
        _name          => $domain,
        _service_infos => undef,
        _properties    => undef,
        _redirections  => {},
        _accounts      => {},
        _mailing_lists => {},
    }, $class;

    my $task = Webservice::OVH::Email::Domain::Domain::Task->_new( module => $module, wrapper => $api_wrapper, domain => $self );
    $self->{_task} = $task;

    return $self;
}

=head2 service_infos

Retrieves additional infos about the email-domain. 
Not part of the properties

=over

=item * Return: HASH

=item * Synopsis: my $info = $email_domain->service_infos;

=back

=cut

sub service_infos {

    my ($self) = @_;

    my $api                   = $self->{_api_wrapper};
    my $domain                = $self->name;
    my $response_service_info = $api->rawCall( method => 'get', path => "/email/domain/$domain/serviceInfos", noSignature => 0 );

    croak $response_service_info->error if $response_service_info->error;

    $self->{_service_infos} = $response_service_info->content;

    return $self->{_service_infos};
}

=head2 quota

Retrieves info about quotas. 
Not part of the properties

=over

=item * Return: HASH

=item * Synopsis: my $info = $email_domain->quota;

=back

=cut

sub quota {

    my ($self) = @_;

    my $api      = $self->{_api_wrapper};
    my $domain   = $self->name;
    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain/quota", noSignature => 0 );

    croak $response->error if $response->error;
    return $response->content;
}

=head2 name

Name is the unique identifier.

=over

=item * Return: VALUE

=item * Synopsis: my $name = $email_domain->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_name};
}

=head2 properties

Retrieves properties of the email-domain.
This method updates the intern property variable.

=over

=item * Return: HASH

=item * Synopsis: my $properties = $email_domain->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    my $api                 = $self->{_api_wrapper};
    my $domain              = $self->name;
    my $response_properties = $api->rawCall( method => 'get', path => "/email/domain/$domain", noSignature => 0 );
    croak $response_properties->error if $response_properties->error;

    $self->{_properties} = $response_properties->content;

    return $self->{_properties};
}

=head2 allowed_account_size

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $allowed_account_size = $email_domain->allowed_account_size;

=back

=cut

sub allowed_account_size {

    my ($self) = @_;

    return $self->{_properties}->{allowedAccountSize};
}

=head2 creation_date

Exposed Property Value. Readonly.

=over

=item * Return: DateTime

=item * Synopsis: my $creation_date = $email_domain->creation_date;

=back

=cut

sub creation_date {

    my ($self) = @_;

    my $str_datetime = $self->{_properties}->{creationDate};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);
    return $datetime;
}

=head2 filerz

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $filerz = $email_domain->filerz;

=back

=cut

sub filerz {

    my ($self) = @_;

    return $self->{_properties}->{filerz};
}

=head2 status

Exposed Property Value. Readonly.

=over

=item * Return: VALUE

=item * Synopsis: my $status = $email_domain->status;

=back

=cut

sub status {

    my ($self) = @_;

    return $self->{_properties}->{status};
}

sub redirections_count {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/redirection", noSignature => 0 );
    croak $response->error if $response->error;

    return scalar @{ $response->content };
}

=head2 redirections

Produces an array of all available redirections that are connected to the email-domain.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $redirections = $email_domain->redirections();

=back

=cut

sub redirections {

    my ( $self, %filter ) = @_;

    my $filter_from = ( exists $filter{from} && !$filter{from} ) ? "_empty_" : $filter{from};
    my $filter_to   = ( exists $filter{to}   && !$filter{to} )   ? "_empty_" : $filter{to};
    my $filter = Webservice::OVH::Helper->construct_filter( "from" => $filter_from, "to" => $filter_to );

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/redirection%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    my $redirection_ids = $response->content;
    my $redirections    = [];

    foreach my $redirection_id (@$redirection_ids) {

        my $redirection = $self->{_redirections}{$redirection_id} = $self->{_redirections}{$redirection_id} || Webservice::OVH::Email::Domain::Domain::Redirection->_new_existing( wrapper => $api, domain => $self, id => $redirection_id, module => $self->{_module} );
        push @$redirections, $redirection;
    }

    return $redirections;
}

sub redirection_exists {

    my ( $self, $redirection_id ) = @_;

    croak "Missing redirection_id" unless $redirection_id;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/redirection/$redirection_id", noSignature => 0 );

    return $response->error ? 0 : 1;
}

=head2 redirection

Returns a single redirection by id

=over

=item * Parameter: $redirection_id - id

=item * Return: L<Webservice::OVH::Email::Domain::Domain::Redirection>

=item * Synopsis: my $service = $email_domain->redirection(12345);

=back

=cut

sub redirection {

    my ( $self, $redirection_id ) = @_;

    croak "Missing redirection_id" unless $redirection_id;

    if ( $self->redirection_exists($redirection_id) ) {

        my $api                    = $self->{_api_wrapper};
        my $from_array_redirection = $self->{_redirections}{$redirection_id} if $self->{_redirections}{$redirection_id} && $self->{_redirections}{$redirection_id}->is_valid;
        my $redirection            = $self->{_redirections}{$redirection_id} = $from_array_redirection || Webservice::OVH::Email::Domain::Domain::Redirection->_new_existing( wrapper => $api, domain => $self, id => $redirection_id, module => $self->{_module} );

        return $redirection;

    } else {

        return undef;
    }
}

=head2 new_redirection

Creates a new redirection.

=over

=item * Parameter:  %params - key => value from to local_copy

=item * Return: L<Webservice::Email::Domain::Domain::Redirection>

=item * Synopsis: my $redirection = $email_domain->new_redirection(from => 'test@test.de', to => 'test2@test.de', local_copy => 'false');

=back

=cut

sub new_redirection {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my $redirection = Webservice::OVH::Email::Domain::Domain::Redirection->_new( wrapper => $api, domain => $self, module => $self->{_module}, %params );

    return $redirection;
}

sub accounts_count {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account", noSignature => 0 );
    croak $response->error if $response->error;

    return scalar @{ $response->content };
}

=head2 accounts

Produces an array of all available accounts that are connected to the email-domain.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $accounts = $email_domain->accounts();

=back

=cut

sub accounts {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account", noSignature => 0 );
    croak $response->error if $response->error;

    my $account_names = $response->content;
    my $accounts      = [];

    foreach my $account_name (@$account_names) {
        my $account = $self->{_accounts}{$account_name} = $self->{_accounts}{$account_name} || Webservice::OVH::Email::Domain::Domain::Account->_new_existing( wrapper => $api, domain => $self, id => $account_name, module => $self->{_module} );
        push @$accounts, $account;
    }

    return $accounts;
}

sub account_exists {

    my ( $self, $account_name ) = @_;

    croak "Missing account_name" unless $account_name;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/account/$account_name", noSignature => 0 );

    return $response->error ? 0 : 1;
}

=head2 account

Returns a single account by name

=over

=item * Parameter: $account_name - name

=item * Return: L<Webservice::OVH::Email::Domain::Domain::Account>

=item * Synopsis: my $account = $email_domain->account('testaccount');

=back

=cut

sub account {

    my ( $self, $account_name ) = @_;

    croak "Missing account_name" unless $account_name;

    $account_name = lc $account_name;

    if ( $self->account_exists($account_name) ) {

        my $api                = $self->{_api_wrapper};
        my $from_array_account = $self->{_accounts}{$account_name} if $self->{_accounts}{$account_name} && $self->{_accounts}{$account_name}->is_valid;
        my $account            = $self->{_accounts}{$account_name} = $from_array_account || Webservice::OVH::Email::Domain::Domain::Account->_new_existing( wrapper => $api, domain => $self, id => $account_name, module => $self->{_module} );

        return $account;

    } else {

        return undef;
    }
}

=head2 new_account

Creates a new account.

=over

=item * Parameter:  %params - key => value account_name password description size

=item * Return: L<Webservice::Email::Domain::Domain::Account>

=item * Synopsis: my $account = $email_domain->new_account(account_name => 'testaccount', password => $password, description => 'a test account', size => 5000000 );

=back

=cut

sub new_account {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my ( $account, $task ) = Webservice::OVH::Email::Domain::Domain::Account->_new( wrapper => $api, domain => $self, module => $self->{_module}, %params );

    return ( $account, $task );
}

sub mailing_lists_count {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList", noSignature => 0 );
    croak $response->error if $response->error;

    return scalar @{ $response->content };
}

sub mailing_lists_names {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 mailing_lists

Produces an array of all available mailing_lists that are connected to the email-domain.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $mailing_lists = $email_domain->mailing_lists();

=back

=cut

sub mailing_lists {

    my ($self) = @_;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;
    my $response    = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList", noSignature => 0 );
    croak $response->error if $response->error;

    my $mailing_list_names = $response->content;
    my $mailing_lists      = [];

    foreach my $mailing_list_name (@$mailing_list_names) {

        my $mailing_list = $self->{_mailing_lists}{$mailing_list_name} = $self->{_mailing_lists}{$mailing_list_name} || Webservice::OVH::Email::Domain::Domain::MailingList->_new_existing( wrapper => $api, domain => $self, id => $mailing_list_name, module => $self->{_module} );
        push @$mailing_lists, $mailing_list;
    }

    return $mailing_lists;
}

sub mailinglist_exists {

    my ( $self, $mailinglist_name ) = @_;

    croak "Missing mailinglist_name" unless $mailinglist_name;

    my $api         = $self->{_api_wrapper};
    my $domain_name = $self->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList/$mailinglist_name", noSignature => 0 );

    return $response->error ? 0 : 1;
}

=head2 mailing_list

Returns a single account by name

=over

=item * Parameter: $mailing_list_name - name

=item * Return: L<Webservice::OVH::Email::Domain::Domain::MailingList>

=item * Synopsis: my $mailing_list = $email_domain->mailing_list('subscriber_list');

=back

=cut

sub mailing_list {

    my ( $self, $mailing_list_name ) = @_;

    croak "Missing mailing_list_name" unless $mailing_list_name;

    if ( $self->mailinglist_exists($mailing_list_name) ) {

        my $api                     = $self->{_api_wrapper};
        my $from_array_mailing_list = $self->{_mailing_lists}{$mailing_list_name} if $self->{_mailing_lists}{$mailing_list_name} && $self->{_mailing_lists}{$mailing_list_name}->is_valid;
        my $mailing_list            = $self->{_mailing_lists}{$mailing_list_name} = $from_array_mailing_list || Webservice::OVH::Email::Domain::Domain::MailingList->_new_existing( wrapper => $api, domain => $self, id => $mailing_list_name, module => $self->{_module} );

        return $mailing_list;

    } else {

        return undef;
    }
}

=head2 new_mailing_list

Creates a new mailing list.

=over

=item * Parameter:  %params - key => value language name options owner_email reply_to

=item * Return: L<Webservice::Email::Domain::Domain::MailingList>

=item * Synopsis: my $mailing_list = $email_domain->new_mailing_list(language 'DE', name => 'infos', options => {}, owner_email => 'owner@test.de', reply_to => 'test@test.de' );

=back

=cut

sub new_mailing_list {

    my ( $self, %params ) = @_;

    my $api = $self->{_api_wrapper};
    my ( $mailing_list, $task ) = Webservice::OVH::Email::Domain::Domain::MailingList->_new( wrapper => $api, domain => $self, module => $self->{_module}, %params );

    return ( $mailing_list, $task );
}

sub task {

    my ($self) = @_;

    return $self->{_task};
}

1;
