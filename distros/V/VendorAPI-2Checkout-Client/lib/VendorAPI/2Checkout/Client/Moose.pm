package VendorAPI::2Checkout::Client::Moose;

use namespace::autoclean;
use LWP::UserAgent;

use Moose;
use MooseX::NonMoose;
extends 'VendorAPI::2Checkout::Client';

use Moose::Util::TypeConstraints;
use Params::Validate qw(:all);

our $VERSION = '0.1502';

sub _base_uri { 'https://www.2checkout.com/api' };
sub _realm    { '2CO API'                       };
sub _netloc   { 'www.2checkout.com:443'         };

enum 'Format' => qw( XML JSON );

class_type 'LPW::UserAGent';

has ua => (
   is => 'ro',
   isa => 'LWP::UserAgent',
   lazy => 1,
   builder => '_buld_ua',
   init_arg => undef,
);

has  accept => (
   isa => 'Str',
   is  => 'ro',
   builder => '_build_accept',
   required => 1,
   init_arg => 'format',
);

sub _build_accept { mime_type($_[1]); }

has [ qw(username password) ] => (
   isa => 'Str',
   is => 'ro',
   required => 1,
);

sub _buld_ua {
   my $self = shift;
   my $ua = LWP::UserAgent->new( agent => "VendorAPI::2Checkout::Client/${VERSION} " );
   $ua->credentials(_netloc(), _realm(), $self->username, $self->password);
   return $ua;
}

sub BUILDARGS {
   my $class = shift;
   return { username => $_[0], password => $_[1], format => $class->mime_type($_[2]), };
}


=item $response = $c->list_sales();

Retrieves the list of sales for the vendor

=cut

my $sort_col_re = qr/^(sale_id|date_placed|customer_name|recurring|recurring_declined|usd_total)$/;
my $sort_dir_re = qr/^(ASC|DESC)$/;

my %v = (
             sale_id             => { type => SCALAR, regex => qw/^\d+$/ , untaint => 1, optional => 1, },
             invoice_id          => { type => SCALAR, regex => qw/^\d+$/ , untaint => 1, optional => 1, },
             pagesize            => { type => SCALAR, regex => qw/^\d+$/ , untaint => 1, optional => 1, },
             cur_page            => { type => SCALAR, regex => qw/^\d+$/ , untaint => 1, optional => 1, },
             customer_name       => { type => SCALAR, regex => qw/^[-A-Za-z.]+$/ , untaint => 1, optional => 1, },
             customer_email      => { type => SCALAR, regex => qw/^[-\w.+@]+$/ , untaint => 1, optional => 1,   },
             customer_phone      => { type => SCALAR, regex => qw/^[\d()-]+$/ , untaint => 1, optional => 1,    },
             vendor_product_id   => { type => SCALAR, regex => qw/^.+$/ , untaint => 1, optional => 1,    },
             ccard_first6        => { type => SCALAR, regex => qw/^\d{6}$/ , untaint => 1, optional => 1, },
             ccard_last2         => { type => SCALAR, regex => qw/^\d\d$/ , untaint => 1, optional => 1,  },
             date_sale_end       => { type => SCALAR, regex => qw/^\d{4}-\d\d-\d\d$/ , untaint => 1, optional => 1, },
             date_sale_begin     => { type => SCALAR, regex => qw/^\d{4}-\d\d-\d\d$/ , untaint => 1, optional => 1, },
             sort_col            => { type => SCALAR, regex => $sort_col_re  , untaint => 1, optional => 1, },
             sort_dir            => { type => SCALAR, regex => $sort_dir_re , untaint => 1, optional => 1,  },
             active_recurrings   => { type => SCALAR, regex => qr/^[01]$/, untaint => 1, optional => 1, },
             declined_recurrings => { type => SCALAR, regex => qr/^[01]$/, untaint => 1, optional => 1, },
             refunded            => { type => SCALAR, regex => qr/^[01]$/, untaint => 1, optional => 1, },
        );

my $_profile = { map { $_ => $v{$_} } keys %v };


sub list_sales {
   my $self = shift;
   my $path = '/sales/list_sales';
   my %input_params = validate(@_, $_profile);
   $self->call_2co_api($path, \%input_params);
}


=item  $response = $c->detail_sale(sale_id => $sale_id);

Retrieves the details for the named sale.

=cut

sub detail_sale {
   my $self = shift;
   my $_detail_profile = { map { $_ => $v{$_} } qw/sale_id invoice_id/ };
   my %p = validate(@_, $_detail_profile);

   unless ($p{sale_id} || $p{invoice_id}) {
      confess("detail_sale requires sale_id or invoice_id and received neither");
   }

   my $path = '/sales/detail_sale';

   my %params;
   if ($p{invoice_id} ) {
      $params{invoice_id} = $p{invoice_id};
   }
   else {
      $params{sale_id} = $p{sale_id};
   }

   $self->call_2co_api($path, \%params);
}

=item $response = $c->list_coupons();

Retrieves the list of coupons for the vendor

=cut

sub list_coupons {
   my $self = shift;
   $self->call_2co_api('/products/list_coupons');
}

=item  $response = $c->detail_coupon(coupon_code => $coupon_code);

Retrieves the details for the named coupon.

=cut

sub detail_coupon {
   my $self = shift;
   my $_detail_profile = { coupon_code => { type => SCALAR, regex => qr/^\w+$/, untaint => 1, optional => 0, }, }; 
   my %p = validate(@_, $_detail_profile);

   unless ( $p{coupon_code} ) {
      confess("detail_coupon requires coupon_code");
   }

   my $path = '/products/detail_coupon';
   my %params = (coupon_code => $p{coupon_code} );
   $self->call_2co_api($path, \%params);
}

=item $response = $c->list_payments();

Retrieves the list of payments for the vendor

=cut

sub list_payments {
   my $self = shift;
   $self->call_2co_api('/acct/list_payments');
}

=item $response = $c->list_products();

Retrieves the list of products for the vendor

=cut

sub list_products {
   my $self = shift;
   $self->call_2co_api('/products/list_products');
}

=item $response = $c->list_options();

Retrieves the list of options for the vendor

=cut

sub list_options {
   my $self = shift;
   $self->call_2co_api('/products/list_options');
}

=item $response = $c->call_2co_api();

Talks to 2CO on behalf of the API methods

=cut

sub call_2co_api {
   my $self = shift;
   my $api_path = shift;
   my $query_params = shift;
   return undef unless $api_path;
   my $uri = URI->new(_base_uri() . $api_path);
   my %headers = ( Accept => $self->accept() );
   for my $k ( keys %$query_params ) {
      $uri->query_param($k => $query_params->{$k});
   }
   $self->ua->get($uri, %headers);
}

__PACKAGE__->meta->make_immutable;
1;
