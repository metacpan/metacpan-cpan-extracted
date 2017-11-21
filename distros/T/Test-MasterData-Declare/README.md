# NAME

Test::MasterData::Declare - It's testing tool for CSV (and other structures) by DSL.

# SYNOPSIS

    use Test::MasterData::Declare;

    master_data {
        load_csv item => "master-data/item.csv";

        subtest "item.type must be like a number and between 1 to 3" => sub { 
            table item => "type",
                like_number => 1 => 3;
        };

        subtest "item.effect is json structure. effect.energy must be between 1 to 100" => sub { 
            table item => "effect",
                if_column type => 1,
                json energy =>
                    like_number 1 => 100;
        }
    };

# DESCRIPTION

`Test::MasterData::Declare` is a testing tool for row like structures.

**THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.**

# FUNCTIONS

## `master_data { ... }`

There functions are working only in this scope.

## `load_csv $table_name => $csv_path, ...;`

Load csv from `$csv_path`. Loaded rows were referenced from `table`.

## `table $table_name => $column_name, $filters_or_expects...`

Check column value. `$filters_or_expects` is a filter functions (ex. `if_column`), expections (ex. `$like_number`), scalar value, regexp reference, `Test2::Compare::*`, etc...

## `if_column $column_name => $column_condition...`

Filter checking rows. `$column_condition` is a scalar or Test2::Compare::\*.

## `like_number $begin => $end`

## `like_number $expects`

Check value that like a number and between `$begin` to `$end` or equals `$expects`.

## `json $key, $inner_key_or_index`

Inflate column to structure data by json.

## `relation $from_table => $to_table, $from_column => $to_column`

Declare relation the `$drom_table` to `$to_table`.

# LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mackee a.k.a macopy <macopy123@gmail.com>
