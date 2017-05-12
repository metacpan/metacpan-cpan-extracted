package WebService::TaobaoIP;

# ABSTRACT: Perl interface to Taobao IP API
use strict;
use warnings;
use utf8;
use Carp;
use JSON::XS;
use LWP::UserAgent;

our $VERSION = '0.03'; # VERSION

binmode STDOUT, ':encoding(UTF8)';

sub new
{
    my ( $class, $ip ) = @_;

    my $self = {};
    bless $self, $class;

    $self->_parse($ip);

    return $self;
}

sub _parse
{
    my ( $self, $ip ) = @_;

    my $base_url = 'http://ip.taobao.com/service/getIpInfo.php?ip=';
    my $full_url = $base_url . $ip;

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get($full_url);

    if ( $res->is_success )
    {
        my $info = JSON::XS->new->decode( $res->content );
        if ( $info->{code} == 0 )
        {
            %$self = %{ $info->{data} };
        }
        else
        {
            croak "$ip: get information failed.";
        }
    }
    else
    {
        croak $res->status_line;
    }
}

sub AUTOLOAD
{
    my ($self) = @_;

    my ($name) = our $AUTOLOAD =~ /::(\w+)$/;

    croak "`$name' method not exist" unless exists $self->{$name};

    return $self->{$name};
}

1;

__END__

=head1 NAME

WebService::TaobaoIP - Perl interface to Taobao IP API

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use WebService::TaobaoIP;

    my $ti = WebService::TaobaoIP->new('123.123.123.123');

    print $ti->ip;
    print $ti->country;
    print $ti->area;
    print $ti->region;
    print $ti->city;
    print $ti->isp;

=head1 DESCRIPTION

The WebService::TaobaoIP is a class implementing Taobao IP API. With it, you can get IP location information.

=head1 CONSTRUCTOR METHODS

=head2 $ti = WebService::TaobaoIP->new($ip)

This method constructs a new WebService::TaobaoIP object. You need to provide $ip argment.

=head1 ATTRIBUTES

The following attribute methods are provided.

=head2 $ti->ip

Return IP address.

=head2 $ti->country

Return country.

=head2 $ti->area

Return area.

=head2 $ti->region

Return region.

=head2 $ti->city

Return city.

=head2 $ti->isp

Return ISP.

=head1 AUTHOR

Xiaodong Xu, C<< <xxdlhy at gmail.com> >>

=head1 COPYRIGHT

Copyright 2013 Xiaodong Xu.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
