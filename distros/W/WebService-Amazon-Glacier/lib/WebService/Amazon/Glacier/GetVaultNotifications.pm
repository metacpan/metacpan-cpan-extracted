use strict;
package WebService::Amazon::Glacier::GetVaultNotifications;
{
  $WebService::Amazon::Glacier::GetVaultNotifications::VERSION = '0.001';
}
use MooseX::App::Command;
use 5.010;
use POSIX qw(strftime);
use HTTP::Request;
use JSON;
use TryCatch;
use WebService::Amazon::Glacier::GlacierError;
extends qw(WebService::Amazon::Glacier);


option 'vaultname' => (
    is            => 'rw',
    isa           => 'Str',
    reader        => 'get_vaultname',
    predicate     => 'has_vaultname',
    required      => 1,
    documentation => q[Name of vault to query for notifications],
    );

sub run {
    my ($self)=@_;
    try{
	say($self->_get_vault_notifications());
    }catch (WebService::Amazon::Glacier::GlacierError $e){
	say("CODE:".$e->error_code());
	die $e->error_message."\n";
    }
    return 0;
}


sub _get_vault_notifications{
    my $self=shift;
    my $hr=HTTP::Request->new('GET',"http://glacier.".$self->get_region().".amazonaws.com/".$self->get_AccountID()."/vaults/".$self->get_vaultname."/notification-configuration", [ 
				  'Host', "glacier.".$self->get_region().".amazonaws.com", 
				  'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				  'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				  'x-amz-glacier-version', '2012-06-01',
			      ]);
    try{
	my $response=$self->_submit_request($hr);
	if ($response->is_success) {
	    return($response->decoded_content());
	}else{
	    die WebService::Amazon::Glacier::GlacierError->new( error_code => $response->code(),
								error_message => $response->as_string(),
		);
	}
    }catch(WebService::Amazon::Glacier::GlacierError $e){
	if ($e->error_code eq "404"){
	    return "Notifications Disabled for ".$self->get_vaultname();
	}else{
	    die $e;
	}
    }
}
1;

__END__

=pod

=head1 NAME

WebService::Amazon::Glacier::GetVaultNotifications

=head1 VERSION

version 0.001

=head1 METHODS

=head2 _get_vault_notifications

Returns a string describing the current vault notifications

=for Pod::Coverage run

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
