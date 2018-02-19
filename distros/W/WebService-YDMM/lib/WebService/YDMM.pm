package WebService::YDMM;
use 5.008001;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use URI;
use HTTP::Tiny;
use JSON;

our $VERSION = "0.03";


sub new {
    my ($class, %args) = @_;

    croak("affiliate_id is required") unless $args{affiliate_id};
    croak("api_id is required") unless $args{api_id};

    _validate_affiliate_id($args{affiliate_id});

    my $self = {
        affiliate_id => $args{affiliate_id},
        api_id       => $args{api_id},
        _agent       => HTTP::Tiny->new( agent => "WebService::YDMM agent $VERSION" ),
        _base_url    => 'https://api.dmm.com/',
    };

    return bless $self, $class;
}


sub _validate_affiliate_id {
    my $account = shift;

    unless ($account =~ m{99[0-9]$}) {
        croak("Postfix of affiliate_id is '990--999'");
    }

    return;
}

sub _validate_site_name {
    my $site = shift;
    
    unless ($site eq 'DMM.com' || $site eq 'DMM.R18'){
        croak('Request to Site name for "DMM.com" or "DMM.R18"');
    }
    return $site;
}


sub _send_get_request {
    my ($self, $target, $query_param) = @_;

    map { $query_param->{$_} = $self->{$_} } qw/affiliate_id api_id/;
    $query_param->{output} = "json";

    my $uri = URI->new($self->{_base_url});
    $uri->path("affiliate/v3/" . $target);
    $uri->query_form($query_param);

    my $res = $self->{_agent}->get($uri->as_string);
    croak("$target API acess failed...") unless $res->{success};

    return decode_json($res->{content});
}


sub _suggestion_site_param {
    if ( scalar @_ == 2){
        return _set_site_param(@_);
    } else {
        return _check_exists_site_param(@_);
    }
}

sub _set_site_param {
    my $site        = _validate_site_name(shift);
    my $query_param = shift;
    $query_param->{site} = $site;
    return $query_param;
}

sub _check_exists_site_param {
    my $query_param = shift;

    if (exists $query_param->{site}){
        _validate_site_name($query_param->{site});
    } else {
        croak('Require to Sitename for "DMM.com" or "DMM.R18"');
    }

    return $query_param;
}


sub _suggestion_floor_param {

    if ( scalar @_ == 2 ){
        return _set_floor_param(@_);
    } else {
        return _check_exists_floor_param(@_);
    }
}


sub _set_floor_param {
    my ($floor_id,$query_param) = @_;

    if (! (defined $floor_id)) {
        croak('Require to floor_id');
    }
    $query_param->{floor_id} = $floor_id;

    return $query_param;
}

sub _check_exists_floor_param {
    my $query_param = shift;
    if  (! (exists $query_param->{floor_id}) ){
        croak('Require to floor_id');
    }
    return $query_param;
}

sub item {
    my $self = shift;
    my $query_param = _suggestion_site_param(@_);
    return $self->_send_get_request("ItemList", +{ %$query_param })->{result};
}

sub floor {
    my $self = shift;
    return $self->_send_get_request("FloorList", +{})->{result};
}

sub actress {
    my($self,$query_param) = @_;
    return $self->_send_get_request("ActressSearch", +{ %$query_param })->{result};
}

sub genre {
    my $self  = shift;
    my $query_param = _suggestion_floor_param(@_);
    return $self->_send_get_request("GenreSearch", +{ %$query_param })->{result};
}

sub maker {
    my $self  = shift;
    my $query_param = _suggestion_floor_param(@_);
    return $self->_send_get_request("MakerSearch", +{ %$query_param })->{result};
}

sub series {
    my $self  = shift;
    my $query_param = _suggestion_floor_param(@_);
    return $self->_send_get_request("SeriesSearch", +{ %$query_param })->{result};
}

sub author {
    my $self  = shift;
    my $query_param = _suggestion_floor_param(@_);
    return $self->_send_get_request("AuthorSearch", +{ %$query_param })->{result};
}



1;
__END__

=encoding utf-8

=head1 NAME

WebService::YDMM - It's yet another DMM sdk.

=head1 SYNOPSIS

    use WebService::YDMM;

    my $dmm = WebService::YDMM->new(
        affiliate_id => ${affiliate_id},
        api_id       => ${api_id},
    );

    my $items = $dmm->item("DMM.com",+{ keyword => "魔法少女まどか☆マギカ"})->{items};

    # or 

    my $items = $dmm->item(+{ site => "DMM.R18" , keyword => "魔法少女まどか☆マギカ"});

    say $items->[0]->{floor_name}   # "コミック"
    say $items->[0]->{iteminfo}->{author}->[1]->{name}  #"ハノカゲ"

=head1 DESCRIPTION

WebService::YDMM is another DMM webservice module.
L<DMM|http://www.dmm.com> is Japanese shopping site.

This module supported by L<DMM.API|https://affiliate.dmm.com/api/>.

=head1 METHODS

=head2 new(%params)
 
Create instance of WebService::YDMM
 
I<%params> must have following parameter:
 
=over 4

=item api_id
 
API ID of DMM.com web service
You can get API key on project application for DMM affiliate service.
 
=item affiliate_id
 
Affiliate ID of DMM.com web service
You can get API key on project application for DMM affiliate service.
This affiliate_id validate of 990 ~ 999 number.

=back

=head2 item([$site],\%params)

You can get item list for DMM.com

=over 4

=item $site [MUST]

You must use either "DMM.com" or DMM.R18" for item param.
Item param can  insert \%params .

=back

=head2 floor()

You  can get floor list.
This methods no requires parameters.

=head2 actress(\%params)

You can get actress information from DMM.

=head2 genre([$floor_id],\%params)

You can get genre information.

=over 4

=item $floor_id [MUST] 

This method  must $floor_id from floor list.
Floor_id param can  insert \%params .

=back

=head2 maker([$floor_id],\%params)

You can get maker information.

=over 4

=item $floor_id [MUST] 

This method  must $floor_id from floor list.
Floor_id param can  insert \%params .

=back

=head2 series([$floor_id],\%params)

You can get series information.

=over 4

=item $floor_id [MUST] 

This method  must $floor_id from floor list.
Floor_id param can  insert \%params .

=back

=head2 author([$floor_id],\%params)

You can get author information.

=over 4

=item $floor_id [MUST] 

This method  must $floor_id from floor list.
Floor_id param can  insert \%params .

=back

=head3 \%params

%params has officional query parameter.
Please check as appropriate for officional api support page from DMM.

=head1 LICENSE

Copyright (C) AnaTofuZ.

DMM API Copyright 
Powered by L<DMM.com Webサービス|https://affiliate.dmm.com/api/>

Powered by L<DMM.R18 Webサービス|https://affiliate.dmm.com/api/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

AnaTofuZ E<lt>anatofuz@gmail.comE<gt>

=cut

