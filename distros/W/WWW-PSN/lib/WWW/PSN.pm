package WWW::PSN;

use Exporter 'import';
@EXPORT = qw/profile trophies/;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;

use constant ORIGIN            => 'https://www.playstation.com';
use constant IO                => 'https://io.playstation.com';
use constant URL_USER_DATA     => '/playstation/psn/profile/public/userData';
use constant URL_TROPHIES_API  => '/playstation/psn/public/trophies/';
use constant URL_TROPHIES_PAGE => '/en-us/my/public-trophies/';
use constant UA_OSX_CHROME =>
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5)'
    . ' AppleWebKit/537.36 (KHTML, like Gecko)'
    . ' Chrome/51.0.2704.103 Safari/537.36';

sub profile {
    my $id = shift;
    return psn_get( URL_USER_DATA, $id );

}

sub trophies {
    my $id = shift;
    return psn_get( URL_TROPHIES_API, $id );
}

sub psn_get {
    my ( $url, $id ) = @_;
    my $headers = {
        'User-Agent' => UA_OSX_CHROME,
        'Referer'    => ORIGIN . URL_TROPHIES_PAGE,
    };

    $url = IO . $url . "?onlineId=$id";
    my $response = HTTP::Tiny->new->get( $url, { 'headers' => $headers } );
    die "Unable to open >$url<. :(\n" unless $response->{success};
    my $json_data = $response->{content};
    $json_data =~ s/^\s+|\s+$//g;
    return JSON::decode_json($json_data);
}

1;

=pod

=encoding UTF-8

=head1 NAME

WWW::PSN - Perl Module for fetching PSN profile and trophy data.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use WWW::PSN;
    my $profile = profile('hajimuc'); # replace hajimuc with your PSN ID.
    print "Current Level: $profile->{'curLevel'}\n";

    # print all the titles
    my $detailed_trophies = trophies('hajimuc');
    for my $t ( @{$detailed_trophies->{list}} ) {
        print encode('utf-8',$t->{title}), "\n";
    }

=head1 DESCRIPTION

C<WWW::PSN> is Perl Module for fetching PSN profile and trophy data.

=head1 METHODS

=head2 profile($psn_id)

User profile including overall trophy progress and numbers.

    {
       "isPlusUser" : "1",
       "curLevel" : "4",
       "handle" : "hajimuc",
       "progress" : "90",
       "avatarUrl" : "//static-resource.np.community.playstation.net/avatar_m/WWS_J/J0003_m.png",
       "trophies" : {
          "bronze" : "98",
          "silver" : "15",
          "gold" : "4",
          "platinum" : "0"
       },
       "totalLevel" : ""
    }

=head2 trophies($psn_id)

Detailed trophies data.

    {
       "overallprogress" : "90",
       "isPlusUser" : "1",
       "avatarUrl" : "//static-resource.np.community.playstation.net/avatar_m/WWS_J/J0003_m.png",
       "handle" : "hajimuc",
       "curLevel" : "4",
       "totalResults" : "15",
       "list" : [
          {
             "title" : "Far Cry® Primal",
             "imgUrl" : "//trophy01.np.community.playstation.net/trophy/np/NPWR09687_00_0090890723F98AD458C3F4EC288C1888A48F880D21/08B0C827B453E9D45ED0DCBE0CB6FFA59BFFD53E.PNG",
             "progress" : 85,
             "platform" : "ps4",
             "gameId" : "NPWR09687_00",
             "trophies" : {
                "silver" : 9,
                "bronze" : 30,
                "gold" : 2,
                "platinum" : 0
             }
          }
        ]
    }

=head1 AUTHOR

Zhu Sheng Li <zshengli@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Zhu Sheng Li.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__

# ABSTRACT: Perl Module for fetching PSN profile and trophy data.

