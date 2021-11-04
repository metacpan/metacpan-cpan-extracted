package DBIx::Class::Valiant::Validator::ResultSet;

use Moo;
use Valiant::I18N;
use Module::Runtime 'use_module';
use namespace::autoclean;

with 'Valiant::Validator::Each';

has min => (is=>'ro', required=>0, predicate=>'has_min');
has max => (is=>'ro', required=>0, predicate=>'has_max');
has skip_if_empty => (is=>'ro', required=>1, default=>sub {0});
has too_few_msg => (is=>'ro', required=>1, default=>sub {_t 'too_few'});
has too_many_msg => (is=>'ro', required=>1, default=>sub {_t 'too_many'});
has invalid_msg => (is=>'ro', required=>1, default=>sub {_t 'invalid'});

has validations => (is=>'ro', required=>1, default=>sub {0});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if(($arg eq '1') || ($arg eq 'nested')) {
    return { validations => 1 };
  } 
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;

  # If a row is marked to be deleted then don't bother to validate it
  my @rows = grep { not $_->is_removed } @{$value->get_cache||[]};
  
  # If there's zero $count and skip_if_empty is true (default is false) then
  # don't bother doing any more validations.
  if(!@rows) {
    return if $self->skip_if_empty;
  }

  # Ok, now run validations.  If we find even one row is invalid, then we need
  # to mark the attribute as invalid.
  my $found_errors = 0;
  foreach my $row (@rows) {
    $row->validate(%$opts); #unless $row->validated
    $found_errors = 1 if $row->errors->size;
  }

  # Ok, next if we are asking to aggregate the nested errors, do that
  if($self->validations) {
    my $rowidx = 0;
    foreach my $row (@rows) {
      if($row->errors->size) {
        my $errors = $row->errors;
        $errors->each(sub {
          my ($index, $message) = @_;
          $record->errors->add("${attribute}.${rowidx}.${index}", $message);
        });
      }
      $rowidx++;
    }
  }

  if($self->has_min || $self->has_max) {

    # If a row is not in storage and can't be saved since its invalid, we don't count it
    # toward mins or maxes.  Otherwise we could mark good rows for deletion but still pass
    # the count tests with new not stored but invalid rows.  If however the new rows are
    # valid then they will get saved so we can count them.  We also don't count it if its
    # marked not to be inserted (generally this is the case with _add.

    my $count = scalar(grep { !$_->{__valiant_donot_insert} } grep { $_->in_storage || !$_->errors->size } @rows);

    $record->errors->add($attribute, $self->too_few_msg, +{%$opts, count=>$count, min=>$self->min})
      if $self->has_min and $count < $self->min;

    $record->errors->add($attribute, $self->too_many_msg, +{%$opts, count=>$count, max=>$self->max})
      if $self->has_max and $count > $self->max;
  }

  $record->errors->add($attribute, $self->invalid_msg, $opts) if $found_errors;
}

1;

=head1 NAME

DBIx::Class::Valiant::Validator::ResultSet - Verify a DBIC related resultset 

=head1 SYNOPSIS

    package Example::Schema::Result::Person;

    use base 'Example::Schema::Result';

    __PACKAGE__->load_components(qw/
      Valiant::Result
      Core
    /);

    __PACKAGE__->table("person");

    __PACKAGE__->add_columns(
      id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
      username => { data_type => 'varchar', is_nullable => 0, size => 48 },
      first_name => { data_type => 'varchar', is_nullable => 0, size => 24 },
      last_name => { data_type => 'varchar', is_nullable => 0, size => 48 },
      password => {
        data_type => 'varchar',
        is_nullable => 0,
        size => 64,
      },
    );

    __PACKAGE__->has_many(
      credit_cards =>
      'Example::Schema::Result::CreditCard',
      { 'foreign.person_id' => 'self.id' }
    );

    __PACKAGE__->validates(
      credit_cards => (
        result_set=>+{ validations=>1, skip_if_empty=>1, min=>2, max=>4 }, 
      )
    );

=head1 DESCRIPTION

Validations on related resultsets. Used to apply constraints on the resultset as a whole
(such as total number of rows) or to trigger running validations on any related row objects.
Any errors from related resultsets will be added as sub errors on the parent result.

=head1 ATTRIBUTES

This validator supports the following attributes:

=head2 validations

Boolean.  Default is 0 ('false').  Used to trigger validations on row objects found inside the
resultset.  Please keep in mind this can be expensive if you have a lot of found rows (consider
using limits and validating in chunks).

Please keep in mind these errors will be localized to the associated object, not on the current
object.

=head2 invalid_msg

Error message returned on the current object if we find any errors inside related objects.
defaults to tag 'invalid_msg'.

=head2 skip_if_empty

Allows you to skip validations if the resultset is empty (has zero rows).  Useful if you want
to do validations only if there are rows found, such as when you have an optional relationship.
Defaults to false.

=head2 min

=head2 max

The minimum or maximum number of rows that the resultset can contain.  Optional.

=head2 too_few_msg

=head2 too_many_msg

Error messages associated with the 'min' or 'max' constraints. Defaults to 'too_few' or 'too_many'
translation tags.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( result_set => 1, ... );

Which is the same as:

    validates attribute => (
      result_set => {
        validations => 1,
      }
    );

Which is a shortcut when you wish to run validations on the related rows

=head1 GLOBAL PARAMETERS

This validator supports all the standard shared parameters: C<if>, C<unless>,
C<message>, C<strict>, C<allow_undef>, C<allow_blank>.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
