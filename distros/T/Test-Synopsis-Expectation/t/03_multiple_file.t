#!perl

use strict;
use warnings;
use FindBin;
use File::Spec::Functions qw/catfile/;
use Test::Synopsis::Expectation;

my $target_file = catfile($FindBin::Bin, 'resources', 'less.pod');
synopsis_ok([*DATA, $target_file]);

done_testing;
__DATA__
=head1 NAME

less - Less! Less!!

=head1 SYNOPSIS

    1; # => 1

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>
