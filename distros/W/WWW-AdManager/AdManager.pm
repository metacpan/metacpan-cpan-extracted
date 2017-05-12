#==============================================================================
#
# CVS Log
#
# $Log: AdManager.pm,v $
# Revision 1.14  2001/10/29 10:52:47  wrigley
# v0.007 - minimal test added
#
# Revision 1.13  2001/10/26 14:40:52  wrigley
# v0.006
#
# Revision 1.12  2001/10/10 17:14:18  wrigley
# various bug fixes: new image is based on max ad no., not nads; alt text is included in new advert; ads with no ct URL are rendered as non-clickable
#
# Revision 1.11  2001/08/29 14:56:37  wrigley
# v0.004
#
# Revision 1.10  2001/08/24 17:39:39  wrigley
# v0.004
#
# Revision 1.9  2001/08/24 13:09:55  wrigley
# v0.003
#
# Revision 1.8  2001/08/23 16:55:17  wrigley
# v0.002
#
# Revision 1.7  2001/08/23 13:19:59  wrigley
# v0.001
#
# Revision 1.6  2001/08/23 11:50:04  wrigley
# *** empty log message ***
#
#
#==============================================================================

=head1 NAME

WWW::AdManager - a perl module to administer and serve online advertising

=head1 SYNOPSIS

=head2 CGI

=head3 advert interface

    WWW::AdManager->new(
        INTERFACE           => 'ADVERT',
        ADMANAGER_URL       => "/admanager",
    )->output();

=head3 admin interface

    WWW::AdManager->new(
        INTERFACE           => 'ADMIN',
        ADMANAGER_URL       => "/admanager",
        ADMANAGER_ADMIN_URL => "/internal/admanager",
    )->output();

=head2 mod_perl

    <IfModule mod_perl.c>

    <Location /internal/admanager>
        SetHandler          perl-script
        PerlHandler         Apache::WWW::AdManager
        PerlSetVar          INTERFACE ADMIN
        PerlSetVar          ADMANAGER_URL /admanager
        PerlSetVar          ADMANAGER_ADMIN_URL /internal/admanager
    </Location>

    <Location /admanager>
        SetHandler          perl-script
        PerlHandler         Apache::WWW::AdManager
        PerlSetVar          INTERFACE ADVERT
        PerlSetVar          ADMANAGER_URL /admanager
    </Location>

</IfModule>

=head1 DESCRIPTION

WWW::AdManager is a module which implements a web advert management system.
This is based around linked images, that are organized into "campaigns". Within
each campaign, the admanager randomizes the display of images, and tracks both
"page impressions" - i.e. the number of times the image is displayed - and
"clickthroughs" - i.e. the number of times the image is clicked on.

The module also provides an administration web interface, which can be served
through a access restricted URL, for creating and updating campaigns and
adverts, and displaying usage stats.

The interface support implementation both through CGI and mod_perl. mod_perl is
highly recommended, especially where there are more than one adver to display
per page.

The insertion of adverts into pages is done using SSI (server side includes -
see L<http://httpd.apache.org/docs/mod/mod_include.html>, for example). The
module does both logging of each relevant transaction (clickthrough / page
impression) and live compilation of stats.

Campaigns can be sub-divided into sub-campaigns for more convenient
organization of adverts.

=cut

#==============================================================================
#
# Package declaration
#
#==============================================================================

package WWW::AdManager;

#==============================================================================
#
# Standard pragmas
#
#==============================================================================

use strict;
use warnings;

#==============================================================================
#
# Modules
#
#==============================================================================

use CGI_Lite;
use File::Path;
use TempDir;
use Data::Dumper;
use IO::File;
use IO::Dir;
use Fcntl qw( :flock );
use HTML::Entities;
use URI;
use Image::Size;
use LWP::Simple;
use Apache::Constants qw( :response :common );

#==============================================================================
#
# Global variables
#
#==============================================================================

use vars qw( $VERSION %OPTIONS $WINDOW_PADDING $MAX_MARGIN );

$WINDOW_PADDING = 20;
$MAX_MARGIN = 20;
$VERSION = '0.007';

#==============================================================================
#
# Private methods
#
#==============================================================================

#------------------------------------------------------------------------------
#
# _mkpath( $dir ) - utility method to untaint a pathname and create it, or die.
#
#------------------------------------------------------------------------------

sub _mkpath
{
    my $self = shift;
    my $dir = shift;

    return if -d $dir;
    $dir = _untaint( $dir );
    mkpath( $dir ) or die "Can't create $dir\n";
}

#------------------------------------------------------------------------------
#
# _untaint( @paths ) - untaint path strings by checking against a regex that
# allows alphanumerics, underscores and periods.
#
#------------------------------------------------------------------------------

sub _untaint
{
    for ( @_ )
    {
        $_ = $1 and next if m{([a-zA-Z0-9_./]*)};
        die "untaint $_ failed\n";
    }
    return wantarray ? @_ : $_[0];
}

#------------------------------------------------------------------------------
#
# _untaint_and_open( $file, $mode ) - untaint the filename %file, and then
# open in mode $mode, returning an IO::File object.
#
#------------------------------------------------------------------------------

sub _untaint_and_open
{
    my $file = shift;
    my $mode = shift;

    my $untaintend_file = _untaint( $file );
    die "'$untaintend_file' ne '$file'\n" if $untaintend_file ne $file;
    return IO::File->new( $untaintend_file, $mode );
}

#------------------------------------------------------------------------------
#
# _freeze( $file, $data ) - "freeze" data in reference $data in filename $file,
# using Data::Dumper
#
#------------------------------------------------------------------------------

sub _freeze
{
    my $self = shift;
    my $file = shift;
    my $data = shift;

    my $fh = _untaint_and_open( $file, 'w' ) 
        or die "can't write to $file: $!\n"
    ;
    flock( $fh, LOCK_EX );
    print $fh Dumper $data;
    $fh->close();
}

#------------------------------------------------------------------------------
#
# _thaw( $file ) - "thaw" data in Data::Dumper file $file, and return as a
# reference.
#
#------------------------------------------------------------------------------

sub _thaw
{
    my $self = shift;
    my $file = shift;
    return {} unless -e $file;
    die "can't read $file\n" unless -r $file;
    my $fh = _untaint_and_open( $file, 'r' ) or die "can't open $file: $!\n";
    flock( $fh, LOCK_SH );
    $file = _untaint( $file );
    my $data = do $file;
    $fh->close();
    return $data;
}

#------------------------------------------------------------------------------
#
# _read_data - read advert data from the Data::Dumper datafile
#
#------------------------------------------------------------------------------

sub _read_data
{
    my $self = shift;
    $self->{ads} = $self->_thaw( $self->{datafile} );
}

#------------------------------------------------------------------------------
#
# _write_data - write advert data to the Data::Dumper datafile
#
#------------------------------------------------------------------------------

sub _write_data
{
    my $self = shift;
    warn "write data for $self->{campaign_path} to $self->{datafile}\n";
    eval {
        $self->_freeze( $self->{datafile}, $self->{ads} );
    };
    warn "error writing data $self->{datafile}: $@\n" if $@;
}

#------------------------------------------------------------------------------
#
# _status - method called to return appropriate status. If called in mod_perl
# mode, returns $self->{APACHE_STATUS}; otherwise, returns $@. In both cases
# also logs errors, if they havce occurred.
#
#------------------------------------------------------------------------------

sub _status
{
    my $self = shift;

    if ( $ENV{MOD_PERL} )
    {
        die "No APACHE_REQUEST\n" unless $self->{APACHE_REQUEST};
        if ( $@ )
        {
            die "$self->{APACHE_REQUEST} can't log_error\n" 
                unless $self->{APACHE_REQUEST}->can( 'log_error' )
            ;
            $self->{APACHE_REQUEST}->log_error( $@ );
            $self->{APACHE_STATUS} = SERVER_ERROR;
        }
        return $self->{APACHE_STATUS};
    }
    else
    {
        warn "$@\n" if $@;
        return $@;
    }
}

#------------------------------------------------------------------------------
#
# _redirect( $url ) - redirect to URL, using whichever method is appropriate to
# whether in mod_perl mode or not. The caller may then exit.
#
#------------------------------------------------------------------------------

sub _redirect
{
    my $self = shift;
    my $url = shift;

    warn "Redirect to $url\n";
    if ( $ENV{MOD_PERL} )
    {
        die "No APACHE_REQUEST\n" unless $self->{APACHE_REQUEST};
        die "$self->{APACHE_REQUEST} can't print\n" 
            unless $self->{APACHE_REQUEST}->can( 'header_out' )
        ;
        $self->{APACHE_REQUEST}->header_out( Location => $url );
        $self->{APACHE_STATUS} = REDIRECT;
    }
    else
    {
        print "Cache-Control: max-age=0\nLocation: $url\n\n";
    }
}

#------------------------------------------------------------------------------
#
# _print( @stuff ) - print stuff to the browser, using print method appropriate
# to whether in mod_perl mode or not.
#
#------------------------------------------------------------------------------

sub _print
{
    my $self = shift;

    if ( $ENV{MOD_PERL} )
    {
        die "No APACHE_REQUEST\n" unless $self->{APACHE_REQUEST};
        $self->{APACHE_REQUEST}->print( @_ );
    }
    else
    {
        print @_;
    }
}

#------------------------------------------------------------------------------
#
# _http_header( $content_type ) - set the content type in the HTTP header to
# $content_type, and add a cache control header to prevent caching. Also, print
# out header if not in mod_perl mode.
#
#------------------------------------------------------------------------------

sub _http_header
{
    my $self = shift;
    my $type = shift;

    if ( $ENV{MOD_PERL} )
    {
        warn "set content-type to $type\n";
        die "No APACHE_REQUEST\n" unless $self->{APACHE_REQUEST};
        $self->{APACHE_REQUEST}->content_type( $type );
        $self->{APACHE_REQUEST}->header_out( 'Cache-Control' => 'max-age=0' );
        $self->{APACHE_REQUEST}->send_http_header;
    }
    else
    {
        print "Content-Type: $type\nCache-Control: max-age=0\n\n";
    }
}

#------------------------------------------------------------------------------
#
# _subcampaigns( $campaign ) - returns all the sub-campagins of $campaign.
#
#------------------------------------------------------------------------------

sub _subcampaigns
{
    my $self = shift;
    my $campaign_path = shift;

    my $dir = "$self->{DATA_DIR}/$campaign_path";
    my %dir;
    tie %dir, 'IO::Dir', $dir;
    my @c = grep !/^\./, grep { -e "$dir/$_/admanager.pl" } %dir;
    return @c;
}

#------------------------------------------------------------------------------
#
# _subcampaigns - returns all the current campaigns.
#
#------------------------------------------------------------------------------

sub _campaigns
{
    my $self = shift;

    my %dir;
    my $dir = $self->{DATA_DIR};
    tie %dir, 'IO::Dir', $dir;
    my @c = grep !/^\./, grep { -e "$dir/$_/admanager.pl" } %dir;
    return @c;
}

#------------------------------------------------------------------------------
#
# _log_entry( $type ) - log an entry of type $type - either ct (clickthough) or
# img (page impression) - for advert number $n. Also increment appropriate
# entry in the stats Data::Dumper file.
#
#------------------------------------------------------------------------------

sub _log_entry
{
    my $self = shift;
    my $type = shift;
    my $n = shift;

    return unless $self->{ads}{log_usage};
    my $fh = _untaint_and_open( $self->{logfile}, 'a' )
        or die "can't write to $self->{logfile}\n"
    ;
    my $url = $self->{ads}{$n}{$type};
    my $datestr = scalar( localtime );
    my $document_name = $ENV{DOCUMENT_NAME} || '-';
    my $remote_host = $ENV{REMOTE_HOST} || $ENV{REMOTE_ADDR} || '-';
    print $fh "$datestr:$n:$type:$url:$document_name:$remote_host\n";
    warn "Log $n $type in $self->{statsfile}\n";
    my $stats = $self->_thaw( $self->{statsfile} );
    $stats->{$n}{$type}++;
    $self->_freeze( $self->{statsfile}, $stats );
}

#------------------------------------------------------------------------------
#
# _get_ad_keys - get a list of the current ad numbers.
#
#------------------------------------------------------------------------------

sub _get_ad_keys
{
    my $self = shift;
    return grep /^\d+$/, keys %{$self->{ads}}; 
}

#------------------------------------------------------------------------------
#
# _get_rand_element( @array ) - return a randomly selected element of the array
# @array.
#
#------------------------------------------------------------------------------

sub _get_rand_element
{
    my $self = shift;
    return $_[rand(@_)];
}

#------------------------------------------------------------------------------
#
# _get_ads - return a list of all the current ad hashrefs.
#
#------------------------------------------------------------------------------

sub _get_ads
{ 
    my $self = shift;
    return map { $self->{ads}{$_} } $self->_get_ad_keys();
}

#------------------------------------------------------------------------------
#
# _get_width - get the total width for the current campaign.
#
#------------------------------------------------------------------------------

sub _get_width
{
    my $self = shift;
    my $width = 0;
    for my $ad ( $self->_get_ads() )
    {
        my $w = $ad->{size}[0];
        $width = $w > $width ? $w : $width;
    }
    $width *= $self->{ads}{nads} if $self->{ads}{nads};

    if ( $self->{ads}{margin} )
    {
        my $nmargins = $self->{ads}{nads} - 1;
        $width += $nmargins * $self->{ads}{margin};
    }
    return $width;
}

#------------------------------------------------------------------------------
#
# _get_height - get the total height for the current campaign
#
#------------------------------------------------------------------------------

sub _get_height
{
    my $self = shift;
    my $height = 0;
    for my $ad ( $self->_get_ads() )
    {
        my $h = $ad->{size}[1];
        $height = $h > $height ? $h : $height;
    }
    return $height;
}

#------------------------------------------------------------------------------
#
# _get_max_adno - get the max. ad no.
#
#------------------------------------------------------------------------------

sub _get_max_adno
{ 
    my $self = shift;

    my $max = -1;
    for my $ad ( $self->_get_ads() )
    {
        $max = $ad->{n} if $ad->{n} > $max;
    }
    return $max;
}

#------------------------------------------------------------------------------
#
# _get_nads - get the current number of ads.
#
#------------------------------------------------------------------------------

sub _get_nads
{ 
    my $self = shift;
    return scalar $self->_get_ads();
}

#------------------------------------------------------------------------------
#
# _html_header - returns an HTML header for the admin interface pages.
#
#------------------------------------------------------------------------------

sub _html_header
{

    my $self = shift;
    return
        "<HEAD><TITLE>Admanager" .
        ( $self->{campaign_path} ? " ($self->{campaign_path})" : '' ) .
        "</TITLE></HEAD>"
    ;
}

#------------------------------------------------------------------------------
#
# _campaigns_as_html - returns HTML formated list of current campaigns, as well
# as a form to submit a new campaign creation request.
#
#------------------------------------------------------------------------------

sub _campaigns_as_html
{
    my $self = shift;

    my $other = $self->{campaign_path} ? "Other " : '';
    my $html = <<EOF;
<h2>${other}Campaigns</h2>
EOF
    my @campaigns = $self->_campaigns;
    $html .= 
        join " | ", 
        map { $_ eq $self->{campaign} ? $_ : <<EOF } 
    <a href="$self->{ADMANAGER_ADMIN_URL}/$_">$_</a>
EOF
        @campaigns
    ;
    $html .= <<EOF;
<form>
New campaign: 
<input name="nc" type="text" size="20">
<input name="action" type="submit" value="create">
</form>
EOF
    return $html;
}

#------------------------------------------------------------------------------
#
# _subcampaigns_as_html - returns HTML formated list of the sub-campaigns of the
# current campaign, as well # as a form to submit a new sub-campaign creation
# request.
#
#------------------------------------------------------------------------------

sub _subcampaigns_as_html
{
    my $self = shift;

    my $campaign_path = $self->{campaign_path};
    return '' unless $campaign_path;
    my $other = '';
    if ( $self->{subcampaign} ) # this is a sub-campaign ...
    {
        $other = "Other ";
    }
    my @subcampaigns = $self->_subcampaigns( $self->{campaign} );
    my $html = <<EOF;
<h2>${other}Sub-Campaigns of $self->{campaign}</h2>
EOF
    $html .= 
        join " | ", 
        map { $_ eq $campaign_path ? $_ : <<EOF } 
    <a href="$self->{ADMANAGER_ADMIN_URL}/$_">$_</a>
EOF
        map { "$self->{campaign}/$_" }
        @subcampaigns
    ;
    $html .= <<EOF;
<form>
New sub-campaign: 
$self->{campaign}/<input name="nsc" type="text" size="20" value="">
<input name="action" type="submit" value="create">
</form>
EOF
    return $html;
}

#------------------------------------------------------------------------------
#
# _current_campaign_actions_as_html - returns an HTML formatted list of actions
# for the current campaign: ad a new advert, view the usage log, test the
# campaign, and delete the campaign.
#
#------------------------------------------------------------------------------

sub _current_campaign_actions_as_html
{
    my $self = shift;

    return '' unless $self->{campaign_path};
    my $add_ad = $self->_get_max_adno() + 1;
    my $html = <<EOF;
<h2>Current Campaign ($self->{campaign_path})</h2>
<p>
    <a href="$self->{admin_url}?add=$add_ad">Add a new advert</a>
EOF
    my $nads = $self->_get_nads();
    if ( $nads )
    {
        my $h = $self->_get_height( $self->{campaign_path} );
        my $w = $self->_get_width( $self->{campaign_path} );
        my $width = $w + $WINDOW_PADDING;
        my $height = $h + $WINDOW_PADDING;
        $html .= <<EOF;
    | <a href="$self->{admin_url}?display_log=1">View the usage log</a>
    | <a 
        target="_blank" 
        href="$self->{ADMANAGER_URL}/$self->{campaign_path}"
        onclick="
            window.open(
                '$self->{ADMANAGER_URL}/$self->{campaign_path}',
                '_blank',
                'width=$width,height=$height,toolbar'
            );
            return false;
        "
    >Test the campaign</a>
EOF
    }
    my $url = 
        "$self->{ADMANAGER_ADMIN_URL}?" .
        'action=delete_campaign&' .
        "c=$self->{campaign_path}"
    ;
    $html .= <<EOF;
    | <a 
        href="$url"
        onclick="return confirm( 'are really sure about that?' );"
    >Delete the campaign</a>
</p>
EOF
    return $html;
}

#------------------------------------------------------------------------------
#
# _ad_info_as_html( $ad ) - returns an HTML formatted table with the info
# for the $ad'th advert in the currrent campaign.
#
#------------------------------------------------------------------------------

sub _ad_info_as_html
{
    my $self = shift;
    my $ad = shift;

    my $n = $ad->{n};
    my $nw = $ad->{nw} ? 'Yes' : 'No';
    my $alt = $ad->{alt} || '';
    my $size = join( 'x', @{$ad->{size}}[0,1] );
    my $ad_as_html = $self->_ad_as_html( $n, 1 );
    return <<EOF;
<table>
    <tr>
        <td colspan="2">$ad_as_html</td>
    </tr>
    <tr>
        <td><b>Image:</b></td><td>$ad->{img}</td>
    </tr>
    <tr>
        <td><b>Image Size:</b></td><td>$size</td>
    </tr>
    <tr>
        <td><b>Clickthough:</b></td><td>$ad->{ct}</td>
    </tr>
    <tr>
        <td><b>Alt. text:</b></td><td>$alt</td>
    </tr>
    <tr>
        <td><b>Open in new window:</b></td><td>$nw</td>
    </tr>
</table>
EOF
}

#------------------------------------------------------------------------------
#
# _ad_stats_as_html( $ad ) - returns an HTML formatted table with the usage
# stats for the $ad'th advert in the currrent campaign.
#
#------------------------------------------------------------------------------

sub _ad_stats_as_html
{
    my $self = shift;
    my $ad = shift;
    my $n = $ad->{n};
    my $stats = $self->_thaw( $self->{statsfile} );
    $stats->{$n}{ct} ||= 0;
    $stats->{$n}{img} ||= 0;
    return <<EOF;
<table>
    <tr>
        <td><b>No. Impressions:</b></td><td>$stats->{$n}{img}</td>
    </tr>
    <tr>
        <td><b>No. Clickthroughs:</b></td><td>$stats->{$n}{ct}</td>
    </tr>
</table>
EOF
}

#------------------------------------------------------------------------------
#
# _all_ads_info_as_html - returns an HTML formatted form with the advert
# attributes relevant to all adverts in the current campaign: the number of
# adverts to display, and the image margins, as well as forms to change these
# values.
#
#------------------------------------------------------------------------------

sub _all_ads_info_as_html
{
    my $self = shift;
    
    my $log_usage = $self->{ads}{log_usage};
    my $html = sprintf( <<EOF, $log_usage ? 'selected' : '', $log_usage ? '' : 'selected' );
<table cellpadding="5">
    <tr>
    <form>
        <td>
            <b>Log usage:</b>
        </td>
        <td>
            <select name="log_usage">
                <option %s value="1"> Yes
                <option %s value="0"> No
            </select>
        </td>
        <td>
            <input type="submit" name="action" value="change log usage">
        </td>
    </tr>
    <form>
EOF
    $html .= <<EOF;
    <form>
    <tr>
        <td>
            <b>No. of ads to display:</b>
        </td>
        <td>
            <select name="nads">
EOF
    my $n = $self->{ads}{nads} || 0;
    my $nads = $self->_get_nads();
    for ( my $i = 1; $i <= $nads;$i++ )
    {
        my $selected = $i == $n ? 'selected' : '';
        $html .= <<EOF;
                <option $selected value="$i">$i</option>
EOF
    }
    $html .= <<EOF;
            </select>
        </td>
        <td>
            <input type="submit" name="action" value="change no. ads">
        </td>
    </form>
    </tr>
    <tr>
    <form>
        <td>
            <b>Image margin:</b>
        </td>
        <td>
            <select name="margin">
EOF
    my $margin = $self->{ads}{margin} || 0;
    $html .= join( '',  map 
        { 
            my $selected = $_ == $margin ? 'selected' : '';
            <<EOF;
                <option $selected value="$_">$_</option>
EOF
        }
        ( 0 .. $MAX_MARGIN )
    );
    my $h = $self->_get_height( $self->{campaign_path} );
    my $w = $self->_get_width( $self->{campaign_path} );
    $html .= <<EOF;
            </select>px
        </td>
        <td>
            <input type="submit" name="action" value="change margin">
        </td>
    </form>
    </tr>
    <tr>
        <td colspan="3">
            <b>Total campaign dimensions: $w x $h</b>
        </td>
    </tr>
</table>
EOF
    return $html;
}

#------------------------------------------------------------------------------
#
# _ads_info_as_html - returns an HTML formatted table with all the advert info
# for the current campaign, including usage stats, and links to actions for
# each ad (edit / delete).
#
#------------------------------------------------------------------------------

sub _ads_info_as_html
{
    my $self = shift;

    my $nads = $self->_get_nads();
    my $colspan = 2 + $self->{ads}{log_usage};
    my $html = <<EOF;
<h2>Adverts</h2>
<table border="1" cellpadding="5">
    <tr>
        <th colspan="$colspan">All Adverts</th>
    </tr>
    <tr>
        <td colspan="$colspan">
EOF
    $html .= $self->_all_ads_info_as_html() . <<EOF;
        </td>
    </tr>
EOF
    return $html . "</table>" unless $nads;
    $html .= "<tr><th>Advert</th>";
    $html .= "<th>Usage Stats</th>" if $self->{ads}{log_usage};
    $html .= " <th>Action</th></tr>";
    for my $ad ( sort { $a->{n} <=> $b->{n} } $self->_get_ads() )
    {
        $html .= <<EOF;
    <tr>
        <td valign="top">
EOF
        $html .= $self->_ad_info_as_html( $ad );
        $html .= <<EOF;
        </td>
EOF
        $html .= 
            qq{<td valign="top">} .
            $self->_ad_stats_as_html( $ad ) .
            qq{</td>}
            if $self->{ads}{log_usage};
        $html .= <<EOF;
        <td valign="top">
            <a href="$self->{admin_url}?edit=$ad->{n}">Edit</a> |
            <a href="$self->{admin_url}?action=delete_ad&ad=$ad->{n}">Delete</a>
        </td>
    </tr>
EOF
    }
    $html .= "</table>";
    return $html;
}

#------------------------------------------------------------------------------
#
# _ssi_code_as_html - returns HTML formatted code for inserting the current
# campaign as an SSI comment.
#
#------------------------------------------------------------------------------

sub _ssi_code_as_html
{
    my $self = shift;
    return '' unless $self->{campaign_path};
    my $html = <<EOF;
<h2>SSI code</h2>
<pre>
EOF
    $html .= encode_entities( <<EOF );
<!--#include virtual="$self->{ADMANAGER_URL}/$self->{campaign_path}" -->
EOF
    $html .= <<EOF;
</pre>
EOF
return( $html );
}

#------------------------------------------------------------------------------
#
# _main_admin_interface - Returns an HTML table containing all current adverts,
# plus the camapigns and sub-campaings list.
#
#------------------------------------------------------------------------------

sub _main_admin_interface
{
    my $self = shift;

    return 
        $self->_html_header() .
        $self->_campaigns_as_html() .
        $self->_subcampaigns_as_html() .
        $self->_current_campaign_actions_as_html() .
        $self->_ads_info_as_html() .
        $self->_ssi_code_as_html()
    ;
}

#------------------------------------------------------------------------------
#
# _change_log_usage - change the "log" attribute for the current campaign to
# the value stored in the formdata hash. The log attribute determined whether
# usage is logged for this campaign.
#
#------------------------------------------------------------------------------

sub _change_log_usage
{
    my $self = shift;
    my $log_usage = $self->{formdata}{log_usage};
    return unless defined $log_usage;
    warn "Changing log_usage to $log_usage\n";
    $self->{ads}{log_usage} = $log_usage;
    $self->_write_data;
}

#------------------------------------------------------------------------------
#
# _change_margin - change the "margin" attribute for the current campaign to
# the value stored in the formdata hash (margin is the width of the margin
# around each image).
#
#------------------------------------------------------------------------------

sub _change_margin
{
    my $self = shift;
    my $margin = $self->{formdata}{margin};
    return unless defined $margin and int( $margin ) eq $margin;
    warn "Changing margin to $margin\n";
    $self->{ads}{margin} = $margin;
    $self->_write_data;
}

#------------------------------------------------------------------------------
#
# _change_nads - change the "nads" attribute for the current campaign to
# the value stored in the formdata hash (nads is the number of ads to display
# simultaneously for the current campaign).
#
#------------------------------------------------------------------------------

sub _change_nads
{
    my $self = shift;
    my $nads = $self->{formdata}{nads};
    return unless defined $nads;
    warn "Changing no. adverts displayed to $nads\n";
    $self->{ads}{nads} = $nads;
    $self->_write_data;
}

#------------------------------------------------------------------------------
#
# _get_imagesize( $url ) - get the image size for a image URL, using
# LWP::Simple to get the image, and Image::Size to calculate its size.
#
#------------------------------------------------------------------------------

sub _get_imagesize( $ )
{
    my $self = shift;
    my $url = shift;
    my $uri = URI->new_abs( $url, $self->{abs_admin_url} );
    my $buf = get( $uri );
    return imgsize( \$buf );
}

#------------------------------------------------------------------------------
#
# _add_ad - add a new advert, using the img, ct, and ad values stored in the
# formdata hash. Also, calculate the image size for the img image. Check that
# ad is equal to the current no. of ads (this helps to prevent two concurrent
# sessions trying to grab the same new ad no.).
#
#------------------------------------------------------------------------------

sub _add_ad
{
    my $self = shift;
    my $img = $self->{formdata}{img};
    my $ct = $self->{formdata}{ct};
    my $ad = $self->{formdata}{ad};
    my $alt = $self->{formdata}{alt};
    $img or die "No img param\n";
    defined( $ct ) or die "no ct param\n";
    defined( $ad ) or die "no ad param\n";

    my @size = $self->_get_imagesize( $img );
    my $ad_add = $self->_get_max_adno() + 1;
    if ( $img and $ct and defined( $ad ) and $ad == $ad_add )
    {
        warn "Adding ad (no $ad): $img $ct (@size)\n";
        $self->{ads}{$ad} =
            { alt => $alt, ct => $ct, img => $img, size => \@size, n => $ad }
        ;
        $self->_write_data;
    }
    else
    {
        warn "Error: $ad != $ad_add\n";
        for my $ad ( $self->_get_ads )
        {
            warn "\t$ad->{n}\n";
        }
    }
}

#------------------------------------------------------------------------------
#
# _edit_ad - edit the ad specified by the ad value in the formdata hash,
# updating the img, ct, nads, and nw fields, and recalculating the image size,
# if necessary.
#
#------------------------------------------------------------------------------

sub _edit_ad
{
    my $self = shift;
    my $img = $self->{formdata}{img};
    my $ct = $self->{formdata}{ct};
    my $ad = $self->{formdata}{ad};
    my $nads = $self->{formdata}{nads};
    my $nw = $self->{formdata}{nw};
    my $alt = $self->{formdata}{alt};
    $img or die "No img param\n";
    defined( $ct ) or die "no ct param\n";
    defined( $ad ) or die "no ad param\n";

    $self->{ads}{$ad}{ct} = $ct;
    $self->{ads}{$ad}{n} = $ad;
    $self->{ads}{$ad}{nads} = $nads;
    $self->{ads}{$ad}{nw} = $nw;
    $self->{ads}{$ad}{alt} = $alt;
    if ( $self->{ads}{$ad}{img} ne $img )
    {
        $self->{ads}{$ad}{img} = $img;
        my @size = $self->_get_imagesize( $img );
        $self->{ads}{$ad}{size} = \@size;
    }
    warn "Edit $ad ad: $img (", @{$self->{ads}{$ad}{size}}, ") -> $ct\n";
    $self->_write_data;
}

#------------------------------------------------------------------------------
#
# _delete_ad - delete the ad specified by the ad value in the formdata hash.
#
#------------------------------------------------------------------------------

sub _delete_ad
{
    my $self = shift;
    my $ad = $self->{formdata}{ad};
    delete( $self->{ads}{$ad} );
    $self->_write_data;
}

#------------------------------------------------------------------------------
#
# _create_campaign - create a new campaign named after the nc value in the
# formdata hash.
#
#------------------------------------------------------------------------------

sub _create_campaign
{
    my $self = shift;
    my $nc = $self->{formdata}{nc};
    unless ( $nc )
    {
        my $nsc = $self->{formdata}{nsc} or
            warn "no nc param\n" and return;
        ;
        $nc = "$self->{campaign_path}/$nsc";
    }
    warn "Create $nc campaign\n";
    my $datadir = _untaint( "$self->{DATA_DIR}/$nc" );
    unless ( -e $datadir )
    {
        mkpath( $datadir ) or die "Can't create $datadir\n";
    }
    $self->{datafile} = "$datadir/admanager.pl";
    $self->{ads} = { log_usage => 1 };
    $self->_write_data;
}

#------------------------------------------------------------------------------
#
# _delete_campaign - delete the campaign corresponding to the c value in the
# formdata hash.
#
#------------------------------------------------------------------------------

sub _delete_campaign
{
    my $self = shift;
    my $c = $self->{formdata}{c};
    die "No campaign specified\n" unless $c;
    warn "Delete $c campaign\n";
    $c = $self->_munge_filename_from_path( $c );
    my $statfile = "$self->{STATS_DIR}/$c.stats";
    warn "statsfile: $statfile\n";
    if ( -e $statfile )
    {
        warn "Unlink $statfile\n";
        unlink( $statfile ) or die "Can't remove $statfile\n";
    }
    my $logfile = "$self->{LOG_DIR}/$c.log";
    warn "logfile: $statfile\n";
    if ( -e $logfile )
    {
        warn "Unlink $logfile\n";
        unlink( $logfile ) or die "Can't remove $logfile\n";
    }
    my $datadir = _untaint( "$self->{DATA_DIR}/$self->{formdata}{c}" );
    warn "datadir: $datadir\n";
    if ( -e $datadir )
    {
        warn "rmtree $datadir\n";
        rmtree( $datadir ) or die "Can't remove $datadir\n";
    }
    $self->_redirect( $self->{ADMANAGER_ADMIN_URL} );
}


#------------------------------------------------------------------------------
#
# _ad_form( $type ) - return an HTML edit/add ad form based on the $type
# argument, and the equivilent value in the formdata hash (which should contain
# the ad number for the ad to be created / edited).
#
#------------------------------------------------------------------------------

sub _ad_form
{
    my $self = shift;
    my $type = shift;

    my $val = $self->{formdata}{$type};
    my $ad = $self->{ads}{$val}; 
    my $alt = $ad->{alt} || '';
    my $ychecked = $ad->{nw} ? 'checked' : '';
    my $nchecked = $ad->{nw} ? '' : 'checked';
    my $form = <<EOF;
<form>
<input type="hidden" name="ad" value="$val">
<table>
    <tr>
        <td>Image URL:</td>
        <td><input type="text" name="img" size="50" value="$ad->{img}"></td>
    </tr>
    <tr>
        <td>Alt. Text:</td>
        <td><input type="text" name="alt" size="50" value="$alt"></td>
    </tr>
    <tr>
        <td>Clickthrough URL:</td>
        <td><input type="text" name="ct" size="50" value="$ad->{ct}"></td>
    </tr>
    <tr>
        <td>Open in new window</td>
        <td>
            <input $ychecked type="radio" name="nw" value="1"> Yes
            <input $nchecked type="radio" name="nw" value="0"> No
        </td>
    </tr>
    <tr>
        <td colspan="2">
            <input type="submit" name="action" value="$type">
        </td>
    </tr>
</table>
</form>
EOF
    return $form;
}

#------------------------------------------------------------------------------
#
# _logfile - return the contents of the logfile for the current campaign.
#
#------------------------------------------------------------------------------

sub _logfile
{
    my $self = shift;
    my $fh = _untaint_and_open( $self->{logfile}, 'r' );
    return unless $fh;
    return join '', <$fh>;
}

#------------------------------------------------------------------------------
#
# _page_impression - log a page impression for th advert number specified by
# the img value in the formdata hash, and redirect to the corresponding image.
#
#------------------------------------------------------------------------------

sub _page_impression
{
    my $self = shift;
    my $n = $self->{formdata}{img};
    die "No img parameter set\n" unless defined $n;
    my $url = $self->{ads}{$n}{img}
        or die "No image $n im campaign $self->{campaign_path}\n"
    ;
    $self->_log_entry( 'img', $n );
    warn "page impression $url\n";
    $self->_redirect( $url );
}

#------------------------------------------------------------------------------
#
# _ad_as_html( $n ) - return advert no. $n as HTML.
#
#------------------------------------------------------------------------------

sub _ad_as_html
{
    my $self = shift;
    my $n = shift;
    my $first = shift;

    my $campaign_path = $self->{campaign_path};
    my $ad = $self->{ads}{$n};
    my $img = $ad->{img};
    my $size = $ad->{size};
    my $size_str = $size ? "width=\"$size->[0]\" height=\"$size->[1]\"" : '';
    my $url = $self->{ADMANAGER_URL};
    $url =~ s/$self->{path_info}$// if $self->{path_info};
    $url .= "/$campaign_path";
    my $alt = $ad->{alt} || "$campaign_path advert no. $n";
    my $rand = $$ . time . rand(1000);
    my $img_url = 
        $self->{REDIRECT_PAGE_IMPRESSIONS} ? 
            "$url?img=$n&amp;rand=$rand" : "$img?$rand"
    ;
    my $margin = $self->{ads}{margin} || 0;
    my $user_agent = $ENV{HTTP_USER_AGENT};
    if ( 
        $user_agent !~ /compatible/ and 
        $user_agent =~ m!Mozilla/4!
    )
    {
        $margin += $size->[0];
    }
    my $style = $first ? '' : "style=\"margin-left:${margin}px;\"";
    if ( $ad->{ct} )
    {
        my $target = $ad->{nw} ? 'target="_blank"' : '';
        my $ct_url = "$url?ct=$n&amp;rand=$rand";
        return <<EOF;
<!-- user agent $user_agent -->
<!-- advert no $n from campaign $campaign_path -->
<a 
    $target 
    $style 
    href="$ct_url"
><img 
        alt="$alt" 
        border="0" 
        $size_str 
        src="$img_url" 
/></a>
EOF
    }
    else
    {
        return
            join( '',
                qq{<!-- advert no $n from campaign $campaign_path -->},
                qq{<img alt="$alt" $size_str $style src="$img_url" />}
        );
    }
}

#------------------------------------------------------------------------------
#
# _random_ad_as_html - return a random ad as HTML, logging a 'img' entry for
# that ad.
#
#------------------------------------------------------------------------------

sub _random_ad_as_html
{
    my $self = shift;

    my @html;
    my $nads = $self->{ads}{nads} || 1;
    my @ad_keys = $self->_get_ad_keys();

    warn "Displaying $nads random ads\n";
    for ( 1 .. $nads )
    {
        my $n = $self->_get_rand_element( @ad_keys );
        warn "$n chosen from @ad_keys\n";
        @ad_keys = grep { $_ ne $n } @ad_keys;
        $self->_log_entry( 'img', $n ) 
            unless $self->{REDIRECT_PAGE_IMPRESSIONS}
        ;
        push( @html, $self->_ad_as_html( $n, $_ == 1 ) );
        warn "Display ad $n as HTML\n";
    }
    my $margin = $self->{ads}{margin} || 0;
    my $spacer = '';
    return join( $spacer, @html );
}

#------------------------------------------------------------------------------
#
# _clickthrough - log a 'ct' entry for the ad corresponding to the ct value in
# the formdata hash, and redirect to the corresponding URL.
#
#------------------------------------------------------------------------------

sub _clickthrough
{
    my $self = shift;
    my $n = $self->{formdata}{ct};
    my $url = $self->{ads}{$n}{ct};
    warn "Click though to $url\n";
    $self->_log_entry( 'ct', $n );
    $self->_redirect( $url );
    return $url;
}

#------------------------------------------------------------------------------
#
# _setup_dirs - sets up and creates the directories required.
#
#------------------------------------------------------------------------------

sub _setup_dirs
{
    my $self = shift;
    unless ( $self->{INSTALL_DIR} )
    {
        my $root = $ENV{HOME} || TempDir->new || die "Can't work out a root\n";
        $self->{INSTALL_DIR} = "$root/.admanager";
    }
    $self->_mkpath( $self->{INSTALL_DIR} );
    $self->{STATS_DIR} ||= "$self->{INSTALL_DIR}/stats";
    $self->_mkpath( $self->{STATS_DIR} );
    $self->{LOG_DIR} ||= "$self->{INSTALL_DIR}/log";
    $self->_mkpath( $self->{LOG_DIR} );
    $self->{DATA_DIR} ||= "$self->{INSTALL_DIR}/data";
    $self->_mkpath( $self->{DATA_DIR} );
    $self->{ERR_DIR} ||= "$self->{INSTALL_DIR}/err";
    $self->_mkpath( $self->{ERR_DIR} );
}

sub _log_errors
{
    my $self = shift;
    my $errfile = 
        "$self->{ERR_DIR}/$self->{INTERFACE}." .
        ( $ENV{MOD_PERL} ? 'mod_perl' : 'cgi' ) .
        ".err"
    ;
    $errfile = _untaint( $errfile );
    open( STDERR, ">>$errfile" ) or die "Can't write to $errfile: $!\n";
    warn "$0: ", scalar( localtime ), "\n";
    warn "PATH_INFO: $ENV{PATH_INFO}\n" if $ENV{PATH_INFO};
    warn 
        "FORM DATA:\n", 
        map { "\t$_ = $self->{formdata}{$_}\n" } 
        keys %{$self->{formdata}}
    ;
    warn "Running under mod_perl\n" if exists $ENV{MOD_PERL};
}

#------------------------------------------------------------------------------
#
# _munge_filename_from_path( $path ) - create a munged filename from a path, by
# replacing '/' characters with '_'s. NOTE: the replacement character needs to
# not clash with the allowable filename characters from _untaint.
#
#------------------------------------------------------------------------------

sub _munge_filename_from_path
{
    my $self = shift;
    my $path = shift;
    $path =~ s{/}{_}g;
    return $path;
}

#------------------------------------------------------------------------------
#
# _setup_files - sets up files required for current campaign
#
#------------------------------------------------------------------------------

sub _setup_files
{
    my $self = shift;
    my $campaign_path = shift;

    return unless $campaign_path;

    my $cn = $self->_munge_filename_from_path( $campaign_path );
    $self->{statsfile} = "$self->{STATS_DIR}/$cn.pl";
    $self->{logfile} = "$self->{LOG_DIR}/$cn.log";
    my $datadir = "$self->{DATA_DIR}/$campaign_path";
    $self->_mkpath( $datadir );
    $self->{datafile} = "$datadir/admanager.pl";
}

#------------------------------------------------------------------------------
#
# _setup_admin_urls - create admin url values
#
#------------------------------------------------------------------------------

sub _setup_admin_urls
{
    my $self = shift;
    my ( $proto ) = $ENV{SERVER_PROTOCOL} =~ /^(\w+)/;
    $self->{abs_admin_url} = 
        lc( $proto ) . '://' .
        $ENV{SERVER_NAME} .
        # ( $ENV{SERVER_PORT} != 80 ? ":$ENV{SERVER_PORT}" : '' ) .
        $ENV{SCRIPT_NAME} .
        ( $ENV{PATH_INFO} ? $ENV{PATH_INFO} : '' ) .
        ( $ENV{QUERY_STRING} ? "?$ENV{QUERY_STRING}" : '' )
    ;
    $self->{ADMANAGER_ADMIN_URL} ||= $ENV{SCRIPT_NAME};
    $self->{admin_url} = "$self->{ADMANAGER_ADMIN_URL}/$self->{campaign_path}";
}

#------------------------------------------------------------------------------
#
# _setup_campaign_path - setup campaign_path. This is maintained using the
# $PATH_INFO.
#
#------------------------------------------------------------------------------

sub _setup_campaign_path
{
    my $self = shift;
    $self->{path_info} = $ENV{PATH_INFO};
    my $campaign_path = $self->{path_info} || '';
    $campaign_path =~ s{/}{};
    $campaign_path ||= '';
    ( $self->{campaign}, $self->{subcampaign} ) = split( '/', $campaign_path );
    return $self->{campaign_path} = $campaign_path;
}

#------------------------------------------------------------------------------
#
# _check_options - check the options passed to the constructor against the
# %OPTIONS hash. Values of this hash are either 'undef' (optional) or contain a
# quoted regex to test the option value against.
#
#------------------------------------------------------------------------------

sub _check_options
{
    my $self = shift;
    for ( keys %$self )
    {
        die "Unknown option $_\n" unless exists $OPTIONS{$_};
    }
    for my $opt ( grep { defined $OPTIONS{$_} } keys %OPTIONS )
    {
        my $whatami = lc( ref( $OPTIONS{$opt} ) );
        die "No $opt option specified\n" unless exists $self->{$opt};
        if ( $whatami eq 'regexp' )
        {
            die "$opt option should be $OPTIONS{$opt}\n" 
                unless $self->{$opt} =~ $OPTIONS{$opt}
            ;
        }
        elsif ( $whatami eq 'code' )
        {
            my $ret = $OPTIONS{$opt}->( $self, $opt );
            die $ret if defined $ret;
        }
    }
}

#==============================================================================

=head1 CONSTRUCTOR

The constructor for the module takes a number of options (see
L<OPTIONS|"OPTIONS">) as a hash of arguments.

=cut

#==============================================================================

sub new
{
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;

    $self->{APACHE_REQUEST} ||= undef;
    $self->_check_options();
    $self->{formdata} = CGI_Lite->new->parse_form_data;

    $self->_setup_dirs();
    $self->_log_errors();
    my $campaign_path = $self->_setup_campaign_path();
    $self->_setup_admin_urls();
    $self->_setup_files( $campaign_path );
    $self->_read_data() if $campaign_path;

    return $self;
}

#==============================================================================

=head1 Apache::Registry HANDLER

WWW::Admanger offers a "handler" method that can be used in a mod_perl ennabled
Apache web server (see L<http://perl.apache.org/>). Various options can be
specified using PerlSetVar directives (see L<SYNOPSIS|"SYNOPSIS">). These
options correspond to the L<CONSTRUCTOR|"CONSTRUCTOR"> options, and are listed
in the L<OPTIONS|"OPTIONS"> section. The handler method simple creates a new
WWW::AdManager object using these options, and calls the L<output|"output">
method on this object.

=cut

#==============================================================================

sub handler
{
    my $r = shift;

    unless ( $ENV{MOD_PERL} )
    {
        die "handler called in non-mod_perl environment\n";
    }
    return WWW::AdManager->new(
        APACHE_REQUEST => $r,
        map { $_ => $r->dir_config->{$_} } 
        grep { $_ ne 'APACHE_REQUEST' } 
        keys %OPTIONS
    )->output;
}

#==============================================================================

=head1 OPTIONS

=cut

#==============================================================================

=head2 INTERFACE

This option deltermined which interface is displayed by the L<output|"ouput">
method.  This option is REQUIRED, and its value should be one of ADMIN or
ADVERT.  Basically, the ADMIN interface presents a user interface to configure
the advertising campaigns. This should probably be offered through an access
restricted URL. The ADVERT interface presents HTML code to include in a page
which is hosing the advert.

=head2 ADMANAGER_URL

This is the URL that corresponds to the CGI / mod_perl interface through which
the advert is served. This is used by WWW::Admanger to generate links (e.g.
test links in the ADMIN interface, and clickthrough / page impression links in
the ADVERT interface. This option is REQUIRED.

=head2 ADMANAGER_ADMIN_URL

This is the URL that corresponds to the CGI / mod_perl interface through which
the administration interface is presented. This is used by WWW::Admanger to
generate links to other views in the administration interface. It is a REQUIRED
option if the L<INTERFACE|"INTERFACE"> option is set to ADMIN.

=head2 INSTALL_DIR

This option specified the default root directory for installing the various
files (logging, stats, advert data) used by / produced by the application. It
is an OPTIONAL option. The default is either $HOME/.admanager, if the $HOME
environment is set, or $TMP/.admanager, where $TMP is the system temporary
directory, as determined by the L<TempDir|TempDir> module.

=head2 ERR_DIR

The directory where application error logs are written. This is an OPTIONAL
option, and defaults to L<INSTALL_DIR|"INSTALL_DIR">/err.

=head2 LOG_DIR

The directory where application user logs are written. There is a seperate log
file per camapign. These logs are of the following format:

    $datestr:$n:$type:$url:$document_name:$remote_host

where:

=over 4

=item $datestr

Date string returned by localtime.

=item $n

No. of the advert in the campaign.

=item $type

Either 'img' if this is a page impression, or 'ct' if this is a clickthrough.

=item $url

The URL corresponding to the image served / clickthrough redirected to.

=item $document_name

The document from which the advert was served (through SSI).

=item $remote_host

The remote host requesting the advert.

=back

This is an OPTIONAL option, and defaults to L<INSTALL_DIR|"INSTALL_DIR">/log.

=head2 STATS_DIR

The directory where usage statistics files are written. This is an OPTIONAL
option, and defaults to L<INSTALL_DIR|"INSTALL_DIR">/stats.

=head2 DATA_DIR

The directory where advert data files are saved (using
L<Data::Dumper|Data::Dumper>). This is an OPTIONAL option, and defaults to
L<INSTALL_DIR|"INSTALL_DIR">/data.

=head2 REDIRECT_PAGE_IMPRESSIONS

If this option is set, page impression URLs (i.e. the SRC attribute of the IMG
tag) are redirected through the admanager system. This helps to ensure that
page impressions are properly logged. It is NOT recommended if the application
is being served through CGI, as it is likely to seriously affext performance.

=cut

%OPTIONS = (

    INTERFACE => 
        sub {
            my $self = shift;
            my $opt = shift;

            return "$opt should be (ADMIN|ADVERT)"
                unless $self->{$opt} =~ /^(ADMIN|ADVERT)$/i
            ;
            return "ADMANAGER_ADMIN_URL option not set\n"
                if 
                    $self->{$opt} eq 'ADMIN' and 
                    not $self->{ADMANAGER_ADMIN_URL}
            ;
            return undef;
        }
    ,
    ADMANAGER_URL               => sub { undef },
    ADMANAGER_ADMIN_URL         => undef,
    INSTALL_DIR                 => undef,
    ERR_DIR                     => undef,
    LOG_DIR                     => undef,
    STATS_DIR                   => undef,
    DATA_DIR                    => undef,
    REDIRECT_PAGE_IMPRESSIONS   => undef,
    APACHE_REQUEST              =>
        sub {
            my $self = shift;
            my $opt = shift;

            return undef unless $ENV{MOD_PERL};
            return "new called with MOD_PERL but no $opt\n"
                unless $self->{$opt}
            ;
            return "$opt is not an Apache object ($self->{$opt})\n"
                unless ref( $self->{$opt} ) =~ /^Apache/
            ;
            $self->{APACHE_STATUS} = OK;
            return undef;
        }
    ,
);

#==============================================================================

=head1 METHODS

=cut

#==============================================================================

=head2 output

This moethod is called to generate the appropriate output for the
L<INTERFACE|"INTERFACE"> created. It does the "right thing" depending on
whether the application is called through CGI or mod_perl.

=cut

sub output
{
    my $self = shift;

    if ( $self->{INTERFACE} eq 'ADVERT' )
    {
        if ( defined $self->{formdata}{ct} )
        {
            my $url = $self->_clickthrough;
        }
        elsif ( defined $self->{formdata}{img} )
        {
            my $url = $self->_page_impression;
        }
        else
        {
            $self->_http_header( 'text/html' );
            my $html = $self->_random_ad_as_html;
            $self->_print( $html );
        }
    }
    elsif ( $self->{INTERFACE} eq 'ADMIN' )
    {
        if ( defined $self->{formdata}{action} )
        {
            if ( $self->{formdata}{action} eq 'delete_campaign' )
            {
                $self->_delete_campaign();
                return $self->_status(); # redirect to the root
            }
            elsif ( $self->{formdata}{action} eq 'create' )
            {
                $self->_create_campaign();
            }
            elsif ( $self->{formdata}{action} eq 'edit' )
            {
                $self->_edit_ad();
            }
            elsif ( $self->{formdata}{action} eq 'change log usage' )
            {
                $self->_change_log_usage();
            }
            elsif ( $self->{formdata}{action} eq 'change margin' )
            {
                $self->_change_margin();
            }
            elsif ( $self->{formdata}{action} eq 'change no. ads' )
            {
                $self->_change_nads();
            }
            elsif ( $self->{formdata}{action} eq 'add' )
            {
                $self->_add_ad();
            }
            elsif ( $self->{formdata}{action} eq 'delete_ad' )
            {
                $self->_delete_ad();
            }
        }
        if ( defined $self->{formdata}{'display_log'} )
        {
            $self->_http_header( 'text/plain' );
            my $logfile = $self->_logfile();
            $self->_print( $logfile );
            return $self->_status;
        }
        elsif ( defined $self->{formdata}{edit} )
        {
            $self->_http_header( 'text/html' );
            my $form = $self->_ad_form( 'edit' );
            $self->_print( $form );
            return $self->_status;
        }
        elsif ( defined $self->{formdata}{add} )
        {
            $self->_http_header( 'text/html', );
            my $form = $self->_ad_form( 'add' );
            $self->_print( $form );
            return $self->_status;
        }
        else
        {
            $self->_http_header( 'text/html' );
            $self->_print( $self->_main_admin_interface() );
        }
    }
    return $self->_status;
}

=head1 ADMINISTRATION WEB INTERFACE

=head2 Campaign

This section shows a list of links to all the current campaigns, plus a form
input to create a new campaign. On creation and selection of a campaign, you
should see ...

=head2 Sub-Campaigns of $campaign

This section shows a list of links all the sub-campaigns of the currently
selected campaign (if any) plus a form input to create a new sub-campaign.

=head2 Current Campaign ($campaign_path)

This section shows details of the current campaign / sub-campaign. This
includes:

=over 4

=item a link to "Add a new advert"

This links to a form which can be used to enter the details of a new advert for
the current campaign (Image URL, Alt. Text, Clickthrough URL, and whether the
advert is to be opened in a new window).

=item a link to "View the usage log"

This link display the text of the usage log for the current campaign. See the
L<LOG section|"LOG"> for details of the log format.

=item a link to "Test the campaign"

This link launches a new window with can be used to preview the current
campaign. Reloading the window should demonstrate the advert rotation.

=item a link to "Delete the campaign"

This link is used to delete all information about the current campaign. It
throws us a javascript confirmation box, just in case!

=back

=head2 Adverts

This section contains a table with details of all the adverts in the current
campaign. It includes links to edit / delete individual adverts, and to change
advert attributes for the whole campaign (the no. of ads to display
simultaneously, the image margin in pixels). It also includes reports on the
usage stats (page impressions / clickthroughs) for each advert in the campaign.

The "Log usage" attribute determines whether ad usage (page impressions /
clickthroughs are logged, and stats accumulated). The default for this is "Yes"
for a new campaign.

The "No. of ads to display" attribute allows campaigns with multiple images to
be displayed simultaneously (side-by-side). The number of ads displayed >= the
number of ads in the campaign, and the displayed images are randomised over the
available "slots".

The "Image margin" attribute determines the margin around adverts. This is
implemented using a margin stylesheet attribute on the img tag.

=head2 SSI code

This section displays the SSI comment that needs to be inserted in a page to
display the current campaign.

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#==============================================================================
#
# True ...
#
#==============================================================================

1;
