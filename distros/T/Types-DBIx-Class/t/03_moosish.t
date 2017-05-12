use strict;
use warnings;
use Test::More;

# Create the DBIx classes to test against
{
    package Test::Schema::Fluffles;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('fluffles');
    __PACKAGE__->add_columns(qw( fluff_factor ));
}

{
    package Test::Schema::Falafels;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('falafels');
    __PACKAGE__->add_columns(qw( falafel_factor ));
}

{
    package Test::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw(
        Fluffles
        Falafels
    ));
}

# Create types for the specific DBIx classes above,
# which inherit from Types::DBIx::Class.
# Would normally be in its own library.
BEGIN {
  package My::Fluffly::Types;
  use Type::Library -base;
  use Type::Utils -all;
  use Types::Standard qw(is_Int);
  use Types::DBIx::Class 'Row';
  use Sub::Quote ();

  class_type $_, {class => "Test::Schema::$_"} for qw(Falafels Fluffles);

  declare 'VeryFluffy',     as Row['Fluffles'], where { $_->fluff_factor > 500 };
  declare 'SomewhatFluffy', as Row['Fluffles'], where { $_->fluff_factor > 50 };

  declare 'PickyFluffiness',
    parent => Row['Fluffles'],
    # Generate a new "where" coderef...
    constraint_generator => sub {
      my ($threshold) = @_;
      die "threshold must an Int" unless defined $threshold && is_Int($threshold);
      return Sub::Quote::quote_sub "\$_->fluff_factor == $threshold";

      return sub {
        #Row(['Fluffles'])->check($_) &&
          $_->fluff_factor == $threshold;
      };
   };
}

my $Moosish_template = q{
    package My::$Moosish::Class;

    use $Moosish;
    use Types::DBIx::Class -types;
    BEGIN {My::Fluffly::Types->import(-types)}

    has str_schema      => ( is => 'rw', isa => Schema['Test::Schema'] );
    has regex_schema    => ( is => 'rw', isa => Schema[qr/schema/i]    );
    has other_schema    => ( is => 'rw', isa => Schema[qr/Other/]      );
    has falafels_rs     => ( is => 'rw', isa => ResultSet[Falafels]    );
    has fluffles_or_falafels_array => ( is => 'rw',
            isa => ResultSet [ [qw(Falafels Fluffles)] ] );
    has fluffles_or_falafels_union => ( is => 'rw',
            isa => ResultSet [ Falafels|Fluffles ] );
    has fluffles_source => ( is => 'rw', isa => ResultSource[Fluffles] );
    has falafel_row     => ( is => 'rw', isa => Row[Falafels]          );
    has any_row         => ( isa => Row, is => 'rw'                    );



    has very_fluffy_fluffle     => ( is => 'rw', isa => VeryFluffy     );
    has somewhat_fluffy_fluffle => ( is => 'rw', isa => SomewhatFluffy );

    has picky_fluffy_fluffle => ( is => 'rw', isa => PickyFluffiness[100] );
    __PACKAGE__->meta->make_immutable unless "$Moosish" eq "Moo";
    1;
};


sub tests_against {
my ($o,$n) = @_;
my $schema = Test::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;
$schema->resultset('Falafels')->create({ falafel_factor => 10 });
$schema->resultset('Fluffles')->create({ fluff_factor => 100 });
$schema->resultset('Fluffles')->create({ fluff_factor => 99 });


$o->str_schema($schema);
is $o->str_schema, $schema, 'Schema set successfully (Str Check) '.$n;

$o->regex_schema($schema);
is $o->regex_schema, $schema, 'Schema set successfully (Regex Check) '.$n;

ok ! eval { $o->other_schema($schema); 1 }, 'Non-matching schema rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'non-matching schema has type-constraint error '.$n;

ok ! eval { $o->other_schema(bless {}, "Other"); 1 }, 'Fake schema rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'Fake schema has type-constraint error '.$n;

ok ! eval { $o->str_schema(undef); 1 }, 'undef schema rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'undef schema has type-constraint error '.$n;


$o->falafels_rs($schema->resultset('Falafels'));
is $o->falafels_rs, $schema->resultset('Falafels'), 'Parameterizable resultset '.$n;

ok !eval {$o->falafels_rs($schema->resultset('Fluffles')); 1 }, 'Incorrect resultset rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'non-matching resultset has type-constraint error '.$n;

$o->fluffles_source($schema->resultset('Fluffles')->result_source);
is $o->fluffles_source, $schema->resultset('Fluffles')->result_source, 'Parameterizable result source '.$n;

ok !eval {$o->fluffles_source($schema->resultset('Falafels')->result_source); 1 }, 'Incorrect result source rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'non-matching result source has type-constraint error '.$n;

ok !eval {$o->fluffles_source(undef); 1 }, 'undef result source rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'undef result source has type-constraint error '.$n;

my $falafel_row = $schema->resultset('Falafels')->first;
$o->falafel_row($falafel_row);
is $o->falafel_row, $falafel_row, 'Parameterizable row Falafels '.$n;

my $fluffles_row = $schema->resultset('Fluffles')->first;
ok !eval {$o->falafel_row($fluffles_row); 1 }, 'Incorrect row rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'Incorrect row gives type-constraint error '.$n;

ok !eval {$o->falafel_row(undef); 1 }, 'Undefined row rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'Undefined row gives type-constraint error '.$n;

ok !eval {$o->falafel_row("abc"); 1 }, 'Non-object row rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'Non-object row gives type-constraint error '.$n;

$o->any_row($fluffles_row);
is $o->any_row, $fluffles_row, 'any_row accepts Fluffles '.$n;

$o->any_row($falafel_row);
is $o->any_row, $falafel_row, 'any_row accepts Falafels '.$n;

ok !eval {$o->any_row("abc"); 1 }, 'Non-object row rejected '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'string "abc" gives type-constraint error '.$n;

$o->somewhat_fluffy_fluffle($fluffles_row);
is $o->somewhat_fluffy_fluffle, $fluffles_row, 'subtyped parameterizable row '.$n;

ok ! eval { $o->very_fluffy_fluffle( $fluffles_row ); 1 }, 'somewhat fluffy fluffle fails very_fluffy_fluffle constraint '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'somewhat-fluffy fluffle has appropriate type-constraint error '.$n;

$o->picky_fluffy_fluffle($fluffles_row);
is $o->picky_fluffy_fluffle, $fluffles_row, 'sub-subtyped parameterizable row '.$n;

$fluffles_row = $schema->resultset('Fluffles')->search({ fluff_factor => 99 })->first;
ok ! eval { $o->picky_fluffy_fluffle( $fluffles_row ); 1 }, 'somewhat (less) fluffy fluffle fails picky_fluffy_fluffle constraint '.$n;
like $@, qr/(does|did) not pass( the)? type constraint/, 'somewhat (less) fluffy fluffle has appropriate type-constraint error '.$n;

$o->fluffles_or_falafels_array($schema->resultset('Fluffles'));
$o->fluffles_or_falafels_array($schema->resultset('Falafels'));
is $o->fluffles_or_falafels_array, $schema->resultset('Falafels'), 'Parameterizable resultset (multiple choice array) '.$n;
$o->fluffles_or_falafels_union($schema->resultset('Falafels'));
$o->fluffles_or_falafels_union($schema->resultset('Fluffles'));
is $o->fluffles_or_falafels_union, $schema->resultset('Fluffles'), 'Parameterizable resultset (union) '.$n;
}


# Object modules we could test with, and their minimum version
my %obj_modules_versions =
  (
   Moo   => '1.001000',
   Moose => '2.0600',
   Mouse => '1.00'
  );
my @obj_modules;
while (my ($mod,$vers)=each %obj_modules_versions) {
  push @obj_modules,$mod if eval "package Sandbox::$mod;use $mod $vers;1"
}
unless (@obj_modules){
  plan skip_all => "Without Moo or Moose or Mouse, nothing to test";
}
for my $obj_module (@obj_modules) {
  # Build the class using Moo, Moose, or Mouse
  $_ = $Moosish_template;
  s/\$Moosish/$obj_module/g;
  eval or BAIL_OUT "Cannot compile $obj_module version of test class:\b$@";
  my $o = eval "My::${obj_module}::Class->new"
    or BAIL_OUT "Cannot instantiate My::${obj_module}::Class\n$@";
  tests_against($o,$obj_module);
}

done_testing;

