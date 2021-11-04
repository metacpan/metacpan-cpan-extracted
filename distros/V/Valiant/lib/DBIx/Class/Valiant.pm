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

B<NOTE> If you are using more than one component, you need to add these first. Hopefully
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

B<NOTE> Update: I consider this code to be beta stage and will now only break things if
its absolutely necessary to fix critical bugs or security matters.

This provides a base result component and resultset component that when added to your
classes glue L<Valiant> into L<DBIx::Class>.  You can set filters and validations on
your result source classes very similarily to how you would use L<Valiant> with L<Moo>
or L<Moose>.  Validations then run when you try to persist a change to the database; if
validations fail then we will not complete persisting the change (typically via insert
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

    use warnings;
    use strict;
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

With a properly setup schema you can propagate creates/updates down into related result sources.  Because
this can be a security issue you must configure your result source classes to allow it.  For example, let's
say you have a C<Person> result source that has a C<Profile> (via 'might_have'), some C<Roles> via a 
'has_many' bridge result class called C<PersonRoles> and finally a list of C<CreditCards> directly via
a 'has_many'.  For the purposes of this example assume the base result and result set classes are setup
to consume the Valiant components as in the L</SYNOPSIS>.

    package Example::Schema::Result::Person;

    use warnings;
    use strict;
    use base 'Example::Schema::Result';

    # This first part is just the normal DBIC class data you assign to a result class
    # in order to read and update tables as well as follow relationships:

    __PACKAGE__->table("person");

    __PACKAGE__->add_columns(
      id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
      username => { data_type => 'varchar', is_nullable => 0, size => 48 },
      first_name => { data_type => 'varchar', is_nullable => 0, size => 24 },
      last_name => { data_type => 'varchar', is_nullable => 0, size => 48 },
    );

    __PACKAGE__->set_primary_key("id");
    __PACKAGE__->add_unique_constraint(['username']);

    __PACKAGE__->might_have(
      profile =>
      'Example::Schema::Result::Profile',
      { 'foreign.person_id' => 'self.id' }
    );

    __PACKAGE__->has_many(
      credit_cards =>
      'Example::Schema::Result::CreditCard',
      { 'foreign.person_id' => 'self.id' }
    );

    __PACKAGE__->has_many(
      person_roles =>
      'Example::Schema::Result::PersonRole',
      { 'foreign.person_id' => 'self.id' }
    );

    __PACKAGE__->many_to_many('roles' => 'person_roles', 'role');

    # In this next part we annotate this class with additional meta data which Valiant will
    # use to performance validations as well as allow you to follow relationships at create / update
    # time:

    __PACKAGE__->validates(username => presence=>1, length=>[3,24], format=>'alpha_numeric', unique=>1);
    __PACKAGE__->validates(first_name => (presence=>1, length=>[2,24]));
    __PACKAGE__->validates(last_name => (presence=>1, length=>[2,48]));

    __PACKAGE__->validates(credit_cards => (result_set=>+{validations=>1, min=>2, max=>4}));
    __PACKAGE__->accept_nested_for('credit_cards', +{allow_destroy=>1});

    __PACKAGE__->validates(person_roles => (result_set=>+{validations=>1, min=>1}));
    __PACKAGE__->accept_nested_for('person_roles', {allow_destroy=>1});

    __PACKAGE__->validates(profile => (result=>+{validations=>1} ));
    __PACKAGE__->accept_nested_for('profile');

So in brief we add some simple validations on fields in the C<Person> result class to validate
things like the length of text fields and we added things like requiring a person to have at least
one C<person_role> and two C<credit_cards>; we also specify that we want to follow those nested
relationships and aggregate errors into the C<Persons> result class (we'll see the validation
definitions for those classes below).   Also we allow that we can delete C<credit_cards> as well
as C<person_roles>.

Here's how we setup these related classes.  Please note that we in general avoid using the 'many_to_many'
pseudo relationship.  DBIC does not define enough internal meta data for m2m to work reliably and we had
other issues around caching.  As a result I recommend avoiding m2m for using with L<Valiant> although it
seems to work ok for simple use cases.  Test cases and patches to improve this are welcomed (you can see
there's quite a few m2m test cases already but I was never able to get the type of consistency I felt 
needed for a data storage layer where integrity is most important).

    package Example::Schema::Result::Profile;

    use warnings;
    use strict;
    use base 'Example::Schema::Result';

    __PACKAGE__->table("profile");
    __PACKAGE__->load_components(qw/Valiant::Result/);

    __PACKAGE__->add_columns(
      id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
      person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
      address => { data_type => 'varchar', is_nullable => 0, size => 48 },
      city => { data_type => 'varchar', is_nullable => 0, size => 32 },
      zip => { data_type => 'varchar', is_nullable => 0, size => 5 },
      birthday => { data_type => 'date', is_nullable => 1 },
      phone_number => { data_type => 'varchar', is_nullable => 1, size => 32 },
    );

    __PACKAGE__->validates(address => (presence=>1, length=>[2,48]));
    __PACKAGE__->validates(city => (presence=>1, length=>[2,32]));
    __PACKAGE__->validates(zip => (presence=>1, format=>'zip'));
    __PACKAGE__->validates(phone_number => (presence=>1, length=>[10,32]));
    __PACKAGE__->validates(birthday => (
        date => {
          max => sub { pop->now->subtract(days=>1) }, # Can't be born yesterday :)
          min => sub { pop->years_ago(30) }, # Don't trust anyone over 30
        }
      )
    );

    __PACKAGE__->set_primary_key("id");
    __PACKAGE__->add_unique_constraint(['id','person_id']);

    __PACKAGE__->belongs_to(
      person =>
      'Example::Schema::Result::Person',
      { 'foreign.id' => 'self.person_id' }
    );

    package Example::Schema::Result::CreditCard;

    use strict;
    use warnings;
    use DateTime;
    use DateTime::Format::Strptime;

    use base 'Example::Schema::Result';

    __PACKAGE__->table("credit_card");
    __PACKAGE__->load_components(qw/Valiant::Result/);

    __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
      person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
      card_number => { data_type => 'varchar', is_nullable => 0, size => '20' },
      expiration => { data_type => 'date', is_nullable => 0 },
    );

    __PACKAGE__->set_primary_key("id");

    __PACKAGE__->validates(card_number => (presence=>1, length=>[13,20], with=>'looks_like_a_cc' ));
    __PACKAGE__->validates(expiration => (presence=>1, with=>'looks_like_a_datetime', with=>'is_future' ));

    __PACKAGE__->belongs_to(
      person =>
      'Example::Schema::Result::Person',
      { 'foreign.id' => 'self.person_id' }
    );

    sub looks_like_a_cc {
      my ($self, $attribute_name, $value) = @_;
      return if $value =~/^\d{13,20}$/;
      $self->errors->add($attribute_name, 'does not look like a credit card'); 
    }

    my $strp = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d');

    sub looks_like_a_datetime {
      my ($self, $attribute_name, $value) = @_;
      my $dt = $strp->parse_datetime($value);
      $self->errors->add($attribute_name, 'does not look like a datetime value') unless $dt;
    }

    sub is_future {
      my ($self, $attribute_name, $value) = @_;
      my $dt = $strp->parse_datetime($value);
      return unless $dt;  # Skip this validation if the user didn't give us a date time
                          # format (that's caught by ->looks_like_a_datetime).
      $self->errors->add($attribute_name, 'must be in the future') unless $dt > DateTime->now);
    }

    package Example::Schema::Result::PersonRole;

    use strict;
    use warnings;
    use base 'Example::Schema::Result';

    __PACKAGE__->table("person_role");
    __PACKAGE__->load_components(qw/Valiant::Result/);

    __PACKAGE__->add_columns(
      person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
      role_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
    );

    __PACKAGE__->set_primary_key("person_id", "role_id");

    __PACKAGE__->belongs_to(
      person =>
      'Example::Schema::Result::Person',
      { 'foreign.id' => 'self.person_id' }
    );

    __PACKAGE__->belongs_to(
      role =>
      'Example::Schema::Result::Role',
      { 'foreign.id' => 'self.role_id' }
    );

    package Example::Schema::Result::Role;

    use strict;
    use warnings;

    use base 'Example::Schema::Result';

    __PACKAGE__->table("role");
    __PACKAGE__->load_components(qw/Valiant::Result/);

    __PACKAGE__->add_columns(
      id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
      label => { data_type => 'varchar', is_nullable => 0, size => '24' },
    );

    __PACKAGE__->set_primary_key("id");
    __PACKAGE__->add_unique_constraint(['label']);

    __PACKAGE__->has_many(
      person_roles =>
      'Example::Schema::Result::PersonRole',
      { 'foreign.role_id' => 'self.id' }
    );

With this setup you could deeply validate / create a Person and its permitted relationships:

    my $person = $schema
      ->resultset('Person')
      ->create({
        first_name => "john",
        last_name => "nap",
        username => "jjn1",
        profile => {
          address => "15604 Harry Lind Road",
          birthday => "2000-02-13",
          city => "Elgin",
          phone_number => "16467081837",
          zip => '10000'
        },
        person_roles => [   
          { role_id => 1 },
          { role_id => 2 },
          { role_id => 4 },
        ],
        credit_cards => [
          {
            card_number => "3423423423423423",
            expiration => "2222-02-02",
          },
          {
            card_number => "1111222233334444",
            expiration => "2333-02-02",
          },
        ],
      });

If the proposed data fails validation then you won't create any recors, but the errors can
be viewed via the C<errors> collection.

For doing nested updates / validations you need to do a bit more work.   You need to use 'prefetch'
to locally cache all the results you are trying to validate:

    my $person = Schema->resultset('Person')->find(
      { 'me.id'=>$pid },
      { prefetch => ['profile', 'credit_cards', {person_roles => 'role' }] }
    );
    $person->build_related_if_empty('profile');

Then you can do an update:

    $person->update({
      username => 'jjn2',
      profile => {
        city => 'NYC'
      },
    });

As before if there's a valiation issue the update won't happen.

=head2 Deleting

If a nested relationship permits deleting (via the 'allow_destroy' flag) you can mark a row for deletion
directly using the C<_delete> flag:

    $person->update({
      username => 'jjn2',
        person_roles => [   
          { role_id => 1 },
          { role_id => 2, _delete => 1 },
          { role_id => 4, _delete => 1 },
        ],
    });

B<Inplicit Deletion>: When deletion is permitted we automatically mark nested object that are fetched from
'prefetch' as deleted if they do not appear in the update statement.  B<NOTE>: This behavior is still
under review and might change in the future so if you rely on it please be sure to follow update notes
on newer versions of this code.

This example is far from complete, for now see example in C<example> directory of the distribution
and more examples in the tests directory.  In particular this example doesn't really cover all the
ins and outs of deleting.  An overall tutorial is in the works but example submission or questions
(that could eventually lead to a FAQ) are very welcomed.

=head1 WARNINGS

Besides the fact that nested is still considered beta code please be aware that you must
be careful with how you expose a deeply nested interface.   If you simply pass fields from a web
form you are potentially opening yourself to SQL injection and similar types of attacks.  I 
recommend being very careful to sanitize incoming parameters, especially any related keys.

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
