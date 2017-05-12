
package State;

use VSO;

subtype 'State::Name' => 
  as      'Str',
  where   { length($_) > 0 },
  message { "Must have a length greater than zero - [$_] is invalid." };

subtype 'State::Population' =>
  as      'Int',
  where   { $_ > 0 },
  message { "Population must be greater than zero" };

subtype 'State::FuncRef'  =>
  as      'CodeRef',
  where   sub { 1 };

coerce 'State::FuncRef' =>
  from  'Str',
  via   sub { my $val = $_; return sub { $val } };

coerce 'State::FuncRef' =>
  from  'CodeRef',
  via   { $_ };

has 'name' => (
  is        => 'ro',
  isa       => 'State::Name',
  required  => 1,
#  'where'     => sub { m{Colorado} }
);

has 'capital' => (
  is        => 'ro',
  isa       => 'Maybe[Str]',
  required  => 1,
);

has 'population' => (
  is        => 'rw',
  isa       => 'State::Population',
  required  => 1,
);


has 'foo' => (
  is        => 'ro',
  isa       => 'HashRef[Foo]',
  required  => 1,
);

has 'func' => (
  is        => 'ro',
  isa       => 'State::FuncRef',
  required  => 1,
  coerce    => 1,
);

before 'population' => sub {
  my ($s, $new_value, $old_value) = @_;
  
  warn "About to change population from '$old_value' to '$new_value'\n";
};

after 'population' => sub {
  my ($s, $new_value, $old_value) = @_;
  
  warn "Changed population from '$old_value' to '$new_value'\n";
};

sub greet
{
  my $s = shift;
  
  warn "Greetings from ", $s->name, "!\n";
  return wantarray ? ( 1..10 ) : 1;
}# end greet()

before 'greet' => sub {
  my $s = shift;
  
  warn "About to greet you (first-defined, second-run)...\n";
};

before 'greet' => sub {
  my $s = shift;
  
  warn "About to greet you (second-defined, first-run)...\n";
};

after 'greet' => sub {
  my $s = shift;
  
  warn "After greeting you (first-defined, first-run)...\n";
};

after 'greet' => sub {
  my $s = shift;
  
  warn "After greeting you (second-defined, second-run)...\n";
};

1;# return true:

