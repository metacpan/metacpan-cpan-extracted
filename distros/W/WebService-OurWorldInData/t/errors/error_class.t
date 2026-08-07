use Test2::V0;

use WebService::OurWorldInData::Error;

ok my $error = WebService::OurWorldInData::Error->new(
    error => 'Invalid something parameter',
    details => 'hitsPerPage must be between 1 and 100',
), 'Can create an Error';

is $error, object {
    prop isa => 'WebService::OurWorldInData::Error';

    field error   => match qr/^Invalid \w+ parameter/;
    field details => 'hitsPerPage must be between 1 and 100';

    end();
}, 'Error object correct';


done_testing();
