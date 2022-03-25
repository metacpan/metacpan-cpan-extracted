use strict;
use warnings;
package Text::SlackEmoji 0.008;
# ABSTRACT: data for mapping Slack :emoji_strings: into Unicode text

use File::ShareDir ();

#pod =head1 SYNOPSIS
#pod
#pod   use Text::SlackEmoji;
#pod
#pod   my $emoji = Text::SlackEmoji->emoji_map;
#pod
#pod   $slack_message =~ s!:([-+a-z0-9_]+):!$emoji->{$1} // ":$1:"!ge;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This library is basically just a container around a hash mapping strings like
#pod "disappointed_relieved" to Unicode text like 😥 .
#pod
#pod =head1 SECRET ORIGINS
#pod
#pod I made the first version of this lookup to power a little C<irssi> plugin so
#pod that when using the Slack IRC gateway, I'd see the same emoji as the people
#pod using the Slack app, at least when possible.
#pod
#pod =cut

our %Emoji;
sub _initialize_emoji {
  $_[0]->load_emoji unless %Emoji;
}

#pod =method load_emoji
#pod
#pod This method reloads the emoji map from disk, allowing the mapping to be updated
#pod in (say) your IRC client without forcing the reload of the module.
#pod
#pod =cut

sub load_emoji {
  my $emoji_file = File::ShareDir::dist_file('Text-SlackEmoji', 'emoji.pl');
  %Emoji = %{ do $emoji_file };
  return;
}

__PACKAGE__->_initialize_emoji;

#pod =method emoji_map
#pod
#pod This method takes no arguments and returns a hashref mapping Slack emoji names
#pod to Unicode strings.  The strings may be more than one character long.
#pod
#pod =cut

sub emoji_map {
  my ($self) = @_;
  $self->_initialize_emoji;
  return { %Emoji };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::SlackEmoji - data for mapping Slack :emoji_strings: into Unicode text

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use Text::SlackEmoji;

  my $emoji = Text::SlackEmoji->emoji_map;

  $slack_message =~ s!:([-+a-z0-9_]+):!$emoji->{$1} // ":$1:"!ge;

=head1 DESCRIPTION

This library is basically just a container around a hash mapping strings like
"disappointed_relieved" to Unicode text like 😥 .

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 load_emoji

This method reloads the emoji map from disk, allowing the mapping to be updated
in (say) your IRC client without forcing the reload of the module.

=head2 emoji_map

This method takes no arguments and returns a hashref mapping Slack emoji names
to Unicode strings.  The strings may be more than one character long.

=head1 SECRET ORIGINS

I made the first version of this lookup to power a little C<irssi> plugin so
that when using the Slack IRC gateway, I'd see the same emoji as the people
using the Slack app, at least when possible.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ricardo Signes Rob N ★

=over 4

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
