package WWW::TheBestSpinner;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Carp 'croak';
use LWP::UserAgent;
use URI::Escape 'uri_escape';
use MIME::Base64;
use PHP::Serialization qw(serialize unserialize);

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my $args = scalar @_ % 2 ? shift : { @_ };

    $args->{username} or croak 'username is required';
    $args->{password} or croak 'password is required';

    $args->{__url} = "http://thebestspinner.com/api.php";

    bless $args, $class;
}

sub _authenticate {
    my ($self) = @_;

    return 1 if $self->{session};

    my $resp = LWP::UserAgent->new->post($self->{__url}, [
        action => 'authenticate',
        'format' => 'php',
        'username' => $self->{username},
        'password' => $self->{password},
    ]);

    unless ($resp->is_success) {
        $errstr = $resp->status_line;
        return;
    }

    my $result = unserialize($resp->content);
    if ($result->{success} eq 'true') {
        $self->{session} = $result->{session};
        return 1;
    } else {
        $errstr = $result->{error};
        return;
    }
}

sub rewriteText {
    my ($self, $text, $protectedterms) = @_;
    $self->_send_request('rewriteText', [
       text => $text,
       protectedterms => $protectedterms || '',
    ]);
}

sub rewriteSentences {
	my ($self, $text) = @_;
    $self->_send_request('rewriteSentences', [
       text => $text,
    ]);
}

sub randomSpin {
	my ($self, $text) = @_;
    $self->_send_request('randomSpin', [
       text => $text,
    ]);
}

sub identifySynonyms {
    my ($self, $text, $maxsyns, $protectedterms) = @_;
    $self->_send_request('identifySynonyms', [
       text => $text,
       maxsyns => $maxsyns || 3,
       protectedterms => $protectedterms || '',
    ]);
}

sub replaceEveryonesFavorites {
    my ($self, $text, $maxsyns, $quality, $protectedterms) = @_;
    $self->_send_request('replaceEveryonesFavorites', [
       text => $text,
       maxsyns => $maxsyns || 3,
       quality => $quality || 1,
       protectedterms => $protectedterms || '',
    ]);
}

sub textCompareUniqueness {
	my ($self, $text1, $text2) = @_;
    $self->_send_request('textCompareUniqueness', [
       text1 => $text1,
       text2 => $text2,
    ]);
}

sub textCompare {
	my ($self, $text1, $text2) = @_;
    $self->_send_request('textCompare', [
       text1 => $text1,
       text2 => $text2,
    ]);
}

sub apiQueries {
     my ($self) = @_;
     $self->_send_request('apiQueries');
}

sub _send_request {
    my ($self, $action, $post) = @_;

    $self->_authenticate or return;
    unshift @$post, (action => $action, format => 'php', session => $self->{session});

    my $url = $self->{__url};
    my $resp = LWP::UserAgent->new->post($url, $post);
#    use Data::Dumper; print Dumper(\$resp);

    unless ($resp->is_success) {
        $errstr = $resp->status_line;
        return;
    }

    my $data = unserialize($resp->content);

    if ($data->{success} eq 'true') {
        return $data->{output} if exists $data->{output};
        return $data;
    } else {
        $errstr = $data->{error};
        return;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::TheBestSpinner - TheBestSpinner API

=head1 SYNOPSIS

  	use WWW::TheBestSpinner;

	my $tbs = WWW::TheBestSpinner->new(
	    username => 'example@mail.com',
	    password => 'mypassword',
	);

	my $quota_left = $tbs->apiQueries or die $tbs->errstr;
	print "quota_left: $quota_left\n";

	my $spin_text = $tbs->replaceEveryonesFavorites($original_text, 10, 3) or die $tbs->errstr;
	print $spin_text . "\n";

=head1 DESCRIPTION

WWW::TheBestSpinner is for L<http://thebestspinner.com/?action=api_info> (requires login).

=head2 replaceEveryonesFavorites

	$tbs->replaceEveryonesFavorites($text, $maxsyns, $quality, $protectedterms);

=head2 rewriteText

	$tbs->rewriteText($text, $protectedterms)

=head2 identifySynonyms

	$tbs->identifySynonyms($text, $maxsyns, $protectedterms)

=head2 rewriteSentences

	$tbs->rewriteSentences($text)

=head2 randomSpin

	$tbs->randomSpin($text);

=head2 textCompareUniqueness

	$tbs->textCompareUniqueness($text1, $text2)

=head2 textCompare

	$tbs->textCompare($text1, $text2)

=head2 apiQueries

	$tbs->apiQueries()

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
