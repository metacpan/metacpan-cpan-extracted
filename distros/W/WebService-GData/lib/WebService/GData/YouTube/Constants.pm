package WebService::GData::YouTube::Constants;
use strict;
use warnings;

our $VERSION = 1.02;

use constant {

    PROJECTION        => 'api',
    BASE_URI          => 'http://gdata.youtube.com/feeds/',
    STAGING_BASE_URI  => 'http://stage.gdata.youtube.com/feeds/',
    API_DOMAIN_URI    => 'http://gdata.youtube.com/',
    STAGING_API_DOMAIN_URI =>'http://stage.gdata.youtube.com/',
    UPLOAD_BASE_URI   => 'http://uploads.gdata.youtube.com/feeds/',
    STAGING_UPLOAD_BASE_URI=>'http://uploads.stage.gdata.youtube.com/feeds/',
    
    YOUTUBE_NAMESPACE => 'xmlns:yt="http://gdata.youtube.com/schemas/2007"',

    MOBILE_H263  => 1,
    H263         => 1,
    MPEG4        => 6,
    MOBILE_MPEG4 => 6,
    EMBEDDABLE   => 5,

    TODAY    => 'today',
    WEEK     => 'this_week',
    MONTH    => 'this_month',
    ALL_TIME => 'all_time',

    NONE     => 'none',
    MODERATE => 'moderate',
    STRICT   => 'strict',
    L0       => 'none',
    L1       => 'moderate',
    L2       => 'strict',

    RELEVANCE     => 'relevance',
    PUBLISHED     => 'published',
    VIEW_COUNT    => 'viewCount',
    RATING        => 'rating',
    POSITION      => 'position',
    COMMENT_COUNT => 'commentCount',
    DURATION      => 'duration'
};

my @general   = qw(PROJECTION BASE_URI UPLOAD_BASE_URI API_DOMAIN_URI STAGING_BASE_URI STAGING_UPLOAD_BASE_URI STAGING_API_DOMAIN_URI);
my @namespace = qw(YOUTUBE_NAMESPACE);
my @format    = qw(MOBILE_H263 H263 MPEG4 MOBILE_MPEG4 EMBEDDABLE);
my @time      = qw(TODAY WEEK MONTH ALL_TIME);
my @safe      = qw(NONE MODERATE STRICT L0 L1 L2);
my @order     =
  qw(RELEVANCE PUBLISHED VIEW_COUNT RATING POSITION COMMENT_COUNT DURATION);

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = ( @format, @time, @safe, @order, @general,@namespace );
our %EXPORT_TAGS = (
    general => [@general],
    format  => [@format],
    'time'    => [@time],
    safe    => [@safe],
    order   => [@order],
    namespace=>[@namespace],
    all     => [ @format, @time, @safe, @order, @general, @namespace]
);

"The Earth is blue like an orange.";

__END__

=pod

=head1 NAME

WebService::GData::YouTube::Constants - constants used for YouTube service.


=head1 SYNOPSIS

    #don't important anything
    use WebService::GData::YouTube::Constants; 

    #import the namespace related constants
    use WebService::GData::YouTube::Constants qw(:format); #or :time or :safe or :all

    use WebService::GData::YouTube;


    my $yt     = new WebService::GData::YouTube();
	my $videos = $yt->get_top_rated_videos('JP','Comedy',TODAY);
	   
	
	   $yt    -> query->safe(STRICT)->orderby(VIEW_COUNT)->q('guitar');
	my $videos = $yt->search_video;

    #if not imported
	
	   $yt->get_top_rated_videos('JP','Comedy',WebService::GData::YouTube::Constants::TODAY);
	   




=head1 DESCRIPTION

This package contains some constants for YouTube Service v2, mostly related to available parameter values when querying the service.
You can import all of them by using :all or import only a subset by using :format,:time or :safe...

=head2 GENERAL CONSTANTS

The general constants map the default projection used and the base url queried.
You can choose to import general related constants by writing use WebService::GData::YouTube::Constants qw(:general);

=head3 PROJECTION

The default projection used is "api".

=head3 BASE_URI

=head3 API_DOMAIN_URI

=head3 UPLOAD_BASE_URI

Below are the constants used to switch to the youtube staging server:

=head3 STAGING_BASE_URI

=head3 STAGING_API_DOMAIN_URI

=head3 STAGING_UPLOAD_BASE_URI


I<import with :general>

=head2 NAMESPACE CONSTANTS

The namespace constants map the youtube xml namespace.
You can choose to import namespace related constants by writing use WebService::GData::YouTube::Constants qw(:namespace);

=head3 YOUTUBE_NAMESPACE


I<import with :namespace>


=head2 FORMAT CONSTANTS

The format constants map the available protocol format as of version 2 of YouTube Service API.
You can choose to import format related constants by writing use WebService::GData::YouTube::Constants qw(:format);

=head3 MOBILE_H263

map the format of value 1.

=head3 H263

map the format of value 1.

=head3 MPEG4

map the format of value 6.

=head3 MOBILE_MPEG4

map the format of value 6.

=head3 EMBEDDABLE

map the format of value 5.

See also L<http://code.google.com/intl/en/apis/youtube/2.0/reference.html#formatsp> for further information about the available formats.

I<import with :format>

=head2 TIME CONSTANTS

The time consants map the available times used as of version 2 of YouTube Service API for the standard feeds.
You can choose to import time related constants by writing use WebService::GData::YouTube::Constants qw(:time);

=head3 TODAY

=head3 WEEK

=head3 MONTH

=head3 ALL_TIME

See also L<http://code.google.com/intl/en/apis/youtube/2.0/reference.html#timesp> for further information about the available time settings.


I<import with :time>

=head2 SAFE CONSTANTS

The safe consants map the available safety mode used as of version 2 of YouTube Service API.
You can choose to import safe mode related constants by writing use WebService::GData::YouTube::Constants qw(:safe);


=head3 NONE

=head3 MODERATE

=head3 STRICT

=head3 L0

alias for NONE

=head3 L1
	
alias for MOEDERATE
	
=head3 L2

alias for STRICT

See also L<http://code.google.com/intl/en/apis/youtube/2.0/reference.html#safeSearchsp> for further information about the available safe mode settings.

I<import with :safe>

=head2 ORDER CONSTANTS

The order settings consants map the available order settings used as of version 2 of YouTube Service API.
You can choose to import order settings related constants by writing use WebService::GData::YouTube::Constants qw(:order);

=head3 RELEVANCE

=head3 PUBLISHED

=head3 VIEW_COUNT

=head3 RATING

=head3 POSITION

=head3 COMMENT_COUNT

=head3 DURATION

See also L<http://code.google.com/intl/en/apis/youtube/2.0/reference.html#orderbysp> for further information about the available ordering settings.

I<import with :order>

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
