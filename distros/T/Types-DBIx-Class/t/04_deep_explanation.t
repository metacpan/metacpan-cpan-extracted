use strict;
use warnings;
use Test::More;

use Types::DBIx::Class ':all';

# deep_explanation's API is subject to change, as of writing this,
# test it explicitly so cpantesters can warn me if it does.

# Sample DBIx::Class schema to test against
{
    package Test::Schema::Fluffles;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('fluffles');
    __PACKAGE__->add_columns(qw( fluff_factor ));
}

{
    package Test::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw(
        Fluffles
    ));
}

my $schema = Test::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;
$schema->resultset('Fluffles')->create({ fluff_factor => 9001 });

my ($rset) = $schema->resultset('Fluffles');
my $rsource = $rset->result_source;
my $row = $rset->first;

my %types = (Row => Row['other'],
             Schema => Schema['other'],
             ResultSet => ResultSet['other'],
             ResultSource => ResultSource->parameterize('other')
            );

BEGIN {
  # For each type in Types::DBIx::Class, check parameterized explanations

  sub foreach_type (&){
    my $to_run = shift;

    my @results;
    while (($_,my $type) = each %types) {
      push @results,$to_run->($type);
    }
    return @results;
  }
}

# Make sure Type::Tiny can tell our objects are paremterized, explainable
my $bad_types = join ',', foreach_type {
  my $type = shift;
  ok($type->is_parameterized, "is_parameterized $_") &&
    ok($type->parent->has_deep_explanation, "parent has_deep_explanation $_") ?
    () : $_;
};
$bad_types && BAIL_OUT "Type::Tiny won't call deep expanation for $bad_types";

# Check that we call deep_explain when needed, and that it looks OK
sub explain_like {
  my ($obj,$msg,$expected_reasons)=@_;
  foreach_type {
    my $type = shift;
    my $val = ref $obj eq "HASH" ? $obj->{$_} : $obj;
    my $explanations = $type->validate_explain($val,'$val');

    my $explanation=join "\n",@$explanations;
    diag $explanation unless
      like $explanation, $expected_reasons, "$msg-$_";
  }
}

explain_like undef,'undef',qr/is a subtype|Not a blessed reference/;

explain_like {
    Schema =>$schema,
    Row => $row,
    ResultSet => $rset,
    ResultSource => $rsource
},'explain',qr/variable .val type '.*?(ResultSource|Schema|ResultSet).*' is not a (\1|Row).other/;

done_testing;
