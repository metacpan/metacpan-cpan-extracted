package WebService::Cache::AbstractCacheManager;
use strict;
use Digest::MD5 qw(md5_hex);
use base qw(Class::Data::Inheritable Class::Accessor);
__PACKAGE__->mk_classdata('lifetime'=>81600);

sub new{
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->init(@_);
	return $self;
}

sub init{
	my $self = shift;
	my %args = @_;
	if(exists $args{'lifetime'}){
		$self->lifetime($args{'lifetime'});
	}
}

sub store_cache{
	my $self   = shift;
	my $id     = shift;
	my $result = shift;
}

sub retrieve_cache{
	my $self    = shift;
	my $id      = shift;
}

sub is_cached{
	my $self = shift;
	my $id     = shift;
	return 0;
}

sub create_cache_id{
	my $self = shift;
	my $id;
	foreach my $arg (sort {$a <=>$b} @_){
		if(ref $arg eq "HASH"){
			$id .= join ':',sort {$a <=> $b} values %{$arg};
		}
		else{
			$id .=$arg;
		}
	}
	return md5_hex($id);
}

1; 
