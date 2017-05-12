use warnings;

package WebService::LOC::CongRec::DayTest;
use base 'WebService::LOC::CongRec::TestBase';
use WebService::LOC::CongRec::Day;

use DateTime;
use Test::More;
use WWW::Mechanize;

sub setup : Test(setup) {
    my ($self) = @_;
    $self->{'mech'} = WWW::Mechanize->new();
};

sub getURL_correctCongress : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->{'mech'},
            date    => DateTime->new(year => 2010, month => 9, day => 16),
            house   => 's',
    );

    like($day->getURL(), qr/B\?r111/);
};

sub getURL_correctHouse : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->{'mech'},
            date    => DateTime->new(year => 2010, month => 9, day => 16),
            house   => 's',
    );

    like($day->getURL(), qr/\@FIELD\(FLD003\+s\)/);
};

sub getURL_correctDate : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->{'mech'},
            date    => DateTime->new(year => 2010, month => 9, day => 16),
            house   => 's',
    );

    like($day->getURL(), qr/\@FIELD\(DDATE\+20100916\)/);
};

sub getPages_usesPassedMech : Test(2) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $firstURL = 'http://www.iana.org/domains/example/';
    $mech->get($firstURL);

    # http://thomas.loc.gov/cgi-bin/query/B?r111:@FIELD(FLD003+s)+@FIELD(DDATE+20101001)
    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->{'mech'},
            date    => DateTime->new(year => 2010, month => 10, day => 1),
            house   => 's',
    );

    $day->_build_pages();

    like($mech->uri(), qr/thomas.loc.gov/);
    $mech->back();
    like($mech->uri(), qr#http://www.iana.org/domains/example/#);
};

sub _build_pages_correctNumber : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    # http://thomas.loc.gov/cgi-bin/query/B?r111:@FIELD(FLD003+s)+@FIELD(DDATE+20101001)
    my $day = WebService::LOC::CongRec::Day->new(
            mech    => $self->{'mech'},
            date    => DateTime->new(year => 2010, month => 10, day => 1),
            house   => 's',
    );

    my @pages = @{$day->_build_pages()};

    is($#pages + 1, 3);
};

1;
