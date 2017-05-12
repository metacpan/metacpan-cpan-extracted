package Time::List::Rows;
use 5.008_001;
use strict;
use warnings;
use Time::Piece;
use Class::Accessor::Lite;
use Time::List::Rows::Row;
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
    end_time_separate_chars   => '~' ,
    time_array => [],
    time_rows => [],
    unixtime_rows_hash => {},
    datetime_rows_hash => {},
    create_summary => 0 , 
    summary_key_name => "summary" , 
    filter => undef , 
    filter_keys => [] , 
);

Class::Accessor::Lite->mk_accessors(keys %DEFAULTS);

sub new {
    my $class = shift;
    
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    my $self = bless {
        %DEFAULTS,
        %args,
    }, $class;
    
    die "set time array" unless $self->time_array;
    $self->_create_time_rows(\%args);
    $self;
}

sub _create_time_rows{
    my ($self , $args)  = @_;
    my $time_array = $self->time_array;
    my $time_rows = [map{
        Time::List::Rows::Row->new(%$args , unixtime => $_);
    }@$time_array];
    my $unixtime_rows_hash = {map{
        $_->unixtime => $_,
    }@$time_rows};
    my $datetime_rows_hash = {map{
        $_->datetime => $_,
    }@$time_rows};
    $self->time_rows($time_rows);
    $self->unixtime_rows_hash($unixtime_rows_hash);
    $self->datetime_rows_hash($datetime_rows_hash);
}

sub get_row_from_datetime{
    my ($self , $datetime)  = @_;
    $self->unixtime_rows_hash()->{$datetime};
}

sub get_row_from_unixtime{
    my ($self , $unixtime)  = @_;
    $self->unixtime_rows_hash()->{$unixtime};
}

sub set_row_from_datetime{
    my ($self , $datetime , $values)  = @_;
    $self->unixtime_rows_hash()->{$datetime}->set($values);
}

sub set_row_from_unixtime{
    my ($self , $unixtime , $values)  = @_;
    $self->unixtime_rows_hash()->{$unixtime}->set($values);
}

sub set_rows_from_input_strftime{
    my ($self , $rows)  = @_;
    my $strf_form = $self->input_strftime_form;
    my $keys = {};
    for my $time(keys %$rows){
        my $values = $rows->{$time};
        for(keys %$values){
            $keys->{$_} = 1;
        }
        my $unixtime = Time::Piece->strptime($time , $strf_form)->strftime('%s');
        my $row = $self->unixtime_rows_hash()->{$unixtime};
        $row->set($values) if $row;
    }
    my $time_rows = $self->time_rows();
    for(@$time_rows){
        $_->{$keys} ||= undef;
    }
}

sub set_rows_from_datetime{
    my ($self , $rows)  = @_;
    my $keys = {};
    for my $datetime(keys %$rows){
        my $values = $rows->{$datetime};
        for(keys %$values){
            $keys->{$_} = 1;
        }
        my $row = $self->datetime_rows_hash()->{$datetime};
        $row->set($values) if $row;
    }
    my $time_rows = $self->time_rows();
    for(@$time_rows){
        $_->{$keys} ||= undef;
    }
}

sub set_rows_from_unixtime{
    my ($self , $rows)  = @_;
    my $keys = {};
    for my $unixtime(keys %$rows){
        my $values = $rows->{$unixtime};
        for(keys %$values){
            $keys->{$_} = 1;
        }
        my $row = $self->unixtime_rows_hash()->{$unixtime};
        $row->set($values) if $row;
    }
    my $time_rows = $self->time_rows();
    for(@$time_rows){
        $_->{$keys} ||= undef;
    }
}

sub get_array{
    my ($self)  = @_;
    my $unixtime_rows_hash = $self->unixtime_rows_hash;
    if($self->create_summary){
        my $summary = {};

        my $rows = [map{
            my $row = $unixtime_rows_hash->{$_->unixtime}->get_values;
            if($self->filter){
                $row = {%$row};
                my @filter_keys = @{$self->filter_keys};
                if(ref $filter_keys[0] eq "SCALAR" && ${$filter_keys[0]} eq "*"){
                    @filter_keys = keys %$row 
                }
                for my $key (@filter_keys){
                    if(exists $row->{$key}){
                        $row->{$key} = $self->filter->($row->{$key});
                    }
                }
            }

            for my $key(keys %$row){
                my $value = $row->{$key};
                if($value && $value =~ /(^|^-)(\d+|\d+\.\d+)$/){
                    $summary->{$key} += $value;
                }
            }

            $row;
        }@{$self->time_rows}];
        $summary->{output_time} = $self->summary_key_name;
        push @$rows , $summary ;
        unshift @$rows , $summary;

        return $rows;
    }else{
        return [map{
                my $row = $unixtime_rows_hash->{$_->unixtime}->get_values;

                if($self->filter){
                    $row = {%$row};
                    my @filter_keys = @{$self->filter_keys};
                    if(ref $filter_keys[0] eq "SCALAR" && ${$filter_keys[0]} eq "*"){
                        @filter_keys = keys %$row 
                    }
                    for my $key (@filter_keys){
                        if(exists $row->{$key}){
                            $row->{$key} = $self->filter->($row->{$key});
                        }
                    }
                }

                $row;
            }@{$self->time_rows}]
    }
}

sub get_hash{
    my ($self)  = @_;
    return {map{$_->get_hash_seed}@{$self->time_rows}};
}

1;


1;
__END__

=head1 NAME

Time::List::Rows - Perl extention to output time list

=head1 VERSION

This document describes Time::List::Rows version 0.13.

=head1 SYNOPSIS

    use Time::List;
    use Time::List::Constant;
    $start_time = "2013-01-01 00:00:00";
    $end_time = "2013-01-01 04:00:00";
    $time_list_rows = Time::List->new(
        input_strftime => '%Y-%m-%d %H:%M:%S',
        output_strftime => '%Y-%m-%d %H:%M:%S',
        time_unit => DAY ,
        output_type => ROWS ,
    )->get_list($start_time , $end_time);
    
    my $data = {
        "2013-01-01 00:00:00" => {id => 1 , name => 'aaa'},
        "2013-01-01 01:00:00" => {id => 2 , name => 'bbb'},
        "2013-01-01 02:00:00" => {id => 3 , name => 'ccc'},
        "2013-01-01 03:00:00" => {id => 4 , name => 'ddd'},
    };
    $time_list_rows->set_rows_from_datetime($data);

    # get array with data
    my $array = $time_list_rows->get_array();
    # [
    #   {output_time => "2013-01-01 00:00:00", id => 1 , name => 'aaa'},
    #   {output_time => "2013-01-01 01:00:00", id => 2 , name => 'bbb'},
    #   {output_time => "2013-01-01 02:00:00", id => 3 , name => 'ccc'},
    #   {output_time => "2013-01-01 03:00:00", id => 4 , name => 'ddd'},
    # ]

    # get hash with data
    my $hash = $time_list_rows->get_hash();
    # {
    #    "2013-01-01 00:00:00" => {id => 1 , name => 'aaa'},
    #    "2013-01-01 01:00:00" => {id => 2 , name => 'bbb'},
    #    "2013-01-01 02:00:00" => {id => 3 , name => 'ccc'},
    #    "2013-01-01 03:00:00" => {id => 4 , name => 'ddd'},
    # }

=head1 DESCRIPTION

    This module is create time list library

=head1 INTERFACE

=head2 Functions

=head3 C<< set_rows_from_datetime >>

Two or more values are set. 
It is ignored when the date does not match. 

    my $data = {
        "2013-01-01 00:00:00" => {id => 4 , name => 'aaa'},
        "2013-01-01 01:00:00" => {id => 5 , name => 'bbb'},
        "2013-01-01 02:00:00" => {id => 6 , name => 'ccc'},
        "2013-01-01 03:00:00" => {id => 7 , name => 'ddd'},
    };
    $time_list_rows->set_rows_from_datetime($data);

=head3 C<< set_rows_from_unixtime >>
    
    # overwrite previous set_rows
    my $data = {
        1356966000 => {id => 1 , name => 'aaa'},
        1357052400 => {id => 2 , name => 'bbb'},
        1357138800 => {id => 3 , name => 'ccc'},
        1357225200 => {id => 4 , name => 'ddd'},
    };
    $time_list_rows->set_rows_from_unixtime($data);

=head3 C<< set_row_from_datetime >>

    $time_list_rows->set_rows_from_datetime("2013-01-01 00:00:00" => {id => 4 , name => 'aaa'});

=head3 C<< get_row_from_datetime >>
    
    my $row = $time_list_rows->get_rows_from_datetime("2013-01-01 00:00:00");
    # $row => {id => 4 , name => 'aaa'}


=head3 C<< set_row_from_unixtime >>

    $time_list_rows->set_rows_from_unixtime(1356966000 => {id => 1 , name => 'aaa'});
    
=head3 C<< get_row_from_unixtime >>

    my $row = $time_list_rows->get_rows_from_unixtime(1356966000);
    # $row => {id => 1 , name => 'aaa'}
    
=head3 C<< get_array >>

    # get array with data
    my $array = $time_list_rows->get_array();
    # [
    #   {output_time => "2013-01-01 00:00:00", id => 1 , name => 'aaa'},
    #   {output_time => "2013-01-01 01:00:00", id => 2 , name => 'bbb'},
    #   {output_time => "2013-01-01 02:00:00", id => 3 , name => 'ccc'},
    #   {output_time => "2013-01-01 03:00:00", id => 4 , name => 'ddd'},
    # ]

=head3 C<< get_hash >>

    # get hash with data
    my $hash = $time_list_rows->get_hash();
    # {
    #    "2013-01-01 00:00:00" => {id => 1 , name => 'aaa'},
    #    "2013-01-01 01:00:00" => {id => 2 , name => 'bbb'},
    #    "2013-01-01 02:00:00" => {id => 3 , name => 'ccc'},
    #    "2013-01-01 03:00:00" => {id => 4 , name => 'ddd'},
    # }

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
