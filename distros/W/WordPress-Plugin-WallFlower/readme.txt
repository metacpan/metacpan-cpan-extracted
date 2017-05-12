=== WallFlower ===
Contributors: C.J. Adams-Collier
Donate link: http://wp.colliertech.org/donate/
Tags: authentication, authorization, auditing
Requires at least: 3.3
Tested up to: 3.4
Stable tag: prod
License: This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
License URI: http://dev.perl.org/licenses/

AAA Layer for social integration

== Description ==

as yet implemented

== Installation ==

1. Upload `wallflower.php` to the `/wp-content/plugins/` directory
2. Activate the plugin through the 'Plugins' menu in WordPress
3. Place `<?php do_action(wallflower_hook'); ?>` in your templates

== Frequently asked questions ==

= Why isn't it done yet =

I'm trying to appear to be an incompetent maintainer so that someone
will offer to take over.  It isn't working yet.  I'm probably
scuttling the attempt just by replying to this FAQ - drat.

== Screenshots ==

1. http://wp.colliertech.org/wallflower/screenie0.png
2. http://wp.colliertech.org/wallflower/screenie1.png

== Changelog ==

Revision history for cpe:/a:colliertech.org:wallflower

0.0.3   20120814T104413 cjac@colliertech.org
      - Stripped perl out of distribution .zip at the request of Mika
        Epstein (Ipstenu) from the wordpress plugin cabal
      - Stripped references to Perl from README based on same above
        request
      - Stole some re-useable bits from WordPress HTTPS.  Thanks go to
        Mike Ems for producing something worth stealing - licensensed
        under GPL3
      - Included the Mvied library to provide a base class - license: GPL3
      - Removed text output from wallflower.php

0.0.2   20120810T173854 carl.j.adams-collier@us.army.mil
      - Made a perl module out of it

0.0.1   20120810T170159 cjac@f5.com
      - Published the PHP version here: http://wp.colliertech.org/downloads/wallflower-0.0.1.zip

== Upgrade notice ==

Still pre-production.  Upgrade all you'd like.

== Arbitrary section ONE ==

arbitrary content ONE
