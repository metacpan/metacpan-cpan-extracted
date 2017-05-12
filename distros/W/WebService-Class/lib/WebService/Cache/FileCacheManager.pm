package WebService::Cache::FileCacheManager;
use strict;
use Digest::MD5 qw(md5_hex);
use Storable qw(store retrieve);
use base qw(WebService::Cache::AbstractCacheManager);
__PACKAGE__->mk_classdata('cache_dir');


sub init{
	my $self = shift;
	my %args = @_;
	$self->SUPER::init(@_);
	if(exists $args{'cache_dir'}){
		$self->cache_dir($args{'cache_dir'});
	}
	else{
		die "Require cache dirctory path " ;
	}
	if(! -f $self->cache_dir){
		mkdir $self->cache_dir();
	}
}

sub store_cache{
	my $self   = shift;
	my $id     = shift;
	my $result = shift;
	store \$result ,$self->cache_dir.$id;
}

sub retrieve_cache{
	my $self    = shift;
	my $id     = shift;
	return retrieve $self->cache_dir.$id;
}

sub is_cached{
	my $self = shift;
	my $id     = shift;
	return 0 unless(-f $self->cache_dir .$id);
	my @file_status = stat($self->cache_dir .$id);
        return 0 if($self->lifetime < (time - $file_status[9]));
	return 1;
}


1; 
