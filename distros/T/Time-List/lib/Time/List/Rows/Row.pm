package Time::List::Rows::Row;
use 5.008_001;
use strict;
use warnings;
use Time::Piece;
use Class::Accessor::Lite;
use Time::List::Constant;
use Encode qw/decode_utf8/;

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
    unixtime => 0,
    datetime => 0,
    values => {},
);

Class::Accessor::Lite->mk_accessors(keys %DEFAULTS);

sub new {
    my $class = shift;
    
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    if($args{show_end_time}){
        my ($unixtime) = split("\t",$args{unixtime});
        $args{datetime} = localtime($unixtime)->strftime( '%Y-%m-%d %H:%M:%S');
    }else{
        $args{datetime} = localtime($args{unixtime})->strftime( '%Y-%m-%d %H:%M:%S');
    }
    decode_utf8($args{datetime});
    my $self = bless {
        %DEFAULTS,
        values => {},
        %args,
    }, $class;
    $self;
}

sub set{
    my ($self , $values)  = @_;
    $self->values(
        {%{$self->values},%$values}
    );
}

sub get_hash_seed{
    my ($self)  = @_;
    my $values = $self->values;
    if($self->show_end_time){
        join($self->end_time_separate_chars, 
        map{decode_utf8(localtime($_)->strftime($self->output_strftime_form))}split("\t",$self->unixtime)) => $values;
    }else{
        decode_utf8(localtime($self->unixtime)->strftime($self->output_strftime_form)) => $values;
    }
}

sub get_key{
    my ($self)  = @_;
    my $values = $self->values;

    if($self->show_end_time){
        join($self->end_time_separate_chars, 
        map{decode_utf8(localtime($_)->strftime($self->output_strftime_form))}split("\t",$self->unixtime));
    }else{
        decode_utf8(localtime($self->unixtime)->strftime($self->output_strftime_form));
    }
}

sub get_values{
    my ($self)  = @_;
    my $values = $self->values;

    $values->{$_} = $self->$_ for qw/datetime unixtime/;
    $values->{output_time} = $self->get_key;
    return $values;
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
        input_strftime => '%Y-%m-%d %H:%M:%S',
        output_strftime => '%Y-%m-%d %H:%M:%S',
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
