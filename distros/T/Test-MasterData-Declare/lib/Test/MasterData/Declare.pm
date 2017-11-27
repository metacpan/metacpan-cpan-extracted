package Test::MasterData::Declare;
use 5.010001;
use strict;
use warnings;
use utf8;

our $VERSION = "0.02";

use Test2::API qw/context/;
use Test2::V0;
use Test2::Compare ();
use Test2::Tools::Compare qw/number/;
use Test2::Compare::Custom;
use Test2::Compare::String;
use Scalar::Util qw/blessed/;

use Carp qw/croak/;

%Carp::Internal = (
    %Carp::Internal,
    "Test::MasterData::Declare"                      => 1,
    "Test::MasterData::Declare::Compare::RowHash"    => 1,
    "Test::MasterData::Declare::Compare::RowCustrom" => 1,
    "Test::MasterData::Declare::Row"                 => 1,
);

use parent "Exporter";
our @EXPORT = qw/
    master_data
    load_csv
    table
    expect_row
    relation

    like_number
    if_column
    json
/;

our $DEFAULT_IDENTIFIER_KEY = "id";

use Test::MasterData::Declare::Runner;
use Test::MasterData::Declare::Reader;
use Test::MasterData::Declare::Compare::RowHash;
use Test::MasterData::Declare::Compare::RowCustom;

my $runner;

sub master_data (&) {
    my $code = shift;

    $runner = Test::MasterData::Declare::Runner->new(
        code => $code,
    );

    $runner->run;

    $runner = undef;
}

sub load_csv {
    my %paths = @_;
    my $identifier_key = delete $paths{_identifier_key} || $DEFAULT_IDENTIFIER_KEY;

    for my $table_name (keys %paths) {
        my $filepath = $paths{$table_name};
        my $reader = Test::MasterData::Declare::Reader->read_csv_from(
            table_name     => $table_name,
            filepath       => $filepath,
            identifier_key => $identifier_key,
        );

        $runner->add_reader_to_bucket($reader);
    }
}

sub row_hash (&) {
    Test2::Compare::build("Test::MasterData::Declare::Compare::RowHash", @_)
}

sub row_json {
    my ($column, @keys) = @_;
    my $check = pop @keys;

    my $build = Test2::Compare::get_build();
    croak "row_json must be with-in Test::MasterData::Declare::Compare::RowHash"
        unless $build->isa("Test::MasterData::Declare::Compare::RowHash");

    $build->add_json_field($column, @keys, $check);
}

sub table {
    my ($table_name, $column, @filters_or_expects) = @_;
    my $ctx = context();

    my $rows = $runner->rows($table_name);
    like $rows, array {
        for my $fe (@filters_or_expects) {
            if (blessed $fe && $fe->isa("Test2::Compare::Base")) {
                all_items
                    row_hash {
                        field $column => $fe;
                    };
            }
            elsif (ref $fe eq "CODE") {
                $fe->($column);
            }
        }
    };

    $ctx->release;
}

sub like_number {
    my ($begin, @funcs) = @_;

    my $end = $funcs[0] && number($funcs[0]) ? shift @funcs : $begin;


    my $operator = "$begin <= ... <= $end";
    my $name = "Between";
    if ($begin == $end) {
        $operator = "$begin == ...";
        $name = "Equal";
    }

    my $cus = Test2::Compare::Custom->new(
        name     => $name,,
        operator => $operator,
        code     => sub {
            my %args = @_;
            return 0 unless number($args{got});

            return $begin <= $args{got} && $args{got} <= $end ? 1 : 0;
        },
    );

    return $cus, @funcs;
}

sub if_column {
    my ($column, $cond, @funcs) = @_;

    my $filter;
    if (ref $column eq "CODE") {
        $filter = sub {
            my @rows = @_;
            my @filtered;
            for my $row (@rows) {
                push @filtered, $row if $column->($row->row);
            }
            return @filtered;
        };
    }
    else {
        $filter = sub {
            my @rows = @_;
            my @filtered;
            for my $row (@rows) {
                my $delta = Test2::Compare::compare(
                    $row->row->{$column},
                    $cond,
                    \&Test2::Compare::relaxed_convert,
                );
                push @filtered, $row unless $delta;
            }
            return @filtered;
        };
    }

    return sub {
        my $array = Test2::Compare::get_build();
        $array->add_filter($filter);
    }, @funcs;
}

sub json {
    my ($key, @funcs) = @_;

    my @keys = ($key);
    while (scalar(@funcs) > 0 && !blessed $funcs[0] && ref $funcs[0] ne "CODE") {
        push @keys, shift @funcs;
    }

    return sub {
        my $column = shift;
        my $ctx = context();
        all_items
            row_hash {
                for my $f (@funcs) {
                    if (blessed $f && $f->isa("Test2::Compare::Base")) {
                        row_json $column, @keys => $f;
                    }
                    elsif (ref $f eq "CODE") {
                        row_json $column, @keys => validator(sub {
                            my %args = @_;
                            my $got = $args{got};
                            $f->($got);
                        });
                    }
                }
            };
        $ctx->release;
    };
}

sub expect_row {
    my ($table_name, $func) = @_;

    my $ctx = context();

    my $check = Test::MasterData::Declare::Compare::RowCustrom->new(
        code => sub {
            my %args = @_;
            my $got = $args{got};
            $func->($got);
        },
    );

    my $rows = $runner->rows($table_name);
    like $rows, array {
        all_items $check;
    };

    $ctx->release;
}

sub relation {
    my ($from_table, $to_table, @opts) = @_;

    my %conds;
    while (!ref $opts[0] && scalar(@opts) >= 2) {
        my $from_table_column = shift @opts;
        my $to_table_column = shift @opts;
        $conds{$from_table_column} = $to_table_column;
    }

    my $from_rows = $runner->rows($from_table);
    my $to_rows = $runner->rows($to_table);
    my $to_rows_selector = sub {
        my %from_row_values = @_;

        my @matched_rows = grep {
            my $row = $_->row;
            grep {
                defined $from_row_values{$_} &&
                defined $row->{$conds{$_}} &&
                $from_row_values{$_} eq $row->{$conds{$_}}
            } keys %conds;
        } @$to_rows;

        return @matched_rows;
    };


    my $check = Test::MasterData::Declare::Compare::RowCustrom->new(
        name     => "HasRelation",,
        operator => "$from_table has $to_table",
        code     => sub {
            my %args = @_;
            my $got = $args{got};
            my @matched_rows = $to_rows_selector->(%$got);

            return scalar(@matched_rows) > 0;
        },
    );

    my $ctx = context();
    like $from_rows, array {
        all_items $check;
    };
    $ctx->release;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::MasterData::Declare - It's testing tool for CSV (and other structures) by DSL.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Test::MasterData::Declare> is a testing tool for row like structures.

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

=head1 FUNCTIONS

=head2 C<<  master_data { ... }  >>

There functions are working only in this scope.

=head2 C<< load_csv $table_name => $csv_path, ...; >>

Load csv from C<$csv_path>. Loaded rows were referenced from C<table>.

=head2 C<< table $table_name => $column_name, $filters_or_expects... >>

Check column value. C<$filters_or_expects> is a filter functions (ex. C<if_column>), expections (ex. C<$like_number>), scalar value, regexp reference, C<Test2::Compare::*>, etc...

=head2 C<< if_column $column_name => $column_condition... >>

Filter checking rows. C<$column_condition> is a scalar or Test2::Compare::*.

=head2 C<< like_number $begin => $end >>

=head2 C<< like_number $expects >>

Check value that like a number and between C<$begin> to C<$end> or equals C<$expects>.

=head2 C<< json $key, $inner_key_or_index >>

Inflate column to structure data by json.

=head2 C<< relation $from_table => $to_table, $from_column => $to_column >>

Declare relation the C<$drom_table> to C<$to_table>.

=head1 LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mackee a.k.a macopy E<lt>macopy123@gmail.comE<gt>

=cut

