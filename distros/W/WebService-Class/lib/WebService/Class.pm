package WebService::Class;

use warnings;
use strict;

=head1 NAME

WebService::Class - WebService retrieve data by object. and have caching structure by file base or memcached base and more

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

use web service

my $api = new WebService::Class::Twitter(username=>'username',password=>'password';
my $result $cache_api->public_timeline();

Cache manager use 

file base cache

my $cache_manager = new WebService::Cache::FileCacheManager('cache_dir'=>'/tmp/.api_cache/');
my $cache_api = new WebService::Class::Twitter(username=>'username',password=>'password','cache_manager'=>$cache_manager);
my $result = $cache_api->public_timeline();

memcached base cache

my $cache_manager = new WebService::Cache::MemcachedCacheManager('servers'=>['127.0.0.1:11211']);
my $api = new WebService::Class::HatenaHaiku(username=>'username',password=>'password','cache_manager'=>$cache_manager);
my $result = $api->public_timeline();

=head1 AUTHOR

Masafumi Yoshida, C<< <masafumi.yoshida820 at gmail.com> >>


1; # End of WebService::Class
