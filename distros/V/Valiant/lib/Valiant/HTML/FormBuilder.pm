package Valiant::HTML::FormBuilder;

use Moo;
use Scalar::Util (); 
use Module::Runtime ();
use Valiant::I18N;

with 'Valiant::Naming';
# Non public helper methods

sub set_unless_defined {
  my ($key, $options, $value) = @_;
  return if exists($options->{$key}) && defined($options->{$key});
  $options->{$key} = $value;
}

has model => ( is => 'ro', required => 1);
has name => ( is => 'ro', required => 1 );
has options => ( is => 'ro', required => 1, default => sub { +{} } );  
has index => ( is => 'ro', required => 0, predicate => 'has_index' );
has namespace => ( is => 'ro', required => 0, predicate => 'has_namespace' );
has tag_helpers => (
  is => 'ro', 
  required => 1,
  handles => [qw/view/],
  builder => '_build_tag_helpers',
  lazy => 1,
);

  sub _build_tag_helpers {
    my ($self) = @_;
    my %args = ();
    $args{view} = exists($self->options->{view}) ? 
      $self->options->{view} :
        Module::Runtime::use_module('Valiant::HTML::Util::View')->new;
    return Module::Runtime::use_module('Valiant::HTML::Util::Form')->new(%args);
  }

has theme => ( is => 'ro', required => 1, lazy =>1, builder => '_build_theme' );

  sub _build_theme {
    my ($self) = @_;
    my $theme = $self->can('default_theme') ? $self->default_theme : +{};
    my $view_theme = $self->view->can('formbuilder_theme') ? $self->view->formbuilder_theme : +{};
    return +{ %$theme, %$view_theme };
  }

has _nested_child_index => (is=>'rw', init_arg=>undef, required=>1, default=>sub { +{} });

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $options = $class->$orig(@args);

  $options->{index} = $options->{child_index} if !exists($options->{index}) && exists($options->{child_index});
  $options->{options} = exists($options->{options}) ? +{%$options, %{$options->{options}}} : $options;

  return $options;
};

sub form_action { shift->options->{html}{action} }
sub form_method { shift->options->{html}{method} }
sub form_enctype { shift->options->{html}{method} }
sub csrf_token { shift->options->{html}{data}{csrf_token} }

sub allow_method_names_outside_object {
  return exists(shift->options->{allow_method_names_outside_object})
  ? shift->options->{allow_method_names_outside_object}
  : 1;
}

sub DEFAULT_MODEL_ERROR_MSG_ON_FIELD_ERRORS { return 'Your form has errors' }
sub DEFAULT_MODEL_ERROR_TAG_ON_FIELD_ERRORS { return 'invalid_form' }
sub DEFAULT_COLLECTION_CHECKBOX_BUILDER { return 'Valiant::HTML::FormBuilder::Checkbox' }
sub DEFAULT_COLLECTION_RADIO_BUTTON_BUILDER { return 'Valiant::HTML::FormBuilder::RadioButton' }

sub id { return shift->options->{id} }

sub nested_child_index {
  my ($self, $attribute) = @_;
  if(exists($self->_nested_child_index->{$attribute})) {
    return ++$self->_nested_child_index->{$attribute};
  } else {
    return $self->_nested_child_index->{$attribute} = 0
  }
}

sub tag_id_for_attribute {
  my ($self, $attribute, @extra) = @_;
  my $opts = +{};
  $opts->{namespace} = $self->namespace if $self->has_namespace;
  $opts->{index} = $self->index if $self->has_index;

  return $self->tag_helpers->field_id($self->name, $attribute, $opts, @extra);
}

# $self->tag_name_for_attribute($attribute, +{ multiple=>1 });
sub tag_name_for_attribute {
  my ($self, $attribute, $opts, @extra) = @_;
  $opts = +{} unless defined $opts;
  $opts->{namespace} = $self->namespace if $self->has_namespace;
  $opts->{index} = $self->index if $self->has_index;

  return $self->tag_helpers->field_name($self->name, $attribute, $opts, @extra);
}

sub tag_value_for_attribute {
  my ($self, $attribute) = @_;
  return $self->tag_helpers->field_value($self->model, $attribute);
}

sub tag_errors_for_attribute {
  my ($self, $attribute) = @_;
  return $self->tag_helpers->field_errors($self->model, $attribute);
}

sub human_name_for_attribute {
  my ($self, $attribute) = @_;
  return $self->model->can('human_attribute_name') ?
    $self->model->human_attribute_name($attribute) :
      $self->tag_helpers->_humanize($attribute);
}

sub human_name_for_label {
  my ($self, $label) = @_;
  return $self->model->can('human_label_name') ?
    $self->model->human_label_name($label) :
      $self->tag_helpers->_humanize($label);
}

sub attribute_has_errors {
  my ($self, $attribute) = @_;
  return $self->model->can('errors') && $self->model->errors->where($attribute) ? 1:0;
}

# $fb->has_errors()
# $fb->model_errors($content)
# $fb->error_for_form(\&template)

sub form_has_errors {
  my ($self) = shift;
  return '' unless $self->model->has_errors # There is at least one field with an error
    || $self->_get_model_errors; # There is at least one error on the model itself

  my $options = ref($_[0]) eq 'HASH' ? shift : +{};
  my $content = @_ ? shift : _t('invalid_form'); 

  return $content->($self->view, $self, $self->model) if ref($content) eq 'CODE';

  $options = $self->merge_theme_field_opts('model_errors', undef, $options);
  $content = $self->model->i18n->translate(
    $content,
    scope=>'valiant.html.errors.messages',
    default=>[ _t("errors.messages.invalid_form"), _t("messages.invalid_form") ],
  ) if $self->model->i18n->is_i18n_tag($content);

  return $self->tag_helpers->tags->div($options, $content);
}

sub _default_form_has_errors_content {
  my ($self) = shift;
  my $message = $self->_generate_default_model_error; 
  return sub {
    my ($view, $self) = @_;
    return $self->tag_helpers->div($message);
  }
}

# Public methods for HTML generation

# $fb->model_errors()
# $fb->model_errors(\%options)
# $fb->model_errors(\%options, \&template)
# $fb->model_errors(\&template)

sub model_errors {
  my ($self) = shift;
  my ($options, $content) = (+{}, undef);

  while(my $arg = shift) {
    $options = $arg if (ref($arg)||'') eq 'HASH';
    $content = $arg if (ref($arg)||'') eq 'CODE';
  }
  $options = $self->merge_theme_field_opts('model_errors', undef, $options);

  my @errors = $self->_get_model_errors;
  my $show_message_on_field_errors = delete $options->{show_message_on_field_errors};

  if(
    $self->_model_has_errors &&     # We have errors
    # !scalar(@errors) &&             # but no model errorsS_VIEW
    ($show_message_on_field_errors)   # And a default model error
  ) {
    unshift @errors, $self->_generate_default_model_error($show_message_on_field_errors);
  }
  return '' unless @errors;

  my $max_errors = exists($options->{max_errors}) ? delete($options->{max_errors}) : undef;
  @errors = @errors[0..($max_errors-1)] if($max_errors);
  $content = $self->_default_model_errors_content($options) unless defined($content);

  my $error_content = $content->(@errors);
  return $error_content;
}

sub _model_has_errors {
  my ($self) = @_;
  return $self->model->has_errors if $self->model->can('has_errors');
  return 0;
}
sub _get_model_errors {
  my ($self) = @_;
  return my @errors = $self->model->errors->model_messages if $self->model->can('errors');
  return ();
}

sub _generate_default_model_error {
  my ($self, $tag) = @_;
  $tag = _t('invalid_form') if $tag eq '1';
  return $tag unless ref $tag;
  return $self->DEFAULT_MODEL_ERROR_MSG_ON_FIELD_ERRORS unless $self->model->can('i18n');
  return $self->model->i18n->translate(
      $tag,
      scope=>'valiant.html.errors.messages',
      default=>[ _t("errors.messages.$tag"), _t("messages.$tag") ],
    );
}

sub _default_model_errors_content {
  my ($self, $options) = @_;
  return sub {
    my (@errors) = @_;
    if( scalar(@errors) == 1 ) {
      return $self->tag_helpers->content_tag('div', $errors[0], $options);
       return $self->tag_helpers->content_tag('div', $errors[0], $options);
    } else {
       return $self->tag_helpers->content_tag('ol', $options, sub { map { $self->tag_helpers->content_tag('li', $_) } @errors });
    }
  }
}

sub merge_theme {
  my ($self, %theme) = @_;
  $self->theme(+{ %{$self->theme}, %theme });
}

sub merge_theme_field_opts {
  my ($self, $tag_type, $attribute, $existing) = @_;
  my $theme = $self->theme;

  if(exists $theme->{$tag_type}) {
    $existing = +{ %{$theme->{$tag_type}}, %$existing };
  }
  if($attribute && exists $theme->{attributes}{$attribute}{$tag_type}) {
    $existing = +{ %{$theme->{attributes}{$attribute}{$tag_type}}, %$existing };
  }
  return $existing;
}

# $fb->label($attribute)
# $fb->label($attribute, \%options)
# $fb->label($attribute, $content)
# $fb->label($attribute, \%options, $content) 
# $fb->label($attribute, \&content);   sub content { my ($translated_attribute) = @_;  ... }
# $fb->label($attribute, \%options, \&content);   sub content { my ( $translated_attribute) = @_;  ... }

sub label {
  my ($self, $attribute) = (shift, shift);
  my ($options, $content) = (+{}, (my $translated_attribute = $self->human_name_for_attribute($attribute)));
  while(my $arg = shift) {
    $options = $arg if (ref($arg)||'') eq 'HASH';
    $content = $arg if (ref($arg)||'') eq 'CODE';
    $content = $arg if (ref(\$arg)||'') eq 'SCALAR';
  }

  set_unless_defined(for => $options, $self->tag_id_for_attribute($attribute));

  $options = $self->merge_theme_field_opts(label=>$attribute, $options);

  my $label ='';
  if((ref($content)||'') eq 'CODE') {
    $label = $self->tag_helpers->label_tag($attribute, $self->process_options($attribute, $options), sub { $content->($translated_attribute) } );
  } else {
    $label = $self->tag_helpers->label_tag($attribute, $content, $self->process_options($attribute, $options));
  }
  return $label;
}

# $fb->errors_for($attribute)
# $fb->errors_for($attribute, \%options)
# $fb->errors_for($attribute, \%options, \&template)
# $fb->errors_for($attribute, \&template)

sub errors_for {
  my ($self, $attribute) = (shift, shift);
  my ($options, $content) = (+{}, undef);
  while(my $arg = shift) {
    $options = $arg if (ref($arg)||'') eq 'HASH';
    $content = $arg if (ref($arg)||'') eq 'CODE';
  }
  $options = $self->merge_theme_field_opts(errors_for=>$attribute, $options);

  return '' unless $self->model->can('errors');

  my @errors = $self->tag_errors_for_attribute($attribute);
  #my @errors = $self->model->errors->full_messages_for($attribute);
  return '' unless scalar(@errors);
  
  my $max_errors = exists($options->{max_errors}) ? delete($options->{max_errors}) : undef;
  @errors = @errors[0..($max_errors-1)] if($max_errors);
  $options = $self->process_options($attribute, $options);
  $content = $self->_default_errors_for_content($options) unless defined($content);

  my $response = $self->view->safe('');
  $response = $content->(@errors) if @errors;

  return $response;
}

sub _default_errors_for_content {
  my ($self, $options) = @_;
  return sub {
    my (@errors) = @_;

    if( scalar(@errors) == 1 ) {
       return $self->tag_helpers->content_tag('div', $errors[0], {%$options, data=>{error_param=>1}});
    } else {
      my @li_content = map { $self->tag_helpers->content_tag('li', $_, {data=>{error_param=>1}}) } @errors;
      return $self->tag_helpers->content_tag('ol', $self->view->safe_concat(@li_content), $options);
    }
  }
}

sub process_options {
  my ($self, $attribute, $options) = @_;

  if($options->{data}{remote}) {
    my $url = $self->form_action->clone;
    my $replace = exists($options->{data}{replace})
      ? $options->{data}{replace}
      : '#'.$options->{id};
    $url->query_param(replace=>$replace);

    $options->{data}{url} = $url;
    $options->{data}{method} ||= $self->form_method;
    $options->{data}{params} = $self->view->uri_escape(csrf_token => $self->csrf_token);
  }

  if( ($self->attribute_has_errors($attribute)) && (my $errors_attrs = delete $options->{errors_attrs})) {
    foreach my $key(keys %$errors_attrs) {
      if(exists $options->{$key}) {
        if( ($key eq 'data') || ($key eq 'aria') ) {
          $options->{$key} = +{ %{$options->{$key}}, %{$errors_attrs->{$key}} };
        } elsif($key eq 'class') {
          $options->{$key} .= " $errors_attrs->{$key}";
        } else {
          $options->{$key} .= $errors_attrs->{$key};
        }
      } else {
        $options->{$key} = $errors_attrs->{$key};
      }
    }
  }
  return $options;
}

# $fb->input($attribute, \%options)
# $fb->input($attribute)

sub input {
  my ($self, $attribute, $options) = (shift, shift, (@_ ? shift : +{}));
  $options = $self->merge_theme_field_opts($options->{type} || 'input', $attribute, $options);

  my %flags = ();
  $flags{force_validity} = delete $options->{force_validity} if exists $options->{force_validity};
  $flags{errors_classes} = delete $options->{errors_classes} if exists $options->{errors_classes};

  my $response = $self->_input($attribute, $options, \%flags);
  return $response;
}

sub _input {
  my ($self, $attribute, $html_attrs, $flags) = @_;
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
  my $valid = 1;
  if(exists($flags->{force_validity})) {
    $valid = $flags->{force_validity};
  } elsif($model->can('errors')) {
    $valid = $model->errors->where($attribute) ? 0 : 1;
  }

  $html_attrs->{class} = join(' ', (grep { defined $_ } $html_attrs->{class}, $flags->{errors_classes}))
    if $flags->{errors_classes} && !$valid;

  set_unless_defined(type => $html_attrs, 'text');
  set_unless_defined(id => $html_attrs, $self->tag_id_for_attribute($attribute));
  set_unless_defined(name => $html_attrs, $self->tag_name_for_attribute($attribute));
  $html_attrs->{value} = $self->tag_value_for_attribute($attribute) unless defined($html_attrs->{value});
  $html_attrs = $self->process_options($attribute, $html_attrs);

  return my $response_obj = $self->tag_helpers->input_tag($attribute, $html_attrs);
}

sub password {
  my ($self, $attribute, $options) = (shift, shift, (@_ ? shift : +{}));
  $options->{type} = 'password';
  $options->{value} = '' unless exists($options->{value});
  return $self->input($attribute, $options);
}

sub hidden {
  my ($self, $attribute, $options) = (shift, shift, (@_ ? shift : +{}));
  $options->{type} = 'hidden';
  return $self->input($attribute, $options);
}

sub text_area {
  my ($self, $attribute, $options) = (shift, shift, (@_ ? shift : +{}));
  $options = $self->merge_theme_field_opts('text_area', $attribute, $options);
  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
  
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes && $self->model->can('errors') && $self->model->errors->where($attribute);

  set_unless_defined(id => $options, $self->tag_id_for_attribute($attribute));
  return $self->tag_helpers->text_area_tag(
    $self->tag_name_for_attribute($attribute),
    $self->tag_value_for_attribute($attribute),
    $self->process_options($attribute, $options),
  );
}

sub checkbox {
  my ($self, $attribute) = (shift, shift);
  my $options = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  $options = $self->merge_theme_field_opts('checkbox', $attribute, $options);

  my $checked_value = @_ ? shift : 1;
  my $unchecked_value = @_ ? shift : 0;
  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
  my $show_hidden_unchecked = exists($options->{include_hidden}) ? delete($options->{include_hidden}) : 1;
  my $name = $self->tag_name_for_attribute($attribute);

  my $checked = 0;
  if(exists($options->{checked})) {
    $checked = delete $options->{checked};
  } else {
    $checked = $self->tag_value_for_attribute($attribute) ? 1:0;
  }

  $options->{type} = 'checkbox';
  $options->{value} = $checked_value unless exists($options->{value});
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes && $self->model->can('errors') && $self->model->errors->where($attribute);

  set_unless_defined(id => $options, $self->tag_id_for_attribute($attribute));

  my $checkbox = $self->tag_helpers->checkbox_tag(
    $name,
    $checked_value,
    $checked,
    $self->process_options($attribute, $options),
  );

  if($show_hidden_unchecked) {
    my $hidden_name = exists($options->{name}) ? $options->{name} : $name;
    my $hidden_checkbox = $self->tag_helpers->tag('input', +{type=>'hidden', name=>$hidden_name, value=>$unchecked_value});
    $checkbox = $self->tag_helpers->join_tags($hidden_checkbox, $checkbox);
  }

  return $checkbox;
}

#radio_button(object_name, method, tag_value, options = {})
sub radio_button {
  my ($self, $attribute) = (shift, shift);
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $options = $self->merge_theme_field_opts('radio_button', $attribute, $options);

  my $value = @_ ? shift : undef;

  $options->{type} = 'radio';
  $options->{value} = $value unless exists($options->{value});
  $options->{checked} = do { $self->tag_value_for_attribute($attribute) eq $value ? 1:0 } unless exists($options->{checked});
  $options->{id} = $self->tag_id_for_attribute($attribute, $value) unless exists($options->{id});

  return $self->input($attribute, $self->process_options($attribute, $options));
}
 
sub date_field {
  my ($self, $attribute, $options) = (@_, +{});
  my $value = $self->tag_value_for_attribute($attribute);
  $options = $self->merge_theme_field_opts('date_field', $attribute, $options);
  $options->{type} = 'date';
  $options->{value} ||= Scalar::Util::blessed($value) ? $value->ymd : $value;
  $options->{min} = $options->{min}->ymd if exists($options->{min}) && Scalar::Util::blessed($options->{min});
  $options->{max} = $options->{max}->ymd if exists($options->{max}) && Scalar::Util::blessed($options->{max});

  return $self->input($attribute, $options);
}

sub datetime_local_field {
  my ($self, $attribute, $options) = (@_, +{});
  my $value = $self->tag_value_for_attribute($attribute);
  $options = $self->merge_theme_field_opts('datetime_local_field', $attribute, $options);

  $options->{type} = 'datetime-local';
  $options->{value} ||= Scalar::Util::blessed($value) ? $value->strftime('%Y-%m-%dT%T') : $value;
  $options->{min} = $options->{min}->strftime('%Y-%m-%dT%T') if exists($options->{min}) && Scalar::Util::blessed($options->{min});
  $options->{max} = $options->{max}->strftime('%Y-%m-%dT%T') if exists($options->{max}) && Scalar::Util::blessed($options->{max});

  return $self->input($attribute, $options);
}

sub time_field {
  my ($self, $attribute, $options) = (@_, +{});
  my $value = $self->tag_value_for_attribute($attribute);
  $options = $self->merge_theme_field_opts('time_field', $attribute, $options);
  my $format = (exists($options->{include_seconds}) && !delete($options->{include_seconds})) ? '%H:%M' : '%T.%3N';

  $options->{type} = 'time';
  $options->{value} ||= Scalar::Util::blessed($value) ? $value->strftime($format) : $value;

  return $self->input($attribute, $options);
}

sub submit {
  my ($self) = shift;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  my $value = @_ ? shift(@_) : $self->_submit_default_value;
  $options = $self->merge_theme_field_opts('submit', undef, $options);

  return $self->tag_helpers->submit_tag($value, $options);
}

sub _submit_default_value {
  my $self = shift;
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
  my $key = $model->can('in_storage') ? ( $model->in_storage ? 'update':'create' ) : 'submit';
  my $model_placeholder = $self->tag_helpers->_humanize($self->name);

  my @defaults = ();

  push @defaults, _t "formbuilder.submit.@{[ $self->name ]}.${key}";
  push @defaults, _t "formbuilder.submit.${key}";
  push @defaults, "@{[ $self->tag_helpers->_humanize($key) ]} ${model_placeholder}";

  return $self->model->i18n->translate(
      shift(@defaults),
      model=>$model_placeholder,
      default=>\@defaults,
    );
}

# ->button($name, \%attrs, \&block)
# ->button($name, \%attrs, $content)
# ->button($name, \&block)
# ->button($name, $content)

sub button {
  my $self = shift;
  my $attribute = shift;
  my $attrs = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  my $content = shift;

  $attrs->{type} = 'submit' unless exists($attrs->{type});
  $attrs->{value} = $self->tag_value_for_attribute($attribute) unless exists($attrs->{value});
  $attrs->{name} = $self->tag_name_for_attribute($attribute) unless exists($attrs->{name});
  $attrs->{id} = $self->tag_id_for_attribute($attribute) unless exists($attrs->{id});
  $attrs = $self->merge_theme_field_opts('button', $attribute, $attrs);

  return ref($content) ?
    $self->tag_helpers->button_tag($attrs, $content) :
      $self->tag_helpers->button_tag($content, $self->process_options($attribute, $attrs));
}

sub legend {
  my ($self) = shift;
  my $value = my $default_value = $self->_legend_default_value;
  my $options = +{};

  $value = pop(@_) if (ref($_[-1])||'') eq 'CODE';
  $options = pop(@_) if (ref($_[-1])||'') eq 'HASH';
  $value = shift(@_) if @_;
  $value = $value->($default_value) if ((ref($value)||'') eq 'CODE');

  return $self->tag_helpers->legend_tag($value, $options);
}

sub legend_for {
  my $self = shift;
  my $attribute = shift;
  my $attrs = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  my $content = @_ ? shift(@_) : $self->human_name_for_attribute($attribute);

  $attrs->{id} = "@{[ $self->tag_id_for_attribute($attribute) ]}_legend" unless exists($attrs->{id});
  $attrs = $self->merge_theme_field_opts('legend_for', $attribute, $attrs);

  return $self->tag_helpers->legend_tag($attrs, $content);
}

sub _legend_default_value {
  my $self = shift;
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
  my $key = $model->can('in_storage') ? ( $model->in_storage ? 'update':'create' ) : 'new';
  my $model_placeholder = $self->tag_helpers->_humanize($self->name);

  my @defaults = ();

  return "@{[ $self->tag_helpers->_humanize($key) ]} ${model_placeholder}" unless $self->model->can('i18n');

  push @defaults, _t "formbuilder.legend.@{[ $self->name ]}.${key}";
  push @defaults, _t "formbuilder.legend.${key}";
  push @defaults, "@{[ $self->tag_helpers->_humanize($key) ]} ${model_placeholder}";

  return $self->model->i18n->translate(
      shift(@defaults),
      model=>$model_placeholder,
      default=>\@defaults,
    );
}

# fields_for($related_attribute, ?\%options?, \&block)
sub fields_for {
  my ($self, $related_attribute) = (shift, shift);
  my $options = (ref($_[0])||'') eq 'HASH' ? shift(@_) : +{};
  my $codeblock = (ref($_[0])||'') eq 'CODE' ? shift(@_) : die "Missing required code block";
  my $finally_block = (ref($_[0])||'') eq 'CODE' ? shift(@_) : undef;

  $options->{builder} = $self->options->{builder} if !exists($options->{builder}) && !defined($options->{builder}) && defined($self->options->{builder});
  $options->{include_id} = $self->options->{include_id} if !exists($options->{include_id}) && !defined($options->{include_id}) && defined($self->options->{include_id});
  $options->{namespace} = $self->namespace if $self->has_namespace;
  $options->{parent_builder} = $self;

  my $related_record = $self->tag_value_for_attribute($related_attribute);
  my $name = "@{[ $self->name ]}.@{[ $related_attribute ]}";

  $related_record = $related_record->to_model if Scalar::Util::blessed($related_record) && $related_record->can('to_model');

  # Coerce an array into a collection.  Not sure if we want this here or not TBH...
  $related_record = $self->tag_helpers->array_to_collection(map { $_->can('to_model') ? $_->to_model : $_ } @$related_record)
    if (ref($related_record)||'') eq 'ARRAY';

  # Ok is the related record a collection or something else.
  if($related_record->can('next')) {
    my @output = ();
    my $explicit_child_index = exists($options->{child_index}) ? $options->{child_index} : undef;

    while(my $child_model = $related_record->next) {
      if(defined($explicit_child_index)) {
        $options->{child_index} = $options->{child_index}->($child_model) if ref() eq 'CODE';  # allow for callback version of this
      } else {
        $options->{child_index} = $self->nested_child_index($related_attribute); 
      }
      my $nested = $self->fields_for_nested_model("${name}[@{[ $options->{child_index} ]}]", $child_model, $options, $codeblock);
      push @output, $nested;
    }
    $related_record->reset if $related_record->can('reset');
    if($finally_block) {
      my $finally_model = $related_record->can('build') ? $related_record->build : die "Can't have a finally block if the collection doesn't support 'build'";
      if(defined($explicit_child_index)) {
        $options->{child_index} = $options->{child_index}->($finally_model) if ref() eq 'CODE';  # allow for callback version of this
      } else {
        $options->{child_index} = $self->nested_child_index($related_attribute); 
      }
      my $finally_content = $self->fields_for_nested_model("${name}[@{[ $options->{child_index} ]}]", $finally_model, $options, $finally_block);
      push @output, $finally_content;
    }
    return $self->tag_helpers->join_tags(@output);
  } else {
    return $self->fields_for_nested_model($name, $related_record, $options, $codeblock);
  }
}

sub fields_for_nested_model {
  my ($self, $name, $model, $options, $codeblock) = @_;
  my $emit_hidden_id = 0;
  $model = $model->to_model if $model->can('to_model');

  if($model->can('in_storage') && $model->in_storage) {
    $emit_hidden_id = exists($options->{include_id}) ? $options->{include_id} : 1;
  }

  return $self->tag_helpers->fields_for($name, $model, $options, sub {
    my $view = shift;
    my $fb = shift;
    my @output = $codeblock->($view, $fb, $model);
    if(@output && $emit_hidden_id && $model->can('primary_columns')) {
      foreach my $id_field ($model->primary_columns) {
        push @output, $fb->hidden($id_field); #TODO this cant be right...
      }
    }
    return $self->tag_helpers->join_tags(@output);
  });
}

sub select {
  my ($self, $attribute_proto) = (shift, shift);
  my $block = (ref($_[-1])||'') eq 'CODE' ? pop(@_) : undef;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $options = $self->merge_theme_field_opts('select', undef, $options);

  my ($attribute) = (ref($attribute_proto)||'') eq 'HASH' ? %$attribute_proto : $attribute_proto;
  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef; 
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes && $self->model->can('errors') && $self->model->errors->where($attribute);

  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
  my $include_hidden = exists($options->{include_hidden}) ? $options->{include_hidden} : 1;
  my $unselected_default = exists($options->{unselected_value}) ? delete($options->{unselected_value}) : undef;


  my @selected = ();
  my $name = '';
  if( (ref($attribute_proto)||'') eq 'HASH') {
    $options->{multiple} = 1 unless exists($options->{multiple});
    $options->{include_hidden} = 0; # Avoid adding two
    my ($bridge, $value_method) = %$attribute_proto;
    my $collection = $model->$bridge;
    $collection = $self->tag_helpers->array_to_collection(map { $_->can('to_model') ? $_->to_model : $_ } @$collection)
      if (ref($collection)||'') eq 'ARRAY';

    while(my $item = $collection->next) {
      push @selected, $item->$value_method;
    }
    $name = $self->tag_name_for_attribute($bridge, +{multiple=>1}) . ".$value_method";
    $options->{id} = $self->tag_id_for_attribute($bridge) . "_$value_method" unless exists $options->{id};
  } else {
    my $tag_value_proto = $self->tag_value_for_attribute($attribute_proto);
    if( (ref($tag_value_proto)||'') eq 'ARRAY') {
      @selected = @$tag_value_proto;
      $options->{multiple} = 1;
      $include_hidden = 1;
    } else {
      @selected = ($tag_value_proto);
    }
    $name = $self->tag_name_for_attribute($attribute_proto);
    $options->{id} = $self->tag_id_for_attribute($attribute_proto);
  }

  my $options_tags = '';
  if(!$block) {
    my $option_tags_proto = @_ ? shift : ();
    my @disabled = ( @{delete($options->{disabled})||[]});
    @selected = @{ delete($options->{selected})||[]} if exists($options->{selected});
    $options_tags = $self->tag_helpers->options_for_select($option_tags_proto, +{
      selected => \@selected,
      disabled => \@disabled,
    });
  } else {
    $options_tags = $self->tag_helpers->join_tags($block->($model, $attribute_proto, @selected));
  }

  $options->{include_hidden} = 0 if $options->{multiple};
  my $select_tag = $self->tag_helpers->select_tag($name, $options_tags, $options);
  if($include_hidden && $options->{multiple}) {
    if(ref($attribute_proto)) {
      my ($bridge, $value_method) = %$attribute_proto;
      my $hidden = $self->hidden("${bridge}[0]._nop", +{value=>1, id=>$options->{id}.'_hidden'});
      $select_tag = $self->tag_helpers->join_tags($hidden, $select_tag);
    } elsif(defined $unselected_default) {
      my $hidden = $self->hidden("${attribute_proto}[0]", +{value=>$unselected_default, id=>$options->{id}.'_hidden'});
      $select_tag = $self->tag_helpers->join_tags($hidden, $select_tag);
    }
  }
  return $select_tag;
}

#collection_select(object, method, collection, value_method, text_method, options = {}, html_options = {})
sub collection_select {
  my ($self, $method_proto) = (shift, shift);
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $options = $self->merge_theme_field_opts('collection_select', undef, $options);

  my ($collection, $value_method, $label_method) = @_;

  # If the collection of options is not provided then we need to figure out what it is
  if(!defined $collection) {
    my ($options_model, $options_method) = ($model, $method_proto);
    if(ref $method_proto) {
      my $bridge; ($bridge, $options_method) = %$method_proto;
      if($model->can('related_model')) {
        $options_model = $model->related_model($bridge);
      } else {
        my $local_model = $model->$bridge;
        if($local_model->can('next')) {
          $local_model = $local_model->next;
        }
        $options_model = $local_model;
      }
    }
    ($collection, $label_method, $value_method) = $options_model->select_options_for($options_method, %$options);
  }
  $collection = $model->$collection if (ref(\$collection)||'') eq 'SCALAR'; 
  $value_method = 'value' unless defined($value_method);
  $label_method = 'label' unless defined($label_method);

  $collection = $model->$collection if (ref(\$collection)||'') eq 'SCALAR'; 

  my $include_hidden = exists($options->{include_hidden}) ? delete($options->{include_hidden}) : 1;
  my (@selected, $name, $id) = ();
  if(ref $method_proto) {
    $options->{multiple} = 1 unless exists($options->{multiple});
    $options->{include_hidden} = 0 unless exists($options->{include_hidden}); # Avoid adding two
    my ($bridge, $value_method) = %$method_proto;
    my $collection = $model->$bridge;
    $collection = $self->tag_helpers->array_to_collection(map { $_->can('to_model') ? $_->to_model : $_ } @$collection)
      if (ref($collection)||'') eq 'ARRAY';

    while(my $item = $collection->next) {
      push @selected, $item->$value_method;
    }
    $name = $self->tag_name_for_attribute($bridge, +{multiple=>1}) . ".$value_method";
    $options->{id} = $self->tag_id_for_attribute($bridge) . "_$value_method" unless exists $options->{id};
  } else {
    my $value = $self->tag_value_for_attribute($method_proto);
    my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
    $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
      if $model->can('errors') && $model->errors->where($method_proto);

    if((ref($value)||'') eq 'ARRAY') {
      @selected = @$value;
      $options->{multiple} = 1 unless exists($options->{multiple});
    } elsif(defined($value)) {
      @selected = ($value);
    } else {
      @selected = ();
    }

    $name = $self->tag_name_for_attribute($method_proto);
    $options->{id} = $id = $self->tag_id_for_attribute($method_proto);
  }

  $collection = $self->tag_helpers->array_to_collection(@$collection)
    if (ref($collection)||'') eq 'ARRAY';

  my @disabled = ( @{delete($options->{disabled})||[]});
  @selected = @{ delete($options->{selected})||[]} if exists($options->{selected});
  my $select_tag = $self->tag_helpers->select_tag(
    $name,
    $self->tag_helpers->options_from_collection_for_select($collection, $value_method, $label_method, +{
      selected => \@selected,
      disabled => \@disabled,
    }),
    $options);

  if($include_hidden && ref($method_proto)) {
    my ($bridge, $value_method) = %$method_proto;
    my $hidden = $self->hidden("${bridge}[0]._nop", +{value=>1, id=>$options->{id}.'_hidden'});
    $select_tag = $self->tag_helpers->join_tags($hidden, $select_tag);    
  }

  return $select_tag;
}

sub default_collection_checkbox_include_hidden { return 1 }

# $fb->collection_checkbox({person_roles => role_id}, $roles_rs, $value_method, $text_method, \%options, \&block);
# $fb->collection_checkbox({person_roles => role_id}, $roles_rs, $value_method, $text_method, \%options, \&block);
sub collection_checkbox {
  my ($self, $attribute_spec) = (shift, shift);
  my $codeblock = (ref($_[-1])||'') eq 'CODE' ? pop(@_) : undef;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $options = $self->merge_theme_field_opts('collection_checkbox', undef, $options);
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;

  my ($collection, $value_method, $label_method) = @_;
  if(!defined $collection) {
    if(ref $attribute_spec) {
      my ($bridge, $method) = %$attribute_spec;
      if($model->can('related_model')) {
        ($collection, $label_method, $value_method) = $model->related_model($bridge)->checkbox_rs_for($method, %$options);
      } else {
        my $local_model = $model->$bridge;
        if($local_model->can('next')) {
          $local_model = $local_model->next;
        }
        ($collection, $label_method, $value_method) = $local_model->checkbox_rs_for($method, %$options);
      }
    } else {
      ($collection, $label_method, $value_method) = $model->checkbox_rs_for($attribute_spec, %$options);
    }
  }

  $collection = $model->$collection if (ref(\$collection)||'') eq 'SCALAR'; 
  $value_method = 'value' unless defined($value_method);
  $label_method = 'label' unless defined($label_method);

  my $include_hidden = exists($options->{include_hidden}) ? delete($options->{include_hidden}) : $self->default_collection_checkbox_include_hidden;
  my $container_tag = exists($options->{container_tag}) ? delete($options->{container_tag}) : 'div';

  # It's either +{ person_roles => role_id } or roles
  my ($attribute, $attribute_value_method, $is_spec_attribute) = ();
  if( (ref($attribute_spec)||'') eq 'HASH' ) {
    ($attribute, $attribute_value_method) = (%{ $attribute_spec });
    $is_spec_attribute = 1;
  } else {
    $attribute = $attribute_spec;
    $attribute_value_method = $value_method;
  }

  $codeblock = $self->_default_collection_checkbox_content unless defined($codeblock);

  my @checked_values = ();
  my $value_collection = $self->tag_value_for_attribute($attribute);
  $value_collection = $self->tag_helpers->array_to_collection(map { Scalar::Util::blessed($_) && $_->can('to_model') ? $_->to_model : $_ } @$value_collection)
    if (ref($value_collection)||'') eq 'ARRAY';

  while(my $value_model = $value_collection->next) {
    if($value_model->can($attribute_value_method)) {
      push @checked_values, $value_model->$attribute_value_method
        unless $value_model->can('is_marked_for_deletion') && $value_model->is_marked_for_deletion;
    } elsif($value_model->isa('Valiant::HTML::Util::Collection::Item') && $value_model->can('value')) {
      push @checked_values, $value_model->value
        unless $value_model->can('is_marked_for_deletion') && $value_model->is_marked_for_deletion;
    }else {
      warn "Can't find value for " . ref($value_model) . " for $attribute";
    }
  }

  my @checkboxes = ();
  my $checkbox_builder_options = +{
    builder => (exists($options->{builder}) ? delete($options->{builder}) : $self->DEFAULT_COLLECTION_CHECKBOX_BUILDER),
    value_method => $value_method,
    label_method => $label_method,
    attribute_value_method => $attribute_value_method,
    parent_builder => $self,
    attribute => $attribute,
    tag_helpers => $self->tag_helpers,
    is_spec_attribute => $is_spec_attribute,
    errors => [$model->errors->where($attribute)],
  };
  $checkbox_builder_options->{namespace} = $self->namespace if $self->has_namespace;

  $collection = $model->$collection if (ref(\$collection)||'') eq 'SCALAR';
  $collection = $self->tag_helpers->array_to_collection(@$collection)
    if (ref($collection)||'') eq 'ARRAY';

  while (my $checkbox_model = $collection->next) {
    #my $index = $self->nested_child_index($attribute); 
    my $name = "@{[ $self->name ]}.${attribute}";
    my $checked = grep {
      my $current_value = $checkbox_model->can('read_attribute_for_html') ? 
        $checkbox_model->read_attribute_for_html($value_method)
          : $checkbox_model->$value_method;
      $_ eq $current_value;
    } @checked_values;

    if($include_hidden && !scalar(@checkboxes)) { # Add nop as first to handle empty list
      my $hidden_fb = $self->tag_helpers->_instantiate_builder($name, $value_collection->build, {%$checkbox_builder_options});
      my $hidden_value = $self->_collection_checkbox_hidden_value($attribute, $is_spec_attribute, $options); 
      push @checkboxes, $hidden_fb->hidden($name, +{name=>$name, id=>$self->tag_id_for_attribute($attribute).'_hidden', value=>$hidden_value});
    }

    #$checkbox_builder_options->{index} = $index;
    $checkbox_builder_options->{checked} = $checked;
    $checkbox_builder_options->{parent_builder} = $self;
    my $checkbox_fb = $self->tag_helpers->_instantiate_builder($name, $checkbox_model, $checkbox_builder_options);
    push @checkboxes, $codeblock->($checkbox_fb);
  }
  $collection->reset if $collection->can('reset');
  my $checkbox_content = $self->view->safe_concat(@checkboxes);

  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes && $model->can('errors') && $model->errors->where($attribute);

  return $self->tag_helpers->content_tag($container_tag, $checkbox_content, +{
    id => $self->tag_id_for_attribute($attribute),
    %$options,
  }); 
}

sub _collection_checkbox_hidden_value {
  my ($self, $attribute, $is_spec_attribute, $options) = @_;
  my $value = $is_spec_attribute ? '{"_nop":""}' : '';
  return $value;
}

sub _default_collection_checkbox_content {
  my ($self) = @_;
  return sub {
    my ($fb) = @_;
    my $label = $fb->label;
    my $checkbox = $fb->checkbox;
    return $self->tag_helpers->join_tags($label, $checkbox);
  };
}

sub default_collection_radio_buttons_include_hidden { return 1 }

sub collection_radio_buttons {
  my ($self, $attribute) = (shift, shift);
  my $codeblock = (ref($_[-1])||'') eq 'CODE' ? pop(@_) : undef;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $options = $self->merge_theme_field_opts('collection_radio_buttons', $attribute, $options);
 
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;

  my ($collection, $value_method, $label_method) = @_;
  if(!defined $collection) {
    if(ref $attribute) {
      my ($bridge, $method) = %$attribute;
      if($model->can('related_model')) {
        ($collection, $label_method, $value_method) = $model->related_model($bridge)->radio_button_rs_for($method, %$options);
      } else {
        my $local_model = $model->$bridge;
        if($local_model->can('next')) {
          $local_model = $local_model->next;
        }
        ($collection, $label_method, $value_method) = $local_model->radio_button_rs_for($method, %$options);
      }
    } else {
      ($collection, $label_method, $value_method) = $model->radio_button_rs_for($attribute, %$options);
    }
  }
  $value_method = 'value' unless defined($value_method);
  $label_method = 'label' unless defined($label_method);

  my $checked_value = exists($options->{checked_value}) ? delete($options->{checked_value}) : $self->tag_value_for_attribute($attribute);
  my $include_hidden = exists($options->{include_hidden}) ? delete($options->{include_hidden}) : $self->default_collection_radio_buttons_include_hidden;
  my $container_tag = exists($options->{container_tag}) ? delete($options->{container_tag}) : 'div';

  $codeblock = $self->_default_collection_radio_buttons_content unless defined($codeblock);

  my @radio_buttons = ();
  my $radio_buttons_builder_options = +{
    builder => (exists($options->{builder}) ? delete($options->{builder}) : $self->DEFAULT_COLLECTION_RADIO_BUTTON_BUILDER),
    value_method => $value_method,
    label_method => $label_method,
    checked_value => $checked_value,
    parent_builder => $self,
    attribute => $attribute,
    tag_helpers => $self->tag_helpers,
    errors => [$model->errors->where($attribute)],
  };
  $radio_buttons_builder_options->{namespace} = $self->namespace if $self->has_namespace;

  $collection = $model->$collection if (ref(\$collection)||'') eq 'SCALAR'; 
  while (my $radio_button_model = $collection->next) {
    my $name = "@{[ $self->name ]}.${attribute}";
    my $current_value = $radio_button_model->can('read_attribute_for_html') ?
      $radio_button_model->read_attribute_for_html($value_method) :
      $radio_button_model->$value_method;
    my $checked = $current_value eq ($checked_value||'') ? 1:0;

    if($include_hidden && !scalar(@radio_buttons) ) { # Add nop as first to handle empty list
      my $hidden_fb = $self->tag_helpers->_instantiate_builder($name, $model, $radio_buttons_builder_options);
      push @radio_buttons, $hidden_fb->hidden($name, +{name=>$name, id=>$self->tag_id_for_attribute($attribute).'_hidden', value=>''});
    }

    $radio_buttons_builder_options->{checked} = $checked;

    my $radio_button_fb = $self->tag_helpers->_instantiate_builder($name, $radio_button_model, $radio_buttons_builder_options);
    push @radio_buttons, $codeblock->($radio_button_fb);
  }
  $collection->reset if $collection->can('reset');
  my $radios = $self->view->safe_concat(@radio_buttons);

  my $errors_classes = exists($options->{errors_classes}) ? delete($options->{errors_classes}) : undef;
  $options->{class} = join(' ', (grep { defined $_ } $options->{class}, $errors_classes))
    if $errors_classes && $model->can('errors') && $model->errors->where($attribute);

  return $self->tag_helpers->content_tag($container_tag, $radios, +{
    id => $self->tag_id_for_attribute($attribute),
    %$options,
  }); 
}

sub _default_collection_radio_buttons_content {
  my ($self) = @_;
  return sub {
    my ($fb) = @_;
    my $label = $fb->label();
    my $checkbox = $fb->radio_button();
    return $self->tag_helpers->join_tags($label, $checkbox);
  };
}

sub radio_buttons {
  my ($self, $attribute) = (shift, shift);
  my $model = $self->model->can('to_model') ? $self->model->to_model : $self->model;
  my $codeblock = (ref($_[-1])||'') eq 'CODE' ? pop(@_) : undef;
  my $options = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $options = $self->merge_theme_field_opts('radio_buttons', $attribute, $options);

  # If args then its either a string to the model method or an arrayref of option
  if(@_) {
    my ($collection, $value_method, $label_method) = @_;
    $collection = do { my $method = shift; $model->$method } if (ref(\$_[0])||'') eq 'SCALAR';
    $collection = $self->tag_helpers->array_to_collection(@{shift(@_)}) if (ref($_[0])||'') eq 'ARRAY';
    $value_method = 'value' unless defined($value_method);
    $label_method = 'label' unless defined($label_method);
    return $self->collection_radio_buttons($attribute, $collection, $value_method, $label_method, $options, $codeblock);
  } else {
    # If we are here that means we are using the model method to get the collection
    my @buttons = $model->radio_buttons_for($attribute, %$options);
    my $collection = $self->tag_helpers->array_to_collection(@buttons);
    my $value_method = 'value';
    my $label_method = 'label';
    return $self->collection_radio_buttons($attribute, $collection, $value_method, $label_method, $options, $codeblock);
  }
}

# select collection needs work (with multiple)
# select with opt grounps needs to work
# ?? date and date time helpers (month field, weeks, etc) ??

1;

=head1 NAME

Valiant::HTML::FormBuilder - General HTML Forms

=head1 SYNOPSIS

Given a model with the correct API such as:

    package Local::Person;

    use Moo;
    use Valiant::Validations;

    has first_name => (is=>'ro');
    has last_name => (is=>'ro');

    validates ['first_name', 'last_name'] => (
      length => {
        maximum => 10,
        minimum => 3,
      }
    );

Wrap a formbuilder object around it and generate HTML form field controls:

    my $person = Local::Person->new(first_name=>'J', last_name=>'Napiorkowski');
    $person->validate;

    my $fb = Valiant::HTML::FormBuilder->new(
      model => $person,
      name => 'person'
    );

    print $fb->input('first_name');
    # <input id="person_first_name" name="person.first_name" type="text" value="J"/> 

    print $fb->errors_for('first_name');
    # <div>First Name is too short (minimum is 3 characters)</div> 

Although you can create a formbuilder instance directly as in the above example you might
find it easier to use the export helper method L<Valiant::HTML::Form/form_for> which encapsulates
the display logic needed for creating the C<form> tags.  This builder creates form tag elements
but not the actual C<form> open and close tags.  

=head1 DESCRIPTION

This class wraps an underlying data model and makes it easy to build HTML form elements based on
the state of that model.  Inspiration for this design come from Ruby on Rails Formbuilder as well
as similar designs in the Phoenix Framework.

You can subclass this to future customize how your form elements display as well as to add more complex
form elements for your templates.

Documentation here is basically API level, a more detailed tutorial will follow eventually but for now
you'll need to review the source, test cases and example application bundled with this distribution
for for hand holding.

Currently this is designed to work mostly with the L<Valiant> model validation framework as well as the
glue for L<DBIx:Class>, L<DBIx:Class::Valiant>, although I did take pains to try and make the API
agnostic many of the test cases are assuming that stack and getting that integration working well is
the primary use case for me.  Thoughts and code to make this more stand alone are very welcomed.

=head1 ATTRIBUTES

This class defines the following attributes used in creating an instance.

=head2 model

This is the data model that the formbuilder inspects for field state and error conditions.   This should be
a model that does the API described here: L<Valiant::HTML::Form/'REQUIRED MODEL API'>. Required but the API
is pretty flexible (see docs).

Please note that my initial use case for this is using L<Valiant> for validation and L<DBIx::Class> as the
model (via L<DBIx:Class::Valiant>) so that combination has the most testing and examples.   If you are using
a different storage or validation setup you need to complete the API described.  Please send test cases
and pull requests to improve interoperability!

=head2 name

This is a string which is the internal name given to the model.  This is used to set a namespace for form
field C<name> attributes and the default namespace for C<id> attributes.  Required.

=head2 options

A optional hashref of options used in form field generation.   Some of these might become attributes in the
future.  Here's a list of the current options

=over 4

=item index

The index of the formbuilder when it is a sub formbuilder with a parent and we are iterating over a collection.

=item child_index

When creating a sub formbuilder that is an element in a collection, this is used to pass the index value

=item builder

The package name of the current builder

=item parent_builder

The parent formbuilder instance to a sub builder.

=item include_id

Used to indicated that a sub formbuilder should add hidden fields indicating the storage ID for the current model.

=item namespace

The ID namespace; used to populate the C<namespace> attribute.

=item as

Used to override how the class and ids are made for your forms.

=back

=head2 index

The current index of a collection for which the current formbuilder is one item in.

=head2 namespace

Used to add a prefix to the ID for your form elements.

=head2 allow_method_names_outside_model

Default is false.  Generally we expect C<method_name> to be an actual method on the
C<model> and if its not we expect an exception.  This helps to prevent typos from
leading to unexpected results.  However sometimes you may wish create a form field that
has a name that isn't on the model but still respects the current namespace and index.
These names would appear in the POST request body and could be used for things other than
updating or creating a model.

=head2 skip_default_ids

Defaults to false.  Generally we create an html C<id> attribute for the field based
on a convention which includes the model name, index and method name.  Setting this
to true prevents that so you should set C<id> manually unless you don't want them.
Please note that even if this is false, you can always override the C<id> on a per
field basis by setting it manually.

=head2 view

Optional.  The view or template object that is using the formbuilder.  If available can be used to
influence how the HTML for controls are created.

Generally used to provide HTML escaping and safe string tagging methods that are compatible with
your template system.  For example L<Mojo::Template> provides its own system for marking strings
safe for template display.  I you don't provide a view then we will use L<Valiant::HTML::SafeString>
for automatic HTML escaping.  If you are not using a view or template system (for example like
L<Template::Toolkit> ) that does automatic escaping then the built in escaping features are probably
fine.

If you provide a view it should provide the following API methods:

=over 4

=item raw

given a string return a single tagged object which is marked as safe for display.  Do not do any HTML 
escaping on the string.  This is used when you want to pass strings straight to display and that you 
know is safe.  Be careful with this to avoid HTML injection attacks.

=item safe

given a string return a single tagged object which is marked as safe for display.  First HTML escape the
string as safe unless its already been done (no double escaping).

=item safe_concat

Same as C<safe> but instead works an an array of strings (or mix of strings and safe string objects) and
concatenates them all into one big safe marked string.

=item html_escape

Given a string return string that has been HTML escaped.

=item read_attribute_for_view

Given an attribute name return the value that the view has defined for it.

B<NOTE> Optional

=item attribute_for_view_exists

Given an attribute name return true if the view has defined a value for it.

B<NOTE> Optional

=back

Both C<raw>, C<safe> and C<safe_concat> should return a 'tagged' object which is specific to your view or
template system. However this object must 'stringify' to the safe version of the string to be displayed.  See
L<Valiant::HTML::SafeString> for example API.  We use <Valiant::HTML::SafeString> internally to provide
safe escaping if you're view doesn't do automatic escaping, as many older template systems like Template
Toolkit.

B<NOTE>: In the future the view API might change so keep an eye on this spot.

=head1 METHODS

This class defines the following public instance methods.

=head2 form_action

The Form action attribute

=head2 form_method

The form method attribute

=head2 form_enctype

the form enctype attribute

=head2 csrf_token

The CSRF token, if there is one

=head2 allow_method_names_outside_object

accessor to the 'allow_method_names_outside_object' option.  This is true by default.   Allow you
to control the behavior of what happens when you try to access a model attribute that doesn't exist

=head2 tag_errors_for_attribute

Given an attribute return an array of error messages for that attribute if any.

=head2 form_has_errors

Display a message if the form has errors.  This is a convenience method that you can use in your
template to display a message if there are any errors in the form.  This is useful if you want to
display a message at the top of the form.  You can also use this method to display a message at the
top of a sub formbuilder if you are using sub formbuilders.

A form has errors if any of the fields has an error or if the model has errors.

    $fb->form_has_errors();
    $fb->form_has_errors(\%attrs);
    $fb->form_has_errors(\%attrs, $content);
    $fb->form_has_errors(\$content);
    $fb->form_has_errors(\&template);

Examples:

    # with default content
    $fb->form_has_errors;

    # with simple content
    $fb->form_has_errors('There were errors in the form. Please correct them.');

    # Simple content with attributes
    $fb->form_has_errors({ class=>'alert alert-danger', role=>'alert' },
      'There were errors in the form. Please correct them and try again.');

    # with complex content
    $fb->form_has_errors(sub ($self, $fb, $contact) {
      div +{ class=>'alert alert-danger', role=>'alert' }, [
        'There were errors in the form. Please correct them and try again.',
      ]
    });

If you pass a scalar as content, the scalar can be a string or a translation tag.

B<Note> Please note this method doesn't show any of the model or field errors,
it just shows a generic 'form has errors' message.  You can either call the field or
L</model_errors> methods, or you can loop over errors in the custom complex
content callback.  Alternatively if you have model level errors for this object
you might prefer to use the L</model_errors> method with the C<show_message_on_field_errors>
option.

=head2 model_errors

    $fb->model_errors();
    $fb->model_errors(\%attrs);
    $fb->model_errors(\%attrs, \&template); # %attrs limited to 'max_errors' and 'show_message_on_field_errors'
    $fb->model_errors(\&template);

Display model level errors, either with a default or custom template.  'Model' errors are
errors that are not associated with a model attribute in particular, but rather the model
as a whole.

Arguments to this method are optional.  "\%attrs" is a hashref which is passed to the tag 
builder to create any needed HTML attributes (such as class and style). "\&template" is
a coderef that gets the @errors as an argument and you can use it to customize how the errors
are displayed.  Otherwise we use a default template that lists the errors with an HTML ordered
list, or a C<div> if there's only one error.

"\%attrs" can also contain two options that gives you some additional control over the display

=over

=item max_errors

Don't display more than a certain number of errors

=item show_message_on_field_errors

Sometimes you want a global message displayed when there are field errors.  L<Valiant> doesn't
add a model error if there's field errors (although it would be easy for you to add this yourself
with a model validation) so this makes it easy to display such a message.  If a string or translation
tag then show that, if its a '1' the show the default message, which is "Form has errors" unless
you overide it.

This can be a useful option when you have a long form and you want a user to know there's errors
possibly off the browser screen.

=back

Examples.  Assume two model level errors "Trouble 1" and "Trouble 2":

    $fb->model_errors;
    # <ol><li>Trouble 1</li><li>Trouble 2</li></ol>

    $fb->model_errors({class=>'foo'});
    # <ol class="foo"><li>Trouble 1</li><li>Trouble 2</li></ol>

    $fb->model_errors({max_errors=>1});
    # <div>Trouble 1</div>

    $fb->model_errors({max_errors=>1, class=>'foo'})
    # <div class="foo">Trouble 1</div>

    $fb->model_errors({show_message_on_field_errors=>1})
    # <ol><li>Form has errors</li><li>Trouble 1</li><li>Trouble 2</li></ol>

    $fb->model_errors({show_message_on_field_errors=>"Bad!"})
    # <ol><li>Bad!</li><li>Trouble 1</li><li>Trouble 2</li></ol>

    $fb->model_errors(sub {
      my (@errors) = @_;
      join " | ", @errors;
    });
    # Trouble 1 | Trouble 2

=head2 label

    $fb->label($attribute)
    $fb->label($attribute, \%options)
    $fb->label($attribute, $content)
    $fb->label($attribute, \%options, $content) 
    $fb->label($attribute, \&content);   sub content { my ($translated_attribute) = @_;  ... }
    $fb->label($attribute, \%options, \&content);   sub content { my ( $translated_attribute) = @_;  ... }

Creates a HTML form element C<label> with the given "\%options" passed to the tag builder to
create HTML attributes and an optional "$content".  If "$content" is not provided we use the
human, translated (if available) version of the "$attribute" for the C<label> content.  Alternatively
you can provide a template which is a subroutine reference which recieves the translated attribute
as an argument.  Examples:

    $fb->label('first_name');
    # <label for="person_first_name">First Name</label>

    $fb->label('first_name', {class=>'foo'});
    # <label class="foo" for="person_first_name">First Name</label>

    $fb->label('first_name', 'Your First Name');
    # <label for="person_first_name">Your First Name</label>

    $fb->label('first_name', {class=>'foo'}, 'Your First Name');
    # <label class="foo" for="person_first_name">Your First Name</label>

    $fb->label('first_name', sub {
      my $translated_attribute = shift;
      return "$translated_attribute ",
        $fb->input('first_name');
    });
    # <label for="person_first_name">
    #   First Name 
    #   <input id="person_first_name" name="person.first_name" type="text" value="John"/>
    # </label>

    $fb->label('first_name', +{class=>'foo'}, sub {
      my $translated_attribute = shift;
      return "$translated_attribute ",
        $fb->input('first_name');
    });
    # <label class="foo" for="person_first_name">
    #   First Name
    #   <input id="person_first_name" name="person.first_name" type="text" value="John"/>
    # </label>

=head2 errors_for

    $fb->errors_for($attribute)
    $fb->errors_for($attribute, \%options)
    $fb->errors_for($attribute, \%options, \&template)
    $fb->errors_for($attribute, \&template)

Similar to L</model_errors> but for errors associated with an attribute of a model.  Accepts
the $attribute name, a hashref of \%options (used to set options controling the display of
errors as well as used by the tag builder to create HTML attributes for the containing tag) and
lastly an optional \&template which is a subroutine reference that received an array of the
translated errors for when you need very custom error display.  If omitted we use a default
template displaying errors in an ordered list (if more than one) or wrapped in a C<div> tag
(if only one error).

\%options used for error display and which are not passed to the tag builder as HTML attributes:

=over

=item max_errors

Don't display more than a certain number of errors

=back

Assume the attribute 'last_name' has the following two errors in the given examples: "first Name
is too short", "First Name contains non alphabetic characters".

    $fb->errors_for('first_name');
    # <ol><li>First Name is too short (minimum is 3 characters)</li><li>First Name contains non alphabetic characters</li></ol>

    $fb->errors_for('first_name', {class=>'foo'});
    # <ol class="foo"><li>First Name is too short (minimum is 3 characters)</li><li>First Name contains non alphabetic characters</li></ol>

    $fb->errors_for('first_name', {class=>'foo', max_errors=>1});
    # <div class="foo">First Name is too short (minimum is 3 characters)</div>

    $fb->errors_for('first_name', sub {
      my (@errors) = @_;
      join " | ", @errors;
    });
    # First Name is too short (minimum is 3 characters) | First Name contains non alphabetic characters

=head2 input

    $fb->input($attribute, \%options)
    $fb->input($attribute)

Create an C<input> form tag using the $attribute's value (if any) and optionally passing a hashref of
\%options which are passed to the tag builder to create HTML attributes for the C<input> tag.  Optionally
add C<errors_classes> which is a string that is appended to the C<class> attribute when the $attribute has
errors.  Examples:

    $fb->input('first_name');
    # <input id="person_first_name" name="person.first_name" type="text" value="J"/>

    $fb->input('first_name', {class=>'foo'});
    # <input class="foo" id="person_first_name" name="person.first_name" type="text" value="J"/>

    $fb->input('first_name', {errors_classes=>'error'});
    # <input class="error" id="person_first_name" name="person.first_name" type="text" value="J"/>

    $fb->input('first_name', {class=>'foo', errors_classes=>'error'});
    # <input class="foo error" id="person_first_name" name="person.first_name" type="text" value="J"/>

Special \%options:

=over 4

=item errors_classes

A string that is appended to the C<class> attribute if the $attribute has errors (as defined by the model API)

=back

=head2 password

    $fb->password($attribute, \%options)
    $fb->password($attribute)

Create a C<password> HTML form field.   Similar to L</input> but sets the C<type> to 'password' and also
sets C<value> to '' since generally you don't want to show the current password (and if you are doing the
right thing and saving a 1 way hash not the plain text you don't even have it to show anyway).

Example:

    $fb->password('password');
    # <input id="person_password" name="person.password" type="password" value=""/>

    $fb->password('password', {class='foo'});
    # <input class="foo" id="person_password" name="person.password" type="password" value=""/>

    $fb->password('password', {class='foo', errors_classes=>'error'});
    # <input class="foo error" id="person_password" name="person.password" type="password" value=""/>

=head2 hidden

    $fb->hidden($attribute, \%options)
    $fb->hidden($attribute)

Create a C<hidden> HTML form field.   Similar to L</input> but sets the C<type> to 'hidden'.

    $fb->hidden('id');
    # <input id="person_id name="person.id" type="hidden" value="101"/>

    $fb->hidden('id', {class='foo'});
    # <input class="foo" id="person_id name="person.id" type="hidden" value="101"/>

=head2 text_area

    $fb->text_area($attribute);
    $fb->text_area($attribute, \%options);

Create an HTML C<text_area> tag based on the attribute value and with optional \%options
which is a a hashref passed to the tag builder for generating HTML attributes.   Can also set
C<errors_classes> that will append a string of additional CSS classes when the $attribute has
errors.  Examples:

    $fb->text_area('comments');
    # <textarea id="person_comments" name="person.comments">J</textarea>

    $fb->text_area('comments', {class=>'foo'});
    # <textarea class="foo" id="person_comments" name="person.comments">J</textarea>

    $fb->text_area('comments', {class=>'foo', errors_classes=>'error'});
    # <textarea class="foo error" id="person_comments" name="person.comments">J</textarea>

Special \%options:

=over 4

=item errors_classes

A string that is appended to the C<class> attribute if the $attribute has errors (as defined by the model API)

=back

=head2 checkbox

    $fb->checkbox($attribute);
    $fb->checkbox($attribute, \%options);
    $fb->checkbox($attribute, $checked_value, $unchecked_value);
    $fb->checkbox($attribute, \%options, $checked_value, $unchecked_value);

Generate an HTML form checkbox element with its state based on evaluating the value of $attribute
in a boolean context. If $attribute is true then the C<checkbox> will be checked. May also pass a
hashref of \%options, which contain render instructions and HTML attributes used by the tag builder.
"$checked_value" and "$unchecked_value" specify the values when the checkbox is checked or not (defaults
to 1 for checked and 0 for unchecked, but $unchecked is ignored if option C<include_hidden> is set to 
false; see below).

Special \%options:

=over 4

=item errors_classes

A string that is appended to the C<class> attribute if the $attribute has errors (as defined by the model API)

=item include_hidden

Defaults to true.  Since the rules for an HTML form checkbox specify that if the checkbox is 'unchecked' then
nothing is submitted.  This can cause issues if you are expecting a submission that somehow indicates 'unchecked'
For example you might have a status field boolean where unchecked should indicate 'false'.  So by default we add
a hidden field with the same name as the checkbox, with a value set to $unchecked_value (defaults to 0).  In the
case where the field is checked then you'll get two values for the same field name so you should have logic that
in the case that field name is an array then take the last one (if you are using L<Plack::Request> this is using
L<Hash::MultiValue> which does this by default; if you are using L<Catalyst> you can use the C<use_hash_multivalue_in_request>
option or you can use something like L<Catalyst::TraitFor::Request::StructuredParameters> which has options to
help with this.   If you are using L<Mojolicious> then the C<param> method works this way as well.

=item checked

A boolean value to indicate if the checkbox field is 'checked' when generated.   By default a checkbox state is
determined by the value of $attribute for the underlying model.  You can use this to override (for example you 
might wish a checkbox default state to be checked when creating a new entry when it would otherwise be false).

=back

Examples:

    $fb->checkbox('status');
    # <input name="person.status" type="hidden" value="0"/>
    # <input id="person_status" name="person.status" type="checkbox" value="1"/>

    $fb->checkbox('status', {class=>'foo'});
    # <input name="person.status" type="hidden" value="0"/>
    # <input class="foo" id="person_status" name="person.status" type="checkbox" value="1"/>

    $fb->checkbox('status', 'active', 'deactive');
    # <input name="person.status" type="hidden" value="deactive"/>
    # <input id="person_status" name="person.status" type="checkbox" value="active"/>

    $fb->checkbox('status', {include_hidden=>0});
    # <input id="person_status" name="person.status" type="checkbox" value="1"/>

    $person->status(1);
    $fb->checkbox('status', {include_hidden=>0});
    # <input checked id="person_status" name="person.status" type="checkbox" value="1"/>

    $person->status(0);
    $fb->checkbox('status', {include_hidden=>0, checked=>1});
    # <input checked id="person_status" name="person.status" type="checkbox" value="1"/>

    $fb->checkbox('status', {include_hidden=>0, errors_classes=>'err'});
    # <input class="err" id="person_status" name="person.status" type="checkbox" value="1"/>

=head2 radio_button

    $fb->radio_button($attribute, $value);
    $fb->radio_button($attribute, $value, \%options);

Generate an HTML input type 'radio', typically part of a group including 2 or more controls.
Generated value attributes uses $value, the control is marked 'checked' when $value matches
the value of $attribute (or you can override, see below).   \%options are HTML attributes which
are passed to the tag builder unless special as described below.

Special \%options:

=over 4

=item errors_classes

A string that is appended to the C<class> attribute if the $attribute has errors (as defined by the model API)

=item checked

A boolean which determines if the input radio control is marked 'checked'.   Used if you want to 
override the default.

=back

Examples:

    # Example radio group

    $person->type('admin');

    $fb->radio_button('type', 'admin');
    $fb->radio_button('type', 'user');
    $fb->radio_button('type', 'guest');

    #<input checked id="person_type_admin" name="person.type" type="radio" value="admin"/>
    #<input id="person_type_user" name="person.type" type="radio" value="user"/>
    #<input id="person_type_guest" name="person.type" type="radio" value="guest"/>
    
    # Example \%options

    $fb->radio_button('type', 'guest', {class=>'foo', errors_classes=>'err'});
    # <input class="foo err" id="person_type_guest" name="person.type" type="radio" value="guest"/>

    $fb->radio_button('type', 'guest', {checked=>1});
    # <input checked id="person_type_guest" name="person.type" type="radio" value="guest"/>

=head2 date_field

    $fb->date_field($attribute);
    $fb->date_field($attribute, \%options);

Generates a 'type' C<date> HTML input control.  Used when your $attribute value is a L<DateTime>
object to get proper string formatting.  Although the C<date> type is considered HTML5 you can
use this for older HTML versions as well when you need to get the object formatting (you just don't
get the date HTML controls).

When the $attribute value is a L<DateTime> object (or actually is any object) we call '->ymd' to stringify
the object to the expected format. '\%options' as in the input control are passed to the tag builder
to create HTML attributes on the input tag with the exception of the specials ones already documented
(such as C<errors_classes>) and the following special \%options

=over 4

=item min

=item max

When these are L<DateTime> objects we stringify using ->ymd to get the expected format; otherwise 
they are passed as is to the tag builder.

=back

Examples:

    $person->birthday(DateTime->new(year=>1969, month=>2, day=>13));

    $fb->date_field('birthday');
    # <input id="person_birthday" name="person.birthday" type="date" value="1969-02-13"/>

    $fb->date_field('birthday', {class=>'foo', errors_classes=>'err'});
    # <input class="foo err" id="person_birthday" name="person.birthday" type="date" value="1969-02-13"/>

    $fb->date_field('birthday', +{
      min => DateTime->new(year=>1900, month=>1, day=>1),
      max => DateTime->new(year=>2030, month=>1, day=>1),
    });
    #<input id="person_birthday" max="2030-01-01" min="1900-01-01" name="person.birthday" type="date" value="1969-02-13"/>

=head2 datetime_local_field

=head2 time_field

Like L</date_field> but sets the input type to C<datetime-local> or C<time> respectively and formats any
<DateTime> values with "->strftime('%Y-%m-%dT%T')" (for C<datetime-local>) or either "->strftime('%H:%M')"
or "->strftime('%T.%3N')" for C<time> depending on the \%options C<include_seconds>, which defaults to true).

Examples:

    $person->due(DateTime->new(year=>1969, month=>2, day=>13, hour=>10, minute=>45, second=>11, nanosecond=> 500000000));

    $fb->datetime_local_field('due');
    # <input id="person_due" name="person.due" type="datetime-local" value="1969-02-13T10:45:11"/>

    $fb->time_field('due');
    # <input id="person_due" name="person.due" type="time" value="10:45:11.500"/>

    $fb->time_field('due', +{include_seconds=>0});
    # <input id="person_due" name="person.due" type="time" value="10:45"/>

=head2 submit

    $fb->submit;
    $fb->submit(\%options);
    $fb->submit($value);
    $fb->submit($value, \%options);

Create an HTML submit C<input> tag with a meaningful default value based on the model name and its state
in storage (if supported by the model).  Will also look up the following two translation tag keys:

    "formbuilder.submit.@{[ $self->name ]}.${key}"
    "formbuilder.submit.${key}"

Where $key is by default 'submit' and if the model supports 'in_storage' its either 'update' or 'create'
depending on if the model is new or already existing.

Examples:

    $fb->submit;
    # <input id="commit" name="commit" type="submit" value="Submit Person"/>

    $fb->submit('Login', {class=>'foo'});
    # <input class="foo" id="commit" name="commit" type="submit" value="Login"/>

=head2 button

    $fb->button($name, \%attrs, \&block)
    $fb->button($name, \%attrs, $content)
    $fb->button($name, \&block)
    $fb->button($name, $content)

Create a C<button> tag with custom attibutes and content.  Content be be a string or a coderef if you
need to do complex layout.

Useful to create submit buttons with fancy formatting or when you need a button that submits in the
form namespace.

Examples:

    $person->type('admin');

    $fb->button('type');
    # <button id="person_type" name="person.type" type="submit" value="admin">Button</button>

    $fb->button('type', {class=>'foo'});
    # <button class="foo" id="person_type" name="person.type" type="submit" value="admin">Button</button>

    $fb->button('type', "Press Me")
    # <button id="person_type" name="person.type" type="submit" value="admin">Press Me</button>

    $fb->button('type', sub { "Press Me" })
    # <button id="person_type" name="person.type" type="submit" value="admin">Press Me</button>

=head2 legend

    $fb->legend;
    $fb->legend(\%options);
    $fb->legend($content);
    $fb->legend($content, \%options);
    $fb->legend(\&template);
    $fb->legend(\%options, \&template);

Create an HTML Form C<legend> element with default content that is based on the model name.
Accepts \%options which are passed to the tag builder and used to create HTML element attributes.
You can override the content with either a $content string or a \&template coderef (which will 
receive the default content translation as its first argument).

The default content will be based on the model name and can be influenced by its storage status
if C<in_storage> is supplied by the model.  We attempt to lookup the content string via the
following translation tags (if the body supports ->i18n):

    "formbuilder.legend.@{[ $self->name ]}.${key}"
    "formbuilder.legend.${key}"

Where $key is 'new' if the model doesn't support C<in_storage> else it's either 'update' or 'create'
based on if the current model is already in storage (update) or its new and needs to be created.

Examples:

    $fb->legend;
    # <legend>New Person</legend>

    $fb->legend({class=>'foo'});
    # <legend class="foo">New Person</legend>

    $fb->legend("Person");
    # <legend>Person</legend>

    $fb->legend("Persons", {class=>'foo'});
    # <legend class="foo">Persons</legend>

    $fb->legend(sub { shift . " Info"});
    # <legend>New Person Info</legend>

    $fb->legend({class=>'foo'}, sub {"Person"});
    # <legend class="foo">Person</legend>

=head2 legend_for

    $fb->legend_for($attr);
    $fb->legend_for($attr, \%options);

Creates an HTML C<legend> tags with it's content set to the human translated name of the given
$attribute.  Allows you to pass some additional HTML attributes to the legend tag.  Examples:

    $fb->legend_for('status')
    # <legend id="status_legend" >Status</legend>
    
    $fb->legend_for('status', {class=>'foo'})
    # <legend id="status_legend" class="foo" >Status</legend>

=head2 fields_for

    $fb->fields_for($attribute, sub {
      my ($nested_fb, $model) = @_;
    });

    $fb->fields_for($attribute, \%options, sub {
      my ($nested_fb, $model) = @_;
    });

    # With a 'finally' block when $attribute is a collection

    $fb->fields_for($attribute, sub {
      my ($nested_fb, $model) = @_;
    }, sub {
      my ($nested_fb, $new_model) = @_;
    });


Used to create sub form builders under the current one for nested models (either a collection of models
or a single model.)  This sub form builder will be passed as the first argument to the enclosing subref
and will encapsulate any indexing or namespacing; its model will be set to the sub model.   You also get
a second argument which is the sub model for ease of access.  Note that if the $attribute refers to a collection
then $model will be set to the current item model of that collection.

When the $attribute refers to a collection the collection object must provide a C<next> method which should
iterate thru the collection in the order desired and return C<undef> to indicate all records have been rolled
thru. This collection object may also implement a C<reset> method to return the index to the start of the
collection (which will be called after the final record is processed) and a C<build> method which should 
return a new empty record (required if you want a C<finally> block as described below).

Please see L<Valiant::HTML::Util::Collection> for example.  B<NOTE>: If you supply an arrayref instead of
a collection object, we will build one using L<Valiant::HTML::Util::Collection> automatically.  This behavior
might change in the future so it would be ideal to not rely on it.

If the $attribute is a collection you may optionally add a second coderef template which is called after
the collect has been fully iterated thru and it recieves a sub formbuilder with a new blank model as an
argument.   This finally block is always called, even if the collection is empty so it can he used to
generate a blank entry for adding new items to the collection (for example) or for any extra code or field
controls that you want under the sub model namespace.

Available \%options:

=over 4

=item builder

The class name of the formbuilder.  Defaults to L<Valiant::HTML::FormBuilder> or whatever the current
builder is (if overridden in the parent).

=item namespace

The ID namespace.  Will default to the parent formbuilder C<namespace> if there is one.

=item child_index

The index of the sub object. Can be a coderef.   Used if you need explicit control over the index generated

=item include_id

Defaults to true.   If the sub model does C<in_storage> and C<primary_columns> then add hidden form fields
with those IDs to the sub model namespace.  Often needed to properly match a record to its existing state
in storage (such as a database).  Not sure why you'd want to turn this off but the option is a carry over
from Rails so I presume there is a use case.

=item id

Override the ID namespace for th sub model.

=item index

Explicitly override the index of the sub model.

=back

Example of an attribute that refers to a nested object.

    $person->profile(Local::Profile->new(zip=>'78621', address=>'ab'));

    $fb->fields_for('profile', sub {
      my $fb_profile = shift;
      return  $fb_profile->input('address'),
              $fb_profile->errors_for('address'),
              $fb_profile->input('zip');
    });

    # <input id="person_profile_address" name="person.profile.address" type="text" value="ab"/>
    # <div>Address is too short (minimum is 3 characters)</div>
    # <input id="person_profile_zip" name="person.profile.zip" type="text" value="78621"/>

Example of an attribute that refers to a nested collection object (and with a "finally block")

    $person->credit_cards([
      Local::CreditCard->new(number=>'234234223444', expiration=>DateTime->now->add(months=>11)),
      Local::CreditCard->new(number=>'342342342322', expiration=>DateTime->now->add(months=>11)),
      Local::CreditCard->new(number=>'111112222233', expiration=>DateTime->now->subtract(months=>11)),  # An expired card
    ]);

    $fb->fields_for('credit_cards', sub {
      my $fb_cc = shift;
      return  $fb_cc->input('number'),
              $fb_cc->date_field('expiration'),
              $fb_cc->errors_for('expiration');
    }, sub {
      my $fb_finally = shift;
      return  $fb_finally->button('add', +{value=>1}, 'Add a New Credit Card');
    });

    # <input id="person_credit_cards_0_number" name="person.credit_cards[0].number" type="text" value="234234223444"/>
    # <input id="person_credit_cards_0_expiration" name="person.credit_cards[0].expiration" type="date" value="2023-01-23"/>
    # <input id="person_credit_cards_1_number" name="person.credit_cards[1].number" type="text" value="342342342322"/>
    # <input id="person_credit_cards_1_expiration" name="person.credit_cards[1].expiration" type="date" value="2023-01-23"/>
    # <input id="person_credit_cards_2_number" name="person.credit_cards[2].number" type="text" value="111112222233"/>
    # <input id="person_credit_cards_2_expiration" name="person.credit_cards[2].expiration" type="date" value="2021-03-23"/>
    # <div>Expiration chosen date can&#39;t be earlier than 2022-02-23</div>
    # <button id="person_credit_cards_3_add" name="person.credit_cards[3].add" type="submit" value="1">Add a New Credit Card</button>

=head2 select

    $fb->select($attribute_proto, \@options, \%options)
    $fb->select($attribute_proto, \@options)
    $fb->select($attribute_proto, \%options, \&template)
    $fb->select($attribute_proto, \&template)

Where C<$attribute_proto> is one of:

    $attribute                # A scalar value which is an attribute on the underlying $model
    { $attribute => $method } # A hashref composed of an $attribute on the underlying $model
                              # which returns a sub model or a collection of sub models
                              # and a $method to be called on the value of that sub model (
                              # or on each item sub model if the $attribute is a collection).

Used to create a C<select> tag group with option tags.  \@options can be anything that can be
accepted by L<Valiant::HTML::FormTags/options_for_select>.  The value(s) of $attribute_proto
are automatically marked as C<selected>.

Since this is built on top if C<select_tag> \%options can be anything supported by that
method.  See L<Valiant::HTML::FormTags/select_tag> for more.  In addition we have the following
special handling for \%options:

=over 4

=item selected

=item disabled

Mark C\<option> tags as selected or disabled.   If you manual set selected then we ignore
the value of $attribute (or @values when $attribute is a collection)

=item unselected_value

The value to set the hidden 'unselected' field to. No default value.  See 'include_hidden' for details.

=item include_hidden

Defaults to true for 'multiple' and false for single type selects.

The rules for an HTML form select field specify that if the no option is 'selected' then
nothing is submitted.  This can cause issues if you are expecting a submission that somehow indicates 'nothing selected'
means to unset some settings. So we do one of two things when 'include_hidden' is true. When the select is a
simple 'single value' select (not multiple) we add a hidden field with the same name as the select name but indexed to 0 so its
always the first value; its value is whatever you set 'unselected_value' to.  If you don't set 'unselected_value' this hidden
field is NOT created.  If you are using L<Plack::Request> or L<Mojolicious> (or using L<Catalyst> with C<use_hash_multivalue_in_request> option set to
true, or something like L<Catalyst::TraitFor::Request::StructuredParameters>) then the last value of an array
body parameter will be returned which will let you choose between a default value or an actual returned value.  Example:

    # $fb->select('state_ids', [map { [$_->label, $_->id] } $roles_collection->all], +{include_hidden=>1, unselected_value=>-1} );
    # <input id="person_state_ids_hidden" name="person.state_ids[0]" type="hidden" value="-1"/>
    # <select id="person_state_ids" multiple name="person.state_ids[]">
    #   <option selected value="1">user</option>
    #   <option value="2">admin</option>
    #   <option selected value="3">guest</option>
    # </select>


If you've set the 'multiple' attribute to true, or we detect that multiple values are intended (either when the form value
of the field is an arrayref or a collection) indicting your select drop list allows one to choose more than one option, 
we add a hidden field '_nop' at index 0 which you will need to treat at the signal for 'this means unset.   If you are using this with
L<DBIx:Class::Valiant> then that code will automatically handle this for you.   Otherwise you'll need to handle it
manually or add code to detect that there is no form submission value under that name.  If you don't want this
behavior you can manually turn it off be explicitly setting 'include_hidden' to false.

=back

Optionally you can provide a \&template which should return C<option> tags.  This coderef
will recieve the $model, $attribute and an array of @selected values based on the $attribute.

Examples:

    $fb->select('state_id', [1,2,3], +{class=>'foo'} );
    # <select class="foo" id="person_state_id" name="person.state_id">
    #   <option selected value="1">1</option>
    #   <option value="2">2</option>
    #   <option value="3">3</option>
    # </select>

    $fb->select('state_id', [1,2,3], +{selected=>[3], disabled=>[1]} );
    # <select id="person_state_id" name="person.state_id">
    #   <option disabled value="1">1</option>
    #   <option value="2">2</option>
    #   <option selected value="3">3</option>
    # </select>

    $fb->select('state_id', [map { [$_->name, $_->id] } $states_collection->all], +{include_blank=>1} );
    # <select id="person_state_id" name="person.state_id">
    #   <option label=" " value=""></option>
    #   <option selected value="1">TX</option>
    #   <option value="2">NY</option>
    #   <option value="3">CA</option>
    # </select>

    $fb->select('state_id', sub {
      my ($model, $attribute, $value) = @_;
      return map {
        my $selected = $_->id eq $value ? 1:0;
        option_tag($_->name, +{class=>'foo', selected=>$selected, value=>$_->id}); 
      } $states_collection->all;
    });
    # <select id="person_state_id" name="person.state_id">
    #   <option class="foo" selected value="1">TX</option>
    #   <option class="foo" value="2">NY</option>
    #   <option class="foo" value="3">CA</option>
    # </select>

Examples when $attribute is a collection:

    $fb->select({roles => 'id'}, [map { [$_->label, $_->id] } $roles_collection->all]), 
    # <input id="person_roles_id_hidden" name="person.roles[0]._nop" type="hidden" value="1"/>
    # <select id="person_roles_id" multiple name="person.roles[].id">
    #   <option selected value="1">user</option>
    #   <option selected value="2">admin</option>
    #   <option value="3">guest</option>
    # </select>

Please note when the $attribute is a collection we add a hidden field to cope with case when
no items are selected, you'll need to write form processing code to mark and notice the
C<_nop> field.

=head2 collection_select

    $fb->collection_select($attribute_proto, $collection, $value_method, $text_method, \%options);
    $fb->collection_select($attribute_proto, $collection, $value_method, $text_method);
    $fb->collection_select($attribute_proto, $collection);
    $fb->collection_select($attribute_proto, \%options);

Where C<$attribute_proto> is one of:

    $attribute                # A string which is an attribute on the underlying $model
                              # that returns a scalar value.
    { $attribute => $method } # A hashref composed of an $attribute on the underlying $model
                              # which returns a sub model or a collection of sub models
                              # and a $method to be called on the value of that sub model (
                              # or on each item sub model if the $attribute is a collection).

Similar to L</select> but works with a $collection instead of delineated options.  The collection can be
an actual collection object, or the string name of a method on the model which provides the actual
collection objection.  Its a type of shortcut to reduce boilerplate at the expense of some flexibility (
if you need that you'll need to use L</select>).  Examples:

    $fb->collection_select('state_id', $states_collection, id=>'name');
    # <select id="person.state_id" name="person.state_id">
    #   <option selected value="1">TX</option>
    #   <option value="2">NY</option>
    #   <option value="3">CA</option>
    # </select>

    $fb->collection_select('state_id', $states_collection, id=>'name', {class=>'foo', include_blank=>1});
    # <select class="foo" id="person.state_id" name="person.state_id">
    #   <option label=" " value=""></option>
    #   <option selected value="1">TX</option>
    #   <option value="2">NY</option>
    #   <option value="3">CA</option>
    # </select>

    $fb->collection_select('state_id', $states_collection, id=>'name', {selected=>[3], disabled=>[1]});
    # <select id="person.state_id" name="person.state_id">
    #   <option disabled value="1">TX</option>
    #   <option value="2">NY</option>
    #   <option selected value="3">CA</option>
    # </select>

    is $fb->collection_select({roles => 'id'}, $roles_collection, id=>'label');
    # <input id="person_roles_id_hidden" name="person.roles[0]._nop" type="hidden" value="1"/>
    # <select id="person_roles_id" multiple name="person.roles[].id">
    #   <option selected value="1">user</option>
    #   <option selected value="2">admin</option>
    #   <option value="3">guest</option>
    # </select>

Please note when the $attribute is a collection value we add a hidden field to allow you to send a signal
to the form processor that this namespace contains no records.   Otherwise the form will just send 
nothing.  If you have a custom way to handle this you can disable the behavior if you wish by explicitly
setting include_hidden=>0

=head2 collection_checkbox

    $fb->collection_checkbox({$attribute=>$value_method}, $collection, $value_method, $text_method, \%options);
    $fb->collection_checkbox({$attribute=>$value_method}, $collection, $value_method, $text_method);
    $fb->collection_checkbox({$attribute=>$value_method}, $collection);
    $fb->collection_checkbox({$attribute=>$value_method}, $collection, $value_method, $text_method, \%options, \&template);
    $fb->collection_checkbox({$attribute=>$value_method}, $collection, $value_method, $text_method, \&template);
    $fb->collection_checkbox({$attribute=>$value_method}, $collection, \&template);

Create a checkbox group for a collection attribute

Examples:

Where the $attribute C<roles> refers to a collection of sub models, each of which provides a method C<id>
which is used to fetch a matching value and $roles_collection refers to the full set of available roles
which can be added or removed from the parent model.

In these examples C<$collection> and C<$roles_collection> can be either a collection object or a string
which is the method name on the current model which provides the collection.

    $fb->collection_checkbox({roles => 'id'}, $roles_collection, id=>'label'); 
    # <div id="person_roles">
    #   <input id="person_roles_hidden" name="person.roles" type="hidden" value="{'_nop':1}"/>
    #   <label for="person_roles_1">user</label>
    #   <input checked id="person_roles_1" name="person.roles" type="checkbox" value="{'id':1}"/>
    #   <label for="person_roles_2">admin</label>
    #   <input checked id="person_roles_2" name="person.roles" type="checkbox" value="{'id':2}"/>
    #   <label for="person_roles_3">guest</label>
    #   <input id="person_roles_3" name="person.roles" type="checkbox" value="{'id':3}"/>
    # </div>

Please note when the $attribute is a collection value we add a hidden field to allow you to send a signal
to the form processor that this namespace contains no records.   Otherwise the form will just send 
nothing.  If you have a custom way to handle this you can disable the behavior if you wish by explicitly
setting include_hidden=>0

If you have special needs for formatting or layout you can override the default template with a coderef
that will receive a special type of formbuilder localized to the current value (an instance of
L<Valiant::HTML::FormBuilder::Checkbox>):

    $fb->collection_checkbox({roles => 'id'}, $roles_collection, id=>'label', sub {
      my $fb_roles = shift;
      return  $fb_roles->checkbox({class=>'form-check-input'}),
              $fb_roles->label({class=>'form-check-label'});
    });

    # <div id="person_roles">
    #   <input id="person_roles_hidden" name="person.roles" type="hidden" value="{'_nop':1}"/>
    #   <label for="person_roles_1" class="form-check-label">user</label>
    #   <input checked class="form-check-input" id="person_roles_1" name="person.roles" type="checkbox" value="{'id':1}"/>
    #   <label for="person_roles_2" class="form-check-label">admin</label>
    #   <input checked class="form-check-input" id="person_roles_2" name="person.roles" type="checkbox" value="{'id':2}"/>
    #   <label for="person_roles_3" class="form-check-label">guest</label>
    #   <input  class="form-check-input" id="person_roles_3" name="person.roles" type="checkbox" value="{'id':3}"/>
    # </div>

In addition to overriding C<checkbox> and C<label> to already contain value and state (if its checked or
not) information.   This special builder contains some additional methods of possible use, you should see
the documentation of L<Valiant::HTML::FormBuilder::Checkbox> for more.

If provided C<%options> is a hashref of the following optional values

=over 4

=item include_hidden

Defaults to whatever the method C<default_collection_checkbox_include_hidden> returns.  In the core code
this returns true.   If true will include a hidden field set to the name of the collection, which is uses
to indicate 'no checked values' since HTML will send nothing by default if there's no checked values.  It
will add this hidden field for each checkbox item to represent the 'none checked' value.

=item builder

Defaults to the values of C<DEFAULT_COLLECTION_CHECKBOX_BUILDER> method.  In core code this is
L<Valiant::HTML::FormBuilder::Checkbox>.  Overide if you need to make a custom builder (tricky work).

=back

=head2 collection_radio_buttons

    $fb->collection_radio_buttons($attribute, $collection, $value_method, $text_method, \%options);
    $fb->collection_radio_buttons($attribute, $collection, $value_method, $text_method);
    $fb->collection_radio_buttons($attribute, $collection);
    $fb->collection_radio_buttons($attribute, $collection, $value_method, $text_method, \%options, \&template);
    $fb->collection_radio_buttons($attribute, $collection, $value_method, $text_method, \&template);
    $fb->collection_radio_buttons($attribute, $collection, \&template);

A collection of radio buttons.  Similar to L<\collection_checkbox> but used one only one value is
permitted.  Example:

    $fb->collection_radio_buttons('state_id', $states_collection, id=>'name');
    # <input id="person_state_id_hidden" name="person.state_id" type="hidden" value=""/>
    # <label for="person_state_id_1">TX</label>
    # <input checked id="person_state_id_1_1" name="person.state_id" type="radio" value="1"/>
    # <label for="person_state_id_2">NY</label>
    # <input id="person_state_id_2_2" name="person.state_id" type="radio" value="2"/>
    # <label for="person_state_id_3">CA</label>
    # <input id="person_state_id_3_3" name="person.state_id" type="radio" value="3"/>

Please note when the $attribute is a collection value we add a hidden field to allow you to send a signal
to the form processor that this namespace contains no records.   Otherwise the form will just send 
nothing.  If you have a custom way to handle this you can disable the behavior if you wish by explicitly
setting include_hidden=>0

If you have special needs for formatting or layout you can override the default template with a coderef
that will receive a special type of formbuilder localized to the current value (an instance of
L<Valiant::HTML::FormBuilder::RadioButton>):

    $fb->collection_radio_buttons('state_id', $states_collection, id=>'name', sub {
      my $fb_states = shift;
      return  $fb_states->radio_button({class=>'form-check-input'}),
              $fb_states->label({class=>'form-check-label'});  
    });
    # <div id='person_state_id'>
    #   <input id="person_state_id_hidden" name="person.state_id" type="hidden" value=""/>
    #   <input checked class="form-check-input" id="person_state_id_1_1" name="person.state_id" type="radio" value="1"/>
    #   <label class="form-check-label" for="person_state_id_1">TX</label>
    #   <input class="form-check-input" id="person_state_id_2_2" name="person.state_id" type="radio" value="2"/>
    #   <label class="form-check-label" for="person_state_id_2">NY</label>
    #   <input class="form-check-input" id="person_state_id_3_3" name="person.state_id" type="radio" value="3"/>
    #   <label class="form-check-label" for="person_state_id_3">CA</label>
    # </div>

In addition to overriding C<radio_button> and C<label> to already contain value and state (if its checked or
not) information.   This special builder contains some additional methods of possible use, you should see
the documentation of L<Valiant::HTML::FormBuilder::RadioButton> for more.

Please note that the generated radio inputs will be wrapped in a containing C<div> tag.  You can change this tag
using the C<container_tag> option.  For example:

    $fb->collection_radio_buttons('state_id', $states_collection, id=>'name', +{container_tag=>'span'}, sub {
      my $fb_states = shift;
      return  $fb_states->radio_button({class=>'form-check-input'}),
              $fb_states->label({class=>'form-check-label'});  
    });

Here's all the values for the '%options' argument.  Any options that are not one of these will be passed to 
the container tag as html attributes:

=over4

=item checked_value

This is the current value of the attribute.  By default its the attribute value (via L<\tag_value_for_attribute>)
but you can override as needed.

=item include_hidden.

Defaults to true.  The value returned if you don't check one of the radio buttons.  

=item container_tag

The tag that contains the generated radio buttons.

=item builder

The builder subclass used in the radio input generator.

=back

=head2 radio_buttons

    $fb->radio_buttons($attribute, \@options, \%options);
    $fb->radio_buttons($attribute, \@options, \%options, \&template);
    $fb->radio_buttons($attribute, \@options);
    $fb->radio_buttons($attribute, \@options, \&template);

Similar to L</collection_radio_buttons> but takes an arrayref of label / values instead of a collection.
Useful when you have a list of radio buttons (like from an ENUM) but you don't want to list each radio
separately.  Example:

    $fb_profile->radio_buttons('status', [[Pending=>'pending'],[Active=>'active'],[Inactive=>'inactive']]);

    # <input id="person_profile_status_hidden" name="person.profile.status" type="hidden" value="">
    # <input id="person_profile_status_pending_pending" name="person.profile.status" type="radio" value="pending">
    # <label for="person_profile_status_pending">Pending</label>
    # <input checked="" id="person_profile_status_active_actie" name="person.profile.status" type="radio" value="active">
    # <label for="person_profile_status_active">Active</label>
    # <input id="person_profile_status_inactive_inactive" name="person.profile.status" type="radio" value="inactive">
    # <label for="person_profile_status_inactive">Inactive</label>

Supports using a template subroutine reference (like L</collection_radio_buttons>) when you need to be
fussy about style and positioning.

=head1 REMOTE FORMS

Remote forms are forms that submit via AJAX.  They are a bit more complex than regular forms because
they need to handle the AJAX response and update the DOM.  The form builder has some support for
remote forms but you will need to write some javascript to handle the response.  Here's an example

    $fb->remote_form_for(sub {
      my $fb = shift;
      return $fb->input('name'),
             $fb->submit('Save');
    }, +{url=>'/person', method=>'POST', remote=>1, success=>'alert("Saved")'});

See L<https://github.com/rails/jquery-ujs> for more information on how to handle the response.
You can also look at the example application for more examples of how this works.

When adding C<remote=1> to the options hashref we will automatically add the following attributes
to the form tag:

=over 4

=item data-replace

The ID of the element to replace with the response.  If not provided we will replace the form itself.

=back

B<NOTE> Remote support is evolving and may change in the future.  Please see the release notes for
changes.  I consider this a beta feature and will break compatibility if needed to fix bugs.  Its
also possible remote support might be moved to a separate module in the future.

=head1 HELPERS

The following methods don't make form controls but just useful methods to help you build your form.

=head2 escape_javascript

    $fb->escape_javascript($string);

Escapes a string so it can be used in a javascript string.  This is a wrapper around
The same method from L<Valiant::HTML::Util::TagBuilder/escape_javascript>.

Basically this escapes ' and " and \ and newlines and a few other neaten up so that you can
use a string as a javascript value.   Helps with injection attackes (but isn't everything
you need).


=head1 THEMING

You can add a method called C<default_theme> to your custom form builder sub class to return a hashref of default
attributes for the various form elements.  For example:

    package Example::FormBuilder;

    use Moo;
    use Example::Syntax;

    extends 'Valiant::HTML::FormBuilder';

    sub default_theme($self) {
      return +{ 
        errors_for => +{ class=>'invalid-feedback' },
        label => +{ class=>'form-label' },
        input => +{ class=>'form-control', errors_classes=>'is-invalid' },
        date_field => +{ class=>'form-control', errors_classes=>'is-invalid' },
        password => +{ class=>'form-control', errors_classes=>'is-invalid' },
        submit => +{ class=>'btn btn-lg btn-success btn-block' },
        button => +{ class=>'btn btn-lg btn-primary btn-block' },
        text_area => +{ class=>'form-control' },
        checkbox => +{ class=>'form-check-input', errors_classes=>'is-invalid' },
        collection_radio_buttons => +{errors_classes=>'is-invalid'},
        collection_checkbox => +{errors_classes=>'is-invalid'},
        collection_select => +{class=>'form-control', errors_classes=>'is-invalid'},
        select => +{class=>'form-control', errors_classes=>'is-invalid'},
        radio_buttons => +{errors_classes=>'is-invalid'},
        radio_button => +{class=>'custom-control-input', errors_classes=>'is-invalid'},
        model_errors => +{ class=>'alert alert-danger', role=>'alert' },
        form_has_errors => +{ class=>'alert alert-danger', role=>'alert' },
        attributes => {
          password => {
            password => { autocomplete=>'new-password' }
          }
        },
      };
    }

In the above example you set class defaults for most of the form elements based on the method name. In
addition you can set specific attributes for specific model attributes (as in the 'password' attribute
at the end of the last example. 

Then you you call a method like C<text_field> it will automatically add the default attributes for that
element.  For example:

    $fb->input('name');
    # <input class="form-control" id="person_name" name="person.name" type="text" value="">

If you are using a CSS framework you can use this to setup default (but overridable) classes for the various
form elements.  For example:

    $fb->input('name', {class=>'form-control form-control-lg'});
    # <input class="form-control form-control-lg" id="person_name" name="person.name" type="text" value="">

You can instead add a method called C<formbuilder_theme> to your view class which does the same thing but
allows you to make local view specific customatizations.  If you use both the formbuilder default theme is
added first and the view theme would override it.

Please note that you are not limited to passing HTML attributes here, you an pass anything that is a valid
attribute for the form field you are generating.

B<NOTE:> I'm still working out some of the rules around how we merge or override the various themes so if you 
go wild here you will need to follow the release notes for following versions carefully.   I consider theming
a beta feature subject to breaking changes if that's what I need to do to fix bugs or make it more flexible.

1;

=head1 SEE ALSO

L<Valiant>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
