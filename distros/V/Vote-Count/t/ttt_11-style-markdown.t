use strict;
use warnings;
use Test::More tests => 3;
use Test::Fatal       qw/ exception /;
use Vote::Count::TextTableTiny qw/ generate_table /;
use utf8;

# verbose flag for extra verbosity.
# prove -lv t/11-style.t :: v
my $verbose = shift @ARGV || 0;

subtest '_md_header_rule', sub {
  my $widthref = [ 12,6,9 ];
  my $alignref = [ 'l','l','l' ];
  is(
    Vote::Count::TextTableTiny::_md_header_rule(
      { 'compact' => 0 }, $widthref, $alignref ),
    qq%|:-------------|:-------|:----------|\n%,
    '3 cols left align'
  );
  $alignref = [qw/c c c/];
  is(
    Vote::Count::TextTableTiny::_md_header_rule(
      { 'compact' => 1 }, $widthref, $alignref  ),
    qq%|:----------:|:----:|:-------:|\n%,
    '3 cols center align with compact option'
  );
  $widthref = [ 3,4,5,6,20];
  $alignref = [ 'r','c','l','r','c' ];
  is(
    Vote::Count::TextTableTiny::_md_header_rule({},$widthref, $alignref ),
    qq%|----:|:----:|:------|-------:|:--------------------:|\n%,
    '5 cols mixed align'
  );
};

subtest '_md_validate_data Enforce Bar', sub {
  my $badrows = [
    [ 'Pokemon',   'Type',         'Seen' ],
    [ 'Rattata',   'Normal',       10199 ],
    [ 'Ekans',     'Poison',       536 ],
    [ 'Vileplume', 'Grass|Poison', 4 ],
  ];
  like(
    exception {
      my $failure = generate_table(
        'rows'  => $badrows,
        'style' => 'markdown'
      )
    },
      qr/invalid Markdown!/,
      "Unescaped '|' is fatal",
  );
  $badrows->[0][0] = '|Card';
  like(
    exception {
      my $failure = generate_table(
        'rows'  => $badrows,
        'style' => 'markdown'
      )
    },
      qr/invalid Markdown!/,
      "Unescaped '|' is fatal (test beginning of field)",
  );
  $badrows->[0] = ['Card','Type', 'Seen|'];
  like(
    exception {
      my $failure = generate_table(
        'rows'  => $badrows,
        'style' => 'markdown'
      )
    },
      qr/invalid Markdown!/,
      "Unescaped '|' is fatal (test end of field)",
  );
};


subtest 'generate_table (markdown)', sub {
my $rows = [
   [ 'Pokemon', 'Type', 'Seen' ],
   [ 'Rattata', 'Normal', 10199 ],
   [ 'Ekans', 'Poison', 536 ],
   [ 'Vileplume', 'Grass / Poison', 4 ],
];
my $table;

my $testname = 'markdown with no options';
$table = generate_table(
    'rows' => $rows,
    'style' => 'markdown' );
warn qq%TEST "$testname" Generated Table:\n$table\n% if $verbose;
is($table,q%| Pokemon   | Type           | Seen  |
|-----------|----------------|-------|
| Rattata   | Normal         | 10199 |
| Ekans     | Poison         | 536   |
| Vileplume | Grass / Poison | 4     |%,
$testname
);

push @{$rows}, ([ 'Escape', 'the \|','Bar']);

$testname = 'markdown aligned right showing escaped bar';
$table = generate_table(
    'rows' => $rows,
    'align' => 'r',
    'compact' => 0,
    'style' => 'markdown' );

warn qq%TEST "$testname" Generated Table:\n$table\n% if $verbose;
 is($table,q%|   Pokemon |           Type |  Seen |
|----------:|---------------:|------:|
|   Rattata |         Normal | 10199 |
|     Ekans |         Poison |   536 |
| Vileplume | Grass / Poison |     4 |
|    Escape |         the \| |   Bar |%,
$testname );

$testname = 'markdown with compact and mixed alignments';
$table = generate_table(
    'rows' => $rows,
    'align' => ['r','c','l' ],
    'compact' => 1,
    'style' => 'markdown' );

warn qq%TEST \"$testname\" Generated Table:\n$table\n% if $verbose;
is($table,q%|  Pokemon|     Type     |Seen |
|--------:|:------------:|:----|
|  Rattata|    Normal    |10199|
|    Ekans|    Poison    |536  |
|Vileplume|Grass / Poison|4    |
|   Escape|    the \|    |Bar  |%,
$testname);
};

done_testing();
