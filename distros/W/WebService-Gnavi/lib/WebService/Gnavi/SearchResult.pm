# $Id: /mirror/perl/WebService-Gnavi/trunk/lib/WebService/Gnavi/SearchResult.pm 7171 2007-05-11T09:10:30.913520Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package WebService::Gnavi::SearchResult;
use strict;
use warnings;
use Data::Page;

sub parse
{
    my $class = shift;
    my $xml = shift;

    my $pager = Data::Page->new(
        $xml->findvalue('/response/total_hit_count'),
        $xml->findvalue('/response/hit_per_page'),
        $xml->findvalue('/response/page_offset')
    );

    my @list;
    foreach my $entry ($xml->findnodes('/response/rest')) {
        my %data = (
            map { ($_ => $entry->findvalue($_)) }
                qw(id update_date name  name_kana latitude longitude category url url_mobile address tel fax opentime holiday budget equipment)
        );

        $data{image_url} = {
            map { ($_ => $entry->findvalue("image_url/$_")) }
                qw(shop_image1 shop_image2 qrcode)
        };

        $data{access} = {
            map { ($_ => $entry->findvalue("access/$_")) }
                qw(line statin station_exit walk note)
        };

        $data{pr} = {
            map { ($_ => $entry->findvalue("pr/$_")) }
                qw(pr_short pr_long)
        };

        $data{flags} = {
            map { ($_ => $entry->findvalue("flags/$_")) }
                qw(mobile_site mobile_coupon pc_coupon)
        };

        $data{code} = {
            map { ($_ => $entry->findvalue("code/$_")) }
                qw(areacode areaname prefcode)
        };

        push @list, \%data;
    }

    bless { 
        pager => $pager,
        list  => \@list
    }, $class;
}

sub pager { shift->{pager} }
sub list  { wantarray ? @{ $_[0]->{list} } : $_[0]->{list} }

1;

__END__

=head1 NAME

WebService::Gnavi::SearchResult - Seach Result For Gnavi Search

=head1 SYNOPSIS

   my $gnavi = WebService::Gnavi->new(...);
   my $res   = $gnavi->search({ ... });
   my $pager = $res->pager;
   my @restaurants = $res->list;

=head1 METHODS

=head2 parse($xml)

Creates a new WebService::Gnavi::SearchResult instance from a XML::LibXML
document.

=head2 pager

Returns the pager

=head2 list

Returns the list of restaurants that were included in the response

=cut
