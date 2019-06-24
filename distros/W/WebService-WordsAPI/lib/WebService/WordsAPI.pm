package WebService::WordsAPI;
$WebService::WordsAPI::VERSION = '0.01';
use 5.006;
use Moo;
use JSON::MaybeXS;

has key => (
    is       => 'ro',
    required => 1,
);

has ua => (
    is      => 'ro',
    default => sub {
                   require HTTP::Tiny;
                   require IO::Socket::SSL;
                   return HTTP::Tiny->new;
               },
);

has base_url => (
    is      => 'ro',
    default => sub { 'https://wordsapiv1.p.mashape.com/words' },
);

has return_type => (
    is      => 'ro',
    default => sub { 'perl' },
);

sub _request
{
    my ($self, $relurl) = @_;
    my $url             = $self->base_url.'/'.$relurl;
    my $headers         = {
                             "X-Mashape-Key" => $self->key,
                             "Accept"        => "application/json",
                          };
    my $response        = $self->ua->get($url, { headers => $headers });

    if (not $response->{success}) {
        die "failed $response->{status} $response->{reason}\n";
    }

    return $self->return_type eq 'json'
           ? $response->{content}
           : decode_json($response->{content})
           ;
}

sub get_word_details
{
    my ($self, $word) = @_;

    return $self->_request($word);
}

sub rhymes_with
{
    my ($self, $word) = @_;

    return $self->_request($word.'/rhymes');
}

sub definitions
{
    my ($self, $word) = @_;

    return $self->_request($word.'/definitions');
}

1;

=head1 NAME

WebService::WordsAPI - a draft Perl 5 interface to the WordsAPI service

=head1 SYNOPSIS

 use WebService::WordsAPI;
 my $api = WebService::WordsAPI->new(key => '...');
 my $details = $api->get_word_details('plan');
 print $details->{results}[0]{definition}, "\n";

=head1 DESCRIPTION

This module is an interface to the WordsAPI service,
which provides an API for getting information about words,
including definitions, pronunciations, number of syllables, and more.

This is very much a first cut at an interface,
so (a) the interface may well change, and
(b) contributions are welcome.

To use this module you need an API I<key> from L<https://rapidapi.com>,
which is where WordsAPI is hosted.
They have a free level, which gets you 2500 lookups per day.

All of the instance methods take a word and by default
return a Perl data structure.
You can request to get back the underlying JSON response instead,
by setting the C<return_type> attribute.

=head1 METHODS

=head2 new

You must provide the B<key> that you got from rapidapi,
and can optionally specify the B<return_type>,
which should be C<'perl'> or C<'json'>.

 my $api = WebService::WordsAPI->new(
               key         => '...',
               return_type => 'json',
           );

I figured people wouldn't want to vary the return type
on a method-by-method basis,
which is why it's not something you can specify on individual methods.

=head2 get_word_details

This is the main function of the API.
It takes a word and returns a structure with various bits of information.
You may get multiple entries in the result.
For example when looking up "wind", it can be a verb,
as in I<to wind a clock>,
and a noun,
as in I<the wind blew from the East>.

 my $details = $api->get_word_details('wind');
 foreach my $result (@{ $details->{results} }) {
   printf "%s: %s\n",
          $result->{partOfSpeech},
          $result->{definition};
 }

Look at the L<API documentation|https://www.wordsapi.com/docs/#get-a-word>
to see exactly what is returned.

=head2 definitions

This returns just the definitions for the word.
As noted above, this may return multiple definitions:

 my $result = $api->definitions('wind');
 foreach my $entry (@{ $result->{definitions} }) {
   printf "%s: %s\n",
          $entry->{partOfSpeech},
          $entry->{definition};
 }

=head2 rhymes_with

This takes a word and returns one or more lists of words
that rhyme with the given word:

 my $results = $api->rhymes_with('wind');
 my $rhymes  = $results->{rhymes};

 foreach my $pos (keys %$rhymes) {
   my $words = @{ $rhymes->{ $pos } };
   print "\n$pos: @words\n";
 }

=head1 SEE ALSO

L<www.wordsapi.com> is the home page for the service;
documentation for the API can be found at L<https://www.wordsapi.com/docs>.

=head1 REPOSITORY

L<https://github.com/neilb/WebService-WordsAPI>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

