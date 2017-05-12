package WWW::KGS::GameArchives::Result::User;
use Moo;

has name => ( is => 'ro', required => 1 );

has rank => ( is => 'ro', predicate => 1 );

has link => ( is => 'ro', required => 1 );

# http://www.gokgs.com/help/rank.html
sub BUILDARGS {
    my $self = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my ( $name, $rank ) = $args{name} =~ /^(\w+)(?: \[(-|\?|\d+[kdp])\??\])?$/;
    $args{rank} = $rank if $rank;
    $args{name} = $name;
    \%args;
}

1;
