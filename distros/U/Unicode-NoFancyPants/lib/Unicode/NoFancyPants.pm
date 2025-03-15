use strict;
use warnings;
package Unicode::NoFancyPants;

use utf8;
use common::sense;
use Text::Unidecode;
use Unicode::Normalize qw(NFC);
our(@EXPORT)=qw(dropFancyPants);
use base qw(Exporter);

our $VERSION = '0.01';
=encoding utf8

=head1 NAME

Unicode::NoFancyPants - Remove fancy Unicode characters, replacing them with ASCII equivalents.

=head1 SYNOPSIS

    use Unicode::NoFancyPants;

    my $ascii_text = Unicode::NoFancyPants::dropFancyPants("Hello, “world”!");
    print $ascii_text; # Output: Hello, "world"! :-)

    # Or, with the exported function:
    use Unicode::NoFancyPants qw(dropFancyPants);
    my @ascii_texts = dropFancyPants("Fancy String 1", "Fancy String 2");
    print join("\n", @ascii_texts);

=head1 DESCRIPTION

This module provides a function, C<dropFancyPants>, that takes Unicode text and returns a version with "fancy" characters replaced by their closest ASCII equivalents. It handles:

* Fancy quotes and dashes.
* Emoji (converting them to basic ASCII smileys where possible).
* Other Unicode symbols (using L<Text::Unidecode>).

=head1 FUNCTIONS

=head2 dropFancyPants($text | @texts)

Takes either a single Unicode string or a list of Unicode strings and returns the corresponding ASCII-converted string(s).

=over 4

=item $text

A Unicode string to be processed.

=item @texts

A list of Unicode strings to be processed.

=back

=head1 EXAMPLES

    use Unicode::NoFancyPants qw(dropFancyPants);

    my $result = dropFancyPants("This is a test—with “fancy” quotes! 😊");
    print $result; # Output: This is a test-with "fancy" quotes! :-)

    my @results = dropFancyPants("String 1: 😃", "String 2: 😞");
    print join("\n", @results); # Output: String 1: :-D\nString 2: :-(

=head1 DEPENDENCIES

* L<Unicode::Normalize>
* L<Text::Unidecode>

=head1 AUTHOR

Nobody <nobody-spam-me@turing-trust.com>

=head1 LICENSE

Artistic License 2.0

=cut

use Unicode::Normalize;
use Text::Unidecode;

sub dropFancyPants {
  local(@_)=@_;
  for(@_) {
    if(ref($_) eq 'ARRAY'){
      @$_=dropFancyPants(@$_);
      next;
    };
    $_ = NFC( $_ );

    # Replace fancy quotes and dashes
    s/([\x{2018}\x{2019}\x{201B}])/'/g; # single quotes
    s/([\x{201C}\x{201D}\x{201E}\x{201F}])/"/g; # double quotes
    s/[\x{2013}\x{2014}]/-/g; # dashes
    s/\x{2026}/.../g; #ellipsis

    # Basic smiley replacements (expand this as needed)
    s/\x{1F600}/:-)/g; # Grinning Face
    s/\x{1F601}/:-D/g; # Grinning Face with Smiling Eyes
    s/\x{1F602}/:D/g; # Face with Tears of Joy
    s/\x{1F603}/:-D/g; # Smiling Face with Open Mouth
    s/\x{1F604}/:-D/g; # Smiling Face with Open Mouth and Smiling Eyes
    s/\x{1F605}/:-)/g; # Smiling Face with Open Mouth and Cold Sweat
    s/\x{1F606}/:-D/g; # Smiling Face with Open Mouth and Tightly-Closed Eyes
    s/\x{1F607}/O:-)/g; # Smiling Face with Halo
    s/\x{1F608}/>:-\]/g; # Smiling Face with Horns
    s/\x{1F609}/;-\)/g; # Winking Face
    s/\x{1F60a}/:-)/g; # shit that got forgot
    s/\x{1F60b}/1F60b:-)/g;
    s/\x{1F60c}/1F60c:-)/g;
    s/\x{1F60d}/1F60d:-)/g;
    s/\x{1F60d}/1F60d:-)/g;
    s/\x{1F60f}/1F60f:-)/g;
    s/\x{1F610}/:-|/g; # Neutral Face
    s/\x{1F611}/:-\|/g; # Expressionless Face
    s/\x{1F612}/:-\(/g; # Unamused Face
    s/\x{1F613}/:-\(/g; # Downcast Face with Sweat
    s/\x{1F614}/:-\(/g; # Pensive Face
    s/\x{1F615}/:-\(/g; # Confused Face
    s/\x{1F616}/:-\(/g; # Confounded Face
    s/\x{1F617}/\)-:/g; # Kissing Face
    s/\x{1F618}/:-*/g; # Face Blowing a Kiss
    s/\x{1F619}/:-*/g; # Kissing Face with Smiling Eyes
    s/\x{1F61A}/:-*/g; # Kissing Face with Closed Eyes
    s/\x{1F61B}/:-P/g; # Face with Stuck-out Tongue
    s/\x{1F61C}/:-P/g; # Winking Face with Stuck-out Tongue
    s/\x{1F61D}/:-P/g; # Face with Stuck-out Tongue and Tightly-Closed Eyes
    s/\x{1F61E}/:-\(/g; # Disappointed Face
    s/\x{1F61F}/:-\(/g; # Worried Face
    s/\x{1F620}/>:-\(/g; # Angry Face
    s/\x{1F621}/>:-\(/g; # Pouting Face
    s/\x{1F622}/:'-\(/g; # Crying Face
    s/\x{1F623}/>:-\(/g; # Persevering Face
    s/\x{1F624}/>:-\(/g; # Face with Look of Triumph
    s/\x{1F625}/:-\(/g; # Disappointed but Relieved Face
    s/\x{1F626}/:-\(/g; # Frowning Face with Open Mouth
    s/\x{1F627}/:-\(/g; # Anguished Face
    s/\x{1F628}/:-O/g; # Fearful Face
    s/\x{1F629}/:-\(/g; # Weary Face
    s/\x{1F62A}/:-Z/g; # Sleepy Face
    s/\x{1F62B}/>:-\(/g; # Tired Face
    s/\x{1F62C}/>:-\(/g; # Face with Open Mouth and Cold Sweat
    s/\x{1F62D}/:'-\(/g; # Loudly Crying Face
    s/\x{1F62E}/:-O/g; # Face with Open Mouth
    s/\x{1F62F}/:-O/g; # Hushed Face
    s/\x{1F630}/:-O/g; # Face with Open Mouth and Cold Sweat
    s/\x{1F631}/:-O/g; # Face Screaming in Fear
    s/\x{1F632}/:-O/g; # Astonished Face
    s/\x{1F633}/:-O/g; # Flushed Face
    s/\x{1F634}/:-Z/g; # Sleeping Face
    s/\x{1F635}/:-X/g; # Dizzy Face
    s/\x{1F636}/:-X/g; # Face Without Mouth
    s/\x{1F637}/:-X/g; # Face with Medical Mask

    # Use Text::Unidecode for the rest
    $_ = unidecode($_);
  };
  local($")="";
  return wantarray ? @_ : "@_";
}
1;
#my $test_string = "Hello, “world”!\n
#😊 This is a test—with fancy quotes and em dashes…\n";
#print dropFancyPants($test_string), "\n";
