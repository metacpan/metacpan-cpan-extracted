package Yancy::Plugin::OpenAPI;
our $VERSION = '0.002';
# ABSTRACT: Generate an OpenAPI spec and API for a Yancy schema

#pod =head1 SYNOPSIS
#pod
#pod   use Mojolicious::Lite;
#pod   plugin Yancy => 'sqlite:data.db';
#pod   plugin OpenAPI => { route => '/api' };
#pod   app->start;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin generates an OpenAPI specification from your database
#pod schema. The generated spec has endpoints to create, read, update,
#pod delete, and search for items in your database.
#pod
#pod =head1 CONFIGURATION
#pod
#pod These configuration keys can be part of the hash reference passed to the
#pod C<plugin> call.
#pod
#pod =head2 route
#pod
#pod The base route path for the generated API. Can be a string or
#pod a L<Mojolicious::Routes> object.
#pod
#pod =head2 title
#pod
#pod The title of the API, used in the OpenAPI spec. See also L</info>.
#pod
#pod =head2 info
#pod
#pod The C<info> section of the OpenAPI spec. A hash reference.
#pod
#pod =head2 host
#pod
#pod The host key of the OpenAPI spec. Defaults to the value of
#pod L<Sys::Hostname/hostname>.
#pod
#pod =head2 model
#pod
#pod The L<Yancy::Model> object to use. Defaults to
#pod L<Mojolicious::Plugin::Yancy/model>.
#pod
#pod =head2 default_controller
#pod
#pod The default controller to use for generated API routes. Defaults to
#pod C<yancy>, the L<Yancy::Controller::Yancy> controller.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious::Plugin::OpenAPI>, L<Yancy>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw( true false );
use Mojo::Util qw( url_escape );
use Yancy::Util qw( json_validator );
use Sys::Hostname qw( hostname );

# XXX: This uses strings from Yancy::I18N. They should probably be moved
# here, which means we need a way to add namespaces to I18N, or
# a separate plugin I18N object/namespace

has moniker => 'openapi';
has route =>;
has model =>;
has app =>;

sub register {
  my ( $self, $app, $config ) = @_;
  $self->app( $app );
  $self->model( $config->{model} // $app->yancy->model );
  $config->{default_controller} //= 'yancy';

  # XXX: Throw an error if there is already a route here
  my $route = $app->yancy->routify( $config->{route} );
  $self->route( $route );

  # First create the OpenAPI schema and API URL
  my $spec = $self->_openapi_spec_from_schema( $config );
  $self->_openapi_spec_add_mojo( $spec, $config );

  my $openapi = $app->plugin(
    'Mojolicious::Plugin::OpenAPI' => {
      route => $route,
      spec => $spec,
      default_response_name => '_Error',
    },
  );
}

sub _openapi_find_schema_name {
  my ( $self, $path, $pathspec ) = @_;
  return $pathspec->{'x-schema'} if $pathspec->{'x-schema'};
  my $schema_name;
  for my $method ( grep !/^(parameters$|x-)/, keys %{ $pathspec } ) {
    my $op_spec = $pathspec->{ $method };
    my $schema;
    if ( $method eq 'get' ) {
      # d is in case only has "default" response
      my ($response) = grep /^[2d]/, sort keys %{ $op_spec->{responses} };
      my $response_spec = $op_spec->{responses}{$response};
      next unless $schema = $response_spec->{schema};
    } elsif ( $method =~ /^(put|post)$/ ) {
      my @body_params = grep 'body' eq ($_->{in} // ''),
        @{ $op_spec->{parameters} || [] },
        @{ $pathspec->{parameters} || [] },
        ;
      die "No more than 1 'body' parameter allowed" if @body_params > 1;
      next unless $schema = $body_params[0]->{schema};
    }
    next unless my $this_ref =
      $schema->{'$ref'} ||
      ( $schema->{items} && $schema->{items}{'$ref'} ) ||
      ( $schema->{properties} && $schema->{properties}{items} && $schema->{properties}{items}{'$ref'} );
    next unless $this_ref =~ s:^#/definitions/::;
    die "$method '$path' = $this_ref but also '$schema_name'"
      if $this_ref and $schema_name and $this_ref ne $schema_name;
    $schema_name = $this_ref;
  }
  if ( !$schema_name ) {
    ($schema_name) = $path =~ m#^/([^/]+)#;
    die "No schema found in '$path'" if !$schema_name;
  }
  $schema_name;
}

# mutates $spec
sub _openapi_spec_add_mojo {
  my ( $self, $spec, $config ) = @_;
  for my $path ( keys %{ $spec->{paths} } ) {
    my $pathspec = $spec->{paths}{ $path };
    my $schema = $self->_openapi_find_schema_name( $path, $pathspec );
    die "Path '$path' had non-existent schema '$schema'"
      if !$spec->{definitions}{$schema};
    for my $method ( grep !/^(parameters$|x-)/, keys %{ $pathspec } ) {
      my $op_spec = $pathspec->{ $method };
      my $mojo = $self->_openapi_spec_infer_mojo( $path, $pathspec, $method, $op_spec );
      # XXX Allow overriding controller on a per-schema basis
      # This gives more control over how a certain schema's items
      # are written/read from the database
      $mojo->{controller} = $config->{default_controller};
      $mojo->{schema} = $schema;
      $op_spec->{ 'x-mojo-to' } = $mojo;
    }
  }
}

# for a given OpenAPI operation, figures out right values for 'x-mojo-to'
# to hook it up to the correct CRUD operation
sub _openapi_spec_infer_mojo {
  my ( $self, $path, $pathspec, $method, $op_spec ) = @_;
  my @path_params = grep 'path' eq ($_->{in} // ''),
    @{ $pathspec->{parameters} || [] },
    @{ $op_spec->{parameters} || [] },
    ;
  my ($id_field) = grep defined,
    (map $_->{'x-id-field'}, $op_spec, $pathspec),
    (@path_params && $path_params[-1]{name});
  if ( $method eq 'get' ) {
    # heuristic: is per-item if have a param in path
    if ( $id_field ) {
      # per-item - GET = "read"
      return {
        action => 'get',
        format => 'json',
      };
    }
    else {
      # per-schema - GET = "list"
      return {
        action => 'list',
        format => 'json',
      };
    }
  }
  elsif ( $method eq 'post' ) {
    return {
      action => 'set',
      format => 'json',
    };
  }
  elsif ( $method eq 'put' ) {
    die "'$method' $path needs id_field" if !$id_field;
    return {
      action => 'set',
      format => 'json',
    };
  }
  elsif ( $method eq 'delete' ) {
    die "'$method' $path needs id_field" if !$id_field;
    return {
      action => 'delete',
      format => 'json',
    };
  }
  else {
    die "Unknown method '$method'";
  }
}

sub _openapi_spec_from_schema {
  my ( $self, $config ) = @_;
  my ( %definitions, %paths );
  my %parameters = (
    '$limit' => {
      name => '$limit',
      type => 'integer',
      in => 'query',
      description => $self->app->l( 'OpenAPI $limit description' ),
    },
    '$offset' => {
      name => '$offset',
      type => 'integer',
      in => 'query',
      description => $self->app->l( 'OpenAPI $offset description' ),
    },
    '$order_by' => {
      name => '$order_by',
      type => 'string',
      in => 'query',
      pattern => '^(?:asc|desc):[^:,]+$',
      description => $self->app->l( 'OpenAPI $order_by description' ),
    },
    '$match' => {
      name => '$match',
      type => 'string',
      enum => [qw( any all )],
      default => 'all',
      in => 'query',
      description => $self->app->l( 'OpenAPI $match description' ),
    },
  );
  for my $schema_name ( $self->model->schema_names ) {
    # Set some defaults so users don't have to type as much
    my $schema = $self->model->schema( $schema_name )->info;
    next if $schema->{ 'x-ignore' };
    my $id_field = $schema->{ 'x-id-field' } // 'id';
    my @id_fields = ref $id_field eq 'ARRAY' ? @$id_field : ( $id_field );
    my $real_schema_name = ( $schema->{'x-view'} || {} )->{schema} // $schema_name;
    my $props = $schema->{properties}
      || $self->model->schema( $real_schema_name )->info->{properties};
    my %props = %$props;

    $definitions{ $schema_name } = $schema;

    for my $prop ( keys %props ) {
      $props{ $prop }{ type } ||= 'string';
    }

    $paths{ '/' . $schema_name } = {
      get => {
        description => $self->app->l( 'OpenAPI list description' ),
        parameters => [
          { '$ref' => '#/parameters/%24limit' },
          { '$ref' => '#/parameters/%24offset' },
          { '$ref' => '#/parameters/%24order_by' },
          { '$ref' => '#/parameters/%24match' },
          map {
            my $name = $_;
            my $type = ref $props{ $_ }{type} eq 'ARRAY' ? $props{ $_ }{type}[0] : $props{ $_ }{type};
            my $description = $self->app->l(
               $type eq 'number' || $type eq 'integer' ? 'OpenAPI filter number description'
               : $type eq 'boolean' ? 'OpenAPI filter boolean description'
               : $type eq 'array' ? 'OpenAPI filter array description'
               : 'OpenAPI filter string description'
            );
            {
              name => $name,
              in => 'query',
              type => $type,
              description => $self->app->l( 'OpenAPI filter description', $name ) . $description,
            }
          } grep !exists( $props{ $_ }{'$ref'} ), sort keys %props,
        ],
        responses => {
          200 => {
            description => $self->app->l( 'OpenAPI list response' ),
            schema => {
              type => 'object',
              required => [qw( items total )],
              properties => {
                total => {
                  type => 'integer',
                  description => $self->app->l( 'OpenAPI list total description' ),
                },
                items => {
                  type => 'array',
                  description => $self->app->l( 'OpenAPI list items description' ),
                  items => { '$ref' => "#/definitions/" . url_escape $schema_name },
                },
                offset => {
                  type => 'integer',
                  description => $self->app->l( 'OpenAPI list offset description' ),
                },
              },
            },
          },
          default => {
            description => $self->app->l( 'Unexpected error' ),
            schema => { '$ref' => '#/definitions/_Error' },
          },
        },
      },
      $schema->{'x-view'} ? () : (post => {
        parameters => [
          {
            name => "newItem",
            in => "body",
            required => true,
            schema => { '$ref' => "#/definitions/" . url_escape $schema_name },
          },
        ],
        responses => {
          201 => {
            description => $self->app->l( 'OpenAPI create response' ),
            schema => {
              @id_fields > 1
              ? (
                type => 'array',
                items => [
                  map +{
                    '$ref' => '#/' . join '/', map { url_escape $_ }
                      'definitions', $schema_name, 'properties', $_,
                  }, @id_fields,
                ],
              )
              : (
                '$ref' => '#/' . join '/', map { url_escape $_ }
                  'definitions', $schema_name, 'properties', $id_fields[0],
              ),
            },
          },
          default => {
            description => $self->app->l( "Unexpected error" ),
            schema => { '$ref' => "#/definitions/_Error" },
          },
        },
      }),
    };

    $paths{ sprintf '/%s/{%s}', $schema_name, $id_field } = {
      parameters => [
        map +{
          name => $_,
          in => 'path',
          required => true,
          type => 'string',
          'x-mojo-placeholder' => '*',
        }, @id_fields
      ],

      get => {
        description => $self->app->l( 'OpenAPI get description' ),
        responses => {
          200 => {
            description => $self->app->l( 'OpenAPI get response' ),
            schema => { '$ref' => "#/definitions/" . url_escape $schema_name },
          },
          default => {
            description => $self->app->l( "Unexpected error" ),
            schema => { '$ref' => '#/definitions/_Error' },
          }
        }
      },

      $schema->{'x-view'} ? () : (put => {
        description => $self->app->l( 'OpenAPI update description' ),
        parameters => [
          {
            name => "newItem",
            in => "body",
            required => true,
            schema => { '$ref' => "#/definitions/" . url_escape $schema_name },
          }
        ],
        responses => {
          200 => {
            description => $self->app->l( 'OpenAPI update response' ),
            schema => { '$ref' => "#/definitions/" . url_escape $schema_name },
          },
          default => {
            description => $self->app->l( "Unexpected error" ),
            schema => { '$ref' => "#/definitions/_Error" },
          }
        }
      },

      delete => {
        description => $self->app->l( 'OpenAPI delete description' ),
        responses => {
          204 => {
            description => $self->app->l( 'OpenAPI delete response' ),
          },
          default => {
            description => $self->app->l( "Unexpected error" ),
            schema => { '$ref' => '#/definitions/_Error' },
          },
        },
      }),
    };
  }

  return {
    info => $config->{info} || { title => $config->{title} // "OpenAPI Spec", version => "1" },
    swagger => '2.0',
    host => $config->{host} // hostname(),
    schemes => [qw( http )],
    consumes => [qw( application/json )],
    produces => [qw( application/json )],
    definitions => {
      _Error => {
        'x-ignore' => 1, # In case we get round-tripped into a Yancy::Model
        title => $self->app->l( 'OpenAPI error object' ),
        type => 'object',
        properties => {
          errors => {
            type => "array",
            items => {
              required => [qw( message )],
              properties => {
                message => {
                  type => "string",
                  description => $self->app->l( 'OpenAPI error message' ),
                },
                path => {
                  type => "string",
                  description => $self->app->l( 'OpenAPI error path' ),
                }
              }
            }
          }
        }
      },
      %definitions,
    },
    paths => \%paths,
    parameters => \%parameters,
  };
}

1;

__END__

=pod

=head1 NAME

Yancy::Plugin::OpenAPI - Generate an OpenAPI spec and API for a Yancy schema

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin Yancy => 'sqlite:data.db';
  plugin OpenAPI => { route => '/api' };
  app->start;

=head1 DESCRIPTION

This plugin generates an OpenAPI specification from your database
schema. The generated spec has endpoints to create, read, update,
delete, and search for items in your database.

=head1 CONFIGURATION

These configuration keys can be part of the hash reference passed to the
C<plugin> call.

=head2 route

The base route path for the generated API. Can be a string or
a L<Mojolicious::Routes> object.

=head2 title

The title of the API, used in the OpenAPI spec. See also L</info>.

=head2 info

The C<info> section of the OpenAPI spec. A hash reference.

=head2 host

The host key of the OpenAPI spec. Defaults to the value of
L<Sys::Hostname/hostname>.

=head2 model

The L<Yancy::Model> object to use. Defaults to
L<Mojolicious::Plugin::Yancy/model>.

=head2 default_controller

The default controller to use for generated API routes. Defaults to
C<yancy>, the L<Yancy::Controller::Yancy> controller.

=head1 SEE ALSO

L<Mojolicious::Plugin::OpenAPI>, L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
