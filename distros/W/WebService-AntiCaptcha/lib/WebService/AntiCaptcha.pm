package WebService::AntiCaptcha;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Carp 'croak';
use LWP::UserAgent;
use URI;
use MIME::Base64;
use JSON;

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{clientKey} or croak "clientKey is required.\n";
    $args{ua} ||= LWP::UserAgent->new;
    $args{url} ||= 'https://api.anti-captcha.com/';
    $args{sleep} ||= 3;

    return bless \%args, $class;
}

sub createTask {
    my ($self, $task, $softId, $languagePool) = @_;

    $self->request('createTask',
        task => $task,
        $softId ? (softId => $softId) : (),
        $languagePool ? (languagePool => $languagePool) : (),
    );
}

sub getTaskResult {
    my ($self, $taskId) = @_;

    $self->request('getTaskResult', taskId => $taskId);
}

sub getBalance {
    my ($self) = @_;

    $self->request('getBalance');
}

sub getQueueStats {
    my ($self, $queueId) = @_;

    $self->request('getQueueStats', queueId => $queueId);
}

sub reportIncorrectImageCaptcha {
    my ($self, $taskId) = @_;

    $self->request('reportIncorrectImageCaptcha', taskId => $taskId);
}

sub request {
    my ($self, $url, %params) = @_;

    $params{clientKey} = $self->{clientKey};

    my $res = $self->{ua}->post($self->{url} . $url,
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'Content' => encode_json(\%params),
    );

    # print Dumper(\$res); use Data::Dumper;

    unless ($res->is_success) {
        $errstr = "Failed to post $url: " . $res->status_line;
        return;
    }
    return decode_json($res->decoded_content);
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::AntiCaptcha - anti-captcha.com API

=head1 SYNOPSIS

    use WebService::AntiCaptcha;

    my $wac = WebService::AntiCaptcha->new(
        clientKey => 'your_client_key'
    );

    my $res = $wac->getBalance or die $wac->errstr;
    print $res->{balance};

=head1 DESCRIPTION

WebService::AntiCaptcha is for L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/196635/Documentation+in+English>

=head1 NOTE

Note we don't raise error for API response errorId > 0. You should handle those yourself.

    # after each method call
    die $wac_res->{errorDescription} if $wac_res->{errorId};

=head1 METHODS

=head2 createTask

L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/5079073/createTask+captcha+task+creating>

    my $res = $wac->createTask($task, $softId, $languagePool);

=head3 ImageToTextTask

    my $res = $wac->createTask({
        type => 'ImageToTextTask',
        body => "BASE64_BODY_HERE!",
    }) or die $wac->errstr;

=head3 NoCaptchaTaskProxyless

recaptcha solving. check xt/recaptcha.pl for a working example.

    my $res = $wac->createTask({
        type => 'NoCaptchaTaskProxyless',
        websiteURL => "http://mywebsite.com/recaptcha/test.php",
        websiteKey => "6Lc_aCMTAAAAABx7u2N0D1XnVbI_v6ZdbM6rYf16"
    }) or die $wac->errstr;

=head3 NoCaptchaTask

with proxy

    my $res = $wac->createTask({
        type => 'NoCaptchaTask',
        websiteURL => "http://mywebsite.com/recaptcha/test.php",
        websiteKey => "6Lc_aCMTAAAAABx7u2N0D1XnVbI_v6ZdbM6rYf16",
        "proxyType" => "http",
        "proxyAddress" => "8.8.8.8",
        "proxyPort" => 8080,
        "proxyLogin" => "proxyLoginHere",
        "proxyPassword" => "proxyPasswordHere",
        "userAgent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"
    }) or die $wac->errstr;

=head2 getTaskResult

L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/5079103/getTaskResult+request+task+result>

    my $res = $wac->getTaskResult($taskId) or die $wac->errstr;

=head2 getBalance

L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/6389791/getBalance+retrieve+account+balance>

    my $res = $wac->getBalance or die $wac->errstr;
    print $res->{balance};

=head2 getQueueStats

L<https://anticaptcha.atlassian.net/wiki/spaces/API/pages/8290316/getQueueStats+obtain+queue+load+statistics>

    my $res = $wac->queueId($queueId) or die $wac->errstr;

=head2 reportIncorrectImageCaptcha

    my $res = $wac->reportIncorrectImageCaptcha($taskId) or die $wac->errstr;

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
