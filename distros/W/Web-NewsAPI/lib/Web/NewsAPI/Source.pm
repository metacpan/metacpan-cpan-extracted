package Web::NewsAPI::Source;

use v5.10;
use Moose;

use Web::NewsAPI::Types;

has 'id' => (
    required => 1,
    isa => 'Maybe[Str]',
    is => 'ro',
);

has 'name' => (
    required => 1,
    isa => 'Str',
    is => 'ro',
);

has 'description' => (
    isa => 'Str',
    is => 'ro',
);

has 'category' => (
    isa => 'Str',
    is => 'ro',
);

has 'language' => (
    isa => 'Str',
    is => 'ro',
);

has 'country' => (
    isa => 'Str',
    is => 'ro',
);

has 'url' => (
    coerce => 1,
    isa => 'NewsURI',
    is => 'ro',
);

1;

=head1 NAME

Web::NewsAPI::Source - Object class representing a News API source

=head1 SYNOPSIS

 use v5.10;
 use Web::NewsAPI;

 my $newsapi = Web::NewsAPI->new(
    api_key => $my_secret_api_key,
 );

 say "Here are some sources for English-language science news...";
 my @sources = $newsapi->sources(
    category => 'science',
    language => 'en'
 );
 for my $source ( @sources ) {
    say $source->name;
    if ( defined $source->id ) {
        say "...it has the NewsAPI ID " . $source->id;
    }
    else {
        say "...but it doesn't have a NewsAPI ID.";
    }
 }

=head1 DESCRIPTION

Objects of this class represent a News API news source. Generally, you
won't create these objects yourself; you'll get them as a result of
calling L<sources() on a Web::NewsAPI object|Web::NewsAPI/"sources">.

=head1 METHODS

=head2 Object attributes

These are all read-only attributes, based on information provided by
News API. They are all strings, except for C<url>, which is a L<URI>
object. Any of them might be undefined, except for C<name>.

=over

=item *

id

=item *

name

=item *

description

=item *

url

=item *

category

=item *

language

=item *

country

=back

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)
