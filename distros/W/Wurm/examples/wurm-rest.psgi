use strict;
use warnings;
use lib qw(lib);

#
# To try this example, from the Wurm distribution run this command:
#
#   plackup examples/wurm-rest.psgi
#
# You should then be able to connect to http://localhost:5000/.
#

# We have upgraded to mob!  More memory utilization!  Slower response!
# But you get to use '->' in your handlers!  \o/
use Wurm qw(mob let);
use Wurm::Grub::REST;
use Data::UUID;
use Encode;
use JSON::XS;
use Tenjin;

my $grub = Wurm::Grub::REST->new
->get(
  # This is the single-item interface.
  sub {
    my $meal = shift;


    # Retrieves a piece of text from the internal memory.
    my $text = $meal->mind->{meld}{$meal->grit->{id}};

    # Since this is expected to pull a record from the database,
    # Wurm::Grub::REST will generate an HTTP C<404> if you don't
    # return a response.
    return
      unless defined $text;

    # Here we set up the grit and let the serializer do the work.
    $meal->grit->{text} = $text;
    return cerealoze($meal, 'item.html');
  },

  # This is the collection interface.
  sub {
    my $meal = shift;

    # We just give the serializer the entire database.
    $meal->grit->{items} = $meal->mind->{meld};
    return cerealoze($meal, 'index.html');
  },
)
->post(sub {
  my $meal = shift;

  # Here we are adding an item to the database.

  # It can be a good idea to use body_parameters to ensure you are
  # only pulling data from the POST body and not query parameters.
  my $text = $meal->req->body_parameters->{text};

  # We can just return here.  The default REST handler will
  # return an HTTP C<400>.
  return
    unless defined $text;

  # We got some text!  Let's keep it forever!
  $meal->grit->{id} = gen_uuid($meal);
  $meal->mind->{meld}{$meal->grit->{id}} = $text;

  # Since we generated an id in C<$meal->grit->{id}> 
  return Wurm::_302($meal->env->{PATH_INFO});
})
->patch(sub {
  my $meal = shift;

  # Patch can be used on single items or whole collections
  # but here we are only using the single-item interface.

  # Obviously it needs to exist first.  Wurm::Grub::REST will
  # return an HTTP C<404> if we don't generate a response.
  return
    unless exists $meal->mind->{meld}{$meal->grit->{id}};

  # Same as with POST, this eliminates parameter mixing.
  my $text = $meal->req->body_parameters->{text};

  # If we delete the id, an HTTP C<400> will be returned.
  # Otherwise an HTTP C<404> would be returned as above.
  # Wurm::Grub::REST remembers if we were PATCHing a single
  # item and checks if it is still set when we return.
  delete $meal->grit->{id}, return
    unless defined $text;

  # Browsers technically do not support PATCH in forms
  # so we return a 204 expecting an automated agent.
  $meal->mind->{meld}{$meal->grit->{id}} = $text;
  return Wurm::_204;
})
->delete(sub {
  my $meal = shift;

  # Delete operates almost exactly like Patch but
  # is for either deleting items or collections.

  # Here an HTTP C<404> will be returned.
  return
    unless exists $meal->mind->{meld}{$meal->grit->{id}};

  # Again, browser support of DELETE in forms is non-existent.
  delete $meal->mind->{meld}{$meal->grit->{id}};
  return Wurm::_204;
})
;

sub cerealoze {
  my $meal = shift;
  # We can delegate to a particular serializer based on what
  # Wurm::Grub::REST detected in the C<Accept> header.
  # It puts flags in C<$meal->vent> that you can check or even
  # use to stash type-specific data.
  return $meal->vent->{json} ? to_json($meal) : to_html($meal, @_);
}

# ID generator
sub gen_uuid {
  my $meal = shift;
  my $uuid = $meal->mind->{uuid};
  return lc $uuid->to_string($uuid->create);
}

# HTML serializer
sub to_html {
  my $meal = shift;
  my $file = shift;
  my $html = $meal->mind->{html}->render($file, $meal->grit);
  return Wurm::_200('text/html', Encode::encode('UTF-8', $html));
}

# JSON serializer
sub to_json {
  my $meal = shift;
  my $json = $meal->mind->{json}->encode($meal->grit);
  return Wurm::_200('application/json', $json);
}

# Package it all up into the C<$mind>.
my $mind = {
  meld => {'Wurm::Grub::REST' => 'Hello, Wurm!'},
  uuid => Data::UUID->new,
  json => JSON::XS->new->utf8,
  html => Tenjin->new({
    path => ['./examples/html/rest'], strict => 1, cache => 0
  }),
};

# Wrapp that app!
# Wurm::Grub::REST creates a Wurm::let so C<->molt()> is required.
my $app = Wurm::wrapp($grub->molt, $mind);
$app
