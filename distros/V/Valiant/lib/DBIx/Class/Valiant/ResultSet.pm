package DBIx::Class::Valiant::ResultSet;

use warnings;
use strict;
use Carp;
use Valiant::Util 'debug';
use namespace::autoclean -also => ['debug'];
use DBIx::Class::Valiant::Util::Exception::TooManyRows;
use Role::Tiny::With;
use Scalar::Util ();

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

# This is a work in progress, this needs to really use code from ::Result
# so that is working against an already loaded resultset, so that we properly
# handle deletes and so forth.
# $self, $data, { rollback_on_invalid=>0||1 }
sub set_recursively {
  my ($self, $data, $opts) = @_;
  my $rollback_on_invalid = delete($opts->{rollback_on_invalid}) || 0;
  my @results = ();

  $self->result_source->schema->txn_begin if $rollback_on_invalid;

  my $err = 0;
  foreach my $row_data (@$data) {
    if(ref($row_data) eq 'HASH') {
      my $new_result = $self->new_result(+{});
      $new_result->set_columns_recursively($row_data);
      $new_result->insert_or_update;
      $err ||= $new_result->errors->count ? 1:0;
      push @results, $new_result;
    } elsif (ref($row_data) && $row_data->isa('DBIx::Class::Row')) {
      $row_data->insert_or_update;
      $err ||= $row_data->errors->count ? 1:0;
      push @results, $row_data;
    } else {
      die "Don't know how to handle row data of type @{[ ref($row_data) ]}";
    }
  }

  $self->result_source->schema->txn_rollback if $rollback_on_invalid && $err;
  $self->result_source->schema->txn_commit if $rollback_on_invalid && !$err;

  $self->set_cache(\@results);
  my @rs_with_errs = grep { $_->errors->count } @results;
  return $self, @rs_with_errs;
}

# $self, ${ cached_only => 0||1, depth => $num, _seen => +{}, _current_depth => 0, allow_undef => 0||1 }
sub _dump_resultset {
    my ($resultset, $seen) = @_;
    my $name = $resultset->result_source->name;
    my @data;

    $resultset->reset;
    while (my $row = $resultset->next) {
        my $data = _dump_row($row, $seen);
        push @data, $data;
    }
    $resultset->reset;

    return +{ $name => \@data};
}

# Recursive function to dump a row and its relationships
sub _dump_row {
  my ($row, $seen) = @_;
  $seen ||= +{};

  # Prevent infinite recursion in case of circular relationships
  my $row_id = Scalar::Util::refaddr($row);
  return if $seen->{$row_id}++;

  my %data = $row->get_columns;
  my %errors = ();
  foreach my $attr (keys %data) {
    my @errors = $row->errors->full_messages_for($attr);
    $errors{$attr} = \@errors if @errors;
  }
  my @model_errors = $row->errors->model_messages;
  $errors{"*"} = \@model_errors if @model_errors;

  my @relationships = $row->result_source->relationships;
  foreach my $rel_name (@relationships) {
    next unless exists $row->{_relationship_data}{$rel_name};
    my $related = $row->{_relationship_data}{$rel_name};
    if (defined $related) {
      if ($related->isa('DBIx::Class::ResultSet')) {
        $data{$rel_name} = $related->_dump_resultset($seen);
      } elsif ($related->isa('DBIx::Class::Row')) {
        my @rel_errors = $row->errors->full_messages_for($rel_name);
        $errors{$rel_name} = \@rel_errors if @rel_errors;
        my $recursed = _dump_row($related, $seen);
        next unless $recursed;
        $data{$rel_name} = $recursed;
      }
    }
  }
  return +{ data => \%data, errors => \%errors };
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

