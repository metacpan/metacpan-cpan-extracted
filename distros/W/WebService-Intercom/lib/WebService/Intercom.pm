use Moops -strict;

# ABSTRACT: interfaces with Intercom.io
# PODNAME: WebService::Intercom

=pod

=head1 NAME

WebService::Intercom - interact with the Intercom.io API

=head1 SYNOPSIS

  my $intercom = WebService::Intercom->new(app_id => '[APP ID]',
                                           api_key => '[API KEY]');

  # Create a user
  my $user = $intercom->user_create_or_update(
     email => 'test@example.com', 
     name => 'test user');
  
  # Retrieve an existing user.
  my $existing_user = $intercom->user_get(email => 'test2@example.com');

  # Add a tag to a user
  $user->tag('test tag');
  $intercom->tag_create_or_update(name => "test tag");
  $intercom->tag_items(name => "test tag", users => [{ email => 'test@example.com'}]);
  $user->untag('test tag');

  # Change the user's name
  $user->name = 'new name';
  $user->save();

  # Delete the user
  $user->delete();
  $intercom->user_delete(email => 'test@example.com');

  # Add a note
  $user->add_note(body => "This is a test note");
  $intercom->note_create(email => 'test@example.com',
                         body => "This is a test note");
 
  # Add an event
  $user->add_event(event_name => 'test event');
  $intercom->event_create(email => 'test@example.com',
                          event_name => 'test event',
                          metadata => {
                             "article" =>  {"url" =>  "https://example.org/",
                                            "value" => "link text"},
                          });

=head1 DESCRIPTION

Provides a nice API for Intercom.io rather than making raw requests.

=head1 IMPLEMENTATION PHILOSOPHY

This module attempts to stick as close to the API as possible.

Documentation for the v2 API:

L<http://doc.intercom.io/api/>

For examples see the test cases, most functionality is well exercised
via tests.

=cut   


use WebService::Intercom::Exception;
use WebService::Intercom::Types;
use WebService::Intercom::User;
use WebService::Intercom::Tag;
use WebService::Intercom::Note;
use WebService::Intercom::Message;
use WebService::Intercom::Admin;

class WebService::Intercom types WebService::Intercom::Types {
    use LWP::UserAgent;
    use HTTP::Response;
    use HTTP::Request::Common qw(DELETE POST GET);
    use JSON::XS;
    use MIME::Base64;
    use Kavorka qw( multi method );


    has 'ua' => (is => 'ro', default => sub { return LWP::UserAgent->new(keep_alive => 10, agent => "WebService::Intercom/1.0") } );
    has 'app_id' => (is => 'ro');
    has 'api_key' => (is => 'ro');

    has 'api_base' => (is => 'ro', isa => Str, default => 'https://api.intercom.io');

=head1 FUNCTIONS

=head2 user_get

Retrieves an existing user.

  $intercom->user_get(Maybe[Str] :$user_id?,
                      Maybe[Str] :$email?,
                      Maybe[Str] :$id?);

Only one of user_id, email or id are required to retrieve a user.

Returns a L<WebService::Intercom::User>.

=cut
    
    
    method user_get(Maybe[Str] :$user_id?,
                    Maybe[Str] :$email?,
                    Maybe[Str] :$id?) {

        if (!(defined($user_id) xor defined($email) xor defined($id))) {
            WebService::Intercom::Exception->throw({ message => "One and only one of user_id, email or id must be defined"});
        }

        my $request;
        if (defined($id)) {
            $request = GET($self->api_base . '/users/' . $id);
        } elsif (defined($user_id)) {
            $request = GET($self->api_base . '/users?user_id=' . URI::Escape::uri_escape($user_id));
        } elsif (defined($email)) {
            $request = GET($self->api_base . '/users?email=' . URI::Escape::uri_escape($email)); 
        }

        $self->_request($request);
    }

=head2 user_create_or_update

Creates or updates a user.

  # When you have an existing WebService::Intercom::User
  $intercom->user_create_or_update(WebService::Intercom::User $user);

  or

  $intercom->user_create_or_update(Maybe[Str] :$user_id?,
                                   Maybe[Str] :$email?,
                                   Maybe[Str] :$id?,
                                   Maybe[Int] :$signed_up_at?,
                                   Str :$name?,
                                   Maybe[IPAddressType] :$last_seen_ip?,
                                   CustomAttributesType :$custom_attributes?,
                                   Maybe[Str] :$last_seen_user_agent?,
                                   HashRef :$companies?,
                                   Maybe[Int] :$last_request_at?,
                                   Maybe[Bool] :$unsubscribed_from_emails?,
                                   Maybe[Bool] :$update_last_request_at?,
                                   Maybe[Bool] :$new_session?);
  
Returns a L<WebService::Intercom::User> that represents the new or updated user.

=cut

    
    
    multi method user_create_or_update(WebService::Intercom::User $user) {
        return $self->user_create_or_update(user_id => $user->user_id,
                                            email => $user->email,
                                            id => $user->id,
                                            name => $user->name,
                                            last_seen_ip => $user->last_seen_ip,
                                            custom_attributes => $user->custom_attributes,
                                            last_seen_user_agent => $user->user_agent_data,
                                            last_request_at => $user->last_request_at,
                                            unsubscribed_from_emails => $user->unsubscribed_from_emails,
                                        );
    }

    multi method user_create_or_update(Maybe[Str] :$user_id?,
                                       Maybe[Str] :$email?,
                                       Maybe[Str] :$id?,
                                       Maybe[Int] :$signed_up_at?,
                                       Maybe[Str] :$name?,
                                       Maybe[IPAddressType] :$last_seen_ip?,
                                       CustomAttributesType :$custom_attributes?,
                                       Maybe[Str] :$last_seen_user_agent?,
                                       HashRef :$companies?,
                                       Maybe[Int] :$last_request_at?,
                                       Maybe[Bool] :$unsubscribed_from_emails?,
                                       Maybe[Bool] :$update_last_request_at?,
                                       Maybe[Bool] :$new_session?) {

        my $json_content = {
            signed_up_at => $signed_up_at,
            name => $name,
            last_seen_ip => $last_seen_ip,
            custom_attributes => $custom_attributes,
            last_seen_user_agent => $last_seen_user_agent,
            companies => $companies,
            last_request_at => $last_request_at,
            unsubscribed_from_emails => $unsubscribed_from_emails,
            update_last_request_at => $update_last_request_at,
            new_session => $new_session
        };
        
        if (defined($user_id)) {
            $json_content->{user_id} = $user_id;
        }
        if (defined($email)) {
            $json_content->{email} = $email;
        }
        if (defined($id)) {
            $json_content->{id} = $id;
        }

        my $json = JSON::XS::encode_json($json_content);
        my $request = POST($self->api_base . '/users',
                           'Content-Type' => 'application/json',
                           Content => $json
                       );

        $self->_request($request);
    }


=head2 user_delete

Deletes a user

  # When you have an existing WebService::Intercom::User
  $intercom->user_delete(WebService::Intercom::User $user);

  or

  $intercom->user_delete(Maybe[Str] :$user_id?,
                         Maybe[Str] :$email?,
                         Maybe[Str] :$id?);

Only one of user_id, email or id is required.
  
Returns a L<WebService::Intercom::User> that represents the deleted user.

=cut

    
    multi method user_delete(WebService::Intercom::User $user) {
        return $self->user_delete(user_id => $user->user_id,
                                  id => $user->id,
                                  email => $user->email);
    }
    
    multi method user_delete(Str :$user_id?,
                       Str :$id?,
                       Str :$email?) {
        my $request;
        if (defined($id)) {
            $request = DELETE($self->api_base . '/users/' . $id);
        } elsif (defined($user_id)) {
            $request = DELETE($self->api_base . '/users?user_id=' . URI::Escape::uri_escape($user_id));
        } elsif (defined($email)) {
            $request = DELETE($self->api_base . '/users?email=' . URI::Escape::uri_escape($email)); 
        }

        $self->_request($request);
    }

=head2 tag_create_or_update

Creates or updates a tag.

  # When you have an existing WebService::Intercom::User
  $intercom->tag_create_or_update(WebService::Intercom::Tag $tag);

  or

  $intercom->tag_create_or_update(Str :$name,
                                  Maybe[Str] :$id?);

Returns a L<WebService::Intercom::Tag> that represents the tag.

=cut

    multi method tag_create_or_update(WebService::Intercom::Tag $tag) {
        return $self->tag_create_or_update(name => $tag->name,
                                           id => $tag->id);
    }
    
    multi method tag_create_or_update(Str :$name,
                                      Maybe[Str] :$id?) {
        my $json_content = {
            name => $name,
        };
        if (defined($id)) {
            $json_content->{id} = $id;
        }
        
        my $request = POST($self->api_base . '/tags',
                           'Content-Type' => 'application/json',
                           Content => JSON::XS::encode_json($json_content)
                       );

        return $self->_request($request);
    }


=head2 tag_items

Applies or removes a tag to users or companies

  # When you have an existing WebService::Intercom::User
  $intercom->tag_items(Str :$name,
                       ArrayRef[TagUserIdentifierType] :$users?,
                       ArrayRef[TagCompanyIdentifierType] :$companies?);

=cut

    
    method tag_items(Str :$name,
                     ArrayRef[TagUserIdentifierType] :$users?,
                     ArrayRef[TagCompanyIdentifierType] :$companies?) {
        
        my $json_content = {
            name => $name,
        };

        if (!(defined($users) xor defined($companies))) {
            WebService::Intercom::Exception->throw({ message => "Either users or companies must be defined as a parameter, not both and not neither"});
        }

        if (defined($users)) {
            $json_content->{users} = $users;
        } elsif (defined($companies)) {
            $json_content->{companies} = $companies;
        } 
        
        
        my $request = POST($self->api_base . '/tags',
                           'Content-Type' => 'application/json',
                           Content => JSON::XS::encode_json($json_content)
                       );

        return $self->_request($request);
    }


=head2 tag_delete

Deletes a tag

  # When you have an existing WebService::Intercom::User
  $intercom->tag_delete(WebService::Intercom::Tag $tag);

  or

  $intercom->tag_delete(Str :$id);

Returns undef

=cut

    
    multi method tag_delete(Str :$id) {
        $self->_request(DELETE($self->api_base . '/tags/' . $id), no_content => 1);
    }

    multi method tag_delete(WebService::Intercom::Tag $tag) {
        return $self->tag_delete(id => $tag->id);
    }


=head2 note_create

Creates a note for a user

  # When you have an existing WebService::Intercom::User
  $intercom->note_create(Maybe[Str] :$user_id?,
                         Maybe[Str] :$email?,
                         Maybe[Str] :$id?,
                         Maybe[Str] :$admin_id?,
                         Str :$body);

Returns a L<WebService::Intercom::Note> that represents the note.

=cut

    

    method note_create(Maybe[Str] :$user_id?,
                       Maybe[Str] :$email?,
                       Maybe[Str] :$id?,
                       Maybe[Str] :$admin_id?,
                       Str :$body) {
        if (!(defined($user_id) xor defined($email) xor defined($id))) {
            WebService::Intercom::Exception->throw({ message => "One and only one of user_id, email or id must be defined"});
        }

        my $json_content = {
            body => $body,
        };

        if (defined($user_id)) {
            $json_content->{user}->{user_id} = $user_id;
        } elsif (defined($email)) {
            $json_content->{user}->{email} = $email;
        } elsif (defined($id)) {
            $json_content->{user}->{id} = $id;
        }

        my $request = POST($self->api_base . '/notes',
                           'Content-Type' => 'application/json',
                           Content => JSON::XS::encode_json($json_content)
                       );


        return $self->_request($request);
    }

=head2 event_create

Creates an event for a user

  # When you have an existing WebService::Intercom::User
  $intercom->event_create(Maybe[Str] :$user_id?,
                          Maybe[Str] :$email?,
                          EventNameType :$event_name,
                          Maybe[Int] :$created_at?,
                          Maybe[EventMetadataType] :$metadata?);

Returns undef.

=cut
    
    method event_create(Maybe[Str] :$user_id?,
                        Maybe[Str] :$email?,
                        EventNameType :$event_name,
                        Maybe[Int] :$created_at?,
                        Maybe[EventMetadataType] :$metadata? where { !defined($_) || scalar(keys %$_) <= 5 }) {

        if (!(defined($user_id) || defined($email))) {
            WebService::Intercom::Exception->throw({ message => "One of user_id or email must be defined"});
        }

        my $json_content = {
            event_name => $event_name,
            created_at => $created_at,
        };

        if (defined($user_id)) {
            $json_content->{user_id} = $user_id;
        } elsif (defined($email)) {
            $json_content->{email} = $email;
        }

        if (defined($metadata)) {
            $json_content->{metadata} = $metadata;
        }
        

        my $request = POST($self->api_base . '/events',
                           'Content-Type' => 'application/json',
                           Content => JSON::XS::encode_json($json_content)
                       );

        return $self->_request($request, no_content => 1);
    }


=head2 create_message

Create a message, can be user or admin initiated.

  # When you have an existing WebService::Intercom::User
  $intercom->create_message(MessagePersonType :$from,
                          Maybe[MessagePersonType] :$to,
                          Str :$body,
                          Maybe[Str] :$subject?,
                          Maybe[StrMatch[qr/^(plain|personal)$/]] :$template,
                          StrMatch[qr/^(inapp|email)$/] :$message_type);

Returns a L<WebService::Intercom::Message>.

=cut
    
    method create_message(MessagePersonType :$from,
                          Maybe[MessagePersonType] :$to,
                          Str :$body,
                          Maybe[Str] :$subject?,
                          Maybe[StrMatch[qr/^(plain|personal)$/]] :$template,
                          StrMatch[qr/^(inapp|email)$/] :$message_type) {

        if (defined($message_type) && $message_type eq 'email') {
            defined($subject) || WebService::Intercom::Exception->throw({ message => "Subject is required for email message"});
        }        
        
        my $json_content = {
            from => $from,
            (defined($to) ? (to => $to) : ()),
            (defined($subject) ? (subject => $subject) : ()),
            (defined($template) ? (template => $template) : ()),
            (defined($message_type) ? (message_type => $message_type) : ()),
            body => $body,
        };

        my $request = POST($self->api_base . '/messages',
                           'Content-Type' => 'application/json',
                           Content => JSON::XS::encode_json($json_content)
                       );

        return $self->_request($request);
    }


    method get_admins() {
        my $request = GET($self->api_base . '/admins/',
                           'Content-Type' => 'application/json');
                      
        return $self->_request($request);
    }


    
    method _request(HTTP::Request $request,  Bool :$no_content?) {
        $request->header('Accept', 'application/json');
        $request->header('Authorization' => "Basic " . MIME::Base64::encode_base64($self->app_id . ":" . $self->api_key, ''));

        my $response = $self->ua->request($request);

        if ($response->is_success()) {
            if (!$no_content) {
                my $data;
                eval {
                    $data = JSON::XS::decode_json($response->content());
                };
                if ($@) {
                    WebService::Intercom::Exception->throw({ message => "Failed to decode JSON result for request: " . $@ . "\n" . $request->as_string() . "\nResult was: " . $response->as_string()});
                }
                if ($data->{type} =~ /^(user|tag|note|user_message|admin_message)$/) {
                    my $class_name = "WebService::Intercom::" . ucfirst($1);
                    $class_name =~ s/(?:user_message|admin_message)$/Message/ig;
                    my $r;
                    eval {
                        $r = $class_name->new({
                            %$data,
                            intercom => $self,
                        });
                    };
                    if ($@) {
                        WebService::Intercom::Exception->throw({ message => "Failed to decode JSON result to object: " . $@ . "\n" . $request->as_string() . "\nResult was: " . $response->as_string()});
                    }
                    return $r;
                } elsif ($data->{type} eq 'admin.list') {
                    my @admins = map { WebService::Intercom::Admin->new($_) } @{$data->{admins}};
                    return \@admins;
                } elsif ($data->{type} eq 'error.list') {
                    WebService::Intercom::Exception->throw(
                        request_id => $data->{request_id},
                        message => $data->{errors}->[0]->{message},
                        code => $data->{errors}->[0]->{code}
                    );
                } else {
                    WebService::Intercom::Exception->throw({ message => "Unknown object type returned: $data->{type}"});
                }
            }
            return;
        } else {
            # Failed request but we still got some json content
            if ($response->header('Content-Type') =~ /json/) {
                my $data;
                eval {
                    $data = JSON::XS::decode_json($response->content());
                };
                if ($@) {
                    WebService::Intercom::Exception->throw({ message => "Failed to decode JSON result for request " . $request->as_string() . "\nResult was: " . $response->as_string()});
                }
                WebService::Intercom::Exception->throw(
                    request_id => $data->{request_id},
                    message => $data->{errors}->[0]->{message},
                    code => $data->{errors}->[0]->{code}
                );
            }
        }
        WebService::Intercom::Exception->throw({ message => "Got a bad response from request:\n" . $request->as_string() . "\nResult was: " . $response->as_string()});        
    }    
}

    
1;

__END__


=head1 SEE ALSO

See L<Moops> and L<Kavorka> to understand parameter signatures.

Also of course Intercom at L<http://www.intercom.io>.

=head1 AUTHOR

Rusty Conover <rusty+cpan@luckydinosaur.com>

=head1 COPYRIGHT

This software is copyright (c) 2015 by Lucky Dinosaur LLC. L<http://www.luckydinosaur.com>

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

    
1;
