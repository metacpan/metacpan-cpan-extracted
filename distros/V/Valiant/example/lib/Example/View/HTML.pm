package Example::View::HTML;

use Moose;
use Mojo::ByteStream qw(b);
use Scalar::Util 'blessed';

extends 'Catalyst::View::MojoTemplate';


__PACKAGE__->config(
  helpers => {
    attr => \&attr,
    method_attr => \&method_attr,
    style_attr => \&style_attr,
    errors_box => \&errors_box,

    # simple tag helpers
    tag => \&tag,
    form_tag => \&form_tag,
    label_tag => \&label_tag,
    input_tag => \&input_tag,
    button_tag => \&button_tag,
    option_tag => \&option_tag,
    select_tag => \&select_tag,
    options_for_select => \&options_for_select,
    checkboxes_from_collection => \&checkboxes_from_collection,
    model_errors_for => \&model_errors_for,

    # tag helpers with an underlying model
    form_for => \&form_for,
    label => \&label,
    input => \&input,
    errors_for => \&errors_for,
    model_errors => \&model_errors,
    human_model_name => \&human_model_name,
    model => \&model,
    fields_for => \&fields_for,
    zelect => \&zelect,
    select_from_collection => \&select_from_collection,
  },
);

sub errors_box {
  my ($self, $c, $model, %attrs) = @_;
  my @errors = ();
  if(blessed $model) {
    @errors = $model->errors->full_messages;
  } elsif($model) {
    @errors = ($model);
  }
  if(@errors) {
    my $max_errors = $attrs{max_errors} ? delete($attrs{max_errors}) : scalar(@errors);
    my $errors = join '', map { "<li>$_" } @errors[0..($max_errors-1)];
    my $attrs =  join ' ', map { "$_='$attrs{$_}'"} keys %attrs;
    return b("<div $attrs/>$errors</div>");
  } else {
    return '';
  } 
}

sub _stringify_attrs {
  my %attrs = @_;
  return unless %attrs;
  return my $attrs =  join ' ', map { "$_='@{[ $attrs{$_}||'' ]}'"} keys %attrs;
}

sub _parse_proto {
  my @proto = @_;
  my $content = undef;
  if(@proto && (ref($proto[-1]) eq 'CODE')) {
    $content = pop @proto;
  } elsif(@proto && (ref(\$proto[-1] ||'') eq 'SCALAR')) {
    my $text = pop @proto;
    $content = sub { $text };
  }
  return ($content) unless @proto;
  my %attrs = ref($proto[0])||'' eq 'HASH' ? %{$proto[0]}:  @proto;
  return ($content, %attrs);
}

sub attr {
  my ($self, $c, $name, $value) = (shift, shift, shift, shift);
  return $name => $value, @_;
}

sub method_attr {
  my ($self, $c, $attr) = (shift, shift, shift);
  die "invalid method value" unless grep { $attr =~ /$_/i } qw(GET POST PUT);
  return $self->attr($c, 'method', $attr, @_);
}

sub style_attr {
  my ($self, $c, $attr) = (shift, shift, shift);
  return $self->attr($c, 'style', $attr, @_);
}


sub tag {
  my ($self, $c, $name, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);

  my $tag = "<${name}";
  $tag .= " @{[ _stringify_attrs(%attrs) ]}" if %attrs;
  return b "$tag/>" unless $content;

  $c->stash->{'valiant.view.current_tag'} = $name;
  my $content_expanded = $content->() || '';
  $tag .= ">" . $content_expanded . "</${name}>";
  delete $c->stash->{'valiant.view.current_tag'};
  return b $tag;
}

sub form_tag {
  my ($self, $c, @proto) = @_;
  return $self->tag($c, 'form', @proto);
}

sub label_tag {
  my ($self, $c, @proto) = @_;
  return $self->tag($c, 'label', @proto);
}

sub input_tag {
  my ($self, $c, @proto) = @_;
  return $self->tag($c, 'input', @proto);
}

sub button_tag {
  my ($self, $c, @proto) = @_;
  return $self->tag($c, 'button', @proto);
}

sub select_tag {
  my ($self, $c, @proto) = @_;
  return $self->tag($c, 'select', @proto);
}

sub option_tag {
  my ($self, $c, @proto) = @_;
  return $self->tag($c, 'option', @proto);
}

# options_for_select( [ [ 'Content', 'value', ?\%attrs], ... ], %attrs)
sub options_for_select {
  my ($self, $c, $options, $global_attrs) = @_;
  my %global_attrs = $global_attrs ? %$global_attrs : ();
  my $selected_value = exists($global_attrs{selected}) ? delete($global_attrs{selected}) : undef;

  my $content = '';
  foreach my $option (@$options) {
    if( (ref($option)||'') eq 'ARRAY') {
      my %merged_attrs = (%global_attrs, value=>$option->[1]);
      %merged_attrs = (%merged_attrs, %{$option->[2]}) if scalar(@$option) == 3;
      $merged_attrs{selected} = 1 if $merged_attrs{value} eq $selected_value;
      $content .= $self->option_tag($c, \%merged_attrs, $option->[0]);
    } else {
      my %merged_attrs = (%global_attrs, value=>$option);
      $merged_attrs{selected} = 1 if $merged_attrs{value} eq $selected_value;
      $content .= $self->option_tag($c, \%merged_attrs, $option);
    }
  }
  return $content;
}

# %= options_from_collection_for_select $states, +{option_value=>'id', option_label=>'name', ... }
sub options_from_collection_for_select {
  my ($self, $c, $options_collection, $global_attrs) = @_;
  my %global_attrs = $global_attrs ? %$global_attrs : ();
  my $value = exists($global_attrs{option_value}) ? delete($global_attrs{option_value}) : 'value';
  my $label = exists($global_attrs{option_label}) ? delete($global_attrs{option_label}) : 'label';
  my @options = map {[ $_->$label => $_->$value ]} $options_collection->all;
  return $self->options_for_select($c, \@options, $global_attrs);
}


# %= checkboxes_from_collection 'person_roles.role', $roles, +{value_field=>'id', label_field=>'name', ... }
sub checkboxes_from_collection {
  my ($self, $c, $field_proto, $collection, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};
  
  my $value = exists($attrs{value_field}) ? delete($attrs{value_field}) : 'id';
  my $label = exists($attrs{label_field}) ? delete($attrs{label_field}) : 'label';

  my $key = '';
  my $field_model = $model;
  my @field_path = split('\.', $field_proto);
  foreach my $part (@field_path) {
    my $info = $field_model->result_source->relationship_info($part);

    if($info) {
      ($key) = keys %{$info->{attrs}{fk_columns}};  # only works with a single field PK for now
      $field_model = $field_model->related_resultset($part);
    } elsif($info = $field_model->_m2m_metadata->{$part}) {
      my $rs_method = $info->{rs_method};
      $field_model = $field_model->$rs_method;
      ($key) = $field_model->result_source->primary_columns;  # only works with a single field FK for now
    }
  }

  my $idx = 0;
  my @tags = ();
  my $related_part = shift @field_path;
  foreach my $item($collection->all) {
    local $c->stash->{'valiant.view.form.namespace'} = [@namespace, $related_part, $idx];
    local $c->stash->{'valiant.view.form.model'} = $item;

    my %checked = $field_model->contains($item) ? (checked=>1) : ();

    push @tags, b "<div class='form-check'>";
    push @tags, $self->input($c, $key, +{type=>'checkbox', value=>$item->$value, class=>'form-check-input', %checked});
    push @tags, $self->label($c, $key, +{class=>'form-check-label'}, sub { $item->$label } );
    push @tags, b "</div>";

    $idx++;
  }

  return b @tags;
}

# %= select_from_collection 'state_id', $states,  +{ class=>'form-control' }
# %= select_from_collection 'state_id', [$states, id=>'name'], +{ class=>'form-control' }
#
sub select_from_collection {
  my ($self, $c, $field, $options, $attrs) = @_;
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};

  $attrs->{class} .= ' is-invalid' if $model->errors->messages_for($field) ;

  if(ref($options) eq 'ARRAY') {
    $attrs->{option_value} = $options->[1];
    $attrs->{option_label} = $options->[2];
    $options = $options->[0];
  }

  $attrs->{id} ||= join '_', (@namespace, $field);
  $attrs->{name} ||= join '.', (@namespace, $field);

  return $self->select_tag($c, $attrs, $self->options_from_collection_for_select($c, $options, +{%$attrs, selected=>$model->read_attribute_for_validation($field)}));
}

# %= zelect 'state_id', [map {[ $_->name, $_->id ]} $states->all], +{ class=>'form-control' }
sub zelect {
  my ($self, $c, $field, $options, $attrs) = @_;
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};

  $attrs->{id} ||= join '_', (@namespace, $field);
  $attrs->{name} ||= join '.', (@namespace, $field);

  return $self->select_tag($c, $attrs, $self->options_for_select($c, $options, +{selected=>$model->read_attribute_for_validation($field)}));
}

sub form_for {
  my ($self, $c, $model, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);

  $attrs{id} ||= $model->model_name->param_key;
  $attrs{method} ||= 'POST';

  if($model->can('in_storage') && $model->in_storage) {
    my $value = $model->model_name->param_key . '_edit';
    $attrs{id} ||= $value;
    $attrs{class} ||= $value;
  } else {
    my $value = $model->model_name->param_key . '_new';
    $attrs{id} ||= $value;
    $attrs{class} ||= $value;
  }

  local $c->stash->{'valiant.view.form.model'} = $model;
  local $c->stash->{'valiant.view.form.namespace'}[0] = $attrs{id};

  return $self->form_tag($c, \%attrs, $content);
}

sub label {
  my ($self, $c, $field, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};

  $attrs{for} ||= join '_', (@namespace, $field);
  $content ||= sub { $model->human_attribute_name($field) };
  
  return $self->label_tag($c, \%attrs, $content);
}

sub input {
  my ($self, $c, $field, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};
  my @errors = $model->errors->messages_for($field);

  $attrs{type} ||= 'text';
  $attrs{id} ||= join '_', (@namespace, $field);
  $attrs{name} ||= join '.', (@namespace, $field);
  $attrs{value} = ($model->read_attribute_for_validation($field) || '') unless defined($attrs{value});
  $attrs{class} .= ' is-invalid' if @errors;

  return $self->input_tag($c, \%attrs, $content);
}

sub hidden {
  my ($self, $c, $field , @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  return $self->input($c, $field, +{%attrs, type=>'hidden'}, $content);
}

sub errors_for {
  my ($self, $c, $field, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};
  my @errors = $model->errors->full_messages_for($field);

  return '' unless @errors;

  my $class = $attrs{class}||'';
  $class .= ' invalid-feedback';
  $attrs{class} = $class;

  my $max_errors = $attrs{max_errors} ? delete($attrs{max_errors}) : scalar(@errors);
  my $divider = $max_errors > 1 ? '<li>' : '';
  my $errors = join '', map { "${divider}$_" } @errors[0..($max_errors-1)];

  return $self->tag($c, 'div', \%attrs, $errors);
}

sub model_errors_for {
   my ($self, $c, $attribute, %attrs) = @_;
   my $model = $c->stash->{'valiant.view.form.model'};

   if(my @errors = $model->errors->full_messages_for($attribute)) {
     my $max_errors = $attrs{max_errors} ? delete($attrs{max_errors}) : scalar(@errors);
     my $errors = join ', ', @errors[0..($max_errors-1)];
     my $attrs =  join ' ', map { "$_='$attrs{$_}'"} keys %attrs;
     return b("<div $attrs/>$errors</div>");
   } else {
     return '';
   }
}

sub model_errors {
  my ($self, $c, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  my $model = $c->stash->{'valiant.view.form.model'};
  my @errors = $model->errors->model_errors;

  if($model->has_errors && !@errors) {
    push @errors, delete $attrs{default_msg} if exists $attrs{default_msg};
  }

  return '' unless @errors;

  my $max_errors = $attrs{max_errors} ? delete($attrs{max_errors}) : scalar(@errors);
  my $divider = $max_errors > 1 ? '<li>' : '';
  my $errors = join '', map { "${divider}$_" } @errors[0..($max_errors-1)];

  return $self->tag($c, 'div', \%attrs, $errors);
}

sub human_model_name {
  my ($self, $c, @proto) = @_;
  return $c->stash->{'valiant.view.form.model'}->model_name->human;
}

sub model {
  my ($self, $c,) = @_;
  return  $c->stash->{'valiant.view.form.model'};
}

sub fields_for {
  my ($self, $c, $related, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  my $model = $c->stash->{'valiant.view.form.model'};
  my @namespace = @{$c->stash->{'valiant.view.form.namespace'}||[]};


  # This next bit is DBIC specific.   It would be more ideal to isolate this
  # behind an abtraction.
  die "No relation '$related' for model $model" unless $model->has_relationship($related);

  my $rel_data = $model->relationship_info($related);
  my $rel_type = $rel_data->{attrs}{accessor};

  if( $rel_type eq 'single') {
    my $result = $model->related_resultset($related)->first;
    return '' unless $result;  # not sure this is correct

    local $c->stash->{'valiant.view.form.model'} = $result;
    local $c->stash->{'valiant.view.form.namespace'} = [@namespace, $related];

    my $content_expanded = $content->();

    if($result->in_storage) {
      my @primary_columns = $result->result_source->primary_columns;
      foreach my $primary_column (@primary_columns) {
        next unless my $value = $result->get_column($primary_column);
        $content_expanded .= $self->hidden($c, $primary_column);
      }
    }
    return b $content_expanded;
  }
}
    
__PACKAGE__->meta->make_immutable;






__END__


      %= input_group 'address', begin
        <div class='form-group'>
          %= label current_field
          %= input current_field, +{ class=>'form-control' }
          %= errors_for current_field
        </div>        
      %= end

    %= input_group 'address', +{ class=>'form-control', div_attrs=>{ class=>'form-group'}  }


sub model_errors_for {
   my ($self, $c, $attribute, %attrs) = @_;
   my $model = $c->stash->{'valiant.view.form.model'};

   if(my @errors = $model->errors->full_messages_for($attribute)) {
     my $max_errors = $attrs{max_errors} ? delete($attrs{max_errors}) : scalar(@errors);
     my $errors = join ', ', @errors[0..($max_errors-1)];
     my $attrs =  join ' ', map { "$_='$attrs{$_}'"} keys %attrs;
     return b("<div $attrs/>$errors</div>");
   } else {
     return '';
   }
}
sub form_tag {
  my ($self, $c, $url, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);
  
  # $attr{action} ||= $c->uri_for()...

  my $out = $self->tag($c, 'form', \%attrs);
  if($content) {
    $out .= $content->();
    $out .= "</form>";
    $out = b $out;
  }

  return $out;
}








sub form_for {
  my ($self, $c, $model, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);

  if($model->can('in_storage') && $model->in_storage) {
    my $value = $model->model_name->param_key . '_edit';
    $attrs{id} ||= $value;
    $attrs{class} ||= $value;
  } else {
    my $value = $model->model_name->param_key . '_new';
    $attrs{id} ||= $value;
    $attrs{class} ||= $value;
  }
  $attrs{method} ||= 'POST';

  return $self->form_tag($c, '', %attrs, $content);
}


sub fields_for {
  my ($self, $c, $model, @proto) = @_;
  my ($content, %attrs) = _parse_proto(@proto);

  local $c->stash->{'valiant.view.form.model'} = $model;
  local $c->stash->{'valiant.view.form.namespace'}[0] = $model->model_name->param_key;

  $attrs{id} ||= $model->model_name->param_key;
  $attrs{method} ||= 'POST';

  my $attrs = _stringify_attrs(%attrs);



}





sub text_field_tag {
  my ($self, $c, $name, $value, $options) = @_;
  $options ||= +{};
  $options->{type} ||= 'text';
  $options->{name} ||= $name;
  $options->{id} ||= do { $name=~tr/\./_/; $name };
  $options->{value} ||= $value;
  return $self->tag($c, 'input', $options);
}

1;
