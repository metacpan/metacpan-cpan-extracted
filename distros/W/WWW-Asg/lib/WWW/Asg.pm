package WWW::Asg;
use strict;
use warnings;
use utf8;

use Carp;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder::XPath;
use Encode;
use URI;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;

#use Smart::Comments;

=head1 NAME

WWW::Asg - Get video informations from Asg.to 

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use WWW::Asg;

    my $asg = WWW::Asg->new();
    my @videos = $asg->latest_videos($page);
    foreach my $v ( @videos ) {
        print $asg->{embed} . "\n";
    }

=cut

my $strp = DateTime::Format::Strptime->new(
    pattern   => '%Y.%m.%d %H:%M',
    locale    => 'ja_JP',
    time_zone => 'Asia/Tokyo',
);
my %default_condition = (
    q              => '',
    searchVideo    => 'true',
    minimumLength  => '',
    searchCategory => 'any',
    sort           => 'date',
);
my $embed_code_format =
'<script type="text/javascript" src="http://asg.to/js/past_uraui.js"></script><script type="text/javascript">Purauifla("mcd=%s", 450, 372);</script>';

=head1 SUBROUTINES/METHODS

=head2 new 
=cut

sub new {
    my ( $class, %opt ) = @_;
    my $self = bless {%opt}, $class;

    $self->{ua} = LWP::UserAgent->new unless $self->{ua};

    $self;
}

=head2 search(%condition) 
=cut

sub search {
    my ( $self, %condition ) = @_;
    %condition = ( %default_condition, %condition );

    my $uri = URI->new('http://asg.to/search');
    $uri->query_form( \%condition );
    my $res = $self->{ua}->get( $uri->as_string );
    return () unless $res->is_success;

    $self->_extract_videos( $res->decoded_content );
}

=head2 latest_videos($page) 
=cut

sub latest_videos {
    my ( $self, $page ) = @_;
    $page ||= 1;
    my $res = $self->{ua}->get("http://asg.to/new-movie?page=$page");
    return () unless $res->is_success;

    $self->_extract_videos( $res->decoded_content );
}

sub _extract_videos {
    my ( $self, $html ) = @_;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($html);

    my $video_nodes = $tree->findnodes('//div[@id="list"]/div');

    my @videos = ();
    foreach my $node (@$video_nodes) {
        my $video = $self->_extract_video($node);
        next if not $video or not %$video;
        push @videos, $video;
    }

    @videos;
}

sub _extract_video {
    my ( $self, $node ) = @_;
    my $video = {};

    my $link_node = $node->findnodes('h3/a')->[0];
    return undef unless $link_node;

    # url
    my $url = $link_node->findvalue('@href');
    return undef
      unless $url =~ /(http:\/\/asg\.to)?\/contentsPage\.html\?mcd=([^?&]+)/;
    $video->{url} = "http://asg.to$url";

    # mcd
    $video->{mcd} = $2;

    # title
    my $title = $link_node->findvalue('@title');
    $title = $1 if $title =~ /.+アダルト動画:(.+)/;
    $video->{title} = $self->_trim($title);

    my $list_info_nodes = $node->findnodes('div[@class="list-info"]/p');

    # description
    my $description = $list_info_nodes->[3]->findvalue('.');
    $description = $1 if $description =~ /.*紹介文：\s*(.+)/;
    $video->{description} = $self->_trim($description);

    # thumbnail
    $video->{thumbnail} = $node->findvalue('a/img[@class="shift-left"]/@src');

    # date
    my $date = $list_info_nodes->[0]->findvalue('.');
    $video->{date} = $self->_date($date);

    # ccd
    my $ccd_node = $list_info_nodes->[1]->findnodes('a')->[0];
    my $ccd      = $ccd_node->findvalue('@href');
    if ( $ccd =~ /(http:\/\/asg\.to)?\/categoryPage\.html\?ccd=([^?&]+)/ ) {
        $video->{ccd} = $2;
    }
    $video->{ccd_text} = $self->_trim( $ccd_node->findvalue('.') );

    # play time
    my $play_time = $list_info_nodes->[2]->findvalue('.');
    if ( $play_time =~ /.*\s([0-9]{1,3}:[0-9]{1,2}).*/ ) {
        my $play_time_text = $1;
        my @splited        = split ':', $play_time_text;
        my $play_time_sec  = int( $splited[0] ) * 60 + int( $splited[1] );
        $video->{play_time}      = $play_time_sec;
        $video->{play_time_text} = $self->_trim($play_time_text);
    }

    # embed code
    $video->{embed} = sprintf( $embed_code_format, $video->{mcd} );

### $video
    return $video;
}

sub _date {
    my ( $self, $date_str ) = @_;
    $self->_trim($date_str);

    my $dt = undef;
    if ( $date_str =~ /.*([0-9]{2,4}\.[0-9]{2}\.[0-9]{2} [0-9]{2}:[0-9]{2}).*/ )
    {
        my $date = "20" . $1;
        $dt = $strp->parse_datetime($date);
    }
    elsif ( $date_str =~
        /.*([0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2}Z)?).*/ )
    {
        my $date = $1;
        $dt = DateTime::Format::ISO8601->new->parse_datetime($date);
    }
    else {
        return undef;
    }

    return $dt->iso8601;
}

sub _trim {
    my ( $self, $str ) = @_;
    $str =~ s/^[\s　]*(.*?)[\s　]*$/$1/ if $str;
    return $str;
}

=head1 AUTHOR

Tatsuya Fukata C<< <tatsuya.fukata@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-asg at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Asg>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Asg

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Asg>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Asg>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Asg>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Asg/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Tatsuya FUKATA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of WWW::Asg
