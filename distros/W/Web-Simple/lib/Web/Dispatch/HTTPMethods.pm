package Web::Dispatch::HTTPMethods;

use strictures 1;
use Web::Dispatch::Predicates qw(match_method);
use Scalar::Util qw(blessed);
use Exporter 'import';

our @EXPORT = qw(GET HEAD POST PUT DELETE OPTIONS);

sub HEAD(&;@) { method_helper(HEAD => @_) }
sub GET(&;@) { method_helper(GET => @_) }
sub POST(&;@) { method_helper(POST => @_) }
sub PUT(&;@) { method_helper(PUT => @_) }
sub DELETE(&;@) { method_helper(DELETE => @_) }
sub OPTIONS(&;@) { method_helper(OPTIONS => @_) }

{
  package Web::Dispatch::HTTPMethods::Endpoint;

  sub new { bless { map { $_=>0 } @EXPORT }, shift }
  sub hdrs { 'Content-Type' => 'text/plain' }

  sub create_implicit_HEAD {
    my $self = shift;
    if($self->{GET} && not $self->{HEAD}) {
      $self->{HEAD} = sub { [ @{$self->{GET}->(@_)}[0,1], []] };
    }
  }

  sub create_implicit_OPTIONS {
    my $self = shift;
    $self->{OPTIONS} = sub {
      [200, [$self->hdrs, Allow=>$self->allowed] , [] ];
    };
  }

  sub allowed { join ',', grep { $_[0]->{$_} } @EXPORT }

  sub to_app {
    my $self = shift;
    my $implicit_HEAD = $self->create_implicit_HEAD;
    my $implicit_OPTIONS = $self->create_implicit_OPTIONS;

    return sub {
      my $env = shift;
      if($env->{REQUEST_METHOD} eq 'HEAD') {
        $implicit_HEAD->($env);
      } elsif($env->{REQUEST_METHOD} eq 'OPTIONS') {
        $implicit_OPTIONS->($env);
      } else {
        [405, [$self->hdrs, Allow=>$self->allowed] , ['Method Not Allowed'] ];
      }
    };
  }
}

sub isa_endpoint {
  blessed($_[0]) &&
    $_[0]->isa('Web::Dispatch::HTTPMethods::Endpoint')
}

sub endpoint_from { return $_[-1] }
sub new_endpoint { Web::Dispatch::HTTPMethods::Endpoint->new(@_) }

sub method_helper {
  my $predicate = match_method(my $method = shift);
  my ($code, @following ) = @_;
  endpoint_from( my @dispatchers = 
    scalar(@following) ? ($predicate, @_) : ($predicate, @_, new_endpoint)
   )->{$method} = $code;

  die "Non HTTP Method dispatcher detected in HTTP Method scope"
   unless(isa_endpoint($dispatchers[-1]));

  return @dispatchers; 
}


1;

=head1 NAME

Web::Dispatch::HTTPMethods - Helpers to make RESTFul Dispatchers Easier

=head1 SYNOPSIS

    package MyApp:WithHTTPMethods;

    use Web::Simple;
    use Web::Dispatch::HTTPMethods;

    sub as_text {
      [200, ['Content-Type' => 'text/plain'],
        [$_[0]->{REQUEST_METHOD}, $_[0]->{REQUEST_URI}] ]
    }

    sub dispatch_request {
      sub (/get) {
        GET { as_text(pop) }
      },
      sub (/get-head) {
        GET { as_text(pop) }
        HEAD { [204,[],[]] },
      },
      sub (/get-post-put) {
        GET { as_text(pop) }  ## NOTE: no commas separating http methods
        POST { as_text(pop) }
        PUT { as_text(pop) }
      },
    }

=head1 DESCRIPTION

Exports the most commonly used HTTP methods as subroutine helpers into your
L<Web::Simple> based application.
Use of these methods additionally adds an automatic HTTP code 405
C<Method Not Allowed> response if none of the HTTP methods match for a given dispatch and
also adds a dispatch rule for C<HEAD> if no C<HEAD> exists but a C<GET> does
(in which case the C<HEAD> returns the C<GET> dispatch with an empty body.)

We also add support at the end of the chain for the OPTIONS method.
This defaults to HTTP 200 OK + Allows http headers.

We also try to set correct HTTP headers such as C<Allows> as makes sense based
on your dispatch chain.

The following dispatch chains are basically the same:

    sub dispatch_request {
      sub (/get-http-methods) {
        GET { [200, ['Content-Type' => 'text/plain'], ['Hello World']] }
      },
      sub(/get-classic) {
        sub (GET) { [200, ['Content-Type' => 'text/plain'], ['Hello World']] },
        sub (HEAD)  { [200, ['Content-Type' => 'text/plain'], []] },
        sub (OPTIONS)  {
          [200, ['Content-Type' => 'text/plain', Allows=>'GET,HEAD,OPTIONS'], []];
        },
        sub () {
          [405, ['Content-Type' => 'text/plain', Allows=>'GET,HEAD,OPTIONS'], 
           ['Method Not Allowed']]
        },
      }
    }

The idea here is less boilerplate to distract the reader from the main point of
the code and also to encapsulate some best practices.

B<NOTE> You currently cannot mix http method style and prototype sub style in
the same scope, as in the following example:

    sub dispatch_request {
      sub (/get-head) {
        GET { ... }
        sub (HEAD) { ... }
      },
    }

If you try this our code will notice and issue a C<die>.  If you have a good use
case please bring it to the authors.  

=head2 EXPORTS

This automatically exports the following subroutines:

    GET
    PUT
    POST
    HEAD
    DELETE
    OPTIONS

=head1 AUTHOR

See L<Web::Simple> for AUTHOR

=head1 CONTRIBUTORS

See L<Web::Simple> for CONTRIBUTORS

=head1 COPYRIGHT

See L<Web::Simple> for COPYRIGHT

=head1 LICENSE

See L<Web::Simple> for LICENSE

=cut

