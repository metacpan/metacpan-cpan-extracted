use strict;
use warnings;
use utf8;

use Test::More;
use WWW::Asg;

my %expects = (
    '2012.01.12 10:50'              => '2012-01-12T10:50:00',
    ' 12.01.12 10:50 '              => '2012-01-12T10:50:00',
    'aaa2012.01.12 10:50bbb'        => '2012-01-12T10:50:00',
    '2012-01-12T10:50:00Z'          => '2012-01-12T10:50:00',
    '2012-01-12T10:50:00Zあああ' => '2012-01-12T10:50:00',
    ' 2012-01-12T10:50:00Z '        => '2012-01-12T10:50:00',
);

my $asg = WWW::Asg->new;

foreach my $date_str ( keys %expects ) {
    my $date = $asg->_date($date_str);
    is $date, $expects{$date_str};
}

done_testing();
