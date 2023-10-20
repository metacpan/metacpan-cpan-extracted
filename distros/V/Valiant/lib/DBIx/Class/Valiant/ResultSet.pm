package DBIx::Class::Valiant::ResultSet;

use warnings;
use strict;
use Carp;
use Valiant::Util 'debug';
use namespace::autoclean -also => ['debug'];
use DBIx::Class::Valiant::Util::Exception::TooManyRows;
use Role::Tiny::With;

with 'Valiant::Naming';

# Gotta jump thru these hoops because of the way the Catalyst
# DBIC model messes with the result namespace but not the schema
# namespace

sub namespace {
  my $self = shift;
  my $class = ref($self) ? ref($self) : $self; 
  my ($ns) = ($class =~m/^(.+)::.+$/);
  return $ns;
}

sub i18n_scope { 'valiant' }

sub i18n_lookup { 
  my ($class_or_self, $arg) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;
  no strict "refs";
  my @proposed = @{"${class}::ISA"};
  push @proposed, $class_or_self->i18n_metadata if $class_or_self->can('i18n_metadata');
  return grep { $_->can('model_name') } ($class, @proposed);
}

sub skip_validation {
  my ($self, $arg) = @_;
  if(defined($arg)) {
    $self->{_skip_validation} = $arg ? 1:0;
  }
  return $self->{_skip_validation};
}
  
sub skip_validate {
  my ($self) = @_;
  $self->skip_validation(1);
  return $self;
}
sub do_validate {
  my ($self) = @_;
  $self->skip_validation(0);
  return $self;
}

sub _nested_info_for_related {
  my ($self, $related) = @_;
  my %nested = $self->result_class->accept_nested_for;
  my %info = %{ $nested{$related}||+{} };
  return %info;
}

sub _related_limit {
  my ($self, $related) = @_;
  my %info = $self->_nested_info_for_related($related);
  if(my $limit_proto = $info{limit}) {
    my $limit = (ref($limit_proto)||'' eq 'CODE') ? $limit_proto->($self) : $limit_proto;
    return 1, $limit;
  }
  return 0, undef;
}

# This is just an alias so that we can decouple the Valiant API from DBIC
sub build { shift->new_result( shift || +{}) }

sub new_result {
  my ($self, $fields, @args) = @_;
  my $context = delete $fields->{__context};

  my %related = ();
  my %nested = $self->result_class->accept_nested_for;
  
  foreach my $associated (keys %nested) {
    $related{$associated} = delete($fields->{$associated})
      if exists($fields->{$associated});
  }

  # Remove any relationed keys we didn't find with the allows nested
  my @rel_names = $self->result_source->relationships();
  my @m2m_names = keys  %{ $self->result_class->_m2m_metadata ||+{} };

  my %found = map { $_ => delete($fields->{$_}) } @rel_names, @m2m_names;

  if(grep { defined $_ } values %found) {
    my $related = join(', ', grep { $found{$_} } keys %found);
    die "You are trying to create a relationship ($related) on @{[$self->result_source->name ]} without setting 'accept_nested_for'";
  }

  my $result = $self->next::method($fields, @args);
  $result->{__VALIANT_CREATE_ARGS}{context} = $context if $context; # Need this for ->insert
  $result->skip_validation(1) if $self->skip_validation;

  debug 2, "made new_result @{[ $result ]}";
  RELATED: foreach my $related(keys %related) {

    if(my $cb = $nested{$related}->{reject_if}) {
      my $response = $cb->($result, $related{$related});
      next RELATED if $response;
    }

    my ($has_limit, $limit) = $self->_related_limit($related);
    if($has_limit) {
      my $num = scalar @{$related{$related}};
      DBIx::Class::Valiant::Util::Exception::TooManyRows
        ->throw(
          limit=>$limit,
          attempted=>$num,
          related=>$related,
          me=>$self->result_source->name,
        ) if $num > $limit;
    }

    $result->set_related_from_params($related, $related{$related});
  }

  return $result;
}

# Utility methods

# this should cache results betters
sub contains {
  my ($self, $row) = @_;
  my %pk = map { $_ => $row->$_ }
    $self->result_source->primary_columns;
  foreach my $item ($self->all) {
    next if $item->is_removed;
    my @matches = grep { 
      $item->get_column($_) eq $pk{$_}
    } keys %pk;
    return 1 if scalar(@matches) == keys %pk;
  }
  return 0;
}

1;

=head1 NAME

DBIx::Class::Valiant::ResultSet - Validation support for resultsets

=head1 SYNOPSIS

    package Example::Schema::ResultSet::Person;

    use base 'DBIx::Class::ResultSet';

    __PACKAGE__->load_components('Valiant::ResultSet');

See <example> directory in the distribution for a more complete example
setup and application.

=head1 DESCRIPTION

A component that needs to be used on any result classes for which you want to add
L<Valiant> validations on.   Its best to add this to your base and default resultset
classes if you plan to use L<DBIx::Class::Valiant> across all your result classes.

=head1 METHODS

This component adds the following methods to your resultset classes.

=head2 skip_validation (1|0)

    $schema->resultset('User')->skip_validation(1)->create(...

Turns off automatic validation on any creates / updates / etc going forward 
in this chain if arg is true.  You may still manually run validations in the
normal way as described in L<Valiant> (via ->validate for example).

=head2 skip_validate

=head2 do_validate

Skip validations or reenable validations.  This is just a wrapper on L</skip_validation>
which presets the enable or disable value.

  $schema->resultset('User')
    ->skip_validate
    ->create(\%user_args);

=head2 build

This is just a shortcut for "->new_result(+{})" and exists mostly to provide expected API
for L<Valiant::HTML::FormBuilder>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
 
=head1 SEE ALSO
 
L<Valiant>, L<DBIx::Class>, L<DBIx::Class::Valiant>

=head1 AUTHOR

See L<Valiant>.

=head1 COPYRIGHT & LICENSE

See L<Valiant>.

=cut

