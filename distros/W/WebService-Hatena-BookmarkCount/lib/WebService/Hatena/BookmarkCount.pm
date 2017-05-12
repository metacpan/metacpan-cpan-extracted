=head1 NAME

WebService::Hatena::BookmarkCount -- Interface for Hatena::Bookmark's XML-RPC API

=head1 SYNOPSIS

    use WebService::Hatena::BookmarkCount;

    my @list = (
        'http://www.hatena.ne.jp/info/webservices',
        'http://www.kawa.net/works/perl/hatena/bookmarkcount.html',
    );
    my $hash = WebService::Hatena::BookmarkCount->getCount( @list );
    foreach my $url ( @list ) {
        printf( "%5d   %s\n", $hash->{$url}, $url );
    }

    my $top = 'http://japan.cnet.com/';
    my $total = WebService::Hatena::BookmarkCount->getTotalCount( $top );

=head1 DESCRIPTION

WebService::Hatena::BookmarkCount is a interface for the Hatena::Bookmark 
Web Services's XML-RPC API. This provides two methods, I<bookmark.getCount> 
and I<bookmark.getTotalCount>, to get numbers of count on bookmarks.

=head1 METHODS

=head3 $hash = WebService::Hatena::BookmarkCount->getCount( @list );

This method makes a I<bookmark.getCount> XML-RPC call for the Hatena::Bookmark 
Web Services. C<@list> is list of URLs to get a number of registrations in 
Hatena::Bookmark. This method returns a reference for a hash, which keys are 
URLs and which values are counts returned by the Hatena Web Services.

=head3 $hash = WebService::Hatena::BookmarkCount->getTotalCount( $url );

This method makes a I<bookmark.getTotalCount> XML-RPC call for 
the Hatena::Bookmark Web Services. C<$url> is the URL to get a number of 
registrations in Hatena::Bookmark. 

=head1 MODULE DEPENDENCIES

L<XML::TreePP>

L<LWP::UserAgent> or L<HTTP::Lite>

=head1 SEE ALSO

Hatena Bookmark
http://b.hatena.ne.jp/

Documents in Japanese
http://www.kawa.net/works/perl/hatena/bookmarkcount.html

=head1 AUTHOR

Yusuke Kawasaki http://www.kawa.net/

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2006-2010 Yusuke Kawasaki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package WebService::Hatena::BookmarkCount;
use strict;
use Carp;
use XML::TreePP;

use vars qw( $VERSION );
$VERSION = "0.07";

my $XMLRPC_URL     = 'http://b.hatena.ne.jp/xmlrpc';
my $WAIT_SECS      = 1;
my $MAX_REQUEST    = 40;
my $TREEPP_OPTIONS = { force_array => [qw( member )] };

sub new {
    my $package = shift;
    my $self    = {@_};
    bless $self, $package;
    $self->{treepp} = XML::TreePP->new(%$TREEPP_OPTIONS);
    $self;
}

sub getCount {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $links = [@_];    # copy

    my $outhash = {};
    my $reqxml;
    my $resxml;
    my $sleep = $WAIT_SECS;
    my $tpp   = $self->{treepp};
    while ( scalar @$links ) {
        my @splice = splice( @$links, 0, $MAX_REQUEST );
        my $param = [ map { { value => { string => $_ } }; } @splice ];
        my $reqtree = {
            methodCall => {
                methodName => "bookmark.getCount",
                params     => { param => $param }
            }
        };
        $reqxml = $tpp->write($reqtree) or last;
        my $tree;
        ( $tree, $resxml ) = $tpp->parsehttp( POST => $XMLRPC_URL, $reqxml );
        last unless ref $tree;
        &parse_res_struct( $tree, $outhash );
        sleep( $sleep++ ) if scalar @$links;    # wait
    }
    $outhash = undef unless scalar keys %$outhash;
    return if ( !$outhash && !wantarray );
    wantarray ? ( $outhash, $reqxml, $resxml ) : $outhash;
}

sub getTotalCount {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $url = shift or return;

    my $reqtree = {
        methodCall => {
            methodName => "bookmark.getTotalCount",
            params => {
                param => {
                    value => {
                        string => $url,
                    }
                }
            }
        }
    };

    my $tpp   = $self->{treepp};
    my $reqxml = $tpp->write($reqtree) or last;
    my( $tree, $resxml ) = $tpp->parsehttp( POST => $XMLRPC_URL, $reqxml );
    return unless ref $tree;
    my $count = &parse_res_simple( $tree );

    wantarray ? ( $count, $reqxml, $resxml ) : $count;
}

sub parse_res_struct {
    my $tree = shift or return;
    my $hash = shift || {};
    return unless ref $tree;
    return unless ref $tree->{methodResponse};
    return unless ref $tree->{methodResponse}->{params};
    return unless ref $tree->{methodResponse}->{params}->{param};
    my $param = $tree->{methodResponse}->{params}->{param};
    return unless ref $param->{value};
    return unless ref $param->{value}->{struct};
    my $array = $param->{value}->{struct}->{member};
    return unless ref $array;
    return unless scalar @$array;

    foreach my $member (@$array) {
        next unless defined $member->{name};
        next unless ref $member->{value};
        my $name  = $member->{name};
        my $value = $member->{value};
        my $type  = ( sort keys %$value )[0] or next;    # first value
        $hash->{$name} = $value->{$type};
    }
    $hash;
}

sub parse_res_simple {
    my $tree = shift or return;
    return unless ref $tree;
    return unless ref $tree->{methodResponse};
    return unless ref $tree->{methodResponse}->{params};
    return unless ref $tree->{methodResponse}->{params}->{param};
    my $param = $tree->{methodResponse}->{params}->{param};
    return unless ref $param->{value};
    my $int = $param->{value}->{int};
    $int;
}

1;
