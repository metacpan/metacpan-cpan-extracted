package Text::Xatena::Inline::Aggressive;

use strict;
use warnings;
use URI::Escape;
use LWP::Simple qw($ua);
use HTML::Entities;
use Text::Xatena::Inline -Base;

sub cache { $_[0]->{cache} }
sub ua    { $_[0]->{ua} || $ua }

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{aggressive} = 1;
    $self;
}

sub title_of {
    my ($self, $uri) = @_;
    my $res = $self->ua->get($uri);
    if ($res->is_success) {
        my ($title) = ($res->decoded_content =~ qr|<title[^>]*>([^<]*)</title>|i);
        $title;
    } else {
        $res->status_line;
    }
}

1;
__END__



