package WWW::Scraper::ISBN::Test_Driver;

use base qw(WWW::Scraper::ISBN::Driver);

sub search {
    my $self = shift;
    my $isbn = shift;

    if($isbn eq '9780987654328') {
        $self->found(0);
        $self->book(undef);
        return;
    }

    if($isbn eq '9790571239589') {
        $self->handler('Website unavailable');
        return;
    }

    my $bk = {
        isbn    => $isbn,
        title   => 'test title',
        author  => 'test author'
    };

    $self->book($bk);
    $self->found(1);
    return $self->book;
}

1;
