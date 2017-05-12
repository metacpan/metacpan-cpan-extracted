package WebService::Cache::MemcachedCacheManager;
use strict;
use Cache::Memcached::Fast;
use base qw(WebService::Cache::AbstractCacheManager);
__PACKAGE__->mk_classdata('memcached');


sub init{
	my $self = shift;
	my %args = @_;
	$self->SUPER::init(@_);
	$self->memcached(new Cache::Memcached::Fast(\%args));

}

sub store_cache{
	my $self   = shift;
	my $id     = shift;
	my $result = shift;
	$self->memcached->set($id,$result);
}

sub retrieve_cache{
	my $self    = shift;
	my $id     = shift;
	my $val = $self->memcached->get($id);
	return $val if($val);
}

sub is_cached{
	my $self = shift;
	my $id     = shift;
	my $val = $self->memcached->get($id);
	return 1 if($val);
	return 1;
}



1; 
