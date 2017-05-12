package WebService::2Captcha;

use strict;
use 5.008_005;
our $VERSION = '0.04';

use Carp 'croak';
use LWP::UserAgent;
use URI;
use MIME::Base64;

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{key} or croak "key is required.\n";
    $args{ua} ||= LWP::UserAgent->new;
    $args{url} ||= 'http://2captcha.com/res.php';
    $args{sleep} ||= 3;

    return bless \%args, $class;
}

sub decaptcha {
    my ($self, $file_or_content, %params) = @_;

    my $captcha_id = $self->upload($file_or_content, %params) or return;
    sleep $self->{sleep}; # put a little sleep since that's really not so fast
    while (1) {
        my $text = $self->get($captcha_id);
        if ($text) {
            return {
                text => $text,
                id   => $captcha_id # for reportbad
            };
        }
        if ($self->errstr =~ /CAPCHA_NOT_READY/) {
            sleep $self->{sleep};
        } else {
            return; # just bad
        }
    }
}

sub upload {
    my ($self, $file_or_content, %params) = @_;

    if (-e $file_or_content) {
        open(my $fh, '<', $file_or_content) or croak "Can't open $file_or_content: $!";
        $file_or_content = do {
            local $/;
            <$fh>;
        };
        close($fh);
    }

    my $res = $self->request(
        url => 'http://2captcha.com/in.php',
        __method => 'POST',
        method => 'base64',
        body => encode_base64($file_or_content),
        %params
    );
    if ($res !~ /OK/) {
        $errstr = $res;
        return;
    }
    $res =~ s/^OK\|//;
    return $res;
}

sub get {
    my ($self, $id) = @_;

    my $res = $self->request(action => 'get', id => $id);
    if ($res !~ /OK/) {
        $errstr = $res;
        return;
    }
    $res =~ s/^OK\|//;
    return $res;
}

sub get_multi {
    my ($self, @ids) = @_;

    my $res = $self->request(action => 'get', ids => join(',', @ids));
    return wantarray ? split(/\|/, $res) : $res;
}

sub getbalance {
    my ($self) = @_;

    $self->request(action => 'getbalance');
}

sub reportbad {
    my ($self, $id) = @_;

    $self->request(action => 'reportbad', id => $id);
}

sub getstats {
    my ($self, $date) = @_;

    $self->request(action => 'getstats', date => $date);
}

sub load {
    my ($self) = @_;

    $self->request(url => 'http://2captcha.com/load.php');
}

sub userrecaptcha {
    my ($self, $googlekey, $pageurl) = @_;

    my $res = $self->request(
        url => 'http://2captcha.com/in.php',
        method => 'userrecaptcha',
        googlekey => $googlekey,
        pageurl => $pageurl,
    );
    if ($res !~ /OK/) {
        $errstr = $res;
        return;
    }
    $res =~ s/^OK\|//;
    return $res;
}

sub request {
    my ($self, %params) = @_;

    $params{key} ||= $self->{key};
    my $url = delete $params{url} || $self->{url};

    my $res;
    my $method = delete $params{__method} || 'GET';
    if ($method eq 'POST') {
        $res = $self->{ua}->post($url, \%params);
        unless ($res->is_success) {
            $errstr = "Failed to post $url: " . $res->status_line;
            return;
        }
    } else {
        my $uri = URI->new($url);
        $uri->query_form(%params);
        $res = $self->{ua}->get($uri->as_string);
        unless ($res->is_success) {
            $errstr = "Failed to get " . $uri->as_string . ": " . $res->status_line;
            return;
        }
    }

    # print Dumper(\$res); use Data::Dumper;

    return $res->decoded_content;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::2Captcha - API 2Captcha.com

=head1 SYNOPSIS

    use WebService::2Captcha;

    my $w2c = WebService::2Captcha->new(
        key => '......', # from https://2captcha.com/setting
    );

    my $b = $w2c->getbalance() or die $w2c->errstr;
    print "Balance: $b\n";

    my $res = $w2c->decaptcha("$Bin/captcha.png", language => 1) or die $w2c->errstr;
    print "Got text as " . $res->{text} . "\n";
    if (0) {
        $w2c->reportbad($res->{id}) or die $w2c->errstr;
    }

=head1 DESCRIPTION

WebService::2Captcha is for L<https://2captcha.com/setting>

=head1 METHODS

=head2 decaptcha

    my $res = $w2c->decaptcha($filename_or_file_content) or die $w2c->errstr;
    my $res = $w2c->decaptcha(
        $filename_or_file_content
        phrase => 1,
        language => 1, # check https://2captcha.com/setting
    ) or die $w2c->errstr;

    print "Got text as " . $res->{text} . "\n";
    if (0) {
        $w2c->reportbad($res->{id}) or die $w2c->errstr;
    }

=head2 upload

    my $captcha_id = $w2c->upload($filename_or_file_content) or die $w2c->errstr;
    my $captcha_id = $w2c->upload(
        $filename_or_file_content
        phrase => 1,
        language => 1, # check https://2captcha.com/setting
    ) or die $w2c->errstr;

=head2 userrecaptcha

    my $captcha_id = $w2c->userrecaptcha($googlekey, $pageurl);

L<https://2captcha.com/2captcha-api#solving_recaptchav2_new>

=head2 get

    my $text = $w2c->get($captcha_id) or die $w2c->errstr;

=head2 get_multi

    my @texts = $w2c->get_multi($captcha_id1, $captcha_id2) or die $w2c->errstr;

=head2 getbalance

    my $b = $w2c->getbalance() or die $w2c->errstr;
    print "Balance: $b\n";

=head2 reportbad

    my $res = $w2c->reportbad($captcha_id) or die $w2c->errstr;

=head2 getstats

    my $res = $w2c->getstats($date) or die $w2c->errstr;

=head2 load

    my $load = $w2c->load();

=head2 request

    my $res = $w2c->request(action => 'getstats', date => $date);

underlaying method to build request

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
