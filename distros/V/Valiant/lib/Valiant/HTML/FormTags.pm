package Valiant::HTML::FormTags;

use warnings;
use strict;
use Exporter 'import'; # gives you Exporter's import() method directly
use Valiant::HTML::TagBuilder ':all';
use Valiant::HTML::Util::Collection;
use Scalar::Util (); 
use Module::Runtime ();

our @EXPORT_OK = qw(
  button_tag checkbox_tag fieldset_tag form_tag label_tag radio_button_tag input_tag option_tag
  text_area_tag submit_tag password_tag hidden_tag select_tag options_for_select _merge_attrs
  options_from_collection_for_select field_value legend_tag
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $DEFAULT_BUTTON_CONTENT = 'Button';
our $DEFAULT_SUBMIT_TAG_VALUE = 'Save changes';
our $DEFAULT_OPTIONS_DELIM = '';

# _merge_attrs does a smart merge of two hashrefs that represent HTML tag attributes.  This
# needs special processing since we need to merge 'data' and 'class' attributes with special
# rules.  For merging in general key/values in the second hashref will override those in the
# first (unless its a special attributes like 'data' or 'class'

sub _merge_attrs {
  my ($attrs1, $attrs2) = @_;
  foreach my $key (keys %{$attrs2||{}}) {
    if( ($key eq 'data') || ($key eq 'aria')) {
      my $data1 = exists($attrs1->{$key}) ? $attrs1->{$key} : +{};
      my $data2 = exists($attrs2->{$key}) ? $attrs2->{$key} : +{};
      $attrs1->{$key} = +{ %$data1, %$data2 };
    } elsif($key eq 'class') {
      my $data = $attrs2->{$key};
      my @data = ref($data) ? @$data : ($data);
      if(exists $attrs1->{$key}) {
        if(ref $attrs1->{$key}) {
          push @{$attrs1->{$key}}, @data;
        } else {
          $attrs1->{$key} = [$attrs1->{$key}, @data];
        }
      } else {
        $attrs1->{$key} = $attrs2->{$key};
      }
    } else {
      $attrs1->{$key} = $attrs2->{$key};
    }
  }
  return $attrs1;
}

# Given a string, return a version of it suitable for use in an 'id' HTML attribute.

sub _sanitize_to_id {
  my $value = shift;
  return unless defined $value;
  $value =~ s/\]//g;
  $value =~ s/[^a-zA-Z0-9:.-]/_/g;
  return $value;
}

sub _prepend_block {
  my ($block, @bits) = @_;
  return sub { return @bits, $block->() };
}

sub _humanize {
  my $value = shift;
  $value =~s/_id$//; # remove trailing _id
  $value =~s/_/ /g;
  return ucfirst($value);
}

sub button_tag {
  my ($content, $attrs) = (undef, +{});

  $attrs = shift @_ if (ref($_[0])||'') eq 'HASH';
  $content = shift @_ if (ref($_[0])||'') eq 'CODE';
  $content = shift @_ unless defined $content;
  $attrs = shift @_ if (ref($_[0])||'') eq 'HASH';
  $attrs = _merge_attrs(+{name => 'button'}, $attrs);

  return ref($content) ? content_tag('button', $attrs, $content) : content_tag('button', ($content||$DEFAULT_BUTTON_CONTENT), $attrs)
}

sub checkbox_tag {
  my $name = shift;
  my ($value, $checked, $attrs) = (1, 0, +{});
  $attrs = pop(@_) if (ref($_[-1])||'') eq 'HASH';
  $value = shift(@_) if defined $_[0];
  $checked = shift(@_) if defined $_[0];
  $attrs->{checked} = 1 if $checked;
  $attrs = _merge_attrs(+{type => 'checkbox', name=>$name, id=>_sanitize_to_id($name), value=>$value}, $attrs);
  return tag('input', $attrs);
}

sub fieldset_tag {
  my ($legend, $attrs, $content) = (undef, +{}, undef);
  $content = pop @_; # Required
  $attrs = pop @_ if (ref($_[-1])||'') eq 'HASH';
  $legend = shift @_ if @_;

  my $block = $legend ? _prepend_block($content, content_tag('legend', $legend)) : $content;

  return content_tag('fieldset', $attrs, $block);
}

sub form_tag {
  my $content = pop @_; # required
  my $attrs = ref($_[-1])||'' eq 'HASH' ? pop(@_) : +{};
  my $url_info = @_ ? shift : undef;
  $attrs = _process_form_attrs($url_info, $attrs);
  return content_tag('form', $attrs, $content);
}

sub _process_form_attrs {
  my ($url_info, $attrs) = @_;
  $attrs->{action} = $url_info if $url_info;
  $attrs->{method} ||= 'post';
  $attrs->{'accept-charset'} ||= 'UTF-8';
  return $attrs;
}

sub label_tag {
  my $name = shift;
  my ($content, $attrs) = (_humanize($name), +{});

  $content = pop @_ if (ref($_[-1])||'') eq 'CODE';
  $attrs =  pop @_ if (ref($_[-1])||'') eq 'HASH';
  $content = shift if @_;
  $attrs->{for} ||= _sanitize_to_id($name) if $name;
  
  return (ref($content)||'') eq 'CODE' ? content_tag('label', $attrs, $content) : content_tag('label', $content, $attrs)
}

sub radio_button_tag {
  my ($name, $value) = (shift @_, shift @_);
  my $attrs = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  my $checked = @_ ? shift(@_) : 0;
  $attrs = _merge_attrs(+{type=>'radio', name=>$name, value=>$value, id=>"@{[ _sanitize_to_id($name) ]}_@{[ _sanitize_to_id($value) ]}" }, $attrs);
  $attrs->{checked} = 'checked' if $checked;
  return tag('input', $attrs);
}

sub option_tag {
  my ($text, $attrs) = (@_, +{});
  $attrs->{value} = $text unless exists $attrs->{value};
  return content_tag('option', $text, $attrs);  
}

sub text_area_tag {
  my $name = shift @_;
  my $attrs = (ref($_[-1])||'') eq 'HASH' ? pop @_ : +{};
  my $content = @_ ? shift @_ : '';

  $attrs = _merge_attrs(+{ name=>$name, id=>"@{[ _sanitize_to_id($name) ]}" }, $attrs);
  return content_tag('textarea', $content, $attrs);
}

sub input_tag {
  my ($name, $value, $attrs) = (undef, undef, +{});
  $attrs = pop @_ if (ref($_[-1])||'') eq 'HASH';
  $name = shift @_ if @_;
  $value = shift @_ if @_;

  $attrs = _merge_attrs(+{type => "text"}, $attrs);
  $attrs = _merge_attrs(+{name => $name}, $attrs) if defined($name);
  $attrs = _merge_attrs(+{value => $value}, $attrs) if defined($value);
  $attrs->{id} = _sanitize_to_id($attrs->{name}) if exists($attrs->{name}) && defined($attrs->{name}) && !exists($attrs->{id});

  return tag('input', $attrs);
}

sub password_tag {
  my $attrs = (ref($_[-1])||'' eq 'HASH') ? pop : +{};
  $attrs = _merge_attrs(+{ type=>'password' }, $attrs);
  return input_tag(@_, $attrs);
}

sub hidden_tag {
  my $attrs = (ref($_[-1])||'' eq 'HASH') ? pop : +{};
  $attrs = _merge_attrs(+{ type=>'hidden' }, $attrs);
  return input_tag(@_, $attrs);
}

sub submit_tag {
  my ($value, $attrs);
  $attrs = (ref($_[-1])||'') eq 'HASH' ? pop(@_) : +{};
  $value = @_ ? shift(@_) : $DEFAULT_SUBMIT_TAG_VALUE;

  $attrs = _merge_attrs(+{ type=>'submit', name=>'commit', value=>$value }, $attrs);
  return input_tag $attrs;
}

# legend_tag $value, \%attrs
# legend_tag \%attrs, \&block
sub legend_tag {
  my $content = (ref($_[-1])||'') eq 'CODE' ? pop(@_) : shift(@_);
  my $attrs = @_ ? shift(@_) : +{};
  return ref($content) ? content_tag('legend', $attrs, $content) : content_tag('legend',  $content, $attrs);
}

sub select_tag {
  my $name = shift;
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
    $option_tags = content_tag('option', $include_blank, $options_for_blank_options_tag)->concat($option_tags);
  }
  if(my $prompt = delete $attrs->{prompt}) {
      $option_tags = content_tag('option', $prompt, +{value=>''})->concat($option_tags);
  }

  $attrs = _merge_attrs(+{ name=>$html_name, id=>"@{[ _sanitize_to_id($name) ]}" }, $attrs);
  my $select_tag = content_tag('select', $option_tags, $attrs);

  if($attrs->{multiple} && $include_hidden) {
    $select_tag = hidden_tag($html_name, '', +{id=>$attrs->{id}.'_hidden', value=>1})->concat($select_tag);    
  }
  return $select_tag;
}

sub options_for_select {
  my $options_proto = shift @_;
  return $options_proto unless( (ref($options_proto)||'') eq 'ARRAY');
  my @options = _normalize_options_for_select($options_proto);

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

  my ($first, @options_for_select) = map { option_for_select($_, \%selected_lookup, \%disabled_lookup, \%global_attributes) } @options;

  return  $first->concat(@options_for_select);
}

sub _normalize_options_for_select {
  my $options_proto = shift;
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
  my ($option_info, $selected, $disabled, $attrs) = @_;
  my %attrs = (value=>$option_info->[1], %{$option_info->[2]}, %$attrs);
  $attrs{selected} = 'selected' if $selected->{$option_info->[1]};
  $attrs{disabled} = 'disabled' if $disabled->{$option_info->[1]};

  return option_tag($option_info->[0], \%attrs);
}

sub option_html_attributes { return +{} }

sub options_from_collection_for_select {
  my ($collection, $value_method, $label_method, $selected_proto) = (@_);

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
    push @options, [ $item->$label_method => $item->$value_method, option_html_attributes($item) ];
    push @selected, $item->$value_method if ((ref($selected_proto)||'') eq 'CODE') && $selected_proto->($item);
  }

  $collection->reset if $collection->can('reset');
  return options_for_select \@options, +{ selected=>\@selected, disabled=>\@disabled, %global_attributes};
}

sub field_value {
  my ($model, $attribute) = @_;
  return  $model->can('read_attribute_for_html') ? $model->read_attribute_for_html($attribute) : $model->$attribute;
}

1;

=head1 NAME

Valiant::HTML::FormTags - HTML Form Tags

=head1 SYNOPSIS

    use Valiant::HTML::FormTags 'input_tag', 'select_tag';  # import named tags
    use Valiant::HTML::FormTags ':all';                     # import all tags

=head1 DESCRIPTION

Functions that generate HTML tags, specifically those around HTML forms.   Not all
HTML tags are in this library, this focuses on things that would be useful for building
HTML forms.   In general this is a support libary for L<Valiant::HTML::FormBuilder> but
there's nothing preventing you from using these stand alone, particularly when you have
very complex form layout needs.

=head1 EXPORTABLE FUNCTIONS

The following functions can be exported by this library

=head2 button_tag

    button_tag($content_string, \%attrs)
    button_tag($content_string)
    button_tag(\%attrs, \&content_code_block)
    button_tag(\&content_code_block)

Creates a button element that defines a submit button, reset button or a generic button which 
can be used in JavaScript, for example. You can use the button tag as a regular submit tag but
it isn't supported in legacy browsers. However, the button tag does allow for richer labels
such as images and emphasis, so this helper will also accept a block. By default, it will create
a button tag with type submit, if type is not given.  HTML attribute C<name> defaults to 
'Button' if not supplied.  Inner content also defaults to 'Button' if not supplied.

=head2 checkbox_tag

    checkbox_tag $name
    checkbox_tag $name, $value
    checkbox_tag $name, $value, $checked
    checkbox_tag $name, \%attrs
    checkbox_tag $name, $value, \%attrs
    checkbox_tag $name, $value, $checked, \%attrs

Creates a check box form input tag.  C<id> will be generated from $name if not passed in \%attrs. C<value>
attribute will default to '1' and the control is unchecked by default.

=head2 fieldset_tag

    fieldset_tag \%content_block
    fieldset_tag \%attrs, \%content_block
    fieldset_tag $legend, \%attrs, \%content_block
    fieldset_tag $legend, \%content_block

Create a C<fieldset> with inner content.  Example:

    fieldset_tag(sub {
      button_tag 'username';
    });

    # <fieldset><button name="button">username</button></fieldset>
  
    fieldset_tag('Info', sub {
      button_tag 'username';
    });

    # <fieldset><legend>Info</legend><button name="button">username</button></fieldset>

=head2 legend_tag

    legend_tag $legend, \%html_attrs;
    legend_tag $legend;
    legend_tag \%html_attrs, \&content_block;
    legend_tag \&content_block;

Create an HTML form legend tag and content.  Examples:

    legend_tag('test', +{class=>'foo'});
    # <legend class="foo">test</legend>

    legend_tag('test');
    # <legend>test</legend>

    legend_tag({class=>'foo'}, sub { 'test' });
    # <legend class="foo">test</legend>

    legend_tag(sub { 'test' });
    # <legend>test</legend>

=head2 form_tag

    form_tag '/signup', \%attrs, \&content
    form_tag \@args, +{ uri_for=>sub {...}, %attrs }, \&content

Create a form tag with inner content.  Example:

    form_tag('/user', +{ class=>'form' }, sub {
      checkbox_tag 'person[1]username', +{class=>'aaa'};
    });

Produces:

    <form accept-charset="UTF-8" action="/user" class="form" method="POST">
      <input class="aaa" id="person_1username" name="person[1]username" type="checkbox" value="1"/>
    </form>';


=head2 label_tag

    label_tag $name, $content, \%attrs;
    label_tag $name, $content;
    label_tag $name, \%attrs, \&content;
    label_tag $name, \&content;

Create a label tag where $name is set to the C<for> attribute.   Can contain string or block contents.  Label
contents default to something based on $name;

    label_tag 'user_name', "User", +{id=>'userlabel'};    # <label id='userlabel' for='user_name'>User</label>
    label_tag 'user_name';                                # <label for='user_name'>User Name</label>

Example with block content:

    label_tag('user_name', sub {
      'User Name Active',
      checkbox_tag 'active', 'yes', 1;
    });

    <label for='user_name'>
      User Name Active<input checked  value="yes" id="user_name" name="user_name" type="checkbox"/>
    </label>

Produce a label tag, often linked to an input tag.   Can accept a block coderef.  Examples:

=head2 radio_button_tag

    radio_button_tag $name, $value
    radio_button_tag $name, $value, $checked
    radio_button_tag $name, $value, $checked, \%attrs
    radio_button_tag $name, $value, \%attrs

Creates a radio button; use groups of radio buttons named the same to allow users to select from a
group of options. Examples:

    radio_button_tag('role', 'admin', 0, +{ class=>'radio' });
    # <input class="radio" id="role_admin" name="role" type="radio" value="admin"/>

    radio_button_tag('role', 'user', 1, +{ class=>'radio' });
    # <input checked class="radio" id="role_user" name="role" type="radio" value="user"/>'

=head2 option_tag

    option_tag $text, \%attributes
    option_tag $text

Create a single HTML option.  C<value> attribute is inferred from $text if not in \%attributes.  Examples:

    option_tag('test', +{class=>'foo', value=>'100'});
    # <option class="foo" value="100">test</option>

    option_tag('test'):
    #<option value="test">test</option>

=head2 text_area_tag

    text_area_tag $name, \%attrs
    text_area_tag $name, $content, \%attrs

Create a named text_area form field. Examples:

    text_area_tag("user", "hello", +{ class=>'foo' });
    # <textarea class="foo" id="user" name="user">hello</textarea>

    text_area_tag("user",  +{ class=>'foo' });
    # <textarea class="foo" id="user" name="user"></textarea>

=head2 input_tag

    input_tag($name, $value, \%attrs)
    input_tag($name, $value)
    input_tag($name)
    input_tag($name, \%attrs)
    input_tag(\%attrs)

Create a HTML input tag. If $name and/or $value are set, they are used to populate the 'name' and
'value' attributes of the C<input>.  Anything passed in the \%attrs hashref overrides.  Examples:

    input_tag('username', 'jjn', +{class=>'aaa'});
    # <input class="aaa" id="username" name="username" type="text" value="jjn"/>

    input_tag('username', 'jjn');
    # <input id="username" name="username" type="text" value="jjn"/>

    input_tag('username');
    # <input id="username" name="username" type="text"/>

    input_tag('username', +{class=>'foo'});
    # <input class="foo" id="username" name="username" type="text"/>

    input_tag(+{class=>'foo'});
    # <input class="foo" type="text"/>

=head2 password_tag

Creates an password input tag with the given type.  Example:

    password_tag('password', +{class=>'foo'});
    # <input class="foo" id="password" name="password" type="password"/>

=head2 hidden_tag

Creates an input tag with the given type.  Example:

    hidden_tag('user_id', 100, +{class=>'foo'});
    # <input class="foo" id="user_id" name="user_id" type="hidden" value="100"/>
    
=head2 submit_tag

    submit_tag
    submit_tag $value
    submit_tag \%attrs
    submit_tag $value, \%attrs 

Create a submit tag.  Examples:

    submit_tag;
    # <input id="commit" name="commit" type="submit" value="Save changes"/>

    submit_tag('person');
    # <input id="commit" name="commit" type="submit" value="person"/>

    submit_tag('Save', +{name=>'person'});
    # <input id="person" name="person" type="submit" value="Save"/>

    submit_tag(+{class=>'person'});
    # <input class="person" id="commit" name="commit" type="submit" value="Save changes"/>

=head2 select_tag

    select_tag $name, $option_tags, \%attrs
    select_tag $name, $option_tags
    select_tag $name, \%attrs

Create a select tag group with options.  Examples:

    select_tag("people", raw("<option>David</option>"));
    # <select id="people" name="people"><option>David</option></select>

    select_tag("people", raw("<option>David</option>"), +{include_blank=>1});
    # <select id="people" name="people"><option label=" " value=""></option><option>David</option></select>

    select_tag("people", raw("<option>David</option>"), +{include_blank=>'empty'});
    # <select id="people" name="people"><option value="">empty</option><option>David</option></select>
      
    select_tag("prompt", raw("<option>David-prompt</option>"), +{prompt=>'empty-prompt', class=>'foo'});
    # <select class="foo" id="prompt" name="prompt"><option value="">empty-prompt</option><option>David-prompt</option></select>

=head2 options_for_select

    options_for_select [$value1, $value2, ...], $selected_value
    options_for_select [$value1, $value2, ...], \@selected_values
    options_for_select [$value1, $value2, ...], +{ selected => $selected_value, disabled => \@disabled_values, %global_options_attributes }
    options_for_select [ [$label, $value], [$label, $value, \%attrs], ...]

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

    options_for_select(['A','B','C']);
    # <option value="A">A</option>
    # <option value="B">B</option>
    # <option value="C">C</option>

    options_for_select(['A','B','C'], 'B');
    # <option value="A">A</option>
    # <option selected value="B">B</option>
    # <option value="C">C</option>

    options_for_select(['A','B','C'], ['A', 'C']);
    #<option selected value="A">A</option>
    #<option value="B">B</option>
    #<option selected value="C">C</option>

    options_for_select(['A','B','C'], ['A', 'C']);
    # <option selected value="A">A</option>
    # <option value="B">B</option>
    # <option selected value="C">C</option>

    options_for_select([[a=>'A'],[b=>'B'], [c=>'C']]);
    # <option value="A">a</option>
    # <option value="B">b</option>
    # <option value="C">c</option>

    options_for_select([[a=>'A'],[b=>'B'], [c=>'C']], 'B');
    # <option value="A">a</option>
    # <option selected value="B">b</option>
    # <option value="C">c</option>

    options_for_select(['A',[b=>'B', {class=>'foo'}], [c=>'C']], ['A','C']);
    # <option selected value="A">A</option>
    # <option class="foo" value="B">b</option>
    # <option selected value="C">c</option>

    options_for_select(['A','B','C'], +{selected=>['A','C'], disabled=>['B'], class=>'foo'});
    # <option class="foo" selected value="A">A</option>
    # <option class="foo" disabled value="B">B</option>
    # <option class="foo" selected value="C">C</option>

This function is useful with the C<select_tag>:

    select_tag("state", options_for_select(['A','B','C'], 'A'), +{include_blank=>1});
    # <select id="state" name="state">
    #  <option label=" " value=""></option>
    #  <option selected value="A">A</option>
    #  <option value="B">B</option>
    #  <option value="C">C</option>
    # </select>

Please note that since C<options_for_select> returns a L<Valiant::HTML::SafeString> you don't need to add 
any additional escaping.

=head2 options_from_collection_for_select

Given a collection (an object that does the interface defined by L<Valiant::HTML::Util::Collection> return 
a string of options suitable for C<select_tag>.  Optionally you can pass additional arguments, like with
C<options_for_select> to mark individual options as selected, disabled and to pass additional HTML attributes.
Examples:

    my $collection = Valiant::HTML::Util::Collection->new([label=>'value'], [A=>'a'], [B=>'b'], [C=>'c']);

    options_from_collection_for_select($collection, 'value', 'label');
    # <option value="value">label</option>
    # <option value="a">A</option>
    # <option value="b">B</option>
    # <option value="c">C</option>

    options_from_collection_for_select($collection, 'value', 'label', 'a');
    # <option value="value">label</option>
    # <option selected value="a">A</option>
    # <option value="b">B</option>
    # <option value="c">C</option>

    options_from_collection_for_select($collection, 'value', 'label', ['a', 'c']);
    # <option value="value">label</option>
    # <option selected value="a">A</option>
    # <option value="b">B</option>
    # <option selected value="c">C</option>

    options_from_collection_for_select($collection, 'value', 'label', +{selected=>['a','c'], disabled=>['b'], class=>'foo'})
    # <option class="foo" value="value">label</option>
    # <option class="foo" selected value="a">A</option>
    # <option class="foo" disabled value="b">B</option>
    # <option class="foo" selected value="c">C</option>

Additionally you can pass a coderef for dynamic selecting.  Example:

    options_from_collection_for_select($collection, 'value', 'label', sub { shift->value eq 'a'} );
    # <option value="value">label</option>
    # <option selected value="a">A</option>
    # <option value="b">B</option>
    # <option value="c">C</option>

The collection object must at minimum provide a method C<next> which returns the next object in the collection.
This method C<next> should return false when all the item objects have been iterated thru in turn. Optionally
you can provide a C<reset> method which will be called to return the collection to the first index.

You can see L<Valiant::HTML::Util::Collection> source for example minimal code.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut

1;
