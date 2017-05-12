package XAS::Model::Database;

our $VERSION = '0.01';

use Class::Inspector;
use XAS::Model::Schema;
use Params::Validate qw/SCALAR ARRAYREF/;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  constants  => 'DELIMITER PKG REFS ARRAY',
  filesystem => 'File',
  utils      => ':validation',
  exports => {
    hooks => {
      schema => [ \&_schema, 1 ],
      table  => [ \&_tables, 1 ],
      tables => [ \&_tables, 1 ],
    }
  },
;

our $KEYS;
  
#use Data::Dumper;

# ---------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------

sub _tables {
    my $self   = shift;
    my $target = shift;
    my $symbol = shift;
    my $tables = shift;

    $self->tables($tables, 4);

    return $self;

}

sub _schema {
    my $self    = shift;
    my $target  = shift;
    my $symbol  = shift;
    my $schemas = shift;

    $self->schemas($schemas);

    return $self;

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub table {
    my $self = shift;

    $self->tables(@_);

}

sub tables {
    my $self = shift;
    my ($tables, $depth) = validate_params(\@_, [
        { type     => SCALAR | ARRAYREF },
        { optional => 1, default => 3 },
    ]);

    $tables = [ split(DELIMITER, $tables) ] unless (ref($tables) eq ARRAY);

    my ($pkg) = caller($depth);     # presummed caller

    no strict REFS;                 # to register new methods in package
    no warnings;                    # turn off warnings

    foreach my $table (@$tables) {

        # building constants in the calling package.

        if ($table ne ':all') {

            *{$pkg.PKG.$table} = sub { $KEYS->{$table}; };

        } else {

            while (my ($key, $value) = each(%$KEYS)) {

                *{$pkg.PKG.$key} = sub { $value; };

            }

            last;

        }

    }

}

sub schemas {
    my $self = shift;
    my ($schemas) = validate_params(\@_, [
        { type => SCALAR | ARRAYREF },
    ]);

    $schemas = [ split(DELIMITER, $schemas) ] unless (ref($schemas) eq ARRAY);

    foreach my $schema (@$schemas) {

        # loading our schema

        XAS::Model::Schema->load_namespaces(
            result_namespace    => "+$schema" . "::Result",
            resultset_namespace => "+$schema" . "::ResultSet",
        );

        # building our keys

        my $pattern = $schema . '::';
        my $modules = Class::Inspector->subclasses('UNIVERSAL');

        foreach my $module (@$modules) {

            next if ($module =~ /ResultSet/);

            if ($module =~ m/$pattern/) {

                my @parts = split('::', $module);
                my $begin = scalar(@parts) - 1;
                my $name = join('', splice(@parts, $begin, $#parts));

                $KEYS->{$name} = $module;

            }

        }

    }

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Model::Database - A class to load database schemas

=head1 SYNOPSIS

  use XAS::Model::Schema;
  use XAS::Model::Database
    schema => 'ETL::Model::Database',
    table  => 'Master';

  try {

      $schema = XAS::Model::Schema->opendb('database');

      my @rows = Master->search($schema);

      foreach my $row (@rows) {

          printf("Hostname = %s\n", $row->Hostname);

      }

  } catch {

      my $ex = $_;

      print $ex;

  };

=head1 DESCRIPTION

This module loads DBIx::Class table definitions and defines a path for
the database.ini configuration file. It can also load shortcut constants
for table definations. 

Example

    use XAS::Model::Database
      schema => 'ETL::Model::Database',
      table  => 'Master'
    ;

    or

    use XAS::Model::Database
      schema => 'ETL::Model::Database',
      tables => qw( Master Detail )
    ;

    or

    use XAS::Model::Database
      schema => 'ETL::Model::Database',
      table => ':all'
    ;

The difference is that in the first example you are only loading the 
"Master" constant into your module. The second example loads the constants 
"Master" and "Detail". The ":all" qualifier would load all the defined
constants. 

=head1 HOOKS

The following hooks are defined to load table definitions and define
constants. The order that they are called is important, i.e. 'schema' must
come before 'table'.

=head2 schema

This defines a load path to the modules that defines a database schema.
DBIx::Class loads modules based on the path. For example all modules
below 'ETL::Model::Database' will be loaded at once. You can be more
specific. If you only want the 'Progress' database schema you can load
it by using 'ETL::Model::Database::Progress'.
 
=head2 table

This will define a constant for a table definition. This constant is based
on the table name, which is defined by the modules name. So the module
'ETL::Model::Database::Progress::ActOther' will have a constant named
'ActOther' that refers to the module.

B<WARNING>

    If you have multiple tables named the same thing in differant schemas
    and load all the schemas at once, this constant will refer to the last
    loaded table definition.

=head2 tables

Does the same thing as 'table'.

=head1 SEE ALSO

=over 4

=item L<XAS::Model::Database|XAS::Model::Database>

=item L<XAS::Model|XAS::Model>

=item L<XAS|XAS>

=item L<DBIx::Class|https://metacpan.org/pod/DBIx::Class>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
