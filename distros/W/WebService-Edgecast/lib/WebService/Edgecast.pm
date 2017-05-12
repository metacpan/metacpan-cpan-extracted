package WebService::Edgecast;
BEGIN {
  $WebService::Edgecast::VERSION = '0.01.00';
}

# ABSTRACT: Perl interface to Edgecast's SOAP API

use strict;
use warnings;

BEGIN {
# XXX Commened out becuase it breaks builds on some Debian lenny boxes

#    use metaclass (
#        metaclass   => 'Moose::Meta::Class',
#        error_class => 'Moose::Error::Confess',
#    );
}

use Carp;
use Moose;
use XML::Simple;
use Module::Pluggable search_path => [ __PACKAGE__ . '::auto' ];

has 'email'       => ( is => 'ro', isa => 'Str', required   => 1, );
has 'password'    => ( is => 'ro', isa => 'Str', required   => 1, );
has 'credentials' => ( is => 'ro', isa => 'Str', lazy_build => 1, );
has 'soap'        => ( is => 'rw', isa => 'Any', lazy_build => 1, );

has 'uri' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'EC:WebServices',
);

has 'error' => (
    is        => 'rw',
    isa       => 'Str|Undef',
    clearer   => 'clear_error',
    predicate => 'has_error',
);

has 'interfaces' => (
    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,
);

has 'client_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'p',
);

has 'security_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'bas',
);

has 'api_type' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'set_api_type',
    trigger => \&_validate_api_type,
);

has 'api_types' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub {
        [
            qw/
              administration
              realtime
              mediamanager
              reporting
              /
        ];
    },
);

no Moose;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    unless ( $self->api_type ) {
        croak 'To make API calls you must set an API type in the '
          . 'constructor, or using the set_api_type() method once '
          . 'the object has been instantiated.';
    }

    ( my $method = $AUTOLOAD ) =~ s/.*\::(.+)$/$1/;

    $self->_do_call( $method, @_ );
}

sub _do_call {
    my $self   = shift;
    my $method = shift;
    my $args   = shift;
    my $raw    = delete $args->{'raw'};
    my $params = { strCredential => $self->credentials };
    my $get    = "get_$method".'Result';
    my $fault  = 'get_faultstring';

    if ($args) {
        foreach my $key ( keys %$args ) {
            $params->{$key} = delete $args->{$key};
        }
    }

    unless ( $self->soap->can($method) ) {
        $self->error(
            "Method '$method' is invalid. Please see the perldoc for package "
          . ref($self->soap) . ' for a list of all valid methods'
        );
        return; 
    }

    my $result = $self->soap->$method($params);

    if ( $result->can($fault) ) {
        my $fault_str = $result->$fault;
        $self->error("$fault_str");
        return;
    } else { 
        $self->clear_error if $self->has_error;
        return $raw ? $result : $self->_parse_xml($result->$get);
    }
}

sub _validate_api_type {
    my $self     = shift;
    my $api_type = shift;
    my $regexp   = join '|', @{ $self->api_types };
    my $fmt = join "\n", map { "\t" . ucfirst( lc $_ ) } @{ $self->api_types };

    unless ( $api_type =~ /^($regexp)$/i ) {
        croak "API type '$api_type' is unsupported. The following are "
          . "valid types:\n$fmt\n";
    }

    # (re)build our soap object with the new api_type
    $self->soap($self->_build_soap);
}

sub _parse_xml {
    my $self = shift;
    my $xml  = shift;

    return unless defined $xml;

    unless ($xml =~ /^\<opt\>.*\<\/opt\>$/) {
        $xml = "<opt>$xml</opt>";
    }

    return XMLin($xml);
}

sub _build_credentials {
    my $self = shift;

    return join( ':',
        map { $self->$_ } qw/ client_type security_type email password / );
}

sub _build_interfaces {
    my $self = shift;
    my %out  = ();

    foreach my $type ( @{ $self->api_types } ) {
        my $module =
          ( grep /$type/i, grep /::Interface::/, $self->plugins )[0];

        #XXX Probably want to warn here
        next unless $module;

        $out{ lc($type) } = $module;
    }

    return {%out};
}

sub _build_soap {
    my $self = shift;
    my $type = $self->api_type;
    my $soap = $self->interfaces->{ lc($type) };
    my $req  = $soap;

    $req =~ s/::/\//g;
    $req .= '.pm';

    eval { require "$req" };
    croak "Failed to require auto-generated class '$soap': $@"
      if $@;

    return $soap->new
      or croak "Failed to instantiate auto-generated class '$soap': $!";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WebService::Edgecast - Perl interface to Edgecast's SOAP API

=head1 VERSION

version 0.01.00

=head1 SYNOPSIS

    use Data::Dumper;
    use WebService::Edgecast;
    
    my $client = WebService::Edgecast->new({
        email    => 'foo@yoo.com',
        password => '...',
        api_type => 'administration',
    });
    
    my $result = $client->CustomerGet({
        strCustomerId => '29D8'
    });
    
    print $client->error || Dumper($result);

=head1 B<I<THIS IS ALPHA SOFTWARE>>

I repeat, this is B<ALPHA> software. For the time being use at your own
risk, but if you do use it B<please report> any found bugs or issues to
the author. Once this module has done the rounds in a production environment
and has been tweaked appropriately this disclaimer will be removed.

=head1 DESCRIPTION

This module implements a simiplified OO SOAP client for Edgecast's CDN
API. It uses C<SOAP::WSDL> to generate all the interface and type classes
from Edgecast's public WSDL descriptions, thus it supports B<all> the
functions defined in Edgecast's API documentation.

=over 4

I<If you are developing against the Edgecast API I am assuming you have
their API documentation in hand. Since this module simply provides an
object interface to their API you'll be spending most of your time
referencing their documentation for the details on supported functions.>

=back

=head2 For Example

In Edgecast's API documentation you might find the following method
definition in the Real-Time Reporting section:

    Method: BandwidthGet
    
    Description: This method call will get the real time bandwidth (bps = bits
                 per second) for a media type. Data updates every minute. 
    
    Parameters:
        strCredential - The EdgeCast credential required to authenticate the client.
        strCustomerId - The unique alphanumeric account number (AN) of the customer,
                        such as "0002" or "00F3".
        intMediaType  - 2=Flash, 3=HTTP Large Object, 4=HTTP Small Object
        
    Return Value:
        A double representing real time bits per second (bps).

This means that when using C<WebService::Edgecast> all you have to do is
invoke the desired method call on the object, and pass in the appropriate
parameters in a hashref, ala:

    my $result = $client->BandwidthGet({
        strCustomerId => '29D8',
        intMediaType  => 3,
    });

Note that you B<do not> have to pass in the C<strCredential> parameter
when calling these methods. This is because when you instantiate your
C<WebService::Edgecast> object you pass in your Edgecast email/password
combo, and your C<strCredential> is generated and automatically used for
every subsequent method call you make.

=head1 API TYPES

At the time of this writing, Edgecast supports four different API's. For
the purpose of this module I am refering to each API as an C<api_type>,
which is the value you pass into the constructor. They are:

=over 4

=item 1 Reporting - Access reporting features such as bytes transferred and hits

api_type : C<reporting>E<10>
endpoint : I<http://api.edgecast.com/v1/Reporting.asmx>

=item 2 Real Time - Access real time reporting such as connections and bandwidth

api_type : C<realtime>E<10>
endpoint : I<http://api.edgecast.com/v1/RealTime.asmx>

=item 3 Media Manager - Perform file / media management functions such as load and purge  

api_type : C<mediamanager>E<10>
endpoint : I<http://api.edgecast.com/v1/MediaManager.asmx>

=item 4 Administration - for partners / resellers to manage their customers

api_type : C<administration>E<10>
endpoint : I<http://api.edgecast.com/v1/Administration.asmx>

=back

=over 4

I<NOTE: You do not need to worry about the C<endpoint> values above when using
this module. They are only there for reference so you know what the source of
all the auto-generated code is.>

=back

So if you need to run a method from the RealTime Reporting API you need to make
sure you instantiate your C<WebService::Edgecast> object with the appropriate
C<api_type>. For the above example where we call the C<BandwidthGet> method
you would need to instantiate your object with the 'realtime' C<api_type>:

    my $client = WebService::Edgecast->new({
        email    => 'foo@yoo.com',
        password => '...',
        api_type => 'realtime',
    });

=head2 Switching API Type at Runtime

If your application requires access to more than one C<api_type> at run time
you can either have several C<WebService::Edgecast> objects, one for each
type you need, B<OR> you can use a single object and switch the C<api_type>
as needed. To do this use the C<set_api_type> method. For example.

    my $client = WebService::Edgecast->new({
        email    => 'foo@yoo.com',
        password => '...',
        api_type => 'administration',
    });
    
    my $result = $client->CustomerGet({...});

    # Process result from Administration API

    $client->set_api_type('realtime');

    $result = $client->BandwidthGet({...}); 

    # Process result from RealTime API

=head1 ERRORS

For any given method call C<WebService::Edgecast> traps any errors returned
and stuffs them into the object's C<error> attribute, and returns C<undef> as
it's result. So to do error checking on the client side you'll probably want
to use one of the following idioms:

    my $result = $client->METHOD({...});

    if ($client->error) {
        croak "Got error: " . $client->error;
    } else {
        # Do something with data
    }

      - OR - 

    my $result = $client->METHOD({...})
        or croak "Got error: " . $client->error;

    # Do something with data

=head1 OBJECT ATTRIBUTES

Beyond instantiating your object with required email, password, and api_type
parameters, there are other attributes whose default values you can override
to customize your SOAP client further. They all have resonable defaults that
you probably wont need to modify, but in the case(s) where you do have to use
different values C<WebService::Edgecast> let's you do just that. They are: 

=over 4

=item * C<uri>

Default: C<EC:WebServices>

See the C<SOAP::Lite> example in the Edgecast API documentation for an
example of where this value is being used internally.

=item * C<client_type>

Defualt: C<p>

This can either be C<p>, for Partner, or C<c>, for Customer. They represent
two different APIs.

=item * C<security_type>

Default: C<bas>

The default, C<bas>, stands for basic security. At the time of writing this
is the only security type supported by Edgecast.

=back

=head1 GENERATED CODE

As noted earlier, the bulk of this module is code automatically generated
by C<SOAP::WSDL>. If you start poking through the source tree you'll see
that the namespace gets I<very> deep and verbose... borderline horrific
actually. I mean really:

 WebService::Edgecast::auto::Reporting::Interface::EdgeCastWebServices::EdgeCastWebServicesSoap

Yuck!

The good news, however, is that the whole point of this module is to
abstract that namespace from you so that all you have to deal with is the
C<WebService::Edgecast> namespace, and nothing more.

But if you're curious and want to poke around in the auto-generateed code
you can find it under the C<CDN/Edgecast/Client/auto/> directory. A lot,
if not most. of those modules have POD that's directly generated from the
WSDL description. So if you don't have direct access to Edgecast's API
documentation you can use the POD in those modules as an alternative
reference.

=head1 SEE ALSO 

=head2 Mooooooose

C<Moose> is the object framwork this module is based on.

=over 4

=item * Home Page - http://www.iinteractive.com/moose

=item * CPAN -  http://search.cpan.org/search?query=Moose

=back

=head2 Edgecast Documentation and WSDLs

The human-readable Edgecast API documentation for Partners and Customers
can be obtained directly from Edgecast, and is avalialbe in PDF. WSDL 
descriptions for each of the 4 APIs can be found at the following URLs:

=over 4

=item * Reporting - http://api.edgecast.com/v1/Reporting.asmx?WSDL

=item * RealTime - http://api.edgecast.com/v1/RealTime.asmx?WSDL

=item * MediaManager - http://api.edgecast.com/v1/MediaManager.asmx?WSDL

=item * Administration - http://api.edgecast.com/v1/Administration.asmx?WSDL

=back

=head2 C<SOAP::WSDL> and C<Dist::Zilla>

This module was built using C<Dist::Zilla> and one of its plugins that
utilizes C<SOAP::WSDL>.

=over 4

=item * C<Dist::Zilla> Home Page - http://dzil.org

=item * C<Dist::Zilla> CPAN - http://search.cpan.org/search?query=Dist+Zilla

=item * C<Dist::Zilla::Plugin::WSDL> CPAN - http://search.cpan.org/search?query=Dist+Zilla+WSDL

=back

=head1 SUPPORT

Please email the author directly for any support or bug related issues.

=head1 AUTHOR

James Conerly I<E<lt>jconerly@cpan.orgE<gt>> 2010

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by James Conerly.

This is free software, licensed under I<The Artistic License 2.0>. Please
see the LICENSE file included in this package for more detailed information.

=cut