#!/usr/bin/perl -T
use 5.006;
use strict;
use warnings;
use Test::Tester;
use Test::Version qw( version_all_ok );
use Test::More tests => 5;

subtest 'do not skip files by default' => sub {
  plan tests => 1;

  my(undef, @results) = run_tests(
    sub {
      version_all_ok 'corpus/generated';
    },
  );

  #is scalar @results, 7, 'corect number of results';
  my @fail = sort map { $_->{name} } grep { ! $_->{ok} } @results;

  is_deeply \@fail, ["check version in 'corpus/generated/Foo/ConfigData.pm'","check version in 'corpus/generated/Foo/Install/Files.pm'"], 'error in expected modules';

  foreach my $result (@results)
  {
    my $name = $result->{name} || $result->{reason};
    my $status = $result->{type} eq 'skip' ? 'SKIP' : $result->{ok} ? 'PASS' : 'FAIL';
    note "$status $name";
  }
};

my %patterns = (

  string     => 'corpus/generated/Foo.pm',
  '[string]' => ['corpus/generated/Foo.pm'],
  regex      => qr/generated\/Foo\.pm$/,
  sub        => sub { $_[0] eq 'corpus/generated/Foo.pm' },

);

while(my($pattern_type, $pattern) = each %patterns)
{

  subtest "match_filename $pattern_type" => sub {
    plan tests => 2;

    Test::Version->import({filename_match => $pattern});

    my(undef, @results) = run_tests(
      sub {
        version_all_ok 'corpus/generated';
      },
    );

    is scalar(grep { ! $_->{ok} } @results), 0, 'no failures';
    is scalar(grep { $_->{ok} && $_->{type} eq '' } @results), 2, 'two passes';

    foreach my $result (@results)
    {
      my $name = $result->{name} || $result->{reason};
      my $status = $result->{type} eq 'skip' ? 'SKIP' : $result->{ok} ? 'PASS' : 'FAIL';
      note "$status $name";
    }
  }

};
