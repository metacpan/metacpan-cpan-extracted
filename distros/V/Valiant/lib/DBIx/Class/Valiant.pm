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
      Valiant::Result
      Core
    /);

    package Example::Schema::ResultSet;

    use strict;
    use warnings;
    use base 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components(qw/
      Valiant::ResultSet
    /);

There's an example schema in the C</example> directory of the distribution to give you
some hints.

B<NOTE> If you are using more than one component, you need to add these first.   Hopefully
that is a restriction we can figure out how to remove (patches welcomed).

=head1 DESCRIPTION

B<NOTE>This works as is 'it passed my existing tests'.   Feel free to use it
if you are willing to get into the code, review / submit test cases, etc.   Also at some
point this will be pulled into its own distribution so please keep in mind.   I
will feel totally free to break backward compatibility on this until it seems
stable.  That being said support for validations at the single result level is pretty
firm and I can't imagine significant changes.  Support for validating nested results
(results that have has_many or similar relationships) is likely to evolve as bugs are
reported.

This provides a base result component and resultset component that when added to your
classes glue L<Valiant> into L<DBIx::Class>.  You can set filters and validations on
your result source classes very similarily to how you would use L<Valiant> with L<Moo>
or L<Moose>.  Validations then run when you try to persist a change to the database; if
validations fail then we will not compete persisting the change (typically via insert
or update SQL).  Errors can be read via the C<errors> method just as on L<Moo> or L<Moose>
based validations.

Additionally we support nested creates and updates; validations follow any nested changes
and errors can be aggregated. Errors at any point in the nested create or update (or as
is often the cases a mixed situation) will cancel the entire changeset (issuing a rollback
if necessary).  Please note that as stated above nested support is still considered a beta
feature and bug reports / test cases (or patches) welcomed.

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

=head1 EXAMPLE

Assuming you have a base result class C<Example::Schema::Result> which uses the L<DBIx::Class::Valiant::Result>
component and a default resultset class which uses the L<Example::Schema::ResultSet> component:

    package Example::Schema::Result::Person;

    use base 'Example::Schema::Result';

    __PACKAGE__->table("person");

    __PACKAGE__->add_columns(
      id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
      username => { data_type => 'varchar', is_nullable => 0, size => 48 },
      first_name => { data_type => 'varchar', is_nullable => 0, size => 24 },
      last_name => { data_type => 'varchar', is_nullable => 0, size => 48 },
    );

    __PACKAGE__->validates(username => presence=>1, length=>[3,24], format=>'alpha_numeric', unique=>1);
    __PACKAGE__->validates(first_name => (presence=>1, length=>[2,24]));
    __PACKAGE__->validates(last_name => (presence=>1, length=>[2,48]));

We now have L<Valiant> validations wrapping any method which mutates the database.

    my $person = $schema->resultset('Person')
      ->create({
        username => 'jjn',   # for this example we'll say this username is taken in the DB
        first_name => 'j',   # too short
        last_name => 'n',    # too short
      });

In this case since we tried to create a record that is not valid the create will be aborted (not saved
to the DB and an object will be returned with errors:

    $person->invalid; # true;
    $person->errors->size; # 3
    person->errors->full_messages_for('username');  # ['Username is not unique']
    person->errors->full_messages_for('first_name');  # ['First Name is too short']
    person->errors->full_messages_for('last_name');  # ['Last Name is too short']

The object will have the invalid values properly populated:

    $person->get_column('username');  # jjn

You might find this useful for building error message responses in for example html forms or other types
or error responses.

See C<example> directory for web application using L<Catalyst> that uses this for more details.

=head1 NESTED VALIDATIONS

TBD for now see example in C<example> directory of the distribution and more examples in the tests
directory.

=head1 WARNINGS

Besides the fact that nested is still considered beta code please be aware that you must
be careful with how you expose a deeply nested interface.   If you simply pass fields from a web
form you are potentially opening yourself to SQL injection and similar types of attacks.

=head2 Many to Many

Many to Many type relationships are supported to the best of my ability but since these types of
fake relationships have lots of known issues you are more likely to run into edge cases.  In
particular its a bad idea to have validations on both a m2m relations and also on the one to many
relation that it bridges.   This is likely to result in false positive validation errors due to the
way the resultset cache works (and doesn't work) for m2m.

Happy to take patches for improvements to anyone that feels strongly about it.

=head1 SEE ALSO
 
L<Valiant>, L<DBIx::Class::Valiant::Result>, L<DBIx::Class::Valiant::ResultSet>, L<DBIx::Class>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
