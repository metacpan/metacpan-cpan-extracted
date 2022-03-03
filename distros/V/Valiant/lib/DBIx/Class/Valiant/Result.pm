package DBIx::Class::Valiant::Result;

use base 'DBIx::Class';

use warnings;
use strict;

use Role::Tiny::With;
use Valiant::Util 'debug';
use Scalar::Util 'blessed';
use Carp;
use namespace::autoclean -also => ['debug'];
use DBIx::Class::Valiant::Util::Exception::TooManyRows;
use DBIx::Class::Valiant::Util::Exception::BadParameterFK;
use DBIx::Class::Valiant::Util::Exception::BadParameters;

with 'DBIx::Class::Valiant::Validates';
with 'Valiant::Filterable';

use DBIx::Class::Candy::Exports;
export_methods ['filters', 'validates', 'filters_with', 'validates_with', 'accept_nested_for', 'auto_validation'];

__PACKAGE__->mk_classdata( _m2m_metadata => {} );
__PACKAGE__->mk_classdata( auto_validation => 1 );
__PACKAGE__->mk_classdata( _nested => [] );
__PACKAGE__->mk_classdata( _src_info => '' );


sub many_to_many {
  my $class = shift;
  my ($meth_name, $link, $far_side) = @_;
  my $store = $class->_m2m_metadata;
  warn("You are overwritting another relationship's metadata")
    if exists $store->{$meth_name};
 
  my $attrs = {
    accessor => $meth_name,
    relation => $link, #"link" table or immediate relation
    foreign_relation => $far_side, #'far' table or foreign relation
    (@_ > 3 ? (attrs => $_[3]) : ()), #only store if exist
    rs_method => "${meth_name}_rs",      #for completeness..
    add_method => "add_to_${meth_name}",
    set_method => "set_${meth_name}",
    remove_method => "remove_from_${meth_name}",
  };

  my $pk_meth = qq[
    package $class;

    sub ${meth_name}_pks {
      my \$self = shift;
      my \@pks = \$self->related_resultset("${link}")->related_resultset("${far_side}")->result_source->primary_columns;
      return map {
        my \$row = \$_;
        +{ map { \$_ => \$row->\$_ } \@pks };
      } \$self->\$meth_name->all;
    }
  ];

  eval $pk_meth;
  die $@ if $@;
 
  #inheritable data workaround
  $class->_m2m_metadata({ $meth_name => $attrs, %$store});
  $class->next::method(@_);
}

sub BUILDARGS  { } # The filter role wants this (for now)

sub new { # also support for the filter role
  my ($class, $attrs) = @_;
  my @columns = $class->columns;
  my %columns = ();
  foreach my $column (@columns) {   #strip $attrs on non column stuff
    if(exists($attrs->{$column})) {
      $columns{$column} = $attrs->{$column};
    }
  }
  my %filtered = (%$attrs, %{$class->_process_filters(\%columns)});
  my $self = $class->next::method(\%filtered);
  return $self;
}

sub accept_nested_for {
  my $class = blessed($_[0]) ? ref(shift) : shift;
  my %default_config = (
    allow_destroy => 0,
    reject_if => 0,
    limit => 0,
    update_only => 0,
  );

  my @existing = @{$class->_nested};
  my %m2m_names = map { $_=>1 } keys %{ $class->_m2m_metadata ||+{} };

  my $changed = 0;
  while(my $attribute = shift) {
    my $config = (ref($_[0])||'') eq 'HASH' ? shift : +{};    
    push @existing, $attribute;
    push @existing, +{ %default_config, %$config };
    $changed = 1;

    ## Handed m2m, ugg
    if($m2m_names{$attribute}) {
      # treat it like a set
      $class->validates($attribute => (result_set=>+{validations=>1} ));
      next;
    }

    ## Add validation
    my $rel_data = $class->relationship_info($attribute);

    die "'$attribute' does not seem to be a relationship. There's a typo in your source or you've placed your 'accept_nested_for' statement before the relationship it's associated with (has_many, belongs_to, etc)." unless $rel_data;

    my $rel_type = $rel_data->{attrs}{accessor};    
    if($rel_type eq 'single') {
      $class->validates($attribute => (result=>+{validations=>1} ));
    } else {
      $class->validates($attribute => (result_set=>+{validations=>1} ));
    }
  }
  $class->_nested(\@existing) if $changed;
  
  return @existing;
}

sub insert {
  my ($self, @args) = @_;
  my %args = %{ $self->{__VALIANT_CREATE_ARGS} ||+{} };
  my $context = $args{context}||[];
  my @context = ref($context)||'' eq 'ARRAY' ? @$context : ($context);
  push @context, 'create' unless grep { $_ eq 'create' } @context;

  # Add in any extra or new contexts passed as ->insert({__context=>...})
  if( (ref($args[0])||'') eq 'HASH') {
    my $ctx = delete($args[0]->{__context})||[];
    my @ctx = ref($ctx)||'' eq 'ARRAY' ? @$ctx : ($ctx);
    push @context, @ctx unless grep { $_ eq 'update' } @context;  ## ?? IS this a bug?  Why update
  }

  $args{context} = \@context;

  debug 2, "About to run validations for @{[$self]} on insert";
  $self->validate(%args) if $self->auto_validation;

  if($self->errors->size) {
    debug 2, "Skipping insert for @{[$self]} because its invalid";
    return $self;
  } else {
    debug 2, "proceeding to insert  @{[$self]} because its valid";
  }

  if($self->{__valiant_donot_insert}) {
    debug 2, "Skipping insert for @{[$self]} because its probably and _add";
    return $self;
  }
  my $ret = $self->next::method(@args);
  # TODO could probably do the merge errors from related here
  return $ret;
}

sub _nested_info_for_related {
  my ($self, $related) = @_;
  my %nested = $self->result_class->accept_nested_for;
  my %info = %{ $nested{$related}||+{} };  
  return %info;
}

sub _related_allow_destroy {
  my ($self, $related) = @_;
  my %info = $self->_nested_info_for_related($related);
  if(my $proto = $info{allow_destroy}) {
    my $allow_or_not = (ref($proto)||'' eq 'CODE') ? $proto->($self) : $proto;
    return $allow_or_not;
  }
  return 0;
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

sub update {
  my ($self, $upd) = @_;
  my $context = delete($upd->{__context})||[];
  my @context = ref($context)||'' eq 'ARRAY' ? @$context : ($context);
  push @context, 'update' unless grep { $_ eq 'update' } @context;

  my %related = ();
  my %nested = $self->result_class->accept_nested_for;

  foreach my $associated(keys %nested) {
    $related{$associated} = delete($upd->{$associated})
      if exists($upd->{$associated});
  }

  # Remove any relationed keys we didn't find with the allows nested
  my @rel_names = $self->result_source->relationships();
  my @m2m_names = keys  %{ $self->result_class->_m2m_metadata ||+{} };
  debug 1, "Found related for @{[ ref $self ]} of @{[ join ',', @rel_names ]}";

  my %found = map { $_ => delete($upd->{$_})  } @rel_names, @m2m_names; # backcompat with old perl

  if(grep { defined $_ } values %found) {
    my $related = join(', ', grep { $found{$_} } keys %found);
    die "You are trying to create a relationship ($related) without setting 'accept_nested_for'";
  }

  my %validate_args = (context => \@context) if @context;

  $self->set_inflated_columns($upd) if $upd;

  foreach my $related(keys %related) {

    if(my $cb = $nested{$related}->{reject_if}) {
      next if $cb->($self, $related{$related});
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

    debug 2, "Setting related '$related' for @{[ ref $self ]} ";

    #$self->update_or_create_related($related, $related{$related});
    $self->{_valiant_nested_info} = $nested{$related};
    $self->set_related_from_params($related, $related{$related});

    delete $self->{_valiant_nested_info};
  }

  debug 2, "About to run validations for @{[$self]} on update";
  $self->validate(%validate_args) if $self->auto_validation;


  if($self->has_errors) {
    debug 2, "Validation errors found, skipping mutate for @{[ ref $self ]} ";
    return $self;
  }
  debug 2, "No validation issues found, proceeding to mutate @{[ ref $self ]} ";

  # wrap it all in a transaction to undo if issues.
  my $txn_guard = $self->result_source->schema->txn_scope_guard;

  foreach my $related(keys %nested) {
    if(my $cb = $nested{$related}->{reject_if}) {
      next if $cb->($self, $related{$related});
    }
    debug 3, "mutating related $related for  @{[ ref $self ]} ";
    $self->_mutate_related($related);
  }

  my $result = $self->next::method();
  $txn_guard->commit;

  return $result;
}

sub register_column {
  my $class = shift;
  my ($column, $info) = @_;

  if(my $validates = delete($info->{validates})) {
    debug 1, "Found validation info inside column '$column' definition";
    $class->validates($column, @$validates);
  }

  if(my $filters = delete($info->{filters})) {
    debug 1, "Found filter info inside column '$column' definition";
    $class->filters($column, @$filters);
  }

  $class->next::method(@_);
}

# Gotta jump thru these hoops because of the way the Catalyst
# DBIC model messes with the result namespace but not the schema
# namespace

sub namespace {
  my $self = shift;
  my $class = ref($self) ? ref($self) : $self; 
  my ($ns) = ($class =~m/^(.+)::.+$/);
  return $ns;
}

# Trouble here is you can only inject one attribute per model.  Will be an
# issue if you have more than one confirmation validation on the model. Should be an easy
# fix, we just need to track incoming attributes so 'new' knows how to init
# all of them

sub inject_attribute {
  my ($class, $attribute_to_inject) = @_;
  my $injection = "
    package $class; 

    __PACKAGE__->mk_group_accessors(simple => '$attribute_to_inject');

    sub new {
      my (\$class, \$args) = \@_;
      my \$val = delete \$args->{$attribute_to_inject};
      my \$new = \$class->next::method(\$args);
      \$new->$attribute_to_inject(\$val);
      return \$new;
    }
  ";

  eval $injection;
  die $@ if $@;
}

# We override here because we really want the uninflated values for the columns.
# Otherwise if we try to inflate first we can get an error since the value has not
# been validated and may not inflate.  We see this very commonly on date type columns
# when the developer is using the DateTime inflation components.

sub read_attribute_for_validation {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return $self->get_column($attribute) if $self->result_source->has_column($attribute);

  if($self->has_relationship($attribute)) {
    my $rel_data = $self->relationship_info($attribute);
    my $rel_type = $rel_data->{attrs}{accessor};
    if($rel_type eq 'single') {
      return $self->$attribute;
      #return $self->related_resultset($attribute)->single;
    } elsif($rel_type eq 'multi') {
      return $self->related_resultset($attribute);
    } else {
      die "Cannot read_attribute_for_validation for '$attribute' of rel_type '$rel_type' in @{[ref $self]}";
    }
  }

  debug 1, "Failing back to accessor for 'read_attribute_for_validation' for object @{[ ref $self ]} attribute $attribute";
  debug 2, "Failing back @{[ $self->can($attribute) ? 'succeeds':'failed' ]}";

  return $self->$attribute if $self->can($attribute); 
}

# Provide basic uniqueness checking for columns.  This is basically a dumb DB lookup.  
# Its probably fine for light work but you'll need something more performant when your
# table gets big.

sub is_unique {
  my ($self, $attribute_name, $value) = @_;
  # Don't do this check unless the user is actually trying to change the
  # value (otherwise it will fail all the time).
  if($self->in_storage) {
    return 1 unless $self->is_column_changed($attribute_name);
  }
  my $found = $self->result_source->resultset->single({$attribute_name=>$value});
  return $found ? 0:1;
}

sub mark_for_deletion {
  my ($self) = @_;
  return unless $self->{__valiant_allow_destroy};
  $self->{__valiant_kiss_of_death} = 1;
}

sub unmark_for_deletion {
  my ($self) = @_;
  $self->{__valiant_kiss_of_death} = 0;
}

sub is_marked_for_deletion {
  my ($self) = @_;
  return $self->{__valiant_kiss_of_death} ? 1:0;
}

sub delete_if_in_storage {
  my ($self) = @_;
  $self->delete if $self->in_storage;  #TODO some sort of relationship handling...
}

####

sub build_related {
  my ($self, $related, $attrs) = @_;
  debug 2, "Building related entity '$related' for @{[ ref $self ]}";

  my $related_obj = $attrs ? $self->find_or_new_related($related, $attrs) : $self->new_related($related, +{});
  return if $related_obj->in_storage;  #I think we can skip if its found

  # TODO do this dance need to go into other places???
  # TODO do I need some set_from_related or something here to get everthing into _relationship_data ???
  my $relinfo = $self->relationship_info($related);
  if ($relinfo->{attrs}{accessor} eq 'single') {
    $self->{_relationship_data}{$related} = $related_obj;
  }
  elsif ($relinfo->{attrs}{accessor} eq 'filter') {
    $self->{_inflated_column}{$related} = $related_obj;
  }

  my @current_cache = @{ $self->related_resultset($related)->get_cache ||[] };
  $self->related_resultset($related)->set_cache([@current_cache, $related_obj]);

  return $related_obj;
}

sub build_related_if_empty {
  my ($self, $related, $attrs) = @_;
  debug 2, "Build related entity '$related' for @{[ ref $self ]} if empty";

  my $rel_data = $self->relationship_info($related);
  unless($rel_data) {
    if(my $rel_data = $self->_m2m_metadata->{$related}) {
      my $relation = $rel_data->{relation};
      my $foreign_relation = $rel_data->{foreign_relation};

      return if @{ $self->related_resultset($relation)->get_cache ||[] };
      my $obj = $self->build_related_if_empty($relation, $attrs);
      return if @{ $obj->related_resultset($foreign_relation)->get_cache ||[] };
      return $obj->build_related_if_empty($foreign_relation);
    }
  }  

  return if @{ $self->related_resultset($related)->get_cache ||[] };
  return $self->build_related($related, $attrs);
}

# When this param is an array we only use the last value, this is to support
# how checkboxes in HTML work (unchecked submits no value).
sub _param_is_delete {
  my ($value_proto) = shift;
  my $value = ref($value_proto) ? $value_proto->[-1] : $value_proto;
  return $value ? 1:0;
}

sub set_from_params_recursively {
  my ($self, %params) = @_;
  debug 2, "Starting 'set_from_params_recursively' for  @{[ ref $self ]}";
  foreach my $param (keys %params) { # probably needs to be sorted so we get specials (_destroy) first
    debug 3, "Starting param $param";
    # Spot to normalize serialized params (like for dates, etc).
    if($self->has_column($param)) {
      $self->set_column($param => $params{$param});
    } elsif($self->has_relationship($param)) {
      my %nested = $self->result_class->accept_nested_for;
      if(my $cb =  $nested{$param}->{reject_if}) {
        next if $cb->($self, $params{$param});
      }
      debug 3, "set_related_from_params for @{[ ref $self ]}, related $param";
      $self->set_related_from_params($param, $params{$param});
    } elsif($self->can($param)) {
      # Right now this is only used by confirmation stuff
      $self->$param($params{$param});
    } elsif( $param eq '_delete') {
      if( _param_is_delete($params{$param}) ) {
        if($self->in_storage) {
          debug 2, "Marking record @{[ ref $self ]}, id @{[ $self->id ]} for deletion";
          $self->mark_for_deletion;
        } else {
          debug 2, "Marking unsaved record @{[ ref $self ]}, id @{[ $self->id||'NA' ]} for deletion (wil be NOP)";
          $self->mark_for_deletion;
        }
      }
    } elsif( $param eq '_nop') {
        if($params{$param}) {
          debug 3, "Found _nop";
          delete $params{$param};
          $self->mark_for_deletion;
        }
    } elsif($param eq '_restore' && $params{$param}) {
      if($self->in_storage) {
        debug 3, "Unmarking record @{[ ref $self ]}, id @{[ $self->id ]} for deletion";
        $self->unmark_for_deletion;
        delete $params{_delete}; 
      } else {
        die "didn't deal with restore on unsaved records";
      }
    } elsif($param eq '_action') {
      my $action = $params{$param};
      $action = ref($action)||'' ? $action->[-1] : $action; # If action is a ref always use the last one
      debug 3, "Found _action param with value $action";
      if($action eq 'delete') {
        if($self->in_storage) {
          debug 2, "Marking record @{[ ref $self ]}, id @{[ $self->id ]} for deletion";
          $self->mark_for_deletion;
        } else {
          die "didn't deal with action 'delete' on unsaved records";
        }
      } elsif($action eq 'nop') {
        # Just skip, this is just a no op to deal with checkboxes and radio controls in HTML
      } else {
        die "Not sure what action '$action' is";
      }
    } else {
      die "Not sure what to do with '$param'";
    }
  }
}

sub set_related_from_params {
  my ($self, $related, $params) = @_;

  my $rel_data = $self->relationship_info($related);
  unless($rel_data) {
    if(my $rel_data = $self->_m2m_metadata->{$related}) {
      debug 2, "Setting params for $related on @{[ ref $self ]} using rel_type m2m";
      return $self->set_m2m_related_from_params($related, $params, $rel_data);
    }
  }

  my $rel_type = $rel_data->{attrs}{accessor};
  debug 2, "Setting params for $related on @{[ ref $self ]} using rel_type $rel_type";
  return $self->set_single_related_from_params($related, $params) if $rel_type eq 'single'; 
  return $self->set_multi_related_from_params($related, $params) if $rel_type eq 'multi'; 

  die "Unhandled relationship type: $rel_type";
}

# m2m is tricky
sub set_m2m_related_from_params {
  my ($self, $related, $params, $rel_data) = @_;
  my $relation = $rel_data->{relation};
  my $foreign_relation = $rel_data->{foreign_relation};

  # We do this to allow for both multi create/update via an array (typical DBIC
  # usage or via a hash of ordered keys (typical via CGI/Web).
  my @param_rows = ();
  if(ref($params) eq 'HASH') {
    @param_rows = map { $params->{$_} } sort { $a <=> $b} keys %{$params || +{}};
  } elsif(ref($params) eq 'ARRAY') { 
    @param_rows = @{$params || []};
  } else {
    # I think if we are here its because the nests set is
    # empty and we can ignore it for now but... not 100% sure :)
    next;
    die "We expect '$params' to be some sort of reference but its not!";
  }
  debug 2, "Setting m2m relation '$related' for @{[ ref $self ]} via '$relation' => '$foreign_relation'";

  # TODO its possible we need to creeate the m2m cache here
  # TODO We need to add PK columens to the @params_rows if we have them

  #use Devel::Dwarn;
  #Dwarn $self->result_source->_resolve_relationship_condition (
  #  infer_values_based_on => +{},
  #  rel_name => $relation,
  #  self_result_object => $self,
  #  foreign_alias => $relation,
  #  self_alias => 'me',
  #)->{inferred_values};
  
  return $self->set_multi_related_from_params($relation, [ map { +{ $foreign_relation => $_ } } @param_rows ]);
}

## TODO
sub is_pruned {
  return shift->{__valiant_is_pruned} ? 1:0;
}

sub is_removed {
  return (($_[0]->{__valiant_is_pruned} || $_[0]->{__valiant_kiss_of_death}) ? 1:0);
}

sub set_multi_related_from_params {
  my ($self, $related, $params) = @_;

  # We do this to allow for both multi create/update via an array (typical DBIC
  # usage or via a hash of ordered keys (typical via CGI/Web).
  my @param_rows = ();
  if(ref($params) eq 'HASH') {
    @param_rows = map { $params->{$_} } sort { $a <=> $b} keys %{$params || +{}};
  } elsif(ref($params) eq 'ARRAY') { 
    @param_rows = @{$params || []};
  } else {
    # I think if we are here its because the nests set is
    # empty and we can ignore it for now but... not 100% sure :)
    next;
    die "We expect '$params' to be some sort of reference but its not!";
  }

  my $allow_destroy = $self->_related_allow_destroy($related);

  # Queue up some meta data here just once.  We get existing rows ans
  # uniqiue key info (including PK info)
  debug 2, "looking for $related cached or existing rows";
  my @existing_rows = @{ $self->$related->get_cache||[] };
  unless(@existing_rows) {
    debug 3, "cache was empty so going to check DB"; ## TODO this is to support ->discard_changes but maybe not need
    if($self->in_storage) {
      @existing_rows = $self->$related->all;
    } else {
      debug 3, "record not in storage, so no point in looking for related rows";
    }
  }
  debug 2, "Found @{[ scalar @existing_rows ]} existing rows for $related";
  
  debug 2, "looking for uniques for $related";
  my @primary_columns = $self->$related->result_source->primary_columns;
  my %uniques = $self->$related->result_source->unique_constraints;
  my @search_sets = ('primary');
  my %nested = $self->result_class->accept_nested_for;

  # Gather the list of fields which are single type rels
  my @single_rels =  grep {
    my $rel_data = $self->$related->result_source->relationship_info($_);
    ($rel_data && ($rel_data->{attrs}{accessor} eq 'single')) ? 1:0;
  }  $self->$related->result_source->relationships;

  # Generally we alow finding the row via the PK only but the user can allow finding
  # by any unique if that's what they really want.
  if($nested{$related}{find_with_uniques}) {
    push @search_sets, grep { $_ ne 'primary' } keys %uniques;
  }

  # Ok now build up the new rows
  my @related_models = ();
  debug 2, "starting loop to update/create related $related (total @{[ scalar @param_rows ]} rows in loop)";
  foreach my $param_row (@param_rows) {
    debug 3, "top of new loop on param_rows";
    if($param_row->{_nop}) {
      debug 3, "Is a NOP row, so skipping";
      next;
    }

    # Ok so if $self is in storage we expect any $related FKs to match whatever is $self $PK.  If that
    # FK is empty we add it.   If its there but has an unexpected value, that's an error (and probably
    # a hacking attempt
    if($self->in_storage) {
      my %cond = %{$self->result_source->relationship_info($related)->{cond}};
      foreach my $fk_proto (keys %cond) {
        my $pk_proto = $cond{$fk_proto};
        my ($pk) = ($pk_proto=~m/^self\.(.+)$/); 
        my ($fk) = ($fk_proto=~m/^foreign\.(.+)$/);

        if(exists $param_row->{$fk}) {
          unless($param_row->{$fk} eq $self->get_column($pk)) {
            DBIx::Class::Valiant::Util::Exception::BadParameterFK->throw(
              fk_field=>$fk, fk_value=>$param_row->{$fk}, 
              pk_field=>$pk, pk_value=>$self->get_column($pk), 
              related=>$related, me=>$self);
          }
        } else {
          $param_row->{$fk} = $self->get_column($pk); # set it since that should help with the lookups
        }
      }
    } else {
      # Now if $self is not in storage we expect the related FK to be empty.  If not throw error since
      # its possible a hacking attempt
      my %cond = %{$self->result_source->relationship_info($related)->{cond}};
      foreach my $fk_proto (keys %cond) {
        my $pk_proto = $cond{$fk_proto};
        my ($pk) = ($pk_proto=~m/^self\.(.+)$/); 
        my ($fk) = ($fk_proto=~m/^foreign\.(.+)$/);

        if(exists $param_row->{$fk}) {
          unless(!defined($param_row->{$fk})) {
            DBIx::Class::Valiant::Util::Exception::BadParameterFK->throw(
              fk_field=>$fk, fk_value=>$param_row->{$fk}, 
              pk_field=>$pk, pk_value=>'undef', 
              related=>$related, me=>$self);
          }
        }
      }
    }

    my $was_add = delete $param_row->{_add};
    my $related_model;
    if(blessed $param_row) {
      debug 1, "params are an object";
      $related_model = $param_row;
    } elsif( (ref($param_row)||'') eq 'HASH') {

      # The first thing to do is to see if we can find a row either in the existing cache
      # or in the DB, matched on the Primary key and (if enabled) unique keys.
      my %keys_used_to_find = ();
      SEARCH_UNIQUE_KEYS: foreach my $key (@search_sets) {
        debug 2, "trying to find a row for $related using key $key";

        my @key_columns = @{$uniques{$key}};
        my %matching = map { $_ => $param_row->{$_} } grep { exists $param_row->{$_} } @key_columns;


        next unless scalar(@key_columns) == scalar(keys(%matching)); # only match when its a full key match
        debug 2, "key $key exists in params";

        # Find matching if they exist in the cache
        foreach my $row (@existing_rows) {
          my %unique_fields = map { $_ => $row->get_column($_) } @key_columns;
          my $a = join "", map { $_, $unique_fields{$_} } sort keys(%unique_fields);
          my $b = join "", map { $_, $matching{$_} } sort keys(%matching);
          if($a eq $b) {
            $related_model = $row;
            if($related_model) {
              debug 2, "found related model for $related with $key in cache";
              %keys_used_to_find = (%keys_used_to_find, %matching);
              last SEARCH_UNIQUE_KEYS
            }
          }
        }

        # If it doesn't match in the cache then we have to find it in the DB. TODO I'm skipping this
        # lookup for now since I don't think we need it unless the user failed to properly prefetch.
        # Its pointless to do this unless $self is in storage anyway
        unless($related_model) {
          debug 2, "Trying to find $related in DB with key $key (SKIPPING)";
          #$related_model = $self->find_related($related, \%matching, +{key=>$key}) if $self->in_storage;
          if($related_model) {
            debug 2, "found related model for $related with $key in DB";
            %keys_used_to_find = (%keys_used_to_find, %matching);
            last SEARCH_UNIQUE_KEYS
          }
        }
      }

      # If we get here its possible there's a single type relation we can use to complete 
      # the lookup.  TODO: Not sure if this should be a param setting in the nested_for data 
      # (it probably should be).  Also not sure if we should limit the ->find_related to 
      # just the FK rel.

      if(grep {$param_row->{$_}} @single_rels) {
        debug 2, "Falling back to default find_related for $related using full param_row";
        $related_model = $self->find_related($related, $param_row) unless $related_model || !%{$param_row};
      }

      # OK so we didnt find it via keys either in the cache or in the DB so that means
      # we need to just create it.
      unless($related_model) {
        debug 2, "Didn't find related model '$related' so making it";
        $related_model = $self->new_related($related, +{});
      }
      debug 2, "About to set_from_params_recursively for @{[ ref $related_model ]}";

      if($was_add) {
        debug 3, "Since @{[ ref $related_model]} was an _add we won't validate since its empty";
        $related_model->skip_validate;
        $related_model->{__valiant_donot_insert} = 1;
      }

      if($allow_destroy) {
          $related_model->{__valiant_allow_destroy} = 1;
      }
      
      # Don't set params for the found keys (waste of time, no change)
      my %params_for_recursive = %$param_row;
      delete @params_for_recursive{ keys %keys_used_to_find} if %keys_used_to_find;
      $related_model->set_from_params_recursively(%params_for_recursive);

      # Ok, so after set_from_params_recursively if the $related_model is not in storage
      # we 'might' have enough info to actually load it now.
      if(!$related_model->in_storage && !$related_model->is_marked_for_deletion) {
        # TODO: We should skip this if we've already tried a full PK
        my %ident = %{ $related_model->_storage_ident_condition ||+{} };
        my $fully_id = 1;
        foreach my $ident(keys %ident) {
          next if defined($related_model->get_column($ident)); # can't try to load from DB if the PK isn't fully found
          $fully_id = 0;
        }
        if($fully_id) {
          my $copy = $related_model->get_from_storage(); # If we now have the full PK we can find it
          $related_model = $copy if $copy;
        }
      }
    } else {
      die "Not sure what to do with $param_row";
    }
    push @related_models, $related_model;
  }

  # This bit we diff between the rows loaded in the orignal cache and what it looks
  # like after the multi update.   Rows that are no longer present are marked for
  # deletion if deletion is allowed
  my @new_pks =  map {
    my $r = $_; 
    +{
      map { $_ => $r->$_ } $r->result_source->primary_columns
    } 
  } grep { $_->in_storage } @related_models;

  debug 1, "Reviewing existing rows for relation $related (total @{[ scalar @existing_rows ]}) for deletion";
  
  foreach my $current (@existing_rows) {
    next if grep {
      my %fields = %$_;
      my @matches = grep { 
        $current->get_column($_) eq $fields{$_}
      } keys %fields;
      scalar(@matches) == keys %fields ? 1 : 0;
    } @new_pks;

    debug 2, "ok its not a new one";

    # Only mark for deletion if its actually in store.
    if($current->in_storage) {
      debug 2, "Marking $current for deletion";
      $current->{__valiant_allow_destroy} = 1 if $allow_destroy;
      $current->mark_for_deletion;  # might be a good idea to find a way to expose this via an override-able method

      # Mark its children as pruned, recursively
      my $cb; $cb = sub {
        my $row = shift;
        debug 3, "marking $row to be pruned" unless $row->is_marked_for_deletion;
        $row->{__valiant_is_pruned} = 1; # unless $row->is_marked_for_deletion;
        my @related = keys %{$row->{_relationship_data}||+{}};
        # TODO only do this for has_one, might_have, has_many
        debug 3, "$row has related data to prune @{[ join ',', @related ]}";
        foreach $related(@related) {
          debug 3, "checking $related for possible pruning";
          my @rows = @{$row->related_resultset($related)->get_cache||[]};
          debug 3, "found @{[ scalar @rows ]} to be pruned";
          foreach my $inner_row (@rows) {
            $cb->($inner_row);
          }
        }
      };
      $cb->($current) if $current->is_marked_for_deletion; # We check because 'mark_for_deletion' will skip unless 'allow_destroy' is set
    }

    if ($current->in_storage) {
      debug 3, "Current model is in storage so put it into cache";
      push @related_models, $current;
    } else {
      debug 3, "Current model is not in storage so don't bother to cache it since its marked for delete anyway";
    }
  }

  debug 3, "About to save cache for @{[ ref $self ]} related resultset $related; has @{[ scalar @related_models ]} models to cache";

  $self->related_resultset($related)->set_cache(\@related_models);
  $self->{_relationship_data}{$related} = \@related_models;
  $self->{__valiant_related_resultset}{$related} = \@related_models; # we have a private copy
}

sub set_single_related_from_params {
  my ($self, $related, $params) = @_;
  my %nested = $self->result_class->accept_nested_for;
  my $allow_destroy = $nested{allow_destroy};

  # Is there an existing related object in the cache?  If so then we
  # will merge params with existing rather than create a new one or
  # run a new query to find one.  I 'think' that's the most expected behavior...
  my ($related_result) = @{ $self->related_resultset($related)->get_cache ||[] }; # its single so only one
  $related_result = $self->{_relationship_data}{$related} unless $related_result;

  if($related_result) {
    ## TODO I might need to do something else if $params is blessed
    ## TODO I think we need the below logic to see if $params has a PK and then use
    ## that as an override.
    #
    ## TODO this is probably wrong if $params has different FKs or unique fields

    debug 2, "Found cached related_result $related for @{[ ref $self ]} ";
    $related_result->{__valiant_allow_destroy} = 1 if $allow_destroy;
    $related_result->set_from_params_recursively(%$params);
  } else {
    debug 2, "No cached related_result $related for @{[ ref $self ]} ";
    if(blessed($params)) {
      debug 2, "related_result $related for @{[ ref $self ]} is blessed object";
      $related_result = $params;
    } else {
      debug 2, "related_result $related for @{[ ref $self ]} is hashed params";

      # When doing an update on single rels (has_one/belongs_to) you need to figure out
      # if you are recursing an update into that exist rel or if you are replacing that
      # rel with a new one (find_or_new).

      if($self->in_storage) {
        my %local_params = %$params;
        my %cond = %{$self->result_source->relationship_info($related)->{cond}};
        my @pks = $self->result_source->primary_columns;
        foreach my $fk_proto (keys %cond) {
          my $pk_proto = $cond{$fk_proto};
          my ($pk) = ($pk_proto=~m/^self\.(.+)$/); 
          my ($fk) = ($fk_proto=~m/^foreign\.(.+)$/);
          next unless grep { $_ eq $pk } @pks;;

          if(exists $local_params{$fk}) {
            unless($local_params{$fk} eq $self->get_column($pk)) {
              DBIx::Class::Valiant::Util::Exception::BadParameterFK->throw(
                fk_field=>$fk, fk_value=>$local_params{$fk}, 
                pk_field=>$pk, pk_value=>$self->get_column($pk), 
                related=>$related, me=>$self);
            }
          } else {
            #$local_params{$fk} = $self->get_column($pk); # set it since that should help with the lookups
          }
        }

        debug 2, "Updating related result '$related' for @{[ ref $self ]} ";
        my %pk = map { $_ => delete $local_params{$_} }
          grep { exists $local_params{$_} }
          $self->related_resultset($related)->result_source->primary_columns;

        # If the user supplied the PK that means use that exact record and replace the current one
        # also apply any updates to that record as indicated.
        if(%pk) {
          debug 3, "Updating with exact record matching pk";

          $related_result = $self->result_source->related_source($related)->resultset->find($params); ## TODO shouldnt this be \%pk??
          $related_result = $self->result_source->related_source($related)->resultset->find(\%pk); ## TODO shouldnt this be \%pk??

          $self->set_from_related($related, $related_result);

          #my $rev_data = $self->result_source->reverse_relationship_info($related);
          #my ($reverse_related) = keys %$rev_data;
          #$related_result->set_from_related($reverse_related, $self) if $reverse_related; # Don't have this for might_have
          $related_result->{__valiant_allow_destroy} = 1 if $allow_destroy;
          $related_result->set_from_params_recursively(%$params);
        } else {
          debug 3, "Updating with record from params (no matching PK)";

          # If the user did not give us a PK either;
          #   1) if undate_only=>1 then update the current record (if existing; create otherwise)
          #   2) otherwise create a new record off the parent.
          
          if(+{$self->result_class->accept_nested_for}->{$related}{update_only}) {
            debug 3, 'update_only true';
            $related_result = $self->related_resultset($related)->single;
            unless($related_result) {
              #$related_result = $self->find_or_new_related($related, $params); # TODO should find from any unique keys on
              # If one doesn't already exist that means 'make a new one'
              $related_result = $self->new_related($related, $params);
            }
          } else {
            debug 3, "update_only false for rel $related on @{[ $self]}";

            my %uniques = $self->related_resultset($related)->result_source->unique_constraints;
            if(%uniques) {
              debug 4, "Have unique constraints to try to find on";
              foreach my $unique_key (keys %uniques) {
                next if $unique_key eq 'primary'; # already done
                debug 4, "checking key $unique_key for related $related";
                my %keys_found = map { $_=>$params->{$_} } grep { exists $params->{$_} } @{$uniques{$unique_key}};
                #$related_result = $self->find_related($related, \%keys_found);
                next unless %keys_found;
                $related_result = $self->result_source->related_source($related)->resultset->find(\%keys_found);
                if($related_result) {
                  debug 4, "found result with unique key $unique_key";
                  last;
                }
              }
            }
            
            #$related_result = $self->result_source->related_source($related)->resultset->find($params);  # TODO problably shoulld search on unique keys only
            unless($related_result) {
              debug 3, "Did not find result for $related so creating new result";
              # $self is in storage so it 'shou;d be safe to do this;
              $related_result = $self->new_related($related, $params);
              #$related_result = $self->result_source->related_source($related)->resultset->new_result($params);
            }

            $self->set_from_related($related, $related_result);
            #my $rev_data = $self->result_source->reverse_relationship_info($related);
            # my ($key) = keys(%$rev_data);
            #$related_result->set_from_related($key, $self) if $key; # Don't have this for might_hav
          }
          $related_result->{__valiant_allow_destroy} = 1 if $allow_destroy;
          $related_result->set_from_params_recursively(%$params);
        }
      } else {
        debug 2, "Find or new related result '$related' for @{[ ref $self ]} which is not saved yet"; 
        # Ok so the object isn't in storage, which means you don't have an database supplied PKs.  So
        # can't do related_resultset since that always returns nothing (if $self doesn't exist in the DB
        # there's nothing in the DB to find.
        #$related_result = $self->find_or_new_related($related, $params);
        #$related_result->set_from_params_recursively(%$params);
        my %local_params = %$params;

        my %cond = %{$self->result_source->relationship_info($related)->{cond}};
        my @pks = $self->result_source->primary_columns;

        my $flag = 0;
        foreach my $fk_proto (keys %cond) {
          my $pk_proto = $cond{$fk_proto};
          my ($pk) = ($pk_proto=~m/^self\.(.+)$/); 
          my ($fk) = ($fk_proto=~m/^foreign\.(.+)$/);
          next unless grep { $_ eq $pk } @pks; 
          next unless exists $local_params{$fk};
          $flag++ if defined($local_params{$fk});
        }

        if($flag == scalar(@pks)) {
          DBIx::Class::Valiant::Util::Exception::BadParameters->throw(related=>$related, me=>$self);
        }

        my %pk = map { $_ => delete $local_params{$_} }
          grep { exists $local_params{$_} }
          $self->related_resultset($related)->result_source->primary_columns;

        # If the user supplied the PK that means use that exact record and replace the current one
        # also apply any updates to that record as indicated.
        if(%pk) {
          debug 3, "setting with exact record matching pk %pk";
          $related_result = $self->result_source->related_source($related)->resultset->find(\%pk);
          #   $self->set_from_related($related, $related_result);
          $related_result->{__valiant_allow_destroy} = 1 if $allow_destroy;
          $related_result->set_from_params_recursively(%$params);
        } else {
          debug 3, "No PK for $related, lets see if there's other ways to find it";
          if($nested{$related}{find_with_uniques}) {
            debug 3, "finding $related for $self with find_with_uniques matching";
            my %uniques = $self->result_source->related_source($related)->unique_constraints;
            foreach my $unique (keys %uniques) {
              next if $unique eq 'primary'; # already done
              my @key_columns = @{$uniques{$unique}};
              my %matching = map { $_ => $params->{$_} } grep { exists $params->{$_} } @key_columns;

              next unless scalar(@key_columns) == scalar(keys(%matching)); # only match when its a full key match
              debug 2, "key $unique exists in params";
              $related_result = $self->result_source->related_source($related)->resultset->find(\%matching);
              if($related_result) {
                debug 3, "Found result via unique keys";
                last;  
              }
            }
          }

          unless($related_result) {
            debug 3, "Did not find result for $related so creating new result";
            $related_result = $self->new_related($related, $params);
          }
          $self->set_from_related($related, $related_result) unless $self->in_storage;
          $related_result->{__valiant_allow_destroy} = 1 if $allow_destroy;
          $related_result->set_from_params_recursively(%$params);
        }
      }
    }
  }

  $self->related_resultset($related)->set_cache([$related_result]);
  $self->{_relationship_data}{$related} = $related_result;
  $self->{__valiant_related_resultset}{$related} = [$related_result];

  # ok so... what about the reverse side of this rel?  Seems this makes for infinite recursion
  #my $rev_data = $self->result_source->reverse_relationship_info($related);
  #my ($key) = keys(%$rev_data);
  #$related_result->{_relationship_data}{$key} = $self;
}

sub mutate_recursively {
  my ($self) = @_;
  debug 2, "mutating relationships for @{[ $self ]}";

  $self->_mutate if $self->is_changed || $self->is_marked_for_deletion;
  foreach my $related (keys %{$self->{_relationship_data}}) {
    #next unless $self->related_resultset($related)->first; # TODO don't think I need this
    debug 2, "mutating relationship $related";
    $self->_mutate_related($related);
  }
}

sub _mutate {
  my ($self) = @_; 
  if($self->is_marked_for_deletion) {
    debug 2, "deleting @{[ ref $self ]} if in storage";
    $self->delete_if_in_storage;
  } else {
    debug 2, "update_or_insert for @{[ ref $self ]}";

    # Ok so when doing update we are losing the relationed info so brute forse
    # cache and restore it (probably wrong but passing tests for now....)

    my %rels = %{$self->{_relationship_data}||+{}};
    my %rels_rs = %{$self->{related_resultsets}||+{}};

    $self->update_or_insert; 

    # copies but quite likely now incorrect even thos my tests pass.....
    # maybe I need a better way to restore this stuff.
    $self->{_relationship_data} = \%rels;
    $self->{related_resultsets} = \%rels_rs if %rels_rs;
  }
}

sub _mutate_related {
  my ($self, $related) = @_;
  my $rel_data = $self->relationship_info($related);
  unless($rel_data) {
    if(my $rel_data = $self->_m2m_metadata->{$related}) {
      return $self->_mutate_m2m_related($related, $rel_data);
    }
  }
  
  my $rel_type = $rel_data->{attrs}{accessor};

  return $self->_mutate_single_related($related) if $rel_type eq 'single';
  return $self->_mutate_multi_related($related) if $rel_type eq 'multi';

  die "not sure how to mutate $related of type $rel_type";
}

sub _mutate_m2m_related {
  my ($self, $related, $rel_data) = @_;
  my $relation = $rel_data->{relation};
  my $foreign_relation = $rel_data->{foreign_relation};

  return $self->_mutate_multi_related($relation);
}

sub _mutate_multi_related {
  my ($self, $related) = @_;
  my @related_results = @{ $self->{__valiant_related_resultset}{$related} ||[] };
  my $rev_data = $self->result_source->reverse_relationship_info($related);
  my ($reverse_related) = keys %$rev_data;

  debug 2, "Trying to mutate multi relations '$related'";

  foreach my $related_result (@related_results) {
    next unless $related_result->is_changed || $related_result->is_marked_for_deletion || !$related_result->in_storage;
    debug 3, "@{[ ref $related_result ]} ready for mutating";
    $related_result->set_from_related($reverse_related, $self) if $reverse_related; # Don't have this for might_have
    $related_result->mutate_recursively;
  }

  # If the mutation completed we need to remove all marked for delation
  my @new_results = grep { !$_->is_marked_for_deletion } @related_results;

  $self->related_resultset($related)->set_cache(\@new_results);
  $self->{_relationship_data}{$related} = \@new_results;
  $self->{__valiant_related_resultset}{$related} = [@new_results];

  # TODO need to update rels
}


sub _mutate_single_related {
  my ($self, $related) = @_;
  #my ($related_result) = @{ $self->{__valiant_related_resultset}{$related} ||[] };
  #my ($related_result) = @{ $self->related_resultset($related)->get_cache ||[] };
  my $related_result =  $self->{_relationship_data}{$related};
  unless($related_result) {
    debug 2, "Skipping _mutate_single_related because related $related is not cached";
    return;
  }

  my $rev_data = $self->result_source->reverse_relationship_info($related);
  my ($reverse_related) = keys %$rev_data;

  debug 2, "Trying to mutate @{[ ref $related_result ]}";
  debug 3, "@{[ ref $related_result ]} is_changed: @{[ $related_result->is_changed]}";
  debug 3, "@{[ ref $related_result ]} is_marked_for_deletion: @{[ $related_result->is_marked_for_deletion]}";
  debug 3, "@{[ ref $related_result ]} in_storage: @{[ $related_result->in_storage]}";

  if($related_result->is_changed || $related_result->is_marked_for_deletion || !$related_result->in_storage) {
    debug 3, "@{[ ref $related_result ]} ready for mutating";
    $related_result->set_from_related($reverse_related, $self) if $reverse_related; # Don't have this for might_have
    $related_result->mutate_recursively;

    # I think if its in storage we need to set cache and all even if marked for deletation
    #my @new_cache = $related_result->is_marked_for_deletion ? () : ($related_result);
    $self->related_resultset($related)->set_cache([$related_result]);
    $self->{__valiant_related_resultset}{$related} = [$related_result];
    $self->{_relationship_data}{$related} = $related_result;
    return;
  }

  # Just continue, we need to do this since related objects might have changed...
  $related_result->mutate_recursively;
}

1;

=head1 NAME

DBIx::Class::Valiant::Result - Base component to add Valiant functionality

=head1 SYNOPSIS

    package Example::Schema::Result::Person;

    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components('Valiant::Result');

Or just add to your base Result class


    package Example::Schema::Result;

    use strict;
    use warnings;
    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components('Valiant::Result');

=head1 DESCRIPTION

Glue L<Valiant> validations into your DBIC result sources.   This package just has some basic
API level docs, you should see L<DBIx::Class::Valiant> for a somewhat more detailed documentation
and examples.

=head1 CONTEXTS

When doing an insert / create on a result, we automatically add a 'create' context which you
can use to limit validations to create events.  Additionally for an update we add an 'update'
context.

=head1 CLASS METHODS

This component adds the following class or package methods to your result classes.  Please note
this is only class methods added by this package, it does not cover those which are aggregated
from the L<Valiant::Validates> role.

=head2 auto_validation (Boolean)

Defaults to true.  When true Valiant will first perform a validation on the existing result
object (and any related objects nested under it which have been loaded from the DB or created)
and if there are validation errors will skip persisting the data to the database.  You can use
this to disable this behavior globally.  Please not there are features to enable skipping auto
validation on a per result/set basis as well.

=head2 accept_nested_for (field => \%options)

Allows you to update / create related objected which are nested under the parent (via has_one,
might_have or has_many defined relationships).  Accepts the following hashref of options:

=over 4

=item allow_destroy

By default you cannot delete related (nested) results.  Setting this to true allows that.

=item reject_if

A coderef that will cause a nested result to skip if you return true.   Arguments are the
parent result and a hashref of the values to be used for the nested build:

    __PACKAGE__->accept_nested_for(
      might => {
        reject_if => sub {
          my ($self, $params) = @_;
          return ($params->{value}||'') eq 'test14' ? 1:0;
        },
      }
    );

Please note that if you have this on a C<has_many> relationship the code ref will be invoked
on each result in the collection of related results you are attempted to nest values into.  This
can impact performance.

=item limit

accepts a scalar which will cause the nested results to fail of the number of items is
greater than the scalar.

=item update_only

For C<has_one> or C<might_have> relationships will force update the existing nested result (if
any exists) even if you fail to set the primary key.  Otherwise the current record will be
deleted and a new one inserted.  Default is false.

=item find_with_uniques

Generally we only try to find a matching row in the DB if a primary key is given.   If you set 
this to true then we also try to match using and unique keys establish for the related row.

=back

B<NOTE> Recursion warning!  You cannot currently C<accept_nested_for> for a relationship
whose target result source is setting C<accept_nested_for> into yourself.   This is probably
fixable, patches and use cases welcomed!

=head1 METHODS

This component adds the following object methods. Please note
this is only class methods added by this package, it does not cover those which are aggregated
from the L<Valiant::Validates> role.

=head2 is_marked_for_deletion

Will be true if the result has been marked for deletion.   You might see this in a related result
nested under a parent when an update calls for the record to be deleted but validation errors prevented
the deletion from occuring.

=head2 is_pruned

Will be true if the result is nested under a result which has been C<marked_for_deletion>.  The result
is not itself marked to be deleted (if validation passes) but it will no longer be attached to the
parent result under which it is nested.

=head2 is_removed

Is true if C<is_pruned> or C<is_marked_for_deletion> is true.

=head2 build_related

=head2 build_related_if_empty

Builds a related result into the cache. The result is only in memory; it can be used to run validation
but is not inserted unless specified later.

You might use these methods if you are validating a nested results but the results are not already in
the database (see C<example> directory for an application that uses this).

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>, L<DBIx::Class>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


