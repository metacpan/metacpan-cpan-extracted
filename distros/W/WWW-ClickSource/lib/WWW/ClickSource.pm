package WWW::ClickSource;

use strict;
use warnings;

use 5.010;

use URI;
use WWW::ClickSource::Request;

use base 'Exporter';

our $VERSION = 0.8;

our @EXPORT_OK = ('detect_source');

=head1 NAME

WWW::ClickSource - Determine the source of a visit on your website : organic, adwords, facebook, referer site

=head1 VERSION

Version 0.6

=head1 DESCRIPTION

Help determine the source of the traffic on your website.

This module tries to do what GoogleAnalytics, Piwik and other monitoring tools do, but it's something you can
use on the backend of your application in real time.

This module can be used together with L<HTTP::BrowserDetect> to get an even deeper understanding of where your 
traffic is generated from.

=head1 SYNOPSIS

Can be used in one of two ways 

OOP interface :

    use WWW::ClickSource;
    
    my $click_source = WWW::ClickSource->new($request);

    my $source = $click_source->source();
    my $medium = $click_source->medium();
    my $campaign = $click_source->campaign();
    my $category = $click_source->category();

or using Export

    use WWW::ClickSource qw/detect_click_source/;

    my %click_info = detect_click_source($request);

The C<$request> argument is one of L<Catalyst::Request> object or a hash ref with the fallowing structure:

    {
        host => 'mydomain.com',
        params => {
            param_1 => 'value_1',
            ...
            param_n => 'value_n',
        },
        referer => 'http://referer-website.com/some_link.html?param1=value1'
    }

params contains the query params from the current HTTP request.

=head1 EXAMPLE

Here is an example on how you can use this module, to keep track of where the user came from using your session object

In case we have a new session but the request had another page on your website as a referer (category is 'pageview') we 
actually want to tag the current page view as being direct traffic. You have to do this yourself because C<WWW::ClickSource>
doesn't know the status of your session.

    my $click_source = WWW::ClickSource->new($request);
    
    if (! $session->click_source ) {
        if ($click_source->category ne "pageview") {
            $session->click_source($click_source->to_hash);
        }
        else {
            $session->click_source({category => 'direct'});
        }
    }
    elsif ($click_source->category ne "pageview") {
        $session->click_source($click_source->to_hash);
    }

=head1 METHODS

=head2 new

Creates a new C<WWW::ClickSource> object

=cut
sub new {
    my ($class,$request,%options) = @_;
    
    my $self = {};
    
    if (! $request) {
        die 'WWW::ClickSource::new() must be called with a $request argument'
    }
    
    $self = detect_click_source($request);
    
    if ($options{keep_request}) { 
        $self->{request} = $request;
    }
    
    bless $self, $class;
    
    return $self;
}

=head2 detect_click_source

Determine where the user came from based on a request object

=cut
sub detect_click_source {
    my ($user_request) = @_;
    
    my $request = WWW::ClickSource::Request->new($user_request);
    
    my %click_info;
        
    if ( my $params = $request->{params} ) {
        if ( $params->{utm_source} || $params->{utm_campaign} || $params->{utm_medium} ) {
            %click_info = (
                    source => $params->{utm_source} // '',
                    campaign => $params->{utm_campaign} // '',
                    medium => $params->{utm_medium} // '',
            );
            
            if (! $click_info{source} ) {
                if ( $request->{referer} ) {
                    if ($request->{referer}->scheme =~ /https?/) {
                        $click_info{source} = $request->{referer}->host;
                    }
                    elsif ($request->{referer}->scheme eq 'android-app') {
                        $click_info{source} = 'android-app',
                        $click_info{app} = $request->{referer}->path,
                    }
                }
            }
            
            if ( $click_info{medium} =~ m/cpc|cpm|facebook_ads/ ) {
                $click_info{category} = 'paid';
            }
            elsif ( $request->{referer} ) {
                $click_info{category} = 'referer';
            }
            else {
                $click_info{category} = 'other';
            }
        }
        elsif ( $params->{gclid} ) { #gclid is a google adwords specific parameter
            if ( $request->{referer} ) {
                if  ( $request->{referer}->scheme =~ /https?/ ) {
                    if ( $request->{referer}->host =~ m/(?:google\.(?:com?\.)?\w{2,3}|googleadservices\.com)$/ ) {            
                        %click_info = (
                                source => 'google',
                                campaign =>  '',
                                medium => 'cpc',
                                category => 'paid',
                        );
                    }
                } elsif ( $request->{referer}->scheme eq 'android-app' ) {
                        %click_info = (
                                source => 'android-app',
                                app => $request->{referer}->authority,
                                campaign =>  '',
                                medium => 'cpc',
                                category => 'paid',
                        );
                }
                else {
                        %click_info = (
                                source => $request->{referer} ."", #stringify
                                campaign =>  '',
                                medium => 'cpc',
                                category => 'paid',
                        );
                }
            }
            else { #gclid param without referer - just use defaults for google, since we don't know anything else
                %click_info = (
                        source => 'google',
                        campaign =>  '',
                        medium => 'cpc',
                        category => 'paid',
                );
            }
        }
    }
    
    if (! $click_info{medium} ) {
        if ( $request->{referer} ) {
            
            if ( $request->{referer}->scheme =~ /https?/ ) {
            
                my $referer_base_url = $request->{referer}->host . $request->{referer}->path;
            
                if ( $referer_base_url =~ m/(?:google\.(?:com?\.)?\w{2,3}|googleadservices\.com).*?\/aclk/ ) {
            
                    %click_info = (
                            source => 'google',
                            campaign =>  '',
                            medium => 'cpc',
                            category => 'paid',
                    );
                }
                else {
                    if ( $request->{referer}->host eq $request->{host} ) {
                        %click_info = (
                            source => $request->{host},
                            category => 'pageview',
                        );
                    }
                    else {
                        %click_info = (
                            source => $request->{referer}->host,
                            category => 'referer',
                        );
                    }
                }
            } 
            elsif ( $request->{referer}->scheme eq 'android-app' ) {
                %click_info = (
                    source => 'android-app',
                    app => $request->{referer}->authority,
                    category => 'referer',
                );  
            }
            else {
                %click_info = (
                    source => $request->{referer} ."", #stringify
                    category => 'referer',
                );
            }
                
            
        }
        else {
            %click_info = (
                medium => '',
                category => 'direct',
            );
        }
        
        if ( $click_info{source} && $click_info{source} =~ m/l\.facebook\.com/ ) {
            $click_info{source} = 'facebook';
            $click_info{medium} = 'paid';
        }
        elsif ( $click_info{source} && $click_info{source} =~ m/(?:(?:m|www)\.)?(facebook|twitter|linkedin|plus\.google)\.(?:com?\.)?\w{2,3}/ ) {
            $click_info{source} = $1;
            $click_info{medium} = 'social';
        }
    }
    
    if ( $click_info{source} && $click_info{category} eq "referer" && ( 
                $click_info{source} =~ m/(?:www|search\.)?(google|yahoo|bing|yandex|baidu|aol|ask|duckduckgo)\.(?:com?\.)?\w{2,3}$/ || 
                $click_info{source} =~ m/webcache\.(google)usercontent\.com/ )
        ) {
        $click_info{source} = $1;
        $click_info{category} = 'organic';
        $click_info{medium} = 'organic';
    }
    
    
    #default to empty strings to avoid undefined value warnings in string comparisons
    $click_info{source} //= '';
    $click_info{campaign} //= '';
    $click_info{medium} //= '';
    $click_info{category} //= '';
    
    return %click_info if wantarray;
    
    return \%click_info;
}

=head2 source

Source of the click picked up from C<utm_source> request param or referer domain name

Only available in OOP mode

=cut
sub source {
    return $_[0]{source};
}

=head2 medium

Medium from which the click originated, usually picked up from C<utm_medium> request param

Only available in OOP mode

=cut
sub medium {
    return $_[0]{medium};
}

=head2 category

Click category, can be one of : direct, paid, referer, pageview

'pageview' means the user came accessed the current page by clicking on a link on another page 
of the same website. (referer host is the same as your domain name)

Only available in OOP mode

=cut
sub category {
    return $_[0]{category};
}

=head2 campaign

Campaign from which the click originated, usually picked up from C<utm_campaign> request param

Only available in OOP mode

=cut
sub campaign {
    return $_[0]{campaign};
}


=head2 to_hash

Return a hash containing all the relevant attributes of the current object 

Only available in OOP mode

=cut
sub to_hash {
    my $self = shift;
    
    my %info = (
        source => $self->{source} // '',
        campaign => $self->{campaign} // '',
        category => $self->{category} // '',
        medium => $self->{medium} // ''
    );
    
    return \%info;
}

=head2 request

Instance of L<WWW::ClickSource::Request> or a subclass of it, representing the internal request object 
used to extract the info we need

Only available in OOP mode and if you specify that you want access to the request object using keep_request => 1

    my $click_source = WWW::ClickSource->new($request, keep_request => 1);

=cut
sub request {
    return $_[0]{request};
}

1;

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 REPOSITORY

L<https://github.com/gliganh/WWW-ClickSource>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-ClickSource>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::ClickSource

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-ClickSource>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-ClickSource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-ClickSource>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-ClickSource/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
