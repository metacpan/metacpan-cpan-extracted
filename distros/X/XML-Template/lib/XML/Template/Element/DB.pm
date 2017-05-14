###############################################################################
# XML::Template::Element::DB
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::DB;
use base qw(XML::Template::Element XML::Template::Element::Iterator);

use strict;
use XML::Template::Element::Iterator;
use IO::String;

use vars qw($AUTOLOAD);


=pod

=head1 NAME

XML::Template::Element::DB - XML::Template module that implements the SQL
tagset.

=head1 SYNOPSIS

This XML::Template module implements the SQL tagset.  XML::Template plugin
modules that query SQL databases should be derived from this module.  The
database and table to query are associated with the namespace of the tags
and is specified in the XML::Template configuration file (see
L<XML::Template::Config>).

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 SQL TAGSET METHODS

=head2 select

This method implements a SELECT SQL query on the database and table
associated with the tag's namespace.  If this tag is nested in a related
namespace, the column will be selected via an intermediate mapping
database table, defined in the XML::Template configuration file. For
instance, suppose the following XML is parsed:

  <xml xmlns:group="http://syrme.net/xml-template/group/v1"
       xmlns:item="http://syrme.net/xml-template/item/v1">
    <group:select name="group1">
      <item:select fields="*" name="item1">
        ...
      </item:select>
    </group:select>
  </xml>

The relationship table that maps items to groups should be defined in the 
XML::Template configuration file.  If the relation table is group2item, 
the following SQL would be generated for the item tag:

  SELECT * FROM items,group2item
           WHERE items.itemname=group2item.itemname
                 AND group2item.groupname='group1'
                 AND group2item.itemname='item1'

The following attributes are used:

=over 4

=item name

A comma-separated list of the names of the primary keys of the database
column to select.  The primary keys and their order is specified in the
XML::Template configuration file.  This attribute is not required.

=item fields, field

A comma separated list of the database table fields to return.  To return 
all fields, use '*'.  For each field returned a variable will be set with 
the field's name and value.  These variables will be available in the 
content of the select element.

=back

Remaining attributes will be used to constrain the selection.  For 
instance, the element

  <block:select name="block1" fields="*"
                title="Title" description="Desc"/>

will result in the following SQL query

  SELECT * FROM blocks
           WHERE blockname='block1'
                 AND title='Title'
                 AND description='Desc'

The value of a remaining attribute may be a comma-separated list, in which 
case, each element in the list is combined into an OR clause.  So the 
following element:

  <block:select name="block1" fields="*" title="Title,Title2"/>

would produce the following SQL query:

  SELECT * FROM blocks
           WHERE blockname='block1'
           AND (title='Title' OR title='Title2')

In addition, if the value of a remaining attribute contains a '%', the 
LIKE comparison will be used rather than =.  For instance,

  <block:select fields="blockname,body" title="%Title%"/>

would produce the following SQL query:

  SELECT blockname,body FROM blocks
                        WHERE title LIKE '%Title%'

=cut

sub select {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Get attribs.
  my $name   = $self->get_attrib ($attribs, 'name')              || 'undef';
  my $fields = $self->get_attrib ($attribs, ['fields', 'field']) || 'undef';

  # Generate named params assignments for the remaining atttribs.
  my $attribs_named_params = $self->generate_named_params ($attribs);

  # Get database info.
  my $namespace = $self->namespace ();
  my $source_mapping_info = $self->get_source_mapping_info (namespace => $namespace);
  my $dbname = $source_mapping_info->{source};
  my $table  = $source_mapping_info->{table};
  my $keys   = $source_mapping_info->{keys};

  my $outcode = qq!
do {
  \$vars->create_context ();

  my \%attribs = ($attribs_named_params);
  \$vars->set (\%attribs);

  my \$tables = '$table';
  my \$where;

  if (defined $name) {
    my \@names = split (/\\s*,\\s*/, $name);
    my \$i = 0;
    foreach my \$key (split (',', '$keys')) {
      \$where .= ' and ' if defined \$where;
      \$where .= "$table.\$key='\$names[\$i]'";
      \$i++;
    }
  }
  my \$twhere = \$process->generate_where (\\\%attribs, '$table');
  if (defined \$where && defined \$twhere) {
    \$where .= " and \$twhere";
  } elsif (defined \$twhere) {
    \$where = \$twhere;
  }

no strict;
  my \$parent_namespace = \$__parent_namespace;
  my \@parent_names     = \@__parent_names;
use strict;

  if (defined \$parent_namespace) {
    my \$parent_namespace_info = \$process->get_source_mapping_info (namespace => \$parent_namespace);
    if (defined \$parent_namespace_info->{relation} &&
        defined \$parent_namespace_info->{relation}->{'$namespace'}) {
      my \$rtable = \$parent_namespace_info->{relation}->{'$namespace'}->{table};

      \$tables .= ",\$rtable";

      my \$i = 0;
      foreach my \$key (split (',', '$keys')) {
        \$where .= ' and ' if defined \$where;
        \$where .= "$table.\$key=\$rtable.\$key";
        \$i++;
      }

      \$i = 0;
      foreach my \$key (split (',', \$parent_namespace_info->{keys})) {
        \$where .= ' and ' if defined \$where;
        \$where .= "\$rtable.\$key='\$parent_names[\$i]'";
        \$i++;
      }
    }
  }

  my \$result;
#  if (defined \$where) {
    my \$db = \$process->get_source ('$dbname');
    if (defined \$db) {
      \$result = \$db->select (Table	=> \$tables,
                             Where	=> \$where);
      die XML::Template::Exception->new ('DB', \$db->error ()) if defined \$db->error ();
      if (defined \$result) {
        if (defined $fields) {
          my \$fields = $fields;
          if (\$fields eq '*') {
            \$vars->set (\%\$result);
          } else {
            foreach my \$field (split (/\\s*,\\s*/, \$fields)) {
              \$vars->set (\$field => \$result->{\$field});
            }
          }
        }
      }
    }
#  }

  my \$__parent_namespace = '$namespace';
  my \@__parent_names;
  if (defined $name) {
    \@__parent_names = split (/\\s*,\\s*/, $name);
  } else {
    if (defined \$result) {
      foreach my \$key (split (/\\s*,\\s*/, '$keys')) {
        push (\@__parent_names, \$result->{\$key});
      }
    }
  }

  $code

  \$vars->delete_context ();
};
  !;
#print "$outcode";

  return $outcode;
}

=pod

=head2 update

This method implements an UPDATE SQL query on the database and table
associated with the tag's namespace.  If this tag is nested in a related
namespace, the column to be updated will be determined via an intermediate
mapping database table, defined in the XML::Template configuration file.  
See C<select> for more details on related namespaces.

The children of this element should be tags with names of the database
table columns and their new values.  For instance:

  <xml xmlns:item="http://syrme.net/xml-template/block/v1">
    <item:update name="item1">
      <item:title>Title</item:title>
      <item:description>Description</item:description>
    </item:update>
  </xml>

These children tags are handled by the AUTOLOAD subroutine.

The following attributes are used:

=over 4

=item name

A comma-separated list of the names of the primary keys of the database
column to select.  The primary keys and their order is specified in the
XML::Template configuration file.  This attribute is required for 
updating.

=item insert

If C<true>, insert a new column in the database table if the one named by
the attribute C<name> is not found.  The default value is C<false>.

=back

Remaining attributes will be used to constrain the selection of which 
column to update.  See C<select> for more details.

=cut

sub update {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Get attribs.
  my $name   = $self->get_attrib ($attribs, 'name')   || 'undef';
  my $insert = $self->get_attrib ($attribs, 'insert') || 'undef';

  # Generate named params assignments for the remaining atttribs.
  my $attribs_named_params = $self->generate_named_params ($attribs);

  # Get database info.
  my $namespace = $self->namespace ();
  my $source_mapping_info = $self->get_source_mapping_info (namespace => $namespace);
  my $dbname = $source_mapping_info->{source};
  my $table  = $source_mapping_info->{table};
  my $keys   = $source_mapping_info->{keys};

  my$outcode = qq!
do {
  \$vars->create_context ();

  my \%attribs = ($attribs_named_params);
  \$vars->set (\%attribs);

  my \$tables = '$table';
  my (\%values, \$where);

  if (defined $name) {
    my \@names = split (/\\s*,\\s*/, $name);
    my \$i = 0;
    foreach my \$key (split (',', '$keys')) {
      \$where .= ' and ' if defined \$where;
      \$where .= "$table.\$key='\$names[\$i]'";
      \$i++;
    }
  }
  my \$twhere = \$process->generate_where (\\\%attribs, '$table');
  if (defined \$where && defined \$twhere) {
    \$where .= " and \$twhere";
  } elsif (defined \$twhere) {
    \$where = \$twhere;
  }
  my \$select_where = \$where;

no strict;
  my \$parent_namespace = \$__parent_namespace;
  my \@parent_names     = \@__parent_names;
use strict;

  if (defined \$parent_namespace) {
    my \$parent_namespace_info = \$process->get_namespace_info (\$parent_namespace);
    if (defined \$parent_namespace_info->{relatedto} &&
        defined \$parent_namespace_info->{relatedto}->{'$namespace'}) {
      \$tables .= ",\$parent_namespace_info->{relatedto}->{'$namespace'}->{table}";

      my \$i = 0;
      foreach my \$key (split (',', '$keys')) {
        \$select_where .= ' and ' if defined \$where;
        \$select_where .= "$table.\$key=\$parent_namespace_info->{relatedto}->{'$namespace'}->{table}.\$key";
        \$i++;
      }

      \$i = 0;
      foreach my \$key (split (',', \$parent_namespace_info->{key})) {
        \$select_where .= ' and ' if defined \$where;
        \$select_where .= "\$parent_namespace_info->{relatedto}->{'$namespace'}->{table}.\$key='\$parent_names[\$i]'";
        \$i++;
      }
    }
  }

  my (\$__parent_namespace, \@__parent_names);
  if (defined $name) {
    \$__parent_namespace = '$namespace';
    \@__parent_names = split (/\\s*,\\s*/, $name);
  }

  $code

  if (defined $name) {
    my \$db = \$process->get_source ('$dbname');
    if (defined \$db) {
      my \$result = \$db->select (Table	=> \$tables,
                                Where	=> \$select_where);
      die XML::Template::Exception->new ('DB', \$db->error ()) if defined \$db->error ();
      if (defined \$result) {
        \$db->update (Table	=> '$table',
                     Values	=> \\\%values,
                     Where	=> \$where)
          || die XML::Template::Exception->new ('DB', \$db->error ());
      } else {
        my \$insert = $insert;
        if (defined \$insert && \$insert =~ /^true\$/i) {
          if (defined $name) {
            my \@names = split (/\\s*,\\s*/, $name);
            my \$i = 0;
            foreach my \$key (split (',', '$keys')) {
              \$values{\$key} = \$names[\$i] if \! exists \$values{\$key};
              \$i++;
            }
          }
          \$db->insert (Table	=> '$table',
                       Values	=> \\\%values)
            || die XML::Template::Exception->new ('DB', \$db->error ());

          if (defined \$parent_namespace) {
            my \$parent_namespace_info = \$process->get_namespace_info (\$parent_namespace);
            if (defined \$parent_namespace_info->{relatedto} &&
              defined \$parent_namespace_info->{relatedto}->{'$namespace'}) {
              my \%map_values;
              foreach my \$key (split (',', '$keys')) {
                \$map_values{\$key} = \$values{\$key};
              }

              my \$i = 0;
              foreach my \$key (split (',', \$parent_namespace_info->{key})) {
                \$map_values{\$key} = \$parent_names[\$i];
                \$i++;
              }

              \$db->insert (Table     => \$parent_namespace_info->{relatedto}->{'$namespace'}->{'table'},
                           Values     => \\\%map_values)
                || die XML::Template::Exception->new ('DB', \$db->error ());
            }
          }
        }
      }
    }
  }
};
!;

  return $outcode;
}

=pod

=head2 insert

This method implements an INSERT SQL query on the database and table 
associated with the tag's namespace.  If this tag is nested in a related 
namespace, the relation table defined in the XML::Template configuration 
file that maps rows between the two related tables will be updated.  
See C<select> for more details on related namespaces.

The children of this element should be tags with names of the database 
table columns and their new values.  See C<update> for more details.

The following attributes are used:

=over 4

=item name

A comma-separated list of the names of the primary keys of the database
column to insert.  The primary keys and their order is specified in the
XML::Template configuration file.  This attribute is required for
inserting.

=back

=cut

sub insert {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Get attribs.
  my $name   = $self->get_attrib ($attribs, 'name')   || 'undef';

  # Get database info.
  my $namespace = $self->namespace ();
  my $source_mapping_info = $self->get_source_mapping_info (namespace => $namespace);
  my $dbname = $source_mapping_info->{source};
  my $table  = $source_mapping_info->{table};
  my $keys   = $source_mapping_info->{keys};

  my $outcode = qq!
do {
  \$vars->create_context ();

  my (\%values, \$where);

  if (defined $name) {
    my \@names = split (/\\s*,\\s*/, $name);
    my \$i = 0;
    foreach my \$key (split (',', '$keys')) {
      \$values{\$key} = \$names[\$i];
      \$where .= ' and ' if defined \$where;
      \$where .= "$table.\$key='\$names[\$i]'";
      \$i++;
    }
  }

  my (\$parent_namespace, \@parent_names);
no strict;
  \$parent_namespace = \$__parent_namespace;
  \@parent_names  = \@__parent_names;
use strict;

  my (\$__parent_namespace, \@__parent_names);
  if (defined $name) {
    \$__parent_namespace = '$namespace';
    \@__parent_names = split (/\\s*,\\s*/, $name);
  }

  $code

  my \$db = \$process->get_source ('$dbname');
  if (defined \$db) {
    if (\! \$db->insert (Table	=> '$table',
                       Values	=> \\\%values)) {
      die XML::Template::Exception->new ('DB', \$db->error ())
        if \! defined \$parent_namespace;
    }

    if (defined \$parent_namespace) {
      my \$parent_namespace_info = \$process->get_source_mapping_info (namespace => \$parent_namespace);
      if (defined \$parent_namespace_info->{relation} &&
          defined \$parent_namespace_info->{relation}->{'$namespace'}) {
        my \$rtable = \$parent_namespace_info->{relation}->{'$namespace'}->{table};

        my \%map_values;
        foreach my \$key (split (',', '$keys')) {
          \$map_values{\$key} = \$values{\$key};
        }

        my \$i = 0;
        foreach my \$key (split (',', \$parent_namespace_info->{keys})) {
          \$map_values{\$key} = \$parent_names[\$i];
          \$i++;
        }

        \$db->insert (Table	=> \$rtable,
                     Values	=> \\\%map_values)
          || die XML::Template::Exception->new ('DB', \$db->error ());
      }
    }
  }
};
!;
#print $outcode;

  return $outcode;
}

=pod

=head2 delect

This method implements a DELETE SQL query on the database and table 
associated with the tag's namespace.  If this tag is nesterd in a related 
namespace, the column to be updated will be determined via an intermediate 
maping database table, defined in the XML::Template configuration file.  
See C<select> for more details on related namespaces.

The following attributes are used:

=over 4

=item name

A comma-separated list of the names of the primary keys of the database
column to delete.  The primary keys and their order is specified in the
XML::Template configuration file.  This attribute is not required.

=back

Remaining attributes will be used to constrain the selection of which
column to delete.  See C<select> for more details.

=cut

sub delete {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Get attribs.
  my $name = $self->get_attrib ($attribs, 'name') || 'undef';

  # Generate named params assignments for the remaining atttribs.
  my $attribs_named_params = $self->generate_named_params ($attribs);

  # Get database info.
  my $namespace = $self->namespace ();
  my $source_mapping_info = $self->get_source_mapping_info (namespace => $namespace);
  my $dbname = $source_mapping_info->{source};
  my $table  = $source_mapping_info->{table};
  my $keys   = $source_mapping_info->{keys};

  my $outcode = qq{
do {
  \$vars->create_context ();

  my \%attribs = ($attribs_named_params);

  my \@names;

no strict;
  my \$parent_namespace = \$__parent_namespace;
  my \@parent_names  = \@__parent_names;
use strict;

  my \$table;
  if (defined \$parent_namespace) {
    my \$parent_namespace_info = \$process->get_source_mapping_info (namespace => \$parent_namespace);
    if (defined \$parent_namespace_info->{relation} &&
        defined \$parent_namespace_info->{relation}->{'$namespace'}) {
      \$table = \$parent_namespace_info->{relation}->{'$namespace'}->{table};
    } else {
      \$table = '$table';
    }
  } else {
    \$table = '$table';
  }

  my \$where;

  if (defined $name) {
    \@names = split (/\\s*,\\s*/, $name);
    my \$i = 0;
    foreach my \$key (split (',', '$keys')) {
      \$where .= ' and ' if defined \$where;
      \$where .= "\$table.\$key='\$names[\$i]'";
      \$i++;
    }
  }
  my \$twhere = \$process->generate_where (\\\%attribs, '$table');
  if (defined \$where && defined \$twhere) {
    \$where .= " and \$twhere";
  } elsif (defined \$twhere) {
    \$where = \$twhere;
  }

  if (defined \$parent_namespace) {
    my \$parent_namespace_info = \$process->get_source_mapping_info (namespace => \$parent_namespace);
    if (defined \$parent_namespace_info->{relation} &&
        defined \$parent_namespace_info->{relation}->{'$namespace'}) {
      my \$i = 0;
      foreach my \$key (split (',', \$parent_namespace_info->{keys})) {
        \$where .= ' and ' if defined \$where;
        \$where .= "\$table.\$key='\$parent_names[\$i]'";
        \$i++;
      }
    }
  }

  my (\$__parent_namespace, \@__parent_names);
  if (defined $name) {
    \$__parent_namespace = '$namespace';
    \@__parent_names = split (/\\s*,\\s*/, $name);
  }

  $code

  my \$result;
  if (defined \$where) {
    my \$db = \$process->get_source ('$dbname');
    if (defined \$db) {
      \$db->delete (Table	=> \$table,
                   Where	=> \$where)
        || die XML::Template::Exception->new ('DB', \$db->error ());
    }

    if (defined $name) {
      my \$parent_namespace_info = \$process->get_source_mapping_info (namespace => \$parent_namespace);
      if (! defined \$parent_namespace
          || (defined \$parent_namespace
              && (! defined \$parent_namespace_info->{relation}
                  || ! defined \$parent_namespace_info->{relation}->{'$namespace'}))) {

        my \$namespace_info = \$process->get_namespace_info ('$namespace');
        if (defined \$namespace_info->{relation}) {
          foreach my \$namespace (keys \%{\$namespace_info->{relatedion}}) {
            my \$source_mapping_info = \$process->get_source_mapping_info (namespace => \$namespace);
            my \$rtable = \$source_mapping_info->{relation}->{\$namespace}->{table};

            my \$where;
            \@names = split (/\\s*,\\s*/, $name);
            my \$i = 0;
            foreach my \$key (split (',', '$keys')) {
              \$where .= ' and ' if defined \$where;
              \$where .= "\$rtable.\$key='\$names[\$i]'";
              \$i++;
            }

            if (defined \$db) {
              \$db->delete (Table	=> \$rtable,
                            Where	=> \$where)
                || die XML::Template::Exception->new ('DB', \$db->error ());
            }
          }
        }
      }
    }
  }

  \$vars->delete_context ();
};
  };

  return $outcode;
}

=pod

=head2 alter

This method implements an ALTER SQL query on the database and table 
associated with the tag's namespace.  The following attributes are used:

=over 4

=item values

=item action

=item columns, column

=item new_column

=item type

=item length

=item decimals

=item unsigned

=item zerofull

=item binary

=item null

=item def_default

=item auto_increment

=item def_primary_key

=item position

=item index

=item primary_key

=item unique

=item fulltext

=item default

=item new_table

=cut

sub alter {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Get attribs.
  my $values         = $self->get_attrib ($attribs, 'values')   || 'undef';
  my $action         = $self->get_attrib ($attribs, 'action')   || 'undef';
  my $columns        = $self->get_attrib ($attribs, ['columns', 'column']) || 'undef';
  my $new_column     = $self->get_attrib ($attribs, 'new_column') || 'undef';
  my $type           = $self->get_attrib ($attribs, 'type')     || 'undef';
  my $length         = $self->get_attrib ($attribs, 'length')   || 'undef';
  my $decimals       = $self->get_attrib ($attribs, 'decimals') || 'undef';
  my $unsigned       = $self->get_attrib ($attribs, 'unsigned') || 'undef';
  my $zerofill       = $self->get_attrib ($attribs, 'zerofull') || 'undef';
  my $binary         = $self->get_attrib ($attribs, 'binary')   || 'undef';
  my $null           = $self->get_attrib ($attribs, 'null')     || 'undef';
  my $def_default    = $self->get_attrib ($attribs, 'def_default') || 'undef';
  my $autoincrement  = $self->get_attrib ($attribs, 'auto_increment') || 'undef';
  my $def_primarykey = $self->get_attrib ($attribs, 'def_primary_key') || 'undef';
  my $position       = $self->get_attrib ($attribs, 'position') || 'undef';
  my $index          = $self->get_attrib ($attribs, 'index') || 'undef';
  my $primarykey     = $self->get_attrib ($attribs, 'primary_key') || 'undef';
  my $unique         = $self->get_attrib ($attribs, 'unique') || 'undef';
  my $fulltext       = $self->get_attrib ($attribs, 'fulltext') || 'undef';
  my $default        = $self->get_attrib ($attribs, 'default') || 'undef';
  my $new_table      = $self->get_attrib ($attribs, 'new_table') || 'undef';

  # Generate named params assignments for the remaining atttribs.
  my $attribs_named_params = $self->generate_named_params ($attribs);

  # Get database info.
  my $namespace_info = $self->get_namespace_info ($self->namespace ());
  my $dbname = $namespace_info->{sourcename};
  my $table  = $namespace_info->{table};

  my $outcode = qq!;
do {
  \$vars->create_context ();

  my \%attribs = ($attribs_named_params);
  \$vars->set (\%attribs);

  my \$db = \$process->get_source ('$dbname');
  if (defined \$db) {
    my \@values;
    my \$values = $values;
    \@values = split (/\\s*,\\s*/, \$values) if defined \$values;
    \$db->alter (
       Table		=> '$table',
       Action		=> $action,
       Column		=> $columns,
       Definition	=> {
         Column		=> $new_column,
         Type		=> $type,
         Length		=> $length,
         Decimals	=> $decimals,
         Values		=> \\\@values,
         Unsigned	=> $unsigned,
         ZeroFill	=> $zerofill,
         Binary		=> $binary,
         Null		=> $null,
         Default	=> $def_default,
         AutoIncrement	=> $autoincrement,
         PrimaryKey	=> $def_primarykey,
       },
       Position		=> $position,
       Index		=> $index,
       PrimaryKey	=> $primarykey,
       Unique		=> $unique,
       FullText		=> $fulltext,
       Default		=> $default,
       NewTable		=> $new_table)
       || die XML::Template::Exception->new ('DB', \$db->error ());
  }

  \$vars->delete_context ();
};
  !;

  return $outcode;
}

=pod

=head2 foreach

XML::Template::Element::DB is a subclass of
L<XML::Template::Element::Iterator>, so it inherits the C<foreach> method,
which in conjunction with the iterator methods defined in this module,
implements iteration through the rows in a database.  For example,

  <item:foreach xmlns:item="http://syrme.net/xml-template/item/v1"
                fields="*">
    ${title}: ${description}
  </item:foreach>

iterates through each column in the items table and prints the title and 
description.

The following attributes are used:

=over 4

=item fields, field

A comma separated list of the database table fields to return.  To return
all fields, use '*'.  For each field returned a variable will be set with
the field's name and value.  These variables will be available in the
content of the select element.

=item orderby

A comma-separated list of the fields used to order the list of rows being 
iterated through.

=item limit

Constrains the number of rows being iterated through.  If one integer, it 
specifies the number of rows to iterate through, starting at the 
beginning.  If two integers separated by a comma, the first specifies the 
offset at which to start iterating, and the second specifies the number of 
rows to iterate through.

=back

=cut

sub loopinit {
  my $self    = shift;
  my $attribs = shift;

  # Get attribs.
  my $fields  = $self->get_attrib ($attribs, ['fields', 'field']) || 'undef';
  my $query   = $self->get_attrib ($attribs, 'query')   || 'undef';
  my $orderby = $self->get_attrib ($attribs, 'orderby') || 'undef';
  my $limit   = $self->get_attrib ($attribs, 'limit')   || 'undef';
  my $match   = $self->get_attrib ($attribs, 'match')   || 'undef';
  my $round   = $self->get_attrib ($attribs, 'round')   || 'undef';

  # Generate named params assignments for the remaining atttribs.
  my $attribs_named_params = $self->generate_named_params ($attribs);

  # Get database info.
  my $namespace = $self->namespace ();
  my $source_mapping_info = $self->get_source_mapping_info (namespace => $namespace);
  my $dbname = $source_mapping_info->{source};
  my $table  = $source_mapping_info->{table};
  my $keys   = $source_mapping_info->{keys};

  my $outcode = qq!
my %attribs = ($attribs_named_params);

my \$tables = '$table';

my \$db = \$process->get_source ('$dbname')
  || die XML::Template::Exception->new ('DB', \$process->error);

my \$sql;
my \$query = $query;
if (defined \$query && \$query eq 'describe') {
  \$sql = \$db->_prepare_sql ('describe',
            {Table	=> '$table'});
} else {
  my \$where   = \$process->generate_where (\\\%attribs, '$table');

no strict;
  my \$parent_namespace = \$__parent_namespace;
  my \@parent_names = \@__parent_names;
use strict;

  if (defined \$parent_namespace) {
    my \$parent_namespace_info = \$process->get_source_mapping_info (namespace => \$parent_namespace);
    if (defined \$parent_namespace_info->{relation} &&
        defined \$parent_namespace_info->{relation}->{'$namespace'}) {
      my \$rtable = \$parent_namespace_info->{relation}->{'$namespace'}->{table};

      \$tables .= ",\$rtable";

      my \$i = 0;
      foreach my \$key (split (',', '$keys')) {
        \$where .= ' and ' if defined \$where;
        \$where .= "$table.\$key=\$rtable.\$key";
        \$i++;
      }

      \$i = 0;
      foreach my \$key (split (',', \$parent_namespace_info->{keys})) {
        \$where .= ' and ' if defined \$where;
        \$where .= "\$rtable.\$key='\$parent_names[\$i]'";
        \$i++;
      }
    }
  }

  \$sql = \$db->_prepare_sql ('select',
            {Fields	=> $fields,
             Table	=> \$tables,
             Where	=> \$where,
             OrderBy	=> $orderby,
             Limit	=> $limit,
             Match	=> $match,
             Round	=> $round})
    || die XML::Template::Exception->new ('DB', \$db->error ());
}

my \$__sth;
if (defined $fields) {
  \$__sth = \$db->{_dbh}->prepare (\$sql)
    || die XML::Template::Exception->new ('DB', \$db->{_dbh}->errstr);
  \$__sth->execute
    || die XML::Template::Exception->new ('DB', \$db->{_dbh}->errstr);
}
  !;

  return $outcode;
}

sub get_first {
  my $self    = shift;
  my $attribs = shift;

  my $outcode = qq!
\$__value = \$__sth->fetchrow_hashref;
if (defined \$__value) {
  if (defined \$query && \$query eq 'describe') {
    my \$type = \$__value->{Type};
    \$type =~ s/\\(([^)]+)\\)\$//;
    \$__value->{Type} = \$type;
    if (\$type eq 'enum' || \$type eq 'set') {
      my \@values = split (/\\s*,\\*/, \$1);
      \$__value->{Values} = \\\@values;
    } else {
      \$__value->{Size} = \$1;
    }
  }
} else {
  \$__sth->finish;
  undef \$__sth;
}
  !;

  return $outcode;
}

sub set_loopvar {
  my $self    = shift;
  my $attribs = shift;

  # Get database info.
  my $namespace = $self->namespace ();
  my $namespace_info = $self->get_namespace_info ($namespace);
  my $keys = $namespace_info->{keys};

  my $outcode = qq!
  while (my (\$name, \$val) = each \%\$__value) {
    \$vars->set (\$name => \$val);
  }

  my (\$__parent_namespace, \@__parent_names);
  if (defined \$__value) {
    \$__parent_namespace = '$namespace';
    foreach my \$key (split (/\\s*,\\s*/, '$keys')) {
      push (\@__parent_names, \$__value->{\$key});
    }
  }

  !;

  return $outcode;
}

sub get_next {
  my $self    = shift;
  my $attribs = shift;

  my $outcode = qq!
  \$__value = \$__sth->fetchrow_hashref;
  if (defined \$__value) {
    if (defined \$query && \$query eq 'describe') {
      my \$type = \$__value->{Type};
      \$type =~ s/\\(([^)]+)\\)\$//;
      \$__value->{Type} = \$type;
      if (\$type eq 'enum' || \$type eq 'set') {
        my \$values = \$1;
        \$values =~ s/^'//;
        \$values =~ s/'\$//;
        my \@values = split (/',\\s*'/, \$values);
        \$__value->{Values} = \\\@values;
      } else {
        \$__value->{Size} = \$1;
      }
    }
  } else {
    \$__sth->finish;
    undef \$__sth;
  }
  !;

  return $outcode;
}
  
sub foreach_describe {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $namespace = $self->namespace ();
  $attribs->{"{$namespace}query"} = "'describe'";
  return $self->foreach ($code, $attribs);
}

sub AUTOLOAD {
  my $self = shift;
  my ($code, $attribs) = @_;

  return if $AUTOLOAD =~ /DESTROY$/;

  $AUTOLOAD =~ /([^:]+)$/;
  my $field = $1;

  my $outcode = qq!
  my \$value;
  my \$io = IO::String->new (\$value);
  my \$ofh = select \$io;

  $code

  select \$ofh;
  \$value =~ s/&(?\!amp)/&amp\;/g;
  \$value =~ s/\\\\/\\\\\\\\/g;

no strict;
  \$values{'$field'} = \$value;
use strict;
  !;

  return $outcode;
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
