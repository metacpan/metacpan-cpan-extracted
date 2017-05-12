package WWW::Wordnik::API;

use warnings;
use strict;
use Carp;

use LWP::UserAgent;

use version; our $VERSION = qv('0.0.5');

use constant {
    API_VERSION  => 4,
    API_BASE_URL => 'http://api.wordnik.com',
    API_KEY      => 'YOUR KEY HERE',
    API_FORMAT   => 'json',
    CACHE        => 10,
    DEBUG        => 0,
    MODULE_NAME  => 'WWW::Wordnik::API',
    USE_JSON     => 0,
};

sub _fields {
    {   server_uri  => API_BASE_URL . q{/v} . API_VERSION,
        api_key     => API_KEY,
        version     => API_VERSION,
        format      => API_FORMAT,
        cache       => CACHE,
        debug       => DEBUG,
        _formats    => { json => 1, xml => 1, perl => 1 },
        _versions   => { 1 => 0, 2 => 0, 3 => 1, 4 => 1 },
        _cache      => { max => CACHE, requests => {}, data => [] },
        _user_agent => LWP::UserAgent->new(
            agent           => 'Perl-' . MODULE_NAME . q{/} . $VERSION,
            default_headers => HTTP::Headers->new( ':api_key' => API_KEY ),
        ),
        _json => USE_JSON,
    };
}

sub new {
    my ( $class, %args ) = @_;

    my $self = bless( _fields(), $class );

    eval { require JSON; JSON->import() };
    $self->{_json} = 'available' unless $@;

    bless $self, $class;

    while ( my ( $key, $value ) = each %args ) {
        croak "Can't access '$key' field in class $class"
            if !exists $self->{$key}
                or $key =~ m/^_/;

        $self->$key($value);
    }

    return $self;
}

sub server_uri {
    my ( $self, $uri ) = @_;

    if ( defined $uri ) {
        $self->{server_uri} = $uri;
    }
    return $self->{server_uri};
}

sub api_key {
    my ( $self, $key ) = @_;

    if ( defined $key ) {
        $self->{_user_agent}->default_headers->header( ':api_key' => $key );
        $self->{api_key} = $key;
    }
    return $self->{api_key};
}

sub version {
    my ( $self, $version ) = @_;

    if ( defined $version ) {
        croak "Unsupported api version: '$version'"
            unless $self->{_versions}->{$version};
        $self->{version} = $version;
    }
    return $self->{version};
}

sub format {
    my ( $self, $format ) = @_;

    if ( defined $format ) {
        croak "Unsupported api format: '$format'"
            unless $self->{_formats}->{$format};

        $self->_json_available
            if 'perl' eq $format;

        $self->{format} = $format;
    }
    return $self->{format};
}

sub cache {
    my ( $self, $cache ) = @_;

    if ( defined $cache and $cache =~ m/\d+/ ) {
        $self->{cache} = $self->{_cache}->{max} = $cache;
    }
    return $self->{cache};
}

sub debug {
    my ( $self, $debug ) = @_;

    if ( defined $debug ) {
        $self->{debug} = $debug;
    }
    return $self->{debug};
}

sub word {
    my ( $self, $word, %args ) = @_;

    return unless $word;

    my %parameters = (
        useSuggest => { true => 0, false => 1 },
        literal    => { true => 1, false => 0 },
    );

    for ( keys %args ) {
        croak "Invalid argument key or value: '$_'"
            unless exists $parameters{$_}
                and exists $parameters{$_}->{ $args{$_} };
    }

    my $query = $word;
    $query .= "?$_=$args{$_}" for keys %args;

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub phrases {
    my ( $self, $word, %args ) = @_;

    return unless $word;

    my %parameters = ( count => 10 );

    for ( keys %args ) {
        croak "Invalid argument key or value: '$_'"
            unless exists $parameters{$_}
                and $args{$_} =~ m/\d+/;
    }

    my $query = "$word/phrases";
    $query .= "?$_=$args{$_}" for keys %args;

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub definitions {
    my ( $self, $word, %args ) = @_;

    return unless $word;

    my %parameters = (
        count        => 5,
        partOfSpeech => {
            noun         => 0,
            verb         => 0,
            adjective    => 0,
            adverb       => 0,
            idiom        => 0,
            article      => 0,
            abbreviation => 0,
            preposition  => 0,
            prefix       => 0,
            interjection => 0,
            suffix       => 0,
        }
    );

    my $query = "$word/definitions";

    for ( keys %args ) {

        if ( 'count' eq $_ ) {
            croak "Invalid argument key or value: '$_'"
                unless $args{count} =~ m/\d/;
            $query .= "?count=$args{count}";
        }
        elsif ( 'ARRAY' eq ref $args{partOfSpeech} ) {
            for my $type ( @{ $args{partOfSpeech} } ) {
                croak "Invalid argument key or value: '$type'"
                    unless exists $parameters{partOfSpeech}->{$type};
            }
            $query .= "?partOfSpeech=" . join q{,}, @{ $args{partOfSpeech} };
        }
        else {
            croak "Parameter 'partOfSpeech' requires a reference to an array";
        }
    }

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub examples {
    my ( $self, $word ) = @_;

    return unless $word;

    my $query = "$word/examples";

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub related {
    my ( $self, $word, %args ) = @_;

    return unless $word;

    my %parameters = (
        type => {
            synonym           => 0,
            antonym           => 0,
            form              => 0,
            hyponym           => 0,
            variant           => 0,
            'verb-stem'       => 0,
            'verb-form'       => 0,
            'cross-reference' => 0,
            'same-context'    => 0,
        },
        limit => 1000,
    );

    my $query = "$word/related";
    $query .= '?' if keys %args;

    if ( exists $args{type} ) {
        if ( 'ARRAY' eq ref $args{type} ) {
            for my $type ( @{ $args{type} } ) {

                croak "Invalid argument key or value: '$type'"
                    unless exists $parameters{type}->{$type};
            }
            $query .= "type=" . join q{,}, @{ $args{type} };
        }
        else {
            croak "Parameter 'type' requires a reference to an array";
        }
    }

    if ( exists $args{limit} ) {
        if ( 0 >= $args{limit} ) {
            croak "Parameter 'limit' must be a positive number";
        }
        $query .= '&' if exists $args{type};
        $query .= "limit=$args{limit}";
    }

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub frequency {
    my ( $self, $word ) = @_;

    return unless $word;

    my $query = "$word/frequency";

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub punctuationFactor {
    my ( $self, $word ) = @_;

    return unless $word;

    my $query = "$word/punctuationFactor";

    return $self->_send_request( $self->_build_request( 'word', $query ) );
}

sub suggest {
    my ( $self, $word, %args ) = @_;

    return unless $word;

    my %parameters = (
        count   => 10,
        startAt => 0,
    );

    for ( keys %args ) {
        croak "Invalid argument key or value: '$_'"
            unless exists $parameters{$_}
                and $args{$_} =~ m/\d+/;
    }

    my $query = "$word";
    $query .= "?$_=$args{$_}" for keys %args;

    return $self->_send_request( $self->_build_request( 'suggest', $query ) );
}

sub wordoftheday {
    my ($self) = @_;

    return $self->_send_request( $self->_build_request('wordoftheday') );
}

sub randomWord {
    my ( $self, %args ) = @_;

    my %parameters = ( hasDictionaryDef => { true => 0, false => 1 }, );

    for ( keys %args ) {
        croak "Invalid argument key or value: '$_'"
            unless exists $parameters{$_}
                and exists $parameters{$_}->{ $args{$_} };
    }

    my $query = "randomWord";
    $query .= "?$_=$args{$_}" for keys %args;

    return $self->_send_request( $self->_build_request( 'words', $query ) );
}

### internal methods

sub _build_request {
    my ( $self, $namespace, $query ) = @_;

    my $request = $self->server_uri . q{/} . $namespace . q{.};
    $request .= 'perl' eq $self->format ? 'json' : $self->format;
    $request .= defined $query ? "/$query" : q{};

    return $request;
}

sub _send_request {
    my ( $self, $request ) = @_;

    return $request if $self->{debug};

    # cache
    if ( $self->cache and exists $self->{_cache}->{requests}->{$request} ) {
        return ${ $self->{_cache}->{requests}->{$request} };
    }

    # request
    else {
        my $response = $self->{_user_agent}->get($request);

        my $data = $self->_validate_response($response);

        $data = from_json($data)
            if 'perl' eq $self->format;

        return $self->_cache_data( $request, $data );
    }
}

sub _validate_response {
    my ( $self, $response ) = @_;

    return $response->decoded_content
        if $response->is_success
            or $response->is_redirect;

    croak $response->as_string
        if ( $response->is_error
        or $response->is_info );
}

sub _pop_cache {
    my ($self) = @_;
    my $c = $self->{_cache};

    return unless $c && 'ARRAY' eq ref $c->{data};
    my $oldest = pop @{ $c->{data} };

    return unless 'ARRAY' eq ref $oldest;
    my ( $request, $data ) = @{$oldest};

    delete $c->{requests}->{$request};
    return $data;
}

sub _load_cache {
    my ( $self, $request, $data ) = @_;

    my $c = $self->{_cache};
    return unless $c;

    $c->{requests}->{$request} = \$data;

    unshift @{ $c->{data} }, [ $request, $data ];

    return $data;
}

sub _cache_data {
    my ( $self, $request, $data ) = @_;

    my $c = $self->{_cache};
    return unless $c;

    $self->_pop_cache if @{ $c->{data} } >= $c->{max};

    return $self->_load_cache( $request, $data );
}

sub _json_available {
    my ($self) = @_;

    croak "The operation you requested requires JSON to be installed"
        unless $self->{_json};
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

WWW::Wordnik::API - Wordnik API implementation

=head1 VERSION

This document describes WWW::Wordnik::API version 0.0.5.

The latest development revision is available at L<git://github.com/pedros/WWW-Wordnik-API.git>.


=head1 SYNOPSIS

    use WWW::Wordnik::API;

    my $p = WWW::Wordnik::API->new();

    $p->api_key('your api key here');
    $p->debug(1);
    $p->cache(100);
    $p->format('perl');

    $p->word('Perl');
    $p->word( 'Perl', useSuggest => 'true' );
    $p->word( 'Perl', literal    => 'false' );

    $p->phrases('Python');
    $p->phrases( 'Python', count => 10 );

    $p->definitions('Ruby');
    $p->definitions( 'Ruby', count => 20 );
    $p->definitions('Ruby',
                    partOfSpeech => [
                        qw/noun verb adjective adverb idiom article abbreviation preposition prefix interjection suffix/
                    ]
    );

    $p->examples('Java');

    $p->related('Lisp');
    $p->related('Lisp', type => [qw/synonym antonym form hyponym variant verb-stem verb-form cross-reference same-context/]);

    $p->frequency('Scheme');

    $p->punctuationFactor('Prolog');

    $p->suggest('C');
    $p->suggest('C', count => 4);
    $p->suggest('C', startAt => 6);

    $p->wordoftheday,

    $p->randomWord(hasDictionaryDef => 'true');


=head1 DESCRIPTION

This module implements version 4.0 of the Wordnik API (L<http://developer.wordnik.com/api>).
It provides a simple object-oriented interface with methods named after the REST ones provided by Wordnik.
You should therefore be able to follow their documentation only and still work with this module.

At this point, this module builds request URIs and ship them out as GET methods to LWP::UserAgent.
Response headers are checked for error codes (specifically, throw exception on headers anything other than 2/3xx).
Response data is not post-processed in any way, other than optionally being parsed from C<JSON> to C<Perl> data structures.
Data::Dumper should be of help there.


=head1 INTERFACE 


=head2 CLASS METHODS

=over

=item new(%args)

    my %args = (
        server_uri => 'http://api.wordnik.com/v4',
        api_key    => 'your key',
        version    => '4',
        format     => 'json', # json | xml | perl
    );

    my $WN = WWW::Wordnik::API->new(%args);

=back


=head2 SELECTOR METHODS

All selector methods can be assigned to, or retrieved from, as follows:

    $WN->method($value) # assign
    $WN->method         # retrieve

=over

=item server_uri()

=item server_uri($uri)

Default C<$uri>: L<http://api.wordnik.com/v4>


=item api_key()

=item api_key($key)

Required C<$key>: Your API key, which can be requested at L<http://api.wordnik.com/signup/>.


=item version()

=item version($version)

Default C<$version>: I<4>. This module supports API version 3 and 4 (default).


=item format()

=item format($format)

Default C<$format>: I<json>. Other accepted formats are I<xml> and I<perl>.


=item cache()

=item cache($cache)

Default C<$cache>: I<10>. Number of requests to cache. Deletes the oldest request if cache fills up.


=item debug()

=item debug($debug)

Default C<$debug>: I<0>. Don't sent GET requests to Wordnik. Return the actual request as a string.

=back


=head2 OBJECT METHODS

=over

=item word($word, %args)

This returns the word you requested, assuming it is found in our corpus.
See L<http://docs.wordnik.com/api/methods#words>.

C<$word> is the word to look up. C<%args> accepts:

Default C<useSuggest>: I<false>. Return an array of suggestions, if available.

Default C<literal>: I<true>. Return non-literal matches.

If the suggester is enabled, you can tell it to return the best match with C<useSuggest=true> and C<literal=false>.


=item phrases($word, %args)

You can fetch interesting bi-gram phrases containing a word.
The "mi" and "wlmi" elements refer to "mutual information" 
and "weighted mutual information" and will be explained in detail via future blog post.
See L<http://docs.wordnik.com/api/methods#phrases>.

C<$word> is the word to look up. C<%args> accepts:

Default C<count>: I<5>. Specify the number of results returned.


=item definitions($word, %args)

Definitions for words are available from Wordnik's keying of the Century Dictionary and parse of the Webster GCIDE.
The Dictionary Model XSD is available in L<http://github.com/wordnik/api-examples/blob/master/docs/dictionary.xsd> in GitHub.
See L<http://docs.wordnik.com/api/methods#definitions>.

C<$word> is the word to look up. C<%args> accepts:

Default C<count>: I<5>. Specify the number of results returned.

Default C<partOfSpeech>: I<empty>. Specify one or many part-of-speech types for which to return definitions. Pass multiple types as an array reference.

The available partOfSpeech values are:

    [noun, verb, adjective, adverb, idiom, article, abbreviation, preposition, prefix, interjection, suffix]


=item examples($word)

You can retrieve 5 example sentences for a words in Wordnik's alpha corpus. Each example contains the source document and a source URL, if it exists.
See L<http://docs.wordnik.com/api/methods#examples>.

C<$word> is the word to look up.


=item related($word, %args)

You retrieve related words for a particular word.
See L<http://docs.wordnik.com/api/methods#relateds>.

C<$word> is the word to look up. C<%args> accepts:

Default C<type>: I<empty>. Return one or many relationship types. Pass multiple types as an array reference.

The available type values are:

    [synonym, antonym, form, hyponym, variant, verb-stem, verb-form, cross-reference, same-context]


=item frequency($word)

You can see how common particular words occur in Wordnik's alpha corpus, ordered by year.
See L<http://docs.wordnik.com/api/methods#freq>.

C<$word> is the word to look up.


=item punctuationFactor($word)

You can see how common particular words are used with punctuation.
See L<http://docs.wordnik.com/api/methods#punc>.

C<$word> is the word to look up.


=item suggest($word, %args)

The autocomplete service gives you the opportunity to take a word fragment (start of a word) and show what other words start with the same letters.
The results are based on corpus frequency, not static word lists, so you have access to more dynamic words in the language.
See L<http://docs.wordnik.com/api/methods#auto>.

C<$word> is the word to look up. C<%args> accepts:

Default C<count>: I<5>. Specify the number of results returned.

Default C<startAt>: I<0>. You can also specify the starting index for the results returned. This allows you to paginate through the matching values.


=item wordoftheday

You can fetch Wordnik's word-of-the day which contains definitions and example sentences.
See L<http://docs.wordnik.com/api/methods#wotd>.


=item randomWord(%args)

You can fetch a random word from the Alpha Corpus.
See L<http://http://developer.wordnik.com/docs>.

C<%args> accepts:

Default C<hasDictionaryDef>: I<true>. You can ask the API to return only words where there is a definition available.

=back


=head1 INSTALLATION

To install this module type the following:

   perl Build.PL
   Build
   Build test
   Build install

or

   perl Makefile.PL
   make
   make test
   make install


=head1 DIAGNOSTICS

=over

=item C<< "Can't access '$key' field in class $class" >>

Private or inexistent member variable.

=item C<< "Invalid argument key or value: '$type'" >>

Inexistent query parameter, or wrong value passed to existing parameter.

=item C<< "Parameter 'partOfSpeech' requires a reference to an array" >>

partOfSpeech => [qw/.../].

=item C<< "Parameter 'type' requires a reference to an array" >>

type => [qw/.../].

=item C<< "The operation you requested requires JSON to be installed" >>

perl -MCPAN -e 'install JSON'.

=item C<< "Unsupported api format: '$format'" >>

Supported formats are 'perl', 'json', 'xml'.

=item C<< "Unsupported api version: '$version'" >>

The only API version supported by this module is 3.

=back


=head1 CONFIGURATION AND ENVIRONMENT

WWW::Wordnik::API requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module requires the core modules C<Test::More>, C<version> and C<Carp>, and C<LWP::UserAgent> from C<CPAN>.
Additionally, it recommends-requires C<JSON> from C<CPAN> for getting data in Perl data structures.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

On versions 0.0.1 and 0.0.2, creation of a second object would clobber the first object's instance variables,
resulting in unexpected behaviour. This is fixed in 0.0.3.

Response data is not post-processed in any way, other than optionally being parsed from C<JSON> to C<Perl> data structures.
Data::Dumper should be of help there.

Please report any bugs or feature requests to
C<bug-www-wordnik-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 TODO

=over

=item Post-processing

Add filtering methods on response data.

=item Implement WWW::Wordnik::API::Response class to handle the above

=back


=head1 AUTHOR

Pedro Silva  C<< <pedros@berkeley.edu> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Pedro Silva C<< <pedros@berkeley.edu> >>. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.
