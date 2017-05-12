#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use Text::Slidez;

my $s = Text::Slidez->new->load(\<<'---');
slides{
  slide{
    My Title

    My Name
  }
  slide{
    Something Something
  }
  slide{
    Thing

    * stuff
    * deal
      * and
        * so
        * on
  }
  slide{
    Some Code

    code[@small]{{{
      slides{slide{stuff}}
    }}}
  }
}
---
ok($s);

my @slides = $s->slides;
is(scalar(@slides), 4);

{
  my $sl = $s->format_slide($slides[0]);
  like($sl->doctype, qr/^html PUBLIC /);
  my $body = $sl->child(1);
  is($body->tag, 'body');
  my $div = $body->child(0)->child(0);
  is($div->tag, 'div');
  # TODO attributes object in XML::Bits?
  like("$div", qr/ class="title"/);
  my $txt = $div->child(0);
  is($txt->type, 'text');
  is("$txt", '    My Title');
  is($body->child(0)->child(2)->child(0)->stringify, '    My Name');
}
{
  my $sl = $s->format_slide($slides[1]);
  like($sl->doctype, qr/^html PUBLIC /);
  my $body = $sl->child(1);
  is($body->tag, 'body');
  my $div = $body->child(0)->child(0);
  is($div->tag, 'div');
  like("$div", qr/ class="cell"/);
  my $txt = $div->child(0)->child(0);
  is($txt->type, 'text');
  is("$txt", '    Something Something');
}
{
  my $sl = $s->format_slide($slides[2]);
  like($sl->doctype, qr/^html PUBLIC /);
  my $body = $sl->child(1);
  is($body->tag, 'body');
  my $div = $body->child(0)->child(0);
  is($div->tag, 'div');
  like("$div", qr/ class="title"/);
  my $txt = $div->child(0);
  is($txt->type, 'text');
  is("$txt", '    Thing');
  is($body->child(0)->child(1)->tag, 'br');
  my $div2 = $body->child(0)->child(2);
  is($div2->tag, 'div');
  my $ul = $div2->child(0);
  is($ul->tag, 'ul');
  is($ul->child(0)->stringify, '<li>stuff</li>');
  is($ul->child(1)->stringify,
    '<li>deal<ul><li>and<ul><li>so</li><li>on</li></ul></li></ul></li>');
}

{
  my $sl = $s->format_slide($slides[3]);
  my $body = $sl->child(1);
  is($body->child(0)->child(1)->tag, 'br');
  my $div = $body->child(0)->child(2);
  is($div->tag, 'div');
  my %atts = $div->atts;
  is($atts{class}, 'auto left small');
}

# vim:ts=2:sw=2:et:sta
