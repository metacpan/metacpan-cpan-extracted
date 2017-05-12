#!/usr/bin/perl -w

package Person;
use VSO;

enum 'Gender' => [qw( m f )];

our @people;

sub BUILD {
  push @people, shift;
}

has 'id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
  lazy      => 1,
  default   => sub {
    my ($s) = @_;
    return scalar(@people);
  }
);

has 'father_id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'mother_id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'first_name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'last_name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
);

has 'full_name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  lazy      => 1,
  default   => sub {
    join ', ', ( $_[0]->last_name, $_[0]->first_name );
  }
);

has 'gender' => (
  is        => 'ro',
  isa       => 'Gender',
  lazy      => 1,
  required  => 0,
  default   => sub {
    my $s = shift;
    # Guess our gender based on our relationship to our children:
    if( my $c = $s->children )
    {
      no warnings 'uninitialized';
      return $c->father_id eq $s->id ? 'm' : $c->mother_id eq $s->id ? 'f' : undef;
    }# end if()
    return;
  }
);

has 'dob' => (
  is        => 'ro',
  isa       => 'Int',
  required  => 1,
);

has 'father' => (
  is        => 'ro',
  isa       => 'Person',
  where     => sub { $_->id eq shift->father_id },
  required  => 0,
  lazy      => 1,
  weak_ref  => 1,
  default   => sub {
    my $s = shift;
    return unless $s->father_id;
    for( grep { (!$_->gender) || $_->gender eq 'm' } @people )
    {
      return $_ if $_->id eq $s->father_id;
    }# end for()
    return;
  }
);

has 'mother' => (
  is        => 'ro',
  isa       => 'Person',
  where     => sub { $_->id eq shift->mother_id },
  required  => 0,
  lazy      => 1,
  weak_ref  => 1,
  default   => sub {
    my $s = shift;
    return unless $s->mother_id;
    for( grep { (!$_->gender) || $_->gender eq 'f' } @people )
    {
      return $_ if $_->id eq $s->mother_id;
    }# end for()
    return;
  }
);

has 'parents' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    [
      grep { $_ } (
        $s->mother,
        $s->father
      )
    ]
  }
);

has 'children' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  where     => sub {
    my $s = shift;
    grep { $_->id eq $s->id } @{ $_->parents }
  },
  required  => 0,
  lazy      => 1,
  default   => sub {
    my $s = shift;
    no warnings 'uninitialized';
    if( $s->gender && $s->dob )
    {
      my $func = $s->gender eq 'm' ? 'father_id' : 'mother_id';
      return [
        grep {
          $_->dob > $s->dob &&
          $_->$func eq $s->id
        } @people
      ];
    }
    elsif( $s->gender )
    {
      my $func = $s->gender eq 'm' ? 'father_id' : 'mother_id';
      return [
        grep {
          $_->$func eq $s->id
        } @people
      ];
    }
    elsif( $s->dob )
    {
      my $func = $s->gender eq 'm' ? 'father_id' : 'mother_id';
      return [
        grep {
          $_->dob > $s->dob
        } @people
      ];
    }
    else
    {
      return [
        grep {
          $_->father_id eq $s->id ||
          $_->mother_id eq $s->id
        } @people
      ];
    }# end if()
  }
);

has 'siblings' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    no warnings 'uninitialized';
    my %saw = ( );
    return [
      grep { $_->id ne $s->id }
        grep { ! $saw{$_->id}++ }
          map { @{ $_->children } } @{ $s->parents }
    ];
  }
);

has 'brothers' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    [
      grep { $_->gender && $_->gender eq 'm' }
        @{ shift->siblings }
    ]
  }
);

has 'sisters' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    [
      grep { $_->gender && $_->gender eq 'f' }
        @{ shift->siblings }
    ]
  }
);

has 'uncles' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    my @uncles;
    for( @{ $s->parents } )
    {
      push @uncles, @{ $_->brothers };
      push @uncles, grep { $_->gender eq 'm' } @{ $_->spouses };
    }# end for()
    return \@uncles;
  }
);

has 'aunts' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    my @aunts;
    for( @{ $s->parents } )
    {
      push @aunts, @{ $_->sisters };
      push @aunts, grep { $_->gender eq 'f' } @{ $_->spouses };
    }# end for()
    return \@aunts;
  }
);

has 'spouses' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    my %saw = ( );

    if( $s->gender eq 'm' )
    {
      return [
        map { $_->mother }
          grep { $_->mother_id && ! $saw{$_->mother_id}++ }
            @{ $s->children }
      ];
    }
    elsif( $s->gender eq 'f' )
    {
      return [
        map { $_->father }
          grep { $_->father_id && ! $saw{$_->father_id}++ }
            @{ $s->children }
      ];
    }# end if()
  }
);

has 'grandfathers' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    
    [
      grep { $_ && $_->gender eq 'm' } @{ $s->grandparents }
    ]
  }
);

has 'grandmothers' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    
    [
      grep { $_ && $_->gender eq 'f' } @{ $s->grandparents }
    ]
  }
);

has 'grandparents' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    
    my @gp = ( );
    if( my $m = $s->mother )
    {
      push @gp, grep { $_ } ( $m->mother, $m->father );
    }# end if()
    if( my $f = $s->father )
    {
      push @gp, grep { $_ } ( $f->mother, $f->father );
    }# end if()
    
    return \@gp;
  }
);

has 'great_grandparents' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    [
      grep { $_ } map { $_->mother, $_->father } @{ $s->grandparents }
    ]
  }
);

has 'great_aunts' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    [
      map { @{ $_->sisters } } @{ $s->grandparents }
    ]
  }
);

has 'great_uncles' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    [
      grep { $_ } map { @{ $_->brothers } } @{ $s->grandparents }
    ]
  }
);

has 'first_cousins' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    my %saw = ( );
    [
      grep { $_ && ! $saw{$_->id}++ } map { @{ $_->children } } grep { $_ } (
        @{ $s->aunts },
        @{ $s->uncles }
      )
    ]
  }
);

has 'second_cousins' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    my %saw = ( );
    [
      grep { $_ && ! $saw{$_->id}++ } map { @{ $_->children } } grep { $_ } (
        @{ $s->great_aunts },
        @{ $s->great_uncles }
      )
    ]
  }
);

has 'third_cousins' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    my %saw = ( );
    [
      grep { $_ && ! $saw{$_->id}++ } map { @{ $_->children } } (
        @{ $s->second_cousins }
      )
    ]
  }
);

has 'grandchildren' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    [
      grep { $_ } map { @{ $_->children } } @{ $s->children }
    ]
  }
);

has 'great_grandchildren' => (
  is        => 'ro',
  isa       => 'ArrayRef[Person]',
  lazy      => 1,
  default   => sub {
    my $s = shift;
    [
      grep { $_ } map { @{ $_->children } } @{ $s->grandchildren }
    ]
  }
);


package main;

use strict;
use warnings 'all';
use Data::Faker;

my $faker = Data::Faker->new();

our @people = ( );
my ($mother, $father);
my $twenty_years = 60 * 60 * 24 * 365 * 20;

my $max = 1000;
for( 1..$max )
{
  warn "$_/$max\n" if $_ % 1000 == 0;
  my $f       = rand() > 0.5 ? $father : undef;
  my $m       = rand() > 0.5 ? $mother : undef;
  my $dob     = $m ? $m->{dob} + $twenty_years : random_dob();
  my $gender  = rand() > 0.5 ? 'm' : 'f';
  my $person = Person->new(
    father_id   => $f ? $f->id : undef,
    mother_id   => $m ? $m->id : undef,
    first_name  => $faker->first_name,
    last_name   => $f ? $f->{last_name} : $faker->last_name,
    dob         => $dob,
    gender      => $gender,
  );
  
  if( rand() > 0.5 )
  {
    $gender eq 'm' ? $father = $person : $mother = $person;
  }# end if()
  
  push @people, $person;
}# end for()


my $num = 1;
for( @people )
{
  warn $num++, "/" . $max . "\n";
  warn $_->full_name, "\n";
  if( my @spouses = @{ $_->spouses } )
  {
    warn join( "\n", map { "\tSpouse: " . $_->full_name } @spouses ), "\n";
  }# end if()

  if( my $f = $_->father )
  {
    warn "\tFather: ", $f->full_name, "\n";
  }# end if()
  if( my $m = $_->mother )
  {
    warn "\tMother: ", $m->full_name, "\n";
  }# end if()
  
  if( my @g = @{ $_->spouses } )
  {
    warn "\tSpouses:\n";
    foreach my $c ( @g )
    {
      warn "\t  * ", $c->full_name, "\n";
    }# end foreach()
  }# end if()
  
  if( my @children = @{ $_->children } )
  {
    warn "\tChildren:\n";
    foreach my $c ( @children )
    {
      warn "\t  * ", $c->full_name, "\n";
    }# end foreach()
  }# end if()
  
  if( my @s = @{ $_->siblings } )
  {
    warn "\tSiblings:\n";
    for( @s )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @uncles = @{ $_->uncles } )
  {
    warn "\tUncles:\n";
    for( @uncles )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @aunts = @{ $_->aunts } )
  {
    warn "\tAunts:\n";
    for( @aunts )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->grandparents } )
  {
    warn "\tGrandparents:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->first_cousins } )
  {
    warn "\t1st Cousins:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->second_cousins } )
  {
    warn "\t2nd Cousins:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->third_cousins } )
  {
    warn "\t3rd Cousins:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->great_aunts } )
  {
    warn "\tGreat Aunts:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->great_uncles } )
  {
    warn "\tGreat Uncles:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->great_grandparents } )
  {
    warn "\tGreat Grandparents:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->grandchildren } )
  {
    warn "\tGrandchildren:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  if( my @c = @{ $_->great_grandchildren } )
  {
    warn "\tGreat Grandchildren:\n";
    for( @c )
    {
      warn "\t  * ", $_->full_name, "\n";
    }# end for()
  }# end if()
  
  warn "\n\n";
}# end for()


sub random_dob
{
  time() - ( 60 * 60 * 24 * int(rand() * 365) * 20 );
}# end random_dob()



