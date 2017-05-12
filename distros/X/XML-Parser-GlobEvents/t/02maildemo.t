
use Test::More tests => 4;

use strict;
use XML::Parser::GlobEvents;

(my $file = __FILE__) =~ s/[\w.~]+$/mail.xml/;
my $text;

XML::Parser::GlobEvents::parse($file,
  '/messages/message' => {
    Start => sub {
      my($node) = @_;
      $text .= "New message:\n";
    },
    End => sub {
      my($node) = @_;
      $text .= "Message complete\n";
    }
  },
  '/messages/message/*' => {
    Start => sub {
      my($node) = @_;
      $text .= "Found tag '$node->{-name}' (more specific filter)\n";
    },
  },
  'message/*' => {
    Start => sub {
      my($node) = @_;
      $text .= "Found tag '$node->{-name}' (less specific filter)\n";
    },
    End => sub {
      my($node) = @_;
      $text .= "text: $node->{-text}\n" unless $node->{-name} eq 'body';
    },
  },
  '/messages/message/body' => {
    End => sub {
      my($node) = @_;
      $text .= "Message body complete\n";
      $text .= "$node->{-text}\n";
    },
    Whitespace => 'trim'
  },
);

print $text;

is($text, <<'EXPECTED', 'output is as expected');
New message:
Found tag 'from' (more specific filter)
Found tag 'from' (less specific filter)
text: claudius@elsinore.gov
Found tag 'to' (more specific filter)
Found tag 'to' (less specific filter)
text: maddog@elsinore.gov
Found tag 'subject' (more specific filter)
Found tag 'subject' (less specific filter)
text: Re: [RSVP] Impromtu Theatrical Performance Today!
Found tag 'body' (more specific filter)
Found tag 'body' (less specific filter)
Message body complete
Hamlet,

     The Queen and I sincerly look forward to attending your play.
     Glad to see that you're feeling better.

     Your Uncle and King,
     Claudius
Message complete
New message:
Found tag 'from' (more specific filter)
Found tag 'from' (less specific filter)
text: rosencrantz@elsinore.gov
Found tag 'to' (more specific filter)
Found tag 'to' (less specific filter)
text: claudius@elsinore.gov
Found tag 'subject' (more specific filter)
Found tag 'subject' (less specific filter)
text: Project Update
Found tag 'body' (more specific filter)
Found tag 'body' (less specific filter)
Message body complete
My King,

     He suspects nothing. Guildenstern and I should be home
     within the week.

     -rosey
Message complete
EXPECTED

ok($text =~ /^Found tag 'to' \(more specific filter\)\nFound tag 'to' \(less specific filter\)$/m,
  'handler order');
ok($text =~ /^text: \S/m, 'text');
ok($text =~ /^Message body complete\n.+\n(\s.*\n)+Message complete$/m,
  'Keep Whitespace');
