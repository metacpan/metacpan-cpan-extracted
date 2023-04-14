package Catalyst::View::Valiant;

use Moo;
use Sub::Util;
use Valiant::HTML::SafeString ();
use Attribute::Handlers;
use Module::Runtime;
use Carp;
use Catalyst::View::Valiant::Form;

extends 'Catalyst::View::BasePerRequest';

## Shared Form Object

my $form;

sub form_args { return () }

sub _install_form {
  my $class = shift;
  my $target = shift;
  my $form_class = shift;
  my $view = Module::Runtime::use_module('Valiant::HTML::Util::View')->new; # Placeholder
  $form = Catalyst::View::Valiant::Form->new(view=>$view, $class->form_args);
}

## Code Attributes

sub Renders :ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data) = @_;
  my $name = *{$symbol}{NAME};
  unless($package->can("__attr_${name}")) {
    my $wrapper = sub {
      my ($self, @args) = @_;
      carp "View method called without correct self" unless $self->isa($package);
      local $form->{view} = $self; # Evil Hack lol
      local $form->{context} = $self->ctx;
      local $form->{controller} = $self->ctx->controller;
      return $referent->(@_);
    };
    Moo::_Utils::_install_tracked($package, "__attr_${name}", $wrapper);
    Moo::_Utils::_install_tracked($package, $name, sub {
      return $package->can("__attr_${name}")->(@_);
    });
  }
}

sub import {
  my $class = shift;
  my $target = caller;

  my (@tags, @views, @utils, $which) = ();
  while(@_) {
    my $next = shift;
    if($next eq '-tags') {
      $which = 'tags';
      next;
    } elsif($next eq '-views') {
      $which = 'views';
      next;
    } elsif(($next eq '-util') || ($next eq '-utils')) {
      $which = 'util';
      next;
    }

    if($which eq 'tags') {
      push @tags, $next;
    } elsif($which eq 'views') {
      my $key = $next;
      $next =~s/::/_/g;
      $next =~s/(?<=[a-z])(?=[A-Z])/_/g;
      push @views, lc($next) => $key;
    } elsif($which eq 'util') {
      push @utils, $next;
    }
  }

  Moo->_set_superclasses($target, $class);
  Moo->_maybe_reset_handlemoose($target);

  $class->_install_form($target);
  $class->_install_tags($target, @tags);
  $class->_install_views($target, @views);
  $class->_install_utils($target, @utils);
}

sub form { $form }
sub tags { $form->tags }

sub _install_utils {
  my $class = shift;
  my $target = shift;

  no strict 'refs';
  foreach my $util (@_) {
    if($util eq '$sf') {
      my $sf = sub { $form->sf(@_) };
      *{"${target}::sf"} = \$sf;
    } elsif($util eq 'content') {
      Moo::_Utils::_install_tracked($target, "__content", \&{"Catalyst::View::BasePerRequest::content"});  
      my $content_sub = sub {
        if(Scalar::Util::blessed($_[0])) {
          return $target->can('__content')->(shift, shift), @_;
        } else {
          return $target->can('__content')->($form->view, shift), @_;
        }
      };
      Moo::_Utils::_install_tracked($target, 'content', $content_sub);
    } elsif( ($util eq 'content_for') || ($util eq 'content_append') || ($util eq 'content_replace') || ($util eq 'content_around') ) {
      Moo::_Utils::_install_tracked($target, "__${util}", \&{"Catalyst::View::BasePerRequest::${util}"}); 
      my $sub = sub {
        if(Scalar::Util::blessed($_[0])) {
          return $target->can("__${util}")->(shift, shift, shift), @_;
        } else {
          return $target->can("__${util}")->($form->view, shift, shift), @_;
        }
      };
      Moo::_Utils::_install_tracked($target, $util, $sub);
    } elsif($util eq 'path') {
      Moo::_Utils::_install_tracked($target, "__path", $target->can('path'));
      my $sub = sub {
        if(Scalar::Util::blessed($_[0]) && $_[0]->isa('Catalyst::View::Valiant')) {
          return $target->can("__path")->(@_);
        } else {
          return $target->can("__path")->($form->view, @_);
        }
      };
      Moo::_Utils::_install_tracked($target, 'path', $sub);
    }

  }
}

sub _install_tags {
  my $class = shift;
  my $target = shift;
  foreach my $tag (@_) {
    my $method;
    if($form->is_content_tag($tag)) {
      #if($target->can($tag)) {
      #  $method = $target->can($tag);
      #  use Devel::Dwarn;
      #  Dwarn [1, $method] if $tag eq 'blockquote';
      #} else {
        $method = Sub::Util::set_subname "${target}::${tag}" => sub {
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
          return $form->tags->$tag($args, $content), @_;
        };
      #  use Devel::Dwarn;
      #  Dwarn [2, $method] if $tag eq 'blockquote';
      #}
    } elsif($form->is_void_tag($tag)) {
      #if($target->can($tag) && $tag ne 'meta') { # meta is a special case 
      #  $method = $target->can($tag);
      #} else {
        $method = Sub::Util::set_subname "${target}::${tag}" => sub {
          my $args = +{};
          $args = shift if ref $_[0] eq 'HASH';
          return $form->tags->$tag($args), @_;
        };
      #}
    } elsif($tag eq 'trow') {
      #if($target->can('tr') && $tag ne 'meta') { # meta is a special case 
      #  $method = $target->can('tr');
      #} else {
        $method = Sub::Util::set_subname "${target}::tr" => sub {
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
          return $form->content_tag('tr', $args, $content), @_;
        };
      #}
    } elsif($form->can($tag)) {
      #if($target->can($tag)) {
      #  $method = $target->can($tag);
      #} else {
        $method = Sub::Util::set_subname "${target}::${tag}" => sub {
          ## return $form->safe_concat($form->$tag(@_));
          ## Will ponder this, it seems to be a performance hit
          my @args = ();
          while(@_) {
            last if
              !defined($_[0])
              || (Scalar::Util::blessed($_[0])||'') eq 'Valiant::HTML::SafeString';
            push @args, shift;
            if(ref $_[0] eq 'ARRAY') {
              my $inner = shift;
              my @content = map {
                (Scalar::Util::blessed($_) && $_->isa($class)) ? $_->get_rendered : $_;
              } @{$inner};
              push @args, $class->safe_concat(@content);
            }
          }
          return $form->$tag(@args), @_; 
        };
      #}
    } else {
      die "No such tag '$tag' for view";
    }

    # I do this dance so that the exported methods can be called as both a function
    # and as a method on the target instance.

    Moo::_Utils::_install_tracked($target, $tag, $method);
    Moo::_Utils::_install_tracked($target, "_tag_${tag}", \&{"${target}::${tag}"});
    Moo::_Utils::_install_tracked($target, $tag, sub {
      my $view = shift if Scalar::Util::blessed($_[0]) && $_[0]->isa($target);
      local $form->{view} = $view if $view;
      local $form->{context} = $view->ctx if $view;
      local $form->{controller} = $view->ctx->controller if $view;
      return $target->can("_tag_${tag}")->(@_);
    });
  }
}

sub _install_views {
  my $class = shift;
  my $target = shift;
  my %view_info = @_;

  foreach my $name (keys %view_info) {
    my $method = Sub::Util::set_subname "${target}::${name}" => sub {
      my @args = ();
      while(@_) {
        last if
          !defined($_[0])
          || ((Scalar::Util::blessed($_[0])||'') eq 'Valiant::HTML::SafeString')
          || (Scalar::Util::blessed($_[0]) && $_[0]->isa($class));
        push @args, shift;
      }
      return $form->view->ctx->view($view_info{$name}, @args), @_ if @_;
      return $form->view->ctx->view($view_info{$name}, @args);
    };
    Moo::_Utils::_install_tracked($target, $name, $method);
    Moo::_Utils::_install_tracked($target, "_view_${name}", \&{"${target}::${name}"});
    Moo::_Utils::_install_tracked($target, $name, sub {
      my $view = shift if Scalar::Util::blessed($_[0]) && $_[0]->isa($target);
      local $form->{view} = $view if $view;
      local $form->{context} = $view->ctx if $view;
      local $form->{controller} = $view->ctx->controller if $view;
      return $target->can("_view_${name}")->(@_);
    });
  }
}

sub safe { shift; return Valiant::HTML::SafeString::safe(@_) }
sub raw { shift; return Valiant::HTML::SafeString::raw(@_) }
sub safe_concat { shift; return Valiant::HTML::SafeString::safe_concat(@_) }
sub escape_html { shift; return Valiant::HTML::SafeString::escape_html(@_) }

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

sub path {
  my $self = shift;
  my $c = $self->ctx;
  my $action_proto = shift;
  my @args = @_;

  # already is an $action
  if(Scalar::Util::blessed($action_proto) && $action_proto->isa('Catalyst::Action')) {
    die "We can't create a URI from '$action_proto' with the given arguments"
      unless my $uri = $c->uri_for($action_proto, @args);
    return $uri;
  }

  return $action_proto if Scalar::Util::blessed($action_proto) && $action_proto->isa('URI'); # common error 
      
  # Hard error if the spec looks wrong...
  die "$action_proto is not a string" unless ref \$action_proto eq 'SCALAR';
      
  my $action;
  if($action_proto =~/^\/?\*/) {
    carp "$action_proto is not a named action"
      unless $action = $c->dispatcher->get_action_by_path($action_proto);
  } elsif($action_proto=~m/^(.*)\:(.+)$/) {
    carp "$1 is not a controller"
      unless my $controller = $c->controller($1||'');
    carp "$2 is not an action for controller ${\$controller->component_name}"
      unless $action = $controller->action_for($2);
  } elsif($action_proto =~/\//) {
    my $path = eval {
      $action_proto=~m/^\// ?
      $action_proto : 
      $c->controller->action_for($action_proto)->private_path;
    } || carp "Error: $@ while trying to get private path for $action_proto";
    carp "$action_proto is not a full or relative private action path" unless $path;
    carp "$path is not a private path" unless $action = $c->dispatcher->get_action_by_path($path);
  } elsif($action = $c->controller->action_for($action_proto)) {
    # Noop
  } else {
    # Fallback to static
    $action = $action_proto;
  }

  carp "We can't create a URI from $action with the given arguments: @{[ join ', ', @args ]}]}"
    unless my $uri = $c->uri_for($action, @args);

  return $uri  
}

around 'get_rendered' => sub {
  my ($orig, $self, @args) = @_;
  $self->ctx->stash->{__view_for_code} = $self->form->view if $self->has_code;
  local $form->{view} = $self; # Evil Hack lol
  local $form->{context} = $self->ctx;
  local $form->{controller} = $self->ctx->controller;
  return $self->$orig(@args);
};

around 'execute_code_callback' => sub {
  my ($orig, $self, @args) = @_;
  my $old_view = delete $self->ctx->stash->{__view_for_code};
  local $form->{view} = $old_view; # Evil Hack lol
  local $form->{context} = $old_view->ctx;
  local $form->{controller} = $old_view->ctx->controller;
  return $self->$orig(@args);
};

__PACKAGE__->config(content_type=>'text/html');

=head1 NAME

Catalyst::View::Valiant - Per Request, strongly typed Views in code

=head1 SYNOPSIS

    package Example::View::HTML::Home;

    use Moo;
    use Catalyst::View::Valiant
      -tags => qw(div blockquote form_for fieldset),
      -utils => qw($sf),
      -views => 'HTML::Layout', 'HTML::Navbar';

    has info => (is=>'rw', predicate=>'has_info');
    has person => (is=>'ro', required=>1);

    sub render($self, $c) {
      html_layout page_title => 'Sign In', sub($layout) {
        html_navbar active_link=>'/',
        blockquote +{ if=>$self->has_info, 
          class=>"alert alert-primary", 
          role=>"alert" }, $self->info,
        div $self->person->$sf('Welcome {:first_name} {:last_name} to your Example Homepage');
        div {if=>$self->person->profile_incomplete}, [
          blockquote {class=>"alert alert-primary", role=>"alert"}, 'Please complete your profile',
          form_for $self->person, sub($self, $fb, $person) {
            fieldset [
              $fb->legend,
              div +{ class=>'form-group' },
                $fb->model_errors(+{show_message_on_field_errors=>'Please fix validation errors'}),
              div +{ class=>'form-group' }, [
                $fb->label('username'),
                $fb->input('username'),
                $fb->errors_for('username'),
              ],
              div +{ class=>'form-group' }, [
                $fb->label('password'),
                $fb->password('password'),
                $fb->errors_for('password'),
              ],
              div +{ class=>'form-group' }, [
                $fb->label('password_confirmation'),
                $fb->password('password_confirmation'),
                $fb->errors_for('password_confirmation'),
              ],
            ],
            fieldset $fb->submit('Complete Account Setup'),
          ],
        ],
      };
    }

    1;

=head1 DESCRIPTION

B<WARNINGS>: Experimental code that I might need to break back compatibility in order
to fix issues.  

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
      my $view = $c->view('HTML::Home', person=>$c->user);
      if( # Some condition ) {
        $view->info('You have been logged in');
      }
    }

    1;

This will then work with the commonly used L<Catalyst::Action::RenderView> or my 
L<Catalyst::ActionRole::RenderView> to produce a view response and set it as the
response body.  

Additionally, this view allows you to import HTML tags from L<Valiant::HTML::Util::TagBuilder>
as well as HTML tag helper methods from L<Valiant::HTML::Util::FormTags> and
L<Valiant::HTML::Util::Form> into your view code.  You should take a look at the
documentation for those modules to see what is available.  Since L<Valiant::HTML::Util::TagBuilder>
includes basic flow control and logic this gives you a bare minimum templating system
that is completely in code.  You can import some utility methods as well as other views
into your view (please see the L</EXPORTS> section below for more details).  This is currently
lightly documented so I recommend also looking at the test cases as well as the example
Catalyst application included in the distribution under the C<example/> directory.

=head1 ATTRIBUTES

This class inherits all of the attributes from L<Catalyst::View::BasePerRequest>

=head1 METHODS

This class inherits all of the methods from L<Catalyst::View::BasePerRequest> as well as:

=head2 form

Returns the current C<form> object.

=head2 tags

A convenience method to get the C<tags> object from the current C<form>.

=head2 safe

Marks a string as safe to render by first escaping it and then wrapping it in a L<Valiant::HTML::SafeString> object.

=head2 raw

Marks a string as safe to render by wrapping it in a L<Valiant::HTML::SafeString> object.

=head2 safe_concat

Given one or more strings and / or L<Valiant::HTML::SafeString> objects, returns
a new L<Valiant::HTML::SafeString> object that is the concatenation of all of the strings.

=head2 escape_html

Given a string, returns a new string that is the escaped version of the original string.

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

=head2 -tags

Export any HTML tag supported in L<Valiant::HTML::TagBuilder> as well as tag helpers from
L<Valiant::HTML::Util::FormTags> and L<Valiant::HTML::Util::Form>.  Please note the C<tr> tag
must be imported by the C<trow> name since C<tr> is a reserved word in Perl.

=head2 -utils

Export the following functions:

=over 4

=item $sf

    $person->$sf('Hi there {:first_name} {:last_name} !!')

Exports a coderef helper that wraps the C<sf> method in L<Valiant::HTML::TagBuilder>.  Useful when
you have an object whos methods you want as values in your view.

=item content

=item content_for

=item content_append

=item content_replace

=item content_around

Wraps the named methods from L<Catalyst::View::BasePerRequest> for export.  You can still call them
directly on the view object if you prefer.

=item path

Given an instance of L<Catalyst::Action> or the name of an action, returns the full path to that action
as a url.   Basically a wrapper over C<uri_for> that will die if it can't find the action.  It also
properly support relatively named actions.

=back

=head2 -views

Create export wrappers for the named Catalyst views.  Export names will be snake cased versions
of the given view names.

=head1 SUBCLASSING

You can subclass this view in order to provide your own default behavior and additional methods.

    package View::Example::View;

    use Moo;
    use Catalyst::View::Valiant
      -tags => qw(blockquote label_tag);

    sub formbuilder_class { 'Example::FormBuilder' }

    sub stuff2 {
      my $self = shift;
      $self->label_tag('test', sub {
        my $view = shift;
        die unless ref($view) eq ref($self);
      });
      return $self->tags->div('stuff2');
    }

    sub stuff3 :Renders {
      blockquote 'stuff3', 
      shift->div('stuff333')
    }

    1;

Then the view C<View::Example::View> can be used in exactly the same way as this view.

=head1 TIPS & TRICKS

=head2 Creating render methods

Often you will want to break up your render method into smaller chunks.  You can do this by
creating methods that return L<Valiant::HTML::SafeString> objects.  You can then call these
methods from your render method.  Here's an example:

    sub simple :Renders {
      my $self = shift;
      return div "Hey";
    }

You can then call this method from another render method:

    sub complex :Renders {
      my $self = shift;
      return $self->simple;
    }

Or use it directly in your main render method:

    sub render {
      my $self = shift;
      return $self->simple;
    }

Please note you need to add the ':Renders' attribute to your method in order for it to be
exported as a render method.  You don't need to do that on the main render method in your
class because we handle that for you.

=head2 Calling for view fragments

You can call for the response of any view's method wish is marked as a render method.

  package Example::View::Fragments;

    use Moo;
    use Catalyst::View::Valiant
      -tags => qw(div);

    sub stuff4 :Renders { div 'stuff4' }

    1;

Then in your main view:

  package Example::View::Hello;

    use Moo;
    use Catalyst::View::Valiant
      -views => qw(Fragments);

    sub render {
      my $self = shift;
      return fragment->stuff4;
    }

You can even call them in a controller:

    sub index :Path {
      my ($self, $c) = @_;
      $c->res->body($c->view('Fragments')->stuff4);
    }

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::Util::Form>, L<Valiant::HTML::Util::FormTags>,
L<Valiant::HTML::Util::Tagbuilder>,  L<Valiant::HTML::SafeString>.

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
