package WWW::Session;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::Session - Generic session management engine for web applications

=head1 DESCRIPTION

Generic session management engine for web applications with multiple backends, 
object serialization and data validation

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

This module allows you to easily create sessions , store data in them and later
retrieve that information, using multiple storage backends

Example: 

    use WWW::Session;
    
    #set up the storage backends                 
    WWW::Session->add_storage( 'File', {path => '/tmp/sessions'} );
    WWW::Session->add_storage( 'Memcached', {servers => ['127.0.0.1:11211']} );
    
    #Set up the serialization engine (defaults to JSON)
    WWW::Session->serialization_engine('JSON');
    
    #Set up the default expiration time (in seconds or -1 for never)
    WWW::Session->default_expiration_time(3600);

    #Turn on autosave
    WWW::Session->autosave(1);
    
    #and than ...
    
    #Create a new session
    my $session = WWW::Session->new($sid,$hash_ref);
    ...
    $session->sid(); #returns $sid
    $session->data(); #returns $hash_ref

    #set the user
    $session->user($user);
    #retrieve the user
    my $user = $session->user();

    #returns undef if it doesn't exist or it's expired
    my $session = WWW::Session->find($sid); 
    
    #returns the existing session if it exists, creates a new session if it doesn't
    my $session = WWW::Session->find_or_create($sid);  

Using the session :

=over 4

=item * Settings values

There are two ways you can save a value on the session :

    $session->set('user',$user);
    
    or 
    
    $session->user($user);
    
If the requested field ("user" in the example above) already exists it will be 
assigned the new value, if it doesn't it will be added.

When you set a value for a field it will be validated first (see setup_field() ). 
If the value doesn't pass validation the field will keep it's old value and the 
set method will return 0. If everything goes well the set method will return 1.
    
=item * Retrieving values

    my $user = $session->get('user');
    
    or
    
    my $user = $session->user();
    
If the requested field ("user" in the example above) already exists it will return 
it's value, otherwise will return C<undef>

=back

We can automaticaly deflate/inflate certain informations when we store / retrieve
from storage the session data (see setup_field() for more details):

    WWW::Session->setup_field( 'user',
                               inflate => sub { return Some::Package->new( $_[0] ) },
                               deflate => sub { $_[0]->id() }
                            );

We can automaticaly validate certain informations when we store / retrieve
from storage the session data (see setup_field() for more details):

    WWW::Session->setup_field( 'age',
                               filter => sub { $_[0] >= 18 }
                             );


Another way to initialize the module :

    use WWW::Session storage => [ 'File' => { path => '/tmp/sessions'},
                                  'Memcached' => { servers => ['127.0.0.1'] }
                                ],
                     serialization => 'JSON',
                     expires => 3600,
                     fields => {
                               user => {
                                     inflate => sub { return Some::Package->new( $_[0] ) },
                                     deflate => sub { $_[0]->id() },
                                     }
                               };
                     
=cut

#Internal variables
my @storage_engines = ();
my $serializer = undef;
my $default_expiration = -1;
my $fields_modifiers = {};
my $autosave = 1;

#Set up the default serializer
__PACKAGE__->serialization_engine('JSON');

=head1 SESSION & OBJECTS

The default serialization engine is JSON, but JSON can't serialize objects by default,
you will have to write more code to accomplish that. If your session data data contains 
objects you can take one of the following approaches :

=over 4 

=item * Use inflate/deflate (recommended)

    # if we have a user object (eg MyApp::User) we can deflate it like this
    
    WWW::Session->setup_field('user', deflate => sub { return $_[0]->id() } );
    
    #and inflate it back like this
    
    WWW::Session->setup_field('user',inflate => sub { return Some::Package->new( $_[0] ) } );
    
This method even thow it's slower, it reduces the size of the session object when stored, and 
it ensures that if the object data changed since we saved it, this changes will be reflected in the 
object when we retrieve restore it (usefull for database result objects)

=item * Change the serialization module to 'Storable'

The 'Storable' serialization engine can handle object without any additional changes

    WWW::Session->serialization_engine('Storable');

Note : The perl Storable module is not very compatible between different version, so sharing data 
between multiple machines could cause problems. We recommad using the 'JSON' engine with 
inflate/defate (described above);

=back

=head1 STORAGE BACKENDS

You can use one or more of the fallowing backends (the list might not be complete, more backends might be available on CPAN):

=head2 File storage

Here is how you can set up the File storage backend :

    use WWW::Session;

    WWW::Session->add_storage('File', {path => '.'} );

See WWW::Session::Storage::File for more details

=head2 Database storage

If you want to store your session is MySQL do this :

    use WWW::Session;

    WWW::Session->add_storage( 'MySQL', { 
                                            dbh => $dbh,
                                            table => 'sessions',
                                            fields => {
                                                    sid => 'session_id',
                                                    expires => 'expires',
                                                    data => 'data'
                                            },
                                        }
                              );

The "fields" hasref contains the mapping of session internal data to the column names from MySQL. 
The keys are the session fields ("sid","expires" and "data") and must all be present. 

The MySQL types of the columns should be :

=over 4

=item * sid => varchar(32)

=item * expires => DATETIME or TIMESTAMP

=item * data => text

=back

See WWW::Session::Storage::MySQL for more details

=head2 Memcached storage

    To use memcached as a storage backend do this :

    use WWW::Session;

    WWW::Session->add_storage('Memcached', {servers => ['127.0.0.1:11211']} );


See WWW::Session::Storage::Memcached for more details


=head1 SUBROUTINES/METHODS

=head2 new

Creates a new session object with the unique identifier and the given data.
If a session with the same identifier previously existed it will be overwritten

Parameters

=over 4

=item * sid = unique id for this session

=item * data = hash reference containing the data that we want to store in the session object

=item * exipres = for how many secconds is this session valid (defaults to the default expiration time)

=back

Retuns a WWW::Session object

Usage :

    my $session = WWW::Session->new('session_id',{ a=> 1, b=> 2});

=cut

sub new {
    my ($class,$sid,$data,$expires) = @_;
    
    $expires ||= -1;
    $data ||= {};
    
    die "You cannot use a undefined string as a session id!" unless $sid;
    
    my $self = {
                data    => {},
                expires => $expires,
                sid     => $sid,
                changed => {},
               };
    
    bless $self, $class;
    
    $self->set($_,$data->{$_}) foreach keys %{$data};
    
    return $self;
}

=head2 find

Retieves the session object for the given session id

Usage :

    my $session = WWW::Session->find('session_id');

=cut
sub find {
    my ($class,$sid) = @_;
    
    die "You cannot use a undefined string as a session id!" unless $sid;
    
    my $info;
    
    foreach my $storage (@storage_engines) {
        $info = $storage->retrieve($sid);
        last if defined $info;
    }
    
    if ($info) {
        my $session = $class->load($info);
        $session->{changed} = {};
        return $session;
    }
    
    return undef;
}

=head2 find_or_create

Retieves the session object for the given session id if it exists, if not it
creates a new object with the given session id

=over 4

=item * sid = unique id for this session

=item * data = hash reference containing the data that we want to store in the session object

=item * exipres = for how many secconds is this session valid (defaults to the default expiration time),

=back

Usage:

    my $session = WWW::Session->find_or_create('session_id',{ c=>2 })

=cut
sub find_or_create {
    my ($class,$sid,$data,$expires) = @_;
    
    my $self = $class->find($sid);
    
    if ($self) {
        $self->expires($expires) if defined ($expires);
        $self->set($_,$data->{$_}) foreach keys %{$data};
    }
    else {
        $self = $class->new($sid,$data,$expires);
    }
    
    return $self;
}


=head2 set

Adds/sets a new value for the given field

Usage :

    $session->set('user',$user);
    
The values can also be set by calling the name of the field you want to set 
as a method :

    $session->user($user);

=cut

sub set {
    my ($self,$field,$value) = @_;
    
    if (! defined $value && exists $fields_modifiers->{$field} && defined $fields_modifiers->{$field}->{default}) {
        $value = $fields_modifiers->{$field}->{default};
    }
    
    $self->run_trigger('before_set_value',$field,$value,$self->get($field));
    
    my $validated = 1;
    
    if ( exists $fields_modifiers->{$field} && defined $fields_modifiers->{$field}->{filter} ) {
            
        $validated = 0; #we have a filter, check the value against the filter first
        
        my $filter = $fields_modifiers->{$field}->{filter};
        
        die "Filter must be a hash ref or array ref or code ref" unless ref($filter);
        
        if (ref($filter) eq "ARRAY") {
            if (grep { $value eq $_ } @{$filter}) {
                $validated = 1;
            }
        }
        elsif (ref($filter) eq "CODE") {
            $validated = $filter->($value);
        }
        elsif (ref($filter) eq "HASH") {
            my $h_valid = 1;
            
            if ( defined $filter->{isa} ) {
                $h_valid = 0 unless ref($value) eq $filter->{isa};
            }
            
            $validated = $h_valid;
        }
    }
    
    if ($validated) {
        $self->{data}->{$field} = $value;
        $self->{changed}->{$field} = 1;
        
        $self->run_trigger('after_set_value',$field,$value);
    }
    else {
        warn "Value $value failed validation for key $field";
    }
    
    return $validated;
}


=head2 get

Retrieves the value of the given key from the session object

Usage :

    my $user = $session->get('user');
    
You can also use the name of the field you want to retrieve as a method.
The above call does the same as :

    my $user = $session->user();
    
=cut

sub get {
    my ($self,$field) = @_;
    
    return $self->{data}->{$field};
}

=head2 delete

Removes the given key from the session data

Usage :

    $session->delete('user');

=cut
sub delete {
    my ($self,$field) = @_;
    
    $self->run_trigger('before_delete',$field,$self->get($field));
    
    $self->{changed}->{$field} = 1;
    my $rv = delete $self->{data}->{$field};
    
    $self->run_trigger('after_delete',$field,$self->get($field));
        
    return $rv;
}

=head2 sid

Returns the session id associated with this session
    
=cut

sub sid {
    my ($self) = @_;
    
    return $self->{sid};
}

=head2 expires

Getter/Setter for the expiration time of this session
    
=cut

sub expires {
    my ($self,$value) = @_;

    if (defined $value) {
        $self->{expires} = $value;
    }

    return $self->{expires};
}

=head2 add_storage

Adds a new storge engine to the list of Storage engines that will be used to
store the session info

Usage :

    WWW::Session->add_storage($storage_engine_name,$storage_engine_options);
    
Parameters :

=over 4

=item * $storage_engine_name = Name of the class that defines a valid storage engine

For WWW::Session::Storage::* modules you can use only the name of the storage,
you don't need the full name. eg Memcached and WWW::Session::Storage::Memcached
are synonyms

=item * $storage_engine_options = hash ref containing the options that will be
passed on to the storage engine module when new() is called

=back

Example :

    WWW::Session->add_storage( 'File', {path => '/tmp/sessions'} );
    
    WWW::Session->add_storage( 'Memcached', {servers => ['127.0.0.1:11211']} );

See each storage module for aditional details

=cut

sub add_storage {
    my ($class,$name,$options) = @_;
    
    $options ||= {};
    
    if ($name !~ /::/) {
        $name = "WWW::Session::Storage::$name";
    }
    
    eval "use $name";
        
    die "WWW::Session cannot load '$name' storage engine! Error : $@" if ($@);
    
    my $storage = $name->new($options);
    
    if ($storage) {
        push @storage_engines, $storage;
    }
    else {
        die "WWW::Session storage engine '$name' failed to initialize with the given arguments!";
    }
}

=head2 serialization_engine

Configures the serialization engine to be used for serialising sessions.

The default serialization engine is JSON

Usage :

    WWW::Session->serialization_engine('JSON');
    
Parameters :

=over 4

=item * $serialization_engine_name = Name of the class that defines a valid serialization engine

For WWW::Session::Serialization::* modules you can use only the short name of the module,
you don't need the full name. eg JSON and WWW::Session::Serialization::JSON
are synonyms

=back

=cut

sub serialization_engine {
    my ($class,$name) = @_;
    
    if ($name !~ /::/) {
        $name = "WWW::Session::Serialization::$name";
    }
    
    eval "use $name";
        
    die "WWW::Session cannot load '$name' serialization engine! Error : $@" if ($@);
    
    my $serializer_object = $name->new($fields_modifiers);
    
    if ($serializer_object) {
        $serializer = $serializer_object;
    }
    else {
        die "WWW::Session serialization engine '$name' failed to initialize!";
    }
}

=head2 autosave

Turn on/off the autosave feature (on by default)

If this feature is on the object will always be saved before beying destroyed

Usage :

    WWW::Session->autosave(1);

=cut

sub autosave {
    my ($class,$value) = @_;
    
    $autosave = $value if defined $value;
    
    return $autosave;
}

=head2 default_expiration_time

Setter/Getter for the default expiration time

Usage :

    WWW::Session->default_expiration_time(1800);
    
=cut

sub default_expiration_time {
    my ($class,$value) = @_;
    
    if (defined $value) {
        $default_expiration = $value;
    }
    
    return $default_expiration;
}

=head2 destroy

Completely removes all the data related to the current session

NOTE: After calling destroy the session object will no longer be usable

Usage :

    $session->destroy();
    
=cut

sub destroy {
    
    #save the session id fiers and undef the object before we delete it from
    #storage to avoid autosave kikking in after we remove it from storage
    
    my $sid = $_[0]->sid();
    
    $_[0] = undef;
        
    foreach my $storage (@storage_engines) {
        $storage->delete($sid);
    }
}


=head2 setup_field 

Sets up the filters, inflators and deflators for the given field

=head3 deflators

Deflators are passed as code refs. The only argument the deflator
method receives is the value of the filed that it must be deflated and 
it must return a single value (scalar, object or reference) that will be 
asigned to the key.

Example :

    # if we have a user object (eg MyApp::User) we can deflate it like this
    
    WWW::Session->setup_field('user', deflate => sub { return $_[0]->id() } );

=head3 inflators

Inflators are passed as code refs. The only argument the inflator 
method receives is the value of the filed that it must inflate and 
it must return a single value (scalar, object or reference) that will be 
asigned to the key.

Example :

    # if we have a user object (eg MyApp::User) we can inflate it like this

    WWW::Session->setup_field('user',inflate => sub { return Some::Package->new( $_[0] ) } );

=head3 filters

Filters can be used to ensure that the values from the session have the required values

Filters can be :

=over 4

=item * array ref

In this case when we call $session->set($field,$value) the values will have to be one of the 
values from the array ref , or the operation will fail

Example :

    #Check that the age is between 18 and 99
    WWW::Session->setup_field('age',filter => [18..99] );

=item * code ref 

In this case the field value will be passed to the code ref as the only parameter. The code ref
must return a true or false value. If it returns a false value the set() operation will fail

Example :

    #Check that the age is > 18
    WWW::Session->setup_field('age',filter => sub { $_[0] > 18 } );

=item * hash ref

In this case the only key from the hash that is recognised is "isa" will will chek that the 
given value has the types specified as the value for "isa"

Example : 

    #Check that the 'rights' field is an array
    WWW::Session->setup_field('age',filter => { isa => "ARRAY" } );
    
    #Check that the 'user' field is an MyApp::User object
    WWW::Session->setup_field('user',filter => { isa => "MyApp::User" } );

=back

=head3 triggers

Triggers allow you to execute a code ref when certain events happen on the key.

The return values from the triggers are completely ignored.

Available triggers are:

=over 4 

=item * before_set_value

Executed before the value is actually storred on the code. Arguments sent to the code ref 
are : session object , new value, old value - in this order

=item * after_set_value

Executed after the new value is set on the session object. Arguments sent to the code ref 
are : session object, new value

=item * before_delete

Executed before the key is removed from the session object. Arguments sent to the code ref
are : session object, current_value

=item * after_delete

Executed after the key is removed from the session object. Arguments sent to the code ref
are : session object, previous_value

=back

Example :

    WWW::Session->setup_field(
                            'user',
                            filter => { isa => "MyApp::User" },
                            deflate => sub { $_[0]->id() },
                            inflate => sub { return MyApp::User->find($_[0]) }
                            trigger => { before_set_value => sub { warn "About to set the user },
                                         after_delete => sub { ... },
                                        }
                            );

=cut

sub setup_field {
    my ($self,$field,%settings) = @_;
    
    while (my ($key,$val)  = each %settings) {
        $fields_modifiers->{$field}{$key} = $val;
    }
}

=head2 save

Serializes a WWW::Session object sends it to all storage engines for saving

=cut

sub save {
    my ($self) = @_;
    
    my $data = {
                sid => $self->{sid},
                expires => $self->{expires},
               };
    
    foreach my $field ( keys %{$self->{data}} ) {
        if (defined $fields_modifiers->{$field} && defined $fields_modifiers->{$field}->{deflate}) {
            $data->{data}->{$field} = $fields_modifiers->{$field}->{deflate}->($self->{data}->{$field});
        }
        else {
            $data->{data}->{$field} = $self->{data}->{$field}
        }
    }
    
    my $string = $serializer->serialize($data);
    
    foreach my $storage (@storage_engines) {
        $storage->save($self->{sid},$self->{expires},$string);
    }
}

=head1 ACCESSING SESSION DATA

Allows us to get/set session data directly by calling the field name as a method

Example:

    my $user = $session->user(); #same as $user = $session->get('user');
    
    #or 
    
    $session->age(21); #same as $session->set('age',21);

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $value = shift;

    my $field = $AUTOLOAD;

    $field =~ s/.*:://;

    if (defined $value) {
        $self->set($field,$value);
    }
    
    return $self->get($field);
}


=head1 AUTOSAVE FEATURE

If you set autosave to 1 the session will be saved before the object is 
destroyed if any data has changed

BE CAREFULL : If you store complex structures only the changes made to direct 
session keys will be detected. 

Example :

    #this change will be detected because it affects a direct session attribute
    $session->age(21); 

    #this changes won't be detected :
    my $user = $session->user();
    $user->{age} = 21;
    
You have two choices :

=over 4

=item 1 Make a change that can be detected

    $session->some_random_field( time() );
    
=item 2 Save the session manually

    $session->save();
    
=back
    
=cut

sub DESTROY {
    my $self = shift;
    
    if ($autosave && scalar(keys %{$self->{changed}})) {
        $self->save();
    }
}


=head1 PRIVATE METHODS

=head2 load

Deserializes a WWW::Session object from the given string and deflates all the fields that
were inflated when the session was serialized

=cut

sub load {
    my ($class,$string) = @_;
    
    my $self = $serializer->expand($string);
    
    foreach my $field ( keys %{$self->{data}} ) {
        if (defined $fields_modifiers->{$field} && defined $fields_modifiers->{$field}->{inflate}) {
            $self->{data}->{$field} = $fields_modifiers->{$field}->{inflate}->($self->{data}->{$field});
        }
    }
    
    bless $self,$class;
    
    return $self;
}

=head2 import

Allows us to configure all the module options in one line 

Example :

    use WWW::Session storage => [ 
                                    'File' => { path => '/tmp/sessions'},
                                    'Memcached' => { servers => ['127.0.0.1'] }
                                ],
                     serialization => 'Storable',
                     expires => 3600,
                     fields => {
                         user => {
                             inflate => sub { return Some::Package->new( $_[0]->id() ) },
                             deflate => sub { $_[0]->id() },
                             },
                         age => {
                             filter => [21..99],
                             }
                     },
                     autosave => 1;

=cut

sub import {
    my ($class, %params) = @_;
    
    if (defined $params{storage}) {
        while ( scalar(@{$params{storage}}) ) {
            my $engine = shift @{$params{storage}};
            my $options = shift @{$params{storage}};
            $class->add_storage($engine,$options);
        }
    }
    if (defined $params{serialization}) {
        $class->serialization_engine($params{serialization});
    }
    if (defined $params{expires}) {
        $class->default_expiration_time($params{expires});
    }
    if (defined $params{autosave}) {
        $class->autosave($params{autosave});
    }
    if (defined $params{fields}) {
        foreach my $field (keys %{$params{fields}}) {
            $class->setup_field($field,%{ $params{fields}->{$field} });
        }
    }
}

=head2 run_trigger

Runs a trigger for the given field

=cut
sub run_trigger {
    my $self = shift;
    my $trigger = shift;
    my $field = shift;
    
    if (   exists $fields_modifiers->{$field}
        && defined $fields_modifiers->{$field}{trigger}
        && defined $fields_modifiers->{$field}{trigger}{$trigger} )
    {
        my $trigger = $fields_modifiers->{$field}{trigger}{$trigger};
        die "WWW::Session triggers must be code refs!" unless ref( $trigger ) && ref( $trigger ) eq "CODE";
        $trigger->( $self, @_ );
    }
}


=head1 TIE INTERFACE

The WWW::Session objects can be tied to hashes to make them easier to use

Example :

    my %session;
    
    tie %session, WWW::Session, 'session_id', {user => $user, authenticated => 1};
    
    ...
    my $user = $session{user};

    ...
    $session{authenticated} = 0;
    delete $session{user};

=cut

sub TIEHASH {
    my ($class,@params) = @_;
    
    return $class->find_or_create(@params);
}

sub STORE {
    my ($self,$key,$value) = @_;
    
    $self->set($key,$value);
}

sub FETCH {
    my ($self,$key) = @_;
    
    return $self->get($key);
}

sub DELETE {
    my ($self,$key) = @_;
    
    $self->delete($key);
}

sub CLEAR {
    my ($self) = @_;
    
    $self->{data} = {};
}

sub EXISTS {
    my ($self,$key) = @_;
    
    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my ($self) = @_;
    
    my $a = keys %{ $self->{data} };
    
    each %{ $self->{data} };
}

sub NEXTKEY {
    my ($self) = @_;
    
    return each %{ $self->{data} };
}

sub SCALAR {
    my ($self) = @_;
    
    return scalar %{ $self->{data} };
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Session


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Session
