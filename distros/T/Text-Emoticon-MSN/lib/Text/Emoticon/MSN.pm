package Text::Emoticon::MSN;

use strict;
our $VERSION = '0.04';

use Text::Emoticon 0.03;
use base qw(Text::Emoticon);

sub default_config {
    return {
        imgbase => "http://messenger.msn.com/Resource/emoticons",
        xhtml   => 1,
        strict  => 0,
        class   => undef,
    };
}

# Table autogernerated from Emoticons.aspx using
# $_ = join "", <>;
# while (m@(<img src="emoticons/(.*?)">|<span class="bold">(.*?)</span>)@g) {
#   $icon = $2 if $2;
#   ($t = $2) =~ s/'/\\'/;
#   $print qq('$t' => "$icon",\n) if $3;
# }

__PACKAGE__->register_subclass({
':-)' => "regular_smile.gif",
':)' => "regular_smile.gif",
':-D' => "teeth_smile.gif",
':d' => "teeth_smile.gif",
':-O' => "omg_smile.gif",
':o' => "omg_smile.gif",
':-P' => "tongue_smile.gif",
':p' => "tongue_smile.gif",
';-)' => "wink_smile.gif",
';)' => "wink_smile.gif",
':-(' => "sad_smile.gif",
':(' => "sad_smile.gif",
':-S' => "confused_smile.gif",
':s' => "confused_smile.gif",
':-|' => "what_smile.gif",
':|' => "what_smile.gif",
':\'(' => "cry_smile.gif",
':-$' => "red_smile.gif",
':$' => "red_smile.gif",
'(H)' => "shades_smile.gif",
'(h)' => "shades_smile.gif",
':-@' => "angry_smile.gif",
':@' => "angry_smile.gif",
'(A)' => "angel_smile.gif",
'(a)' => "angel_smile.gif",
'(6)' => "devil_smile.gif",
':-#' => "47_47.gif",
'8o|' => "48_48.gif",
'8-|' => "49_49.gif",
'^o)' => "50_50.gif",
':-*' => "51_51.gif",
'+o(' => "52_52.gif",
':^)' => "71_71.gif",
'*-)' => "72_72.gif",
'<:o)' => "74_74.gif",
'8-)' => "75_75.gif",
'|-)' => "77_77.gif",
'(C)' => "coffee.gif",
'(c)' => "coffee.gif",
'(Y)' => "thumbs_up.gif",
'(y)' => "thumbs_up.gif",
'(N)' => "thumbs_down.gif",
'(n)' => "thumbs_down.gif",
'(B)' => "beer_mug.gif",
'(b)' => "beer_mug.gif",
'(D)' => "martini.gif",
'(d)' => "martini.gif",
'(X)' => "girl.gif",
'(x)' => "girl.gif",
'(Z)' => "guy.gif",
'(z)' => "guy.gif",
'({)' => "guy_hug.gif",
'(})' => "girl_hug.gif",
':-[' => "bat.gif",
':[' => "bat.gif",
'(^)' => "cake.gif",
'(L)' => "heart.gif",
'(l)' => "heart.gif",
'(U)' => "broken_heart.gif",
'(u)' => "broken_heart.gif",
'(K)' => "kiss.gif",
'(k)' => "kiss.gif",
'(G)' => "present.gif",
'(g)' => "present.gif",
'(F)' => "rose.gif",
'(f)' => "rose.gif",
'(W)' => "wilted_rose.gif",
'(w)' => "wilted_rose.gif",
'(P)' => "camera.gif",
'(p)' => "camera.gif",
'(~)' => "film.gif",
'(@)' => "cat.gif",
'(&)' => "dog.gif",
'(T)' => "phone.gif",
'(t)' => "phone.gif",
'(I)' => "lightbulb.gif",
'(i)' => "lightbulb.gif",
'(8)' => "note.gif",
'(S)' => "moon.gif",
'(*)' => "star.gif",
'(E)' => "envelope.gif",
'(e)' => "envelope.gif",
'(O)' => "clock.gif",
'(o)' => "clock.gif",
'(M)' => "messenger.gif",
'(m)' => "messenger.gif",
'(sn)' => "53_53.gif",
'(bah)' => "70_70.gif",
'(pl)' => "55_55.gif",
'(||)' => "56_56.gif",
'(pi)' => "57_57.gif",
'(so)' => "58_58.gif",
'(au)' => "59_59.gif",
'(ap)' => "60_60.gif",
'(um)' => "61_61.gif",
'(ip)' => "62_62.gif",
'(co)' => "63_63.gif",
'(mp)' => "64_64.gif",
'(st)' => "66_66.gif",
'(li)' => "73_73.gif",
'(mo)' => "69_69.gif",
});

1;
__END__

=head1 NAME

Text::Emoticon::MSN - Emoticon filter of MSN Messenger

=head1 SYNOPSIS

  use Text::Emoticon::MSN;

  my $emoticon = Text::Emoticon::MSN->new(
      imgbase => "http://example.com/emo",
  );

  my $text = "Yet Another Perl Hacker ;-)";
  print $emoticon->filter($text);

  # it prints
  # Yet Another Perl Hacker <img src="http://example.com/emo/regular_smile.gif" />

=head1 DESCRIPTION

Text::Emoticon::MSN is a text filter that replaces text emoticons like ":-)", ";-P", etc. to the icons of MSN Messenger, detailed in http://messenger.msn.com/Resource/Emoticons.aspx

=head1 METHODS

=over 4

=item new

  $emoticon = Text::Emoticon::MSN->new(
      imgbase => "http://yourhost.example.com/images/emoticons",
      xhtml   => 1,
      class   => "emoticon",
  );

Constructs new Text::Emoticon::MSN object. It accepts two options:

=over 6

=item imgbase

Base URL where icon gif files are located. It defaults to
"http://messenger.msn.com/Resource/emoticons" (the MSN site) but I
don't recommend that, as there's a possibility MSN will ban your site.

=item xhtml

Whether it uses XHTML style img tags. It defaults to 1.

=item class

CSS class used in C<img> tags. It defaults to nothing.

  $emoticon = Text::Emoticon::MSN->new(class => "emo");

will print:

  <img src="blah.gif" class="emo" />
 
=item strict

Whether it will disable smileys with space in them.
defaults to 0.
 
=back

=item filter

  $filtered_text = $emoticon->filter($text);

Filters emoticons in text and returns C<img> tagged text (HTML).

=back

=head1 TODO

=over 4

=item *

Handling original emoticons. (Patches welcome)

=item *

Common API for other Emoticons like Yahoo! (maybe Text::Emoticons)

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://messenger.msn.com/Resource/Emoticons.aspx

=cut
