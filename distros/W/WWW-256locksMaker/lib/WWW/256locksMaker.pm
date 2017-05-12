package WWW::256locksMaker;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";
our $ENDPOINT_URL = 'http://maker-256locks.herokuapp.com/name';

use URI;
use Furl;
use Imager;
use Class::Accessor::Lite (
    new => 1,
    ro => [qw[image_url tweet_link image]],
);

my $furl = Furl->new(agent => __PACKAGE__.'/'.$VERSION);

sub make {
    my ($class, $str) = @_;
    my $uri = URI->new($ENDPOINT_URL);
    $uri->query_form(name => $str);
    my $res = $furl->get($uri->as_string);
    unless ($res->is_success) {
        warn sprintf('remote server(%s) said : %s', $uri->host, $res->status_line);
        return;
    }
    my $image_url = $class->get_image_url($res->content);
    my $tweet_link = $class->get_tweet_link($res->content);
    my $image = do{ 
        my $r = $furl->get($image_url); 
        $r->is_success ? Imager->new(data => $r->content) : undef;
    };
    return $class->new(
        image_url => $image_url,
        tweet_link => $tweet_link,
        image => $image,
    );
}

sub get_image_url {
    my ($class, $content) = @_;
    my ($url) =  $content =~ /<div id="image"><img src="(.+?)"><\/div>/;
    return $url;
}

sub get_tweet_link {
    my ($class, $content) = @_;
    my ($url) = $content =~ /<a id="tweets" href="(.+?)">/;
    return $url;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::256locksMaker - Perl Interface of 256locks maker (http://maker-256locks.herokuapp.com/)

=head1 SYNOPSIS

    use WWW::256locksMaker;
    my $nigolox = WWW::256locksMaker->make('yourname');
    printf("image_url:%s tweet_link:%s\n", $nigolox->image_url, $nigolox->tweet_link);
    
    ### image method returns Imager object.
    $nigolox->image->write(file => '/path/to/somefile.png');

=head1 DESCRIPTION

WWW::256locksMaker is a perl interface of 256locks maker.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

