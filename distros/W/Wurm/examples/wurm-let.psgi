use strict;
use warnings;
use lib qw(lib);

use Wurm qw(let);
use Data::Dumper;

# Re-implements the Hello, World app with let.
sub build_grub {
  my ($name) = @_;

  return Wurm::let->new
  ->gate(sub {
    my $meal = shift;
    $meal->{vent}{to} = ucfirst $name;
    push @{$meal->{grit}{path}}, $name. '/gate';
    return;
  })
  ->neck(sub {
    my $meal = shift;
    push @{$meal->{grit}{path}}, $name. '/neck';
    return;
  })
  # The same as ->body(get       => sub { })
  # The same as ->body([qw(get)] => sub { })
  ->get(sub {
    my $meal = shift;
    push @{$meal->{grit}{path}}, $name. '/body:get';
    return;
  })
  ->tail(sub {
    my $meal = shift;
    push @{$meal->{grit}{path}}, $name. '/tail';
    return wrap_it_up($meal);
  })
};

sub wrap_it_up {
  my $meal = shift;

  my $path = join ', ', @{$meal->{grit}{path}};

  my $text = '';
  $text .= "$meal->{mind}{intro} $meal->{vent}{to},\n";
  $text .= "This is the path I took: $path\n";
  $text .= "This is what is in the tube: $meal->{tube}\n";
  $text .= "This is what I've seen: $meal->{seen}\n";

  return Wurm::_200('text/plain', $text);
}

# How many methods are called before the assignment is made?
# This is the 'root' grub.
my $grub = build_grub('root')
  ->case(sub {
    my $meal = shift;
    $meal->{vent}{to}   = 'Nobody';
    $meal->{grit}{path} = [ ];
    return $meal;
  })
  ->pore(sub {
    my ($res, $meal) = @_;
    $res->[2][0] = $res->[2][0]
      . ($res->[0] == 200 ? '' : "\n")
      . 'PSGI env: '. Dumper($meal->{env})
    ;
    return $res;
  })
;

{
  # C<grub()> will make a new grub for us.
  # Or use what we give it.
  my $what = $grub->grub(wurm => build_grub('wurm'));

  # Grubs molt to become pretty butterflies.
  # If you believe nested hashes of anonymous sub-routines are
  # beautiful.  Or butterflies.

  # Tubes require molted grubs.
  $what->tube($_ => build_grub($_)->molt)
    for qw(foo bar baz);

  # I don't... better not to ask questions.  This looks nasty.
  $grub->grub($_ => $what->molt->{tube}{$_})
    for qw(foo baz);

  # qux is already molted inside $what.  eww.
  # I told you it was special.
  my $qux = $what->grub(qux => build_grub('qux'));
  $qux->gate(sub {
    my ($meal) = @_;
    $meal->{vent}{to} = 'Lord Qux';
    push @{$meal->{grit}{path}}, '*/gate';
    return wrap_it_up($meal);
  });
}

# Now turn the... uh... thing into an application.
my $app = Wurm::wrapp($grub->molt, {intro => 'Hello'});
$app
