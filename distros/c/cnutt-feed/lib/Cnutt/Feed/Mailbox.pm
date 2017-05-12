package Cnutt::Feed::Mailbox;

use strict;
use utf8;

=head1 NAME

Cnutt::Feed::Mailbox - Take a feed and populate a mailbox

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 DESCRIPTION

This file is part of cnutt-feed. You should read its documentation.

=cut

use Encode;
use Digest::MD5 qw(md5_base64);

use XML::Feed;

use Email::LocalDelivery;
use Email::MIME::CreateHTML;
use Email::Address;
use Email::Date;
use Email::Folder;

use MIME::EncWords "encode_mimewords";

use HTML::Encoding "encoding_from_xml_declaration";
use HTML::Entities;
use HTML::TreeBuilder;
use HTML::FormatText::WithLinks;

=head2 fetch

  Cnutt::Feed::Mailbox->fetch($url, $mb, $dohtml, $delete, $verbose,
  $name)

will fetch the feed given by the url in C<$url> and put the entries in
the mailbox C<$mb> (See L<Email::LocalDelivery> for the supported
formats).

If not C<undef> it uses C<$name> for dislaying errors.

If C<$dohtml> is true, an html part will be enclosed in the built
messages.

If C<$delete> is true, old messages will be deleted. NOT IMPLEMENTED.

If C<$verbose> is true, informations will be printed on STDOUT.

=cut

sub fetch {
    shift;
    my ($url, $mb, $dohtml, $delete, $verbose, $name) = @_;

    my $count = 0;

# searching already downloaded entries
    my %ids;
    eval {
        my $folder = Email::Folder->new($mb)  ;
        if (defined($folder)) {
            map { $ids{$_->header("X-Id")}++ } $folder->messages;
        }
    };

# building uri
    if ($url =~ m!^https?://!) {
        $url = URI->new($url);
    }

# feed parsing
    my $feed = eval {XML::Feed->parse($url)};
    if (!defined($feed)) {
        my $error = XML::Feed->errstr;
        if (defined($error)) {
			if (defined($name)) {
	            warn "XML::Feed error: $error in $name\n";
			}
			else {
	            warn "XML::Feed error: $error in $url\n";
			}
        }
        return undef;
    }

    print "From ", $feed->title, "\n" if $verbose;

    my $xml = eval {$feed->as_xml};
    $xml = "" unless defined($xml);
    my $enc = "ISO-8859-15";
    $enc = encoding_from_xml_declaration($xml) if defined($xml);

# fetching each entries
    for my $entry ($feed->entries) {
# identification
        my $id = $entry->id;
        $id = $entry->link
            unless defined($id);
        $id = md5_base64($feed->title,$entry->title)
            unless defined($id);

        next if ($ids{$id}); # entry already seen

        my $title = $entry->title;
        $title = "" unless defined($title);
        print "fetching «", $title, "» \033[s..." if $verbose;

# permalink
        my $link = $entry->link;
        $link = "" unless defined($link);

# from and to
        my @addresses = Email::Address->parse($entry->author);
        if (@addresses == 0) {
            @addresses = (Email::Address->new($entry->author =>
                                            'invalid@localhost'));
        }
        my $from = "@addresses";

        my $to = Email::Address->new($feed->title => 'invalid@localhost');

# html body
        my $html_body = $entry->content->body;
        $html_body = "" unless defined($html_body);

        my $html_sig  = "<br>\n-- <br>\n" .
            "<a href=\"" . $link . "\">" .
            $link . "</a>" . "<br>\n" .
            $feed->title . "<br>\n" .
            $feed->description . "<br>\n";
        my $html = $html_body . $html_sig;

# text body
        my $text_tree = HTML::TreeBuilder->new_from_content($html_body);
        my $formatter = HTML::FormatText::WithLinks->new(leftmargin => 0,
                                                         rightmargin => 78);
        my $text_body = $formatter->format($text_tree);
        $text_body =~ s/^(\n)*//s; # empty lines deletion at the beginning
        my $text_sig  = "\n-- \n" .
            $link . "\n" .
            $feed->title . "\n" .
            $feed->description . "\n";
        my $text = $text_body . $text_sig;

        my $date = time();
        $date = $entry->issued->epoch if defined($entry->issued);

# building of the message
        my $email = eval {
            Email::MIME->create_html(
                                     header => [
                                                'From' => $from,
                                                'To' => $to,
                                                'Subject' =>
                                                encode_mimewords(
                                                                 decode_entities($title)),
                                                'Date' => format_date($date),
                                                'X-Id' => $id,
                                                ],
                                     body => $html,
                                     body_attributes => {
                                         charset => $enc},
                                     text_body => $text,
                                     text_body_attributes => {
                                         charset => $enc},
                                     embed => $dohtml,
                                     base => $feed->link,
                                     );
          };

# sending of the message
        if (defined($email)) {
            my @delivered_to = Email::LocalDelivery->deliver($email->as_string,
                                                             ($mb));
        }

        $count++;
        print " \033[u   \n" if $verbose;
    }

    return $count;
}

1;

