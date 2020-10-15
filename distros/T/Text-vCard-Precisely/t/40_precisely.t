use strict;
use warnings;

use Test::More tests => 10;

use_ok 'Text::vCard::Precisely';    #01

my $vc = new_ok 'Text::vCard::Precisely';    #02
is '3.0', $vc->version, "new()";             #03

$vc = new_ok 'Text::vCard::Precisely', [ version => '3.0' ];    #04
is '3.0', $vc->version, "new( version => '3.0' )";              #05

$vc = new_ok 'Text::vCard::Precisely', [ version => '4.0' ];    #06
is '4.0', $vc->version, "new( version => '4.0' )";              #07

$vc->adr(
    {   street    => '123 Main Street',
        city      => 'Any Town',
        region    => 'CA',
        post_code => '91921-1234',
        country   => 'U.S.A.',
        label =>
            "Mr. John Q. Public, Esq.\nMail Drop: TNE QB\n123 Main Street\nAny Town, CA  91921-1234\nU.S.A."
    }
);
( my $text = <<'END') =~ s/\n/\r\n/g;
BEGIN:VCARD
VERSION:4.0
ADR;LABEL="Mr. John Q. Public, Esq.
Mail Drop: TNE QB
123 Main Street
Any
  Town, CA  91921-1234
U.S.A.":;;123 Main Street;Any Town;CA;91921-
  1234;U.S.A.
END:VCARD
END

is $vc->as_string(), $text, "label is now available";    #08

my $fail = eval { $vc->version('3.0') };
is undef, $fail, "fail to change the version";           #09

$fail = eval { $vc = Text::vCard::Precisely->new( version => '2.1' ) };
is undef, $fail, "fail to declare an invalid version";    #10

done_testing;
