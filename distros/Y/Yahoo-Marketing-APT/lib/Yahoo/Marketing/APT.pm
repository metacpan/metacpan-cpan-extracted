package Yahoo::Marketing::APT;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use warnings;
use strict;
use Carp;

=head1 NAME

Yahoo::Marketing::APT - an interface for Yahoo! Search Marketing's APT Web Services.

=head1 VERSION

Version 6.01

=cut

# not using 3 part version #s,
# see http://www.perlmonks.org/?node_id=520850
our $VERSION = '6.01';

=head1 SYNOPSIS

This collection of modules makes interacting with Yahoo! Search Marketing's APT Web Services as easy as possible.

B<Note that this version (0.x) is intended to be used with V0 of the APT web services.>

Sample Usage:

    use Yahoo::Marketing::APT::Site;
    use Yahoo::Marketing::APT::SiteService;

    my $service = Yahoo::Marketing::APT::SiteService->new;

    # setup your credentials

    $service->username( 'your username' );
    $service->password( 'your password' );
    $service->license( 'your license' );
    $service->account( 'your account ID' );
    $service->endpoint( 'https://sandbox.apt.yahooapis.com/services/V6' );

    # OR

    $service->parse_config( section => 'sandbox' );


    # create a site object, and add it

    my $site = Yahoo::Marketing::APT::Site->new
                                          ->name( $site_name )
                                          ->url( 'http://my.someurl.com' )
                                          ->description( 'some description text' )
                                          ;

    my $site_response = $service->addSite( site => $site );

   # added site will have ID set

    my $added_site = $site_response->site;
    ...

=head1 VERSIONING

This version of Yahoo::Marketing::APT is intended to be used with V0 of Yahoo's Marketing API.

=head1 OVERVIEW

Yahoo! Search Marketing's APT API allows you to manage your search marketing APT account in an automated fashion rather than manually.

This Yahoo::Marketing::APT module is a set of sub-classes of Yahoo::Marketing. Therefore, Yahoo::Marketing is a prerequisite of this module. And Yahoo::Marketing::APT inherits all the features from Yahoo::Marketing. see

L<http://search.cpan.org/dist/Yahoo-Marketing/>

The calls you can make to the various services are documented on YSM's Technology Solutions Portal.  See

L<http://help.yahoo.com/l/us/yahoo/apt/webservices/index.html>

=head1 EXPORT

No exported functions

=head1 METHODS

There are no methods available in Yahoo::Marketing::APT directly.  All functionality is exposed by the various Service modules and complex types.

See perldoc Yahoo::Marketing::Service for service use

And perldoc Yahoo::Marketing::ComplexTypes for Complex Type documentation

=head1 EXAMPLES

=head2 Example Code

Please see Perl example code at Yahoo! Developer Network:

http://help.yahoo.com/l/us/yahoo/apt/webservices/sample_code/index.html

=head2 Example 1 - creating a site (from SiteService)

  my $site_service = Yahoo::Marketing::APT::SiteService->new
                                                       ->parse_config( section => 'sandbox' );
  # create a site
  my $site_response = $site_service->addSite( site =>
                          Yahoo::Marketing::APT::Site->new
                                                     ->name( 'my site' )
                                                     ->url( 'http://www.somethingaboutmysite.com' )
                      );
  my $site = $site_response->site;

  # $site now contains the newly created site.
  # $site->ID will be set to the ID assigned to the new site.


=head2 Example 2 - updating folders (from FolderService)

  my $folder_service = Yahoo::Marketing::APT::FolderService->new
                                                           ->parse_config( section => 'sandbox' );
  my @responses = $folder_service->updateFolders(
                      folders => [ Yahoo::Marketing::APT::Folder->new
                                                                ->ID( '10456' )  # ID of existing folder
                                                                ->name( 'new folder name 1' )
                                   ,
                                   Yahoo::Marketing::APT::Folder->new
                                                                ->ID( '10982' )  # ID of existing folder
                                                                ->name( 'new folder name 2' )
                                   ,
                                  ] );
  my $folder1 = $responses[0]->folder;
  my $folder2 = $responses[1]->folder;


=head2 Example 3 - submitting a request for a report (from ReportService)

  my $report_service = Yahoo::Marketing::APT::ReportService->new->parse_config( section => 'sandbox' );

  # get available reports
  my @reports = $report_service->getAvailableReports();
  foreach my $report (@reports) {
      print ("context: " . $report->context . "; name: " . $report->name . "\n");
  }

  # submit the report request, we choose one report name on Account context level.
  my $report_request = Yahoo::Marketing::APT::ReportRequest->new
                                                           ->contextID( $report_service->account )
                                                           ->reportName( 'SalesCompensation' )
                                                           ->dateRange( 'Yesterday' )
                       ;
  my $report_id = $report_service->addSavedReportRequest(
      reportRequest => $report_request,
  );

  # $report_id now contains the ID for this submitted report.


=head2 Example 4 - clearing the location cache from the command line

The following code will clear the location cache from the command line on a *nix machine.

  perl -MYahoo::Marketing::APT::Service -e 'my $ysm_ws = Yahoo::Marketing::APT::Service->new->clear_cache;'

On windows, using double quotes instead of single quotes should work.

=head2 Example Config File

Config files are expected to be in YAML format.  See perldoc YAML.

default_account is optional.  If present, it will be set when a config file
is loaded B<only if an account has not already been set!>

Please note: masterAccountID is not required in Yahoo APT Web Services Request SOAP header,
so master_account entry is optional for config file in Yahoo::Marketing::APT.

 ---
 default:
   default_account: 12345678
   endpoint: https://endpoint.host/services
   license: your-ews-license
   password: secretpassword
   uri: http://apt.yahooapis.com/V6
   username: defaultusername
   version: V6
 sandbox:
   default_account: 21921327
   endpoint: https://sandbox.apt.yahooapis.com/services
   license: 90837ada-3b26-c2e5-6d59-61d7f2fb578e
   password: mypassword
   uri: http://apt.yahooapis.com/V6
   username: mytestusername
   version: V6


=head1 DEBUGGING

If you'd like to see the SOAP requests and responses, or other debugging information available from SOAP::Lite, you can turn
it on just as you would for SOAP::Lite.  See perldoc SOAP::Trace.  As an example, if you wanted to see all trace information
available, you could add the following to whatever module or script you use Yahoo::Marketing in:

 use SOAP::Lite +trace;



=head1 AUTHOR

Johnny Shen C<< <nycperl at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-yahoo-marketing-apt at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Yahoo-Marketing-APT>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yahoo::Marketing::APT

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Yahoo-Marketing-APT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Yahoo-Marketing-APT>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Yahoo-Marketing-APT>

=item * Search CPAN

L<http://search.cpan.org/dist/Yahoo-Marketing-APT>

=back

=head1 ACKNOWLEDGEMENTS

Thanks Jeff Lavallee, C<< <jeff at zeroclue.com> >>, the author of Yahoo::Marketing. Without his great work for Yahoo::Marketing, these APT sub modules won't have been possible.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008 Yahoo! Inc.  All rights reserved.
The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)


=cut


1; # End of Yahoo::Marketing::APT

