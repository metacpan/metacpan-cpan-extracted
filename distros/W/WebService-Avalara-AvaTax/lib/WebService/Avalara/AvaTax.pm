package WebService::Avalara::AvaTax;

# ABSTRACT: Avalara SOAP interface as compiled Perl methods

use strict;
use warnings;

our $VERSION = '0.020';    # VERSION
use utf8;

#pod =head1 SYNOPSIS
#pod
#pod     use WebService::Avalara::AvaTax;
#pod     my $avatax = WebService::Avalara::AvaTax->new(
#pod         username => 'avalara@example.com',
#pod         password => 'sekrit',
#pod     );
#pod     my $answer_ref = $avatax->ping;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class provides a Perl method API for
#pod Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
#pod web services. The first call to any AvaTax SOAP operation uses
#pod L<XML::Compile::WSDL11|XML::Compile::WSDL11>
#pod to compile and execute against the specified Avalara AvaTax service;
#pod subsequent calls can vary the parameters but will use the same compiled code.
#pod
#pod =cut

use Carp;
use Const::Fast;
use DateTime;
use DateTime::Format::XSD;
use English '-no_match_vars';
use Moo;
use Package::Stash;
use Scalar::Util 'blessed';
use Sys::Hostname;
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Str);
use WebService::Avalara::AvaTax::Service::Address;
use WebService::Avalara::AvaTax::Service::Tax;
use namespace::clean;
with 'WebService::Avalara::AvaTax::Role::Connection';

#pod =method new
#pod
#pod Builds a new AvaTax web service client. Since this class consumes the
#pod L<WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection>
#pod role, please consult that module's documentation for a full list of attributes
#pod that can be set at construction.
#pod
#pod =cut

#pod =attr services
#pod
#pod This module is really just a convenience wrapper around instances of
#pod L<WebService::Avalara::AvaTax::Service::Address|WebService::Avalara::AvaTax::Service::Address>
#pod and
#pod L<WebService::Avalara::AvaTax::Service::Tax|WebService::Avalara::AvaTax::Service::Tax>
#pod modules. As such this attribute is used to keep an array reference to
#pod instances of both classes, with the following attributes from L</new>
#pod passed to both:
#pod
#pod =over
#pod
#pod =item L<username|WebService::Avalara::AvaTax::Role::Connection/username>
#pod
#pod =item L<password|WebService::Avalara::AvaTax::Role::Connection/password>
#pod
#pod =item L<use_wss|WebService::Avalara::AvaTax::Role::Connection/use_wss>
#pod
#pod =item L<is_production|WebService::Avalara::AvaTax::Role::Connection/is_production>
#pod
#pod =item L<user_agent|WebService::Avalara::AvaTax::Role::Connection/user_agent>
#pod
#pod =item L<debug|WebService::Avalara::AvaTax::Role::Connection/debug>
#pod
#pod =back
#pod
#pod =cut

has services => (
    is       => 'lazy',
    isa      => ArrayRef,
    init_arg => undef,
    default  => sub {
        [ map { $_[0]->_new_service($_) } qw(Address Tax) ];
    },
);

sub _new_service {
    my $self  = shift;
    my $class = __PACKAGE__ . '::Service::' . shift;
    return $class->new(
        map { ( $_ => $self->$_ ) }
            qw(username password use_wss is_production user_agent debug),
    );
}

#pod =head1 METHODS
#pod
#pod Aside from the L</new> method, L</services> attribute and
#pod other attributes and methods consumed from
#pod L<WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection>,
#pod available method names are dynamically loaded from each
#pod L</services>' C<wsdl>
#pod attribute and can be passed either a hash or reference to a hash with the
#pod necessary parameters. In scalar context they return a reference to a hash
#pod containing the results of the SOAP call; in list context they return the
#pod results hashref and an
#pod L<XML::Compile::SOAP::Trace|XML::Compile::SOAP::Trace>
#pod object suitable for debugging and exception handling.
#pod
#pod If there is no result then you should check the trace object for why.
#pod
#pod Please consult the
#pod Avalara SOAP API reference (C<http://developer.avalara.com/api-reference>)
#pod for semantic details on the methods, parameters and results available for each
#pod of the methods listed below. Note that in order to make this interface easier
#pod and more Perl-ish, the following changes have been made:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod SOAP operation names have been transformed from C<CamelCase> to
#pod C<lowercase_with_underscores>. For example, C<GetTax> is now
#pod L</get_tax>. If you do not like this behavior then use
#pod L<<< C<< orthodox => 1 >>|/orthodox >>> when calling L</new>.
#pod
#pod =item *
#pod
#pod Parameters do not need to be enclosed in C<{parameters}{FooRequest}{ ... }>
#pod hashes of hashes. These will be automatically added for you, along with all
#pod necessary SOAP headers. The examples below reflect this.
#pod
#pod =item *
#pod
#pod Similarly, results are not enclosed in C<{parameters}{FooResult}{ ... }>
#pod hashes of hashes. They are, however, returned as a hash reference, not a
#pod simple hash. If you want access to other aspects of the SOAP response, make
#pod the call in list context and the second value in the list will be an
#pod L<XML::Compile::SOAP::Trace|XML::Compile::SOAP::Trace>
#pod instance with methods for retrieving the full request and response as
#pod L<HTTP::Request|HTTP::Request> and
#pod L<HTTP::Response|HTTP::Response> objects,
#pod along with other methods for doing things like retrieving the parsed
#pod L<XML::LibXML::Document|XML::LibXML::Document> DOM
#pod node of the response.
#pod
#pod =back
#pod
#pod =attr orthodox
#pod
#pod When set to true at construction, the generated methods will exactly match
#pod their C<CamelCase> SOAP operation names.
#pod
#pod =cut

has orthodox => ( is => 'ro', isa => Bool, default => 0 );

#pod =for Pod::Coverage BUILD
#pod
#pod =cut

sub BUILD {
    my $self = shift;

    for my $service ( @{ $self->services } ) {
        while ( my ( $operation_name, $client )
            = each %{ $service->clients } )
        {
            my $method_name = $operation_name;
            if ( not $self->orthodox ) {    # normalize operation name
                $method_name
                    =~ s/ (?<= [[:alnum:]] ) ( [[:upper:]] ) /_\l$1/xmsg;
                $method_name = lcfirst $method_name;
            }

            $self->_stash->add_symbol( "&$method_name" =>
                    _method_closure( $service, $operation_name, $client ) );
        }
    }
    return;
}

has _stash => (
    is      => 'lazy',
    isa     => InstanceOf ['Package::Stash'],
    default => sub { Package::Stash->new(__PACKAGE__) },
);

const my %OPERATION_PARAMETER => (
    Ping         => 'Message',
    IsAuthorized => 'Operations',
    map { ( $_ => "${_}Request" ) }
        qw(
        GetTax
        GetTaxHistory
        PostTax
        CommitTax
        CancelTax
        ReconcileTaxHistory
        AdjustTax
        ApplyPayment
        TaxSummaryFetch
        Validate
        ),
);

sub _method_closure {
    my ( $service, $operation_name, $client ) = @_;
    return sub {
        my ( $self, @parameters ) = @_;

        $service->_current_operation_name($operation_name);
        if ( 'GetTax' eq $operation_name ) {
            @parameters = _today_to_docdate(@parameters);
        }

        my $client_version  = "$PROGRAM_NAME,";
        my $adapter_version = __PACKAGE__ . q{,};
        if ($main::VERSION) { $client_version  .= $main::VERSION }
        if ($VERSION)       { $adapter_version .= $VERSION }
        my ( $answer_ref, $trace ) = $client->(
            Profile => {
                Client  => $client_version,
                Adapter => $adapter_version,
                Machine => hostname(),
            },
            parameters => {
                $OPERATION_PARAMETER{$operation_name} => @parameters % 2
                ? "@parameters"
                : {@parameters},
            },
            $service->use_wss ? ()
            : ( Security => {
                    UsernameToken => {
                        map { ( "\u$_" => $service->$_ ) }
                            qw(username password),
                    },
                },
            ),
        );
        if ( 'HASH' eq ref $answer_ref ) {
            ## no critic (ValuesAndExpressions::ProhibitAccessOfPrivateData)
            $answer_ref
                = $answer_ref->{parameters}{"${operation_name}Result"};
        }
        return wantarray ? ( $answer_ref, $trace ) : $answer_ref;
    };
}

sub _today_to_docdate {
    my %parameters = @_;
    if ( not defined $parameters{DocDate} ) {
        $parameters{DocDate}
            = DateTime::Format::XSD->format_datetime( DateTime->today );
        $parameters{DocDate} =~ s/ T .* \z//xms;
    }
    return %parameters;
}

1;

__END__

=pod

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

WebService::Avalara::AvaTax - Avalara SOAP interface as compiled Perl methods

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use WebService::Avalara::AvaTax;
    my $avatax = WebService::Avalara::AvaTax->new(
        username => 'avalara@example.com',
        password => 'sekrit',
    );
    my $answer_ref = $avatax->ping;

=head1 DESCRIPTION

This class provides a Perl method API for
Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
web services. The first call to any AvaTax SOAP operation uses
L<XML::Compile::WSDL11|XML::Compile::WSDL11>
to compile and execute against the specified Avalara AvaTax service;
subsequent calls can vary the parameters but will use the same compiled code.

=head1 METHODS

Aside from the L</new> method, L</services> attribute and
other attributes and methods consumed from
L<WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection>,
available method names are dynamically loaded from each
L</services>' C<wsdl>
attribute and can be passed either a hash or reference to a hash with the
necessary parameters. In scalar context they return a reference to a hash
containing the results of the SOAP call; in list context they return the
results hashref and an
L<XML::Compile::SOAP::Trace|XML::Compile::SOAP::Trace>
object suitable for debugging and exception handling.

If there is no result then you should check the trace object for why.

Please consult the
Avalara SOAP API reference (C<http://developer.avalara.com/api-reference>)
for semantic details on the methods, parameters and results available for each
of the methods listed below. Note that in order to make this interface easier
and more Perl-ish, the following changes have been made:

=over

=item *

SOAP operation names have been transformed from C<CamelCase> to
C<lowercase_with_underscores>. For example, C<GetTax> is now
L</get_tax>. If you do not like this behavior then use
L<<< C<< orthodox => 1 >>|/orthodox >>> when calling L</new>.

=item *

Parameters do not need to be enclosed in C<{parameters}{FooRequest}{ ... }>
hashes of hashes. These will be automatically added for you, along with all
necessary SOAP headers. The examples below reflect this.

=item *

Similarly, results are not enclosed in C<{parameters}{FooResult}{ ... }>
hashes of hashes. They are, however, returned as a hash reference, not a
simple hash. If you want access to other aspects of the SOAP response, make
the call in list context and the second value in the list will be an
L<XML::Compile::SOAP::Trace|XML::Compile::SOAP::Trace>
instance with methods for retrieving the full request and response as
L<HTTP::Request|HTTP::Request> and
L<HTTP::Response|HTTP::Response> objects,
along with other methods for doing things like retrieving the parsed
L<XML::LibXML::Document|XML::LibXML::Document> DOM
node of the response.

=back

=head2 new

Builds a new AvaTax web service client. Since this class consumes the
L<WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection>
role, please consult that module's documentation for a full list of attributes
that can be set at construction.

=head2 get_tax

I<< (SOAP operation: C<GetTax>) >>

As a convenience to
L<Business::Tax::Avalara|Business::Tax::Avalara>
users (and others), the C<DocDate> element below will default to today's date
in the UTC time zone.

Constructing and making an example request:

    my %get_tax_request = (
        CompanyCode         => 'APITrialCompany',
        DocType             => 'SalesInvoice',
        DocCode             => 'INV001',
        DocDate             => '2014-01-01',
        CustomerCode        => 'ABC4335',
        Discount            => 0,
        OriginCode          => 0,
        DestinationCode     => 1,
        DetailLevel         => 'Tax',
        HashCode            => 0,
        Commit              => 'false',
        ServiceMode         => 'Automatic',
        PaymentDate         => '1900-01-01',
        ExchangeRate        => 1,
        ExchangeRateEffDate => '1900-01-01',
    );

    my @addresses = (
        {   Line1       => '45 Fremont Street',
            City        => 'San Francisco',
            Region      => 'CA',
            PostalCode  => '94105-2204',
            Country     => 'US',
            TaxRegionId => 0,
        },
        {   Line1       => '118 N Clark St',
            Line2       => 'ATTN Accounts Payable',
            City        => 'Chicago',
            Region      => 'IL',
            PostalCode  => '60602-1304',
            Country     => 'US',
            TaxRegionId => 0,
        },
        {   Line1       => '100 Ravine Lane',
            City        => 'Bainbridge Island',
            Region      => 'WA',
            PostalCode  => '98110',
            Country     => 'US',
            TaxRegionId => 0,
        },
    );
    for my $address_code (0 .. $#addresses) {
        push @{$get_tax_request{Addresses}{BaseAddress}} => {
            AddressCode => $address_code,
            %{ $addresses[$address_code] },
        };
    }

    my @lines = (
        {   OriginCode      => 0,
            DestinationCode => 1,
            ItemCode        => 'N543',
            TaxCode         => 'NT',
            Qty             => 1,
            Amount          => 10,
            Discounted      => 'false',
            Description     => 'Red Size 7 Widget',
        },
        {   OriginCode      => 0,
            DestinationCode => 2,
            ItemCode        => 'T345',
            TaxCode         => 'PC030147',
            Qty             => 3,
            Amount          => 150,
            Discounted      => 'false',
            Description     => 'Size 10 Green Running Shoe',
        },
        {   OriginCode      => 0,
            DestinationCode => 2,
            ItemCode        => 'FREIGHT',
            TaxCode         => 'FR',
            Qty             => 1,
            Amount          => 15,
            Discounted      => 'false',
            Description     => 'Shipping Charge',
        },
    );
    for my $line_no (1 .. @lines) {
        push @{$get_tax_request{Lines}{Line}} => {
            No => $line_no,
            %{ $lines[$line_no - 1] },
        };
    }

    my ( $answer_ref, $trace ) = $avatax->get_tax(%get_tax_request);

=head2 post_tax

I<< (SOAP operation: C<PostTax>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->post_tax(
        CompanyCode => 'APITrialCompany',
        DocType     => 'SalesInvoice',
        DocCode     => 'INV001',
        Commit      => 0,
        DocDate     => '2014-01-01',
        TotalTax    => '14.27',
        TotalAmount => 175,
        NewDocCode  => 'INV001-1',
    );

=head2 commit_tax

I<< (SOAP operation: C<CommitTax>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->commit_tax(
        DocCode     => 'INV001',
        DocType     => 'SalesInvoice',
        CompanyCode => 'APITrialCompany',
        NewDocCode  => 'INV001-1',
    );

=head2 cancel_tax

I<< (SOAP operation: C<CancelTax>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->cancel_tax(
        CompanyCode => 'APITrialCompany',
        DocType     => 'SalesInvoice',
        DocCode     => 'INV001',
        CancelCode  => 'DocVoided',
    );

=head2 adjust_tax

I<< (SOAP operation: C<AdjustTax>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->adjust_tax(
        AdjustmentReason      => 4,
        AdjustmentDescription => 'Transaction Adjusted for Testing',
        GetTaxRequest => {
            CustomerCode => 'ABC4335',
            DocDate      => '2014-01-01',
            CompanyCode  => 'APITrialCompany',
            DocCode      => 'INV001',
            DetailLevel  => 'Tax',
            Commit       => 0,
            DocType      => 'SalesInvoice',
            # BusinessIdentificationNo => '234243',
            # CustomerUsageType        => 'G',
            # ExemptionNo              => '12345',
            # Discount                 => 50,
            # LocationCode             => '01',
            # TaxOverride => [
            #    {   TaxOverrideType => 'TaxDate',
            #        Reason          => 'Adjustment for return',
            #        TaxDate         => '2013-07-01',
            #        TaxAmount       => 0,
            #    },
            # ],
            # ServiceMode => 'Automatic',
            PurchaseOrderNo     => 'PO123456',
            ReferenceCode       => 'ref123456',
            PosLaneCode         => '09',
            CurrencyCode        => 'USD',
            ExchangeRate        => '1.0',
            ExchangeRateEffDate => '2013-01-01',
            SalespersonCode     => 'Bill Sales',
            Addresses => { BaseAddress => [
                {   AddressCode => '01',
                    Line1       => '45 Fremont Street',
                    City        => 'San Francisco',
                    Region      => 'CA',
                },
                {   AddressCode => '02',
                    Line1       => '118 N Clark St',
                    Line2       => 'Suite 100',
                    Line3       => 'ATTN Accounts Payable',
                    City        => 'Chicago',
                    Region      => 'IL',
                    Country     => 'US',
                    PostalCode  => '60602',
                },
                {   AddressCode => '03',
                    Latitude    => '47.627935',
                    Longitude   => '-122.51702',
                },
            ] },
            Lines => { Line => [
                {   No              => '01',
                    ItemCode        => 'N543',
                    Qty             => 1,
                    Amount          => 10,
                    TaxCode         => 'NT',
                    Description     => 'Red Size 7 Widget',
                    OriginCode      => '01',
                    DestinationCode => '02',
                    # CustomerUsageType => 'L',
                    # ExemptionNo       => '12345',
                    # Discounted        => 1,
                    # TaxIncluded       => 1,
                    # TaxOverride => {
                    #     TaxOverrideType => 'TaxDate',
                    #     Reason          => 'Adjustment for return',
                    #     TaxDate         => '2013-07-01',
                    #     TaxAmount       => 0,
                    # },
                    Ref1 => 'ref123',
                    Ref2 => 'ref456',
                },
                {   No              => '02',
                    ItemCode        => 'T345',
                    Qty             => 3,
                    Amount          => 150,
                    OriginCode      => '01',
                    DestinationCode => '03',
                    Description     => 'Size 10 Green Running Shoe',
                    TaxCode         => 'PC30147',
                },
                {   No              => '02-FR',
                    ItemCode        => 'FREIGHT',
                    Qty             => 1,
                    Amount          => 15,
                    OriginCode      => '01',
                    DestinationCode => '03',
                    Description     => 'Shipping Charge',
                    TaxCode         => 'FR',
                },
            ] },
        },
    );

=head2 get_tax_history

I<< (SOAP operation: C<GetTaxHistory>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->get_tax_history(
        CompanyCode => 'APITrialCompany',
        DocType     => 'SalesInvoice',
        DocCode     => 'INV001',
        DetailLevel => 'Tax',
    );

=head2 validate

I<< (SOAP operation: C<Validate>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->validate(
        Address => {
            Line1      => '118 N Clark St',
            Line2      => 'Suite 100',
            Line3      => 'ATTN Accounts Payable',
            City       => 'Chicago',
            Region     => 'IL',
            PostalCode => '60602',
        },
        Coordinates => 1,
        Taxability  => 1,
        TextCase    => 'Upper',
    );

=head2 is_authorized

I<< (SOAP operation: C<IsAuthorized>) >>

Both
L<WebService::Avalara::AvaTax::Service::Address|WebService::Avalara::AvaTax::Service::Address>
and
L<WebService::Avalara::AvaTax::Service::Tax|WebService::Avalara::AvaTax::Service::Tax>
provide C<IsAuthorized> operations. However, since the latter is loaded last,
only its version is called when you call this method. If you need to
specifically call a particular service's C<IsAuthorized>, use the
L<call|XML::Compile::WSDL11/Compilers>
method on its C<wsdl> attribute.

Note that the parameter passed to this call is a comma-delimited list of
SOAP operation names in C<CamelCase>, not C<lowercase_with_underscores>.

Example:

    my ( $answer_ref, $trace ) = $avatax->is_authorized(
        join ', ' => qw(
            Ping
            IsAuthorized
            GetTax
            PostTax
            GetTaxHistory
            CommitTax
            CancelTax
            AdjustTax
        ),
    );

=head2 ping

I<< (SOAP operation: C<Ping>) >>

Both
L<WebService::Avalara::AvaTax::Service::Address|WebService::Avalara::AvaTax::Service::Address>
and
L<WebService::Avalara::AvaTax::Service::Tax|WebService::Avalara::AvaTax::Service::Tax>
provide C<Ping> operations. However, since the latter is loaded last,
only its version is called when you call this method. If you need to
specifically call a particular service's C<Ping>, use the
L<call|XML::Compile::WSDL11/Compilers>
method on its C<wsdl> attribute.

Note that this method does support a single string as a message parameter;
this is effectively ignored though.

Example:

    use List::Util 1.33 'any';
    my ( $answer_ref, $trace ) = $avatax->ping;
    for my $code ( $answer_ref->{ResultCode} ) {
        if ( $code eq 'Success' ) { say $code;                    last }
        if ( $code eq 'Warning' ) { warn $answer_ref->{Messages}; last }

        die $answer_ref->{Messages} if any {$code eq $_} qw(Error Exception);
    }

=head2 tax_summary_fetch

I<< (SOAP operation: C<TaxSummaryFetch>) >>

Example:

    my ( $answer_ref, $trace ) = $avatax->tax_summary_fetch(
        MerchantCode => 'example',
        StartDate    => '2014-01-01',
        EndDate      => '2014-01-31',
    );

=head2 apply_payment (DEPRECATED)

I<< (SOAP operation: C<ApplyPayment>) >>

From Avalara API documentation
(C<http://developer.avalara.com/api-docs/soap/applypayment>):

=over

The ApplyPayment method of the TaxSvc was originally designed to update an
existing document record with a PaymentDate value. This function (and
cash-basis accounting in general) is no longer supported, and will not work
on new or existing accounts, but remains in the TaxSvc WSDL and some
automatically built adaptors for backwards compatibility.

=back

Example:

    my ( $answer_ref, $trace ) = $avatax->apply_payment(
        DocId       => 'example',
        CompanyCode => 'APITrialCompany',
        DocType     => 'SalesInvoice',
        DocCode     => 'INV001',
        PaymentDate => '2014-01-01',
    );

=head2 reconcile_tax_history (LEGACY API)

I<< (SOAP operation: C<ReconcileTaxHistory>) >>

From Avalara API documentation
(C<http://developer.avalara.com/api-docs/soap/reconciletaxhistory>):

=over

The ReconcileTaxHistory method of the TaxSvc was designed to allow users to
pull a range of documents for reconciliation against a document of record
(i.e. in the ERP), and then flag the reconciled documents as completed. Those
flagged documents would then be omitted from subsequent ReconcileTaxHistory
calls. This method no longer changes the "reconciled" document flag, but can
be used to retrieve ranges of document data (much like the AccountSvc
DocumentFetch
(C<http://developer.avalara.com/api-docs/soap/accountsvc/document-elements>)),
and remains in the TaxSvc WSDL and some automatically built
adaptors for backwards compatibility.

=back

Example:

    my ( $answer_ref, $trace ) = $avatax->reconcile_tax_history(
        CompanyCode => 'APITrialCompany',
        LastDocId   => 'example',
        Reconciled  => 1,
        StartDate   => '2014-01-01',
        EndDate     => '2014-01-31',
        DocStatus   => 'Temporary',
        DocType     => 'SalesOrder',
        LastDocCode => 'example',
        PageSize    => 10,
    );

=head1 ATTRIBUTES

=head2 services

This module is really just a convenience wrapper around instances of
L<WebService::Avalara::AvaTax::Service::Address|WebService::Avalara::AvaTax::Service::Address>
and
L<WebService::Avalara::AvaTax::Service::Tax|WebService::Avalara::AvaTax::Service::Tax>
modules. As such this attribute is used to keep an array reference to
instances of both classes, with the following attributes from L</new>
passed to both:

=over

=item L<username|WebService::Avalara::AvaTax::Role::Connection/username>

=item L<password|WebService::Avalara::AvaTax::Role::Connection/password>

=item L<use_wss|WebService::Avalara::AvaTax::Role::Connection/use_wss>

=item L<is_production|WebService::Avalara::AvaTax::Role::Connection/is_production>

=item L<user_agent|WebService::Avalara::AvaTax::Role::Connection/user_agent>

=item L<debug|WebService::Avalara::AvaTax::Role::Connection/debug>

=back

=head2 orthodox

When set to true at construction, the generated methods will exactly match
their C<CamelCase> SOAP operation names.

=for Pod::Coverage BUILD

=head1 SEE ALSO

=over

=item Avalara Developer Network (C<http://developer.avalara.com/>)

Official source for Avalara developer information, including API
references, technical articles and more.

=item L<Business::Tax::Avalara|Business::Tax::Avalara>

An alternative that uses Avalara's REST API.

=item L<XML::Compile::SOAP|XML::Compile::SOAP> and L<XML::Compile::WSDL11|XML::Compile::WSDL11>

Part of the L<XML::Compile|XML::Compile> suite
and the basis for this distribution. It's helpful to understand these in
order to debug or extend this module.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc WebService::Avalara::AvaTax

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/WebService-Avalara-AvaTax>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/WebService-Avalara-AvaTax>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/WebService-Avalara-AvaTax>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/WebService-Avalara-AvaTax>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/WebService-Avalara-AvaTax>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/WebService-Avalara-AvaTax>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/WebService-Avalara-AvaTax>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=WebService-Avalara-AvaTax>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=WebService::Avalara::AvaTax>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
L<https://github.com/mjgardner/WebService-Avalara-AvaTax/issues>.
You will be automatically notified of any progress on the
request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/WebService-Avalara-AvaTax>

  git clone git://github.com/mjgardner/WebService-Avalara-AvaTax.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
