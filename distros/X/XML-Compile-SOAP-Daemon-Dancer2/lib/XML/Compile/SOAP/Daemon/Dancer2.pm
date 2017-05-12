package XML::Compile::SOAP::Daemon::Dancer2;
use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.07';
use Dancer2::Plugin;
use Dancer2::FileUtils 'path';
use Class::Load qw(try_load_class);
use Carp;

use XML::Compile::SOAP::Daemon::Dancer2::Handler;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::SOAP12;

sub get_implementation {
    my ( $class_name, $dsl ) = @_;
    my ($ok, $error) = try_load_class($class_name);
    if (! $ok) {
        confess "Cannot load implementation class $class_name: $error";
    }

    my $implementation = $class_name->new( dsl => $dsl );

    die "Implementation class needs to do the role XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation"
        unless $implementation->DOES('XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation');

    return $implementation;
}

register 'wsdl_endpoint' => sub {
    my ($dsl, $path, $options) = @_;

    my $settings = plugin_setting;
    my $wsdl_path = path( $dsl->setting('appdir'), $settings->{wsdl_path}//"wsdl" );
    my $xsd_path = path( $dsl->setting('appdir'), $settings->{xsd_path}//"wsdl" );

    for my $key ( qw(wsdl) ) {
        confess "$key option mandatory when calling wsdl_endpoint" unless exists $options->{$key};
    }

    my $wsdl_file = path( $wsdl_path, $options->{wsdl} );
    unless( -f $wsdl_file ) {
        confess "wsdl file not found ($wsdl_file)";
    }

    my $wsdl = XML::Compile::WSDL11->new( $wsdl_file  );

    if( exists $options->{xsd} ) {
        if( ref $options->{xsd} eq 'ARRAY' ) {
            for my $file ( @{$options->{xsd}} ) {
                my $xsd_file = path( $xsd_path, $file );
                $wsdl->importDefinitions( $xsd_file );
            }
        } else {
            confess 'xsd must be an array ref of xsd files';
        }
    }

    my $operations = {};
    if( exists $options->{operations} ) {
        confess "operation should be a hasref of operation => sub {}" unless ref $options->{operations} eq "HASH";
        $operations = $options->{operations};
    }
    if( exists $options->{implementation_class} ) {
        #class provided for inplementation
        #try to load the class
        my $implementation = get_implementation( $options->{implementation_class}, $dsl );

        for my $operation ( $wsdl->operations() ) {
            #$dsl->error( $operation->action );
            if( my $call = $implementation->can("soapaction_".$operation->action) ) {
                $operations->{$operation->action} = sub { $implementation->$call( @_ ) };
            }
        }
    }

    my $daemon = XML::Compile::SOAP::Daemon::Dancer2::Handler->new();

    $daemon->operationsFromWSDL(
        $wsdl,
        callbacks => $operations,
    );

    $dsl->app->add_route(
        method  => 'get',
        regexp  => $path,
        code    => sub {
            my $params = $dsl->params;

            if( exists $params->{wsdl} ) {
                $dsl->content_type( 'application/wsdl+xml' );
                $dsl->send_file( $wsdl_file , system_path => 1 );
            }
        }
    );

    $dsl->app->add_route(
        method  => 'post',
        regexp  => $path,
        code    => sub {
            $daemon->handle( $dsl );
        }
    );
};

register_plugin;
1;
__END__

=encoding utf-8

=head1 NAME

XML::Compile::SOAP::Daemon::Dancer2 - simple implementation of a WSDL server within Dancer2

=head1 SYNOPSIS

    package MyDancer2App;
    use Dancer2;
    use XML::Compile::SOAP::Daemon::Dancer2;

    wsdl_endpoint '/calculator', {
        wsdl                    => 'calculator.wsdl',
        xsd                     => [],
        implementation_class    => 'Calculator',
        operations  => {
            add => sub {
                my ( $soap, $data, $dsl ) = @_;
                $dsl->error( $dsl->to_dumper( $data ) );
                return +{
                    Result => $data->{parameters}->{x} + $data->{parameters}->{y},
                };
            },
        }
    };

=head1 DESCRIPTION

XML::Compile::SOAP::Daemon::Dancer2 is a plugin to add a SOAP endpoint to a Dancer2 app

The plugin is Heavily inspired by XML::Compile::SOAP::Daemon::PSGI

The plugin export a keyword wsdl_endpoint, that takes 2 arguments, a route path and an options hashref.

Options available are:
* wsdl: name of the wsdl file (under appdir/wsdl)
* xsd: an arrayref of xsd file (under appdir/wsdl)
* implementation_class: name of class to implement the operations
* operations: hashref with soap operation name as key, sub as value
* implementation_class : the class needs to do the role XML::Compile::SOAP::Daemon::Dancer2::Role::Implementation

For each operation, define a sub in the implementation class, soapaction_{operation_name}, each sub will be called with
the following parameters: $soap, $data, $dsl

operations: each sub will be called with parameters: $soap, $data, $dsl

=head1 AUTHOR

Pierre VIGIER E<lt>pierre.vigier@gmail.comE<gt>

=head1 CONTRIBUTORS

Mohamad Hallal L<https://github.com/mohdhallal>

=head1 COPYRIGHT

Copyright 2016- Pierre VIGIER

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
