package INDataCenter;
use src::com::zoho::crm::api::dc::DataCenter;
use Moose;
extends 'DataCenter';
sub new
{
	my $class=shift;
	my $self={};
	bless $self,$class;
	return $self;
}

sub PRODUCTION
{
	return DataCenter::set_environment('https://www.zohoapis.in',INDataCenter->new()->get_iam_url(), INDataCenter->new()->get_file_upload_url());
}

sub SANDBOX
{
	return DataCenter::set_environment('https://www.zohoapis.in',INDataCenter->new()->get_iam_url(), INDataCenter->new()->get_file_upload_url());
}

sub DEVELOPER
{
	return DataCenter::set_environment('https://developer.zohoapis.in',INDataCenter->new()->get_iam_url(), INDataCenter->new()->get_file_upload_url());
}

sub get_iam_url
{
	return 'https://accounts.zoho.in/oauth/v2/token';
}

sub get_file_upload_url
{
	return "https://content.zohoapis.in";
}

=head1 NAME

com::zoho::crm::api::dc::INDataCenter - This class representing the India country Zoho CRM and Accounts URL. It is used to denote the domain of the user.

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<new>

This method creates the instance of the INDataCenter class.

=item C<PRODUCTION>

This Environment method  represents the India country's Zoho CRM production environment.

Returns instance of the Environment class.

=item C<SANDBOX>

This Environment method represents the India country's Zoho CRM sandbox environment.

Returns instance of Environment class.

=item C<DEVELOPER>

This Environment method represents the India country's Zoho CRM developer environment.

Returns instance of Environment class.

=back

=cut

1;
