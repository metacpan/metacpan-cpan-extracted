use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP::UA;

{
  package Test2::Tools::HTTP::UA::Foo;
  use parent 'Test2::Tools::HTTP::UA';
  
  sub instrument
  {
    my($self) = @_;
    $self->ua->i(42);
  }
  
  sub request
  {
  }
  
  __PACKAGE__->register('Foo::Bar', 'instance');
  
  package Foo::Bar;
  
  sub new
  {
    bless {}, 'Foo::Bar';
  }
  
  sub i
  {
    my($self, $value) = @_;
    $self->{i} = $value;
  }
}

my $foobar  = Foo::Bar->new;
my $wrapper = Test2::Tools::HTTP::UA->new($foobar);

isa_ok $wrapper, 'Test2::Tools::HTTP::UA';
ref_is( $wrapper->ua, $foobar );

is( $foobar->i, undef );

done_testing;
