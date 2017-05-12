package WebService::RequestAPI::AbstractRequestAPI;
use strict;
use utf8;
use JSON;
use XML::Simple;
use base qw(Class::Data::Inheritable Class::Accessor);
__PACKAGE__->mk_accessors(qw/result cache_id cache_manager/);

sub new{
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->init(@_);
	return $self;
}


sub init{
	my $self = shift;
	my %args = @_;
	$self->cache_manager($args{'cache_manager'});		
}

sub parse_json{
	my $self   = shift;
	if($self->cache_manager){
		if($self->cache_manager->is_cached($self->cache_id)){
			return $self->cache_manager->retrieve_cache($self->cache_id);
		}
		my $result = decode_json($self->result);
		$self->cache_manager->store_cache($self->cache_id,$result);
		return $result;	
	}
	return  decode_json($self->result);
}

sub parse_xml{
	my $self    = shift;
	if($self->cache_manager){
		if($self->cache_manager->is_cached($self->cache_id)){
			return $self->cache_manager->retrieve_cache($self->cache_id);
		}
		my $result = XML::Simple->new()->XMLin($self->result);
		$self->cache_manager->store_cache($self->cache_id,$result);
		return $result;	
	}
	return  XML::Simple->new()->XMLin($self->result);
}

sub request{
	my $self   = shift;
	my %args = @_;
	if($self->cache_manager){
		$self->cache_id($self->cache_manager->create_cache_id(@_));
		if($self->cache_manager->is_cached($self->cache_id)){
			return $self;
		}
	}
	$self->_request(@_);
	return $self;
}


1; 
