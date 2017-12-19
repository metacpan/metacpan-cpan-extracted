#!perl

package Example::Class;

use Test::Roo;

use lib 't/lib';

with qw/ Test::Roo::DataDriven /;

1;

package main;

use Test::Most;
use Path::Tiny;

plan skip_all => "Error messages may be locale-dependent"
  unless $ENV{LANG} && $ENV{LANG} =~ /^en/;

subtest 'nonexistent' => sub {

    my $file = path('t/data/errors/nonexistent.err');

    throws_ok {

        Example::Class->parse_data_file($file);

    }
    qr/failed on ${file}: No such file or directory/;

};

subtest 'syntax' => sub {

    my $file = path('t/data/errors/syntax.err');

    throws_ok {

        Example::Class->parse_data_file($file);

    }
    qr/failed on ${file}: Missing right curly/;

};

subtest 'missing prereq' => sub {

    my $file = path('t/data/errors/function.err');

    throws_ok {

        Example::Class->parse_data_file($file);

    }
    qr/failed on ${file}: Undefined subroutine/;

};

done_testing;
