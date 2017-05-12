package Yahoo::Lifestyle;

use strict;
use Yahoo::BBAuth;
use LWP;
use XML::Simple;

our $VERSION = '0.2';

sub new {
    my $self = shift;
    my $param = shift;
    my $appid = $param->{appid};
    my $version = 'v0.1';
    my $url = 'http://tw.lifestyle.yahooapis.com/';
    my $request = $url.$version."/";
    bless ( { 
	    version => $version, 
	    url => $url, 
	    appid => $appid,
	    request => $request }, 
	$self);
}

sub auth {
    my $self = shift;
    my $param = shift; 
    my $secret = $param->{secret};
    my $bbauth = Yahoo::BBAuth->new(
	appid => $self->{appid},
	secret => $secret,
    );
    bless ( { auth => $bbauth }, $self);
}

sub Bizsearch {
    # we don't need the bbauth for this method
    my $self = shift;
    my $param = shift;
    my $p = $param->{BizName};
    my $l = $param->{address};
    my $page = $param->{page};
    my $request = $self->{request}."Biz.search?BizName=$p&address=$l&page=$page";
    my $response = XMLin($self->_get($request));
    if ($response->{status} eq 'ok') {
	return $response->{BizList};
    } else {
	return 0;
    }
}

sub BizgetDetails {
    my $self = shift;
    my $param = shift;
    my $id = $param->{id};
    my $request = $self->{request}."Biz.getDetails?ID=$id";
    my $response = XMLin($self->_get($request));
    if ($response->{status} eq 'ok') {
	return $response->{Biz};
    } else {
	return 0;
    }
}

sub BizlistReviews {
    my $self = shift;
    my $param = shift;
    my $id = $param->{id};
    my $begin = $param->{begin} || 0;
    my $limit = $param->{limit} || 10;
    my $request = $self->{request}."Biz.listReviews?id=$id&begin=$begin&limit=$limit";
    my $response = XMLin($self->_get($request));
    if ($response->{status} eq 'ok') {
	return $response->{ReviewList};
    } else {
	return 0;
    }
}

sub BizlistBuzzBizs {
    my $self = shift;
    my $request = $self->{request}."Biz.listBuzzBizs";
    my $response = XMLin($self->_get($request));
    if ($response->{status} eq 'ok') {
	return $response->{BizList};
    } else {
	return 0;
    }
}

sub ClasslistClasses {
    my $self = shift;
    my $request = $self->{request}."Class.listClasses";
    my $response = XMLin($self->_get($request));
    if ($response->{status} eq 'ok') {
	return $response->{ClassList};
    } else {
	return 0;
    }
}

sub ClasslistBizsInRange {
    my $self = shift;
    my $param = shift;
    my $class = $param->{class} || 0;
    my $lon = $param->{lon} || '121.5438';
    my $lat = $param->{lat} || '25.0417';
    my $request = $self->{request}."Class.listBizsInRange?class=$class&lon=$lon&lat=$lat";
    my $response = XMLin($self->_get($request));
    if ($response->{status} eq 'ok') {
	return $response->{BizList};
    } else {
	return 0;
    }
}

sub BizaddReview {
    my $self = shift;
    my $param = shift;
    my $comment = $param->{comment};
    if ($self->auth && $self->auth->validate_sig()) {
	my $request = $self->{request}."Biz.addReview?comment=$comment";
	return $self->auth->auth_ws_get_call($request);
    } else {
	return 0;
    }
}

sub UserlistBookmarks {
    my $self = shift;
    if ($self->auth && $self->auth->validate_sig()) {
	my $request = $self->{request}."User.listBookmarks";
	my $response = XMLin( $self->auth->auth_ws_get_call($request));
	if ($response->{status} eq 'ok') {
	    return $response->{BookmarkList};
	} else {
	    return 0;
	}
    } else {
	return 0;
    }
}

sub UserlistReviews {
    my $self = shift;
    my $param = shift;
    my $biz = $param->{biz};
    my $request;
    if ($biz) {
	$request = $self->{request}."User.listReviews?biz=$biz";
    } else {
	$request = $self->{request}."User.listReviews";
    }
    if ($self->auth->auth_ws_get_call($request)) {
	my $response = XMLin($self->auth->auth_ws_get_call($request));
	if ($response->{status} eq 'ok') {
	    return $response->{ReviewList};
	} else {
	    return 0;
	}
    } else {
	return 0;
    }

}

sub _get {
    my $self = shift;
    my $url = shift;
    my $ua = LWP::UserAgent->new;
    $url .= "&appid=".$self->{appid};
    my $req = HTTP::Request->new(POST => $url);
    my $res = $ua->request($req);
    if ($res->is_success) {
	return $res->content;
    } else {
	return $res->status_line;
    }
}


1;

__END__

=head1 NAME

Yahoo::Lifestyle is a simple interface for Yahoo! Taiwan Lifestyle open APIs. And you will need the Yahoo::BBAuth for some authentication APIs. Before you use that, you have to register a appid and secret for APIs request.

=head1 VERSION

This document describes version 0.1 of Yahoo::Lifestyle, released 
January 16, 2008.

=head1 SYNOPSIS

use Yahoo::Lifestyle;

$life = Yahoo::Lifestyle({ appid => "Ea6oQPHIkY03GklWeauQHWPpPJByMjCDoxRxcW"});
$res = $life->Bizsearch({BizName => 'coffee', address => '', page => '3');
$list = $life->BizlistReviews({id => 'b4328e0fa8b25615', begin => '0', limit => '10');
print $res->{Biz}->{$_}->{Name} for (keys %{$res});
$life->bbauth({secret => $secret});
$bookmarks = $life->UserlistBookmarks;

=head1 DESCRIPTION

Yahoo! Taiwan provides open APIs for local yellow page searching. Users can search the business information by search APIs. And developers can get the comments and feedback by the open APIs. It's a little complicate if developers want to implement the mashup or any other plugins by BBAuth provided by Yahoo. Yahoo::Lifestyle uses the Yahoo::BBAuth to make a simple interface for the developers who want to use the Lifestyle APIs.

=head1 METHODS

For more methods, please just refer the Yahoo! Developers Network in Taiwan. E<lt>http://tw.developer.yahoo.com/lifestyle_api.htmlE<gt> 

=head1 AUTHORS

Hsin-Chan Chien E<lt>hcchien@hcchien.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 by Hsin-Chan Chien E<lt>hcchien@hcchien.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

