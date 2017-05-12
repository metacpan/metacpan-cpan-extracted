package Wurm::Grub::REST;

use strict;
use warnings;
use parent qw(Wurm::let);

use Wurm;

sub new {
  my ($self, $map) = @_;

  $map //= {
    'text/html'        => 'html',
    'application/json' => 'json',
    'text/xml'         => 'xml',
    'application/xml'  => 'xml',
  };

  die "invalid type map" unless 'HASH' eq ref $map;

  $self->SUPER::new->gate(sub {
    my $meal = shift;

    for my $accept (split ',', $meal->{env}{HTTP_ACCEPT}) {
      my $node = $map->{$accept};
      $meal->{vent}{$node} = 1
        if defined $node;
    }

    $meal->{grit}{id} = Wurm::bend($meal);
    return;
  });
}

sub get {
  my ($self, $one, $all) = @_;

  die "invalid handler" unless 'CODE' eq ref $one;
  die "invalid handler" unless 'CODE' eq ref $all;

  $self->SUPER::get(sub {
    my $meal = shift;
    my $cast = defined $meal->{grit}{id}
      ? $one->($meal)
      : $all->($meal)
    ;
    return defined $cast ? $cast : Wurm::_404();
  });
}

sub post {
  my ($self, $post) = @_;

  die "invalid handler" unless 'CODE' eq ref $post;

  $self->SUPER::post(sub {
    my $meal = shift;

    return Wurm::_400()
      if defined $meal->{grit}{id};

    my $cast = $post->($meal);
    return $cast
      if defined $cast;

    return Wurm::_400()
      unless defined $meal->{grit}{id};

    my $uri = $meal->{seen} // '';
    $uri .= '/' if '/' ne substr($uri, length($uri) - 1, 1);
    $uri .= $meal->{grit}{id};

    return Wurm::_201($uri);
  });
}

sub put {
  my ($self, $new, $old) = @_;

  die "invalid handler" unless 'CODE' eq ref $new;
  die "invalid handler" unless 'CODE' eq ref $old;

  $self->SUPER::put(sub {
    my $meal = shift;
    my $flag = defined $meal->{grit}{id};
    my $cast = $flag
      ? $old->($meal)
      : $new->($meal)
    ;
    return $cast
      if defined $cast;

    return Wurm::_400()
      unless defined $meal->{grit}{id};

    my $uri = $meal->{seen} // '';
    $uri .= '/' if '/' ne substr($uri, length($uri) - 1, 1);
    $uri .= $meal->{grit}{id};

    return $flag ? Wurm::_302($uri) : Wurm::_201($uri);
  });
}

sub patch {
  my ($self, $one, $all) = @_;

  die "invalid handler" unless 'CODE' eq ref $one;

  $self->SUPER::patch(sub {
    my $meal = shift;

    my $cast;
    if(defined $meal->{grit}{id}) {
      $cast = $one->($meal);
      return Wurm::_400() unless defined $meal->{grit}{id};
      return Wurm::_404() unless defined $cast;
    }
    else {
      return Wurm::_404() unless defined $all;
      $cast = $all->($meal);
      return Wurm::_400() unless defined $cast;
    }
    return $cast;
  });
}

sub delete {
  my ($self, $one, $all) = @_;

  die "invalid handler" unless 'CODE' eq ref $one;

  return $self->SUPER::delete(sub {
    my $meal = shift;

    my $cast;
    if(defined $meal->{grit}{id}) {
      $cast = $one->($meal);
      return Wurm::_400() unless defined $meal->{grit}{id};
      return Wurm::_404() unless defined $cast;
    }
    else {
      return Wurm::_404() unless defined $all;
      $cast = $all->($meal);
      return Wurm::_400() unless defined $cast;
    }
    return $cast;
  });
}

'.oOo.' # in wurm i trust
__END__

=pod

=head1 NAME

Wurm::Grub::REST - Wurm::let grub for generating RESTful services.

=head1 SYNOPSIS

  use Wurm qw(mob let);
  use Wurm::Grub::REST;
  use Data::UUID;
  use JSON::XS;
  use Tenjin;

  my $grub = Wurm::Grub::REST->new
  ->get(
    sub {
      my $meal = shift;

      my $item = $meal->mind->{meld}{$meal->grit->{id}};
      return
        unless defined $item;

      $meal->grit->{item} = $item;
      return $meal->vent->{json}
        ? to_json($meal)
        : to_html($meal, 'item.html')
      ;
    },
    sub {
      my $meal = shift;

      $meal->grit->{items} = $meal->mind->{meld};
      return $meal->vent->{json}
        ? to_json($meal)
        : to_html($meal, 'index.html')
      ;
    },
  )
  ->post(sub {
    my $meal = shift;

    my $text = $meal->req->parameters->{text};
    return
      unless defined $text;

    $meal->grit->{id} = gen_uuid($meal);
    $meal->mind->{meld}{$meal->grit->{id}} = $text;
    return Wurm::_302($meal->env->{PATH_INFO});
  })
  ->patch(sub {
    my $meal = shift;

    return
      unless exists $meal->mind->{meld}{$meal->grit->{id}};

    my $text = $meal->req->parameters->{text};
    return
      unless defined $text;

    $meal->mind->{meld}{$meal->grit->{id}} = $text;
    return Wurm::_204;
  })
  ->delete(sub {
    my $meal = shift;

    return
      unless exists $meal->mind->{meld}{$meal->grit->{id}};

    delete $meal->mind->{meld}{$meal->grit->{id}};
    return Wurm::_204;
  })
  ;

  sub gen_uuid {
    my $meal = shift;
    my $uuid = $meal->mind->{uuid};
    return lc $uuid->to_string($uuid->create);
  }

  sub to_html {
    my $meal = shift;
    my $file = shift;
    my $html = $meal->mind->{html}->render($file, $meal->grit);
    return Wurm::_200('text/html', $html);
  }

  sub to_json {
    my $meal = shift;
    my $json = $meal->mind->{json}->encode($meal->grit);
    return Wurm::_200('application/json', $json);
  }

  my $mind = {
    meld => {'Wurm::Grub::REST' => 'Hello, Wurm!'},
    uuid => Data::UUID->new,
    json => JSON::XS->new->utf8,
    html => Tenjin->new({
      path => ['./examples/html/rest'], strict => 1, cache => 0
    }),
  };

  my $app = Wurm::wrapp($grub->molt, $mind);
  $app

=head1 DESCRIPTION

B<Wurm::Grub::REST> is a L<Wurm::let> to help build REST-enabled
services.  It provides a library of light-weight handler wrappers
that attempt to conform to the REST protocol specification.

=head1 METHODS

Please see the documentation for L<Wurm::let> for a description
of super-class methods.  Below is a list of overriden methods:

=over

=item new($accept_map)

Creates a new L<Wurm::let> object with a gate handler installed
that will inspect the C<HTTP_ACCEPT> request variable for possible
response content types.  The C<$accept_map> parameter can be
used to specify a custom mapping between a mime-type and a key
name that will be set in C<$meal-E<gt>{vent}>.  If no map is given,
a default map is installed with the following values:

  text/html        => html
  application/json => json
  text/xml         => xml
  application/xml  => xml

The purpose of this is to make response encoding decisions easier.
When the HTTP C<Accept> header is set properly, this should
allow you to do something like:

  sub handler {
    my $meal = shift;

    ...

    if   ($meal->{vent}{json}) { return to_json($meal); }
    elsif($meal->{vent}{xml} ) { return to_xml ($meal); }
    elsif($meal->{vent}{html}) { return to_html($meal); }

    # no type handler installed; someone else's problem
    return;
  }

The gate handler will also modify C<$meal-E<gt>{tube}> by calling
C<Wurm::bend()> assuming that any atom returned is an application
record id.  This is stored in C<$meal-E<gt>{grit}{id}> for further
down-stream dispatching and access to the application.  From the
client point-of-view, this simply looks like:

  'http://.../path/to/rest'

and

  'http://.../path/to/rest/$id'

=item get($one, $all)

Adds an HTTP C<GET> body handler to implement record and collection
indexing and retrieval.

If a record id is present, the C<$one> handler is called.  Otherwise
the C<$all> handler is called.  Each are expected to return a
response upon success.  If no response is returned, an HTTP C<404>
is returned instead.

=item post($post)

Adds an HTTP C<POST> body handler to implement record creation.

If a record id is present, an HTTP C<400> is generated.  Otherwise
the request is dispatched to the handler in C<$post> which may
return its own response.  If no response is returned an HTTP
C<400> will be generated if C<$meal-E<gt>{grit}{id}> is not
defined.  Otherwise an HTTP <201> will be generated with the
C<Location> header set to the URL of the new resource.

=item put($old, $new)

Adds an HTTP C<PUT> body handler to implement record
modification and creation.

If a record id is present, the C<$old> hander is called.  Otherwise
the C<$new> handler is called.  Each are expected to return a
response upon success.  If no record id is present in
C<$meal-E<gt>{grit}{id}> after calling the handler, an HTTP C<400>
response is returned.  Otherwise a redirect to the resource URL
will be generated with the code set to C<201> for new records and
C<302> for old records.

=item patch($one, $all)

Adds an HTTP C<PATCH> body handler to implement record
and collection patching.

If a record id is present, the C<$one> handler is called and is
expected to generate a response upon success.  An HTTP C<400> will
be generated if the record id is removed from C<$meal-E<gt>{grit}{id}>.
An HTTP C<404> is generated if the handler does not generate a response.

If no record id is present, an HTTP C<404> will be returned if the
handler in C<$all> is not defined.  If a handler is defined, it will
be called expecting to return a response.  If no response is returned
an HTTP C<400> is generated.

=item delete($delete)

Adds an HTTP C<DELETE> body handler to implement record
and collection deletion.

If a record id is present, the C<$one> handler is called and is
expected to generate a response upon success.  An HTTP C<400> will
be generated if the record id is removed from C<$meal-E<gt>{grit}{id}>.
An HTTP C<404> is generated if the handler does not generate a response.

If no record id is present, an HTTP C<404> will be returned if the
handler in C<$all> is not defined.  If a handler is defined, it will
be called expecting to return a response.  If no response is returned
an HTTP C<400> is generated.

=back

=head1 SEE ALSO

=over

=item L<Wurm>

=item L<Wurm::let>

=back

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 LICENSE

This software is information.
It is subject only to local laws of physics.

=cut
