package WebService::Class::AbstractClass;
use warnings;
use strict;
use base qw(Class::Data::Inheritable Class::Accessor);
__PACKAGE__->mk_classdata('service_name');
__PACKAGE__->mk_classdata('cache_manager');
__PACKAGE__->mk_classdata('base_url');
__PACKAGE__->mk_classdata('urls');
__PACKAGE__->mk_classdata('username');
__PACKAGE__->mk_classdata('password');
__PACKAGE__->mk_accessors(qw/request_api/);


sub new{
	my $class = shift;
	my $self = $class->SUPER::new();
	$self->init(@_);
	return $self;
}

sub init{
	my $self = shift;
	my %args = @_;
	$self->username($args{'username'});
	$self->password($args{'password'});
}



1;
