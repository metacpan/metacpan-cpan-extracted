use strict;
use warnings;
use Test::More;
use Type::Guess;

my $SQLite = Type::Guess->with_roles("+SQL::SQLite");
my $SQLiteDate = Type::Guess->with_roles("+SQL::SQLite", "+DateTime");

# -------------------------
# Str -> VARCHAR / TEXT
# -------------------------

my $t = $SQLite->new(qw/foo bar baz/);
is($t->to_sql, "VARCHAR(3)", "short strings -> VARCHAR(n)");

$t = $SQLite->new(qw/foo bar bazbaz/);
is($t->to_sql, "VARCHAR(6)", "VARCHAR width tracks longest value");

$t = $SQLite->new("x" x 1024, "y" x 512);
is($t->to_sql, "TEXT", "long strings -> TEXT");

$t = $SQLite->new("x" x 1023, "y" x 512);
is($t->to_sql, "VARCHAR(1023)", "just under threshold -> VARCHAR");

# -------------------------
# Int -> INTEGER
# -------------------------

$t = $SQLite->new(1, 2, 3, 42);
is($t->to_sql, "INTEGER", "integers -> INTEGER");

$t = $SQLite->new(-1, -2, -3);
is($t->to_sql, "INTEGER", "negative integers -> INTEGER");

$t = $SQLite->new(0, 1, 2);
is($t->to_sql, "INTEGER", "zero inclusive -> INTEGER");

# -------------------------
# Num -> FLOAT
# -------------------------

$t = $SQLite->new(1.1, 2.2, 3.3);
is($t->to_sql, "FLOAT", "floats -> FLOAT");

$t = $SQLite->new(-1.5, 2.5, -3.5);
is($t->to_sql, "FLOAT", "signed floats -> FLOAT");

$t = $SQLite->new(1.0, 2.0, 3.0);
is($t->to_sql, "INTEGER", "whole number floats -> INTEGER");

# -------------------------
# DateTime (no +DateTime role) -> VARCHAR / TEXT
# -------------------------

$t = $SQLite->new(qw/2024-01-01 2024-06-15 2023-12-31/);
is($t->to_sql, "VARCHAR(10)", "dates without +DateTime role -> VARCHAR");

# -------------------------
# DateTime (with +DateTime role) -> DATETIME
# -------------------------

$t = $SQLiteDate->new(qw/2024-01-01 2024-06-15 2023-12-31/);
is($t->to_sql, "DATETIME", "dates with +DateTime role -> DATETIME");

$t = $SQLiteDate->new(qw/2024-01-01T09:30:00 2024-06-15T12:00:00 2023-12-31T23:59:59/);
is($t->to_sql, "DATETIME", "datetimes with +DateTime role -> DATETIME");

# -------------------------
# tolerance interaction
# -------------------------

$SQLite->tolerance(0.25);

$t = $SQLite->new(1, 2, 3, "a");
is($t->to_sql, "INTEGER", "Int with tolerance -> INTEGER");

$t = $SQLite->new(1.1, 2.2, 3.3, "a");
is($t->to_sql, "FLOAT", "Num with tolerance -> FLOAT");

$SQLite->tolerance(0);

# -------------------------
# skip_empty interaction
# -------------------------

$SQLite->skip_empty(1);

$t = $SQLite->new(1, 2, "", 3, 4);
is($t->to_sql, "INTEGER", "Int with empty skipped -> INTEGER");

$t = $SQLite->new(qw/foo bar/, "", qw/baz/);
is($t->to_sql, "VARCHAR(3)", "Str with empty skipped -> VARCHAR");

$SQLite->skip_empty(0);

$t = $SQLite->new(1, 2, "", 3, 4);
is($t->to_sql, "INTEGER", "integer and empty -> INTEGER");
$SQLite->skip_empty(1);

# -------------------------
# forced type
# -------------------------

$t = $SQLite->new(1, 2, 3);
$t->type("Str");
is($t->to_sql, "VARCHAR(" . $t->length . ")", "forced Str -> VARCHAR");

$t = $SQLite->new(qw/foo bar baz/);
$t->type("Int");
is($t->to_sql, "INTEGER", "forced Int -> INTEGER");

done_testing;
