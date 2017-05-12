package Test::Sah;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Data::Sah qw(gen_validator);
use Test::Builder;

our $VERSION = '0.01'; # VERSION

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::is_valid'}   = \&is_valid;
    *{$caller.'::is_invalid'} = \&is_invalid;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub is_valid {
    my ($data, $schema, $msg) = @_;

    my $v = gen_validator($schema, {return_type=>'str'});
    my $res = $v->($data);
    my $ok = $Test->ok(!$res, $msg);
    $ok or $Test->diag($res);
    $ok;
}

sub is_invalid {
    my ($data, $schema, $msg) = @_;

    my $v = gen_validator($schema, {return_type=>'str'});
    $Test->ok($v->($data), $msg);
}

1;
# ABSTRACT: Test data against Sah schema



__END__
=pod

=head1 NAME

Test::Sah - Test data against Sah schema

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Test::More;
 use Test::Sah; # exports is_valid() and is_invalid()

 is_valid  ({}, [hash => keys=>{a=>"int", b=>"str"}]); # ok
 is_invalid([], [array => {min_len=>1}]);              # ok
 done_testing;

=head1 DESCRIPTION

This module is a proof of concept. It provides C<is_valid()> and C<is_invalid()>
to test data structure against L<Sah> schema.

=head1 FUNCTIONS

All these functions are exported by default.

=head2 is_valid($data, $schema[, $msg]) => BOOL

Test that C<$data> validates to C<$schema>.

=head2 is_invalid($data, $schema[, $msg]) => BOOL

Test that C<$data> does not validate to C<$schema>.

=head1 SEE ALSO

L<Sah>

L<Data::Sah>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

