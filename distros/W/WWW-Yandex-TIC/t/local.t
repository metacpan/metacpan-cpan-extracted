#!perl -w

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use WWW::Yandex::TIC; 
my $ytic = new WWW::Yandex::TIC;

# use HTTP::Headers;

# my $headers = HTTP::Headers->new;
# $headers->header ('Accept-Charset' => 'utf-8;q=0.7,*;q=0.7');

# $ytic->user_agent->default_headers ($headers);

my ($tic, $resp) = $ytic->get('www.yandex.ru');

ok($tic);

# warn $resp->content;

exit;
__END__
