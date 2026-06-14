use strict;
use warnings;
use Test::More;
use Type::Guess;

my $PG       = Type::Guess->with_roles("+SQL::Pg");
my $PGDate   = Type::Guess->with_roles( "+DateTime", "+SQL::Pg",);

# -------------------------
# Str -> VARCHAR / TEXT
# -------------------------

my $t = $PG->new(qw/foo bar baz/);
is($t->to_sql, "VARCHAR(3)", "short strings -> VARCHAR(n)");

$t = $PG->new(qw/foo bar bazbaz/);
is($t->to_sql, "VARCHAR(6)", "VARCHAR width tracks longest value");

$t = $PG->new("x" x 1024, "y" x 512);
is($t->to_sql, "TEXT", "long strings -> TEXT");

$t = $PG->new("x" x 1023, "y" x 512);
is($t->to_sql, "VARCHAR(1023)", "just under threshold -> VARCHAR");

# -------------------------
# Int -> INTEGER / BIGINT
# -------------------------

$t = $PG->new(1, 2, 3, 42);
is($t->to_sql, "INTEGER", "small integers -> INTEGER");

$t = $PG->new(-1, -2, -3);
is($t->to_sql, "INTEGER", "negative integers -> INTEGER");


$t = $PG->new(999999999, 111111111);
is($t->to_sql, "INTEGER", "9 digit integers -> INTEGER");

$t = $PG->new(1000000000, 2000000000);
is($t->to_sql, "BIGINT", "10 digit integers -> BIGINT");
# -------------------------
# Num -> DECIMAL(n,p)
# -------------------------

$t = $PG->new(1.1, 2.2, 3.3);
is($t->to_sql, sprintf("DECIMAL(%d,%d)", $t->length, $t->precision), "floats -> DECIMAL(n,p)");

$t = $PG->new(1.10, 2.20, 3.30);
is($t->to_sql, sprintf("DECIMAL(%d,%d)", $t->length, $t->precision), "trailing zero floats -> DECIMAL(n,p)");

$t = $PG->new(-1.5, 2.5, -3.5);
is($t->to_sql, sprintf("DECIMAL(%d,%d)", $t->length, $t->precision), "signed floats -> DECIMAL(n,p)");

$t = $PG->new(1.123456789, 2.987654321);
is($t->to_sql, sprintf("DECIMAL(%d,%d)", $t->length, $t->precision), "high precision floats -> DECIMAL(n,p)");

# -------------------------
# DateTime (no +DateTime role) -> VARCHAR / TEXT
# -------------------------

$t = $PG->new(qw/2024-01-01 2024-06-15 2023-12-31/);
is($t->to_sql, "VARCHAR(10)", "dates without +DateTime role -> VARCHAR");

# -------------------------
# DateTime (with +DateTime role) -> TIMESTAMP
# -------------------------

$t = $PGDate->new(qw/2024-01-01 2024-06-15 2023-12-31/);
is($t->to_sql, "TIMESTAMP", "dates with +DateTime role -> TIMESTAMP");

$t = $PGDate->new(qw/2024-01-01T09:30:00 2024-06-15T12:00:00 2023-12-31T23:59:59/);
is($t->to_sql, "TIMESTAMP", "datetimes with +DateTime role -> TIMESTAMP");

# -------------------------
# Postgres vs SQLite dialect difference
# -------------------------

my $SQLite     = Type::Guess->with_roles("+SQL::SQLite");
my $SQLiteDate = Type::Guess->with_roles("+SQL::SQLite", "+DateTime");

$t = $PG->new(1, 2, 3);
is($t->to_sql, "INTEGER", "PG integers -> INTEGER");

$t = $SQLite->new(1, 2, 3);
is($t->to_sql, "INTEGER", "SQLite integers -> INTEGER");

$t = $PG->new(1.1, 2.2, 3.3);
isnt($t->to_sql, $SQLite->new(1.1, 2.2, 3.3)->to_sql, "PG DECIMAL vs SQLite FLOAT differ");

$t = $PGDate->new(qw/2024-01-01 2024-06-15 2023-12-31/);
my $s = $SQLiteDate->new(qw/2024-01-01 2024-06-15 2023-12-31/);
isnt($t->to_sql, $s->to_sql, "PG TIMESTAMP vs SQLite DATETIME differ");

# -------------------------
# tolerance interaction
# -------------------------

$PG->tolerance(0.25);

$t = $PG->new(1, 2, 3, "a");
is($t->to_sql, "INTEGER", "Int with tolerance -> INTEGER");

$t = $PG->new(1.1, 2.2, 3.3, "a");
is($t->to_sql, sprintf("DECIMAL(%d,%d)", $t->length, $t->precision), "Num with tolerance -> DECIMAL");

$PG->tolerance(0);

# -------------------------
# skip_empty interaction
# -------------------------

$PG->skip_empty(1);

$t = $PG->new(1, 2, "", 3, 4);
is($t->to_sql, "INTEGER", "Int with empty skipped -> INTEGER");

$t = $PG->new(qw/foo bar/, "", qw/baz/);
is($t->to_sql, "VARCHAR(3)", "Str with empty skipped -> VARCHAR");


$PG->skip_empty(1);

# -------------------------
# forced type
# -------------------------

$t = $PG->new(1, 2, 3);
$t->type("Str");
is($t->to_sql, "VARCHAR(" . $t->length . ")", "forced Str -> VARCHAR");

$t = $PG->new(qw/foo bar baz/);
$t->type("Int");
is($t->to_sql, "INTEGER", "forced Int -> INTEGER");

$t = $PG->new(1, 2, 3);
$t->type("Num");
is($t->to_sql, sprintf("DECIMAL(%d,%d)", $t->length, $t->precision), "forced Num -> DECIMAL");

done_testing;
