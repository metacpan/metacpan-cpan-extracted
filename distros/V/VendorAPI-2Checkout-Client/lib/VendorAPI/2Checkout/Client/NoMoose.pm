package VendorAPI::2Checkout::Client::NoMoose;

use 5.006;
use strict;
use warnings;

use LWP::UserAgent;
use Params::Validate qw(:all);
use Carp qw(confess);
use URI;
use URI::QueryParam;

=head1 NAME

VendorAPI::2Checkout::Client::NoMoose - an non-Moose OO interface to the 2Checkout.com Vendor API

=head1 VERSION

Version 0.1502

=cut

use vars qw( $VERSION @ISA );

@ISA = ( 'VendorAPI::2Checkout::Client' );
$VERSION = '0.1502';

=head1 SYNOPSIS

    use VendorAPI::2Checkout::Client;

    my $tco = VendorAPI::2Checkout::Client->new($username, $password, $format);
    $response = $tco->list_sales();

    $response = $tco->detail_sale(sale_id => 1234554323);

    $response = $tco->list_coupons();

    $response = $tco->detail_coupon(coupon_code => 'COUPON42');

    $response = $tco->list_payments();

    $response = $tco->list_products();

    $response = $tco->list_options();

    ...

=head1 DESCRIPTION

This module is an OO interface to the 2Checkout.com Vendor API.

This modules uses Params::Validate which likes to die() when the parameters do not pass validation, so
wrap your code in evals, etc.

Presently implements list_sales(), detail_sale(), list_coupons(), and detail_coupon(), list_payments(),
list_options(), list_products().

Return data is in XML or JSON.

Please refer to L<2Checkout's Back Office Admin API Documentation|http://www.2checkout.com/documentation/api>
for input parameters and expexted return values.

=head1 CONSTRUCTORS AND METHODS

=over 4

=item $c = VendorAPI::2Checkout::Client->new($username, $password, $format)

Contructs a new C<VendorAPI::2Checkout::Client> object to comminuncate with the 2Checkout Back Office Admin API.
You must pass your Vendor API username and password or the constructor will return undef;

=cut

sub new {
   my $class    = shift;
   my $username = shift;
   my $password = shift;
   my $accept   = shift;

   unless ( $username && $password) {
      return undef;
   }

   unless ( defined $accept && $accept =~ qr/^(?:XML|JSON)$/) {
      $accept = 'XML';
   }

   my $self = bless {}, $class;
   my $ua = LWP::UserAgent->new( agent => "VendorAPI::2Checkout::Client/${VERSION}" );
   $ua->credentials($self->SUPER::_netloc(), $self->SUPER::_realm(), $username, $password);

   $self->{ua}     = $ua;
   $self->{accept} =  $self->mime_type($accept);
   return $self;
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
   my $uri = URI->new($self->SUPER::_base_uri . '/sales/list_sales');
   my %headers = ( Accept => $self->_accept() );

   my %input_params = validate(@_, $_profile);

   foreach my $param_name ( keys %input_params ) {
      $uri->query_param($param_name => $input_params{$param_name});
   }

   $self->_ua->get($uri, %headers);
}

=item $response = $c->list_coupons();

Retrieves the list of coupons for the vendor

=cut

sub list_coupons {
   my $self = shift;
   $self->call_2co_api('/products/list_coupons');
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

   my $uri = URI->new($self->SUPER::_base_uri . '/sales/detail_sale');
   my %headers = ( Accept => $self->_accept() );

   if ($p{invoice_id} ) {
      $uri->query_param(invoice_id => $p{invoice_id});
   }
   else {
      $uri->query_param(sale_id => $p{sale_id});
   }

   $self->_ua->get($uri, %headers);
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

   my $uri = URI->new($self->SUPER::_base_uri . '/products/detail_coupon');
   my %headers = ( Accept => $self->_accept() );

   $uri->query_param(coupon_code => $p{coupon_code});

   $self->_ua->get($uri, %headers);
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
   return undef unless $api_path;
   my $uri = URI->new($self->SUPER::_base_uri . $api_path);
   my %headers = ( Accept => $self->_accept() );
   $self->_ua->get($uri, %headers);
}


#####################################################

sub _accept {
   $_[0]->{accept};
};

sub _ua {
   $_[0]->{ua};
};

=back

=head1 AUTHOR

Len Jaffe, C<< <lenjaffe at jaffesystems.com> >>

=head1 GITHUB

The source code is available at
L<Github|https://github.com/vampirechicken/VendorAPI--2Checkout--Client>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vendorapi-2checkout-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=VendorAPI-2Checkout-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VendorAPI::2Checkout::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=VendorAPI-2Checkout-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/VendorAPI-2Checkout-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/VendorAPI-2Checkout-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/VendorAPI-2Checkout-Client/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Len Jaffe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of VendorAPI::2Checkout::Client
