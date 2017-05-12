package Yahoo::Answers;

=head1 NAME

Yahoo::Answers - The great new Yahoo::Answers!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Yahoo::Answers;
	use Data::Dumper;

    my $ya = Yahoo::Answers->new(
        query   => 'teste',
        results => 50,
        sort    => 'date_desc',
        appid =>
'9J_NabHV34Fuzb1qIdxpKfQdBmV6eaMGeva5NESfQ7IDCupidoKd_cSGK7MI5Xvl.eLeQKd9YkPOU0M4DsX73A--'
    );

    $ya->region_by_name('Brazil');
    my $struct = $ya->get_search;
    if ( $ya->has_error ) {
        die( Dumper $ya->error );
    }
    else {
        print Dumper $struct;
    }

=cut

use Moose;
use Moose::Util::TypeConstraints;

use MooseX::Types::Common::String qw/NonEmptySimpleStr SimpleStr/;
use MooseX::Types::Common::Numeric qw/PositiveInt SingleDigit/;

use WWW::Mechanize;
use URI::QueryParam;
use URI;
use JSON;

has 'mechanize' => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    lazy    => 1,
    default => sub {
        my $self = shift;
        WWW::Mechanize->new(
            onerror => sub { $self->error("@_"), timeout => 120 } );
    }
);

has 'url' => (
    is      => 'rw',
    isa     => 'Object',
    default => sub {
        URI->new(
            'http://answers.yahooapis.com/AnswersService/V1/questionSearch');
    }
);

has 'query' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_query'
);

subtype 'Search_in' => as Str => where { /^all$|^question$|^best_answer$/ };
has 'search_in' => (
    is        => 'rw',
    isa       => 'Search_in',
    default   => 'all',
    lazy      => 1,
    predicate => 'has_search_in'
);

has 'category_id' =>
  ( is => 'rw', isa => PositiveInt, predicate => 'has_category_id' );

has 'category_name' =>
  ( is => 'rw', isa => SimpleStr, predicate => 'has_category_name' );

subtype 'Region' => as Str => where {
    /^us$|^uk$|^ca$|^au$|^in$|^es$|^br$|^ar$|^mx$|^e1$|^it$|^de$|^fr$|^sg$/x;
};
has 'region' => (
    isa       => 'rw',
    isa       => 'Region',
    predicate => 'has_region',
);

=head2 region_by_name

With this, you can pass the country name, not the "us,uk" you can
literary write the country name. The countrys are available here:

	United States
	United kingdom
	Canada
	Australia
	India
	Spain
	Brazil
	Argentina
	Mexico
	Italy
	Germany
	France
	Singapore

you can also search for only results in espanol with,

	En espanol

=cut

sub region_by_name {
    my ( $self, $region ) = @_;
    my %country = (
        'united states'  => 'us',
        'united kingdom' => 'uk',
        'canada'         => 'ca',
        'australia'      => 'au',
        'india'          => 'in',
        'spain'          => 'es',
        'brazil'         => 'br',
        'argentina'      => 'ar',
        'mexico'         => 'mx',
        'en espanol'     => 'e1',
        'italy'          => 'it',
        'germany'        => 'de',
        'france'         => 'fr',
        'singapore'      => 'sg'
    );

    if ( length($region) > 2 ) {
        $self->{'region'} = $country{ lc($region) }
          || die "There is no region with the name: {$region}";
    }
}

subtype 'Date_Range' => as Str => where { /all|\d|\d\-\d|more\d/ };
has 'date_range' => (
    is        => 'rw',
    isa       => 'Date_Range',
    default   => 'all',
    lazy      => 1,
    predicate => 'has_date_range'
);

subtype 'Sort' => as Str => where { /relevance|date_desc|date_asc/ };
has 'sort' => (
    is        => 'rw',
    isa       => 'Sort',
    default   => 'relevance',
    lazy      => 1,
    predicate => 'has_sort'
);

# You can see more information at,
# http://developer.yahoo.com/faq/index.html#appid

has 'appid' => (
    is        => 'rw',
    isa       => NonEmptySimpleStr,
    required  => 1,
    predicate => 'has_appid'
);

subtype 'Search_Type',
  as Str => where { /^all$|^resolved$|^open$|^undecided$/ };
has 'search_type' => ( is => 'rw', isa => 'Type_', predicate => 'has_type' );

has 'start' => ( is => 'rw', isa => PositiveInt, predicate => 'has_start' );

subtype Results => as Int => where { $_[0] <= 50 };
has 'results' => ( is => 'rw', isa => 'Results', predicate => 'has_results' );

has 'output' => ( is => 'ro', isa => NonEmptySimpleStr, default => 'json' );

=head2 url_builder

Build the URL to do the "get" with all arguments that you pass
for the attributes.

=cut

sub url_builder {
    my $self = shift;
    for my $acr (
        'query',       'search_in',  'category_id', 'category_name',
        'region',      'date_range', 'sort',        'appid',
        'search_type', 'start',      'results',     'output'
      )
    {
        $self->url->query_param( $acr => $self->{$acr} ) if $self->{$acr};
    }
}

=head2 get_search

Make the search, and decode the JSON, if don't have the attribute
"query", it return nothing.

=cut

sub get_search {
    my $self = shift;
    my $json = JSON->new->allow_nonref;

    # if haven't "query" to search.
    return unless $self->has_query;

    if ( my $request = $self->request ) {
        my $content = $json->decode($request);
        $self->check_error($content);
        return $content;
    }
}

has 'error' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_error',
);

=head2 check_error

If have any error with your search, it sets the attribute error,
so you can see the error and check for errors.

=cut

sub check_error {
    my ( $self, $content ) = @_;
    if ( my $error = $content->{'Error'} ) {
        $self->error($error);
    }

    # - Clear the query
    $self->query(0);
    return 1;
}

=head2 request

Do the request, and return the content.

=cut

before 'request' => sub { shift->url_builder };

sub request {
    my $self = shift;
    $self->mechanize->get( $self->url );
    $self->mechanize->success
      ? return $self->mechanize->content
      : return;
}

=head1 AUTHOR

Daniel de O. Mantovani, C<< <daniel.oliveira.mantovani at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yahoo-ansewers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Yahoo-Answers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Yahoo::Answers


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Yahoo-Answers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Yahoo-Answers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Yahoo-Answers>

=item * Search CPAN

L<http://search.cpan.org/dist/Yahoo-Answers/>

=back


=head1 ACKNOWLEDGEMENTS

Thiago Rondon

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Aware (www.aware.com.br)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Yahoo::Answers
