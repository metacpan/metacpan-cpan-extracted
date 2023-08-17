#!perl
use strict;
use warnings;
use Test::More tests => 6;
use WebService::Rackspace::CloudFiles::Object::Iterator;

sub make_iterator {
    my @data = ([1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]);
    return WebService::Rackspace::CloudFiles::Object::Iterator->new(
        callback => sub {
            return shift @data;
        }
    );
}

my $iterator = make_iterator();
isa_ok($iterator, 'WebService::Rackspace::CloudFiles::Object::Iterator');

my $data1 = $iterator->next;
is_deeply($data1, [1, 2, 3], 'iterator->next');

my @data2 = $iterator->items;
is_deeply(\@data2, [4, 5, 6], 'iterator->items');

my @data3 = $iterator->all;
is_deeply(\@data3, [7, 8, 9, 10, 11, 12], 'iterator->all');

ok($iterator->isa('WebService::Rackspace::CloudFiles::Object::Iterator'));

# The object should be upgraded to Data::Stream::Bulk::Callback if unsupported
# methods, such as chunk(), are called.
SKIP: {
    my $dsbc = eval { require Data::Stream::Bulk::Callback; 2; };
    skip("Data::Stream::Bulk::Callback not installed", 1) unless $dsbc;
 
    my $iterator = make_iterator();
    my $chunked  = $iterator->chunk(4);
    my $next = $chunked->next;
    is_deeply([@{$next}[0..3]], [1, 2, 3, 4]);
}
