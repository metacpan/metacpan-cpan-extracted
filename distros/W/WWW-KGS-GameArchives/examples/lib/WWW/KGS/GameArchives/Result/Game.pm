package WWW::KGS::GameArchives::Result::Game;
use Moo;
use Time::Piece;
use WWW::KGS::GameArchives::Result::User;

has kifu_uri => (
    is => 'ro',
    predicate => 'is_viewable',
);

has editor => (
    is => 'ro',
    coerce => sub { WWW::KGS::GameArchives::Result::User->new($_[0]) },
    predicate => 1,
);

has [qw/white black/] => (
    is => 'ro',
    predicate => 1,
    coerce => sub {
        my $users = shift;
        [ map { WWW::KGS::GameArchives::Result::User->new($_) } @$users ];
    },
);

has size => ( is => 'ro', required => 1 );

has handicap => ( is => 'ro', predicate => 1 );

has start_time => (
    is => 'ro',
    coerce => sub { gmtime->strptime($_[0], '%D %I:%M %p') },
    required => 1,
);

has type => ( is => 'ro', required => 1 );

has result => ( is => 'ro', required => 1 );

has tag => ( is => 'ro', predicate => 1 );

sub BUILDARGS {
    my $self = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $setup = delete $args{setup};
    my ( $size, $handicap ) = $setup =~ /^(\d+)\x{d7}\d+ (?:H(\d+))?$/;
    $args{handicap} = $handicap if $handicap;
    $args{size} = $size;
    \%args;
}

1;
