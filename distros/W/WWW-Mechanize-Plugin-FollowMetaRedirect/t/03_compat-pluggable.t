use strict;
use warnings;
use Test::More;
use URI::file;

eval "use WWW::Mechanize::Pluggable";
if( $@ ){
    plan skip_all => "we don't have WWW::Mechanize::Pluggable";
}
else{
    use_ok( 'WWW::Mechanize::Pluggable' );
    can_ok( 'WWW::Mechanize', 'follow_meta_redirect' );

    my $mech = WWW::Mechanize::Pluggable->new;
    my $uri = URI::file->new_abs("t/assets/meta_format_01.html")->as_string;

    # load initial page
    $mech->get( $uri );
    ok( $mech->success, "Fetched: $uri" ) or die "cannot load test html!";

    # follow
    ok( $mech->follow_meta_redirect( ignore_wait => 1 ), "follow meta refresh link" );

    # check
    ok( $mech->is_html, "is html" );
    ok( $mech->content =~ /test ok\./, "result html" );
}

done_testing;

__END__