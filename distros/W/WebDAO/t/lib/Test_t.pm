package Test_t;
use strict;
use warnings;
use Data::Dumper;
use WebDAO;
use base 'WebDAO';

sub ___my_name {
    return "aaraer/aaa"
}

sub test_echo {
    my $self = shift;
    return @_
}

sub Test_echo {
    my $self = shift;
    return @_
}

#default method for methods call
sub Index_x {
    my $self = shift;
    return '2'
}

sub index_html {
    my $self = shift;
    return "aaaa"
}
sub Test_resonse {
    my $self = shift;
    my $resonse = $self->response;
    $resonse->html = 'ok';
    return $resonse
}
1;
