package DBIx::Class::Valiant;

# Placeholder for now

1;

=head1 NAME

DBIx::Class::Valiant - Glue Valiant validations into DBIx::Class

=head1 SYNOPSIS

You need to add the components L<DBIx::Class::Valiant::Result> and L<DBIx::Class::Valiant::ResultSet>
to your result and result classes:

    package Example::Schema::Result::Person;

    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components('Valiant::Result');

    package Example::Schema::ResultSet::Person;

    use base 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components('Valiant::ResultSet');

Alternatively (and likely easier if you wish to use this across your entire DBIC schema) you can set these
on your base result / resultset classes:

    package Example::Schema::Result;

    use strict;
    use warnings;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/
      Core
      Valiant::Result/);

    package Example::Schema::ResultSet;

    use strict;
    use warnings;
    use base 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components(qw/
      Valiant::ResultSet
    /);

There's an example schema in the C</example> directory of the distribution to give you
some hints.

=head1 DESCRIPTION

B<NOTE>This works as is 'it passed my existing tests'.   Feel free to use it
if you are willing to get into the code, review / submit test cases, etc.   Also at some
point this will be pulled into its own distribution so please keep in mind.   I
will feel totally free to break backward compatibility on this until it seems
stable.

This provides a base result component and resultset component that when added to your
classes glue L<Valiant> into L<DBIx::Class>.  You can set filters and validations on
your result source classes very similarily to how you would use L<Valiant> with L<Moo>
or L<Moose>.  Validations then run when you try to persist a change to the database; if
validations fail then we will not compete persisting the change (typically via insert
or update SQL).  Errors can be read via the C<errors> method just on on L<Moo> or L<Moose>
based validations.

Additionally we support nested creates and updates; validations follow any nested changes
and errors can be aggregated.   Errors at any point in the nested create or update (or as
is often the cases a mixed situation) will cancel the entire changeset (issuing a rollback
if necessary).

Documentation in this package only covers how L<Valiant> is glued into your result sources
and any local differences in behavior.   If you need a comprehensive overview of how
L<Valiant> works you should refer to that package.

=head2 Combining validations into column definitions

If you are hand writing your table source definitions you can add validations directly
onto a column definition.   You might perfer this if you think it looks neater and adds
fewer lines of code.

    package Example::Schema::Result::CreditCard;

    use strict;
    use warnings;

    use base 'Example::Schema::Result';

    __PACKAGE__->table("credit_card");
    __PACKAGE__->load_components(qw/Valiant::Result/);
    __PACKAGE__->set_primary_key("id");

    __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
      person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
      card_number => { 
        data_type => 'varchar', 
        is_nullable => 0, 
        size => '20',
        validates => [ presence=>1, length=>[13,20], with=>'looks_like_a_cc' ],
        filters => [trim => 1],
      },
      expiration => { 
        data_type => 'date', 
        is_nullable => 0,
        validates => [ presence=>1, with=>'looks_like_a_datetime', with=>'is_future' ],
      },
    );

As in the example above you can define filters this way as well.

=head2 DBIC Candy

This has L<DBIx::Class::Candy> integration if you use that and prefer it:

    package Schema::Create::Result::Person;

    use DBIx::Class::Candy -base => 'Schema::Result';

    table "person";

    column id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 };
    column username => { data_type => 'varchar', is_nullable => 0, size => 48 };
    column first_name => { data_type => 'varchar', is_nullable => 0, size => 24 };
    column last_name => { data_type => 'varchar', is_nullable => 0, size => 48 };
    column password => { data_type => 'varchar', is_nullable => 0, size => 64 };

    primary_key "id";
    unique_constraint ['username'];

    might_have profile => (
      'Schema::Create::Result::Profile',
      { 'foreign.person_id' => 'self.id' }
    );

    filters username => (trim => 1);

    validates profile => (result=>+{validations=>1} );
    validates username => (presence=>1, length=>[3,24], format=>'alpha_numeric', unique=>1);
    validates first_name => (presence=>1, length=>[2,24]);
    validates last_name => (presence=>1, length=>[2,48]);
    validates password => (presence=>1, length=>[8,24]);
    validates password => (confirmation => { on=>'create' } );
    validates password => (confirmation => { 
        on => 'update',
        if => 'is_column_changed', # This method defined by DBIx::Class::Row
      });
     
    accept_nested_for 'profile', {update_only=>1};

    1;

When using this with L<DBIx::Class::Candy> the following class methods are available as exports:

  'filters', 'validates', 'filters_with', 'validates_with', 'accept_nested_for',
  'auto_validation'

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validations>, L<Valiant::Validates>, L<DBIx::Class>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
