#!perl -w
use strict;
use Test::More;

use Time::List;
use Time::List::Constant;

$ENV{TZ} = "JST";

plan( skip_all => "I don't have windows perl so skip and patch welcome" ) if $^O eq 'MSWin32';

subtest 'get_list_array'=> sub {
    my $timelist = Time::List->new(
        input_strftime_form => '%Y-%m-%d %H:%M:%S',
        output_strftime_form => '%Y-%m-%d',
        time_unit => MONTH,
        output_type => ARRAY ,
    );

    my ($start_time , $end_time , $array );

    $start_time = "2013-01-01 00:00:00";
    $end_time = "2013-06-01 00:00:00";
    $array = $timelist->get_list($start_time , $end_time);
    is_deeply [
        "2013-01-01",
        "2013-02-01",
        "2013-03-01",
        "2013-04-01",
        "2013-05-01",
        "2013-06-01",
    ] , $array;

    $start_time = "2013-01-15 00:00:01";
    $end_time = "2013-06-01 00:00:01";
    $array = $timelist->get_list($start_time , $end_time);

    is_deeply [
        "2013-01-01",
        "2013-02-01",
        "2013-03-01",
        "2013-04-01",
        "2013-05-01",
        "2013-06-01",
    ] , $array;

    $start_time = "2013-04-23 00:00:01";
    $end_time = "2013-04-30 00:00:01";
    $array = $timelist->get_list($start_time , $end_time);

    is_deeply [
        "2013-04-01",
    ] , $array;
    $start_time = "2013-04-23 00:00:01";
    $end_time = "2013-05-30 00:00:01";
    $array = $timelist->get_list($start_time , $end_time);

    is_deeply [
        "2013-04-01",
        "2013-05-01",
    ] , $array;


    done_testing;
};

subtest 'get_list_array_with_endtime'=> sub {
    my $timelist = Time::List->new(
        input_strftime_form => '%Y-%m-%d',
        output_strftime_form => '%Y-%m-%d',
        time_unit => MONTH,
        output_type => ARRAY ,
        show_end_time => 1 ,
    );

    my ($start_time , $end_time , $array );

    $start_time = "2013-01-01";
    $end_time = "2013-06-01";
    $array = $timelist->get_list($start_time , $end_time);
    is_deeply [
        "2013-01-01~2013-01-31",
        "2013-02-01~2013-02-28",
        "2013-03-01~2013-03-31",
        "2013-04-01~2013-04-30",
        "2013-05-01~2013-05-31",
        "2013-06-01~2013-06-30",
    ] , $array;

    $start_time = "2013-01-01";
    $end_time = "2013-06-01";
    $timelist->end_time_separate_chars(" :: ");
    $array = $timelist->get_list($start_time , $end_time);
    is_deeply [
        "2013-01-01 :: 2013-01-31",
        "2013-02-01 :: 2013-02-28",
        "2013-03-01 :: 2013-03-31",
        "2013-04-01 :: 2013-04-30",
        "2013-05-01 :: 2013-05-31",
        "2013-06-01 :: 2013-06-30",
    ] , $array;

    $start_time = "2013-11-01";
    $end_time = "2013-12-01";
    $array = $timelist->get_list($start_time , $end_time);
    is_deeply [
        "2013-11-01 :: 2013-11-30",
        "2013-12-01 :: 2013-12-31",
    ] , $array;

    $start_time = "2013-11-01";
    $end_time = "2014-01-01";
    $array = $timelist->get_list($start_time , $end_time);
    is_deeply [
        "2013-11-01 :: 2013-11-30",
        "2013-12-01 :: 2013-12-31",
        "2014-01-01 :: 2014-01-31",
    ] , $array;


};

done_testing;
