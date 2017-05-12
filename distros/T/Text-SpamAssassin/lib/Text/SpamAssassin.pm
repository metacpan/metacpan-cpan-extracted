package Text::SpamAssassin;
BEGIN {
  $Text::SpamAssassin::VERSION = '2.001';
}

use 5.006;
use strict;
use warnings;

use Mail::SpamAssassin;
use Mail::Address;
use Mail::Header;
use Mail::Internet;
use POSIX qw(strftime);
use Data::Random qw(rand_chars);

BEGIN {
    if ($Mail::SpamAssassin::VERSION < 3) {
        require Mail::SpamAssassin::NoMailAudit;
    }
}

sub new {
    my ($class, %opts) = @_;

    my $self = bless {}, $class;
    $self->reset;

    $self->{analyzer} = Mail::SpamAssassin->new($opts{sa_options});
    $self->{analyzer}->compile_now if not $opts{lazy};

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    local $@;
    eval { $self->{analyzer}->finish };
}

sub reset {
    my ($self) = @_;

    $self->reset_metadata;
    $self->reset_headers;

    return $self;
}

sub reset_metadata {
    my ($self) = @_;

    $self->{metadata} = {};

    return $self;
}

sub reset_headers {
    my ($self) = @_;

    $self->{header} = {};

    return $self;
}

sub set_metadata {
    my ($self, $key, $value) = @_;

    if (defined $value) {
        $self->{metadata}{lc $key} = $value;
    }
    else {
        delete $self->{metadata}{lc $key};
    }

    return $self;
}

sub set_header {
    my ($self, $key, $value) = @_;

    $value = [ $value ] if not ref $value;

    if (defined $value) {
        $self->{header}{lc $key} = $value;
    }
    else {
        delete $self->{header}{lc $key};
    }

    return $self;
}

sub set_text {
    my ($self, @text) = @_;

    $self->{text} = join '', @text;
    delete $self->{html};

    return $self;
}

sub set_html {
    my ($self, @html) = @_;

    $self->{html} = join '', @html;
    delete $self->{text};

    return $self;
}

sub analyze {
    my ($self) = @_;

    my $msg = $self->_generate_message;
    my $status = $self->{analyzer}->check($msg);
    $msg->finish;

    if (! $status) {
        return {
            verdict => 'UNKNOWN',
            score   => 0,
            rules   => '',
        };
    }

    my $result = {
        verdict => $status->is_spam ? 'SUSPICIOUS' : 'OK',
        score   => $status->get_hits,
        rules   => $status->get_names_of_tests_hit,
    };

    $status->finish;

    return $result;
}

sub _generate_header {
    my ($self) = @_;

    my $h = Mail::Header->new;

    for my $key ( keys %{$self->{headers}} ) {
        $h->add($key, $_) for @{$self->{headers}{$key}};
    }

    my $set = sub {
        my ($key, $value) = @_;
        $h->get($key) or $h->add($key, $value);
    };

    $set->('To' => q{blog@example.com});
    $set->('From' => Mail::Address->new(
        $self->{metadata}{author} || q{Anonymous Coward},
        $self->{metadata}{email}  || q{nobody@example.com},
    )->format);
    $set->('Subject' => $self->{metadata}{subject} || q{Eponymous});

    $set->('Date' => strftime("%a, %d %b %Y %H:%M:%S %z", localtime));

    $set->('Received' => sprintf (
        q{from %s ([%s]) by localhost (Postfix) with SMTP id %s for <blog@example.com>; %s},
        $self->{metadata}{ip} || q{127.0.0.1},
        $self->{metadata}{ip} || q{127.0.0.1},
        (join '', rand_chars(set => 'alphanumeric', size => 10)),
        strftime("%a, %d %b %Y %H:%M:%S %z", localtime),
    ));

    $set->('Message-Id', sprintf (
        q{<%s@%s.example.com>},
        (join '', rand_chars(set => 'alphanumeric', size => 32)),
        (join '', rand_chars(set => 'alphanumeric', size => 10)),
    ));

    $set->('MIME-Version', q{1.0});
    $set->('Content-Transfer-Encoding', q{8bit});

    if ( $self->{html} ) {
        $set->('Content-Type', q{text/html; charset="us-ascii"});
    }
    else {
        $set->('Content-Type', q{text/plain; charset="us-ascii"});
    }

    return $h;
}

sub _generate_body {
    my ($self) = @_;

    my @lines;

    if ( $self->{text} ) {
        @lines = (
            (map { "$_: $self->{metadata}{$_}" } sort keys %{$self->{metadata}}),
            (keys %{$self->{metadata}} ? q{} : ()),
            $self->{text},
        );
    }

    elsif ( $self->{html} ) {
        @lines = (
            q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">},
            q{<html><head><title>Anazlyzed comment</title></head><body><ul>},
            (map { "<li>$_: $self->{metadata}{$_}</li>" } sort keys %{$self->{metadata}}),
            q{</ul>},
            $self->{html},
            q{</body></html>},
        );
    }

    return join "\n", @lines;
}

sub _generate_message {
    my ($self) = @_;

    my $msg = Mail::Internet->new(
        Header => $self->_generate_header,
        Body   => [$self->_generate_body],
    );

    if ($Mail::SpamAssassin::VERSION < 3) {
        return Mail::SpamAssassin::NoMailAudit->new(
            data => [ split(/\n/, $msg->as_string) ],
        );
    }

    return Mail::SpamAssassin::Message->new({
        message => $msg->as_string,
    });
}

1;

__END__

=head1 NAME

Text::SpamAssassin - Detects spamminess of arbitrary text, suitable for wiki and blog defense

=head1 VERSION

version 2.001

=head1 SYNOPSIS

    use Text::SpamAssassin;

    my $sa = Text::SpamAssassin->new(
        sa_options => {
            userprefs_filename => 'comment_spam_prefs.cf',
        },
    );

    $sa->set_text($content);

    my $result = $sa->analyze;
    print "result: $result->{verdict}\n";

=head1 DESCRIPTION

Text::SpamAssassin is a wrapper around Mail::SpamAssassin that makes it easy to check simple blocks of text or HTML for spam content. Its main purpose is to help integrate SpamAssassin into non-mail contexts like blog comments. It works by creating a minimal email message based on the text or HTML you pass it, then handing that email to SpamAssassin for analysis. See L<MESSAGE GENERATION> for more details.

=head1 CONSTRUCTOR

    my $sa = Text::SpamAssassin->new(
        sa_options => {
            userprefs_filename => 'comment_spam_prefs.cf',
        },
    );

As well as initializing the object the constructor creates a Mail::SpamAssassin object for the actual analysis work. The following options may be passed to the constructor

=over 4

=item sa_options

A hashref. This will be passed as-is to the Mail::SpamAssassin constructor. At the very least you probably want to provide the C<userprefs_filename> as the default configuration isn't particularly well suited to non-mail spam. See L<SPAMASSASSIN CONFIGURATION> for details.

=item lazy

By default the Mail::SpamAssassin object will be fully created in the Text::SpamAssassin constructor. This requires it to compile the rulesets and load any modules it needs which can take a little while. If the C<lazy> option is set to a true value, this setup will be deferred until the first scan is done.

=back

=head1 METHODS

All the C<set_*> and C<reset_*> methods return a copy of Text::SpamAssasin object they are invoked on to allow easy call chaining:

    my $result = $sa->reset
                    ->set_text("comments")
                    ->set_metadata("ip", "127.0.0.1");
                    ->analyze;

=head2 set_text

    $sa->set_text("some comment text");

Store some text content and stores it for later analysis. Any content previously set with C<set_text> or C<set_html> will be overwritten.

=head2 set_html

    $sa->set_html("<p>see <a href='#'>here</a> for more info</p>");

Store some HTML content and stores it for later analysis. Any content previously set with C<set_text> or C<set_html> will be overwritten.

=head2 set_header

    $sa->set_header("Subject", "your blog is stupid");

Set a header that will be added to the constructed message that gets passed to SpamAssassin. This will override any header of the same name that would normally be generated by Text::SpamAssassin. To set multiple headers with the same name, provide an arrayref as the value instead.

=head2 set_metadata

    $sa->set_metadata("ip", "127.0.0.1");

Sets metadata related to the text, usually taken from additional fields in a blog comment form. Some of these values are used when constructing the message header for SpamAssassin. When scanning text (but not HTML) this data will also be added to the message body so they can be scanned. Any additional data that you want scanned (such as URLs) should be added here.

=head2 reset

    $sa->reset;

Calls C<reset_headers> and C<reset_headers> to reset the object state. You should use this if you have a long-lived Text::SpamAssassin object that will be used multiple times.

=head2 reset_headers

    $sa->reset_headers;

Removes any headers previously set with C<set_header>.

=head2 reset_metadata

    $sa->reset_metadata;

Removes any metadata previously set with C<set_metadata>.

=head2 analyze

    my $result = $sa->analyze;

Scan the previously-supplied data. Returns a hashref containing three values:

=over 4

=item verdict

One of the following values:

=over 4

=item OK

The message was considered to be clean by SpamAssassin.

=item SUSPICIOUS

The message was considered to be spam by SpamAssassin.

=item UNKNOWN

The scan failed for an unknown reason.

=back

=item score

The score that SpamAssassin gave the message.

=item rules

The list of rules that SpamAssassin matched when considering the message.

=back

=head1 MESSAGE GENERATION

Because SpamAssassin only knows how to scan email messages, its necessary for Text::SpamAssassin to generate a message from the data you provide. This section details how that message is created.

A message body is created from the supplied text or HTML data and the supplied metadata. If text is supplied then the message body contains the data supplied to C<set_metadata> as lines of "key: value", one per line, followed by the supplied message text. If HTML supplied then the body is wrapped in a HTML doctype and header, and the metadata is included as a unordered list.

The header is mostly hardcoded, but the following metadata items will be included if present.

=over 4

=item author

Included in the C<From:> header as the sender name.

=item email

Included in the C<From:> header as the sender address.

=item subject

Used as-is for the C<Subject:> header.

=item ip

Included in the C<Received:> header as the originating IP.

=back

Sane defaults will be used for any metadata that is not provided.

Additionally, the C<Content-Type:> will be set to either C<text/plain> or C<text/html> depending on the type of message content provided.

=head1 SPAMASSASSIN CONFIGURATION

By default SpamAssassin is configured in a way that does a good job of detecting spam in email traffic. Many of its rules that work well in that context are unsuitable for use in other scenarios. An example of this is DUN/DUL rulesets that check for known "dial-up" IP networks (such as those used by ISP customers) are almost always useless for something that scans blog comments, as you likely want home users to be able to comment on our blog when you'd never dream of accepting mail from them directly.

For this reason, its highly recommended that you specify an alternate configuration using the C<userprefs_filename> option in C<sa_options>. Sample configuration files can be found in the C<examples> directory of the C<Text-SpamAssassin> distribution.

=head1 BUGS

None known. Please report bugs via the CPAN Request Tracker at L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-SpamAssassin>

=head1 FEEDBACK

If you find this module useful, please consider rating it on the CPAN Ratings
service at L<http://cpanratings.perl.org/rate?distribution=Text-SpamAssassin>.

If you like (or hate) this module, please tell the author! Send mail to
E<lt>rob@eatenbyagrue.orgE<gt>.

=head1 SEE ALSO

L<Mail::SpamAssassin>

L<http://apthorpe.cynistar.net/code/babycart/>

=head1 AUTHOR

Originally by Bob Apthorpe E<lt>apthorpe+babycart@cynistar.netE<gt>

Cleanup for 2.0 and CPAN release by Robert Norris E<lt>rob@eatenbyagrue.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Bob Apthorpe

Copyright 2010 by Robert Norris

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut