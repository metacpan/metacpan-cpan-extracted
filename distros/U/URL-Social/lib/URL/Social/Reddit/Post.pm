package URL::Social::Reddit::Post;
use Moose;
use namespace::autoclean;

has 'author'         => ( isa => 'Str', is => 'ro', required => 1, default => '' );
has 'created'        => ( isa => 'Num', is => 'ro', required => 1, default =>  0 );
has 'created_utc'    => ( isa => 'Num', is => 'ro', required => 1, default =>  0 );
has 'domain'         => ( isa => 'Str', is => 'ro', required => 1, default => '' );
has 'upvote_count'   => ( isa => 'Int', is => 'ro', required => 1, default =>  0 );
has 'downvote_count' => ( isa => 'Int', is => 'ro', required => 1, default =>  0 );
has 'comment_count'  => ( isa => 'Int', is => 'ro', required => 1, default =>  0 );
has 'score'          => ( isa => 'Int', is => 'ro', required => 1, default =>  0 );
has 'subreddit'      => ( isa => 'Str', is => 'ro', required => 1, default => '' );
has 'permalink'      => ( isa => 'Str', is => 'ro', required => 1, default => '' );
has 'title'          => ( isa => 'Str', is => 'ro', required => 1, default => '' );

__PACKAGE__->meta->make_immutable;

1;