package WebService::DetectLanguage;
$WebService::DetectLanguage::VERSION = '0.02';
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
    default => sub { 'https://ws.detectlanguage.com/0.2' },
);

sub _get
{
    my ($self, $relurl) = @_;
    my $url             = $self->base_url.'/'.$relurl;
    my $headers         = { "Authorization" => "Bearer ".$self->key };
    my $response        = $self->ua->get($url, { headers => $headers });

    if (not $response->{success}) {
        die "failed $response->{status} $response->{reason}\n";
    }
    return decode_json($response->{content});
}

sub detect
{
    my ($self, $string) = @_;

    my ($result) = $self->multi_detect($string);
    return @{ $result };
}

sub multi_detect
{
    my ($self, @strings) = @_;
    my $url              = $self->base_url."/detect";
    my $headers          = { "Authorization" => "Bearer ".$self->key };
    my $form_data        = { 'q[]' => \@strings };
    my $response         = $self->ua->post_form($url, $form_data, { headers => $headers });

    if (not $response->{success}) {
        die "failed $response->{status} $response->{reason}\n";
    }

    require WebService::DetectLanguage::Result;
    require WebService::DetectLanguage::Language;

    my $data = decode_json($response->{content});
    my @results;

    foreach my $result_set (@{ $data->{data}{detections} }) {
        my $set = [];
        foreach my $result (@$result_set) {
            my $object = WebService::DetectLanguage::Result->new(
                             language    => WebService::DetectLanguage::Language->new(code => $result->{language}),
                             is_reliable => $result->{isReliable},
                             confidence  => $result->{confidence},
                         );
            push(@$set, $object);
        }
        push(@results, $set);
    }

    return @results;
}

sub languages
{
    my $self   = shift;
    my $result = $self->_get("languages");

    require WebService::DetectLanguage::Language;

    return map { WebService::DetectLanguage::Language->new($_) } @$result;
}

sub account_status
{
    my $self   = shift;
    # my $result = $self->_request("user/status");
    my $result = $self->_get("user/status");

    require WebService::DetectLanguage::AccountStatus;

    return WebService::DetectLanguage::AccountStatus->new( $result );
}

1;

=head1 NAME

WebService::DetectLanguage - interface to the language detection API at DetectLanguage.com

=head1 SYNOPSIS

 use WebService::DetectLanguage;
 my $api = WebService::DetectLanguage->new(key => '...');
 my @possibilities = $api->detect("there can be only one");
 foreach my $poss (@possibilities) {
     printf "language = %s  confidence=%f\n",
            $poss->language->name,
            $poss->confidence;
 }

=head1 DESCRIPTION

This module is an interface to the DetectLanguage service,
which provides an API for guessing what natural language is used
in a sample of text.

This is very much a first cut at an interface,
so (a) the interface may well change, and
(b) contributions are welcome.

To use the API you must sign up to get an API key,
at L<https://detectlanguage.com/plans>.
There is a free level which lets you make 1,000 requests per day,
and you don't have to provide a card to sign up for the free level.

=head2 Example Usage

Let's say you've got a sample of text in a file.
You might read it into C<$text> using C<read_text()>
from L<File::Slurper>.

To identify the language, you call the C<detect()> method:

 @results = $api->detect($text);

Each result is an instance of L<WebService::DetectLanguage::Result>.
If there's only one result,
you should look at the C<is_reliable> flag to see whether they're
confident of the identification
The more text they're given, the more confident they are, in general.

 if (@results == 1) {
   $result = $results[0];
   if ($result->is_reliable) {
     printf "Language is %s!\n", $result->language->name;
   }
   else {
     # Hmm, maybe check with the user?
   }
 }

You might get more than one result though.
This might happen if your sample contains
words from more than one language,
for example.

In that case, the C<is_reliable> flag can be used to check
if the first result is reliable enough to go with.

 if (@results > 1 && $results[0]->is_reliable) {
   # we'll go with that!
 }

Each result also includes a confidence value,
which looks a bit like a percentage,
but L<their FAQ|https://detectlanguage.com/faq#confidence>
says that it can go higher than 100.

 foreach my $result (@results) {
   my $language = $result->language;
   printf "language = %s (%s) with confidence %f\n",
       $language->name,
       $language->code,
       $result->confidence;
 }

=head1 METHODS

=head2 new

You must provide the B<key> that you got from C<detectlanguage.com>.

 my $api = WebService::WordsAPI->new(
               key         => '...',
           );


=head2 detect

This method takes a UTF-8 text string,
and returns a list of one or more guesses
at the language.

Each guess is a data object which has attributes
C<language>, C<confidence>, and C<is_reliable>.

 my $text    = "It was a bright cold day in April, ...";
 my @results = $api->detect($text);

 foreach my $result (@results) {
   printf "language = %s (%s)  confidence = %f  reliable = %s\n",
       $result->language->name,
       $result->language->code,
       $result->confidence,
       $result->is_reliable ? 'Yes' : 'No';
 }

Look at the L<API documentation|https://detectlanguage.com/documentation#single-detection>
to see how to interpret each result.


=head2 multi_detect

This takes multiple strings and returns a list of arrayrefs;
there is one arrayref for each string, returned in the same order as the strings.
Each arrayref contains one or more language guess,
as for C<detect()> above.

 my @strings = (
   "All happy families are alike; each unhappy family ... ",
   "This is my favourite book in all the world, though ... ",
   "It is a truth universally acknowledged, that Perl ... ",
 );

 my @results = $api->multi_detect(@strings);

 for (my $i = 0; $i < @strings; $i++) {
    print "Text: $strings[$i]\n";
    my @results = @{ $results[$i] };

    # ... as for detect() above
 }


=head2 languages

This returns a list of the supported languages:

 my @languages = $api->languages;

 foreach my $language (@languages) {
   printf "%s: %s\n",
          $language->code,
          $language->name;
 }

=head2 account_status

This returns a bunch of information about your account:

 my $status = $api->account_status;

 printf "plan=%s  status=%s  requests=%d\n",
   $status->plan,
   $status->status,
   $status->requests;

For the full list of attributes,
either look at the API documentation,
or L<WebService::DetectLanguage::AccountStatus>.

=head1 SEE ALSO

L<https://detectlanguage.com> is the home page for the service;
documentation for the API can be found at L<https://detectlanguage.com/documentation>.

=head1 REPOSITORY

L<https://github.com/neilb/WebService-DetectLanguage>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

