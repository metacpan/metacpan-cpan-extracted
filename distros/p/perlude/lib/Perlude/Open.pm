package Perlude::Open;
use strict;
use warnings;
use 5.10.0;
use Exporter qw< import >;
our @EXPORT  = qw< open_file >;

sub _source_for_nargs (_) {
    my $nargs = shift or die; 
    my $args =  join ',', map {'$a'.$_} 1..$nargs;
    sprintf 'sub {
        my (%s) = @_;
        open my $fh, %s
            or die "$! while open_file %s";
        $fh; }', ($args)x3;
};

sub _prepare_special_forms {
    +{ map {
        my $cb = eval _source_for_nargs;
        $@ and die $@;
        $_ => $cb; } 1..4 };
}

sub _callback_for_nargs(_) {
    # build callbacks for number of arguments from 1 to 4
    state $open_with = _prepare_special_forms;
    # the 4 arguments form callback should work for 4 and more.
    # i copy this ref on demand whenever i see a new number of arguments 
    $open_with->{ +@_ } ||= $open_with->{4}; 
}

sub open_file {
    # if the file (can be $_) is open, just return
    return shift if ref ($_[0]||=$_);
    ( _callback_for_nargs +@_ )->(@_)
} 
