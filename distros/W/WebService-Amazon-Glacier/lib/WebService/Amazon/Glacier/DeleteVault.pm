use strict;
package WebService::Amazon::Glacier::DeleteVault;
{
  $WebService::Amazon::Glacier::DeleteVault::VERSION = '0.001';
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
    documentation => q[Name of vault to create],
    );

sub run {
    my ($self)=@_;
    
    try{
	$self->_delete_vault();
    }catch (WebService::Amazon::Glacier::GlacierError $e){
	die $e->error_message;
    }
    return 0;
}

sub _delete_vault{
    my $self=shift;
    
    my $hr=HTTP::Request->new('DELETE',"https://glacier.".$self->get_region().".amazonaws.com/".$self->get_AccountID()."/vaults/".$self->get_vaultname(), [ 
				  'Host', "glacier.".$self->get_region().".amazonaws.com", 
				  'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				  'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				  'x-amz-glacier-version', '2012-06-01',
			       ]);

    my $response=$self->_submit_request($hr);

    if ($response->is_success) {
	return;
    } else {
	die WebService::Amazon::Glacier::GlacierError->new( error_code => $response->code(),
							    error_message => $response->as_string(),
	    );

    }
    return;
}

1;

__END__

=pod

=head1 NAME

WebService::Amazon::Glacier::DeleteVault

=head1 VERSION

version 0.001

=head1 METHODS

=head2 _delete_vault

Requires vaultname to be set.  Deletes the selected vault.  Throws an
exception if it can't be created for any reason.

=for Pod::Coverage run

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
