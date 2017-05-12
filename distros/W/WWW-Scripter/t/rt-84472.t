#!/usr/bin/env perl

use strict;
use warnings;

use lib 't';
use HTTP::Response ();
use WWW::Scripter ();

my $w = WWW::Scripter->new( autocheck => 1 );

for (
    [ 'R1' => \'fake:///R2'                                              ],
    [ 'R2' => '<script>document.location.replace("fake:///R3")</script>' ],
    [ 'R3' => 'DESIRED CONTENT'                                          ],
) {
    my ($req_path, $res_data) = @$_;
    my $is_redir = ref $res_data;
    require HTTP::Config; # probably loaded already, but just in case
    # Suppress bogus uninit warning in older HTTP::Config versions
    local $SIG{__WARN__} =
        sub { return if $_[0] =~ /uninitialized/; warn $_[0] }
      if HTTP::Config->VERSION < 6.09;
    $w->set_my_handler(
        'request_send',
        sub {
            my $req = shift;
            my $res = HTTP::Response->new( $is_redir ? 302 : 200 );
            $res->request($req);
            if ($is_redir) {
                $res->header( 'Location' => $$res_data );
            }
            else {
                $res->header( 'Content-Type' => 'text/html' );
                $res->content($res_data);
            }
            return $res;
        },
        ( m_scheme => 'fake', m_path => "/${req_path}" ),
    );
}

use tests 3;
SKIP: {
    skip 'tests require WWW::Scripter::Plugin::JavaScript', 3
        if not eval { require WWW::Scripter::Plugin::JavaScript; 1 };
    $w->use_plugin('JavaScript');

    $w->get('fake:///R3');
    like $w->content, qr/DESIRED CONTENT/,
         "'content' method must return desired content";

    $w->get('fake:///R2');
    like $w->content, qr/DESIRED CONTENT/,
         "'content' method must return desired content";

    $w->get('fake:///R1');
    like $w->content, qr/DESIRED CONTENT/,
         "'content' method must return desired content";
}
