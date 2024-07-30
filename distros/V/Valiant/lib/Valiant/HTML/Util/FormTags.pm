package Valiant::HTML::Util::FormTags;

use Moo;
use Valiant::HTML::Util::Collection;
use Scalar::Util;
use URI;

extends 'Valiant::HTML::Util::TagBuilder';

our $DEFAULT_BUTTON_CONTENT = 'Button';
our $DEFAULT_SUBMIT_TAG_VALUE = 'Save changes';
our $DEFAULT_OPTIONS_DELIM = '';

# private

sub _sanitize_to_id {
  my ($self, $value) = @_;
  return unless defined $value;
  $value =~ s/\]//g;
  $value =~ s/[^a-zA-Z0-9:.-]/_/g;
  return $value;
}

sub _humanize {
  my ($self, $value) = @_;
  return unless defined $value;
  $value =~s/_id$//; # remove trailing _id
  $value =~s/_/ /g;
  return ucfirst($value);
}

sub _prepend_block {
  my ($self, $block, @bits) = @_;
  return sub { return @bits, $block->(@_) };
}

# _merge_attrs does a smart merge of two hashrefs that represent HTML tag attributes.  This
# needs special processing since we need to merge 'data' and 'class' attributes with special
# rules.  For merging in general key/values in the second hashref will override those in the
# first (unless its a special attributes like 'data' or 'class'

sub _merge_attrs {
  my ($self, $attrs1, $attrs2, @list) = @_;
  my $overide = @list ? 0 : 1;
  @list = keys %{$attrs2||{}} unless @list;
  foreach my $key (@list) {
    next unless exists $attrs2->{$key}; # Don't create from @list, don't bother if not existing
    if( ($key eq 'data') || ($key eq 'aria')) {
      my $data1 = exists($attrs1->{$key}) ? $attrs1->{$key} : +{};
      my $data2 = exists($attrs2->{$key}) ? $attrs2->{$key} : +{};
      $attrs1->{$key} = +{ %$data1, %$data2 };
    } elsif($key eq 'class' || $key eq 'style') {
      my $data = $attrs2->{$key};
      my @data = ref($data) ? @$data : ($data);
      if(exists $attrs1->{$key}) {
        if(ref $attrs1->{$key}) {
          push @{$attrs1->{$key}}, @data;
        } else {
          $attrs1->{$key} = [$attrs1->{$key}, @data];
        }
      } else {
        $attrs1->{$key} = $attrs2->{$key} if($overide || !exists $attrs1->{$key});
      }
    } else {
      $attrs1->{$key} = $attrs2->{$key} if($overide || !exists $attrs1->{$key});
    }
  }
  return $attrs1;
}

# public

sub array_to_collection {
  my $self = shift;
  return Valiant::HTML::Util::Collection->new(@_);
}

sub button_tag {
  my ($self, $content, $attrs) = (shift(), undef, +{});

  $attrs = shift @_ if (ref($_[0])||'') eq 'HASH';
  $content = shift @_ if (ref($_[0])||'') eq 'CODE';
  $content = shift @_ unless defined $content;
  $content = $DEFAULT_BUTTON_CONTENT unless defined $content;
  $attrs = shift @_ if (ref($_[0])||'') eq 'HASH';
  $attrs = $self->_merge_attrs(+{name => 'button'}, $attrs);

  return $self->tags->button($attrs, $content);
}

sub checkbox_tag {
  my $self = shift;
  my $name = shift;
  my ($value, $checked, $attrs) = (1, 0, +{});
  $attrs = pop(@_) if (ref($_[-1])||'') eq 'HASH';
  $value = shift(@_) if defined $_[0];
  $checked = shift(@_) if defined $_[0];
  $attrs->{checked} = 1 if $checked;
  $attrs = $self->_merge_attrs(
    +{type => 'checkbox', name=>$name, id=>$self->_sanitize_to_id($name), value=>$value},
    $attrs
  );
  return $self->tags->input($attrs);
}

sub fieldset_tag {
  my $self = shift;
  my ($legend, $attrs, $content) = (undef, +{}, undef);
  $content = pop @_; # Required
  $attrs = pop @_ if (ref($_[-1])||'') eq 'HASH';
  $legend = shift @_ if @_;

  my $block = $legend ? $self->_prepend_block($content, $self->legend_tag($legend)) : $content;

  return $self->tags->fieldset($attrs, $block);
}

# $tb->form_tag($url_info, \%attrs, \&content);
# $tb->form_tag($url_info, \&content);

sub form_tag {
  my $self = shift;
  my $content = pop @_; # required
  my $attrs = ref($_[-1])||'' eq 'HASH' ? pop(@_) : +{};
  my $url_info = @_ ? shift : undef;
  $attrs = $self->_process_form_attrs($url_info, $attrs);
  $content = $self->_process_content($content, $attrs);

  return $self->tags->form($attrs, $content);
}

sub _process_form_attrs {
  my ($self, $url_info, $attrs) = @_;
  $attrs->{action} = $url_info if $url_info;
  $attrs->{method} ||= 'post';
  $attrs->{'accept-charset'} ||= 'UTF-8';
  $attrs->{enctype} ||= 'application/x-www-form-urlencoded';
  $self->_process_method($attrs);

  return $attrs;
}

sub _process_method {
  my ($self, $attrs) = @_;
  return unless delete $attrs->{tunneled_method};
  return if (lc($attrs->{method}) eq 'post') || (lc($attrs->{method}) eq 'get');

  my $uri = Scalar::Util::blessed($attrs->{action}||'') ? $attrs->{action} : URI->new( $attrs->{action}||'');
  my $params = $uri->query_form_hash;

  $params->{'x-tunneled-method'} = $attrs->{method};
  $uri->query_form($params);
  $attrs->{action} = $uri;
  $attrs->{method} = 'post';
}

sub _process_content {
  my ($self, $content, $attrs) = @_;
  return $content unless exists $attrs->{csrf_token};
  $attrs->{data}{csrf_token} = delete $attrs->{csrf_token};
  return $self->_prepend_block($content, $self->hidden_tag('csrf_token', $attrs->{data}{csrf_token}));
}

sub label_tag {
  my ($self, $name) = (shift(), shift());
  my ($content, $attrs) = ($self->_humanize($name), +{});

  $content = pop @_ if (ref($_[-1])||'') eq 'CODE';
  $attrs =  pop @_ if (ref($_[-1])||'') eq 'HASH';
  $content = shift if @_;
  $attrs->{for} ||= $self->_sanitize_to_id($name) if $name;

  return $self->tags->label($attrs, $content);
}

sub text_area_tag {
  my $self = shift @_;
  my $name = shift @_;
  my $attrs = (ref($_[-1])||'') eq 'HASH' ? pop @_ : +{};
  my $content = @_ ? shift @_ : '';

  $attrs = $self->_merge_attrs(+{ name=>$name, id=>"@{[ $self->_sanitize_to_id($name) ]}" }, $attrs);
  return $self->tags->textarea($attrs, $content);
}

sub input_tag {
  my $self = shift;
  my ($name, $value, $attrs) = (undef, undef, +{});
  $attrs = pop @_ if (ref($_[-1])||'') eq 'HASH';
  $name = shift @_ if @_;
  $value = shift @_ if @_;

  $attrs = $self->_merge_attrs(+{type => "text"}, $attrs);
  $attrs = $self->_merge_attrs(+{name => $name}, $attrs) if defined($name);
  $attrs = $self->_merge_attrs(+{value => $value}, $attrs) if defined($value);
  $attrs->{id} = $self->_sanitize_to_id($attrs->{name}) if exists($attrs->{name}) && defined($attrs->{name}) && !exists($attrs->{id});

  return $self->tags->input($attrs);
}

sub radio_button_tag {
  my $self = shift;
  my ($name, $value) = (shift @_, shift @_);
  my $attrs = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  my $checked = @_ ? shift(@_) : 0;

  $attrs = $self->_merge_attrs(+{
    type=>'radio', 
    name=>$name, 
    value=>$value, 
    id=>"@{[ $self->_sanitize_to_id($name) ]}_@{[ $self->_sanitize_to_id($value) ]}"
  }, $attrs);
  $attrs->{checked} = 'checked' if $checked;

  return $self->input_tag($attrs);
}

sub password_tag {
  my $self = shift;
  my $attrs = (ref($_[-1])||'' eq 'HASH') ? pop : +{};
  $attrs = $self->_merge_attrs(+{ type=>'password' }, $attrs);
  return $self->input_tag(@_, $attrs);
}

sub hidden_tag {
  my $self = shift;
  my $attrs = (ref($_[-1])||'' eq 'HASH') ? pop : +{};
  $attrs = $self->_merge_attrs(+{ type=>'hidden' }, $attrs);
  return $self->input_tag(@_, $attrs);
}

sub submit_tag {
  my $self = shift;
  my ($value, $attrs);
  $attrs = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $value = @_ ? shift(@_) : $DEFAULT_SUBMIT_TAG_VALUE;

  $attrs = $self->_merge_attrs(+{ type=>'submit', name=>'commit', value=>$value }, $attrs);
  return $self->input_tag($attrs);
}

# legend_tag $value, \%attrs
# legend_tag \%attrs, \&block

sub legend_tag {
  my $self = shift;
  my $content = (ref($_[-1])||'') eq 'CODE' ? pop(@_) : shift(@_);
  my $attrs = @_ ? shift(@_) : +{};
  return $self->tags->legend($attrs, $content)
}

sub option_tag {
  my $self = shift;
  my ($text, $attrs) = (@_, +{});
  $attrs->{value} = $text unless exists $attrs->{value};
  return $self->tags->option($attrs, $text);
}

sub select_tag {
  my ($self, $name) = (shift(), shift());
  my $attrs = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  my $option_tags = @_ ? shift(@_) : "";
  my $html_name = $name;
  if($attrs->{multiple}) {
    $html_name = "${name}[]" unless ( ($name =~ m/\[\]$/) || ($name =~ m/\[\]\.\w+$/) );
  }

  my $include_hidden = exists($attrs->{include_hidden}) ? delete($attrs->{include_hidden}) : 1;
  if(my $include_blank = delete $attrs->{include_blank}) {
    my $options_for_blank_options_tag = +{ value => '' };
    if($include_blank eq '1') {
      $include_blank = '';
      $options_for_blank_options_tag->{label} = ' ';
    }
    my $blank_options = $self->content_tag('option', $include_blank, $options_for_blank_options_tag);
    $option_tags = $self->join_tags($blank_options, $option_tags);
  }
  if(my $prompt = delete $attrs->{prompt}) {
      my $prompt = $self->content_tag('option', $prompt, +{value=>''});
      $option_tags = $self->join_tags($prompt, $option_tags);
  }

  $attrs = $self->_merge_attrs(+{ name=>$html_name, id=>"@{[ $self->_sanitize_to_id($name) ]}" }, $attrs);
  my $select_tag = $self->content_tag('select', $option_tags, $attrs);

  if($attrs->{multiple} && $include_hidden) {
    my $hidden = $self->hidden_tag($html_name, '', +{id=>$attrs->{id}.'_hidden', value=>1});
    $select_tag = $self->join_tags($hidden, $select_tag, $attrs);
  }
  return $select_tag;
}

sub options_for_select {
  my ($self, $options_proto) = (shift(), shift());
  return $options_proto unless( (ref($options_proto)||'') eq 'ARRAY');
  my @options = $self->_normalize_options_for_select($options_proto);

  my $attrs_proto = $_[0] ? shift(@_) : [];
  my (@selected_values, @disabled_values,  %global_attributes) = ();
  if( (ref($attrs_proto)||'') eq 'ARRAY') {
    @selected_values = @$attrs_proto;
  } elsif( (ref($attrs_proto)||'') eq 'HASH') {
    @selected_values = @{delete $attrs_proto->{selected}} if exists($attrs_proto->{selected});
    @disabled_values = @{delete $attrs_proto->{disabled}} if exists($attrs_proto->{disabled});
    %global_attributes = %{$attrs_proto};
  } else {
    @selected_values = ($attrs_proto);
  }
  
  my %selected_lookup = @selected_values ? (map { $_=>1 } @selected_values) : ();
  my %disabled_lookup = @disabled_values ? (map { $_=>1 } @disabled_values) : ();
  my (@options_for_select) = map {
    $self->option_for_select($_, \%selected_lookup, \%disabled_lookup, \%global_attributes);
    } @options;

  return $self->join_tags(@options_for_select);
}

sub _normalize_options_for_select {
  my ($self, $options_proto) = (shift(), shift());
  my @options = map {
    push @$_, +{} unless (ref($_->[-1])||'') eq 'HASH';
    unshift @$_, $_->[0] unless scalar(@$_) == 3;
    $_;
  } map {
    (ref($_)||'') eq 'ARRAY' ? $_ : [$_, $_, +{}];
  } @$options_proto;
  return @options;
}

sub option_for_select {
  my ($self, $option_info, $selected, $disabled, $attrs) = @_;
  my %attrs = (value=>$option_info->[1], %{$option_info->[2]}, %$attrs);
  $attrs{selected} = 'selected' if $selected->{$option_info->[1]};
  $attrs{disabled} = 'disabled' if $disabled->{$option_info->[1]};

  return $self->option_tag($option_info->[0], \%attrs);
}

sub option_html_attributes { return +{} }

sub options_from_collection_for_select {
  my ($self, $collection, $value_method, $label_method, $selected_proto) = (@_);

  my @options = ();
  my @selected = ();
  my @disabled = ();
  my %global_attributes = ();

  @disabled = @{ delete($selected_proto->{disabled})||[] } if (ref($selected_proto)||'') eq 'HASH';
  @selected = @{ delete($selected_proto->{selected})||[] } if (ref($selected_proto)||'') eq 'HASH';
  %global_attributes = %{$selected_proto} if (ref($selected_proto)||'') eq 'HASH';
  @selected = @$selected_proto if (ref($selected_proto)||'') eq 'ARRAY';
  @selected = ($selected_proto) if ((ref(\$selected_proto)||'') eq 'SCALAR') && defined($selected_proto);

  while(my $item = $collection->next) {
    push @options, [ $self->field_value($item,$label_method),  $self->field_value($item, $value_method), $self->option_html_attributes($item) ];
    push @selected, $item->$value_method if ((ref($selected_proto)||'') eq 'CODE') && $selected_proto->($item);
  }

  $collection->reset if $collection->can('reset');
  return $self->options_for_select(\@options, +{ selected=>\@selected, disabled=>\@disabled, %global_attributes});
}

my %_sanitized_name_cache = ();
sub _sanitize {
  my ($self, $value) = (shift(), shift());
  return unless defined($value);
  return $_sanitized_name_cache{$value} if exists $_sanitized_name_cache{$value};

  my $original_value = $value;
  $value =~ s/\]\[|[^a-zA-Z0-9:-]/_/g;
  $value =~s/_$//;
  $_sanitized_name_cache{$original_value} = $value;
  return $value;
}

sub field_value {
  my ($self, $model, $attribute) = @_;
  return $model->read_attribute_for_html($attribute) if $model->can('read_attribute_for_html');
  return $model->$attribute if $model->can($attribute);
  return ''; # TODO should look at $formbuilder->options->{allow_method_names_outside_object}
}

sub field_id {
  my ($self, $model_or_model_name, $attribute, $options, @extra) = @_;
  my $model_name = Scalar::Util::blessed($model_or_model_name) ? 
    $model_or_model_name->model_name->singular : 
      $model_or_model_name;

  my $sanitized_object_name = $self->_sanitize($model_name);
  my $id = exists($options->{namespace}) ? $options->{namespace} . '_' : '';

  if($sanitized_object_name) {
    $id .= exists($options->{index}) ?
      "@{[ $sanitized_object_name ]}_@{[ $options->{index} ]}_${attribute}" :
      "@{[ $sanitized_object_name ]}_${attribute}";
  } else {
    $id .= $attribute;
  }

  $id = join('_', $id, @extra) if scalar @extra;
  return $id;
}

sub field_name {
  my ($self, $model_name, $attribute, $options, @names) = @_;
  my $names = @names ? join("", map { "[$_]" } @names) : '';

  my $name;
  if($model_name) {
    $name = exists($options->{index}) ?
      "@{[ $model_name ]}\[@{[ $options->{index}]}\].${attribute}${names}" :
      "@{[ $model_name ]}.${attribute}${names}";
  } else {
    $name = "${attribute}${names}";
  }
  $name .= '[]' if $options->{multiple};

  return $name;
}

1;

=head1 NAME



Valiant::HTML::Util::FormTags - HTML Form Tags

=head1 SYNOPSIS

    my $view = Valiant::HTML::Util::View->new(aaa => 1,bbb => 2);
    my $tb = Valiant::HTML::Util::FormTags->new(view => $view);

=head1 DESCRIPTION

Functions that generate HTML tags, specifically those around HTML forms.   Not all
HTML tags are in this library, this focuses on things that would be useful for building
HTML forms. In general this is a support libary for L<Valiant::HTML::FormBuilder> but
there's nothing preventing you from using these stand alone, particularly when you have
very complex form layout needs.

Requiers a 'view' or template object that supports methods for created 'safe' strings that
are properly marked as safe for HTML display.

=head1 ATTRIBUTES

This class has the following initialization attributes

=head2 view

Object, Required.  This should be an object that provides methods for creating escaped
strings for HTML display.  Many template systems provide a way to mark strings as safe
for display, such as L<Mojo::Template>.  You will need to add the following proxy methods
to your view / template to adapt it for use in creating safe strings.

=over

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

=item read_attribute_for_html

Given an attribute name return the value that the view has defined for it.  

=item attribute_exists_for_html

Given an attribute name return true if the view has defined it.

=back

Both C<raw>, C<safe> and C<safe_concat> should return a 'tagged' object which is specific to your view or
template system. However this object must 'stringify' to the safe version of the string to be displayed.  See
L<Valiant::HTML::SafeString> for example API.  We use L<Valiant::HTML::SafeString> internally to provide
safe escaping if you're view doesn't do automatic escaping, as many older template systems like Template
Toolkit.

See L<Valiant::HTML::Util::View> for a simple view object that provides these methods.

=head1 INHERITANCE

This class extends L<Valiant::HTML::Util::TagBuilder> and inherits all methods from that class.

=head1 METHODS

The following instance methods are supported by this class

=head2 button_tag

    $tb->button_tag($content_string, \%attrs)
    $tb->button_tag($content_string)
    $tb->button_tag(\%attrs, \&content_code_block)
    $tb->button_tag(\&content_code_block)

Creates a button element that defines a submit button, reset button or a generic button which 
can be used in JavaScript, for example. You can use the button tag as a regular submit tag but
it isn't supported in legacy browsers. However, the button tag does allow for richer labels
such as images and emphasis, so this helper will also accept a block. By default, it will create
a button tag with type submit, if type is not given.  HTML attribute C<name> defaults to 
'Button' if not supplied.  Inner content also defaults to 'Button' if not supplied.

=head2 checkbox_tag

    $tb->checkbox_tag($name)
    $tb->checkbox_tag($name, $value)
    $tb->checkbox_tag($name, $value, $checked)
    $tb->checkbox_tag($name, \%attrs)
    $tb->checkbox_tag($name, $value, \%attrs)
    $tb->checkbox_tag($name, $value, $checked, \%attrs)

Creates a check box form input tag.  C<id> will be generated from $name if not passed in \%attrs. C<value>
attribute will default to '1' and the control is unchecked by default.

=head2 fieldset_tag

    $tb->fieldset_tag(\%content_block)
    $tb->fieldset_tag(\%attrs, \%content_block)
    $tb->fieldset_tag($legend, \%attrs, \%content_block)
    $tb->fieldset_tag($legend, \%content_block)

Create a C<fieldset> with inner content.  Example:

    $tb->fieldset_tag(sub {
      $tb->button_tag('username');
    });

    # <fieldset><button name="button">username</button></fieldset>
  
    $tb->fieldset_tag('Info', sub {
      $tb->button_tag('username');
    });

    # <fieldset><legend>Info</legend><button name="button">username</button></fieldset>

=head2 legend_tag

    $tb->legend_tag($legend, \%html_attrs);
    $tb->legend_tag($legend);
    $tb->legend_tag(\%html_attrs, \&content_block);
    $tb->legend_tag(\&content_block);

Create an HTML form legend tag and content.  Examples:

    $tb->legend_tag('test', +{class=>'foo'});
    # <legend class="foo">test</legend>

    $tb->legend_tag('test');
    # <legend>test</legend>

    $tb->legend_tag({class=>'foo'}, sub { 'test' });
    # <legend class="foo">test</legend>

    $tb->legend_tag(sub { 'test' });
    # <legend>test</legend>

=head2 form_tag

    $tb->form_tag('/signup', \%attrs, \&content)
    $tb->form_tag(\@args, \%attrs, \&content)

Create a form tag with inner content.  Example:

    $tb->form_tag('/user', +{ class=>'form' }, sub {
      $tb->checkbox_tag('person[1]username', +{class=>'aaa'});
    });

Produces:

    <form accept-charset="UTF-8" action="/user" class="form" method="POST">
      <input class="aaa" id="person_1username" name="person[1]username" type="checkbox" value="1"/>
    </form>';

In general C<\%attrs> are expected to be HTML attributes.  However, the following special attributes
are supported:

=over 4

=item csrf_token

If set, will use the value given to generate a hidden input tag with the name C<csrf_token> and the value.
Example:

    my $csrf_token = "1234567890";
    $tb->form_tag('/user', +{ csrf_token=>$csrf_token }, sub {
      $tb->checkbox_tag('username', +{class=>'aaa'});
    });

Produces:
  
    <form accept-charset="UTF-8" action="/user" class="form" method="POST">
      <input class="aaa" id="username" name="username" type="checkbox" value="1"/>
      <input name="csrf_token" type="hidden" value="1234567890"/>
    </form>';

=item tunneled_method

If set, will change any C<method> attribute to C<POST> and add a query parameter to
the action URL with the name C<_method> and the value of the C<method> attribute.  Example:

    $tb->form_tag('/user', +{ method=>'DELETE', tunneled_method=>1 }, sub {
      $tb->checkbox_tag('username', +{class=>'aaa'});
    });

Produces:
  
    <form accept-charset="UTF-8" action="/user?_method=DELETE" class="form" method="POST">
      <input class="aaa" id="username" name="username" type="checkbox" value="1"/>
    </form>';

Useful for browsers that don't support C<PUT> or C<DELETE> methods in forms (which is most of them).

=back

These special attributes will be removed from the attributes list before generating the HTML tag.

=head2 label_tag

    $tb->label_tag($name, $content, \%attrs);
    $tb->label_tag($name, $content);
    $tb->label_tag($name, \%attrs, \&content);
    $tb->label_tag($name, \&content);

Create a label tag where $name is set to the C<for> attribute.   Can contain string or block contents.  Label
contents default to something based on $name;

    $tb->label_tag('user_name', "User", +{id=>'userlabel'});    # <label id='userlabel' for='user_name'>User</label>
    $tb->label_tag('user_name');                                # <label for='user_name'>User Name</label>

Example with block content:

    $tb->label_tag('user_name', sub {
      'User Name Active',
      $tb->checkbox_tag('active', 'yes', 1);
    });

    <label for='user_name'>
      User Name Active<input checked  value="yes" id="user_name" name="user_name" type="checkbox"/>
    </label>

Produce a label tag, often linked to an input tag.   Can accept a block coderef.  Examples:

=head2 radio_button_tag

    $tb->radio_button_tag($name, $value)
    $tb->radio_button_tag($name, $value, $checked)
    $tb->radio_button_tag($name, $value, $checked, \%attrs)
    $tb->radio_button_tag($name, $value, \%attrs)

Creates a radio button; use groups of radio buttons named the same to allow users to select from a
group of options. Examples:

    $tb->radio_button_tag('role', 'admin', 0, +{ class=>'radio' });
    # <input class="radio" id="role_admin" name="role" type="radio" value="admin"/>

    $tb->radio_button_tag('role', 'user', 1, +{ class=>'radio' });
    # <input checked class="radio" id="role_user" name="role" type="radio" value="user"/>'

=head2 option_tag

    $tb->option_tag($text, \%attributes)
    $tb->option_tag($text)

Create a single HTML option.  C<value> attribute is inferred from $text if not in \%attributes.  Examples:

    $tb->option_tag('test', +{class=>'foo', value=>'100'});
    # <option class="foo" value="100">test</option>

    $tb->option_tag('test'):
    #<option value="test">test</option>

=head2 text_area_tag

    $tb->text_area_tag($name, \%attrs)
    $tb->text_area_tag($name, $content, \%attrs)

Create a named text_area form field. Examples:

    $tb->text_area_tag("user", "hello", +{ class=>'foo' });
    # <textarea class="foo" id="user" name="user">hello</textarea>

    $tb->text_area_tag("user",  +{ class=>'foo' });
    # <textarea class="foo" id="user" name="user"></textarea>

=head2 input_tag

    $tb->input_tag($name, $value, \%attrs)
    $tb->input_tag($name, $value)
    $tb->input_tag($name)
    $tb->input_tag($name, \%attrs)
    $tb->input_tag(\%attrs)

Create a HTML input tag. If $name and/or $value are set, they are used to populate the 'name' and
'value' attributes of the C<input>.  Anything passed in the \%attrs hashref overrides.  Examples:

    $tb->input_tag('username', 'jjn', +{class=>'aaa'});
    # <input class="aaa" id="username" name="username" type="text" value="jjn"/>

    $tb->input_tag('username', 'jjn');
    # <input id="username" name="username" type="text" value="jjn"/>

    $tb->input_tag('username');
    # <input id="username" name="username" type="text"/>

    $tb->input_tag('username', +{class=>'foo'});
    # <input class="foo" id="username" name="username" type="text"/>

    $tb->input_tag(+{class=>'foo'});
    # <input class="foo" type="text"/>

=head2 password_tag

Creates an password input tag with the given type.  Example:

    $tb->password_tag('password', +{class=>'foo'});
    # <input class="foo" id="password" name="password" type="password"/>

=head2 hidden_tag

Creates an input tag with the given type.  Example:

    $tb->hidden_tag('user_id', 100, +{class=>'foo'});
    # <input class="foo" id="user_id" name="user_id" type="hidden" value="100"/>
    
=head2 submit_tag

    $tb->submit_tag
    $tb->submit_tag($value)
    $tb->submit_tag(\%attrs)
    $tb->submit_tag \($value, \%attrs)

Create a submit tag.  Examples:

    $tb->submit_tag;
    # <input id="commit" name="commit" type="submit" value="Save changes"/>

    $tb->submit_tag('person');
    # <input id="commit" name="commit" type="submit" value="person"/>

    $tb->submit_tag('Save', +{name=>'person'});
    # <input id="person" name="person" type="submit" value="Save"/>

    $tb->submit_tag(+{class=>'person'});
    # <input class="person" id="commit" name="commit" type="submit" value="Save changes"/>

=head2 select_tag

    $tb->select_tag($name, $option_tags, \%attrs)
    $tb->select_tag($name, $option_tags)
    $tb->select_tag($name, \%attrs)

Create a select tag group with options.  Examples:

    $tb->select_tag("people", raw("<option>David</option>"));
    # <select id="people" name="people"><option>David</option></select>

    $tb->select_tag("people", raw("<option>David</option>"), +{include_blank=>1});
    # <select id="people" name="people"><option label=" " value=""></option><option>David</option></select>

    $tb->select_tag("people", raw("<option>David</option>"), +{include_blank=>'empty'});
    # <select id="people" name="people"><option value="">empty</option><option>David</option></select>
      
    $tb->select_tag("prompt", raw("<option>David-prompt</option>"), +{prompt=>'empty-prompt', class=>'foo'});
    # <select class="foo" id="prompt" name="prompt"><option value="">empty-prompt</option><option>David-prompt</option></select>

=head2 options_for_select

    $tb->options_for_select([$value1, $value2, ...], $selected_value)
    $tb->options_for_select([$value1, $value2, ...], \@selected_values)
    $tb->options_for_select([$value1, $value2, ...], +{ selected => $selected_value, disabled => \@disabled_values, %global_options_attributes })
    $tb->options_for_select([ [$label, $value], [$label, $value, \%attrs], ...])

Create a string of HTML option tags suitable for using with C<select_tag>.  Accepts two arguments the
first of whuch is required.  The first argument is an arrayref of values used for the options. Each value
can be one of a scalar (in which case the value is used as both the text label for the option as well as 
its actual value attribute) or a arrayref where the first item is the option label, the second is the value
and an option third is a hashref used to add custom attributes to the option.

The second (optional) argument lets you set which options are marked C<selected> and possible C<disabled>
If the second argument is a scalar value then it is used to mark that value as selected.  If its an arrayref
then all matching values are selected.  If its a hashref we look for a key C<selected> and key <disabled>
and expect those (if exists) to be an arrayref of matching values.  Any additional keys in the hash will be
passed as global HTML attributes to the options.  Examples:

    $tb->options_for_select(['A','B','C']);
    # <option value="A">A</option>
    # <option value="B">B</option>
    # <option value="C">C</option>

    $tb->options_for_select(['A','B','C'], 'B');
    # <option value="A">A</option>
    # <option selected value="B">B</option>
    # <option value="C">C</option>

    $tb->options_for_select(['A','B','C'], ['A', 'C']);
    #<option selected value="A">A</option>
    #<option value="B">B</option>
    #<option selected value="C">C</option>

    $tb->options_for_select(['A','B','C'], ['A', 'C']);
    # <option selected value="A">A</option>
    # <option value="B">B</option>
    # <option selected value="C">C</option>

    $tb->options_for_select([[a=>'A'],[b=>'B'], [c=>'C']]);
    # <option value="A">a</option>
    # <option value="B">b</option>
    # <option value="C">c</option>

    $tb->options_for_select([[a=>'A'],[b=>'B'], [c=>'C']], 'B');
    # <option value="A">a</option>
    # <option selected value="B">b</option>
    # <option value="C">c</option>

    $tb->options_for_select(['A',[b=>'B', {class=>'foo'}], [c=>'C']], ['A','C']);
    # <option selected value="A">A</option>
    # <option class="foo" value="B">b</option>
    # <option selected value="C">c</option>

    $tb->options_for_select(['A','B','C'], +{selected=>['A','C'], disabled=>['B'], class=>'foo'});
    # <option class="foo" selected value="A">A</option>
    # <option class="foo" disabled value="B">B</option>
    # <option class="foo" selected value="C">C</option>

This function is useful with the C<select_tag>:

    $tb->select_tag("state", options_for_select(['A','B','C'], 'A'), +{include_blank=>1});
    # <select id="state" name="state">
    #  <option label=" " value=""></option>
    #  <option selected value="A">A</option>
    #  <option value="B">B</option>
    #  <option value="C">C</option>
    # </select>

Please note that since C<options_for_select> returns a L<Valiant::HTML::SafeString> or safe string object
as supported by your view/template system of choice you don't need to add any additional escaping.

=head2 options_from_collection_for_select

Given a collection (an object that does the interface defined by L<Valiant::HTML::Util::Collection> return 
a string of options suitable for C<select_tag>.  Optionally you can pass additional arguments, like with
C<options_for_select> to mark individual options as selected, disabled and to pass additional HTML attributes.
Examples:

    my $collection = Valiant::HTML::Util::Collection->new([label=>'value'], [A=>'a'], [B=>'b'], [C=>'c']);

    $tb->options_from_collection_for_select($collection, 'value', 'label');
    # <option value="value">label</option>
    # <option value="a">A</option>
    # <option value="b">B</option>
    # <option value="c">C</option>

    $tb->options_from_collection_for_select($collection, 'value', 'label', 'a');
    # <option value="value">label</option>
    # <option selected value="a">A</option>
    # <option value="b">B</option>
    # <option value="c">C</option>

    $tb->options_from_collection_for_select($collection, 'value', 'label', ['a', 'c']);
    # <option value="value">label</option>
    # <option selected value="a">A</option>
    # <option value="b">B</option>
    # <option selected value="c">C</option>

    $tb->options_from_collection_for_select($collection, 'value', 'label', +{selected=>['a','c'], disabled=>['b'], class=>'foo'})
    # <option class="foo" value="value">label</option>
    # <option class="foo" selected value="a">A</option>
    # <option class="foo" disabled value="b">B</option>
    # <option class="foo" selected value="c">C</option>

If you have a properly formed array you can use the C<array_to_collection> helper method:

    my $collection = $tb->array_to_collection([label=>'value'], [A=>'a'], [B=>'b'], [C=>'c']);
    $tb->options_from_collection_for_select($collection, 'value', 'label');

Additionally you can pass a coderef for dynamic selecting.  Example:

    $tb->options_from_collection_for_select($collection, 'value', 'label', sub { shift->value eq 'a'} );
    # <option value="value">label</option>
    # <option selected value="a">A</option>
    # <option value="b">B</option>
    # <option value="c">C</option>

The collection object must at minimum provide a method C<next> which returns the next object in the collection.
This method C<next> should return false when all the item objects have been iterated thru in turn. Optionally
you can provide a C<reset> method which will be called to return the collection to the first index.

You can see L<Valiant::HTML::Util::Collection> source for example minimal code.

=head2 array_to_collection

Given a array of option labels as described above, create a collection

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

1;
