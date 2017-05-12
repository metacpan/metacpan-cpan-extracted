use strict;
use warnings;
use Test::More;
# Use "+ResultSet" to get both ResultSet type and is_ResultSet predicate
# or simply spell out exactly what you need. Both methods below.
use Types::DBIx::Class qw(
    +ResultSet
    +ResultSource
    Row is_Row
    Schema is_Schema
);

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

ok(is_Schema($schema),'is_Schema');
ok(is_ResultSet(my $rset = $schema->resultset('Fluffles')),'is_ResultSet');
ok(is_ResultSource(my $rsource = $rset->result_source),'is_ResultSource');
ok(is_Row(my $row = $rset->first),'is_Row');

ok(!is_Schema($rset),'!is_Schema');
ok(!is_ResultSet($schema),'!is_ResultSet');
ok(!is_ResultSource($row),'!is_ResultSource');
ok(!is_Row($rsource),'!is_Row');

ok((my $fluff_row_type = Row['Fluffles'])->check($row),'Row Fluffles');
ok((ResultSet['Fluffles'])->check($rset),'ResultSet Fluffles');
ok((ResultSource['Fluffles'])->check($rsource),'ResultSource Fluffles');
ok((Schema[qr/Test/])->check($schema),'Schema Test');

ok(!(Schema['other'])->check($schema),'!Schema other');
ok(!(my $other_row_type = Row['other'])->check($row),'!Row other');
ok(!(ResultSet['other'])->check($rset),'!ResultSet other');
ok(!(ResultSource['other'])->check($rsource),'!ResultSource other');

my $validator = $fluff_row_type->compiled_check;
ok($validator->($row),'compiled_check succeeds');
$validator = $other_row_type->compiled_check;
ok(!$validator->($row),'compiled_check rejects bad type');

ok($fluff_row_type->assert_valid($row),'assert_valid');
ok(!eval{$other_row_type->assert_valid($row);1} &&
   $@ =~ /Fluffles.*other/,'assert_valid dies on bad type');


done_testing;
