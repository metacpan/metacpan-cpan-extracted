#use lib qw();
use base qw(Rdb::DB::Object);
use Rose::DB::Object::Loader;
use strict;
use warnings;

my $loader =
  Rose::DB::Object::Loader->new( db => Rdb::DB->new, class_prefix => 'Rdb::' );
my @classes = $loader->make_modules;

