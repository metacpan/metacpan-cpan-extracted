package WebService::Vtiger;

use warnings;
use strict;

use LWP::UserAgent;
use JSON;
use Digest::MD5;


=head1 NAME

Webservice::Vtiger - Interface to vtiger5.2 webservices

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

Class that handles the webservice interface to vtiger. 

The basic object in that transactions is $session that holds sessionName and userId values. This values will be used to perform request services

    use Webservice::Vtiger;

    my $vt       = new Webservice::Vtiger();
    my $usermane = 'admin';
    my $pin      = 'f956n34fc6';
    
    my $session  = $vt->getSession($username, $pin);
    
With a 'Session Id' string we can perform querys: 

    my $contacts  = $vt->query(
        $session->{'sessionName'},
        "select * from Contacts;"
      ); 

=head1 CRUD

To change vtiger objects we need the userId holded by our session object.

=head2 CREATE

   # create a new contact
   my $ctcData = {
        'assigned_user_id'=> $session->{'userId'},
        'lastname'        => 'Filipo'
       };

    my $newContact = $vt->create(
         $session->{'sessionName'},
         'Contacts',
         $ctcData
        );

=head2 RETRIEVE

    my $retrieved =$vt->retrieve($session->{'sessionName'}, $contactId);
    
=head2 UPDATE

    $retrieved->{'lastname'} = "Filapo";
    $vt->update($session->{'sessionName'},$retrieved)

=head2 DELETE

    my $deleted =$vt->delete($session->{'sessionName'}, $contactId);

=head1 SUBROUTINES/METHODS

=head2 new

A Webservice::Vtiger object can be instantiated by the new method.

The module instance has blessed 4 attributes:

=over 2 

=item * ua: the browser

Instance of LWP::UserAgent

=item * json: the json handler 

Instance of JSON

=item * ctx: the MD5 handler

Instance of Digest::MD5

=item * url: the url of vtiger5.2 CRM

=back

=cut

sub new {
    my $class = shift;
    my $url   = shift;
    my $self  = {
        'ua'   => LWP::UserAgent->new,        # browser
        'json' => JSON->new->allow_nonref,    # json handler
        'ctx'  => Digest::MD5->new,           # MD5 handler
        'url'  => $url                        # vtiger service url
    };
    bless $self, $class;

    $self->{'ua'}->agent("synodos filos/$VERSION");
    return $self;
}

=head2 getSession

Returns a session object.

A session holds sessionName and userId values. 

This values must be used to identify the user in web services requests.

        my $sessionName = $session->{'sessionName'};
        my $userId      = $session->{'userId'};

=cut

sub getSession {
    my $self     = shift;
    my $username = shift;
    my $pin      = shift;
    my $params   = '?operation=getchallenge&username=' . $username;
    my $session;

    # The login process need a challenge hash and a access key

    my $req = HTTP::Request->new( GET => $self->{'url'} . $params );
    my $res = $self->{'ua'}->request($req);

    my $challenge = {};
    if ( $res->is_success ) {
        $challenge = $self->{'json'}->decode( $res->content );

        # the md5 digested access key
        $self->{'ctx'}->add( $challenge->{result}{token} . $pin );
        my $ak = $self->{'ctx'}->hexdigest;
        $session = $self->_login( $username, $ak );
    }
    else {
        die "Network fault! server response: " . $res->status_line, "\n";
    }
    return $session;
}

sub _login {
    my $self = shift;
    my $un   = shift;
    my $ak   = shift;

    # we need a POST request
    my $req = HTTP::Request->new( POST => $self->{'url'} );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( 'operation=login&username=' . $un . '&accessKey=' . $ak );

    # Pass the request to user agent and get response back
    my $res          = $self->{'ua'}->request($req);
    my $jsonResponse = {};
    if ( $res->is_success ) {
        $jsonResponse = $self->{'json'}->decode( $res->content );
        die( 'Login fault: ' . $jsonResponse->{error}{message} )
          unless $jsonResponse->{'success'} eq 'true';
        my $result = $jsonResponse->{result};

        #use Data::Dumper;
        #print Dumper $result;
        return $result;
    }
    else {
        die("Connection error\n");
    }
}

=head2 describe

Returns the vtiger module descripton.

        my $description = $vt->describe{$sessionName, $module};
        my @fieldNames  = @{$description->{'fields'}};

The description consists of the following fields:

=over 2 

=item * label - The label used for the name of the module.

=item * name - The name of the module.

=item * createable - A boolean value specifying whether the object can be created.

=item * updateable - A boolean value specifying whether the object can be updated.

=item * deleteable - A boolean value specifying whether the object can be deleted.

=item * retrieveable - A boolean value specifying whether the object can be retrieved.

=item * fields - An array containing the field names and their type information.

=back

Each element in the fields array describes a particular field in the object.

=over 2

=item * name - The name of the field, as used internally by vtiger.

=item * label - The label used for displaying the field name.

=item * mandatory - This is a boolean that specifies whether the field is mandatory, mandatory fields must be provided when creating a new object.

=item * type - An map that describes the type information for the field.

=item * default - The default value for the field.

=item * nillable - A boolean that specifies whether the field can be set to null.

=item * editable - A boolean that specifies whether the field can be modified.

=back

The type field is of particular importance as it describes what type of the field is. This is an map that will contain at the least an element called name which is the name of the type. The name could be one of the following.

=over 2

=item * string - A one line text field.

=item * text - A multiline text field.

=item * integer - A non decimal number field.

=item * double - A field for for floating point numbers.

=item * boolean - A boolean field, can have the values true or false.

=item * time - A string of the format hh:mm, format is based on the user's settings time format.

=item * date - A string representing a date, the type map will contain another element called format which is the format in which the value of this field is expected, its based on the user's settings date format.

=item * datetime - A string representing the date and time, the format is base on the user's settings date format.

=item * autogenerated - Thes are fields for which the values are generated automatically by vtiger, this is usually an object's id field.

=item * reference - A field that shows a relation to another object, the type map will contain another element called refersTo which is an array containing the name of modules of which the field can point to.

=item * picklist - A field that can a hold one of a list of values, the map will contain two elements, picklistValues which is a list of possible values, and defaultValue which is the default value for the picklist.

=item * multipicklist - A picklist field where multiple values can be selected.

=item * phone - A field for storing phone numbers

=item * email - A field for storing email ids

=item * url - A field for storing urls

=item * skype - A field for storing skype ids or phone numbers.

=item * password - A field for storing passwords.

=item * owner - A field for defining the owner of the field. which could be a group or individual user.

=back

=cut

sub describe {
    my $self      = shift;
    my $sessionId = shift;
    my $module    = shift;
    my $params =
        '?sessionName='
      . $sessionId
      . '&elementType='
      . $module
      . '&operation=describe';
    my $result = $self->_getVtiger($params);

    #use Data::Dumper;
    #print Dumper $result;

    return $result;
}

=head2 create

=cut

sub create {
    my $self       = shift;
    my $sessionId  = shift;
    my $moduleName = shift;
    my $data       = shift;

    my $objectJson = $self->{'json'}->encode($data);
    my $params     = {
        (
            'sessionName' => $sessionId,
            'operation'   => 'create',
            'element'     => $objectJson,
            'elementType' => $moduleName
        )
    };
    my $result = $self->_postVtiger($params);
    return $result;
}

=head2 delete

=cut

sub delete {
    my $self      = shift;
    my $sessionId = shift;
    my $id        = shift;

    my $params = {
        (
            'sessionName' => $sessionId,
            'id'          => $id,
            'operation'   => 'delete'
        )
    };
    $self->_postVtiger($params);
    return 'deleted';
}

=head2 update

=cut

sub update {
    my $self      = shift;
    my $sessionId = shift;
    my $data      = shift;

    my $objectJson = $self->{'json'}->encode($data);
    my $params     = {
        (
            'sessionName' => $sessionId,
            'operation'   => 'update',
            'element'     => $objectJson,
        )
    };
    my $result = $self->_postVtiger($params);
    return $result;
}

=head2 query

=cut

sub query {
    my $self      = shift;
    my $sessionId = shift;
    my $query     = shift;
    my $params =
      '?sessionName=' . $sessionId . '&operation=query&query=' . $query;
    my $result = $self->_getVtiger($params);

    #use Data::Dumper;
    #print Dumper $result->[0];

    return $result;
}

=head2 retrieve

=cut

sub retrieve {
    my $self      = shift;
    my $sessionId = shift;
    my $id        = shift;
    my $params = '?sessionName=' . $sessionId . '&operation=retrieve&id=' . $id;
    my $result = $self->_getVtiger($params);

    #use Data::Dumper;
    #print Dumper $result;
    return $result;
}

=head2 listModules

=cut

sub listModules {
    my $self      = shift;
    my $sessionId = shift;
    my $params    = '?sessionName=' . $sessionId . '&operation=listtypes';
    my $result    = $self->_getVtiger($params);
    return $result;
}

sub _getVtiger {
    my $self   = shift;
    my $params = shift;

    #use Data::Dumper;
    #print Dumper $params;

    my $req = HTTP::Request->new( GET => $self->{'url'} . $params );
    my $res = $self->{'ua'}->request($req);

    #my $res    = $self->{'ua'}->get( $self->{'url'}, $params );

    my $jsonResponse = {};
    if ( $res->is_success ) {

        $jsonResponse = $self->{'json'}->decode( $res->content );
        die( 'Service fault! ' . $jsonResponse->{'error'}{'message'} )
          unless $jsonResponse->{'success'} eq 'true';
        return $jsonResponse->{result};
    }
    else {
        die("Connection error\n");
    }
}

sub _postVtiger {
    my $self   = shift;
    my $params = shift;

    #use Data::Dumper;
    #print Dumper $params;

    my $res = $self->{'ua'}->post( $self->{'url'}, $params );
    my $jsonResponse = {};
    if ( $res->is_success ) {
        $jsonResponse = $self->{'json'}->decode( $res->content );

        #print ($jsonResponse->{error}{xdebug_message});
        die(    'POST fault: '
              . $jsonResponse->{error}{message} . "\n"
              . $self->{'url'} )
          unless $jsonResponse->{'success'} eq 'true';
        return $jsonResponse->{result};
    }
    else {
        die("Connection error (POST)\n$@\n");
    }
}

=head1 AUTHOR

Monsenhor, C<< <monsenhor at cpan.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-vtiger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Vtiger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Vtiger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Vtiger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Vtiger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Vtiger>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Vtiger/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Monsenhor.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Vtiger
