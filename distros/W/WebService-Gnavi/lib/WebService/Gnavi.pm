# $Id: /mirror/perl/WebService-Gnavi/trunk/lib/WebService/Gnavi.pm 7171 2007-05-11T09:10:30.913520Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package WebService::Gnavi;
use strict;
use warnings;
use LWP::UserAgent;
use URI;
use XML::LibXML;
use WebService::Gnavi::SearchResult;
our $VERSION = '0.02';
our $BASE_URI = URI->new('http://api.gnavi.co.jp/');

sub new
{
    my $class = shift;
    my %args  = @_;
    $args{access_key} || die "WebService::Gnavi requires an access_key";
    bless {
        version    => 'ver1',
        access_key => $args{access_key},
    }, $class;
}

sub _user_agent
{
    my $self = shift;
    $self->{_lwp} ||= LWP::UserAgent->new(agent => "WebService::Gnavi/$VERSION");
}

sub _libxml
{
    my $self = shift;
    $self->{_libxml} ||= XML::LibXML->new;
}

sub search
{
    my $self = shift;
    my $args = shift;
    my $uri = $BASE_URI->clone;
    $uri->path("/$self->{version}/RestSearchAPI/");
    $uri->query_form({
        keyid => $self->{access_key},
        %$args
    });
    my $request = HTTP::Request->new(GET => $uri);
    $self->send_request('search', $request);
}

sub areas
{
    my $self = shift;

    my $uri     = $BASE_URI->clone;
    $uri->path("/$self->{version}/AreaSearchAPI/");
    $uri->query_form({
        keyid => $self->{access_key}
    });
    my $request = HTTP::Request->new(GET => $uri);
    $self->send_request('areas', $request);
}

sub prefectures
{
    my $self = shift;

    my $uri     = $BASE_URI->clone;
    $uri->path("/$self->{version}/PrefSearchAPI/");
    $uri->query_form({
        keyid => $self->{access_key}
    });
    my $request = HTTP::Request->new(GET => $uri);
    $self->send_request('prefectures', $request);
}

sub category_large
{
    my $self = shift;

    my $uri     = $BASE_URI->clone;
    $uri->path("/$self->{version}/CategoryLargeSearchAPI/");
    $uri->query_form({
        keyid => $self->{access_key}
    });
    my $request = HTTP::Request->new(GET => $uri);
    $self->send_request('category_large', $request);
}

sub category_small
{
    my $self = shift;

    my $uri     = $BASE_URI->clone;
    $uri->path("/$self->{version}/CategorySmallSearchAPI/");
    $uri->query_form({
        keyid => $self->{access_key}
    });
    my $request = HTTP::Request->new(GET => $uri);
    $self->send_request('category_small', $request);
}

sub send_request
{
    my ($self, $type, $req) = @_;

    my $ua = $self->_user_agent();
    my $res = $ua->request($req);
    return $self->_parse_response($type, $res);
}

sub _parse_response
{
    my ($self, $type, $res) = @_;

    my $parser = $self->_libxml();
    my $xml    = $parser->parse_string($res->content);
    my ($code) = $xml->findnodes('/gnavi/error/code');
    if ($code) {
        die WebService::Gnavi::Exception->new(code => $code->textContent());
    }

    if ($type eq 'search') {
        return WebService::Gnavi::SearchResult->parse($xml);
    }

    my $method = "_parse_$type";
    $self->$method($xml);
}

sub _parse_areas
{
    my ($self, $xml) = @_;

    my @list;
    foreach my $a ($xml->findnodes('/response/area')) {
        push @list, {
            area_code => $a->findvalue('area_code'),
            area_name => $a->findvalue('area_name')
        }
    }
    return @list;
}

sub _parse_prefectures
{
    my ($self, $xml) = @_;

    my @list;
    foreach my $a ($xml->findnodes('/response/pref')) {
        push @list, {
            pref_code => $a->findvalue('pref_code'),
            pref_name => $a->findvalue('pref_name'),
            area_code => $a->findvalue('area_code'),
        }
    }
    return @list;
}

sub _parse_category_large
{
    my ($self, $xml) = @_;

    my @list;
    foreach my $a ($xml->findnodes('/response/category_l')) {
        push @list, {
            map { ($_ => $a->findvalue($_)) }
                qw(category_l_code category_l_name)
        }
    }
    return @list;
}

sub _parse_category_small
{
    my ($self, $xml) = @_;

    my @list;
    foreach my $a ($xml->findnodes('/response/category_s')) {
        push @list, {
            map { ($_ => $a->findvalue($_)) }
                qw(category_s_code category_s_name category_l_code)
        }
    }
    return @list;
}

package WebService::Gnavi::Exception;
use strict;
use warnings;
use overload
    "" => \&as_string
;

sub new
{
    my $class = shift;
    my %args  = @_;
    bless { %args }, $class;
}

sub code { shift->{code} }
sub as_string { shift->{code} }

1;

__END__

=head1 NAME

WebService::Gnavi - Use Gnavi API From Perl

=head1 SYNOPSIS

  my $gnavi = WebService::Gnavi->new(
    access_key => $key
  );

  my $res   = $gnavi->search(\%params);
  my $pager = $res->pager;
  my @list  = $res->list;

  my @list = $gnavi->areas();
  my @list = $gnavi->prefectures();
  my @list = $gnavi->category_large();
  my @list = $gnavi->category_small();

=head1 DESCRIPTION

WebService::Gnavi allows you to access gnavi.co.jp's APIs from Perl.

=head1 METHODS

=head2 new

Creates a new instance of WebService::Gnavi. The access_key argument is
required.

=head2 search(\%params)

Searches for restaurants using the specified params

=head2 areas()

Returns the list of areas.

=head2 prefectures()

Returns the list of prefectures.

=head2 category_large()

Returns the list of large categories.

=head2 category_small()

Returns the list of small categories.

=head2 send_request($type, $request)

Sends a request to the API

=head1 CAVEATS

WebService::Gnavi::SearchResult doesn't collect categories at the moment.
This is planned to be fixed soon-ish (or, send in a patch, please ;)

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut