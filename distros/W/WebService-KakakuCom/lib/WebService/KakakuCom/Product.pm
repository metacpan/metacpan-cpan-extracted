package WebService::KakakuCom::Product;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

my @Fields = qw/ProductID ProductName MakerName CategoryName PvRanking ImageUrl ItemPageUrl BbsPageUrl ReviewPageUrl LowestPrice NumOfBbs ReviewRating/;

__PACKAGE__->mk_accessors(@Fields);

sub new {
    my $class = shift;
    my $self = bless $class->SUPER::new(@_), $class;
    $self->init(@_);
    $self;
}

sub init {
    my $self = shift;
    $self->$_(URI->new($self->$_)) for grep { m/Url$/ } @Fields;
}

1;
