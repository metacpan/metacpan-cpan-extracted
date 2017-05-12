package WebService::E4SE;

use Moo;
use Authen::NTLM 1.09;
use LWP::UserAgent 6.02;
use HTTP::Headers;
use HTTP::Request;
use Scalar::Util ();
use URI 1.60;
use XML::Compile::Licensed            ();
use XML::Compile::SOAP11              ();
use XML::Compile::SOAP12              ();
use XML::Compile::SOAP11::Client      ();
use XML::Compile::WSDL11              ();
use XML::Compile::Transport::SOAPHTTP ();
use XML::LibXML                       ();

use Carp ();
use strictures 2;
use namespace::clean;
use v5.10;

our $AUTHORITY = 'cpan:CAPOEIRAB';
our $VERSION   = '0.050';
$VERSION = eval $VERSION;

has _ua => (
    is   => 'rw',
    lazy => 1,
    isa  => sub {
        die "Not an LWP::UserAgent"
            unless Scalar::Util::blessed($_[0]) && $_[0]->isa('LWP::UserAgent');
    },
    default => sub { LWP::UserAgent->new(keep_alive => 1) },
);

has base_url => (
    is  => 'rw',
    isa => sub {
        die "Not an URI"
            unless Scalar::Util::blessed($_[0]) && $_[0]->isa('URI');
    },
    coerce => sub {
        (Scalar::Util::blessed($_[0]) && $_[0]->isa('URI'))
            ? $_[0]
            : URI->new($_[0]);
    },
    required => 1,
    default  => sub {
        URI->new('http://epicor/e4se/');
    }
);

has files => (
    is   => 'rw',
    lazy => 1,
    isa  => sub {
        die 'Should be an array reference'
            unless $_[0] && ref($_[0]) eq 'ARRAY';
    },
    default => sub {
        [
            qw(
                ActionCalls Attachment BackOfficeAP BackOfficeAR BackOfficeCFG
                BackOfficeGBBackOfficeGL BackOfficeIV BackOfficeMC Billing
                Business Carrier CommercialTerms Company ControllingProject
                CostVersion CRMClientHelper Currency Customer ECSClientHelper
                Employee ExchangeInterface Expense FinancialsAP FinancialsAR
                FinancialsCFG FinancialsGB FinancialsGL FinancialsMC
                FinancialsSync GLAccount IntersiteOrder InventoryLocation Journal
                Location LotSerial Manufacturer Material MaterialPlan MiscItems
                MSProject MSProjectEnterpriseCustomFieldsandLookupTables
                Opportunity Organization PartMaster Partner PriceStructure
                Project Prospect PSAClientHelper PurchaseOrder Receiving Recognize
                Resource SalesCycleManagement SalesOrder SalesPerson Shipping Site
                Supplier svActionCall svAttachment svBackOfficeAP svBackOfficeAR
                svBackOfficeCFG svBackOfficeGB svBackOfficeGL svBackOfficeIV
                svBackOfficeMC svBilling svBusiness svCarrier svCommercialTerms
                svCompany svControllingProject svCostVersion svCRMClientHelper
                svCurrency svCustomer svECSClientHelper svEmployee
                svExchangeInterface svExpense svFinancialsAP svFinancialsAR
                svFinancialsCFG svFinancialsGB svFinancialsGL svFinancialsMC
                svFinancialsSync svGLAccount svIntersiteOrder svInventoryLocation
                svJournal svLocation svLotSerial svManufacturer svMaterial
                svMaterialPlan svMiscItems svMSProject
                svMSProjectEnterpriseCustomFieldsandLookupTables svOpportunity
                svOrganization svPartMaster svPartner svPriceStructure svProject
                svProspect svPSAClientHelper svPurchaseOrder svReceiving
                svRecognize svResource svSalesCycleManagement svSalesOrder
                svSalesPerson svShipping svSite svSupplier svSysArtifact
                svSysDirector svSysDomainInfo svSysNotify svSysSearchManager
                svSysSecurity svSysWorkflow svTax svTime svUOM SysArtifact
                SysDirector SysDomainInfo SysNotify SysSearchManager SysSecurity
                SysWorkflow Tax Time UOM
                )
        ];
    },
);

has force_wsdl_reload => (
    is     => 'rw',
    coerce => sub {
        return 0 unless $_[0];
        return 1 if ref($_[0]);
        (lc($_[0]) eq 'false') ? 0 : 1;
    },
    required => 1,
    default  => 0
);

has password => (is => 'rw', required => 1, default => '',);

has realm => (is => 'rw', required => 1, default => '',);

has site => (is => 'rw', required => 1, default => 'epicor:80',);

has username => (is => 'rw', required => 1, default => '',);

sub _get_port {
    my ($self, $file) = @_;
    return "WSSoap" unless defined($file) and length($file);
    $file =~ s/\.\w+$//;    #strip extension
    return $file . "WSSoap";
}

sub _valid_file {
    my ($self, $file) = @_;
    return 0 unless defined $file and length $file;
    $file =~ s/\.asmx$//i;
    return 1 if (grep { $_ eq $file } @{$self->files});
    return 0;
}

sub call {
    my ($self, $file, $function, %parameters) = @_;
    Carp::croak("$file is not a valid web service found in E4SE.")
        unless $self->_valid_file($file);

    my $wsdl = $self->get_object($file);
    Carp::croak("Couldn't obtain the WSDL") unless $wsdl;

    return $wsdl->call($function, %parameters);
}

sub get_object {
    my ($self, $file) = @_;
    $self->{cache} //= {};
    Carp::croak("$file is not a valid web service found in E4SE.")
        unless $self->_valid_file($file);
    my $cache = $self->{cache};
    if ($self->force_wsdl_reload()) {
        delete($cache->{$file});
        $self->force_wsdl_reload(0);
    }

    #if our wsdl is already setup, let's just return
    return $cache->{$file}
        if (exists($cache->{$file}) && defined($cache->{$file}));

#wsdl doesn't exist.  let's setup the user agent for our transport and move along
    $self->_ua->credentials($self->site, $self->realm, $self->username,
        $self->password);

    my $res = $self->_ua->get(URI->new("$file?WSDL")->abs($self->base_url));
    Carp::croak("Unable to grab the WSDL from $file: " . $res->status_line())
        unless $res->is_success;

    $cache->{$file} = XML::Compile::WSDL11->new($res->decoded_content,
        server_type => 'SharePoint');
    Carp::croak("Unable to create new XML::Compile::WSDL11 object")
        unless $cache->{$file};

    my $trans = XML::Compile::Transport::SOAPHTTP->new(
        user_agent => $self->_ua,
        address    => URI->new($file)->abs($self->base_url),
    );
    Carp::carp("Unable to create new XML::Compile::Transport::SOAPHTTP object")
        unless $trans;

    $cache->{$file}
        ->compileCalls(port => $self->_get_port($file), transport => $trans,);
    return $cache->{$file};
}

sub operations {
    my ($self, $file) = @_;
    Carp::croak("$file is not a valid web service found in E4SE.")
        unless $self->_valid_file($file);
    my $wsdl = $self->get_object($file);
    my @ops = $wsdl->operations(port => $self->_get_port($file));
    return [map { $_->name } @ops];
}

1;    # End of WebService::E4SE

=encoding utf8

=head1 NAME

WebService::E4SE - Communicate with the various Epicor E4SE web services.

=head1 SYNOPSIS

	use WebService::E4SE;

	# create a new object
	my $ws = WebService::E4SE->new(
		username => 'AD\username',                  # NTLM authentication
		password => 'A password',                   # NTLM authentication
		realm => '',                                # LWP::UserAgent and Authen::NTLM
		site => 'epicor:80',                        # LWP::UserAgent and Authen::NTLM
		base_url => URL->new('http://epicor/e4se'), # LWP::UserAgent and Authen::NTLM
		timeout => 30,                              # LWP::UserAgent
	);

	# get an array ref of web service APIs to communicate with
	my $res = $ws->files();
	say Dumper $res;

	# returns a list of method names for the file you wanted to know about.
	my @operations = $ws->operations('Resource');
	say Dumper @operations;

	# call a method and pass some named parameters to it
	my ($res,$trace) = $ws->call('Resource','GetResourceForUserID', userID=>'someuser');

	# give me the XML::Compile::WSDL11 object
	my $wsdl = $ws->get_object('Resource'); #returns the usable XML::Compile::WSDL11 object

=head1 DESCRIPTION

L<WebService::E4SE> allows us to connect to
L<Epicor's E4SE|http://www.epicor.com/products/e4se.aspx> SOAP-based APIs
service to access our data or put in our timesheet.

Each action on the software calls a SOAP-based web service API method. Each API
call is authenticated via NTLM.

There are more than 100 web service files you could work with (.asmx
extensions) each having their own set of methods. On your installation of E4SE,
you can get a listing of method calls available by visiting one of those files
directly (C<http://your_epicor_server/e4se/Resource.asmx> for example).

The module will grab the WSDL from the file you're trying to deal with.  It will make
use of that WSDL with L<XML::Compile::WSDL11>.  You can force a reload of the WSDL at any
time.  So, we build the L<XML::Compile::WSDL11> object and hold onto it for any further
calls to that file.  These are generated by the calls you make, so hopefully we don't
kill you with too many objects.  You can work directly with the new L<XML::Compile::WSDL11>
object if you like, or use the abstracted out methods listed below.

For transportation, we're using L<XML::Compile::Transport::SOAPHTTP> using
L<LWP::UserAgent> with L<Authen::NTLM>.

=head1 ATTRIBUTES

L<WebService::E4SE> makes the following attributes available:

=head2 base_url

	my $url = $ws->base_url;
	$url = $ws->base_url(URI->new('http://epicor/e4se'));

This should be the base L<URL|URI> for your E4SE installation.

=head2 files

	my $files = $ws->files;
	$files = $ws->files(['file1', 'file2']);
	say join ', ', @$files;

This is reference to an array of file names that this web service has
knowledge of for an E4SE installation. If your installation has some services
that we're missing, you can inject them here. This will clobber, not
merge/append.

=head2 force_wsdl_reload

	my $force = $ws->force_wsdl_reload;
	$force = $ws->force_wsdl_reload(1);

This attribute is defaulted to false (0).  If set to true, the next call to a
method that would require a L<XML::Compile::WSDL11> object will go out to the
server and re-grab the WSDL and re-setup that WSDL object no matter if we have
already generated it or not. The attribute will be reset to false (0) directly
after the next WSDL object setup.

=head2 password

	my $pass = $ws->password;
	$pass = $ws->password('foobarbaz');

This will be your domain password.  No attempt to hide this is made.

=head2 realm

	my $realm = $ws->realm;
	$realm = $ws->realm('MyADRealm');

Default is an empty string.  This is for the L<Authen::NTLM> module and can generally be left blank.

=head2 site

	my $site = $ws->site;
	$site = $ws->site('epicor:80');

This is for the L<Authen::NTLM> module.  Set this accordingly.

=head2 username

	my $user = $ws->username;
	$user = $ws->username('AD\myusername');

Usually, you need to prefix this with the domain your E4SE installation is using.

=head1 METHODS

L<WebService::E4SE> makes the following methods available:

=head2 call

	use Try::Tiny;
	try {
		my ( $res, $trace) = $ws->call('Resource', 'GetResourceForUserID', %parameters );
		say Dumper $res;
	}
	catch {
		warn "An error happened: $_";
		exit(1);
	}

This method will call an API method for the file you want.  It will die on
errors outside of L<XML::Compile::WSDL11>'s knowledge, otherwise
it's just a little wrapper around L<XML::Compile::WSDL11>->call();

Another way to do this would be

	$ws->get_object('Reource')->call( 'GetResourceForUserID', %params );

=head2 get_object

	my $wsdl = $ws->get_object('Resource');

This method will return an L<XML::Compile::WSDL11> object for the file name
you supply.  This handles going to the file's WSDL URL, grabbing that URL
with L<LWP::UserAgent> and L<Authen::NTLM>, and using that WSDL response to
setup a new L<XML::Compile::WSDL11> object.

Note that if you have previously setup a L<XML::Compile::WSDL> object for that
file name, it will just return that object rather than going to the server and
requesting a new WSDL.

=head2 operations

	my $available_operations = $ws->operations( $file );

This method will return a list of  L<XML::Compile::SOAP::Operation> objects
that are available for the given file.

=head1 AUTHOR

Chase Whitener << <cwhitener at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests on GitHub L<https://github.com/genio/webservice-e4se/issues>.
We appreciate any and all criticism, bug reports, enhancements, or fixes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WebService::E4SE


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/genio/webservice-e4se>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013

This is free software, licensed under:

The Artistic License 2.0 (GPL Compatible)

=cut
