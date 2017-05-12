#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Warn;
use Text::Sprintf::Named;

my $obj;

# TEST
$obj = Text::Sprintf::Named->new( { fmt => 'No Tokens Here!', } );

warnings_are { $obj->format() }[], 'No Tokens and No Parameters';

# TEST
$obj = Text::Sprintf::Named->new( { fmt => "Example >%(name)s<", } );

warning_like { $obj->format() } qr/Token 'name'/,
  'Missing Token Throws Warning ( String )';

# TEST
$obj = Text::Sprintf::Named->new( { fmt => "Example >%(foo)8.3f<", } );

warnings_like { $obj->format() }[ qr/Token 'foo'/, qr/numeric.*sprintf/ ],
  'Missing Token Throws Warning ( Float )';

no warnings 'Text::Sprintf::Named';

# TEST
$obj = Text::Sprintf::Named->new( { fmt => 'No Tokens Here!', } );

warnings_are { $obj->format() }[], 'No Tokens and No Parameters';

# TEST
$obj = Text::Sprintf::Named->new( { fmt => "Example >%(name)s<", } );

warnings_are { $obj->format() }[],
  '[Silent] Missing Token Throws Warning ( String )';

# TEST
$obj = Text::Sprintf::Named->new( { fmt => "Example >%(foo)8.3f<", } );

warnings_like { $obj->format() }[qr/numeric.*sprintf/],
  '[Subdued] Missing Token Throws Warning ( Float )';

# TEST
$obj = Text::Sprintf::Named->new( { fmt => '.' } );

use warnings 'Text::Sprintf::Named';

warning_like {
    $obj->format(
        {
            erroneous_parameter => 'this one',
            more_error          => 'this',
            this_will_never     => 'work',
        }
    );
}
qr/Format parameters were specified, but none/,
  'Weird Format Parameters Throws Warning';

# TEST
no warnings 'Text::Sprintf::Named';

warnings_are {
    $obj->format(
        {
            erroneous_parameter => 'this one',
            more_error          => 'this',
            this_will_never     => 'work',
        }
    );
}
[], '[Silenced] Weird Format Parameters Throws Warning';

