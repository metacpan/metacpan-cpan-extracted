package Valiant::HTML::Util::TagBuilder;

use Moo;
use Sub::Util;
use Carp;
use Scalar::Util;
use Cpanel::JSON::XS ('encode_json');
use overload 
  bool => sub {1}, 
  '""' => sub { shift->to_string },
  fallback => 1;

our $ATTRIBUTE_SEPARATOR = ' ';
our %SUBHASH_ATTRIBUTES = map { $_ => 1} qw(data aria);
our %ARRAY_ATTRIBUTES = map { $_ => 1 } qw(class);
our %HTML_VOID_ELEMENTS = map { $_ => 1 } qw(area base br col circle embed hr img input keygen link meta param source track wbr);
our %BOOLEAN_ATTRIBUTES = map { $_ => 1 } qw(
  allowfullscreen allowpaymentrequest async autofocus autoplay checked compact controls declare default
  defaultchecked defaultmuted defaultselected defer disabled enabled formnovalidate hidden indeterminate
  inert ismap itemscope loop multiple muted nohref nomodule noresize noshade novalidate nowrap open
  pauseonexit playsinline readonly required reversed scoped seamless selected sortable truespeed
  typemustmatch visible);

our %HTML_CONTENT_ELEMENTS = map { $_ => 1 } qw(
  a abbr acronym address apple article aside audio
  b basefont bdi bdo big blockquote body button
  canvas caption center cite code colgroup
  data datalist dd del details dfn dialog dir div dl dt
  em
  fieldset figcaption figure font footer form frame frameset
  head header hgroup h1 h2 h3 h4 h5 h6 html
  i iframe ins
  kbd label legend li
  main map mark menu menuitem meter
  nav noframes noscript
  object ol optgroup option output
  p picture pre progress
  q
  rp rt ruby
  s samp script section select small span strike strong style sub summary sup svg
  table tbody td template textarea tfoot th thead time title  tt tr
  u ul
  var video);

our @ALL_TAGS = (keys(%HTML_VOID_ELEMENTS), keys(%HTML_CONTENT_ELEMENTS));

has view => (
  is => 'ro',
  required => 1,
  handles => [qw(safe raw escape_html safe_concat)],
);

sub BUILD {
  my $self = shift;
  my $class = ref $self;
  $class->_install_tags;
}

sub _install_tags {
  my $class = shift;

  foreach my $e (keys %HTML_VOID_ELEMENTS) {
    next if "${class}::_tags"->can($e);
    my $full_name = $class . "::_tags::$e";
    $full_name = Sub::Util::set_subname $full_name => sub {
      my ($self, $attrs) = @_;
      $attrs = +{} unless $attrs;

      return $self->{tb}->tag($e, $attrs);
    };
    Moo::_Utils::_install_tracked("${class}::_tags", $e, $full_name);
  }

  foreach my $e (keys %HTML_CONTENT_ELEMENTS) {
    next if "${class}::_tags"->can($e);
    my $full_name = $class . "::_tags::$e";
    $full_name = Sub::Util::set_subname $full_name => sub {
      my $self = shift;
      my $attrs = ((ref($_[0])||'') eq 'HASH') ? shift : +{};
      my $content = shift;
      my @args = (((ref($content)||'') eq 'CODE') || ((ref($content)||'') eq 'ARRAY')) ?
        ($e, $attrs, $content) :
          ($e, $content, $attrs);

      return $self->{tb}->content_tag(@args);
    };
    Moo::_Utils::_install_tracked("${class}::_tags", $e, $full_name);
  }
}

sub is_content_tag {
  my ($self, $name) = @_;
  return $HTML_CONTENT_ELEMENTS{$name} ? 1 : 0;
}

sub is_void_tag {
  my ($self, $name) = @_;
  return $HTML_VOID_ELEMENTS{$name} ? 1 : 0;
}

sub tags {
  my $self = shift;
  my $class = ref $self;
  return bless +{ tb=>$self }, "${class}::_tags";
}

sub _omit_tag {
  my ($self, $attrs) = @_;
  return 0 unless exists $attrs->{omit};
  my $omit_tag = delete $attrs->{omit};
  if(ref($omit_tag) eq 'CODE') {
    return $omit_tag->($self->view) ? 1 : 0;
  } 
  return $omit_tag ? 1 : 0;
}

sub _process_cb_attr {
  my ($self, $attr_val) = @_;
  return $attr_val->($self->view) if ref($attr_val) eq 'CODE';
  return $attr_val;
}

sub tag {
  my ($self, $name, $attrs) = (@_, +{});
  croak "'$name' is not a valid VOID HTML element" unless $HTML_VOID_ELEMENTS{$name};

  # Handle given / when / when_default
  if(exists $attrs->{when}) {
    my $when = $self->_process_cb_attr(delete $attrs->{when});
    return $self->raw('') unless $when eq $self->{_given}{val};
    $self->{_given}{gone} = 1;
  }
  if(exists $attrs->{when_default}) {
    return $self->raw('') if $self->{_given}{gone};
    delete $attrs->{when_default};
  }

  # Handle 'map'
  if(my $repeat_proto = $self->_process_cb_attr(delete $attrs->{map})) {
    my $idx = 0;
    my @repeated_content = ();
    my $repeat = ref($repeat_proto) eq 'ARRAY' ? 
      Valiant::HTML::Util::Collection->new(@$repeat_proto)
        : $repeat_proto;
    my @code_placeholder_attrs = grep { (ref($attrs->{$_})||'') eq 'CODE' } keys %$attrs;
    my @template_placeholder_attrs = grep { $attrs->{$_} =~m/\{:.*?\}/ } keys %$attrs;
    while(my $next = $repeat->next) {
      my %expanded_attrs = (
        %$attrs,
        (map { my $key = $_; local $_ = $next; $key => $attrs->{$key}->($self->view, $next, $idx) } @code_placeholder_attrs),
        (map { $_ => $self->sf($next, $attrs->{$_}) } @template_placeholder_attrs),
      );
      push @repeated_content, $self->tag($name, \%expanded_attrs);
      $idx++;
    }
    $repeat->reset if $repeat->can('reset');
    my $repeated_content = $self->safe_concat(@repeated_content);
    return $repeated_content;
  }
  return $self->raw('') if $self->_omit_tag($attrs);
  return my $tag = $self->raw("<${name}@{[ $self->_tag_options(%{$attrs}) ]}/>");
}

sub content_tag {
  my $self = shift;
  my $name = shift;
  croak "'$name' is not a valid HTML content element" unless $HTML_CONTENT_ELEMENTS{$name};

  my ($code, $block);
  if(ref($_[-1]) eq 'CODE') {
    $code = pop(@_);
  } elsif(ref($_[-1]) eq 'ARRAY') {
    $block = $self->safe_concat(@{ pop @_ });
  } elsif(ref(\$_[-1]) eq 'SCALAR') {
    $block = pop @_;
  } elsif(ref(\$_[0]) eq 'SCALAR') {
    $block = shift @_;
  }

  my $attrs = +{};
  if(ref($_[-1]) eq 'HASH') {
    $attrs = pop(@_);
  } elsif(ref($_[0]) eq 'HASH') {
    $attrs = shift(@_);
  }

  $block = $self->safe_concat(@_) if @_;

  my $content = $self->raw('');

  # Handle 'if'
  return $content if exists($attrs->{if}) && !$self->_process_cb_attr(delete $attrs->{if});
  # Handle 'with'
  my @args = ($self->view);
  push @args, $self->_process_cb_attr(delete $attrs->{with}) if exists $attrs->{with};

  # Handle given / when / when_default
  if(exists $attrs->{when}) {
    my $when = $self->_process_cb_attr(delete $attrs->{when});
    return $content unless $when eq $self->{_given}{val};
    $self->{_given}{gone} = 1;
  }
  if(exists $attrs->{when_default}) {
    return $content if $self->{_given}{gone};
    delete $attrs->{when_default};
  }
  local $self->{_given} = { val => $self->_process_cb_attr(delete $attrs->{given})} if exists $attrs->{given};

  # Handle 'map'
  if(my $repeat_proto = $self->_process_cb_attr(delete $attrs->{map})) {
    my $idx = 0;
    my @repeated_content = ();
    my $repeat = ref($repeat_proto) eq 'ARRAY' ? 
      Valiant::HTML::Util::Collection->new(@$repeat_proto)
        : $repeat_proto;
    my @code_placeholder_attrs = grep { (ref($attrs->{$_})||'') eq 'CODE' } keys %$attrs;
    my @template_placeholder_attrs = grep { $attrs->{$_} =~m/\{:.*?\}/ } keys %$attrs;
    while(my $next = $repeat->next) {
      my %expanded_attrs = (
        %$attrs,
        (map { my $key = $_; local $_ = $next; $key => $attrs->{$key}->($self->view, $next, $idx) } @code_placeholder_attrs),
        (map { $_ => $self->sf($next, $attrs->{$_}) } @template_placeholder_attrs),
      );
      if(defined $code) {
        push @repeated_content, $self->content_tag($name, \%expanded_attrs, sub { $code->(@_, $next, $idx++) } );
      } elsif(defined $block) {
        push @repeated_content, $self->content_tag($name, \%expanded_attrs, $block);
      } else {
        push @repeated_content, $self->content_tag($name, \%expanded_attrs, $content);
      }
    }
    $repeat->reset if $repeat->can('reset');
    my $repeated_content = $self->safe_concat(@repeated_content);
    return $repeated_content;
  }
    
  my $processed_code = 0;
  if(defined $code) {

    # Handle 'repeat'
    if(my $repeat_proto = $self->_process_cb_attr(delete $attrs->{repeat})) {
      my $idx = 0;
      my @repeated_content = ();
      my $repeat = ref($repeat_proto) eq 'ARRAY' ? 
        Valiant::HTML::Util::Collection->new(@$repeat_proto)
          : $repeat_proto;

      $processed_code = 1; # Code is considered processed even if there's no iteration
      while(my $next = $repeat->next) {
        push @repeated_content, $code->($self->view, $next, $idx++);
      }
      $repeat->reset if $repeat->can('reset');
      $content = $self->safe_concat(@repeated_content);
    }
    #prepare content
    if(! $processed_code ) {
      my @return = $code->(@args);
      $content = $self->safe_concat(@return);
    }
  } elsif(defined $block) {
    $content = $self->safe_concat($block);
  }

  return $content if $self->_omit_tag($attrs);
  return my $tag = $self->raw("<${name}@{[ $self->_tag_options(%{$attrs}) ]}>${content}</${name}>");
}

sub sf {
  my $self = shift;
  if(Scalar::Util::blessed $_[0]) {
    my ($src_object, $format, $opts) = @_;
    my $raw = exists($opts->{raw}) ? delete $opts->{raw} : 0;
    $format =~ s/\{(.*?)\:([^}]+)\}/ $src_object->can($2) ? ($1 ? sprintf($1,$src_object->$2) : $src_object->$2) : croak("Source object '@{[ ref $src_object ]}' has no method '$2'") /gex;
    return $raw ? $self->raw($format) : $self->safe($format);
  } else {
    my ($format, %args) = @_;
    my $collapse = delete $args{collapse};
    my $raw = delete $args{raw};
    $format =~ s/\{(.*?)\:([^}]+)\}/ exists($args{$2})? ($1 ? sprintf($1,$args{$2}) : $args{$2}) : croak("Source data has no value '$2'") /gex;
    if($collapse) {
      $format =~s/\s+/ /gsm;
    }
    return $raw ? $self->raw($format) : $self->safe($format);
  }
};

sub join_tags {
  my $self = shift;
  return $self->safe_concat(@_);
}

sub to_string { return shift->{tag_info} || '' }

# helpers

sub text { return shift->safe_concat(@_) }

sub link_to {
  my $self = shift;
  my $url = shift || croak 'link_to requires a url';
  my $attrs = (ref($_[0]) eq 'HASH') ? shift : {};
  my $content = @_ ? shift : $url;
  $attrs->{href} = $url;
  return $self->content_tag('a', $attrs, $content);
}

# private

sub _tag_options {
  my $self = shift;
  my (%attrs) = @_;
  return '' unless %attrs;
  my @attrs = ('');
  foreach my $attr (sort keys %attrs) {
    if($BOOLEAN_ATTRIBUTES{$attr}) {
      push @attrs, $attr if $attrs{$attr};
    } elsif($SUBHASH_ATTRIBUTES{$attr}) {
      foreach my $subkey (sort keys %{$attrs{$attr}}) {
        push @attrs, $self->_tag_option("${attr}-@{[ _dasherize($subkey) ]}", $attrs{$attr}{$subkey});
      }
    } elsif($ARRAY_ATTRIBUTES{$attr}) {
      my $class = ((ref($attrs{$attr})||'') eq 'ARRAY') ? join(' ', @{$attrs{$attr}}) : $attrs{$attr};
      push @attrs, $self->_tag_option($attr, $class);
    } else {
      push @attrs, $self->_tag_option($attr, $attrs{$attr});
    }
  }
  return join $ATTRIBUTE_SEPARATOR, @attrs;
}

sub _tag_option {
  my $self = shift;
  my $attr = shift;
  my $value = defined($_[0]) ? shift() : '';

  if(ref($value) eq 'HASH') {
    $value = encode_json($value);
    $value = $self->safe($value);
  } else {
    $value = $self->safe($value);
  }

  return qq[${attr}="@{[ $value ]}"];
}

sub _dasherize {
  my $value = shift;
  my $copy = $value;
  $copy =~s/_/-/g;
  return $copy;
}

package Valiant::HTML::Util::TagBuilder::_tags;

use overload 
  bool => sub {1}, 
  '""' => sub { shift->to_string },
  fallback => 1;

sub to_string {
  my $self = shift;
  return $self->{tb}->to_string;
}

sub join_tags { my $self = shift; $self->{tb}->join_tags(@_); return $self }
sub text { my $self = shift; $self->{tb}->text(@_); return $self }
sub tag { my $self = shift; $self->{tb}->tag(@_); return $self }
sub content_tag { my $self = shift; $self->{tb}->content_tag(@_); return $self }

1;


=head1 NAME

Valiant::HTML::Util::TagBuilder - Utility class to generate HTML tags

=head1 SYNOPSIS

    use Valiant::HTML::Util::TagBuilder;
    my $tag_builder = Valiant::HTML::Util::TagBuilder->new(view => $view);
    my $tag = $tag_builder->tag('div', { class => 'container' });

=head1 DESCRIPTION

L<Valiant::HTML::Util::TagBuilder> is a utility class for generating HTML tags.  It wraps
a view or template object which must provide methods for html escaping and for marking
strings as safe for display.

=head1 ATTRIBUTES

This class has the following initialization attributes

=head2 view

Object, Required.  This should be an object that provides methods for creating escaped
strings for HTML display.  Many template systems provide a way to mark strings as safe
for display, such as L<Mojo::Template>.  You will need to add the following proxy methods
to your view / template to adapt it for use in creating safe strings that work in the way
it expects.  If you're view doesn't need this you can just use L<Valiant::HTML::Util::View>.

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

=item read_attribute

Given an attribute name return the value that the view has defined for it.  

=item attribute_exists

Given an attribute name return true if the view has defined a value for it.

=back

Both C<raw>, C<safe> and C<safe_concat> should return a 'tagged' object which is specific to your view or
template system. However this object must 'stringify' to the safe version of the string to be displayed.  See
L<Valiant::HTML::SafeString> for example API.  We use L<Valiant::HTML::SafeString> internally to provide
safe escaping if you're view doesn't do automatic escaping, as many older template systems like Template
Toolkit.

=head1 METHODS

=head2 new

Create a new instance of the TagBuilder.

  my $tag_builder = Valiant::HTML::Util::TagBuilder->new(view => $view);

=head2 tags

Returns a reference to a blessed hash that provides shortcut methods for all HTML tags.

  my $tags = $tag_builder->tags;
  my $img_tag = $tags->img({src => '/path/to/image.jpg'});
  # <img src="/path/to/image.jpg" />
  
  my $div_tag = $tags->div({id=>'top}, "Content");
  # <div id="top">Content<div>

=head2 tag

Generates a HTML tag of the specified type and with the specified attributes.

=head2 content_tag

Generates a HTML content tag of the specified type, with the specified attributes, and with the specified content.

    my $tag = $tag_builder->content_tag('p', { class => 'lead' }, 'Lorem ipsum dolor sit amet');

The content can also be generated by a code block, as shown in the following example.

    my $tag = $tag_builder->content_tag('ul', { class => 'list-group' }, sub {
      $tag_builder->content_tag('li', 'Item 1') .
      $tag_builder->content_tag('li', 'Item 2') .
      $tag_builder->content_tag('li', 'Item 3')
    });

=head2 join_tags

Joins multiple tags together and returns them as a single string.

    my $tags = $tag_builder->join_tags(
      $tag_builder->tag('div', { class => 'container' }),
      $tag_builder->content_tag('p', 'Lorem ipsum dolor sit amet')
    );

=head2 text

Generates a safe string of text.

   my $text = $tag_builder->text('Lorem ipsum dolor sit amet');

=head2 link_to

Helper method to generate a link tag.

  my $link = $tag_builder->link_to($url, \%attrs, $content);

C<$url> is the URL to link to and is required.  Both C<%attrs> and c<$content>
are optional. If C<$content> is not provided, the link text will be the URL.

=head2 to_string

Returns the generated HTML tag as a string.

    my $tag = $tag_builder->tag('div', { class => 'container' });
    my $tag_string = $tag->to_string;

=head1 PROXY METHODS

The following methods are proxied from the enclosed view object.  You should
refer to your view for more.

=head2 safe

=head2 raw

=head2 escape_html

=head2 safe_concat

=head1 LOGIC AND FLOW CONTROL

L<Valiant::HTML::Util::TagBuilder> builds in some basic logic and control flow to
make it easier to use in small places where a full on template system would be too much
but you don't want ugly string concatenation.  This system works by adding a handful of
custom html attributes to your tag declarations.   These custom tags are removed from
the final output.

=head2 omit

    my $t = $tag_builder->tags;
    say $t->hr({omit=>1}) +
      $t->div({omit=>1}, 'Hello World!');

If the value is true the tag is removed from the final output.  However any content
is preserved.

Value can be a scalar which will be evaluated as a boolean, or a coderef which will be called 
and passed the current C<$view> as an argument).

    say $t->hr({omit => sub ($view) { 1 }}); # is empty

=head if

    my $bool = 1;
    say $t->div({id=>'one', if=>$bool}, sub {
      my ($view) = @_;
      $t->p('hello');
    }): # '<div id="one"><p>hello</p></div>';

    $bool = 0;
    say $t->div({id=>'one', if=>$bool}, sub {
      my ($view) = @_;
      $t->p('hello');
    }): # '';

If the processed value of the tag is false, the tag and any of its contents are removed from
the output.  Value can be a scalar value or a coderef (which gets the C<$view> as its one
argument).

=head with

Create content with a new local context.

    say $t->div({id=>'one', with=>'two'}, sub {
      my ($view, $var) = @_;
      $t->p($var);
    }); # '<div id="one"><p>two</p></div>';

Useful if you need a local value in your template

=head2 repeat

=head2 map

Used to loop over a tags contents (for content tags) or the tag itself (for both content and
empty tags).  Examples:

    say $t->div({id=>'one', repeat=>[1,2,3]}, sub {
      my ($view, $item, $idx) = @_;
      $t->p("hello[$idx] $item");
    }); # '<div id="one"><p>hello[0] 1</p><p>hello[1] 2</p><p>hello[2] 3</p></div>';

    say $t->div({id=>sub {"one_${_}"}, map=>[1,2,3]}, sub {
      my ($view) = @_;
      $t->p('hello');
    }); # '<div id="one_1"><p>hello</p></div><div id="one_2"><p>hello</p></div><div id="one_3"><p>hello</p></div>';

Values for the looping attributes can be an arrayref, an object that does '->next' (for example a L<DBIx::Class>
resultset) or a coderef that receives the current view object and returns either of the above.

If your object also does C<reset> that method will be called automatically after the last loop item.

In the case of C<map> if you want to modify the attributes of the enclosing tag you can use coderefs for
those attributes.  They will be called with the current view object and current loop item value and index.  When also
localize C<$_> to be to the current loop item value for ease of use.

    say $t->hr({ id => sub { my ($view, $val, $i) = @_; "rule_${val}" }, map => [1,2,3] });

returns

    <hr id='rule_2' /><hr id='rule_2' /><hr id='rule_3' />

and this does the same:

    say $t->hr({ id => sub { "rule_${_}" }, map =>[1,2,3] });

=head2 given / when

Given / When 'switchlike' conditional.  Example:

    say $t->div({id=>'one', given=>'one'}, sub {
      my ($view) = @_;
      $t->p({when=>'one'}, "hello one"),
      $t->p({when=>'two'}, "hello two"),
      $t->hr({when=>'three'}),
      $t->p({when_default=>1}, "hello four")
    }); # '<div id="one"><p>hello one</p></div>';

When a content tag has the C<given> attribute, its content must be a coderef which will get the current
C<$view> as its one argument.  Inside the coderef we will render a tag with a matching C<when> attribute
or if there are no matches a tag with the C<when_default> attribute.

The value of C<given=> may be a scalar or a coderef.  If its a coderef we will call it with the current
view object and expect a scalar.

=head1 AUTHOR

See L<Valiant>

=head1 SEE ALSO

L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
