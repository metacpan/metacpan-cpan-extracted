#!/usr/bin/perl
use strict;
use WWW::NicoVideo::Download;
use Term::ProgressBar;

my($email, $password, $video_id) = @ARGV;

my($term, $fh);

my $client = WWW::NicoVideo::Download->new( email => $email, password => $password );
$client->download($video_id, \&cb);

sub cb {
    my($data, $res, $proto) = @_;

    unless ($term && $fh) {
        my $ext = (split '/', $res->header('Content-Type'))[-1] || "flv";
        open $fh, ">", "$video_id.$ext" or die $!;
        $term = Term::ProgressBar->new( $res->header('Content-Length') );
    }

    $term->update( $term->last_update + length $data );
    print $fh $data;
}
