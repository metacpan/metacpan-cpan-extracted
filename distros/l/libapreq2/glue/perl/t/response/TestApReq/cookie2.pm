package TestApReq::cookie2;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK);

use Apache2::Cookie ();

sub handler {
    my $r = shift;

    plan $r, tests => 5;

    {
        my $cookie = Apache2::Cookie->new($r, name => 'n', value => undef);
        ok t_cmp(
                 $cookie,
                 undef,
                 "value => undef return undef not a cookie"
				);
    }

    {
        my $cookie = Apache2::Cookie->new($r, name => 'n');
        ok t_cmp(
                 $cookie,
                 undef,
                 "no value attribute specified"
				);
    }

    {
        my $cookie = Apache2::Cookie->new($r, name => 'n', value => '');
        ok t_cmp(
                 $cookie,
                 "n=",
                 "'' returns a valid cookie object"
				);
    }

    {
        my $cookie = Apache2::Cookie->new($r, name => 'n', value => []);
        ok t_cmp(
                 $cookie,
                 "n=",
                 "value => [] returns a valid cookie object"
				);
    }

    {
        my $cookie = Apache2::Cookie->new($r, name => 'n', value => {});
        ok t_cmp(
                 $cookie,
                 "n=",
                 "value => {} returns a valid cookie object"
				);
    }



    return Apache2::Const::OK;
}

1;

__END__
