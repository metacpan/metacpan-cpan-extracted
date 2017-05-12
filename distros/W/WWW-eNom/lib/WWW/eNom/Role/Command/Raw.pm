package WWW::eNom::Role::Command::Raw;

use strict;
use warnings;
use utf8;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( HTTPTiny Str Strs );

use Data::Util qw( is_hash_ref );
use HTTP::Tiny;
use XML::LibXML::Simple qw( XMLin );
use Mozilla::PublicSuffix qw( public_suffix );

use Try::Tiny;
use Carp;

requires 'username', 'password', '_uri', 'response_type';

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Raw eNom API Commands

use Readonly;
# Create methods to support eNom API version 7.8:
Readonly my $COMMANDS => [qw(
    AddBulkDomains AddContact AddDomainFolder AddDomainHeader AddHostHeader
    AddToCart AdvancedDomainSearch AM_AutoRenew AM_Configure AM_GetAccountDetail
    AM_GetAccounts AssignToDomainFolder AuthorizeTLD CalculateAllHostPackagePricing
    CalculateHostPackagePricing CancelHostAccount CancelOrder CertChangeApproverEmail
    CertConfigureCert CertGetApproverEmail CertGetCertDetail CertGetCerts CertModifyOrder
    CertParseCSR CertReissueCert CertPurchaseCert CertResendApproverEmail
    CertResendFulfillmentEmail Check CheckLogin CheckNSStatus CommissionAccount
    Contacts CreateAccount CreateHostAccount CreateSubAccount DeleteAllPOPPaks DeleteContact
    DeleteCustomerDefinedData DeleteDomainFolder DeleteDomainHeader DeleteFromCart
    DeleteHostedDomain DeleteHostHeader DeleteNameServer DeletePOP3 DeletePOPPak
    DeleteRegistration DeleteSubaccount DisableFolderApp DisableServices EnableFolderApp
    EnableServices Extend Extend_RGP ExtendDomainDNS Forwarding GetAccountInfo GetAccountPassword
    GetAccountValidation GetAddressBook GetAgreementPage GetAllAccountInfo GetAllDomains
    GetAllHostAccounts GetAllResellerHostPricing GetBalance GetCartContent GetCatchAll GetCerts
    GetConfirmationSettings GetContacts GetCusPreferences GetCustomerDefinedData GetCustomerPaymentInfo
    GetDNS GetDNSStatus GetDomainCount GetDomainExp GetDomainFolderDetail GetDomainFolderList
    GetDomainHeader GetDomainInfo GetDomainNameID GetDomains GetDomainServices GetDomainSLDTLD
    GetDomainSRVHosts GetDomainStatus GetDomainSubServices GetDotNameForwarding GetExpiredDomains
    GetExtAttributes GetExtendInfo GetFilePermissions GetForwarding GetGlobalChangeStatus
    GetGlobalChangeStatusDetail GetHomeDomainList GetHostAccount GetHostAccounts GetHostHeader GetHosts
    GetIDNCodes GetIPResolver GetMailHosts GetMetaTag GetNameSuggestions GetNews GetOrderDetail
    GetOrderList GetPasswordBit GetPOP3 GetPOPExpirations GetPOPForwarding GetProductNews
    GetProductSelectionList GetRegHosts GetRegistrationStatus GetRegLock GetRenew GetReport
    GetResellerHostPricing GetResellerInfo GetServiceContact GetSPFHosts GetStorageUsage
    GetSubAccountDetails GetSubAccountPassword GetSubAccounts GetSubaccountsDetailList GetTLDDetails
    GetTLDList GetTransHistory GetWebHostingAll GetWhoisContact GetWPPSInfo GM_CancelSubscription
    GM_CheckDomain GM_GetCancelReasons GM_GetControlPanelLoginURL GM_GetRedirectScript GM_GetStatuses
    GM_GetSubscriptionDetails GM_GetSubscriptions GM_ReactivateSubscription GM_RenewSubscription
    GM_UpdateBillingCycle GM_UpdateSubscriptionDetails HostPackageDefine HostPackageDelete HostPackageModify
    HostPackageView HostParkingPage InsertNewOrder IsFolderEnabled ListDomainHeaders ListHostHeaders
    ListWebFiles MetaBaseGetValue MetaBaseSetValue ModifyDomainHeader ModifyHostHeader ModifyNS
    ModifyNSHosting ModifyPOP3 MySQL_GetDBInfo NameSpinner NM_CancelOrder NM_ExtendOrder
    NM_GetPremiumDomainSettings NM_GetSearchCategories NM_ProcessOrder NM_Search
    NM_SetPremiumDomainSettings ParseDomain PE_GetCustomerPricing PE_GetDomainPricing PE_GetEapPricing
    PE_GetPOPPrice PE_GetPremiumPricing PE_GetProductPrice PE_GetResellerPrice PE_GetRetailPrice
    PE_GetRetailPricing PE_GetRocketPrice PE_GetTLDID PE_SetPricing PP_CancelSubscription PP_CheckUpgrade
    PP_GetCancelReasons PP_GetControlPanelLoginURL PP_GetStatuses PP_GetSubscriptionDetails PP_GetSubscriptions
    PP_ReactivateSubscription PP_UpdateSubscriptionDetails PP_ValidatePassword Portal_GetDomainInfo
    Portal_GetAwardedDomains Portal_GetToken Portal_UpdateAwardedDomains PreConfigure Purchase PurchaseHosting
    PurchasePOPBundle PurchasePreview PurchaseServices PushDomain Queue_GetInfo Queue_GetExtAttributes
    Queue_DomainPurchase Queue_GetDomains Queue_GetOrders Queue_GetOrderDetail RAA_GetInfo RAA_ResendNotification
    RC_CancelSubscription RC_FreeTrialCheck RC_GetLoginToken RC_GetSubscriptionDetails RC_GetSubscriptions
    RC_RebillSubscription RC_ResetPassword RC_SetBillingCycle RC_SetPassword RC_SetSubscriptionDomain
    RC_SetSubscriptionName RefillAccount RegisterNameServer RemoveTLD RemoveUnsyncedDomains RenewPOPBundle
    RenewServices RPT_GetReport SendAccountEmail ServiceSelect SetCatchAll SetCustomerDefinedData SetDNSHost
    SetDomainSRVHosts SetDomainSubServices SetDotNameForwarding SetFilePermissions SetHosts SetIPResolver
    SetPakRenew SetPassword SetPOPForwarding SetRegLock SetRenew SetResellerServicesPricing SetResellerTLDPricing
    SetSPFHosts SetUpPOP3User SL_AutoRenew SL_Configure SL_GetAccountDetail SL_GetAccounts StatusDomain
    SubAccountDomains SynchAuthInfo TEL_AddCTHUser TEL_GetCTHUserInfo TEL_GetCTHUserList TEL_GetPrivacy TEL_IsCTHUser
    TEL_UpdateCTHUser TEL_UpdatePrivacy TLD_AddWatchlist TLD_DeleteWatchlist TLD_GetTLD TLD_GetWatchlist
    TLD_GetWatchlistTlds TLD_Overview TLD_PortalGetAccountInfo TLD_PortalUpdateAccountInfo TM_Check TM_GetNotice
    TM_UpdateCart TP_CancelOrder TP_CreateOrder TP_GetDetailsByDomain TP_GetOrder TP_GetOrderDetail TP_GetOrderReview
    TP_GetOrdersByDomain TP_GetOrderStatuses TP_GetTLDInfo TP_ResendEmail TP_ResubmitLocked TP_SubmitOrder
    TP_UpdateOrderDetail TS_AutoRenew TS_Configure TS_GetAccountDetail TS_GetAccounts UpdateAccountInfo
    UpdateAccountPricing UpdateCart UpdateCusPreferences UpdateDomainFolder UpdateExpiredDomains
    UpdateHostPackagePricing UpdateMetaTag UpdateNameServer UpdateNotificationAmount UpdatePushList
    UpdateRenewalSettings ValidatePassword WBLConfigure WBLGetCategories WBLGetFields WBLGetStatus
    WebHostCreateDirectory WebHostCreatePOPBox WebHostDeletePOPBox WebHostGetCartItem WebHostGetOverageOptions
    WebHostGetOverages WebHostGetPackageComponentList WebHostGetPackageMinimums WebHostGetPackages WebHostGetPOPBoxes
    WebHostGetResellerPackages WebHostGetStats WebHostHelpInfo WebHostSetCustomPackage WebHostSetOverageOptions
    WebHostUpdatePassword WebHostUpdatePOPPassword WSC_GetAccountInfo WSC_GetAllPackages WSC_GetPricing WSC_Update_Ops
    XXX_GetMemberId XXX_RemoveMemberId XXX_SetMemberId
)];

has '_api_commands' => (
    is       => 'ro',
    isa      => Strs,
    default  => sub { $COMMANDS },
    init_arg => undef,
);

has '_ua' => (
    is      => 'ro',
    isa     => HTTPTiny,
    lazy    => 1,
    default => sub { HTTP::Tiny->new },
);

sub BUILD {
    my $self = shift;

    $self->install_methods();

    return;
}

sub install_methods {
    my $self = shift;

    for my $command (@{ $self->_api_commands }) {
        $self->meta->add_method(
            $command => sub {
                my $self = shift;
                my %args = @_ == 1 && is_hash_ref( $_[0] ) ? %{ $_[0] } : @_;

                my $uri      = $self->_make_query_string( $command, \%args );
                my $response = $self->_ua->get( $uri )->{content};

#                print STDERR "URI: $uri\n";
#                print STDERR "Response: $response\n";

                if ( $self->response_type eq "xml_simple" ) {
                    $response = $self->_serialize_xml_simple_response( $response );
                }

                return $response;
            }
        );
    };

    return;
}

sub _make_query_string {
    my $self    = shift;
    my $command = shift;
    my %args    = @_ == 1 && is_hash_ref( $_[0] ) ? %{ $_[0] } : @_;

    my $uri = $self->_uri;
    if ( $command ne "CertGetApproverEmail" && exists $args{Domain} ) {
        @args{qw(SLD TLD)} = $self->_split_domain(delete $args{Domain});
    }

    my $response_type = $self->response_type eq 'xml_simple' ? 'xml' : $self->response_type;

    $uri->query_form(
        command      => $command,
        uid          => $self->username,
        pw           => $self->password,
        responseType => $response_type,
        %args,
    );

    return $uri;
}

sub _split_domain {
    my $self = shift;
    my ( $domain ) = pos_validated_list( \@_, { isa => Str } );

    return try {
        # Look for an eNom wildcard TLD:
        if( $domain =~ qr|(.+)\.([*12@]+)$|x ) {
            return ( $1, $2 );
        }

        my $suffix = public_suffix($domain);
        if( !$suffix ) {
            croak 'Unable to find a suffix from the domain';
        }

        # Finally, add in the neccesary API arguments:
        my ( $sld ) = $domain =~ /^(.+)\.$suffix$/x;

        return ($sld, $suffix);
    }
    catch {
        croak "Domain name, $domain, does not look like a valid domain.";
    };
}

sub _serialize_xml_simple_response {
    my $self = shift;
    my ( $response ) = pos_validated_list( \@_, { isa => Str } );

    $response = XMLin($response);

    $response->{errors}    &&= [ values %{ $response->{errors} } ];
    $response->{responses} &&= $response->{responses}{response};
    $response->{responses} =   [ $response->{responses} ]
        if $response->{ResponseCount} == 1;

    foreach my $key ( keys %{$response} ) {
        next unless $key =~ /(.*?)(\d+)$/;

        $response->{$1} = undef if ref $response->{$key};
        $response->{$1}[ $2 - 1 ] = delete $response->{$key};
    }

    return $response;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::eNom::Role::Command::Raw - Low Level Access to eNom API

=head1 SYNOPSIS

    use WWW::eNom;

    my $eNom     = WWW::eNom->new( ... );
    my $response = $eNom->Check(
        SLD => 'enom',
        TLD => 'com',
    );

=head1 REQUIRES

=over 4

=item username

=item password

=item _uri

=item response_type

=back

=head1 DESCRIPTION

This role composes a series of methods into the consuming class (L<WWW::eNom>) that directly expose methods of the L<eNom|http://www.enom.com/APICommandCatalog/> API.  It is the lowest level of access to the eNom API and is intended only for the most advanced usages that are not covered by other commands.

B<NOTE> You almost never want to make this low level of a call.  You really should be looking at the L<commands|WWW::eNom/COMMANDS> to find the specific method to accomplish your goals.

=head1 METHODS

Most of the eNom API Methods have been included and are exposed based on the name of the method as documented in L<eNom's API Reference Docs|http://www.enom.com/APICommandCatalog/API%20topics/api_alpha_list.htm>.  If you really wish to use the eNom API directly this is how you would do it, but keep in mind you'll have to read the details of the documentation for that method and handle the parsing of request params and the response yourself.  Again, you should try very hard to avoid doing this, if you find some functionalty that is not exposed through L<WWW::eNom> a bug report or pull request is your best bet.

However, if your heart is set then let's use an example method to demonstrate how best to make use of these low level API calls.

=head2 Check

    use WWW::eNom;

    my $eNom = WWW::eNom->new(
        ...
        response_type => 'xml_simple',
    );

￼   my $response = $eNom->Check(
        SLD => 'enom',
        TLD => 'com',
    );

Although not required, it is recommend that you specify a response_type of 'xml_simple' when making low level requests.  This will at least make the response a HashRef (rather than a string).  This response should look very similar to the response documented by the specific method with eNom with the following modifications made to make the system easier to work with.

=over 4

=item "responses" returns an ArrayRef of HashRefs

=item Keys which end with a number are transformed into an ArrayRef

If you had a response:

    {
        RRPText1 => 'Domain Not Available',
        RRPText2 => 'Domain Available',
        RRPText3 => 'Domain Not Available',
    }

This is automagically converted into...

    {
        RRPText => [ 'Domain Not Available', 'Domain Available', 'Domain Not Available' ],
    }

This is especially important when looking at errors or the "ErrX" response.  Rather than having the numbered responses, that is converted to an ArrayRef.

=back

These changes make a possible response look like:

    {
        Domain  => [qw(enom.com enom.net enom.org enom.biz enom.info)],
        Command => "CHECK",
        RRPCode => [qw(211 211 211 211 211)],
        RRPText => [
            "Domain not available",
            "Domain not available",
            "Domain not available",
            "Domain not available",
            "Domain not available"
        ]
    }

However, keep in mind you will need to refer to the actual documentation from eNom because even similar methods could have vastly different responses.

=for Pod::Coverage install_methods

=cut
