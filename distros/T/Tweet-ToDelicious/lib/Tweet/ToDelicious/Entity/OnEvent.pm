package Tweet::ToDelicious::Entity::OnEvent;

use v5.14;
use warnings;
use parent 'Tweet::ToDelicious::Entity::Interface';
use Class::Accessor::Lite ( new => 1 );

use constant STATUS_FORMAT => 'https://twitter.com/#!/%s/status/%s';

sub screen_name { $_[0]->{source}->{screen_name} }
sub text        { $_[0]->{target_object}->{text} }
sub is_favorite { $_[0]->{event} && $_[0]->{event} eq 'favorite' }
sub tags        {qw/favorite via:tweet2delicious/}

sub in_reply_to_screen_name {
    $_[0]->{target_object}->{in_reply_to_screen_name};
}

sub urls {
    my $self = shift;
    sprintf STATUS_FORMAT, $self->{target_object}->{user}->{screen_name},
        $self->{target_object}->{id_str};
}

sub posts {
    my $self = shift;
    my ($url) = $self->urls;
    return {
        url => $url,
        tags        => join( ',', $self->tags ),
        description => $self->text,
        replace     => 1,
    };
}
1;
