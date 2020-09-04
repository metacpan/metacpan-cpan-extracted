package Environment;
sub new
{
	my $class=shift;
	my $self={
		'url'=>shift,
		'accounts_url'=>shift,
		'file_upload_url'=>shift};
	bless $self,$class;
	return $self;

}
sub get_url
{
	my $self=shift;
	return $self->{url};
}
sub get_accounts_url
{
	my $self=shift;
	return $self->{accounts_url};
}

sub get_file_upload_url
{
	my $self = shift;
	return $self->{file_upload_url};
}


package DataCenter;
sub get_iam_url
{
}

sub get_file_upload_url
{
}

sub set_environment
{
	my ($url,$accounts_url, $file_upload_url)=@_;
	return Environment->new($url,$accounts_url, $file_upload_url);
}

=head1 NAME

com::zoho::crm::api::dc::Environment - This abstract class representing the Zoho CRM environment.

com::zoho::crm::api::dc::DataCenter - This class representing the Zoho CRM environment and accounts URL.

=head1 DESCRIPTION

=head2 METHODS(Environment)

=over 4

=item C<new>

Creates the instance of class Environment

=item C<get_url>

This method to get Zoho CRM API URL.

Returns a String representing ZOHO CRM API URL

=item C<get_accounts_url>

This method to get Zoho CRM Accounts URL.

Returns a String representing Accounts URL.

=back

=head2 METHODS(DataCenter)

=over 4

=item C<get_iam_url>

This method to get accounts URL.URL to be used when calling an OAuth accounts.

Returns a string representing accounts url.

=item C<set_environment>

This method sets the environment for the DataCenter.

Param url : A string representing URL.

Param accounts_url : A String representing the accounts url.

Returns Environment class object.

=back

=cut

1;
