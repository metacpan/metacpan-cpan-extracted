package MyWeb;
use WebService::GData 'private';
use base 'WebService::GData';

	#extend __init method
	sub __init {
		my $this = shift;
		$this->SUPER::__init(@_);
		$this->{extra}=1;
	}

	
WebService::GData::install_in_package(
	[qw(firstname lastname)],
	sub {
		my $funcname = shift;
		return sub {
			my $this = shift;
			if(@_){
				$this->{$funcname}=$_[0];
			}
			return $this->{$funcname};
		}
	}
);

private this_function_is_private => sub {
	my ($arg1,$arg2)=@_;
	return ref($arg1).$arg2 if($arg1 && $arg2);
};
#can call this function from within the package...
this_function_is_private();

sub call_private_function(){
	my $this=shift;
	return $this->this_function_is_private('::call_private_function');
}
1;
