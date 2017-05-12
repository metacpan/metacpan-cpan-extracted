use strict;
use warnings;
use lib 'lib';
use WebService::8tracks;
use Data::Dumper;

local $Data::Dumper::Indent = 1;

my %args;

if ($ENV{'EIGHTTRACKS_USERNAME'} && $ENV{'EIGHTTRACKS_PASSWORD'}) {
    %args = (
        username => $ENV{'EIGHTTRACKS_USERNAME'},
        password => $ENV{'EIGHTTRACKS_PASSWORD'},
    );
}

my $api = WebService::8tracks->new(%args);
$api->user_agent->show_progress(1);

if (my $res_file = $ENV{RECORD_RESPONSE}) {
    open my $fh, '>>', $res_file;

    $api->user_agent->add_handler(
        response_done => sub {
            my ($res, $ua, $h) = @_;
            my $req = $res->request;
            print $fh '@@ ', $req->method, ' ', $req->uri, "\n";
            print $fh $res->as_string, "\n";
        },
    );
}

my ($session, $result);

while (1) {
    local $| = 1;

    my $prompt = '8tracks';
    $prompt .= " [$session->{play_token}]" if $session;

    if ($result) {
        print "\e[32m" if $result->is_success;
        print "\e[31m" if $result->is_error;
    }

    print "$prompt> ";

    print "\e[m" if $result;

    my $line = <STDIN>;
    last unless defined $line;
    chomp $line;

    my ($method, @args) = split /\s+/, $line;

    $result = eval { ($session || $api)->$method(@args) };
    if ($@) {
        warn $@;
        next;
    }

    print +Dumper $result;

    if (ref $result eq 'WebService::8tracks::Session') {
        $session = $result;
        undef $result;
    }
    if ($session && $session->at_end) {
        undef $session;
    }
}

__END__

=pod

=head1 NAME

eg/cui.pl - Try API with console

=head1 SYNOPSIS

  % perl eg/cui.pl
  8tracks> user_mixes youpy
  ... [Response Dumped]
  8tracks> create_session 7063
  ... [Response Dumped]
  8tracks [470046627]> play
  ... [Response Dumped]
  8tracks [470046627]> next
  ... [Response Dumped]


=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=cut
