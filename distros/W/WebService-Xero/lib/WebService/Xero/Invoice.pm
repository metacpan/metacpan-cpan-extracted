package WebService::Xero::Invoice;

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
=head1 NAME

WebService::Xero::Invoice - encapsulates a Xero API Invoice record

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

our @PARAMS = qw/Date DueDate Status LineAmountTypes SubTotal TotalTax Total UpdatedDateUTC CurrencyCode Type InvoiceID InvoiceNumber AmountDue AmountPaid AmountCredited CurrencyRate/;

our @ARRAY_PARAMS = qw//; ## TODO: implement 


=head1 SYNOPSIS

Object to describe an Organisation record as specified by Xero API and the associated DTD at 
L<https://github.com/XeroAPI/XeroAPI-Schemas/blob/master/src/main/resources/XeroSchemas/v2.00/Invoice.xsd>.

Mostly a wrapper for Xero Invoice data structure.

Perhaps a little code snippet.

    use  WebService::Xero::Invoice;
    my $foo =  WebService::Xero::Invoice->new();
    ...


=head1 METHODS

=head2 new()

=cut

sub new 
{
  my ( $class, %params ) = @_;

    my $self = bless 
    {
      debug => $params{debug},
      API_URL => 'https://api.xero.com/api.xro/2.0/Invoices'
    }, $class;
    foreach my $key (@PARAMS) { $self->{$key} = defined $params{$key} ? $params{$key} : '';  }

    return $self; #->_validate_agent(); ## derived classes will validate this

}


=head2 create_new_through_agent()

=cut 

sub create_new_through_agent
{
  my ( $self, %params ) = @_;

  croak('need a valid agent parameter') unless (  ref( $params{agent} ) =~ /Agent/m  ); ## 

  my $new = WebService::Xero::Invoice->new( %params );

  ## TODO: Create 
  return $new;
}


=head2 new_from_api_data()

  creates a new instance from the data provided by querying the API organisation end point 
  ( typically handled by WebService::Xero::Agent->do_xero_api_call() )

  Example Contact Queries using Xero Agent that return Data consumable by this method:
    https://api.xero.com/api.xro/2.0/Contacts

  Returns undef, a single object instance or an array of object instances depending on the data input provided.


=cut 

sub new_from_api_data
{
  my ( $self, $data ) = @_;
  
  if ( ref($data->{Invoices}) eq 'ARRAY' and scalar(@{$data->{Invoices}})==1 )
  {
    return WebService::Xero::Invoice->new(  %{$data->{Invoices}[0]} ) 
  }
  elsif ( ref($data->{Invoices}) eq 'ARRAY' and scalar(@{$data->{Invoices}})>1 )
  {
    my $invoices = [];
    foreach my $invoice_struct ( @{$data->{Invoices}} ) 
    {
      push @$invoices, WebService::Xero::Invoice->new(  %{$invoice_struct} );
    }
    return $invoices;
  }
  return WebService::Xero::Invoice->new( debug=> $data );  

}


=head2 as_text()

=cut


sub as_text 
{
    my ( $self ) = @_;
    return "Invoice:\n" . join("\n", map { "$_ : $self->{$_}" } @PARAMS);
}


=head1 TODO


=head2 get_pdf()

  see API LIMITATIONS
  also https://developer.xero.com/documentation/getting-started/http-requests-and-responses/#get-individual
 
=cut 

sub get_pdf
{
  my ( $self ) = @_;
  return $self->error('Not implemented');
  ## TODO: confirm that we have a populated instance and id and if so - request as PDF
}




=head1 AUTHOR

Peter Scott, C<< <peter at computerpros.com.au> >>


=head1 REFERENCE


=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-xero at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Xero>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 API LIMITATIONS

Emailing Invoices - FROM Xero Developer Docs ( https://developer.xero.com/documentation/api/invoices/ )

It is not possible to email an invoice through the Xero application using the Xero accounting API.
To track progress on this feature request, or to add your support to it, please vote here.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Xero::Invoice


You can also look for information at:

=over 4

=item * Xero Developer API Docs

L<https://developer.xero.com/documentation/api/contacts/>


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
