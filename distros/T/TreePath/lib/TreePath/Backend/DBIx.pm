package TreePath::Backend::DBIx;
$TreePath::Backend::DBIx::VERSION = '0.22';
use Moose::Role;
use base 'DBIx::Class::Schema';
use Carp qw/croak/;
use Path::Class;
use Hash::Merge;

use FindBin '$Bin';
require UNIVERSAL::require;


my $attrs = {
             # starting with v3.3, SQLite supports the "IF EXISTS" clause to "DROP TABLE",
             # even though SQL::Translator::Producer::SQLite 1.59 isn't passed along this option
             # see https://rt.cpan.org/Ticket/Display.html?id=48688
             sqlite_version => 3.3,
             add_drop_table => 0,
             no_comments => 0,
             RaiseError => 1,
             PrintError => 0,
            };

has dsn          => (
                     is        => 'rw',
                     default   => sub {
                       my $self = shift;
                       return $self->model_config->{'connect_info'}->{dsn};
                     }
                    );

has model_config => (
                     is         => 'rw',
                     lazy_build => 1,
                    );

has 'schema'     => (
                     is        => 'rw',
                     predicate => 'has_schema',
                     lazy_build      => 1,
                    );

has '_source_name' => (
                is       => 'rw',
                isa      => 'Str',
               );

has '_populate_backend' => (
                is       => 'rw',
                isa      => 'Int',
               );

sub _build_model_config {
  my $self = shift;

  my $model_config = $self->conf->{$self->config->{backend}->{args}->{model}}
      or croak "'backend/args/model' is not defined in conf file !";
  return $model_config
}

sub _build_schema {
  my $self = shift;

  my($dsn, $user, $password, $allattrs) = $self->_connect_info;

  my $schema_class =  $self->model_config->{schema_class};
  eval "require $schema_class";
  if( $@ ){
    die("Cannot load $schema_class : $@");
  }
  return $schema_class->connect($dsn,$user,$password,$allattrs);
}


sub _connect_info {
  my $self = shift;

  my $model_config = $self->model_config;

  my ($dsn, $user, $password, $unicode_option, $db_type);
  eval {
    if (!$dsn)
      {
        if (ref $model_config->{'connect_info'}) {

          $dsn      = $model_config->{'connect_info'}->{dsn};
          $user     = $model_config->{'connect_info'}->{user};
          $password = $model_config->{'connect_info'}->{password};

          # Determine database type amongst: SQLite, Pg or MySQL
          $dsn =~ m/^dbi:(\w+)/;
          $db_type = lc($1);
          my %unicode_connection_for_db = (
                'sqlite' => { sqlite_unicode    => 1 },
                'pg'     => { pg_enable_utf8    => 1 },
                'mysql'  => { mysql_enable_utf8 => 1 },

                );
          $unicode_option = $unicode_connection_for_db{$db_type};
        }
        else {
          $dsn = $model_config->{'connect_info'};
        }
      }
  };

  if ($@) {
    die "Your DSN line in " . $self->conf . " doesn't look like a valid DSN.";
  }
  die "No valid Data Source Name (DSN).\n" if !$dsn;
  $dsn =~ s/__HOME__/$FindBin::Bin\/\.\./g;

  if ( $db_type eq 'sqlite' ){
    $dsn =~ m/.*:(.*)$/;
    my $dir = dir($1)->parent;
    $dir->mkpath;
  }

  my $merge    = Hash::Merge->new( 'LEFT_PRECEDENT' );
  my $allattrs = $merge->merge( $unicode_option, $attrs );

  return $dsn, $user, $password, $allattrs;
}



sub _load {
    my $self = shift;

    $self->_log("Loading tree from dbix");

    $self->_populate_backend($self->config->{backend}->{args}->{'populate_backend'})
        if ( $self->can('_populate_backend') && ! defined $self->_populate_backend && defined $self->config->{backend}->{args}->{'populate_backend'} );

    my $schema = $self->schema;
    my @sources_name = keys %{$self->config->{backend}->{args}->{sources_name}}
        or croak "'backend/args/sources_name' is not defined in conf file !";

    my @datas;
   foreach my $source_name ( @sources_name ) {

       my($dsn, $user, $password, $allattrs) = $self->_connect_info;
       $self->_source_name($source_name);
       eval { $schema->resultset($source_name)->count };

      if ( $@ ) {
          print "Deploy and populate $dsn\n" if $self->debug;
          $schema->deploy;
          $schema->_populate if ( $schema->can('_populate') && $self->_populate_backend);
      }
      my $rs = $self->schema->resultset($source_name)->search();

       my @primary_columns = $rs->result_source->primary_columns;
       croak "Multi-column primary keys are not supported." if (scalar @primary_columns > 1 );
       croak "No primary key found." if (scalar @primary_columns == 0 );
       my $primary_key = shift @primary_columns;

       foreach my $row ( $rs->all) {
           my $obj = $self->_row_to_obj($row);
           $obj->{$primary_key} = $row->$primary_key;
           push(@datas,$obj);
       }
   }
    return \@datas;
}


sub _row_to_obj {
    my $self = shift;
    my $row  = shift;


    my $result_source = ref($row);
    my ($source) = ($result_source =~ /^.*::(.*)/s);

    my $obj = {};

    my $cols = $self->config->{backend}->{args}->{sources_name}->{$source}->{columns}
        or croak "backend/args/sources_name/$source/columns is not defined in conf file !";

    foreach my $col (@$cols) {

        my $value = $row->$col;

        # it's not a relationship'
        if ( ! ref($value)) {
            $obj->{$col} = $value;
        }
        # relationship has_many (not already tested)
        elsif ( ref($value) eq 'DBIx::Class::ResultSet') {
            my @results = $row->$col;
            $obj->{$col} = [];
            #  save rs in array
            foreach my $res (@results) {
                push( @{$obj->{$col}}, $self->_rs_to_obj_key($res));
            }
        }
        # relationship belongs_to
        else {
            # save result in hashref
            $obj->{$col} = { $self->_rs_to_obj_key($row->$col) => 1 };
        }
    }
    # Ajout de la source a l'objet
    $obj->{source} = $source;
    return $obj;
}


sub _rs_to_obj_key {
    my $self = shift;
    my $row  = shift;

    my $result_source = ref($row);
    my ($source) = ($result_source =~ /^.*::(.*)/s);
    return $source . '_' . $row->id ;
}


# sub _create {
#     my $self = shift;
#     my $node = shift;

#     my $clone = $self->_clone_node($node);
#     $self->schema->resultset($self->_source_name)->create($clone);
# }

# sub _update {
#     my $self = shift;
#     my $node = shift;

#     my $clone = $self->_clone_node($node);
#     $self->schema->resultset($self->_source_name)->update_or_create($clone);
# }

# sub _delete {
#     my $self  = shift;
#     my $nodes = shift;

#     foreach my $node (@$nodes) {
#         $self->schema->resultset($self->_source_name)->find($node->{id})->delete;
#     }
# }



=head1 NAME

TreePath::Backend::DBIx - Backend 'DBIx' for TreePath

=head1 VERSION

version 0.22

=head1 CONFIGURATION

         $tp = TreePath->new(  conf  => 't/conf/treefromdbix.yml'  );

         # t/conf/treefromdbix.yml
         Model::TPath:
           schema_class: Schema::TPath
           connect_info:
             dsn: 'dbi:SQLite:dbname=:memory:'

         TreePath:
           debug: 0
           backend:
             name: DBIx
             args:
               model: Model::TPath
               populate_backend: 1
               sources_name:
                 Page:
                   columns:
                     - name
                     - parent
                   search_field: name
                   parent_field: parent

                 Comment:
                   columns:
                     - page
                   parent_field: page


=head2 REQUIRED SCHEMA

See t/lib/Schema/TPath.pm

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Daniel Brosseau.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
