package Workflow::Config::XML;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Config );
use Log::Any qw( $log );
use Workflow::Exception qw( configuration_error );
use Carp qw(croak);
use Syntax::Keyword::Try;

$Workflow::Config::XML::VERSION = '2.05';

my %XML_OPTIONS = (
    action => {
        ForceArray =>
            [ 'action', 'field', 'source_list', 'param', 'validator', 'arg' ],
        KeyAttr => [],
    },
    condition => {
        ForceArray => [ 'condition', 'param' ],
        KeyAttr    => [],
    },
    persister => {
        ForceArray => ['persister'],
        KeyAttr    => [],
    },
    validator => {
        ForceArray => [ 'validator', 'param' ],
        KeyAttr    => [],
    },
    workflow => {
        ForceArray => [
            'extra_data', 'state',
            'action',     'resulting_state',
            'condition',  'observer'
        ],
        KeyAttr => [],
    },
    observer => {
        ForceArray => [ 'observer' ],
        KeyAttr => [],
    }
);

my $XML_REQUIRED = 0;

sub parse {
    my ( $self, $type, @items ) = @_;

    $self->_check_config_type($type);
    my @config_items = Workflow::Config::_expand_refs(@items);
    return () unless ( scalar @config_items );

    my @config = ();
    foreach my $item (@config_items) {
        my $file_name = ( ref $item ) ? '[scalar ref]' : $item;
        $log->info("Will parse '$type' XML config file '$file_name'");
        my $this_config;
        try {
            $this_config = $self->_translate_xml( $type, $item );
        }
        catch ($error) {
            # If processing multiple config files, this makes it much easier
            # to find a problem.
            croak $log->error("Processing $file_name: ", $error);
        }
        $log->info("Parsed XML '$file_name' ok");

        # This sets the outer-most tag to use
        # when returning the parsed XML.
        my $outer_tag = $self->get_config_type_tag($type);
        if ( ref $this_config->{$outer_tag} eq 'ARRAY' ) {
            $log->debug("Adding multiple configurations for '$type'");
            push @config, @{ $this_config->{$outer_tag} };
        } else {
            $log->debug("Adding single configuration for '$type'");
            push @config, $this_config;
        }
    }
    return @config;
}

# $config can either be a filename or scalar ref with file contents

sub _translate_xml {
    my ( $self, $type, $config ) = @_;
    unless ($XML_REQUIRED) {
        try {
            require XML::Simple;
        }
        catch ($error) {
            configuration_error "XML::Simple must be installed to parse ",
                "configuration files/data in XML format";
        }

        XML::Simple->import(':strict');
        $XML_REQUIRED++;
    }
    my $options = $XML_OPTIONS{$type} || {};
    my $data = XMLin( $config, %{$options} );
    return $data;
}

1;

__END__

=pod

=head1 NAME

Workflow::Config::XML - Parse workflow configurations from XML content

=head1 VERSION

This documentation describes version 2.05 of this package

=head1 SYNOPSIS

 my $parser = Workflow::Config->new( 'xml' );
 my $conf = $parser->parse( 'condition',
                            'my_conditions.xml', 'your_conditions.xml' );

=head1 DESCRIPTION

Implementation of configuration parser for XML files/data; requires
L<XML::Simple> to be installed. See L<Workflow::Config> for C<parse()>
description.

=head2 METHODS

=head3 parse ( $type, @items )

This method parses the configuration provided it is in XML format.

Takes two parameters: a $type indication and an array of of items

Returns a list of config parameters as a array upon success.

=head1 SEE ALSO

=over

=item * L<XML::Simple>

=item * L<Workflow::Config>

=back

=head1 COPYRIGHT

Copyright (c) 2004-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
