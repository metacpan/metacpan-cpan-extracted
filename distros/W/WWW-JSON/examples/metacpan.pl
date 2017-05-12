#!/usr/bin/env perl
use WWW::JSON;
use Data::Dumper;

# /v0/release/_search?q=author:MSTROUT&filter=status:latest&fields=name&size=5
my $wj = WWW::JSON->new(
    base_url => 'http://api.metacpan.org/v0?fields=name,distribution&size=1',
    post_body_format           => 'JSON',
    default_response_transform => sub { shift->{hits}{hits}[0]{fields} },
);

my $get = $wj->get(
    '/release/_search',
    {
        q      => 'author:ANTIPASTA',
        filter => 'status:latest',
    }
);
if ($get->success) {
    warn "DISTRIBUTION: " . $get->res->{distribution} ;
} else {
    warn $get->error;
}


my $post = $wj->post(
    '/release/_search',
    {

        filter => {
            term => {
                'release.dependency.module' => 'Moo',
            }
        },
        size => 1
    }
);
warn "DISTRIBUTION: " . $get->res->{distribution} unless $get->success;
warn "Status is " . $post->status_line;
warn "Request URL is " . $post->url;
warn "Content is " . Dumper( $post->res );
