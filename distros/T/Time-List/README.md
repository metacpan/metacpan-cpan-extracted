# NAME

Time::List - Perl extention to output time list

# VERSION

This document describes Time::List version 0.13.

# SYNOPSIS

    use Time::List;
    use Time::List::Constant;
    $timelist = Time::List->new(
        input_strftime_form => '%Y-%m-%d %H:%M:%S',
        output_strftime_form => '%Y-%m-%d %H:%M:%S',
        time_unit => DAY ,
        output_type => ARRAY ,
    );

    my ($start_time , $end_time , $array );
    $start_time = "2013-01-01 00:00:00";
    $end_time = "2013-01-05 00:00:00";
    $array = $timelist->get_list($start_time , $end_time); # 5 elements rows
    # "2013-01-01 00:00:00" ,"2013-01-02 00:00:00","2013-01-03 00:00:00","2013-01-04 00:00:00","2013-01-05 00:00:00",

    $start_time = "2013-01-01 00:00:00";
    $end_time = "2013-01-01 04:00:00";
    $timelist->time_unit(HOUR);
    $array = $timelist->get_list($start_time , $end_time); # 5 elements rows
    # "2013-01-01 00:00:00" ,"2013-01-01 01:00:00","2013-01-01 02:00:00","2013-01-01 03:00:00","2013-01-01 04:00:00",

# DESCRIPTION

    This module is create time list library

# INTERFACE

## Functions

### `new`

    # You can set some options.
    $timelist->new(
        time_unit       => DAY , 
        output_type     => ARRAY , 
        limit_rows      => 0 ,
        input_strftime_form    => '%Y-%m-%d %H:%M:%S', 
        output_strftime_form   => '%Y-%m-%d %H:%M:%S', 
        show_end_time   => 0 ,
        end_time_separate_chars   => '~' ,
    );
    # accesstor by Class::Accessor::Lite 
    $timelist->output_type(HASH);

### `get_list`

    # You can get TimeArray 
    $timelist->output_type(HASH);
    $array = $timelist->get_list($start_time , $end_time);

    # You can get TimeHash
    # key => value
    # time => {}
    $timelist->output_type(HASH);
    $hash = $timelist->get_list($start_time , $end_time);

    # You can get Time::List::Rows instance
    #
    $timelist->output_type(ROWS);
    $time_list_rows = $timelist->get_list($start_time , $end_time);

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# AUTHOR

<<Shinichiro Sato>> <<<s2otsa59@gmail.com>>>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, <<Shinichiro Sato>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
