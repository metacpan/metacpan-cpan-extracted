# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 90-regression-background.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/90-regression-background.t $
#
use strict;
use warnings;
use Text::Sass;
use Test::More tests => 5;

{
  my $scss = q[.x-panel-body { background: white url(/images/RegH_logo_RGB.gif) no-repeat; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT', 'local background + colour');
.x-panel-body {
  background: white url(/images/RegH_logo_RGB.gif) no-repeat;
}
EOT
}

{
  my $scss = q[.x-panel-body { background: url(/images/RegH_logo_RGB.gif) no-repeat; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT', 'local background');
.x-panel-body {
  background: url(/images/RegH_logo_RGB.gif) no-repeat;
}
EOT
}

{
  my $scss = q[.x-panel-body { background: url(http://images/RegH_logo_RGB.gif) no-repeat; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT', 'http/remote background');
.x-panel-body {
  background: url(http://images/RegH_logo_RGB.gif) no-repeat;
}
EOT
}

{
  my $scss = q[.x-panel-body { background: url("http://images/RegH_logo_RGB.gif") no-repeat; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT', 'http remote background, double-quoted');
.x-panel-body {
  background: url("http://images/RegH_logo_RGB.gif") no-repeat;
}
EOT
}

{
  my $scss = q[.x-panel-body { background: url('https://images/RegH_logo_RGB.gif') no-repeat 0 0; }];
  my $ts   = Text::Sass->new;
  is($ts->scss2css($scss), <<'EOT', 'https remote background, single-quoted');
.x-panel-body {
  background: url('https://images/RegH_logo_RGB.gif') no-repeat 0 0;
}
EOT
}

