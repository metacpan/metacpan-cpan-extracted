package UR::Service::JsonRpcServer;

use strict;
use warnings;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object',
    properties => [
        host => { type => 'String', is_transient => 1, default_value => '0.0.0.0', doc => 'The local address to listen on'},
        port => { type => 'String', is_transient => 1, default_value => 8080, doc => 'The local port to listen on'},
        server => { type => 'Net::HTTPServer', is_transient => 1, doc => 'The Net::HTTPServer instance for this Server instance' },
        api_root => { type => 'String', is_transient => 1, default_value => 'URapi' },
    ],
    id_by => ['host','port'],
    doc => 'An object serving as a web server to respond to JSON-RPC requests; wraps Net::HTTPServer',
);

=pod

=head1 NAME

UR::Service::JsonRpcServer - A self-contained JSON-RPC server for UR namespaces

=head1 SYNOPSIS

    use lib '/path/to/your/moduletree';
    use YourNamespace;

    my $rpc = UR::Service::JsonRpcServer->create(host => 'localhost',
                                                 port => '8080',
                                                 api_root => 'URapi',
                                                 docroot => '/html/pages/path',
                                               );
    $rpc->process();

=head1 Description

This is a class containing an implementation of a JSON-RPC server to respond to 
requests involving UR-based namespaces and their objects.  It uses Net::HTTPServer
as the web server back-end library.

Incoming requests are divided into two major categories:

=over 4

=item http://server:port/C<api-root>/class/Namespace/Class

This is the URL for a call to a class metnod on C<Namespace::Class>

=item http://server:port/C<api-root>/obj/Namespace/Class/id

This is the URL for a method call on an object of class Namespace::Class with the given id

=back

=head1 Constructor

The constructor takes the following named parameters:

=over 4

=item host

The hostname to listen on.  This can be an ip address, host name, or undef.
The default value is '0.0.0.0'.  This argument is passed along verbatim to
the Net::HTTPServer constructor.

=item port

The TCP port to listen on.  The default value is 8080.  This argument is passed
along verbatim to the Net::HTTPServer constructor.

=item api_root

The root path that the http server will listen for requests on.  The constructor registers
two paths with the Net::HTTPServer with RegisterRegex() for /C<api_root>/class/* and
/C<api_root>/obj/* to respond to class and instance metod calls.

=back

All other arguments are passed along to the Net::HTTPServer constructor.

=head1 Methods

=over 4

=item $rpc->process()

A wrapper to the Net::HTTPServer Process() method.  With no arguments, this call will
block forever from the perspective of the caller, and process all http requests coming in.
You can optionally pass in a timeout value in seconds, and it will respond to requests
for the given number of seconds before returning.

=back

=head1 Client Side

There are (or will be) client-side code in both Perl and Javascript.  The Perl code is (will be)
implemented as a UR::Context layer that will return light-weight object instances containing only
class info and IDs.  All method calls will be serialized and sent over the wire for the server
process to execute them.

The Javascript interface is defined in the file urinterface.js.  An example:

    var UR = new URInterface('http://localhost:8080/URApi/');  // Connect to the server
    var FooThingy = UR.get_class('Foo::Thingy');  // Get the class object for Foo::Thingy
    var thingy = FooThingy.get(1234);  // Retrieve an instance with ID 1234
    var result = thingy.call('method_name', 1, 2, 3);  // Call $thingy->method_name(1,2,3) on the server


=head1 SEE ALSO

Ney::HTTPServer, urinterface.js

=cut

use Net::HTTPServer;
use JSON;
use Class::Inspector;

sub create {
    my($class,%args) = @_;

    my $api_root = delete $args{'api_root'};

    my $server = Net::HTTPServer->new(%args);
    return unless $server;

    my %create_args = ( host => $args{'host'}, port => $args{'port'} );
    $create_args{'api_root'} = $api_root if defined $api_root;
    my $self = $class->SUPER::create(%create_args);
    return unless $self;

    $self->server($server);
    $server->RegisterRegex("^/$api_root/class/*", sub { $self->_api_entry_classes(@_) } ) if $api_root;
    $server->RegisterRegex("^/$api_root/obj/*", sub { $self->_api_entry_obj(@_) } ) if $api_root;

    my $port = $server->Start();
    if ($args{'port'} eq 'scan') {
        $self->port($port);
    }

    return $self;
}


sub process {
    my $self = shift;

    #$self->server->Process(@_);
    my $server = $self->server;
    $server->Process(@_);
    
}


sub _api_entry_classes {
    my($self,$request) = @_;

    my $response = $request->Response();

    #$DB::single = 1;
    my $data = $self->_get_post_data_from_request($request);
    #my $struct = decode_json($data);
    my $struct = jsonToObj($data);
 
    my $class = $self->_parse_class_from_request($request);
    unless ($class) {
        $response->Code(404);
        $response->Print("Couldn't parse URL " . $request->URL);
        return $response;
    }

    my $method = $struct->{'method'};
    my $params = $struct->{'params'};

    my @retval;

    if ($method eq '_get_class_info') { # called when the other end gets a class object
        eval {
            my $class_object = $class->__meta__;
            my %id_names = map { $_ => 1 } $class_object->all_id_property_names();
            my @id_names = keys(%id_names);
       
            my %property_names = map { $_ => 1 } 
                                 grep { ! exists $id_names{$_} }
                                 $class_object->all_property_names();
            my @property_names = keys(%property_names);
        
            my $possible_method_names = Class::Inspector->methods($class, 'public');
            my @method_names = grep { ! exists $id_names{$_} and ! exists $property_names{$_} }
                               @$possible_method_names;

            push @retval, { id_properties => \@id_names,
                            properties => \@property_names,
                            methods => \@method_names };
        };
    } else {
        eval {
            @retval = $class->$method(@$params);
        };
    }

    my $return_struct = { id => $struct->{'id'}, version => $struct->{'version'}, result => \@retval};
    if ($@) {
        $return_struct->{'result'} = undef;
        $return_struct->{'error'} = $@;
    } else {
        foreach my $item ( @retval ) {
            my $reftype = ref $item;
            if ($reftype && $reftype ne 'ARRAY' && $reftype ne 'HASH') {  # If it's an object of some sort
                my %copy = %$item;
                $copy{'object_type'} = $class;
                $item = \%copy;
            }
        }
        $return_struct->{'result'} = \@retval;
    }


    #my $encoded_result = to_json($return_struct, {convert_blessed => 1});
    my $encoded_result = objToJson($return_struct);
    $response->Print($encoded_result);

    return $response;
}


sub _api_entry_obj {
    my($self,$request) = @_;

    my $response = $request->Response();

    #$DB::single = 1;
    my $data = $self->_get_post_data_from_request($request);
    #my $struct = decode_json($data);
    my $struct = jsonToObj($data);
 
    my($class,$id) = $self->_parse_class_and_id_from_request($request);
    unless ($class) {
        $response->Code(404);
        $response->Print("Couldn't parse URL " . $request->URL);
        return $response;
    }

    my $method = $struct->{'method'};
    my $params = $struct->{'params'};

    my @retval;
    eval {
        my $obj = $class->get($id);
        @retval = $obj->$method(@$params);
    };

    my $return_struct = { id => $struct->{'id'}, version => $struct->{'version'}};
    if ($@) {
        $return_struct->{'result'} = undef;
        $return_struct->{'error'} = $@;
    } else {
        foreach my $item ( @retval ) {
            my $reftype = ref $item;
            if ($reftype && $reftype ne 'ARRAY' && $reftype ne 'HASH') {  # If it's an object of some sort
                my %copy = %$item;
                $copy{'object_type'} = $class;
                $item = \%copy;
            } 
        }
        $return_struct->{'result'} = \@retval;
    }


    #my $encoded_result = to_json($return_struct, {convert_blessed => 1});
    my $encoded_result = objToJson($return_struct);
    $response->Print($encoded_result);

    return $response;
}


    

## This one uses the last part of the URL as the ID - won't work with a generic get()
#sub old_api_entry_point {
#    my($self,$request) = @_;
#
#    my $response = $request->Response();
#
##$DB::single = 1;
#    my $data = $self->_get_post_data_from_request($request);
#    my $struct = decode_json($data);
#
#    my($class,$id) = $self->_parse_class_and_id_from_request($request);
#    unless ($class) {
#        $response->Code(404);
#        $response->Print("Couldn't parse URL " . $request->URL);
#        return $response;
#    }
#
#    my $method = $struct->{'method'};
#    my $params = $struct->{'params'};
#    my @retval;
#    eval {
#        my $obj = $class->get($id);
#        if ($method eq 'get') {
#            my %copy = %$obj;
#            $retval[0] = \%copy;
#        } else {
#            @retval = $obj->$method(@$params);
#        }
#    };
#
#    my $return_struct = { id => $struct->{'id'}, version => $struct->{'version'}};
#    if ($@) {
#        $return_struct->{'result'} = undef;
#        $return_struct->{'error'} = $@;
#    } else {
#        $return_struct->{'result'} = \@retval;
#    }
#
#    
#    my $encoded_result = to_json($return_struct, {convert_blessed => 1});
#    $response->Print($encoded_result);
#
#    return $response;
#}

     
# URLs are expected to look something like this:
# http://server/URapi/Namespace/Class/Name/ID
# and would translate to the class Namespace::Class::Name with the ID property ID
sub _parse_class_and_id_from_request {
    my($self,$request) = @_;

    my $api_root = $self->api_root;
    my $url = $request->URL();

    my @api_root = split(/\//,$api_root);
    my @url_parts = split(/\//, $url);
    shift @url_parts until ($url_parts[0]);

    { no warnings 'uninitialized';
        while($api_root[0] eq $url_parts[0]) {
            shift @api_root;
            shift @url_parts;
        }
    }
    shift @url_parts if ($url_parts[0] eq 'class' || $url_parts[0] eq 'obj');

    my $id = pop @url_parts;
    my $class = join('::', @url_parts);

    return($class,$id);
}

# This works for URLs that don't have an ID at the end
sub _parse_class_from_request {
    my($self,$request) = @_;

    my $api_root = $self->api_root;
    my $url = $request->URL();
    
    my @api_root = split(/\//,$api_root);
    my @url_parts = split(/\//, $url);
    shift @url_parts until ($url_parts[0]);

    { no warnings 'uninitialized';
        while($api_root[0] eq $url_parts[0]) {
            shift @api_root;
            shift @url_parts;
        }
    }

    shift @url_parts if ($url_parts[0] eq 'class' || $url_parts[0] eq 'obj');

    my $class = join('::', @url_parts);
    return $class;
}


sub _get_post_data_from_request {
    my($self,$request) = @_;

    my $message = $request->Request;
    my($data) = ($message =~ m/\r\n\r\n(.*)/m);

    return $data;
}

1;


