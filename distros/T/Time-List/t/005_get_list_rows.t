#!perl -w
use strict;
use Test::More;

use Time::List;
use Time::List::Constant;

$ENV{TZ} = "JST";

plan( skip_all => "I don't have windows perl so skip and patch welcome" ) if $^O eq 'MSWin32';

subtest 'get_list_array'=> sub {
    my $timelist = Time::List->new(
        input_strftime_form => '%Y-%m-%d',
        output_strftime_form => '%Y-%m-%d',
        time_unit => MONTH,
        output_type => ROWS ,
        filter => sub {} , 
        filter_keys => [] , 
    );

    my ($start_time , $end_time);

    $start_time = "2013-01-01";
    $end_time = "2013-03-01";
    
    my $time_list_rows = $timelist->get_list($start_time , $end_time);
   
    $time_list_rows->set_rows_from_datetime({
        "2013-01-01 00:00:00" => {id => 1 , value => "a"},
        "2013-02-01 00:00:00" => {id => 2 , value => "b"},
        "2013-03-01 00:00:00" => {id => 3 , value => "c"},
    });

    my $hash = $time_list_rows->get_hash;
    is_deeply {
        "2013-01-01" => {id => 1 , value => "a"},
        "2013-02-01" => {id => 2 , value => "b"},
        "2013-03-01" => {id => 3 , value => "c"},
    } , $hash;

    my $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {output_time => "2013-01-01" , datetime => "2013-01-01 00:00:00" , id => 1 , value => "a"},
        {output_time => "2013-02-01" , datetime => "2013-02-01 00:00:00" , id => 2 , value => "b"},
        {output_time => "2013-03-01" , datetime => "2013-03-01 00:00:00" , id => 3 , value => "c"},
    ] , $array;
    
    $timelist->output_strftime_form( '%Y-%m-%d %H:%M:%S' );
    $time_list_rows = $timelist->get_list($start_time , $end_time);
    $time_list_rows->set_rows_from_datetime({
        "2013-01-01 00:00:00" => {id => 1 , value => "a"},
        "2013-02-01 00:00:00" => {id => 2 , value => "b"},
        "2013-03-01 00:00:00" => {id => 3 , value => "c"},
    });

    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00" , id => 1 , value => "a"},
        {output_time => "2013-02-01 00:00:00" , datetime => "2013-02-01 00:00:00" , id => 2 , value => "b"},
        {output_time => "2013-03-01 00:00:00" , datetime => "2013-03-01 00:00:00" , id => 3 , value => "c"},
    ] , $array;

    $timelist->show_end_time(1);
    $time_list_rows = $timelist->get_list($start_time , $end_time);
    $time_list_rows->set_rows_from_datetime({
        "2013-01-01 00:00:00" => {id => 1 , value => "a"},
        "2013-02-01 00:00:00" => {id => 2 , value => "b"},
        "2013-03-01 00:00:00" => {id => 3 , value => "c"},
    });

    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {output_time => "2013-01-01 00:00:00~2013-01-31 23:59:59" , datetime => "2013-01-01 00:00:00" , id => 1 , value => "a"},
        {output_time => "2013-02-01 00:00:00~2013-02-28 23:59:59" , datetime => "2013-02-01 00:00:00" , id => 2 , value => "b"},
        {output_time => "2013-03-01 00:00:00~2013-03-31 23:59:59" , datetime => "2013-03-01 00:00:00" , id => 3 , value => "c"},
    ] , $array;

    done_testing;
};

subtest 'get_list_rows_per_hours'=> sub {
    my $timelist = Time::List->new(
        input_strftime_form => '%Y-%m-%d',
        output_strftime_form => '%Y-%m-%d %H:%M:%S' ,
        time_unit => HOUR,
        output_type => ROWS ,
        boundary_included => 0 , 
    );

    my ($start_time , $end_time);

    $start_time = "2013-01-01";
    $end_time = "2013-01-02";

    my $time_list_rows = $timelist->get_list($start_time , $end_time);
    my $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00"},
        {output_time => "2013-01-01 01:00:00" , datetime => "2013-01-01 01:00:00"},
        {output_time => "2013-01-01 02:00:00" , datetime => "2013-01-01 02:00:00"},
        {output_time => "2013-01-01 03:00:00" , datetime => "2013-01-01 03:00:00"},
        {output_time => "2013-01-01 04:00:00" , datetime => "2013-01-01 04:00:00"},
        {output_time => "2013-01-01 05:00:00" , datetime => "2013-01-01 05:00:00"},
        {output_time => "2013-01-01 06:00:00" , datetime => "2013-01-01 06:00:00"},
        {output_time => "2013-01-01 07:00:00" , datetime => "2013-01-01 07:00:00"},
        {output_time => "2013-01-01 08:00:00" , datetime => "2013-01-01 08:00:00"},
        {output_time => "2013-01-01 09:00:00" , datetime => "2013-01-01 09:00:00"},
        {output_time => "2013-01-01 10:00:00" , datetime => "2013-01-01 10:00:00"},
        {output_time => "2013-01-01 11:00:00" , datetime => "2013-01-01 11:00:00"},
        {output_time => "2013-01-01 12:00:00" , datetime => "2013-01-01 12:00:00"},
        {output_time => "2013-01-01 13:00:00" , datetime => "2013-01-01 13:00:00"},
        {output_time => "2013-01-01 14:00:00" , datetime => "2013-01-01 14:00:00"},
        {output_time => "2013-01-01 15:00:00" , datetime => "2013-01-01 15:00:00"},
        {output_time => "2013-01-01 16:00:00" , datetime => "2013-01-01 16:00:00"},
        {output_time => "2013-01-01 17:00:00" , datetime => "2013-01-01 17:00:00"},
        {output_time => "2013-01-01 18:00:00" , datetime => "2013-01-01 18:00:00"},
        {output_time => "2013-01-01 19:00:00" , datetime => "2013-01-01 19:00:00"},
        {output_time => "2013-01-01 20:00:00" , datetime => "2013-01-01 20:00:00"},
        {output_time => "2013-01-01 21:00:00" , datetime => "2013-01-01 21:00:00"},
        {output_time => "2013-01-01 22:00:00" , datetime => "2013-01-01 22:00:00"},
        {output_time => "2013-01-01 23:00:00" , datetime => "2013-01-01 23:00:00"},
    ] , $array;

    my $values = {map{$_ => {id => 1 , name => 2}}
        "2013-01-01 00:00:00",
        "2013-01-01 01:00:00",
        "2013-01-01 02:00:00",
        "2013-01-01 03:00:00",
        "2013-01-01 04:00:00",
        "2013-01-01 05:00:00",
        "2013-01-01 06:00:00",
        "2013-01-01 07:00:00",
        "2013-01-01 08:00:00",
        "2013-01-01 09:00:00",
        "2013-01-01 10:00:00",
        "2013-01-01 11:00:00",
        "2013-01-01 12:00:00",
        "2013-01-01 13:00:00",
        "2013-01-01 14:00:00",
    };
    
    $time_list_rows->set_rows_from_datetime($values);
    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {id => 1 , name => 2 , output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 01:00:00" , datetime => "2013-01-01 01:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 02:00:00" , datetime => "2013-01-01 02:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 03:00:00" , datetime => "2013-01-01 03:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 04:00:00" , datetime => "2013-01-01 04:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 05:00:00" , datetime => "2013-01-01 05:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 06:00:00" , datetime => "2013-01-01 06:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 07:00:00" , datetime => "2013-01-01 07:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 08:00:00" , datetime => "2013-01-01 08:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 09:00:00" , datetime => "2013-01-01 09:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 10:00:00" , datetime => "2013-01-01 10:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 11:00:00" , datetime => "2013-01-01 11:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 12:00:00" , datetime => "2013-01-01 12:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 13:00:00" , datetime => "2013-01-01 13:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 14:00:00" , datetime => "2013-01-01 14:00:00"},
        {output_time => "2013-01-01 15:00:00" , datetime => "2013-01-01 15:00:00"},
        {output_time => "2013-01-01 16:00:00" , datetime => "2013-01-01 16:00:00"},
        {output_time => "2013-01-01 17:00:00" , datetime => "2013-01-01 17:00:00"},
        {output_time => "2013-01-01 18:00:00" , datetime => "2013-01-01 18:00:00"},
        {output_time => "2013-01-01 19:00:00" , datetime => "2013-01-01 19:00:00"},
        {output_time => "2013-01-01 20:00:00" , datetime => "2013-01-01 20:00:00"},
        {output_time => "2013-01-01 21:00:00" , datetime => "2013-01-01 21:00:00"},
        {output_time => "2013-01-01 22:00:00" , datetime => "2013-01-01 22:00:00"},
        {output_time => "2013-01-01 23:00:00" , datetime => "2013-01-01 23:00:00"},
    ] , $array;
    $time_list_rows->create_summary(1);

    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {id => 15 , name => 30 , output_time => "summary"},
        {id => 1 , name => 2 , output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 01:00:00" , datetime => "2013-01-01 01:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 02:00:00" , datetime => "2013-01-01 02:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 03:00:00" , datetime => "2013-01-01 03:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 04:00:00" , datetime => "2013-01-01 04:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 05:00:00" , datetime => "2013-01-01 05:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 06:00:00" , datetime => "2013-01-01 06:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 07:00:00" , datetime => "2013-01-01 07:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 08:00:00" , datetime => "2013-01-01 08:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 09:00:00" , datetime => "2013-01-01 09:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 10:00:00" , datetime => "2013-01-01 10:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 11:00:00" , datetime => "2013-01-01 11:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 12:00:00" , datetime => "2013-01-01 12:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 13:00:00" , datetime => "2013-01-01 13:00:00"},
        {id => 1 , name => 2 , output_time => "2013-01-01 14:00:00" , datetime => "2013-01-01 14:00:00"},
        {output_time => "2013-01-01 15:00:00" , datetime => "2013-01-01 15:00:00"},
        {output_time => "2013-01-01 16:00:00" , datetime => "2013-01-01 16:00:00"},
        {output_time => "2013-01-01 17:00:00" , datetime => "2013-01-01 17:00:00"},
        {output_time => "2013-01-01 18:00:00" , datetime => "2013-01-01 18:00:00"},
        {output_time => "2013-01-01 19:00:00" , datetime => "2013-01-01 19:00:00"},
        {output_time => "2013-01-01 20:00:00" , datetime => "2013-01-01 20:00:00"},
        {output_time => "2013-01-01 21:00:00" , datetime => "2013-01-01 21:00:00"},
        {output_time => "2013-01-01 22:00:00" , datetime => "2013-01-01 22:00:00"},
        {output_time => "2013-01-01 23:00:00" , datetime => "2013-01-01 23:00:00"},
        {id => 15 , name => 30 , output_time => "summary"},
    ] , $array;

    my $i = -5;
    $values = {map{$i += 0.5;$_ => {id => 1 , name => $i};}
        "2013-01-01 00:00:00",
        "2013-01-01 01:00:00",
        "2013-01-01 02:00:00",
        "2013-01-01 03:00:00",
        "2013-01-01 04:00:00",
        "2013-01-01 05:00:00",
        "2013-01-01 06:00:00",
        "2013-01-01 07:00:00",
        "2013-01-01 08:00:00",
        "2013-01-01 09:00:00",
        "2013-01-01 10:00:00",
        "2013-01-01 11:00:00",
        "2013-01-01 12:00:00",
        "2013-01-01 13:00:00",
        "2013-01-01 14:00:00",
    };
    
    $time_list_rows->set_rows_from_datetime($values);

    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {id => 15 , name => -15 , output_time => "summary"},
        {id => 1 , name => -4.5 , output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00"},
        {id => 1 , name => -4   , output_time => "2013-01-01 01:00:00" , datetime => "2013-01-01 01:00:00"},
        {id => 1 , name => -3.5 , output_time => "2013-01-01 02:00:00" , datetime => "2013-01-01 02:00:00"},
        {id => 1 , name => -3   , output_time => "2013-01-01 03:00:00" , datetime => "2013-01-01 03:00:00"},
        {id => 1 , name => -2.5 , output_time => "2013-01-01 04:00:00" , datetime => "2013-01-01 04:00:00"},
        {id => 1 , name => -2   , output_time => "2013-01-01 05:00:00" , datetime => "2013-01-01 05:00:00"},
        {id => 1 , name => -1.5 , output_time => "2013-01-01 06:00:00" , datetime => "2013-01-01 06:00:00"},
        {id => 1 , name => -1   , output_time => "2013-01-01 07:00:00" , datetime => "2013-01-01 07:00:00"},
        {id => 1 , name => -0.5 , output_time => "2013-01-01 08:00:00" , datetime => "2013-01-01 08:00:00"},
        {id => 1 , name => 0    , output_time => "2013-01-01 09:00:00" , datetime => "2013-01-01 09:00:00"},
        {id => 1 , name => 0.5  , output_time => "2013-01-01 10:00:00" , datetime => "2013-01-01 10:00:00"},
        {id => 1 , name => 1    , output_time => "2013-01-01 11:00:00" , datetime => "2013-01-01 11:00:00"},
        {id => 1 , name => 1.5  , output_time => "2013-01-01 12:00:00" , datetime => "2013-01-01 12:00:00"},
        {id => 1 , name => 2    , output_time => "2013-01-01 13:00:00" , datetime => "2013-01-01 13:00:00"},
        {id => 1 , name => 2.5  , output_time => "2013-01-01 14:00:00" , datetime => "2013-01-01 14:00:00"},
        {output_time => "2013-01-01 15:00:00" , datetime => "2013-01-01 15:00:00"},
        {output_time => "2013-01-01 16:00:00" , datetime => "2013-01-01 16:00:00"},
        {output_time => "2013-01-01 17:00:00" , datetime => "2013-01-01 17:00:00"},
        {output_time => "2013-01-01 18:00:00" , datetime => "2013-01-01 18:00:00"},
        {output_time => "2013-01-01 19:00:00" , datetime => "2013-01-01 19:00:00"},
        {output_time => "2013-01-01 20:00:00" , datetime => "2013-01-01 20:00:00"},
        {output_time => "2013-01-01 21:00:00" , datetime => "2013-01-01 21:00:00"},
        {output_time => "2013-01-01 22:00:00" , datetime => "2013-01-01 22:00:00"},
        {output_time => "2013-01-01 23:00:00" , datetime => "2013-01-01 23:00:00"},
        {id => 15 , name => -15 , output_time => "summary"},
    ] , $array;

    $time_list_rows->filter(sub{
            my $value = shift;
            return $value * 2;
        });
    $time_list_rows->filter_keys([qw/name/]);

    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {id => 15 , name => 2 * -15 , output_time => "summary"},
        {id => 1  , name => 2 * -4.5 , output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00"},
        {id => 1  , name => 2 * -4   , output_time => "2013-01-01 01:00:00" , datetime => "2013-01-01 01:00:00"},
        {id => 1  , name => 2 * -3.5 , output_time => "2013-01-01 02:00:00" , datetime => "2013-01-01 02:00:00"},
        {id => 1  , name => 2 * -3   , output_time => "2013-01-01 03:00:00" , datetime => "2013-01-01 03:00:00"},
        {id => 1  , name => 2 * -2.5 , output_time => "2013-01-01 04:00:00" , datetime => "2013-01-01 04:00:00"},
        {id => 1  , name => 2 * -2   , output_time => "2013-01-01 05:00:00" , datetime => "2013-01-01 05:00:00"},
        {id => 1  , name => 2 * -1.5 , output_time => "2013-01-01 06:00:00" , datetime => "2013-01-01 06:00:00"},
        {id => 1  , name => 2 * -1   , output_time => "2013-01-01 07:00:00" , datetime => "2013-01-01 07:00:00"},
        {id => 1  , name => 2 * -0.5 , output_time => "2013-01-01 08:00:00" , datetime => "2013-01-01 08:00:00"},
        {id => 1  , name => 2 * 0    , output_time => "2013-01-01 09:00:00" , datetime => "2013-01-01 09:00:00"},
        {id => 1  , name => 2 * 0.5  , output_time => "2013-01-01 10:00:00" , datetime => "2013-01-01 10:00:00"},
        {id => 1  , name => 2 * 1    , output_time => "2013-01-01 11:00:00" , datetime => "2013-01-01 11:00:00"},
        {id => 1  , name => 2 * 1.5  , output_time => "2013-01-01 12:00:00" , datetime => "2013-01-01 12:00:00"},
        {id => 1  , name => 2 * 2    , output_time => "2013-01-01 13:00:00" , datetime => "2013-01-01 13:00:00"},
        {id => 1  , name => 2 * 2.5  , output_time => "2013-01-01 14:00:00" , datetime => "2013-01-01 14:00:00"},
        {output_time => "2013-01-01 15:00:00" , datetime => "2013-01-01 15:00:00"},
        {output_time => "2013-01-01 16:00:00" , datetime => "2013-01-01 16:00:00"},
        {output_time => "2013-01-01 17:00:00" , datetime => "2013-01-01 17:00:00"},
        {output_time => "2013-01-01 18:00:00" , datetime => "2013-01-01 18:00:00"},
        {output_time => "2013-01-01 19:00:00" , datetime => "2013-01-01 19:00:00"},
        {output_time => "2013-01-01 20:00:00" , datetime => "2013-01-01 20:00:00"},
        {output_time => "2013-01-01 21:00:00" , datetime => "2013-01-01 21:00:00"},
        {output_time => "2013-01-01 22:00:00" , datetime => "2013-01-01 22:00:00"},
        {output_time => "2013-01-01 23:00:00" , datetime => "2013-01-01 23:00:00"},
        {id => 15 , name => 2 * -15 , output_time => "summary"},
    ] , $array;

    $time_list_rows->filter(sub{
            my $value = shift;
            return $value unless $value =~ /^-?(?:\d+|\d\.\d+)$/;
            return $value * 3;
        });
    $time_list_rows->filter_keys([\"*"]);

    $array = $time_list_rows->get_array;
    delete $_->{unixtime} for @$array;
    is_deeply [
        {id => 3 * 15 , name => 3 * -15 , output_time => "summary"},
        {id => 3 * 1  , name => 3 * -4.5 , output_time => "2013-01-01 00:00:00" , datetime => "2013-01-01 00:00:00"},
        {id => 3 * 1  , name => 3 * -4   , output_time => "2013-01-01 01:00:00" , datetime => "2013-01-01 01:00:00"},
        {id => 3 * 1  , name => 3 * -3.5 , output_time => "2013-01-01 02:00:00" , datetime => "2013-01-01 02:00:00"},
        {id => 3 * 1  , name => 3 * -3   , output_time => "2013-01-01 03:00:00" , datetime => "2013-01-01 03:00:00"},
        {id => 3 * 1  , name => 3 * -2.5 , output_time => "2013-01-01 04:00:00" , datetime => "2013-01-01 04:00:00"},
        {id => 3 * 1  , name => 3 * -2   , output_time => "2013-01-01 05:00:00" , datetime => "2013-01-01 05:00:00"},
        {id => 3 * 1  , name => 3 * -1.5 , output_time => "2013-01-01 06:00:00" , datetime => "2013-01-01 06:00:00"},
        {id => 3 * 1  , name => 3 * -1   , output_time => "2013-01-01 07:00:00" , datetime => "2013-01-01 07:00:00"},
        {id => 3 * 1  , name => 3 * -0.5 , output_time => "2013-01-01 08:00:00" , datetime => "2013-01-01 08:00:00"},
        {id => 3 * 1  , name => 3 * 0    , output_time => "2013-01-01 09:00:00" , datetime => "2013-01-01 09:00:00"},
        {id => 3 * 1  , name => 3 * 0.5  , output_time => "2013-01-01 10:00:00" , datetime => "2013-01-01 10:00:00"},
        {id => 3 * 1  , name => 3 * 1    , output_time => "2013-01-01 11:00:00" , datetime => "2013-01-01 11:00:00"},
        {id => 3 * 1  , name => 3 * 1.5  , output_time => "2013-01-01 12:00:00" , datetime => "2013-01-01 12:00:00"},
        {id => 3 * 1  , name => 3 * 2    , output_time => "2013-01-01 13:00:00" , datetime => "2013-01-01 13:00:00"},
        {id => 3 * 1  , name => 3 * 2.5  , output_time => "2013-01-01 14:00:00" , datetime => "2013-01-01 14:00:00"},
        {output_time => "2013-01-01 15:00:00" , datetime => "2013-01-01 15:00:00"},
        {output_time => "2013-01-01 16:00:00" , datetime => "2013-01-01 16:00:00"},
        {output_time => "2013-01-01 17:00:00" , datetime => "2013-01-01 17:00:00"},
        {output_time => "2013-01-01 18:00:00" , datetime => "2013-01-01 18:00:00"},
        {output_time => "2013-01-01 19:00:00" , datetime => "2013-01-01 19:00:00"},
        {output_time => "2013-01-01 20:00:00" , datetime => "2013-01-01 20:00:00"},
        {output_time => "2013-01-01 21:00:00" , datetime => "2013-01-01 21:00:00"},
        {output_time => "2013-01-01 22:00:00" , datetime => "2013-01-01 22:00:00"},
        {output_time => "2013-01-01 23:00:00" , datetime => "2013-01-01 23:00:00"},
        {id => 3 * 15 , name => 3 * -15 , output_time => "summary"},
    ] , $array;




    done_testing;
};

done_testing;
