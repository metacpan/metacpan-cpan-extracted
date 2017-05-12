package Time::List;
use 5.008_001;
use strict;
use warnings;
use Time::Piece;
use Time::List::Rows;
use Class::Accessor::Lite;
use Time::List::Constant;

our $VERSION = '0.13';

my $unit_time = {
    DAY()   => 3600 * 24 , 
    WEEK()  => 3600 * 24 * 7 ,
    HOUR()  => 3600 ,
};

my %DEFAULTS = (
    time_unit       => DAY() , 
    output_type     => ARRAY() , 
    limit_rows      => 0 ,
    input_strftime_form    => '%Y-%m-%d %H:%M:%S', 
    output_strftime_form   => '%Y-%m-%d %H:%M:%S', 
    show_end_time   => 0 ,
    boundary_included => 1 ,
    end_time_separate_chars   => '~' ,
    create_summary => 0 , 
    summary_key_name => "summary" , 
    filter => undef , 
    filter_keys => [] , 
);

Class::Accessor::Lite->mk_accessors(keys %DEFAULTS);

sub new {
    my $class = shift;
    
    my $self = bless {
        %DEFAULTS,
        @_ == 1 ? %{ $_[0] } : @_,
    }, $class;
    $self;
}

sub get_list{
    my ($self , $start_time , $end_time) = @_;

    my $output_type = $self->output_type;
    my $time_unit = $self->time_unit;
    my $input_strftime_form = $self->input_strftime_form;
    my $output_strftime_form = $self->output_strftime_form;
    
    my $time_array = [];
    my $show_end_time = $self->show_end_time;
    if($time_unit == MONTH){
        my $start_tp = Time::Piece->strptime($start_time , $input_strftime_form);
        my $end_tp = Time::Piece->strptime($end_time , $input_strftime_form);
        
        my ($start_year , $start_month) = ($start_tp->strftime('%Y') , $start_tp->strftime('%m'));
        
        my ($end_year , $end_month) = ($end_tp->strftime('%Y') , $end_tp->strftime('%m'));

        if($self->boundary_included){
            while($start_year < $end_year || ($start_year == $end_year && $start_month <= $end_month)){
                if($show_end_time){
                    my ( $next_year  , $next_month) = ($start_year , $start_month);
                    if(++$next_month > 12){
                        $next_month = 1;
                        $next_year++;
                    }
                    push @$time_array , 
                        Time::Piece->strptime("$start_year:$start_month" , '%Y:%m')->strftime('%s')
                        . "\t" 
                        . (Time::Piece->strptime("$next_year:$next_month" , '%Y:%m')->strftime('%s') - 1);
                }else{
                    push @$time_array , Time::Piece->strptime("$start_year:$start_month" , '%Y:%m')->strftime('%s');
                }
                if(++$start_month > 12){
                    $start_month = 1;
                    $start_year ++;
                }
            }
        }else{
            while($start_year < $end_year || $start_month < $end_month){
                if($show_end_time){
                    my ( $next_year  , $next_month) = ($start_year , $start_month);
                    if(++$next_month > 12){
                        $next_month = 1;
                        $next_year++;
                    }
                    push @$time_array , 
                        Time::Piece->strptime("$start_year:$start_month" , '%Y:%m')->strftime('%s')
                        . "\t" 
                        . (Time::Piece->strptime("$next_year:$next_month" , '%Y:%m')->strftime('%s') - 1);
                }else{
                    push @$time_array , Time::Piece->strptime("$start_year:$start_month" , '%Y:%m')->strftime('%s');
                }
                if(++$start_month > 12){
                    $start_month = 1;
                    $start_year ++;
                }
            }

        }
    }else{
        my $unit_time_value = $unit_time->{$time_unit};
        die 'set time unit' unless $unit_time_value;
        my $start_tp_time = Time::Piece->strptime($start_time , $input_strftime_form)->strftime('%s');
        my $start_posix_time = Time::Piece->strptime(
            localtime($start_tp_time + $unit_time_value - 1 , '%s')->strftime($time_unit == HOUR() ? '%Y-%m-%d %H:00:00' : '%Y-%m-%d 00:00:00') , 
            '%Y-%m-%d %H:%M:%S')
                ->strftime('%s');
        my $end_posix_time = Time::Piece->strptime($end_time , $input_strftime_form)->strftime('%s');
        
        if($self->boundary_included){
            if($show_end_time){
                push @$time_array ,
                    $start_posix_time
                    . "\t"
                    . ($start_posix_time + $unit_time_value - 1);
            }else{
                push @$time_array , $start_posix_time;
            }

            while($start_posix_time < $end_posix_time){
                $start_posix_time += $unit_time_value;
                if($show_end_time){
                    push @$time_array ,
                        $start_posix_time
                        . "\t"
                        . ($start_posix_time + $unit_time_value - 1);
                }else{
                    push @$time_array , $start_posix_time;
                }
            }
        }else{
            while($start_posix_time < $end_posix_time){
                if($show_end_time){
                    push @$time_array ,
                        $start_posix_time
                        . "\t"
                        . ($start_posix_time + $unit_time_value - 1);
                }else{
                    push @$time_array , $start_posix_time;
                }
                $start_posix_time += $unit_time_value;
            }
        }
    }

    my $end_time_separate_chars = $self->end_time_separate_chars;
    if($output_type == ARRAY){
        if($show_end_time){
            return [map{
                my ($t1 , $t2) = split("\t" , $_);
                localtime($t1)->strftime($output_strftime_form) 
                . $end_time_separate_chars 
                . localtime($t2)->strftime($output_strftime_form)
                }@$time_array];
        }else{
            return [map{localtime($_)->strftime($output_strftime_form)}@$time_array];
        }
    }elsif($output_type == HASH){
        if($show_end_time){
            return {
                map{
                    my ($t1 , $t2) = split("\t" , $_);
                    localtime($t1)->strftime($output_strftime_form) 
                    . $end_time_separate_chars 
                    . localtime($t2)->strftime($output_strftime_form) => {}
            }@$time_array};
        }else{
            return {map{localtime($_)->strftime($output_strftime_form) => {}}@$time_array};
        }
    }elsif($output_type == ROWS){
        my %args = %$self;
        return Time::List::Rows->new(%args , time_array => $time_array);
    }else{
        die 'set output type';
    }
}

1;


1;
__END__

=head1 NAME

Time::List - Perl extention to output time list

=head1 VERSION

This document describes Time::List version 0.13.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

    This module is create time list library

=head1 INTERFACE

=head2 Functions

=head3 C<< new >>
    
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

=head3 C<< get_list >>
    
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

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<Shinichiro Sato>> E<lt><<s2otsa59@gmail.com>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, <<Shinichiro Sato>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

