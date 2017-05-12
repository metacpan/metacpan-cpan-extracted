package WebService::Speechmatics;
$WebService::Speechmatics::VERSION = '0.02';
use 5.010;
use Moo 1.006;
use JSON           qw/ decode_json /;
use Carp           qw/ croak       /;
use File::Basename qw/ basename    /;
use Scalar::Util   qw/ reftype     /;

use WebService::Speechmatics::User;
use WebService::Speechmatics::Job;
use WebService::Speechmatics::Submission;
use WebService::Speechmatics::Speaker;
use WebService::Speechmatics::Word;
use WebService::Speechmatics::Transcript;

my $BASE_URL = 'https://api.speechmatics.com/v1.0';
my $default_ua = sub {
    require LWP::UserAgent;
    require HTTP::Request::Common;
    require IO::Socket::SSL;

    return LWP::UserAgent->new();
};

my $get = sub {
    my $self = shift;
    my $path = shift;
    my $url  = $self->base_url.$path.'?auth_token='.$self->token;

    # TODO handle failure by throwing an exception here
    return $self->ua->get($url);
};

has token        => (is => 'ro', required => 1);
has ua           => (is => 'ro', required => 1, default => $default_ua);
has base_url     => (is => 'ro', required => 1, default => sub { $BASE_URL });
has user_id      => (is => 'ro', required => 1);
has lang         => (is => 'ro', required => 0);
has callback     => (is => 'ro');
has notification => (is => 'ro', default => sub { 'none' });

sub user
{
    my $self = shift;
    my $response = $self->$get('/user/'.$self->user_id);
    my $userdata = decode_json($response->content);

    return WebService::Speechmatics::User->new($userdata->{user});
}

sub balance
{
    my $self = shift;
    my $user = $self->user;

    return $user->balance;
}

sub jobs
{
    my $self = shift;
    my $response = $self->$get('/user/'.$self->user_id.'/jobs');
    my $jobsdata = decode_json($response->content);

    return map { WebService::Speechmatics::Job->new($_) }
               @{ $jobsdata->{jobs} };
}

sub job
{
    my $self     = shift;
    my $id       = shift;
    my $response = $self->$get('/user/'.$self->user_id.'/jobs/'.$id);
    my $jobdata  = decode_json($response->content);

    return WebService::Speechmatics::Job->new($jobdata->{job});
}

sub submit_job
{
    my $self     = shift;
    my $argref   = shift;

    if (not defined reftype($argref)) {
        $argref = { filename => $argref };
    }
    elsif (reftype($argref) ne 'HASH') {
        croak "You can either pass a filename or a hashref to submit_job()";
    }

    if (not exists $argref->{filename}) {
        croak "you must pass a filename";
    }

    my $lang     = $argref->{lang}
                   // $self->lang
                   // croak "You must specify the language with 'lang'";

    my $callback = $argref->{callback}
                   // $self->callback;

    my $url      = sprintf('%s/user/%d/jobs/?auth_token=%s',
                           $self->base_url,
                           $self->user_id,
                           $self->token,
                          );
    my @args     = (
                    data_file    => [$argref->{filename}],
                    model        => $lang,
                   );

    if (defined $callback) {
        push(@args, notification => 'callback',
                        callback => $callback);
    }
    else {
        push(@args, notification => $argref->{notification}
                                    // $self->notification);
    }

    my $request = HTTP::Request::Common::POST(
                      $url,
                      Content_Type => 'form-data',
                      Content      => \@args,
                  );

    my $response = $self->ua->request($request);

    if (!defined($response) || !$response->is_success) {
        croak "failed to submit job\n",
              "HTTP status code: ", $response->code;
    }

    return WebService::Speechmatics::Submission->new(
               decode_json($response->content)
           );
}

sub transcript
{
    my $self     = shift;
    my $id       = shift;
    my $path     = sprintf('/user/%d/jobs/%d/transcript', $self->user_id, $id);
    my $response = $self->$get($path);
    my $txdata   = decode_json($response->content);

    if (exists $txdata->{job}) {
        my $job      = WebService::Speechmatics::Job->new($txdata->{job});
        my @speakers = map { WebService::Speechmatics::Speaker->new($_) }
                       @{ $txdata->{speakers} };
        my @words    = map { WebService::Speechmatics::Word->new($_) }
                       @{ $txdata->{words} };
        return WebService::Speechmatics::Transcript->new(
                   job      => $job,
                   speakers => \@speakers,
                   words    => \@words,
               );
    }
    else {
        return;
    }
}

1;

=head1 NAME

WebService::Speechmatics - ALPHA interface to speech-to-text API from speechmatics.com

=head1 SYNOPSIS

 use WebService::Speechmatics;

 my $sm = WebService::Speechmatics->new(
              user_id => 42,
              token   => '...THISISNOTREALLYMYAPITOKEN...',
              lang    => 'en-GB',
          );
 my $response = $sm->submit_job('foobar.wav');

 # wait a bit

 $transcript = $sm->transcript($response->id);

=head1 DESCRIPTION

This module provides an interface to the
L<Speechmatics|https://speechmatics.com>
L<API|https://speechmatics.com/api-details> for
converting speech audio to text.

B<UNSTABLE>: please note that this is very much a work in progress,
and all aspects of the interface may change in the future.
I've only played with the service so far. Happy to hear suggestions
for this module's interface. My current thoughts are in C<TODO.md>.

Before using this module you need to register with
L<speechmatics.com|https://speechmatics.com>,
which will provide you with a user id (integer) and a token
to use with the API (a string of random characters).

After submitting a speech audio file, you can either poll until it has
been converted to text (or failed), or you can provide a callback URL
and Speechmatics will POST the result to your URL.

=head2 Specifying language

Whenever you submit a transcription job, you must specify the suspected
language (of the speaker(s) in the audio). Right now that can be one of

 en-GB    UK English
 en-US    American English

You can either specify the language every time you submit a transcription
job, or you can specify it when you instantiate this module,
as in the SYNOPSIS.


=head1 METHODS

=head2 new

The following attributes can be passed to the constructor:

=over 4

=item * token - the API token on registering with Speechmatics.

=item * user_id - the integer user id which you also get from Speechmatics.

=item * lang - the suspected language of the speaker, described above.

=item * callback - a URL which transcripts should be POSTed back to.

=item * notification - if you set this to 'email' then you'll get an email
sent to you when jobs are completed. Defaults to 'none'.

=back

The B<token> and B<user_id> attributes are required, but the others are
optional, as they can be specified on a per-job basis as well.

=head2 submit_job

There are two ways to submit a job. The simplest is where you just
pass the name / path for an audio file:

 $speechmatics->submit_job('i-have-a-dream.wav');

To submit jobs this way, you must specify the language by passing B<lang>
to the constructor.

You can also provide additional attributes by passing a hash ref:

 $speechmatics->submit_job({
     filename     => 'i-have-a-dream.wav',
     lang         => 'en-GB',
     notification => 'email',
 });

=head2 jobs

Returns a list of your jobs, each of which is an instance of
L<WebService::Speechmatics::Job>,
which has attributes named exactly the same as the fields given
in the Speechmatics API documentation.

=head2 balance

Returns an integer, which is the number of Speechmatics credits
you have left in your account.

=head2 transcript

Returns an instance of L<WebService::Speechmatics::Transcript>,
or C<undef> if the job is still in progress. This has three attributes:

=over 4

=item * job - instance of L<WebService::Speechmatics::Job> with details
of the job which produced this transcription.

=item * speakers - an array ref of speakers, which will currently
always contain the single dominant speaker.

=item * words - an array ref of L<WebService::Speechmatics::Word>.
Each instance has attributes named exactly as in the Speechmatics API doc.

=back

Here's a simple example how you might submit a job for transcription,
then dispay the converted text:

 my $sm         = WebService::Speechmatics->new( ... );
 my $response   = $sm->submit_job('sample.wav');

 # wait

 my $transcript = $sm->transcript($response->id);
 my @words      = map { $_->name } @{ $transcript->words };

 print "you said: @words\n";

=head1 SEE ALSO

L<speechmatics.com|https://speechmatics.com> - home page for Speechmatics

L<API doc|https://speechmatics.com/api-details> - the official documentation
for the Speechmatics API.

=head1 REPOSITORY

L<https://github.com/neilbowers/WebService-Speechmatics>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

