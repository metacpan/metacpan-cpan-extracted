package # hide from PAUSE
  Catalyst::ActionRole::Verbs;

{
  package Catalyst::ActionRole::Verbs::Utils::MethodNotAllowed;
   
  use Moose;
  use namespace::clean -except => 'meta';
    
  extends 'CatalystX::Utils::HttpException';
  
  has resource => (is=>'ro', required=>1);
  has allowed_methods => (is=>'ro', isa=>'ArrayRef[Str]', required=>1);
  has attempted_method => (is=>'ro', isa=>'Str', required=>1);

  has '+status' => (is=>'ro', init_arg=>undef, default=>sub {405});
  has '+errors' => (
    is=>'ro',
    init_arg=>undef, 
    default=>sub { ["HTTP Method '@{[ $_[0]->attempted_method ]}' not permitted for resource '@{[ $_[0]->resource ]}'.  Can only be: @{[ join ', ', @{$_[0]->allowed_methods||[]} ]}"] },
  );
   
  __PACKAGE__->meta->make_immutable;
}

use Moose::Role;
use Catalyst::ActionRole::Verbs::Utils::MethodNotAllowed;
use Catalyst::Utils;

requires 'attributes', 'list_extra_info', 'execute', 'dispatch';

our $VERSION = '0.001';
our @VERBS = qw(GET POST PUT DELETE HEAD OPTIONS PATCH TRACE CONNECT);

has allowed_verbs => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_build_allowed_verbs' );

  sub _build_allowed_verbs {
    my $self = shift;
    my @core_allowed = $self->can('allowed_http_methods') ? $self->allowed_http_methods : ();
    my %allow = map { $_=~s/^\s+|\s+$//g; $_=>1  } map { split(',',$_) } (@{$self->attributes->{Allow} || []}, @core_allowed);
    my @verbs =
      grep { 
        $self->class->can("${_}_${\$self->name}")
        || $self->class->can($_)
        || $allow{$_};
      } @VERBS;
    return \@verbs;
  }

has verb_action_handlers => (
  is => 'ro',
  required => 1,
  lazy => 1,
  builder => '_build_verb_action_handlers' );

  sub _build_verb_action_handlers {
    my $self = shift;
    my %handler_map = ();
    foreach my $verb (@{$self->allowed_verbs||[]}) {
      if($self->class->can("${verb}_${\$self->name}")) {
        $handler_map{$verb} = "${verb}_${\$self->name}";
      } elsif($self->class->can($verb)) {
        $handler_map{$verb} = $verb;
      }
    }
    return \%handler_map;
  }

around 'list_extra_info' => sub {
  my ($orig, $self, @args) = @_;
  my @allowed_methods = sort @{$self->allowed_verbs||[]};
  my %info = %{$self->$orig(@args)||+{}};
  if(exists $info{HTTP_METHODS}) {
    push @{$info{HTTP_METHODS}}, @allowed_methods;
  } else {
    $info{HTTP_METHODS} = \@allowed_methods;
  }
  return \%info;
};

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  my $method = $ctx->req->method;
  my @allowed = @{$self->allowed_verbs||[]};
  $ctx->response->header( 'Allow' => \@allowed );

  return Catalyst::ActionRole::Verbs::Utils::MethodNotAllowed->throw(attempted_method=>$method, allowed_methods=>\@allowed, resource=>$ctx->req->uri)
    unless grep { $_ eq $method } @allowed; # TODO need to thow not allowed exception

  my ($first, @return) = $self->$orig($controller, $ctx, @args);
  if($first) {
    $ctx->stash->{__execute} = [$first, @return];
  } else {
    $ctx->stash->{__execute} = [];
  }
  return $first, @return;
};

around 'dispatch', sub {
  my ($orig, $self, $ctx, @args) = @_;
  my $ret = $self->$orig($ctx, @args);
  my $method = $ctx->req->method;
  my @return = @{ delete $ctx->stash->{__execute}||[] };

  return $ret unless my $action_handler = $self->verb_action_handlers->{$method};
  return $self->_dispatch_to_verb($ctx, $action_handler, @return);
};

sub _dispatch_to_verb {
  my ($self, $ctx, $action_handler, @return) = @_;

  ## TODO @return seems to contain undef when it really means empty.
  #return $ctx->forward($action_handler, [@{$ctx->req->args}, @return]);
  return $ctx->forward($action_handler, $ctx->req->args)
}

1;

=head1 NAME

Catalyst::ActionRole::Verbs - Dispatch by HTTP Verbs

=head1 SYNOPSIS

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub myaction :Chained(/) Does('Methods') CaptureArgs(1) {
      my ($self, $c, $arg) = @_;
      # When this action is matched, first execute this action's
      # body, then an action matching the HTTP method or the not
      # implemented one if needed.
    }

      sub myaction_GET :Action {
        my ($self, $c, $arg) = @_;
        # Note that if the 'parent' action has args or capture-args, those are
        # made available to a matching method action.
      }

      sub myaction_POST {
        my ($self, $c, $arg) = @_;
        # We match the subroutine name whether its an action or not.  If you
        # make it an action, as in the _GET above, you are allowed to apply
        # action roles (which is the main advantage to this AFAIK).
      }

      sub myaction_not_implemented {
        my ($self, $c, $arg) = @_;
        # There's a sane default for this, but you can override as needed.
      }

      sub next_action_in_chain_1 :Chained(myaction) Args(0) { ... }

      sub next_action_in_chain_2 :Chained(myaction) Args(0) { ... }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is a L<Moose::Role> version of the classic L<Catalyst::Action::REST> action
class.  The intention is to offer some of the popular functionality that comes
with L<Catalyst::Action::REST> in a more modular, 'build what you need' package.

Bulk of this documentation and test cases derive from L<Catalyst::Action::REST>
with the current author's gratitude.

This Action Role handles doing automatic method dispatching for requests.  It
takes a normal Catalyst action, and changes the dispatch to append an
underscore and method name.  First it will try dispatching to an action with
the generated name, and failing that it will try to dispatch to a regular
method.

    sub foo :Local :Does('Methods') {
      ... do setup for HTTP method specific handlers ...
    }
 
    sub foo_GET {
      ... do something for GET requests ...
    }
 
    # alternatively use an Action
    sub foo_PUT : Action {
      ... do something for PUT requests ...
    }
 
For example, in the example above, calling GET on "/foo" would result in
the foo_GET method being dispatched.
 
If a method is requested that is not implemented, this action will
return a status 405 (Method Not Found).  It will populate the "Allow" header
with the list of implemented request methods.  You can override this behavior
by implementing a custom 405 handler like so:
 
   sub foo_not_implemented {
      ... handle not implemented methods ...
   }
 
If you do not provide an _OPTIONS subroutine, we will automatically respond
with a 200 OK.  The "Allow" header will be populated with the list of
implemented request methods. If you do not provide an _HEAD either, we will
auto dispatch to the _GET one in case it exists.

=head1 VERSUS Catalyst::Action::REST

L<Catalyst::Action::REST> works fine doesn't it?  Why offer a new approach?  There's
a few reasons:

First, when L<Catalyst::Action::REST> was written we did not have
L<Moose> and the only way to augment functionality was via inheritance.  Now that
L<Moose> is common we instead say that it is typically better to use a L<Moose::Role>
to augment a class function rather to use a subclass.  The role approach is a smaller
hammer and it plays nicer when you need to combine several roles to augment a class
(as compared to multiple inheritance approaches.).  This is why we brought support for
action roles into core L<Catalyst::Controller> several years ago.  Letting you have
this functionality via a role should lead to more flexible systems that play nice
with other roles.  One nice side effect of this 'play nice with others' is that we
were able to hook into the 'list_extra_info' method of the core action class so that
you can now see in your developer mode debug output the matched http methods, for
example:

    .-------------------------------------+----------------------------------------.
    | Path Spec                           | Private                                |
    +-------------------------------------+----------------------------------------+
    | /myaction/*/next_action_in_chain    | GET, HEAD, POST /myaction (1)          |
    |                                     | => /next_action_in_chain (0)           |
    '-------------------------------------+----------------------------------------'

This is not to say its never correct to use an action class, but now you have the
choice.

Second, L<Catalyst::Action::REST> has the behavior as noted of altering the core
L<Catalyst::Request> class.  This might not be desired and has always struck the
author as a bit too much side effect / action at a distance.

Last, L<Catalyst::Action::REST> is actually a larger distribution with a bunch of
other features and dependencies that you might not want.  The intention is to offer
those bits of functionality as standalone, modern components and allow one to assemble
the parts needed, as needed.

This action role is for the most part a 1-1 port of the action class, with one minor
change to reduce the dependency count.  Additionally, it does not automatically
apply the L<Catalyst::Request::REST> action class to your global L<Catalyst>
action class. This feature is left off because its easy to set this yourself if
desired via the global L<Catalyst> configuration and we want to follow and promote
the idea of 'do one thing well and nothing surprising'.

B<NOTE> There is an additional minor change in how we handle return values from actions.  In
general L<Catalyst> does nothing with an action return value (unless in an auto action).
However this might not always be the future case, and you might have used that return value
for something in your custom code.  In L<Catalyst::Action::REST> the return value was
always the return of the dispatched sub action (if any).  We tweaked this so that we use
the sub action return value, BUT if that value is undefined, we use the parent action
return value instead.

We also dropped saying 'REST' when all we are doing is dispatching on HTTP method.
Since the time that the first version of L<Catalysts::Action::REST> was released to
CPAN our notion of what 'REST' means has greatly evolved so I think its correct to
change the name to be functionality specific and to not confuse people that are new
to the REST discipline.

This action role is intended to be used in all the places
you used to use the action class and have the same results, with the exception
of the already mentioned 'not messing with the global request class'.  However
L<Catalyst::Action::REST> has been around for a long time and is well vetted in
production so I would caution care with changing your mission critical systems
very quickly.

=head1 VERSUS NATIVE METHOD ATTRIBUTES

L<Catalyst> since version 5.90030 has offered a core approach to dispatch on the
http method (via L<Catalyst::ActionRole::HTTPMethods>).  Why still use this action role
versus the core functionality?  ALthough it partly comes down to preference and the
author's desire to give current users of L<Catalyst::Action::REST> a path forward, there
is some functionality differences beetween the two which may recommend one over the
other.  For example the core method matching does not offer an automatic default
'Not Implemented' response that correctly sets the OPTIONS header.  Also the dispatch
flow between the two approaches is different and when using chained actions one 
might be a better choice over the other depending on how your chains are arranged and
your desired flow of action.

=head1 METHODS
 
This role contains the following methods.

=head2 get_allowed_methods

Returns a list of the allowed methods.

=head2 dispatch
 
This method overrides the default dispatch mechanism to the re-dispatching
mechanism described above.

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>

Author list from L<Catalyst::Action::REST>
 
  Adam Jacob E<lt>adam@stalecoffee.orgE<gt>, with lots of help from mst and jrockway
  Marchex, Inc. paid me while I developed this module. (L<http://www.marchex.com>)
 
=head1 CONTRIBUTORS

The following contributor list was copied from L<Catalyst::Action::REST>
from where the bulk of this code was copied.
 
Tomas Doran (t0m) E<lt>bobtfish@bobtfish.netE<gt>
 
John Goulah
 
Christopher Laco
 
Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>
 
Hans Dieter Pearcey
 
Brian Phillips E<lt>bphillips@cpan.orgE<gt>
 
Dave Rolsky E<lt>autarch@urth.orgE<gt>
 
Luke Saunders
 
Arthur Axel "fREW" Schmidt E<lt>frioux@gmail.comE<gt>
 
J. Shirley E<lt>jshirley@gmail.comE<gt>
 
Gavin Henry E<lt>ghenry@surevoip.co.ukE<gt>
 
Gerv http://www.gerv.net/
 
Colin Newell <colin@opusvl.com>
 
Wallace Reis E<lt>wreis@cpan.orgE<gt>
 
AndrÃ© Walker (andrewalker) <andre@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2006-2015 the above named AUTHOR and CONTRIBUTORS
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
