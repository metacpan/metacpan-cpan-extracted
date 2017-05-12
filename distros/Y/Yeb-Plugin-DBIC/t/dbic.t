#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);

{
  package WebDBICDB::Result::Test;
  use base qw/DBIx::Class::Core/;
 
  __PACKAGE__->table('test');
  __PACKAGE__->add_columns(qw/ id name /);
  __PACKAGE__->set_primary_key('id');
   
  1;
}

{
  package WebDBICDB;
  use base 'DBIx::Class::Schema';
  __PACKAGE__->register_class('Test','WebDBICDB::Result::Test');
  1;
}

$INC{'WebDBICDB.pm'} = 1;
$INC{'WebDBICDB/Result/Test.pm'} = 1;

{
  package WebDBIC;
  use strictures;
  use Yeb;

  BEGIN { plugin DBIC => ( schema => 'WebDBICDB' ) }

  r "/" => sub {
    text join(' ',resultset('Test')->search({},{
      order_by => 'id'
    })->get_column('name')->all);
  };

  r "/desc" => sub {
    text join(' ',resultset('Test')->search({},{
      order_by => { -desc => 'id' },
    })->get_column('name')->all);
  };

  sub BUILD {
    my ( $self ) = @_;
    my $id = 0;
    schema->deploy;
    my $resultset = resultset('Test');
    for my $name (qw( test test2 test3 )) {
      $id++;
      resultset('Test')->create({
        id => $id,
        name => $name,
      });
    }
  }

  1;
}

$INC{'WebDBIC.pm'} = 1;

$ENV{YEB_ROOT} = $Bin;
$ENV{DBI_DSN} = 'dbi:SQLite::memory:';

my $app = WebDBIC->new;

my @tests = (
  [ '', 'test test2 test3' ],
  [ 'desc', 'test3 test2 test' ],
);

for (@tests) {
  my $path = $_->[0];
  my $url = "http://localhost/".$path;
  note($url);
  my $test = $_->[1];
  my $code = defined $_->[2] ? $_->[2] : 200;
  ok(my $res = $app->run_test_request( GET => $url ), 'response on /'.$path);
  cmp_ok($res->code, '==', $code, 'Status '.$code.' on /'.$path);
  my $ctn = 'Expected content on /'.$path;
  if (ref $test eq 'Regexp') {
    like($res->content, $test, $ctn);
  } elsif (ref $test eq 'HASH') {
    my $data = from_json($res->content);
    is_deeply($data,$test, $ctn);
  } elsif (defined $test) {
    cmp_ok($res->content, 'eq', $test, $ctn);
  }
}


done_testing;
