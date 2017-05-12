# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 60-functions.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/60-functions.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 39;

use_ok('Text::Sass::Functions');
# $Text::Sass::DEBUG = 1;

my $cf = 'Text::Sass::Functions';

{
  isa_ok($cf, 'Text::Sass::Functions');
  ok($cf->can('darken'),'can darken');
}

# RGB
{
  is($cf->rgb(10,10,10), '#0a0a0a', 'rgb');
  # rgba
  is($cf->red('#806040'), 128, 'red');
  is($cf->green('#806040'), 96, 'green');
  is($cf->blue('#806040'), 64, 'blue');
  is($cf->mix('#f00', '#00f'), '#7f007f', 'mix 1');
  is($cf->mix('#f00', '#00f', '25%'), '#3f00bf', 'mix 2');
}

# HSL
{
  is($cf->hsl(90,'50%','50%'), '#7fbf3f', 'hsl');
  # hsla
  is($cf->hue('#7fbf3f'), 90, 'hue');
  is((sprintf q[%0.2f], $cf->saturation('#7fbf3f')), (sprintf q[%0.2f], 0.503937007874016), 'saturation');
  is((sprintf q[%0.2f], $cf->lightness('#7fbf3f')), (sprintf q[%0.2f], 0.498039215686275), 'lightness');
  is($cf->adjust_hue('#811', 45), '#886a10', 'adjust-hue');
  is($cf->lighten('#800', '20%'), '#ee0000', 'lighten');
  is($cf->darken('#3bbfce', '9%'), '#2ba1af', 'darken 1');
  is($cf->darken('#800', '20%'), '#220000', 'darken 2');
  is($cf->saturate('#855', '20%'), '#9e3e3e', 'saturate');
  is($cf->desaturate('#855', '20%'), '#716b6b', 'desaturate');
  is($cf->grayscale('#855'), $cf->desaturate('#855', '100%'), 'grayscale');
  is($cf->complement('#f00'), $cf->adjust_hue('#f00', 180), 'complement');
}

# String
{
  is($cf->unquote('"foo"'), 'foo', 'unquote 1');
  is($cf->unquote('foo'), 'foo', 'unquote 2');
  is($cf->quote('"foo"'), '"foo"', 'quote 1');
  is($cf->quote('foo'), '"foo"', 'quote 2');
}

# Numbers
{
  is($cf->percentage(2), '200%', 'percentage');
  is($cf->round('10.4px'), '10px', 'round 1');
  is($cf->round('10.6px'), '11px', 'round 2');
  is($cf->ceil('10.4px'), '11px', 'ceil 1');
  is($cf->ceil('10.6px'), '11px', 'ceil 2');
  is($cf->floor('10.4px'), '10px', 'floor 1');
  is($cf->floor('10.6px'), '10px', 'floor 2');
  is($cf->abs('10px'), '10px', 'abs 1');
  is($cf->abs('-10px'), '10px', 'abs 2');
}

# Introspective
{
  is($cf->unit(100), '""', 'unit 1');
  is($cf->unit('100px'), '"px"', 'unit 2');
  is($cf->unit('3em'), '"em"', 'unit 3');
  ok($cf->unitless(100), 'unitless 1');
  ok(!$cf->unitless('100px'), 'unitless 2');
}
