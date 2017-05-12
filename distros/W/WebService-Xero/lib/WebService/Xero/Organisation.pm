package WebService::Xero::Organisation;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

WebService::Xero::Organisation - Object encapulates Organisation data returned by API

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

our @PROPERTIES = qw/APIKey Name LegalName PaysTax Version BaseCurrency CountryCode IsDemoCompany OrganisationStatus 
                     RegistrationNumber TaxNumber FinancialYearEndDay FinancialYearEndMonth 
                    SalesTaxBasis SalesTaxPeriod DefaultSalesTax DefaultPurchasesTax PeriodLockDate EndOfYearLockDate
                    CreatedDateUTC OrganisationEntityType OrganisationType Timezone ShortCode LineOfBusiness
                    Addresses Phones ExternalLinks PaymentTerms
                         /;

## ValidationErrors Warnings

=head1 SYNOPSIS

Object to describe an Organisation record as specified by Xero API and the associated DTD at 
L<https://github.com/XeroAPI/XeroAPI-Schemas/blob/master/src/main/resources/XeroSchemas/v2.00/Organisation.xsd>.

Perhaps a little code snippet.

    use  WebService::Xero::Organisation;

    my $org =  WebService::Xero::Organisation->new();
    
    or

    my $org = $xero_agent->api_account_organisation();


=head1 METHODS

=head2 new()

=cut

sub new 
{
  my ( $class, %params ) = @_;

    my $self = bless 
    {
      API_URL      => 'https://api.xero.com/api.xro/2.0/organisation',
      debug        => $params{debug} ## NOT REALLY USED YET
    }, $class;
    foreach my $key (@PROPERTIES) { 
      ## $self->{$key} = $params{$key} || '' 
      $self->{$key} = defined $params{$key} ? $params{$key} : ''; ## thanks to https://metacpan.org/author/STEVEB
    }

    return $self; #->_validate_agent(); ## derived classes will validate this

}


=head2 new_from_api_data()

  creates a new instance from the data provided by querying the API organisation end point 
  ( typically handled by WebService::Xero::Agent->api_account_organisation() which calls this method )

=cut 

sub new_from_api_data
{
  my ( $self, $data ) = @_;
  return $self->new(  %{$data->{Organisations}[0]} ) if ( ref($data->{Organisations}) eq 'ARRAY' and scalar(@{$data->{Organisations}})==1 );  
  return $self->new( debug=> $data );  

}

=head2 as_text()

  Returns a string with Carriage returns of each unique( non hash or array )
  property -  useful for debugging. NB - doesn't include Array or Hash properties

=cut


sub as_text 
{
    my ( $self ) = @_;


    # return join("\n", map { "$_ : $self->{$_}" if (defined $self->{$_} and $_  !~ /Addresses|Phones|ExternalLinks|PaymentTerms/m ) } @PROPERTIES); ## this works ok
    return "Organisation:\n" . join("\n", map { "$_ : $self->{$_}" if (defined $self->{$_} and ref($self->{$_}) !~ /ARRAY|HASH/m ) } @PROPERTIES);  ## this looks a little better?
}



=head1 TODO

  consider inclusion of Locale modules - Locale::Currency and Locale::Country


=head1 AUTHOR

Peter Scott, C<< <peter at computerpros.com.au> >>


=head1 REFERENCE


=head1 BUGS

Please report any bugs or feature requests to C<bug-ccp-xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CCP-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Xero::Organisation


You can also look for information at:

=over 4

=item * Xero Developer API Docs

L<https://developer.xero.com/documentation/api/organisation/>

=item * Xero API Schemas 

L<https://github.com/XeroAPI/XeroAPI-Schemas>

=item * Xero API Schema Organisation

L<https://github.com/XeroAPI/XeroAPI-Schemas/blob/master/src/main/resources/XeroSchemas/v2.00/Organisation.xsd>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Scott.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::Xero
