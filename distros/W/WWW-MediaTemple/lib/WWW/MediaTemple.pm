package WWW::MediaTemple;

use Carp qw(croak);
use JSON;
use XML::Simple;

use base qw(REST::Client);

our $VERSION = 0.02;

sub new {
    my ( $class, %args ) = @_;

    if ( !$args{api_key} ) { croak "new method requires an api key"; }

    my %parent_args = (
        host         => 'https://api.mediatemple.net/api/v1',
        pretty_print => 'true',
        wrap_root    => 'true',
        format       => 'json',
        raw_data     => '',
        key          => ''
    );

    # we prefer the following verbage
    $parent_args{host} = $args{base_host} if $args{base_host};
    $parent_args{key}  = $args{api_key}   if $args{api_key};

    # assign args to parent
    while ( my ( $key, $value ) = each %args ) {
        if ( exists $parent_args{$key} ) {
            $parent_args{$key} = $value;
        }
    }

    my $self = $class->SUPER::new( { host => $parent_args{host} } );
    bless $self, $class;

    foreach my $params ( keys %parent_args ) {
        $self->{$params} = $parent_args{$params};
    }

    $self->getUseragent()->agent("perl-WWW-MediaTemple/$VERSION");
    $self->{headers} = {
        'Content-type' => "application/$self->{format}",
        Accept         => "application/$self->{format}",
        Authorization  => "MediaTemple $self->{key}"
    };

    $self->{params} =
      "prettyPrint=$self->{pretty_print}&wrapRoot=$self->{wrap_root}";

    return $self;
}

sub services {
    my ($self) = @_;

    $self->GET( "/services?" . $self->{params}, $self->{headers} );

    return _dumper($self);
}

sub serviceIds {
    my ($self) = @_;

    $self->GET( "/services/ids?" . $self->{params}, $self->{headers} );

    return _dumper($self);
}

sub service {
    my ( $self, %args ) = @_;

    if ( !$args{serviceId} ) {
        croak "service method requires a serviceId parameter";
    }

    $self->GET( "/services/$args{serviceId}?" . $self->{params},
        $self->{headers} );

    return _dumper($self);
}

sub serviceTypes {
    my ($self) = @_;

    $self->GET( "/services/types?" . $self->{params}, $self->{headers} );

    return _dumper($self);
}

sub serviceOSTypes {
    my ($self) = @_;

    $self->GET( '/services/types/os?' . $self->{params}, $self->{headers} );

    return _dumper($self);
}

sub addService {
    my ( $self, %args ) = @_;

    my $b_content = undef;

    # prepare xml/json
    if ( $self->{format} eq 'xml' ) {
        $b_content = "<service><serviceType>$args{serviceType}</serviceType>"
          . "<primaryDomain>$args{primaryDomain};</primaryDomain>";

        if ( $args{operatingSystem} ) {
            $param .=
              "<operatingSystem>$args{operatingSystem}</operatingSystem>";
        }

        $param .= "</service>";
    }
    else {
        $b_content = "{ \"serviceType\": $args{serviceType}, "
          . "\"primaryDomain\": \"$args{primaryDomain};\"";

        if ( $args{operatingSystem} ) {
            $param .= ", \"operatingSystem\": \"$args{operatingSystem}\"";
        }

        $param .= " }";
    }

    $self->POST( '/services' . $self->{params}, $b_content, $self->{headers} );

    return _dumper($self);
}

sub reboot {
    my ( $self, %args ) = @_;

    if ( !$args{serviceId} ) {
        croak 'reboot method requires a serviceId parameter';
    }

    $self->POST( "/services/$args{serviceId}/reboot?" . $self->{params},
        '', $self->{headers} );

    return _dumper($self);
}

sub flushFirewall {
    my ( $self, %args ) = @_;

    if ( !$args{serviceId} ) {
        croak 'flushFirewall method requires a serviceId parameter';
    }

    $self->POST( "/services/$args{serviceId}/firewall/flush?" . $self->{params},
        '', $self->{headers} );

    return _dumper($self);
}

sub addTempDisk {
    my ( $self, %args ) = @_;

    if ( !$args{serviceId} ) {
        croak 'addTempDisk method requires a serviceId parameter';
    }

    $self->POST( "/services/$args{serviceId}/disk/temp?" . $self->{params},
        '', $self->{headers} );

    return _dumper($self);
}

sub pleskPassword {
    my ( $self, %args ) = @_;

    if ( !$args{serviceId} ) {
        croak 'pleskPassword method requires a serviceId parameter';
    }

    my $b_content = undef;

    if ( $self->{format} eq 'xml' ) {
        $b_content = "<password>$args{password}</password>";
    }
    else {
        $b_content = "{\"password\": \"$args{password}\"}";
    }

    $self->PUT( "/services/$args{serviceId}/pleskPassword?" . $self->{params},
        $b_content, $self->{headers} );

    return _dumper($self);
}

sub setRootPass {
    my ( $self, %args ) = @_;

    if ( !$args{serviceId} ) {
        croak 'setRootPass method requires a serviceId parameter';
    }

    my $b_content = undef;

    if ( $self->{format} eq 'xml' ) {
        $b_content = "<password>$args{password}</password>";
    }
    else {
        $b_content = "{\"password\": \"$args{password}\"}";
    }

    $self->PUT( "/services/$args{serviceId}/rootPassword?" . $self->{params},
        $b_content, $self->{headers} );

    return _dumper($self);
}

sub stats {
    my ( $self, %args ) = @_;

    my ( $added_param, $extra_param ) = undef;

    if ( $args{precision} ) {
        $added_param .= "&precision=" . $arg{precision};
    }
    if ( $args{resolution} ) {
        $added_param .= "&resolution=" . $arg{resolution};
    }
    if ( $args{start} && $arg{end} ) {
        $added_param .= "&start=" . $arg{start} . "&end=" . $arg{end};
    }
    if ( $args{predefined} ) {
        $extra_param = "/$args{predefined}";
    }

    $self->GET(
        "/stats/$args{serviceId}"
          . $extra_param . "?"
          . $self->{params}
          . $added_param,
        $self->{headers}
    );

    return _dumper($self);
}

sub warnings {
    my ($self) = @_;

    $self->GET( "/stats/warnings?" . $self->{params}, $self->{headers} );

    return _dumper($self);
}

sub thresholds {
    my ($self) = @_;

    $self->GET( "/stats/warnings/thresholds?" . $self->{params},
        $self->{headers} );

    return _dumper($self);
}

sub _dumper {
    my ($self) = @_;

    my ( $init_mod, $ret_val );

    # return object based on constructor
    # ( xml object, json object, or raw xml/json text)
    if ( $self->{format} eq 'xml' and !$self->{raw_data} ) {
        $init_mod = XML::Simple->new();
        $ret_val  = $init_mod->XMLin(
            $self->responseContent,
            KeyAttr    => [],
            ForceArray => 0
        );
    }

    if ( $self->{format} eq 'json' and !$self->{raw_data} ) {
        $ret_val = JSON->new->utf8->decode( $self->responseContent );
    }

    if ( $self->{raw_data} ) {
        $ret_val = $self->responseContent;
    }

    return $ret_val;
}

1;

__END__

=head1 NAME

WWW::MediaTemple - A Perl interface to the Media Temple API

=head1 VERSION

Version 0.02

=head1 SYNPOSIS

    use WWW::MediaTemple;

    my $api = WWW::MediaTemple->new(
        api_key => 'your_api_key'
    );

    $api->setRootPasswd( serviceId => '000001',
                         password  => '!f4k3p455w0rd'
    );

=head1 DESCRIPTION

This module is intended to provide an interface between Perl and the Media
Temple API. The Media Temple API is a RESTful web service. In order to use this
module you must provide an api key which requires a valid account. For more
information please see http://wiki.mediatemple.net/w/Category:API   

=head1 CONSTRUCTOR

=head2 new()

Creates and returns a new WWW::MediaTemple object

    my $api= WWW::MediaTemple->new()

=over 4

=item * C<< api_key => [your_api_key] >>

The api_key parameter is required. You must provide a valid key.

=item * C<< pretty_print => [true|false} >>

This parameter allows you to enable the pretty print function of the API. By
default this parameter is set to true

=item * C<< wrap_root => [true|false] >>

This parameter defaults to 'true'. It wraps the json object with the root
object name. Specifying 'false' will not wrap the object.

=item * C<< format => [json|xml] >>

The data format you intend PUT, POST and GET. Currently defaults to JSON

=item * C<< raw_data => [true|false] >>

Return raw data in xml and or json format opposed to an object

=back

=head1 SUBROUTINES/METHODS

=head2 $obj->services

get the service info for all services

=head2 $obj->serviceIds

get a list of all service ids

=head2 $obj->service(...)

get the service info for a single service

* B< serviceId > S< (integer, required: true, default: none) >

    $obj->service( serviceId => 000001 );

=head2 $obj->serviceTypes

get a list of valid service types

=head2 $obj->serviceOSTypes

get a list of OS's that can be installed on a (ve)

=head2 $obj->addService(...)

create a new service

* B< serviceType > S< (integer, required: true, default: none) >

* B< primaryDomain > S< (string, required: true(dv only), default: none, (ve) autogenerates a domain) >

* B< operatingSystem > S< (integer, required: true, default: Ubuntu 9.10 (16) ) >

    $obj->addService( operatingSystem => 16, 
                      serviceType     => 000001,
                      primaryDomain   => 'snakeoil.dom'
    );

=head2 $obj->reboot(...)

reboot the specified service

* B< serviceId > S< integer, required: true, default: none >

    $obj->reboot( serviceId => 000001 );

=head2 $obj->flushFirewall(...)

flushes the firewall rules on the specified service

* B< serviceId > S< integer, required: true, default: none >

    $obj->flushFirewall( serviceId => 000001 );

=head2 $obj->addTempDisk(...)

adds temporary disk space for the specified service

* B< serviceId > S< integer, required: true, default: none >

    $obj->addTempDisk( serviceId => 000001 );

=head2 $obj->pleskPassword(...)

set plesk password for the specified service

* B< serviceId > S< integer, required: true, default: none >

    $obj->pleskPassword( serviceId => 000001 );

=head2 $obj->setRootPass(...)

set the root password for the specified service

* B< serviceId > S< integer, required: true, default: none >

    $obj->setRootPass( serviceId => 000001 );

=head2 $obj->stats(...)

get the stats for a single service

* B< start > S< (integer, required: false, default: none, beginning range in epoch seconds) >

* B< end > S< (integer, required: false, default: none, end range in epoch seconds >

* B< resolution > S< (integer, required: false, default: 15, The interval of data points in seconds to request >

* B< precision > S< (integer, required: false, default: 2, Digits to the right of the decimal>

* B< predefined > S< (integer, required: false, default: get stats over a predefined range (5min, 1year)>

* B< NOTE: When using a predefined range the C<start> option will be ignored>

    $obj->stats( predefined => '5min', 
                 resolution => 10,
                 precision  => 5
    );

=head2 $obj->warnings

get the service warnings for an account

=head2 $obj->thresholds

get the service warning thresholds

=head2 _dumper

convert API output into XML, JSON or raw output based on constructor parameters

=head1 DIAGNOSTICS 

N/A at the current point in time

=head1 CONFIGURATION AND ENVIRONMENT

No special configuration and or configuration files are needed. This module is
intended to run in any and all environment.

=head1 INCOMPATIBILITIES

This package is intended to be compatible with Perl 5.008 and beyond.

=head1 BUGS AND LIMITATIONS

Please use https://forums.mediatemple.net to provide bug reports and or
feedback concerning the API.

=head1 DEPENDENCIES

B<REST::Client>, B<XML::Simple>, B<JSON>

=head1 SEE ALSO

B<http://mediatemple.net/api>

=head1 SUPPORT

The module is provided free of support however feel free to contact the
author or current maintainer with questions, bug reports, and patches.

Considerations will be taken when making changes to the API. Any changes to its
interface will go through at the least one deprecation cycle.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 (mt) Media Temple, INC.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for a
particular purpose.

=head1 Author

Casey Vega <cvega@mediatemple.net>

=cut

