package Text::Emoticon::GoogleTalk;

use strict;
our $VERSION = '0.01';

use Text::Emoticon 0.03;
use base qw(Text::Emoticon);

sub default_config {
    return {
        imgbase => "http://mail.google.com/mail/help/images/screenshots/chat",
        xhtml   => 1,
        strict  => 0,
        class   => undef,
    };
}

# Table autogernerated from http://mail.google.com/support/bin/answer.py?answer=34056

__PACKAGE__->register_subclass({
"<3" => "heart.gif",
":(|)" => "monkey.gif",
"\\m/" => "rockout.gif",
":-o" => "shocked.gif",
":D" => "grin.gif",
":(" => "frown.gif",
"X-(" => "angry.gif",
"B-)" => "cool.gif",
":'(" => "cry.gif",
"=D" => "equal_grin.gif",
";)" => "wink.gif",
":-|" => "straightface.gif",
"=)" => "equal_smile.gif",
":-D" => "nose_grin.gif",
";^)" => "wink_big_nose.gif",
";-)" => "wink_nose.gif",
":-)" => "nose_smile.gif",
":-/" => "slant.gif",
":P" => "tongue.gif",
});

1;
__END__

=head1 NAME

Text::Emoticon::GoogleTalk - Emoticon filter of GoogleTalk

=head1 SYNOPSIS

  use Text::Emoticon::GoogleTalk;
  my $emoticon = Text::Emoticon::GoogleTalk->new;

  my $text = "I <3 You :(|)";

=head1 DESCRIPTION

Text::Emoticon::GoogleTalk is a text filter that replace text
emoticons like ":-)", "<3", etc. with the icons of Google Talk (or
Gmail Chat), detailed in
L<http://mail.google.com/support/bin/answer.py?answer=34056>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::Emoticon>, L<Text::Emoticon::Yahoo>, L<Text::Emoticon::MSN>

=cut
