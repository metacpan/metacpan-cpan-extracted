package The::synthesizer;

=head1 NAME

The::synthesizer - Why don't I use the synthesizer

=head1 SYNOPSIS

  perl -e'use The::synthesizer';

The code above will open the URL
L<http://open.spotify.com/track/0oks4FnzhNp5QPTZtoet7c> on Linux, Windows or
OS X.

=head1 DESCRIPTION

When I was fifteen, sixteen, when I started really to play the guitar, I
definitely wanted to become a musician. It was almost impossible because
the dream was so big. I didn't see any chance because I was living in a
little town; I was studying. And when I finally broke away from school and
became a musician, I thought, "Well, now I may have a little bit of a
chance," Because all I really wanted to do is music - and not only play
music, But compose music.

At that time, in Germany, in '69-'70, they had already discotheques. So, I
would take my car, would go to a discotheque and sing maybe 30 minutes. I
think I had about seven, eight songs. I would partially sleep in the car
because I didn't want to drive home and that help me for about almost two
years to survive in the beginning.

I wanted to do a album with the sound of the '50s, the sound of the '60s,
of the '70s and then have a sound of the future. And I said, "Wait a
second...I know the synthesizer - why don't I use the synthesizer which is
the sound of the future?" And I didn't have any idea what to do, but I
knew I needed a click so we put a click on the 24 track which then was
synched to the Moog Modular. I knew that it could be a sound of the future
but I didn't realise how much impact it would be.

My name is Giovanni Giorgio, but everybody calls me Giorgio.

Once you free your mind about a concept of harmony and music being
correct, you can do whatever you want. So, nobody told me what to do, and
there was no preconception of what to do.

=cut

our $VERSION = '0.0201';

sub import {
  my $class = shift;
  my $url = shift || 'http://open.spotify.com/track/0oks4FnzhNp5QPTZtoet7c';
  my $os = $ENV{OPERATING_SYSTEM} || $^O;
  my $m;

  $os =~ /linux/i and exec "xdg-open $url";
  $os =~ /darwin/i and exec "open $url";
  $os =~ /win/i and exec "start $url";

  open my $LYRICS, '<', __FILE__;
  while(<$LYRICS>) {
    last if /=cut/;
    print if $m;
    next unless /=head1 DESCRIPTION/;
    $m++;
  }
}

=head1 AUTHOR

Jan Henning Thorsen - L<mailto:jhthorsen@cpan.org>

=cut

1;
