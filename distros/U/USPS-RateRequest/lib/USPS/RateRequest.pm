package USPS::RateRequest;
$USPS::RateRequest::VERSION = '1.0004';
use strict;
use Moose;
use XML::DOM;
use AnyEvent::HTTP::LWP::UserAgent;
use AnyEvent;
use Ouch;
use POSIX qw(ceil);
use XML::Simple;
use 5.010;

=head1 NAME

USPS::RateRequest - Ultra fast parallelized asyncronous USPS rate lookups.

=head1 VERSION

version 1.0004

=head1 SYNOPSIS

 use USPS::RateRequest;
 use Box::Calc;
 use Ouch;

 my $calc = Box::Calc->new();
 $calc->add_box_type(...);
 $calc->add_item(...);
 $calc->pack_items;

 my $rates = eval {
    USPS::RateRequest->new(
        user_id     => 'usps username'
        password    => 'usps password',
        from        => 53716,
        postal_code => 90210,
        country     => 'US',
     )->request_rates($calc->boxes)->recv;
 };

 if (hug) {
    die "USPS Error: $@";
 }

 my $priority_postage_for_first_box = $rates->{$calc->get_box(0)->id}{'USPS Priority'}{postage};

 # view the complete data structure
 use Data::Dumper;
 say Dumper($rates);

=head1 DESCRIPTION

USPS::RateRequest exists for two reasons:

=over

=item *

L<Business::Shipping> is very slow when you have to request rates for varying amounts and sizes of parcels. That's because each request is done in serial. USPS::RateRequest makes all requests in parallel, thus increasing performance dramatically.

=item *

L<Box::Calc> does a ton of work figuring out exactly what can be packed into each parcel. USPS::RateRequest takes advantage of all that data being loaded and makes use of it to calculate very precise package dimensions and weights to get the most accurate shipping prices.

=back

If there are errors returned from the USPS, USPS::RateRequest will throw exceptions via L<Ouch> with the code "USPS Error" and the error returned from the USPS.  If no rates are returned at all, then it will throw an exception with the code "No Rates".

=head1 METHODS

=head2 new( params )

Constructor.

=over

=item params

A hash of initialization parameters.  An asterisk denotes required parameters.

=over 

=item test_mode

Boolean. If true requests will be posted to the USPS test server rather than the production server.

=item prod_uri

The URI to the production instance of the USPS web tools web services. Defaults to C<http://production.shippingapis.com/ShippingAPI.dll>.

=item test_uri

The URI to the test instance of the USPS web tools web services. Defaults to C<http://testing.shippingapis.com/ShippingAPItest.dll>.

=item user_id (*)

The username provided to you by signing up for USPS web tools here: L<https://www.usps.com/business/web-tools-apis/welcome.htm>

=item password (*)

The password that goes with C<user_id>.

=item from (*)

The zip code from which the parcels will ship.

=item postal_code (*)

The postal_code code where the parcels will be delivered.

=item country (*)

The name of the country where the parcels will be delivered.  See the USPS web services documentation
for a list of valid countries. L<https://www.usps.com/business/web-tools-apis/price-calculators.htm>
The proper name for the USA is "United States of America".

=item service

Defaults to C<all>. Optionally limit the response to specific delivery services, such as C<PRIORITY>. See the USPS web service documentation for details: L<https://www.usps.com/business/web-tools-apis/price-calculators.htm>

=item debug

Add additional items into the returned rate request data for debugging issues with rate lookups and name sanitization.  This data is not guaranteed to stay the same from release to release.

=back

=back

=cut

has 'test_mode' => (
    is          => 'rw',
    default     => 0,
);

has prod_uri => (
    is          => 'rw',
    default     => 'http://production.shippingapis.com/ShippingAPI.dll'
);

has test_uri => (
    is          => 'rw',
    default     => 'http://testing.shippingapis.com/ShippingAPItest.dll',
);

has user_id => (
    is          => 'ro',
    required    => 1,
);

has password => (
    is          => 'ro',
    required    => 1,
);

has from => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
);

has postal_code => (
    is          => 'rw',
    required    => 1,
);

has country => (
    is          => 'rw',
    required    => 1,
);

has service => (
    is          => 'rw',
    default     => 'all',
);

has debug => (
    is          => 'rw',
    default     => 0,
    isa         => 'Int',
);

__PACKAGE__->meta()->make_immutable();


# this sub is almost a verbatim copy from Business::Shipping

sub _generate_request_xml {
    my ($self, $boxes) = @_;
    my $rate_request_document = XML::DOM::Document->new();
    my $rate_request_element  = $rate_request_document->createElement(
        $self->domestic() ? 'RateV4Request' : 'IntlRateV2Request');

    # Note that these are required even for test mode transactions.
    $rate_request_element->setAttribute('USERID',   $self->user_id);
    $rate_request_element->setAttribute('PASSWORD', $self->password);
    $rate_request_document->appendChild($rate_request_element);

# needed for special services    
    my $revision_element = $rate_request_document->createElement('Revision');
    $revision_element->appendChild($rate_request_document->createTextNode(2));
    $rate_request_element->appendChild($revision_element);

    foreach my $box (@{ $boxes }) {
        my $package_element = $rate_request_document->createElement('Package');
        $package_element->setAttribute('ID', $box->id);
        $rate_request_element->appendChild($package_element);

        if ($self->domestic) {
            my $service_element = $rate_request_document->createElement('Service');
            $service_element->appendChild($rate_request_document->createTextNode($self->service)); 
            $package_element->appendChild($service_element);

            my $zip_origin_element = $rate_request_document->createElement('ZipOrigination');
            $zip_origin_element->appendChild($rate_request_document->createTextNode($self->from));
            $package_element->appendChild($zip_origin_element);

            my $zip_destination_element = $rate_request_document->createElement('ZipDestination');
            ##USPS only supports ZIP, not ZIP+4 formats
            my $zip = $self->postal_code;
            $zip =~ s/(\d{5})-\d{4}/$1/;
            $zip_destination_element->appendChild($rate_request_document->createTextNode($zip));
            $package_element->appendChild($zip_destination_element);
        }

        my $weight = $box->calculate_weight;
        my $pounds = int($weight / 16);
        my $ounces = $weight % 16;

        my $pounds_element = $rate_request_document->createElement('Pounds');
        $pounds_element->appendChild($rate_request_document->createTextNode($pounds));
        $package_element->appendChild($pounds_element);

        my $ounces_element = $rate_request_document->createElement('Ounces');
        $ounces_element->appendChild($rate_request_document->createTextNode($ounces));
        $package_element->appendChild($ounces_element);

        unless ($self->domestic) {
            my $mail_type_element = $rate_request_document->createElement('MailType');
            $mail_type_element->appendChild($rate_request_document->createTextNode($box->mail_type));
            $package_element->appendChild($mail_type_element);
            
            my $gxg_element = $rate_request_document->createElement('GXG');
            my $pobox_flag_element = $rate_request_document->createElement('POBoxFlag');
            $pobox_flag_element->appendChild($rate_request_document->createTextNode($box->mail_pobox_flag));
            $gxg_element->appendChild($pobox_flag_element);
            my $gift_flag_element = $rate_request_document->createElement('GiftFlag');
            $gift_flag_element->appendChild($rate_request_document->createTextNode($box->mail_gift_flag));
            $gxg_element->appendChild($gift_flag_element);
            $package_element->appendChild($gxg_element);
            
            my $value_of_contents_element = $rate_request_document->createElement('ValueOfContents');
            $value_of_contents_element->appendChild($rate_request_document->createTextNode($box->value_of_contents));
            $package_element->appendChild($value_of_contents_element);            

            my $country_element = $rate_request_document->createElement('Country');
            $country_element->appendChild($rate_request_document->createTextNode($self->country));
            $package_element->appendChild($country_element);            

        }
        
        my $container_element = $rate_request_document->createElement('Container');
        $container_element->appendChild($rate_request_document->createTextNode($self->domestic ? $box->mail_container : 'RECTANGULAR'));
        $package_element->appendChild($container_element);

        my $oversize_element   = $rate_request_document->createElement('Size');
        $oversize_element->appendChild($rate_request_document->createTextNode($box->mail_size));
        $package_element->appendChild($oversize_element);

        my $width_element   = $rate_request_document->createElement('Width');
        $width_element->appendChild($rate_request_document->createTextNode($box->y));
        $package_element->appendChild($width_element);

        my $length_element   = $rate_request_document->createElement('Length');
        $length_element->appendChild($rate_request_document->createTextNode($box->x));
        $package_element->appendChild($length_element);

        my $height_element   = $rate_request_document->createElement('Height');
        $height_element->appendChild($rate_request_document->createTextNode($box->z));
        $package_element->appendChild($height_element);

        my $girth_element   = $rate_request_document->createElement('Girth');
        $girth_element->appendChild($rate_request_document->createTextNode($box->girth));
        $package_element->appendChild($girth_element);

            if ($self->country eq 'Canada') {
                my $origin_zip = $rate_request_document->createElement('OriginZip');
                $origin_zip->appendChild($rate_request_document->createTextNode($self->from));
                $package_element->appendChild($origin_zip);            
            }

        if ($self->domestic) {
            if ($self->service =~ /all/i and not defined $box->mail_machinable()) {
                $box->mail_machinable('False');
            }

    # trying to get special services working
            #my $special_services_element = $rate_request_document->createElement('SpecialServices');
            #my $insurance_element = $rate_request_document->createElement('SpecialService');
            #$insurance_element->appendChild($rate_request_document->createTextNode(1));
            #$special_services_element->appendChild($insurance_element);
            #$package_element->appendChild($special_services_element);

            if (defined $box->mail_machinable) {
                my $machine_element = $rate_request_document->createElement('Machinable');
                $machine_element->appendChild($rate_request_document->createTextNode($box->mail_machinable));
                $package_element->appendChild($machine_element);
            }
        }
        

    }
    return $rate_request_document->toString();
}

sub _generate_requests {
    my ($self, $boxes) = @_;
    my @requests = ();
    my @boxes = @{ $boxes };
    my $limit = 20; # the USPS service craps out if the XML document is too big, most likely due to it being URL encoded, rather than a post body
    my $pages = ceil( scalar(@boxes) / $limit );
    for (1..$pages) {
        my @temp = ();
        my $temp_limit = scalar @boxes;
        $temp_limit = $limit if $limit < $temp_limit;
        for (1..$temp_limit) {
            push @temp, shift @boxes;
        }
        push @requests, $self->_generate_request_xml(\@temp);
    }
    return \@requests;
}

sub _generate_uri {
    my $self = shift;
    return $self->test_mode ? $self->test_uri : $self->prod_uri;
}

=head2 request_rates ( boxes )

Returns an L<AnyEvent> condition variable. When you call the C<recv> method on that variable it will send out all the requests for rates, collate and translate the responses, and return a hash reference that looks like this:

 {
        'box-id-1' => {
                        'USPS Priority Small Flat Rate Box' => {
                                                               'postage' => '5.80'
                                                             },
                        'USPS Priority Express Hold For Pickup' => {
                                                                   'postage' => '56.05'
                                                                 },
                        'USPS Priority Express Flat Rate Envelope' => {
                                                                      'postage' => '19.99'
                                                                    },
                        'USPS Priority Medium Flat Rate Box' => {
                                                                'postage' => '12.35'
                                                              },
                        'USPS Standard Post' => {
                                                'postage' => '13.34'
                                              },
                        'USPS Media' => {
                                        'postage' => '4.61'
                                      },
                        [....]
        },
        'box-id-2' => {
                        [....]
        },
        [....]

 }

=over

=item boxes

An array reference of boxes created by C<Box::Calc>.

=back

=cut

sub request_rates {
    my ($self, $boxes) = @_;
    my @responses = ();
    my $cv = AnyEvent->condvar;
    $cv->begin(sub { shift->send($self->_handle_responses(\@responses)) });
    foreach my $request_xml (@{$self->_generate_requests($boxes)}) {
        if ($self->debug) {
            say $request_xml;
        }
        $cv->begin;
        my $content = 'API=' . ($self->domestic ? 'RateV4' : 'IntlRateV2') . '&XML=' . $request_xml;
        my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->post_async($self->_generate_uri,
            Content_Type        => 'application/x-www-form-urlencoded',
            'content-length'    => CORE::length($request_xml),
            Content             => $content,
            )->cb(sub {
                push @responses, shift->recv;
                $cv->end;
            });
    }
    $cv->end;
    return $cv;
}

sub _handle_responses {
    my ($self, $responses) = @_;
    my %rates = ();
    foreach my $response (@{$responses}) {
        $self->_handle_response($response, \%rates);
    }
    unless (scalar keys %rates) {
        ouch 'No Rates', 'No rates were returned for your packages.';
    }
    return \%rates;
}

sub _handle_response {
    my ($self, $response, $rates) = @_;

    unless (ref $response eq 'HTTP::Response') {
        ouch 500, $response;
    }

    if ($self->debug) {
        say $response->decoded_content;
    }

    ### Keep the root element, because USPS might return an error and 'Error' will be the root element
    my $response_tree = XML::Simple::XMLin(
        $response->decoded_content,
        ForceArray => 0,
        KeepRoot   => 1
    );
    
    ### Discard the root element on success
    $response_tree = $response_tree->{RateV4Response} if (exists($response_tree->{RateV4Response}));
    $response_tree = $response_tree->{IntlRateV2Response} if (exists($response_tree->{IntlRateV2Response}));

    # Handle errors
    ### Get all errors
    my $errors = [];
    push(@$errors, $response_tree->{Error}) if (exists($response_tree->{Error}));
    if (ref $response_tree->{Package} eq 'HASH') {
        if (exists($response_tree->{Package}{Error})) {
            push(@$errors, $response_tree->{Package}{Error});
            $errors->[$#{$errors}]{PackageID} = $response_tree->{Package}{ID};
        }
    }
    elsif (ref $response_tree->{Package} eq 'ARRAY') {
        foreach my $pkg (@{ $response_tree->{Package} }) {
            if (exists($pkg->{Error})) {
                push(@$errors, $pkg->{Error});
                $errors->[$#{$errors}]{PackageID} = $pkg->{ID};
            }
        }
    }
    
    # throw an exception if there are errors
    if (@$errors > 0) {
        ouch 'USPS Error', $errors->[0]{Description}, $errors;
    } 
        
    # normalize rates for domestic and international
    my $packages = ref $response_tree->{Package} eq 'ARRAY' ?  $response_tree->{Package} : [$response_tree->{Package}];
    if ($self->domestic) {
        foreach my $package (@{$packages}) {
            my %services = ();
            foreach my $service (@{$package->{Postage}}) {
                my $service_name = $self->sanitize_service_name($service->{MailService});
                $services{$service_name} = {
                    postage     => $service->{Rate},
                };
                if ($self->debug) {
                    $services{$service_name}->{label} = $service->{MailService};
                }
            }
            $rates->{$package->{ID}} = \%services;
        }
    }
    else {
        foreach my $package (@{$packages}) {
            my %services = ();
            foreach my $service (@{$package->{Service}}) {
                my $service_name = $self->sanitize_service_name($service->{SvcDescription});
                $services{$service_name} = {
                    postage     => $service->{Postage},
                };
                if ($self->debug) {
                    $services{$service_name}->{label} = $service->{SvcDescription};
                }
            }
            $rates->{$package->{ID}} = \%services;
        }
    }
}

=head2 sanitize_service_name ( name )

=cut

sub sanitize_service_name {
    my ($class, $name) = @_;    
    my $remove_tm  = quotemeta('&lt;sup&gt;&amp;trade;&lt;/sup&gt;');
    my $remove_gxg = quotemeta(' (GXG)');
    $name =~ s/\*//g;
    $name =~ s{&lt;sup&gt;&(?:amp;reg|amp;trade|#174|#8482);&lt;/sup&gt;}{}gi;
    $name =~ s/$remove_gxg//gi;
    $name =~ s/GXG/Global Express Guaranteed/gi;
    $name =~ s/ Mail//gi;
    $name =~ s/ \d-Day//gi;
    $name =~ s/ APO\/FPO\/DPO//gi;
    $name =~ s/ APO//gi;
    $name =~ s/ DPO//gi;
    $name =~ s/ FPO//gi;
    $name =~ s/ Military//gi;
    $name =~ s/ International//gi;
    $name =~ s/USPS //gi;
    $name =~ s/Envelopes/Envelope/gi;
    $name =~ s/Boxes/Box/gi;
    $name =~ s/priced box/Box/gi;
    return 'USPS '.$name;
}

=head2 domestic ( )

Returns a 1 or 0 depending upon whether the C<country> is 'United States of America'.

=cut

sub domestic {
    my $self = shift;
    return $self->country eq 'United States of America' ? 1 : 0;
}

=head1 CAVEATS

Although Box::Calc doesn't care what units you use for weights and measurements, USPS does. Make sure all your weights are in ounces and all your measurements are in inches.

=head1 AUTHOR

=over

=item JT Smith <jt_at_plainblack_dot_com>

=back

=head1 LEGAL

Box::Calc is Copyright 2014 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.


=cut

1;
