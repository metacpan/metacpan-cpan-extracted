#!perl -T

use warnings;
use strict;

use Test::More;
use Test::XML;
use XML::Quick;

plan tests => 2;

# one single quote
is(
    xml({ foo => { _attrs => { bar => "O'Reilly" }}}),
    q{<foo bar='O&apos;Reilly'/>},
);

# multiple single quotes
is(
    xml({ foo => { _attrs => { bar => "O'Reilly and O'Toole" }}}),
    q{<foo bar='O&apos;Reilly and O&apos;Toole'/>},
);
