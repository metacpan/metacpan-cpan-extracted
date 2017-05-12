package TextLinkAds;

use strict;
use warnings;

use Carp qw( carp croak );

our $VERSION = '0.01';


=head1 NAME

TextLinkAds - Retrieve Text Link Ads advertiser data


=head1 SYNOPSIS

    use TextLinkAds;
    
    my $tla = TextLinkAds->new;
    
    # Fetch link information from text-link-ads.com...
    my @links = @{ $tla->fetch( $inventory_key ) };
    
    # Output the data in some meaningful way...
    print "<ul>\n";
    foreach my $link ( @links ) {
        my $before = $link->{BeforeText} || '';
        my $after  = $link->{AfterText}  || '';

        print <<"END_OF_HTML";
        <li>
            $before <a href="$link->{URL}">$link->{Text}</a> $after
        </li>
    END_OF_HTML
    }
    print '</ul>';


=head1 DESCRIPTION

This module fetches advertiser information for a given Text Link Ads publisher
account.

See L<http://www.text-link-ads.com/publisher_program.php?ref=23206>.


=head1 METHODS

=head2 ->new( \%options )

Instantiate a new TextLinkAds object.

=head3 %options

=over

=item cache

Optional. By default this module will try to use L<Cache::FileCache> to store
data retrieved from the text-link-ads.com site for one hour. You may use the
C<cache> parameter to provide an alternative object that implements the
L<Cache::Cache> interface. To disable caching set C<cache> to a scalar value
that resolves to C<false>.

=item tmpdir

Optional. A temporary directory to use when caching data. The default
behaviour is to use the directory determined by
L<File::Spec-E<gt>tmpdir|File::Spec/tmpdir>.

=back

=cut


sub new {
    my ( $class, $args ) = @_;
    
    my $self = bless {}, $class;
    
    # Where the tmpdir isn't defined or valid, use File::Spec to determine an
    # appropriate directory...
    my $tmpdir = $args->{tmpdir};
    unless ( defined $tmpdir && -d $tmpdir && -w $tmpdir ) {
        require File::Spec;
        $tmpdir = File::Spec->tmpdir;
    }
    $self->{tmpdir} = $tmpdir;
    
    
    # Where cache is not defined, or is a scalar with a true value, fall back
    # to using Cache::FileCache (providing it is installed)...
    my $cache = $args->{cache};
    if ( !defined $cache || ( !ref $cache && $cache ) ) {
        eval { require Cache::FileCache; };
        unless ( $@ ) {
            $cache = Cache::FileCache->new({
                cache_root         => $tmpdir,
                default_expires_in => '1 hour',
            });
        
            $self->{cache} = $cache;
        }
    }
    
    
    return $self;
}


=head2 ->fetch( $inventory_key, \%options )

Fetch advertiser information for the given key. It will first attempt to get
the data from the cache where available, and failing that will send a request
to text-link-ads.com, using the *_proxy environment variables and  the
If-Modified_Since request header.


=head3 $inventory_key

Required. The XML Key for the desired site as provided by Text Link Ads.

=head3 %options

=over

=item user_agent

Optional. In the vanilla code examples provided by Text Link Ads, both the
user agent and referer CGI environment variables are included in the URI used
to retrieve the XML data. While the link appears to function without them, it
would probably be polite to include them where possible.

=item referer

See above.

=back


=cut


sub fetch {
    my ( $self, $inventory_key, $args ) = @_;
    
    # First, attempt to retrieve the data from the cache where available...
    my $links;
    if ( defined $self->{cache} ) {
        $links = $self->{cache}->get( "tla_$inventory_key" );
        
        return $links if defined $links;
    }
    
    # Otherwise, we'll need to retrieve the data from text-link-ads.com, so
    # create a new user agent object...
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new(
        agent => "TextLinkAds.pm/$VERSION " . LWP::UserAgent->_agent,
    );
    $ua->env_proxy;  # obey the *_proxy environment variables
    
    
    # Determine the URI to use when requesting the advertiser data...
    my $referer    = $self->{referer};
    my $user_agent = $self->{user_agent};
    
    my $uri = 'http://www.text-link-ads.com/xml.php'
            . "?inventory_key=$inventory_key"
            . ( defined $referer    ? "&referer=$referer"       : '' )
            . ( defined $user_agent ? "&user_agent=$user_agent" : '' );
    
    
    # Request the advertiser data, using "If-Modified-Since" where possible...
    my $temp_file = $self->{tmpdir} . "/tla_$inventory_key";
    my $response  = $ua->mirror( $uri, $temp_file );
    
    if ( !$response->is_success ) {
        croak $response->status_line;
    }
    
    # The resulting file was empty. This may mean there were no advertisers,
    # though it's also possible that an incorrect $inventory_key was given...
    if ( -z $temp_file ) {
        carp "No advertisers found for '$inventory_key'";
        return [];
    }
    
    # Parse the XML...
    require XML::Simple;
    $links = XML::Simple::XMLin($temp_file)->{Link};
    
    
    # Remove empty BeforeText/AfterText attributes...
    foreach my $link ( @$links ) {
        delete $link->{BeforeText} if ref $link->{BeforeText};
        delete $link->{AfterText}  if ref $link->{AfterText};
    }
    
    
    # Store the new data if caching is enabled...
    $self->{cache}->set( "tla_$inventory_key", $links )
        if defined $self->{cache};
    
    return $links;
}



1;  # End of the module code; everything from here is documentation...
__END__

=head1 DEPENDENCIES

TextLinkAds requires the following modules:

=over

=item

L<Carp>

=item

L<File::Spec>

=item

L<LWP::UserAgent>

=item

L<XML::Simple>

=back

TextLinkAds recommends the following modules:

=over

=item

L<Cache::FileCache>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-textlinkads at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TextLinkAds>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TextLinkAds

You may also look for information at:

=over 4

=item * TextLinkAds

L<http://perlprogrammer.co.uk/modules/TextLinkAds/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TextLinkAds/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TextLinkAds>

=item * Search CPAN

L<http://search.cpan.org/dist/TextLinkAds/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut
