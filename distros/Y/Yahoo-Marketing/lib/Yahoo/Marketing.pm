package Yahoo::Marketing;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use warnings;
use strict;
use Carp;

=head1 NAME

Yahoo::Marketing - an interface for Yahoo! Search Marketing's Web Services.

=head1 VERSION

Version 7.03

=cut

# not using 3 part version #s, 
# see http://www.perlmonks.org/?node_id=520850
our $VERSION = '7.03';


=head1 SYNOPSIS

This collection of modules makes interacting with Yahoo! Search Marketing's Web Services as easy as possible.

B<Note that this version (6.x) is intended to be used with V7 of the marketing web services.>

Sample Usage:

    use Yahoo::Marketing::Keyword;
    use Yahoo::Marketing::KeywordService;

    my $service = Yahoo::Marketing::KeywordService->new;

    # setup your credentials

    $service->username( 'your username' )
            ->password( 'your password' )
            ->license( 'your license' )
            ->master_account( 'your master account ID' )
            ->account( 'your account ID' )
            ->endpoint( 'https://sandbox.marketing.ews.yahooapis.com/services' );

    # OR

    $service->parse_config( section => 'sandbox' );


    # create a keyword object, and add it

    my $keyword = Yahoo::Marketing::Keyword->new
                                           ->adGroupID( $ad_group_id )
                                           ->text( 'some text' )
                                           ->alternateText( 'some alternate text' )
                                           ->sponsoredSearchMaxBid( 1.00 )
                                           ->status( 'On' )
                                           ->advancedMatchON( 'true' )
                                           ->url( 'http://www.someurl.com' )
                  ;

    my $keyword_response = $service->addKeyword( keyword => $keyword );

    # added keyword will have ID set 

    my $added_keyword = $keyword_response->keyword;
    ...

=head1 VERSIONING

This version of Yahoo::Marketing is intended to be used with V7 of Yahoo's Marketing API.  If you need to access both V4 and V6 simultaneously, you'll need to install 2 versions of Yahoo::Marketing.  In order to have 2 versions of the same perl module installed, you'll need to put one in a non-standard location, for example ~/perl/.  See perldoc CPAN for more information.

=head1 OVERVIEW

Yahoo's Marketing API allows you to manage your search marketing account in an automated fashion rather than manually.  The API is exposed as a standard SOAP service that you can make calls to.  This set of modules is designed to make using the SOAP service easier than using SOAP::Lite (for example) directly.  There are 2 main types of modules available.  The service modules (CampaignService, AdGroupService, BidInformationService, etc) are used to make the actual calls to each of the SOAP services in the API.  The other type of module provided are the complex type modules, each of which represents one of the complex types defined in one of the WSDLs of the SOAP service.  Examples include Campaign, AdGroup, Ad, PendingAd, CreditCardInfo, etc.

Yahoo::Marketing will call LocationService for you, and cache the results.  This should be completely transparent.  See the documtation for cache, cache_expire_time, purge_cache and clear_cache in Yahoo::Marketing::Service for more details.

The calls you can make to the various services are documented on YSM's Technology Solutions Portal.  See

L<http://searchmarketing.yahoo.com/developer/docs/index.php>

Where the documentation indicates that a complex type must be passed in to a particular service call, you must pass in the appropriate 
Yahoo::Marketing::ComplexType object.  For example, CampaignService->addCampaign requires that a Campaign be passed in:

 use Yahoo::Marketing::Campaign;
 use Yahoo::Marketing::CampaignService;

 my $campaign          = Yahoo::Marketing::Campaign->new
                                                   ->startDate( '2006-07-16T09:20:30-05:00' )
                                                   ->endDate( '2007-07-16T09:20:30-05:00' )
                                                   ->name( 'test campaign' )
                                                   ->status( 'On' )
                                                   ->accountID( 123456789 )
                         ;
 
 my $campaign_service  =  Yahoo::Marketing::CampaignService->new;

 my $campaign_response = $campaign_service->addCampaign( campaign => $campaign );

 my $added_campaign    = $campaign_response->campaign;

Note that Yahoo::Marketing is smart enough to upgrade status from a simple string to the CampaignStatus simpleType for you.  All simpleTypes referenced in the WSDLs are automatically handled for you - just pass in an appropriate string, and let Yahoo::Marketing do the rest.

When a method expects that multiple values will be set for a parameter, you must pass an anonymous array.  An example would be AdGroupService->deleteAdGroups:

 my $ad_group_service = Yahoo::Marketing::AdGroupService->new;

 $ad_group_service->deleteAdGroups( adGroupIDs => [ '9167298', '2932719', '1827349' ] );   # existing Ad Group IDs


If a call returns data, you will receive an array if you make the call in an array context:

 my @ad_groups = $ad_group_service->getAdGroups(
                                        adGroupIDs => [ '9167298', '2932719', '1827349'],
                                    );

Or just the first (or only element, if only one returned object is expected) if you make the call in a scalar context:

 my $ad_group = $ad_group_service->getAdGroups(
                                       adGroupIDs => [ '9167298', '2932719', '1827349'],
                                   );
 # $ad_group is just the first ad group returned (likely Ad Group ID 9167298)

Suggestions for improving how multiple return values should be handled in a scalar context are welcome.

If a SOAP Fault is encountered (whenever a call fails), the Yahoo::Marketing service will croak with the fault by default.  If you set the immortal option, Yahoo::Marketing will not die, $service->fault will be set to the SOAP fault.  The "immortal mode" is similar to how SOAP::Lite behaves by default.

Note that all get/set methods (and many other methods) are "chainable".  That is, they return $self when used to set, so you can chain them together.  See examples of this above and below in this documentation.


=head1 EXPORT

No exported functions

=head1 METHODS

There are no methods available in Yahoo::Marketing directly.  All functionality is exposed by the various Service modules and complex types.

See perldoc Yahoo::Marketing::Service for service use

And perldoc Yahoo::Marketing::ComplexTypes for Complex Type documentation

=head1 EXAMPLES

=head2 Example Code

See t/example.t for an example that parallels the perl example code at 

L<http://searchmarketing.yahoo.com/developer/docs/V7/sample_code/perl.php>

and

L<http://searchmarketing.yahoo.com/developer/docs/V7/sample_code/perlsdk.php>

=head2 Example 1 - creating a campaign
 
 my $campaign_service  = Yahoo::Marketing::CampaignService->new
                                                          ->parse_config( section => 'sandbox' );
 
 # Create a Campaign
 my $campaign_response = $campaign_service->addCampaign( campaign => 
                             Yahoo::Marketing::Campaign->new
                                                       ->name( 'MP3' )
                                                       ->description( 'MP3 Player' )
                                                       ->accountID( $campaign_service->account )
                                                       ->status( 'On' )
                                                       ->sponsoredSearchON( 'true' )
                                                       ->advancedMatchON( 'true' )
                                                       ->contentMatchON( 'true' )
                                                       ->campaignOptimizationON( 'false' )
                                                       ->startDate( '2006-06-07T19:32:37-05:00' )
                                                       ->endDate( '2007-07-08T07:32:37-05:00' )
                         );

  my $campaign         = $campaign_response->campaign;

  # $campaign now contains the newly created campaign.
  # $campaign->ID will be set to the ID assigned to the new campaign.

=head2 Example 2 - updating Ads

 my $ad_service = Yahoo::Marketing::AdService->new
                                             ->parse_config;

 $ad_service->updateAds( ads       => [ Yahoo::Marketing::Ad->new
                                                            ->ID( '12427153' )   # id of existing ad
                                                            ->name( 'better than the old name' )
                                                            ->status( 'Off' )
                                        ,
                                        Yahoo::Marketing::Ad->new
                                                            ->ID( '32482170' )   # id of existing ad
                                                            ->displayUrl( 'http://new.display.url/' )
                                                            ->url( 'http://new.url' )
                                                            ->description( 'a fancy new description' )
                                        ,
                                      ],      # end of our array of ads
                         updateAll => 'false',
                       ); 

  # Note that we passed an anonymous array for the ads parameter.
  # Also note that only the fields that were being updated needed to be
  #   set, in addition to the ID field.

=head2 Example 3 - getting forecast information

 my $forecast_service = Yahoo::Marketing::ForecastService->new->parse_config;

 my $forecast_request_data 
     = Yahoo::Marketing::ForecastRequestData->new
                                            ->accountID( $forecast_service->account )    # default_account from config file, set in parse_config call
                                            ->contentMatchMaxBid( '0.88' )
                                            ->marketID( 'US' )
                                            ->matchTypes( [qw(advanced_match content_match sponsored_search )] )
                                            ->sponsoredSearchMaxBid( '0.99' );

 my $result = $forecast_service->getForecastForKeyword(
                                     keyword             => 'porsche',
                                     adGroupID           => 116439261,           # some existing Ad Group ID
                                     forecastRequestData => $forecast_request_data,
                                 );

 my $forecast_response_detail = $result->forecastResponseDetail;

 print "Number of forecast impressions: "
      .$forecast_response_detail->impressions
      ."\n" 
 ;
 print "Number of forecast average position: "
      .$forecast_response_detail->averagePosition
      ."\n"
 ; 
 my $forecast_landscapes = $result->forecastLandscape;

 foreach my $forecast ( @$forecast_landscapes ){
     print "cost per click: "
          .$forecast->costPerClick
          ."\n"
     ;
 }

=head2 Example 4 - using BidInformationService

 my $bid_info_service  = Yahoo::Marketing::BidInformationService->new->parse_config;

 my $bid_information = $bid_info_service->getBidsForBestRank(
                                              adGroupID => '90171822',   # existing Ad Group ID
                                              keyword   => 'porsche',
                                          );

 print "Bid: "
      .$bid_information->bid
      ."\n"
 ;
 print "Cut Off Bid: "
      .$bid_information->cutOffBid
      ."\n"
 ;
 
=head2 Example 5 - clearing the location cache from the command line

The following code will clear the location cache from the command line on a *nix machine.  

  perl -MYahoo::Marketing::Service -e 'my $ysm_ws = Yahoo::Marketing::Service->new->clear_cache;'

On windows, using double quotes instead of single quotes should work.
 
=head2 Example Config File

Config files are expected to be in YAML format.  See perldoc YAML.

default_account is optional.  If present, it will be set when a config file
is loaded B<only if an account has not already been set!>

 ---
 default:
   default_account: 12345678
   endpoint: https://endpoint.host/services
   vault_endpoint: https://vault.endpoint.host/services
   license: your-ews-license
   master_account: 98765432
   password: secretpassword
   uri: http://marketing.ews.yahooapis.com/V7
   username: defaultusername
   version: V7
 sandbox:
   default_account: 21921327 
   endpoint: https://sandbox.marketing.ews.yahooapis.com/services
   vault_endpoint: https://sandboxvault.marketing.ews.yahooapis.com/services
   license: 90837ada-3b26-c2e5-6d59-61d7f2fb578e
   master_account: 21921326 
   password: mypassword
   uri: http://marketing.ews.yahooapis.com/V7
   username: mytestusername
   version: V7


=head1 DEBUGGING

If you'd like to see the SOAP requests and responses, or other debugging information available from SOAP::Lite, you can turn it on just as you would for SOAP::Lite.  See perldoc SOAP::Trace.  As an example, if you wanted to see all trace information available, you could add the following to whatever module or script you use Yahoo::Marketing in:

 use SOAP::Lite +trace;




=head1 AUTHOR

Jeff Lavallee, C<< <jeff at zeroclue.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-yahoo-marketing at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Yahoo-Marketing>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yahoo::Marketing

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Yahoo-Marketing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Yahoo-Marketing>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Yahoo-Marketing>

=item * Search CPAN

L<http://search.cpan.org/dist/Yahoo-Marketing>

=back

=head1 ACKNOWLEDGEMENTS

co-author Johnny Shen, C<< <shenj at yahoo-inc.com> >> without whom this wouldn't have been possible.
Also Gerard Paulke C<< <paulkeg at yahoo-inc.com> >>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

=head1 TODO

The TODO list is empty - if you have suggestions, please file a wishlist entry in RT (link above)

=cut

sub new {
    my ( $class, %args ) = @_;
    croak "cannot instantiate @{[ __PACKAGE__ ]} directly" 
        unless $class ne __PACKAGE__;

    my $self = bless %args, $class;
    return $self;
}



1; # End of Yahoo::Marketing

