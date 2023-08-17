package DBIx::Class::Valiant::Validator::SetSize;

use Moo;
use Valiant::I18N;
use namespace::autoclean;

with 'Valiant::Validator::Each';

has min => (is=>'ro', required=>0, predicate=>'has_min');
has max => (is=>'ro', required=>0, predicate=>'has_max');
has skip_if_empty => (is=>'ro', required=>1, default=>sub {0});
has skip_if_blank => (is=>'ro', required=>1, default=>sub {0});
has too_few_msg => (is=>'ro', required=>1, default=>sub {_t 'too_few'});
has too_many_msg => (is=>'ro', required=>1, default=>sub {_t 'too_many'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if( (ref($arg)||'') eq 'ARRAY') {
    return +{
      min => $arg->[0],
      max => $arg->[1],
    }
  }
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;

  return if($self->skip_if_blank && !exists $value->{all_cache});

  # If a row is marked to be deleted then don't bother to validate it
  my @rows = grep { not $_->is_removed } @{$value->get_cache||[]};
  if(!@rows) {
    return if $self->skip_if_empty;
  }
  
  # This bit here where we exclude rows with errors from the count might not be right. It's likely
  # that if someone submits enough rows that we don't want to see this error just because one or more
  # has errors.
  #

  my $count = scalar(grep { !$_->{__valiant_donot_insert} } grep { $_->in_storage || !$_->errors->size } @rows);
  #my $count = scalar(grep { !$_->errors->size } @rows);
  #my $count = scalar(@rows);
  
  $record->errors->add($attribute, $self->too_few_msg, +{%$opts, count=>$count, min=>$self->min})
    if $self->has_min and $count < $self->min;

  $record->errors->add($attribute, $self->too_many_msg, +{%$opts, count=>$count, max=>$self->max})
    if $self->has_max and $count > $self->max;
}

1;

=head1 NAME

DBIx::Class::Valiant::Validator::SetSize - Verify a DBIC related resultset 

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
        set_size=>+{ skip_if_empty=>1, min=>2, max=>4 }, 
      )
    );

=head1 DESCRIPTION

Validations on related resultsets.  This constrains minimum / maximum sizes on the set and
permits optional sets (where the min/max is only applied when the set has entries).

=head1 ATTRIBUTES

This validator supports the following attributes:

=head2 skip_if_empty

Skip validations if the resultset is empty.  In this context empty means that you have zero records.
Probably not that useful; yhou might actually want 'skip_if_blank' instead.

=head2 skip_if_blank

Allows you to skip validations if the resultset is blank.  In this context blank means that you
have not prefetched the relationship or loaded it in any way.  'blank' is different from 'has none'.
You might for example want to skip size validations if you have not prefetched the relationship. 

=head2 min

=head2 max

The minimum or maximum number of rows that the resultset can contain.  Optional (but I suspect you'd
set at least one otherwise why bother with this constraint?

=head2 too_few_msg

=head2 too_many_msg

Error messages associated with the 'min' or 'max' constraints. Defaults to 'too_few' or 'too_many'
translation tags.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( result_set => [1,4], ... );

Which is the same as:

    validates attribute => (
      result_set => {
        min => 1,
        max => 4,
      }
    );

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
