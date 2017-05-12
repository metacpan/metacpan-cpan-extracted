use strict;
use warnings;
use lib qw(lib);

use Wurm;
use Data::Dumper;

# Wurm applications are defined by a structure of anonymous
# sub-routines that get called based on the incoming request
# and where they live within the application tree.

# When a request is received it is first packaged into a
# C<$meal> which is then dispatched to a series of handlers.
# Handlers are expected to inspect, filter, and otherwise
# act on the request until a PSGI response is generated.
# Once a response is generated, dispatching halts and the
# response is returned back up the Plack chain.
# This process is called "folding".

# The internet really can be a series of tubes.
sub build_tube {
  my ($name) = @_;

  # Here we create a basic component skeleton which we will use
  # to build our application.  We use closures to capture
  # $name but sub-routines can also simply be copied throughout
  # the dispatch tree to duplicate behavior without creating
  # new sub-routines, modules, classes, or objects.

  return ({
    # Gate handlers are always called first when folding.
    # They are primarily meant for inspection, filtering,
    # and resource setup.

    # They will be called as Wurm traverses the URL path from
    # the request.  Wurm maintains C<PATH_INFO> information in
    # C<$meal->{tube}>.  As a request is dispatched, non-C<'/'>
    # atoms and a trailing C<'/'> are removed and concatenated
    # to C<$meal->{seen}>.  You can check C<$meal->{tube} eq ''>
    # to see if this component will be targeted for further dispatch.
    gate => sub {
      my $meal = shift;
      $meal->{log}->({level => 'debug',
        message => "$name ))) $meal->{tube}"});
      $meal->{vent}{to} = ucfirst $name
        if $meal->{tube} eq '';
      push @{$meal->{grit}{path}}, $name. '/gate';
      return;
    },

    # What is not seen here are Tube handlers.  Tube handlers are
    # what define the path ways within your application for dispatching
    # down C<PATH_INFO>.  Since this is just a skeleton, we will tie the
    # application together with tube handlers later.

    # Neck handlers are called when C<$meal->{tube} eq ''>.
    # Unless more advanced dispatching is performed at run-time,
    # this starts the final dispatch chain.
    neck => sub {
      my $meal = shift;
      push @{$meal->{grit}{path}}, $name. '/neck';
      return;
    },

    # Body handlers are used to dispatch based on the request method.
    # Unlike gate, neck, and tail handlers these require a slightly
    # more complex structure.  You must provide a C<HASH> that
    # contains handlers keyed off of the lower cased request method
    # you would like that code to process.
    body => {
      get => sub {
        my $meal = shift;
        push @{$meal->{grit}{path}}, $name. '/body:get';
        return;
      },
    },

    # Tail handlers are the final possible step in a dispatch chain
    # before a C<404> is generated.  While you can easily return a
    # response from a body handler, tail handlers give you the option
    # of tying multiple body response handling paths into a single spot.
    tail => sub {
      my $meal = shift;
      push @{$meal->{grit}{path}}, $name. '/tail';
      return wrap_it_up($meal);
    },
  })
};

# Look ma... modularity.
# More advanced applications might have a template engine or other
# data transformers contained in C<$meal->{mind}>.  C<$meal->{grit}>
# and C<$meal->{vent}> data areas are for your application to use
# as needed on a per-request basis.
sub wrap_it_up {
  my $meal = shift;

  my $path = join ', ', @{$meal->{grit}{path}};

  my $text = '';
  $text .= "$meal->{mind}{intro} $meal->{vent}{to},\n";
  $text .= "This is the path I took: $path\n";
  $text .= "This is what is in the tube: $meal->{tube}\n";
  $text .= "This is what I've seen: $meal->{seen}\n";

  # Wurm provides some easy response handlers.
  # They are probably too simple to be useful.
  # Good luck.
  return Wurm::_200('text/plain', $text);
}


# Now let's build the app!


# This is the root "controller".
my $wurm = build_tube('root');

# The case routine can be defined to munge the request meal.
# It is only called once at request entry.
$wurm->{case} = sub {
  my $meal = shift;
  $meal->{vent}{to}   = 'Nobody';
  $meal->{grit}{path} = [ ];
  return $meal;
};

# The pore routine can be defined to munge the response.
# It is only ever called once at request exit.
$wurm->{pore} = sub {
  my ($res, $meal) = @_;
  $res->[2][0] = $res->[2][0]
    . ($res->[0] == 200 ? '' : "\n")
    . 'PSGI env: '. Dumper($meal->{env})
  ;
  return $res;
};


# Tinker-tubes!

# Tubes are sub-tree structures that Wurm will re-dispatch to
# during a request based on elements in the URL path.  They
# have the exact same structure as described above with the
# exception that C<case()> and C<pore()> handlers are ignored.

# When a request begins, the HTTP C<PATH_INFO> information is
# copied to C<$meal->{tube}> with a leading C<'/'> removed.
# Wurm will remove a non-C<'/'> atom and trailing C<'/'> from
# C<$meal->{tube}> during each dispatch cycle and will
# re-dispatch the request to the folding tree defined under
# that atom.  If no folding tree is found for a particular atom,
# a C<404> is returned.

# This builds a path route for 'wurm/' and 'wurm'.
$wurm->{tube}{wurm} = build_tube('wurm');

# This builds more path routes ('wurm/{foo,bar,baz,qux}/').
$wurm->{tube}{wurm}{tube}{$_} = build_tube($_)
  for qw(foo bar baz qux);

# Now we have 'foo/' and 'baz/'.
$wurm->{tube}{$_} = $wurm->{tube}{wurm}{tube}{$_}
  for qw(foo baz);

# qux is special.
# It has a gate handler that will always return a 200.
# This will act like a catch all for 'wurm/qux/*'.
$wurm->{tube}{wurm}{tube}{qux}{gate} = sub {
  my $meal = shift;
  $meal->{vent}{to} = 'Lord Qux';
  push @{$meal->{grit}{path}}, '*/gate';
  return wrap_it_up($meal);
};

# Now turn the closure nightmare into a PSGI application.
# The second argument to wrapp() is the C<$meal->{mind}>.
# You can use it to store application-wide state like
# configuration or other global resources.
my $app = Wurm::wrapp($wurm, {intro => 'Hello'});
$app
