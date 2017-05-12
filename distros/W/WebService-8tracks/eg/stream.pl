use strict;
use warnings;
use lib 'lib';
use WebService::8tracks;
use AnyEvent::Util;
use Perl6::Say;
use Data::Dumper;

my $api = WebService::8tracks->new;
$api->user_agent->add_handler(
    request_send => sub {
        my ($request) = @_;
        say STDERR $request->method . ' ' . $request->uri;
        return undef;
    },
);

my $mix_id = shift or die "usage: $0 mix_id";

if ($mix_id =~ m(^[\w-]+/[\w-]+$)) {
    # Currently, 8tracks API does not provide way to get mix_id from 'user/mix-name'.
    my $res = $api->user_agent->get("http://8tracks.com/$mix_id");
    die $res->message if $res->is_error;
    ($mix_id) = $res->decoded_content =~ /data-mix_id="(\d+)"/ or die 'Could not parse response';
}

my $session = $api->create_session($mix_id);

while (1) {
    my $res = $session->next;
    die Dumper $res->{errors} if $res->{errors};

    if ($res->{set}->{at_end}) {
        say STDERR 'Reached at mix end';
        last;
    }

    my $track = $res->{set}->{track};
    say STDERR "$track->{name} / $track->{performer} ($track->{url})";

    my $media_url = $track->{url} or die 'Media URL not found';
    my $cv = run_cmd [ qw(ffmpeg -i), $media_url, qw(-f mp3 -) ], '2>' => sub { };

    my $exit_code = $cv->recv;
    die "ffmpeg exited with code $exit_code" if $exit_code != 0;
}

__END__

=pod

=head1 NAME

eg/stream.pl - Stream mix to stdout

=head1 SYNOPSIS

  % perl eg/stream.pl [user-id/mix-name or mix_id] | httpcat.pl --content-type audio/mp3 --port 12345

Listen to http://yourhost:12345/ with your music player.

Save https://gist.github.com/725025 as httpcat.pl.

You should have ffmpeg installed.

=head1 SEE ALSO

ffmpeg L<http://www.ffmpeg.org/>.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=cut
