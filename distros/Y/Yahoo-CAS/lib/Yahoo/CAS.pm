package Yahoo::CAS;

use strict;
use LWP;
use XML::Simple;

our $VERSION = '0.2';

sub new {
    my $self = shift;
    my $param = shift;
    my $appid = $param->{appid};
    my $version = 'v1';
    my $url = 'http://asia.search.yahooapis.com/cas/';
    my $request = "$url.$version/";
    bless ( { 
	    version => $version, 
	    url => $url, 
	    appid => $appid,
	    request => $request }, 
	$self);
}

sub ws {
    my $self= shift;
    my $param = shift;
    my $content = $param->{content};
    my $request = { url => $self->{request}."ws", content => $content };
    my $response = XMLin($self->_get($request));
    if (exists($response->{WordSegmentationResult})) {
	return $response->{WordSegmentationResult};
    } else {
	return 0;
    }
}

sub ke {
    my $self= shift;
    my $param = shift;
    my $content = $param->{content};
    my $threshold = $param->{threshold};
    my $maxnum = $param->{maxnum};
    my $request = { url => $self->{request}."ke", content => "content=$content&threshold=$threshold&maxnum=$maxnum" };
    my $response = XMLin($self->_get($request));
    if (exists($response->{KeywordExtractionResult})) {
	return $response->{KeywordExtractionResult};
    } else {
	return 0;
    }
}

sub _get {
    my $self = shift;
    my $request = shift;
    my $req = HTTP::Request->new(POST => $request->{url});
    $req->content_type('application/x-www-form-urlencoded');
    $req->{content} = $request->{content}."&appid=".$self->{appid};
    my $res = $req->request($req);
    if ($res->is_success) {
	return $res->content;
    } else {
	return $res->status_line;
    }
}


1;

__END__

=head1 NAME

Yahoo::CAS is a simple interface for Yahoo! Asia keyword segment and TVS open APIs. 

=head1 VERSION

This document describes version 0.1 of Yahoo::CAS , released 
January 16, 2008.

=head1 SYNOPSIS

use Yahoo::CAS;

$cas = Yahoo::CAS({ appid => "Ea6oQPHIkY03GklWeauQHWPpPJByMjCDoxRxcW"});
$res = $cas->ws({content => '..........');
$list = $cas->ke({thredhold => '30', maxnum => '10', content => '...');
print $res->{token} for (keys %{$Segment});
print $res->{token} for (keys %{$Keyword});

=head1 DESCRIPTION

Yahoo! Asia provides open APIs for segment and keyword extract for an article. The ws is for segment and the ke is for the concept extract of article. So you just need to apply the appid and then you can use it very easy. 

=head1 METHODS

For more methods, please just refer the Yahoo! Developers Network in Taiwan. E<lt>http://tw.developer.yahoo.com/cas/api.phpE<gt> 

=head1 AUTHORS

Hsin-Chan Chien E<lt>hcchien@hcchien.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 by Hsin-Chan Chien E<lt>hcchien@hcchien.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

