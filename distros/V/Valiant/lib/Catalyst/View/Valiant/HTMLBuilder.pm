package Catalyst::View::Valiant::HTMLBuilder;

use Moose;
use Moo::_Utils;
use Module::Runtime;
use Valiant::HTML::SafeString;
use Valiant::HTML::Util::TagBuilder;
use Valiant::JSON::Util;
use Scalar::Util;
use Sub::Util;
use URI::Escape ();
use Carp;

extends 'Catalyst::View::BasePerRequest';

has 'caller' => (is=>'ro', required=>0, predicate=>'has_caller');

has 'tb' => (is=>'ro', required=>1, lazy=>1, builder=>'_build_tags');

  sub _build_tags {
    my $self = shift;
    return Valiant::HTML::Util::TagBuilder->new(view=>$self);
  }

has 'view_fragment' => (is=>'ro', predicate=>'has_view_fragment');

sub components { return qw/Form Pager/ }  

foreach my $component (components()) {
  my $component_method_name = lc($component);
  my $sub = Sub::Util::set_subname $component_method_name => sub {
    my $self = shift;
    return $self->{"__${component_method_name}"} ||= do {
      my $module = Module::Runtime::use_module("Catalyst::View::Valiant::HTMLBuilder::$component");
      $module->new(
        view=>$self,
        context=>$self->ctx,
        controller=>$self->ctx->controller,
      );
    };
  };
  Moo::_Utils::_install_tracked(__PACKAGE__, $component_method_name, $sub);
}

my $_SELF;
sub BUILD { $_SELF = shift }

sub import {
  my $class = shift;
  my $target = caller;
  my @args = @_;

  $target->meta->superclasses($class);
  $class->_install_helpers($target, @args);
  $class->_install_tags($target);
}

sub _install_helpers {
  my $class = shift;
  my $target = shift;
  my @args = @_;

  foreach my $helper (@args) {
    my $sub = Sub::Util::set_subname "${target}::${helper}" => sub {
      my $self = shift;
      croak "View method called without correct self" unless $self and $self->isa($target);
      return $self->form->$helper(@_) if $self->form->can($helper);
      return $self->pager->$helper(@_) if $self->pager->can($helper);
      return $self->ctx->controller->$helper(@_) if $self->ctx->controller->can($helper);
      return $self->ctx->$helper(@_) if $self->ctx->can($helper);

      croak "Can't find helper '$helper' in form, pager, controller or context";
    };
    Moo::_Utils::_install_tracked($target, $helper, $sub);
  }
}

sub _install_tags {
  my $class = shift;
  my $target = shift;
  my $tb = Module::Runtime::use_module('Valiant::HTML::Util::TagBuilder');

  my %tags = map {
    ref $_ ? @$_ : ($_ => ucfirst($_) ); # up case the tag name
  } (@Valiant::HTML::Util::TagBuilder::ALL_TAGS);
  $tags{$_} = $_ for @_;

  foreach my $tag (keys %tags) {
    my $tag_name = $tags{$tag};

    my $method;
    if(Valiant::HTML::Util::TagBuilder->is_content_tag($tag)) {
      $method = Sub::Util::set_subname "${target}::${tag_name}" => sub {
        my ($args, $content) = (+{}, '');
        $args = shift if ref $_[0] eq 'HASH';
        if(defined($_[0])) {
          if(Scalar::Util::blessed($_[0]) && $_[0]->isa($class)) {
            $content = shift->get_rendered;
          } elsif((ref($_[0])||'') eq 'ARRAY') {
            my $inner = shift;
            my @content = map {
              (Scalar::Util::blessed($_) && $_->isa($class)) ? $_->get_rendered : $_;
            } @{$inner};
            $content = $class->safe_concat(@content);
          } else {
            $content = shift;
          }
        }
        return $_SELF->tb->tags->$tag($args, $content), @_ if @_;
        return $_SELF->tb->tags->$tag($args, $content);
      };
    } elsif(Valiant::HTML::Util::TagBuilder->is_void_tag($tag)) {
      $method = Sub::Util::set_subname "${target}::${tag_name}" => sub {
        my $args = +{};
        $args = shift if ref $_[0] eq 'HASH';
        return $_SELF->tb->tags->$tag($args), @_ if @_;
        return $_SELF->tb->tags->$tag($args);
      };
    }
     Moo::_Utils::_install_tracked($target, $tag_name, $method);
  }
}

sub view {
  my $self = shift;
  my $view = shift;  
  my @args = (caller=>$self);

  push @args, %{shift()} if ((ref($_[0])||'') eq 'HASH');
  push @args, shift if ((ref($_[0])||'') eq 'CODE');

  my $view_object = $self->ctx->view($view, @args);

  return $view_object, @_ if @_;
  return $view_object;
}

sub read_attribute_for_html {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return my $value = $self->$attribute if $self->can($attribute);
  die "No such attribute '$attribute' for view"; 
}

sub attribute_exists_for_html {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return 1 if $self->can($attribute);
  return;
}

sub flatten_rendered {
  my ($self, @rendered) = @_;
  return $self->safe_concat(@rendered);
}

my %data_templates = ();
sub data_template {
  my $self = shift;
  my $class = ref($self) || $self;
  my $template = $data_templates{$class} ||= do {
    my $data = "${class}::DATA";
    my $template = do { local $/; <$data> };
  };

  return $self->tb->sf($self, $template, {raw=>1});
}

sub safe { shift; return Valiant::HTML::SafeString::safe(@_) }
sub raw {shift; return Valiant::HTML::SafeString::raw(@_) }
sub safe_concat { shift; return Valiant::HTML::SafeString::safe_concat(@_) }
sub escape_html { shift; return Valiant::HTML::SafeString::escape_html(@_) }
sub escape_javascript { shift; return Valiant::JSON::Util::escape_javascript(@_) }
sub escape_js { shift->escape_javascript(@_) }

sub uri_escape {
  my $self = shift;
  if(scalar(@_) > 1) {
    my %pairs = @_;
    return join '&', map { URI::Escape::uri_escape($_) . '=' . URI::Escape::uri_escape($pairs{$_}) } keys %pairs;
  } else {
    my $string = shift;
    return URI::Escape::uri_escape($string);
    
  }
}

around 'get_rendered' => sub {
  my ($orig, $self, @args) = @_;
  if($self->has_view_fragment) {
    my $method = $self->view_fragment;
    return $self->$method;
  } else {
    return $self->$orig(@args);
  }
};

__PACKAGE__->config(content_type=>'text/html');
__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::View::Valiant::HTMLBuilder - Per Request, strongly typed Views in code

=head1 SYNOPSIS

    package Example::View::HTML::Home;

    use Moose;
    use Catalyst::View::Valiant::HTMLBuilder
        qw(form_for link_to uri);

    has 'page_title' => (is=>'ro', required=>1);

    sub the_time  ($self) { P {class=>'timestamp'}, scalar localtime}

    sub render($self, $c, $content) {
      return Html +{ lang=>'en' }, [
        Head [
          Title $self->page_title,
          Meta +{ charset=>"utf-8" },
          Meta +{ name=>"viewport", content=>"width=device-width, initial-scale=1, shrink-to-fit=no" },
          Link +{ rel=>"stylesheet", type=>'text/css', href=>"/static/core.css" },
          Link +{ rel=>"stylesheet",
                  href=>"https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css",
                  integrity=>'sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N',
                  crossorigin=>"anonymous" },
          ($self->caller->can('css') ? $self->caller->css : ''),
        ],
        Body [
          $content,
          Div $self->the_time,
          Script +{ src=>'https://code.jquery.com/jquery-3.7.0.min.js',
                    integrity=>'sha256-2Pmvv0kuTBOenSvLm6bvfBSSHrUJ+3A7x6P5Ebd07/g=',
                    crossorigin=>"anonymous" }, '',
          Script +{ src=>'https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.bundle.min.js',
                    integrity=>'sha384-Fy6S3B9q64WdZWQUiU+q4/2Lc9npb8tCaSX9FK7E8HnRr0Jz8D6OP9dO5Vg3Q9ct',
                    crossorigin=>"anonymous" }, '',
        ],
      ];
    }

    1;

=head1 DESCRIPTION

B<WARNINGS>: Experimental code that I might need to break back compatibility in order
to fix issues.  I've rewritten this from scratch twice already so if I do so again
and it breaks all your code, you've been warned.  

This is a L<Catalyst::View> subclass that provides a way to write views in code
that are strongly typed and per request.  It also integrates with several of L<Valiant>'s
HTML form generation code modules to make it easier to create HTML forms that properly
synchronize with your L<Valiant> models for displaying errors and performing validation.

Unlike most Catalyst views, this view is 'per request' in that it is instantiated for
each request.  This allows you to store per request state in the view object as well as
localize view specific logic to the view object.  In particular it allows you to avoid or
reduce using the stash in order to pass values from the controller to the view.  I think
this can make your views more robust and easier to support for the long term.  It builds
upons L<Catalyst::View::BasePerRequest> which provides the per request behavior so you should
take a look at the documentation and example controller integration in that module in
order to get the idea.

As a quick example here's a possible controller that might invoke the view given in the
SYNOPSIS:

    package Example::Controller::Home;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub index($self, $c) {
      my $view = $c->view('HTML::Home', page_title=>'The Home Page');
    }

    1;

This will then work with the commonly used L<Catalyst::Action::RenderView> or my 
L<Catalyst::ActionRole::RenderView> to produce a view response and set it as the
response body.  

This approach is experimental and I expect best practices around it to evolve so don't
get stuck on any particular way of doing things.

=head1 ATTRIBUTES

This class inherits all of the attributes from L<Catalyst::View::BasePerRequest>

=head1 METHODS

This class inherits all of the methods from L<Catalyst::View::BasePerRequest> as well as:

=head2 tb

Instance of L<Valiant::HTML::Util::TagBuilder> that is used to generate HTML tags.

Returns the current C<form> object.

=head2 view

Given the name of a view, returns the view object.  Basically a wrapper around C<< $c->view >>.

=head2 data_template

Returns the data template for the current view.  This is a template that is used to generate
data attributes for the view.  The template is read from a file named C<DATA> in the view
class.  The template is processed by the C<sf> method in L<Valiant::HTML::TagBuilder> so
you can use the same syntax as you would in a view.  Example

    package Example::View::HTML::Home;

    use Moose;
    use Catalyst::View::Valiant::HTMLBuilder;

    has bar => (is=>'ro', required=>1);

    sub render($self, $c, $content) {
      return Div +{ $self->data_template }, $content;
    }

    1;

    __DATA__
    data-foo="{:bar}"

=head2 safe

Marks a string as safe to render by first escaping it and then wrapping it in a L<Valiant::HTML::SafeString> object.

=head2 raw

Marks a string as safe to render by wrapping it in a L<Valiant::HTML::SafeString> object.

=head2 safe_concat

Given one or more strings and / or L<Valiant::HTML::SafeString> objects, returns
a new L<Valiant::HTML::SafeString> object that is the concatenation of all of the strings.

=head2 escape_html

Given a string, returns a new string that is the escaped version of the original string.

=head2 escape_javascript

Given a string, returns a new string that is the javascript escaped version of the original string.

=head2 uri_escape

Given a string, returns a new string that is the URI escaped version of the original string.
Given an array, returns a string that is the URI escaped version of the key value pairs in the array.

=head2 read_attribute_for_html

Given an attribute name, returns the value of that attribute if it exists.  If the attribute does not exist, it will die.

=head2 attribute_exists_for_html

Given an attribute name, returns true if the attribute exists and false if it does notu.

=head2 formbuilder_class 

    sub formbuilder_class { 'Example::FormBuilder' }

Provides an easy way to override the default formbuilder class.  By default it will use
L<Valiant::HTML::FormBuilder>.  You can override this method to return a different class
via a subclass of this view.

=head1 EXPORTS

All HTML tags are exported as functions.  For example:

    package Example::View::HTML::Home;

    use Moose;
    use Catalyst::View::Valiant::HTMLBuilder;

    sub render($self, $c, $content) {
      return Div +{ class=>'foo' }, $content;
    }

The export is the same as the HTML tag name but with the first letter capitalized.

In addition you can request to export any method from the form object, the pager object,
the controller object or the context object.  For example:

    package Example::View::HTML::Home;

    use Moose;
    use Catalyst::View::Valiant::HTMLBuilder
        qw(form_for link_to uri);

    sub render($self, $c, $content) {
      return Div +{ class=>'foo' }, $content;
    }

This will export the C<form_for>, C<link_to> and C<uri> methods from the form object, the
pager object, the controller object and the context object respectively.

See L<Valiant::HTML::Util::Form> and L<Valiant::HTML::Util::FormTags> for more information
on the form methods.

See L<Valiant::HTML::Util::Tagbuilder> for more information on the tag methods.

See L<Valiant::HTML::SafeString> for more information on the safe string methods.

See L<Valiant::JSON::Util> for more information on the JSON methods.

=head1 SUBCLASSING

Create a base class in your project:

    package Example::View::HTML;

    use Moose;
    use Catalyst::View::Valiant::HTMLBuilder;

    sub redirect_to_action ($self, $action, @args) {
      return $self->redirect_to($self->uri_for_action($action, @args));
    }

    sub the_time  ($self) {
      return P {class=>'timestamp'}, scalar localtime;
    }

    __PACKAGE__->meta->make_immutable;

Then you can use it as in this example.   The subclass will automatically
inherit any local methods and attributes from the base class.

    package Example::View::HTML::Page;

    use Moose;
    use Example::View::HTML;

    has 'page_title' => (is=>'ro', required=>1);

    sub render($self, $c, $content) {
      return Html +{ lang=>'en' }, [
        Head [
          Title $self->page_title,
          Meta +{ charset=>"utf-8" },
          Meta +{ name=>"viewport", content=>"width=device-width, initial-scale=1, shrink-to-fit=no" },
          Link +{ rel=>"stylesheet", type=>'text/css', href=>"/static/core.css" },
          Link +{ rel=>"stylesheet",
                  href=>"https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css",
                  integrity=>'sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N',
                  crossorigin=>"anonymous" },
        ],
        Body [
          $content,
          Div $self->the_time,
        ],
      ];
    }

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::Util::Form>, L<Valiant::HTML::Util::FormTags>,
L<Valiant::HTML::Util::Tagbuilder>,  L<Valiant::HTML::SafeString>.

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
