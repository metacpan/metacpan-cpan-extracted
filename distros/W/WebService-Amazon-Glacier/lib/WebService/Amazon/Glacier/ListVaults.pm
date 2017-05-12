use strict;
package WebService::Amazon::Glacier::ListVaults;
{
  $WebService::Amazon::Glacier::ListVaults::VERSION = '0.001';
}
use MooseX::App::Command;
use 5.010;
use POSIX qw(strftime);
use HTTP::Request;
use JSON;
use TryCatch;
use WebService::Amazon::Glacier::GlacierError;
use Net::Amazon::SignatureVersion4;
extends qw(WebService::Amazon::Glacier);


sub run {
    my ($self)=@_;
    try{
	foreach my $vault ($self->_list_vaults()){
	    say($vault->{'VaultName'});
	}
    }catch (WebService::Amazon::Glacier::GlacierError $e){
	die $e->error_message."\n";
    }
    return 0;
}


sub _list_vaults{
    my $self=shift;
    my @rv;
    my $marker="";
    my $query_param="limit=".$self->get_limit();
    my $hr=HTTP::Request->new('GET',"http://glacier.".$self->get_region().".amazonaws.com/".$self->get_AccountID()."/vaults?".$query_param, [ 
				  'Host', "glacier.".$self->get_region().".amazonaws.com", 
				  'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				  'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				  'x-amz-glacier-version', '2012-06-01',
			      ]);
    my $response=$self->_submit_request($hr);
    if ($response->is_success) {
	my $vault_list = decode_json($response->decoded_content());
	foreach my $vault(@{$vault_list->{'VaultList'}}){
	    push @rv, $vault;
	}
	if (defined $vault_list->{'Marker'}){
	    $marker=$vault_list->{'Marker'};
	}
    }

    while ($marker ne ""){
	my $query_param="limit=".$self->get_limit();
	$query_param .= "&marker=".$marker if (defined $marker);
	my $hr=HTTP::Request->new('GET',"http://glacier.".$self->get_region().".amazonaws.com/".$self->get_AccountID()."/vaults?".$query_param, [ 
				      'Host', "glacier.".$self->get_region().".amazonaws.com", 
				      'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				      'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				      'x-amz-glacier-version', '2012-06-01',
				  ]);
	my $response=$self->_submit_request($hr);
	if ($response->is_success) {
	    my $vault_list = decode_json($response->decoded_content());
	    foreach my $vault(@{$vault_list->{'VaultList'}}){
		push @rv, $vault;
	    }
	    if (defined $vault_list->{'Marker'}){
		$marker=$vault_list->{'Marker'};
	    }else{
		$marker="";
	    }
	}
    }
    return (@rv);
}

sub _encode{
    my $encoder = URI::Encode->new();
    my $rv=shift;
#    %20=%2F%2C%3F%3E%3C%60%22%3B%3A%5C%7C%5D%5B%7B%7D&%40%23%24%25%5E=
#    +  =/  ,  ?  %3E%3C%60%22;  :  %5C%7C]  [  %7B%7D&@  #  $  %25%5E=
    $rv=$encoder->encode($rv);
    $rv=~s/\+/\%20/;
    $rv=~s/\//\%2F/;
    $rv=~s/\,/\%2C/;
    $rv=~s/\?/\%3F/;
    $rv=~s/\;/\%3B/;
    $rv=~s/\:/\%3A/;
    $rv=~s/\]/\%5D/;
    $rv=~s/\[/\%5B/;
    $rv=~s/\@/\%40/;
    $rv=~s/\#/\%23/;
    $rv=~s/\$/\%24/;
#    $rv=~s///r;
    return $rv;
}
1;

__END__

=pod

=head1 NAME

WebService::Amazon::Glacier::ListVaults

=head1 VERSION

version 0.001

=head1 METHODS

=head2 _list_vaults

Returns an array of current vaults owned by the current AccountID.

=for Pod::Coverage run

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
