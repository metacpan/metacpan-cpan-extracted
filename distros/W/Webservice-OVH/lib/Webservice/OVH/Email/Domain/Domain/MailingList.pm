package Webservice::OVH::Email::Domain::Domain::MailingList;

=encoding utf-8

=head1 NAME

Webservice::OVH::Email::Domain::Domain::MailingList

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $email_domain = $ovh->email->domain->domain('testdomain.de');
    
    my $mailing_list = $email_domain->new_redirection(language 'de', name => 'infos', options => {moderatorMessage => 'true', subscribeByModerator => 'true', usersPostOnly => 'false'}, owner_email => 'owner@test.de' );

=head1 DESCRIPTION

Provides ability to create, delete, change and manage mailinglists.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };
use JSON;

our $VERSION = 0.47;

use Webservice::OVH::Helper;
use Webservice::OVH::Email::Domain::Domain::Task;

=head2 _new_existing

Internal Method to create a MailingList object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $domain - parent domain Objekt, $mailing_list_name => unique name

=item * Return: L<Webservice::OVH::Email::Domain::Domain::MailingList>

=item * Synopsis: Webservice::OVH::Email::Domain::Domain::MailingList->_new_existing($ovh_api_wrapper, $domain, $mailing_list_name, $module);

=back

=cut

sub _new_existing {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    die "Missing id"      unless $params{id};
    die "Missing domain"  unless $params{domain};

    my $module            = $params{module};
    my $api_wrapper       = $params{wrapper};
    my $mailing_list_name = $params{id};
    my $domain            = $params{domain};

    die "Missing mailing_list_name" unless $mailing_list_name;

    my $self = bless { _valid => 1, _api_wrapper => $api_wrapper, _name => $mailing_list_name, _properties => undef, _domain => $domain, _module => $module }, $class;

    return $self;
}

=head2 _new

Internal Method to create the MailingList object.
This method should never be called directly.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object, $domain - parent domain, %params - key => value

=item * Return: L<Webservice::OVH::Email::Domain::Domain::MailingList>

=item * Synopsis: Webservice::OVH::Email::Domain::Domain::MailingList->_new($ovh_api_wrapper, $domain, $module, language 'DE', name => 'infos', options => {}, owner_email => 'owner@test.de', reply_to => 'test@test.de' );

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

    my @keys_needed = qw{ language name options owner_email };

    die "Missing domain" unless $domain;

    if ( my @missing_parameters = grep { not exists $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $moderator_message      = $params{options}{moderator_message}      || $params{options}{moderatorMessage};
    my $subscribe_by_moderator = $params{options}{subscribe_by_moderator} || $params{options}{subscribeByModerator};
    my $users_post_only        = $params{options}{users_post_only}        || $params{options}{usersPostOnly};

    my $options = {};
    $options->{moderatorMessage}     = $moderator_message eq 'true'      || $moderator_message eq 'yes'      || $moderator_message eq '1'      ? JSON::true : JSON::false;
    $options->{subscribeByModerator} = $subscribe_by_moderator eq 'true' || $subscribe_by_moderator eq 'yes' || $subscribe_by_moderator eq '1' ? JSON::true : JSON::false;
    $options->{usersPostOnly}        = $users_post_only eq 'true'        || $users_post_only eq 'yes'        || $users_post_only eq '1'        ? JSON::true : JSON::false;

    my $domain_name = $domain->name;
    my $body        = {};
    $body->{language}   = $params{language};
    $body->{name}       = Webservice::OVH::Helper->trim($params{name});
    $body->{options}    = $options;
    $body->{ownerEmail} = Webservice::OVH::Helper->trim($params{owner_email});
    $body->{replyTo}    = Webservice::OVH::Helper->trim($params{reply_to}) if exists $params{reply_to};
    my $response = $api_wrapper->rawCall( method => 'post', path => "/email/domain/$domain_name/mailingList", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api_wrapper, domain => $domain, id => $task_id, module => $module );

    my $self = bless { _valid => 1, _api_wrapper => $api_wrapper, _properties => undef, _name => $params{name}, _domain => $domain, _module => $module }, $class;

    return ( $self, $task );
}

=head2 is_valid

When this mailinglist is deleted on the api side, this method returns 0.

=over

=item * Return: VALUE

=item * Synopsis: print "Valid" if $mailing_list->is_valid;

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

=item * Synopsis: my $name = $redirection->name;

=back

=cut

sub name {

    my ($self) = @_;

    return $self->{_name};
}

=head2 id

Secondary unique identifier.

=over

=item * Return: VALUE

=item * Synopsis: my $id = $mailing_list->id;

=back

=cut

sub id {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{properties}{id};
}

=head2 domain

Returns the email-domain this redirection is attached to. 

=over

=item * Return: L<Webservice::Email::Domain::Domain>

=item * Synopsis: my $email_domain = $mailing_list->domain;

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

=head2 properties

Returns the raw properties as a hash. 
This is the original return value of the web-api. 

=over

=item * Return: HASH

=item * Synopsis: my $properties = $mailing_list->properties;

=back

=cut

sub properties {

    my ($self) = @_;

    return unless $self->{_valid};

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $response          = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList/$mailing_list_name", noSignature => 0 );
    carp $response->error if $response->error;

    if ( $response->error ) {

        $self->{_valid}      = 0;
        $self->{_properties} = undef;
        return undef;

    } else {

        $self->{_properties} = $response->content;
        return $self->{_properties};
    }
}

=head2 language

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $language = $mailing_list->language;

=back

=cut

sub language {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{language};
}

=head2 options

Exposed property value. 

=over

=item * Return: HASH

=item * Synopsis: my $options = $mailing_list->options;

=back

=cut

sub options {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{options};
}

=head2 owner_email

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $owner_email = $mailing_list->owner_email;

=back

=cut

sub owner_email {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{ownerEmail};
}

=head2 reply_to

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $reply_to = $mailing_list->reply_to;

=back

=cut

sub reply_to {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{replyTo};
}

=head2 nb_subscribers_update_date

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $nb_subscribers_update_date = $mailing_list->nb_subscribers_update_date;

=back

=cut

sub nb_subscribers_update_date {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    my $str_datetime = $self->{_properties}->{nbSubscribersUpdateDate};
    my $datetime     = Webservice::OVH::Helper->parse_datetime($str_datetime);

    return $datetime;
}

=head2 nb_subscribers

Exposed property value. 

=over

=item * Return: VALUE

=item * Synopsis: my $nb_subscribers = $mailing_list->nb_subscribers;

=back

=cut

sub nb_subscribers {

    my ($self) = @_;

    $self->properties unless $self->{_properties};
    return unless $self->{_valid};

    return $self->{_properties}->{nbSubscribers};
}

=head2 change

Changes the objcet.

=over

=item * Parameter: %params - key => value language owner_email reply_to

=item * Synopsis: $mailing_list->change( language => 'en', owner_email => 'other@test.de', reply_to => 'reply@test.de');

=back

=cut

sub change {

    my ( $self, %params ) = @_;

    return unless $self->{_valid};

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $body              = {};
    $body->{language}   = $params{language}    if exists $params{language};
    $body->{ownerEmail} = Webservice::OVH::Helper->trim($params{owner_email}) if exists $params{owner_email};
    $body->{replyTo}    = Webservice::OVH::Helper->trim($params{reply_to})    if exists $params{reply_to};
    my $response = $api->rawCall( method => 'put', path => "/email/domain/$domain_name/mailingList/$mailing_list_name", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    $self->properties;
}

=head2 delete

Deletes the mailinglist api sided and sets this object invalid.

=over

=item * Synopsis: $mailing_list->delete;

=back

=cut

sub delete {

    my ($self) = @_;

    return unless $self->{_valid};

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $response          = $api->rawCall( method => 'delete', path => "/email/domain/$domain_name/mailingList/$mailing_list_name", noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    $self->{_valid} = 0;

    return $task;
}

=head2 change_options

Changes additional options.

=over

=item * Parameter: %params - key => value moderator_message subscribe_by_moderator users_post_only

=item * Synopsis: $mailing_list->change_options( moderator_message => 'false', subscribe_by_moderator => 'false', users_post_only => 'true' );

=back

=cut

sub change_options {

    my ( $self, %params ) = @_;

    return unless $self->{_valid};

    my @keys_needed = qw{ moderator_message subscribe_by_moderator users_post_only };

    if ( my @missing_parameters = grep { not exists $params{$_} } @keys_needed ) {

        croak "Missing parameter: @missing_parameters";
    }

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $body              = { options => {} };
    $body->{options}->{moderatorMessage}     = $params{moderator_message}      if exists $params{moderator_message};
    $body->{options}->{subscribeByModerator} = $params{subscribe_by_moderator} if exists $params{subscribe_by_moderator};
    $body->{options}->{usersPostOnly}        = $params{users_post_only}        if exists $params{users_post_only};
    my $response = $api->rawCall( method => 'post', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/changeOptions", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    $self->properties;

    return $task;
}

=head2 moderators

Returns an array of all moderators of this mailinglist.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $moderators = $mailing_list->moderators();

=back

=cut

sub moderators {

    my ($self) = @_;

    return unless $self->{_valid};

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $response          = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/moderator", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 moderators

Returns properties for a specified moderator E-Mail

=over

=item * Parameter: $email - email address

=item * Return: HASH

=item * Synopsis: my $properties = $mailing_list->moderator('moderator@test.de');

=back

=cut

sub moderator {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $response          = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/moderator/$email", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 add_moderator

Adds a moderator via E-Mail address.

=over

=item * Parameter: $email - email address

=item * Synopsis: my $properties = $mailing_list->add_moderator('moderator@test.de');

=back

=cut

sub add_moderator {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $body              = { email => Webservice::OVH::Helper->trim($email) };
    my $response          = $api->rawCall( method => 'post', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/moderator", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    return $task;

}

=head2 delete_moderator

Deletes a moderator via E-Mail address.

=over

=item * Parameter: $email - email address

=item * Synopsis: my $properties = $mailing_list->delete_moderator('moderator@test.de');

=back

=cut

sub delete_moderator {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $response          = $api->rawCall( method => 'delete', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/moderator/$email", noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    return $task;

}

=head2 delete_moderator

Sends the subscriber and moderator list to a specified E-Mail address.

=over

=item * Parameter: $email - email address

=item * Synopsis: my $properties = $mailing_list->send_list_by_email('moderator@test.de');

=back

=cut

sub send_list_by_email {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $body              = { email => Webservice::OVH::Helper->trim($email) };
    my $response          = $api->rawCall( method => 'post', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/sendListByEmail", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    return $task;
}

=head2 subscribers

Returns an array of all subscribers or a filtered list.

=over

=item * $email - filter for specified E-Mail address

=item * Return: L<ARRAY>

=item * Synopsis: my $subscribers = $mailing_list->subscribers();

=back

=cut

sub subscribers {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    my $filter_email = $email ? $email : "";
    my $filter = Webservice::OVH::Helper->construct_filter( "email" => $filter_email );

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;

    my $response = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/mailingList/$mailing_list_name/subscriber%s", $filter ), noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 subscriber

Returns  the properties of a single subscriber.

=over

=item * Parameter: $email - E-Mail address

=item * Return: HASH

=item * Synopsis: my $subscriber = $mailing_list->subscriber('sub@test.de');

=back

=cut

sub subscriber {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;

    my $response = $api->rawCall( method => 'get', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/subscriber/$email", noSignature => 0 );
    croak $response->error if $response->error;

    return $response->content;
}

=head2 add_subscriber

Adds an subscriber to the mailinglist.

=over

=item * Parameter: $email - E-Mail address

=item * Synopsis: $mailing_list->add_subscriber('sub@test.de');

=back

=cut

sub add_subscriber {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $body              = { email => Webservice::OVH::Helper->trim($email) };
    my $response          = $api->rawCall( method => 'post', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/subscriber", body => $body, noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    return $task;

}

=head2 delete_subscriber

Deletes an subscriber to the mailinglist.

=over

=item * Parameter: $email - E-Mail address

=item * Synopsis: $mailing_list->delete_subscriber('sub@test.de');

=back

=cut

sub delete_subscriber {

    my ( $self, $email ) = @_;

    return unless $self->{_valid};

    croak "Missing email" unless $email;

    my $api               = $self->{_api_wrapper};
    my $domain_name       = $self->domain->name;
    my $mailing_list_name = $self->name;
    my $response          = $api->rawCall( method => 'delete', path => "/email/domain/$domain_name/mailingList/$mailing_list_name/subscriber/$email", noSignature => 0 );
    croak $response->error if $response->error;

    my $task_id = $response->content->{id};
    my $task = Webservice::OVH::Email::Domain::Domain::Task::Mailinglist->_new_existing( wrapper => $api, domain => $self->domain, id => $task_id, module => $self->{_module} );

    return $task;
}

=head2 tasks

Get all associated tasks

=over

=item * Return: HASH

=item * Synopsis: $mailinglist->tasks;

=back

=cut

sub tasks {

    my ($self) = @_;

    return unless $self->{_valid};

    my $domain_name = $self->domain->name;
    my $api         = $self->{_api_wrapper};
    my $name        = $self->name;

    my $response = $api->rawCall( method => 'get', path => sprintf( "/email/domain/$domain_name/task/mailinglist?account=%s", $name ), noSignature => 0 );
    croak $response->error if $response->error;

    my $taks = $response->content || [];

    return unless scalar @$taks;

    return $taks;

}

1;
