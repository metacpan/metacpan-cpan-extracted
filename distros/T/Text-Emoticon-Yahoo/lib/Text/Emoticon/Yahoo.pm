package Text::Emoticon::Yahoo;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use Text::Emoticon 0.03;
use base qw(Text::Emoticon);

sub default_config {
    return {
        imgbase => "http://us.i1.yimg.com/us.yimg.com/i/mesg/emoticons6",
        xhtml   => 1,
        class   => undef,
    };
}

# Table autogernerated from emoticons.php using
# use LWP::Simple
# my $content  = get('http://messenger.yahoo.com/emoticons.php');
#    $content .= get('http://messenger.yahoo.com/hiddenemoticons.php');
# my $i = 1;
# while($content =~ m/emoticons6\/(\d+.gif).+?<\/td>.+?<td width=30 nowrap>([^<]+)<\/td>/gs) {
#    my ($img, $smile) = ($1, $2);
#    $smile =~ s/&lt;/</g;
#    $smile =~ s/&gt;/>/g;
#    printf("%-6s => '%s',\n", "'$smile'", $img);
# }

__PACKAGE__->register_subclass({
':)'   => '1.gif',
':('   => '2.gif',
';)'   => '3.gif',
':D'   => '4.gif',
';;)'  => '5.gif',
'>:D<' => '6.gif',
':-/'  => '7.gif',
':x'   => '8.gif',
':">'  => '9.gif',
':P'   => '10.gif',
':-*'  => '11.gif',
'=(('  => '12.gif',
':-O'  => '13.gif',
'X('   => '14.gif',
':>'   => '15.gif',
'B-)'  => '16.gif',
':-S'  => '17.gif',
'#:-S' => '18.gif',
'>:)'  => '19.gif',
':(('  => '20.gif',
':))'  => '21.gif',
':|'   => '22.gif',
'/:)'  => '23.gif',
'=))'  => '24.gif',
'O:)'  => '25.gif',
':-B'  => '26.gif',
'=;'   => '27.gif',
'I-|'  => '28.gif',
'8-|'  => '29.gif',
'L-)'  => '30.gif',
':-&'  => '31.gif',
':-$'  => '32.gif',
'[-('  => '33.gif',
':O)'  => '34.gif',
'8-}'  => '35.gif',
'<:-P' => '36.gif',
'(:|'  => '37.gif',
'=P~'  => '38.gif',
':-?'  => '39.gif',
'#-o'  => '40.gif',
'=D>'  => '41.gif',
':-SS' => '42.gif',
'@-)'  => '43.gif',
':^o'  => '44.gif',
':-w'  => '45.gif',
':-<'  => '46.gif',
'>:P'  => '47.gif',
'<):)' => '48.gif',
':@)'  => '49.gif',
'3:-O' => '50.gif',
':(|)' => '51.gif',
'~:>'  => '52.gif',
'@};-' => '53.gif',
'%%-'  => '54.gif',
'**==' => '55.gif',
'(~~)' => '56.gif',
'~O)'  => '57.gif',
'*-:)' => '58.gif',
'8-X'  => '59.gif',
'=:)'  => '60.gif',
'>-)'  => '61.gif',
':-L'  => '62.gif',
'[-O<' => '63.gif',
'$-)'  => '64.gif',
':-"'  => '65.gif',
'b-('  => '66.gif',
':)>-' => '67.gif',
'[-X'  => '68.gif',
'\:D/' => '69.gif',
'>:/'  => '70.gif',
';))'  => '71.gif',
':-@'  => '76.gif',
'^:)^' => '77.gif',
':-j'  => '78.gif',
'(*)'  => '79.gif',
});

1;
__END__

=head1 NAME

Text::Emoticon::Yahoo - Emoticon filter of Yahoo! Messenger

=head1 SYNOPSIS

  use Text::Emoticon::Yahoo;

  my $emoticon = Text::Emoticon::Yahoo->new(
      imgbase => "http://example.com/emo",
  );

  my $text = "Yet Another Perl Hacker ;)";
  print $emoticon->filter($text);

  # it prints
  # Yet Another Perl Hacker <img src="http://example.com/emo/3.gif" />

=head1 DESCRIPTION

Text::Emoticon::Yahoo is a text filter that replaces text emoticons like ":)", ";P", etc. to the icons of Yahoo! Messenger, detailed in http://messenger.yahoo.com/emoticons.php

=head1 METHODS

=over 4

=item new

  $emoticon = Text::Emoticon::Yahoo->new(
      imgbase => "http://yourhost.example.com/images/emoticons",
      xhtml   => 1,
      class   => "emoticon",
  );

Constructs new Text::Emoticon::Yahoo object. It accepts two options:

=over 6

=item imgbase

Base URL where icon gif files are located. It defaults to
"http://us.i1.yimg.com/us.yimg.com/i/mesg/emoticons6/" (the Yahoo
site), but I don't recommend that, as there's a possibility Yahoo!
will ban your site.

=item xhtml

Whether it uses XHTML style img tags. It defaults to 1.

=item class

CSS class used in C<img> tags. It defaults to nothing.

  $emoticon = Text::Emoticon::Yahoo->new(class => "emo");

will print:

  <img src="blah.gif" class="emo" />

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

Common API for other Emoticons (maybe Text::Emoticons)

=back

=head1 AUTHOR

M. Blom E<lt>b10m@perlmonk.org<gt>

Text::Emoticon::MSN by Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://messenger.yahoo.com/emoticons.php

=cut
