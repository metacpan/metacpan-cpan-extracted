use warnings;

package WebService::LOC::CongRec::PageTest;
use base 'WebService::LOC::CongRec::TestBase';
use WebService::LOC::CongRec::Page;

use Test::More;
use URI::file;
use WWW::Mechanize;

sub setup : Test(setup) {
    my ($self) = @_;

    my $testDir = WebService::LOC::CongRec::TestBase->getTestDir();
    $self->{'testFile'} = URI::file->new_abs($testDir . '/testHTML/20010912-Senate-02.html');
    $self->{'mech'} = WWW::Mechanize->new();
};

sub pageID : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $webPage = WebService::LOC::CongRec::Page->new(
            mech    => $self->{'mech'},
            url     => $self->{'testFile'}->as_string(),
    );

    is($webPage->pageID, 'S9283');
};

sub summary : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $webPage = WebService::LOC::CongRec::Page->new(
            mech    => $self->{'mech'},
            url     => $self->{'testFile'}->as_string(),
    );

    is($webPage->summary, 'PLEDGE OF ALLEGIANCE -- (Senate - September 12, 2001)');
};

sub content : Test(1) {
    my ($self) = @_;
    my $mech = $self->{'mech'};

    my $webPage = WebService::LOC::CongRec::Page->new(
            mech    => $self->{'mech'},
            url     => $self->{'testFile'}->as_string(),
    );

    my $expected = q/The Honorable
ROBERT C. BYRD
led the Pledge of Allegiance, as follows:
I pledge allegiance to the Flag of the United States of America and to the Republic for which it stands, one nation under God, indivisible, with liberty and justice for all.
/;
    is($webPage->content, $expected);
};

1;
