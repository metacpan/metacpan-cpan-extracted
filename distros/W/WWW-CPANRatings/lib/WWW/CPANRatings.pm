package WWW::CPANRatings;
use strict;
use warnings;
our $VERSION = '0.03';
use utf8;
use List::Util qw(sum);
use LWP::UserAgent;
use DateTime::Format::DateParse;
use HTML::TokeParser::Simple;
use URI;
use Web::Scraper;
use JSON::XS;
use Text::CSV_PP;
use feature 'say';

sub new { 
    my $class = shift;
    my $args = shift || {};
    my $self = bless $args,$class;
    $self->setup_request(sub{
        my $url = shift;
        my $ua = LWP::UserAgent->new;
        my $response = $ua->get( $url );
        return $response->decoded_content;
    });
    return $self;
}

sub setup_request {
    my ($self,$cb) = @_;
    $self->{requester} = $cb;
}

sub request {
    my ($self,$url) = @_;
    return $self->{requester}->( $url );
}

sub fetch_ratings {
    my $self = shift;
    my $arg = shift;

    # if it's file
    my $text;
    if( $arg && -e $arg ) {
        open my $fh , "<" , $arg;
        local $/;
        $text = <$fh>;
        close $fh;
    }
    elsif( $arg && $arg =~ /^http/ ) {
        $text = get( $arg );
    }

    unless ( $text ) {
        $text = $self->request('http://cpanratings.perl.org/csv/all_ratings.csv');
    }

    my @lines = split /\n/,$text;
    my $csv = Text::CSV_PP->new();     # create a new object

    # drop first 2 lines
    splice @lines,0,2;
    my %rating_data;

    for my $line ( @lines ) {
        chomp($line);
        my $status  = $csv->parse($line);
        die 'csv file parse failed.' unless $status;
        my ($dist,$rating,$review_count) = $csv->fields();

        # say $dist, $rating, $review_count;
        $rating_data{ $dist } = {
            dist => $dist,
            rating => $rating,
            review_cnt => $review_count,
        };
    }
    return $self->{rating_data} = \%rating_data;
}

sub rating_data { 
    my $self = shift;
    $self->fetch_ratings unless $self->{rating_data};
    return $self->{rating_data};
}

sub get_ratings {
    my ($self,$distname) = @_;
    $distname =~ s/::/-/g;
    return $self->rating_data->{ $distname };
}

# dist_name format 
sub get_reviews {
    my ($self,$modname) = @_;
    my $distname = $modname;
    $distname =~ s/::/-/g;
    my $base_url = "http://cpanratings.perl.org/dist/";
    my $url = $base_url . $distname;
    my $content = $self->request($url);
    return unless $content;
    return unless $content =~ /$modname reviews/;
    my $result = $self->parse_review_page($content);
    return @{ $result->{reviews} };
}


# returned structure,
#     $VAR1 = {
#        'reviews' => [
#                 {
#                   'body' => ' Moose got me laid. Could you ask anything more of a CPAN module? ',
#                   'user_link' => bless( do{\(my $o = 'http://cpanratings.perl.org/user/funguy')}, 'URI::http' ),
#                   'attrs' => 'Fun Guy - 2011-04-12T14:30:46 ',
#                   'user' => 'Fun Guy',
#                   'dist' => ' Moose',
#                   'dist_link' => bless( do{\(my $o = 'http://search.cpan.org/dist/Moose/')}, 'URI::http' )
#                 },



sub rating_scraper { 
    my $self = shift;
    return scraper {
        process '.review' => 'reviews[]' => scraper {
            process '.review_header a', 
                    dist_link => '@href',
                    dist => 'TEXT';

            process '.review_header',
                    header => 'TEXT';

            process '.review_header img',
                    ratings => '@alt';

            process '.review_text', body => 'TEXT';

            process '.review_attribution' ,
                'attrs' => 'TEXT';
            process '.review_attribution a' , 
                'user' => 'TEXT',
                'user_link' => '@href';
        };
    };
}

sub parse_review_page {
    my ($self,$content) = @_;

    my $rating_scraper = $self->rating_scraper;
    my $res = $rating_scraper->scrape( $content );

    # post process

    for my $review ( @{ $res->{reviews} } ) {
        if( $review->{header} =~ m{^\s*([a-zA-Z:]+)\s+\(([0-9.]+)\)\s*$} ) {
            $review->{version} = $2;
        }

        $review->{dist} =~ s{^\s*}{};
        $review->{dist} =~ s{\s*$}{};

        if( $review->{attrs} =~ m{([0-9-T:]+)\s*$} ) {
            $review->{created_on} = 
                DateTime::Format::DateParse->parse_datetime( $1 );
        }

        delete $review->{attrs};
    }
    return $res;
}


sub get_all_reviews {
    my $self = shift;
    my $all_ratings = $self->rating_data;
    while( my( $distname,$ratings) = each %$all_ratings ) {
        # $ratings->{review_cnt};
        # $ratings->{dist};
        # $ratings->{rating};
        $ratings->{reviews} = [ $self->get_reviews( $ratings->{dist} ) ];
    }
    return $all_ratings;
}

1;
__END__

=head1 NAME

WWW::CPANRatings - parsing CPANRatings data

=head1 SYNOPSIS

    use WWW::CPANRatings;

    my $r = WWW::CPANRatings->new;

    my $all_ratings = $r->rating_data;  # get rating data.

    my $ratings = $r->get_ratings( 'Moose' );  # get Moose rating scores.

    my @reviews = $r->get_reviews( 'Moose' );  # parse review text from cpanratings.perl.org.




    for my $r ( @reviews ) {
        $r->{dist};
        $r->{dist_link};
        $r->{version}
        $r->{user};
        $r->{user_link};
        $r->{created_on};  # DateTime object.
        $r->{ratings};
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 $r->fetch_ratings()

Download/Parse csv rating data.

=head2 AllRatingData | HashRef = $r->rating_data()

Get csv rating data.

=head2 RatingData | HashRef = $r->get_ratings( DistName | String )

Get rating data of a distribution

=head2 Reviews | Array = $r->get_reviews( DistName | String )

Get distribution reviews (including text, user, timestamp)

=head2 $r->get_all_reviews

Get reviews from all distributions.

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<WWW::CPANRatings::RSS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
