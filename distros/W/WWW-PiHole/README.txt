NAME
    WWW::PiHole - Perl interface to Pi-hole

VERSION
    version 0.230680

METHODS
  version([$mode])
    Get the version string for Pi-hole components

  enable()
    Enable Pi-Hole

    Returns the status ('enabled')

  disable()
    Disable Pi-Hole

    Returns the status ('disabled')

  status()
    Get Pi-Hole status

    Returns 'enabled' or 'disabled'

  add($domain [, $list])
    Add a domain to the blacklist (by default)

    $list can be one of: "black", "regex_black", "white", "regex_white"

    URL: http://pi.hole/admin/groups-domains.php

  remove($domain [, $list])
    Remove a domain from the blacklist (by default)

    $list can be one of: "black", "regex_black", "white", "regex_white"

    AdminLTE API Function: "sub"

    URL: http://pi.hole/admin/groups-domains.php

  recent()
    Get the most recently blocked domain name

    AdminLTE API: "recentBlocked"

  add_dns($domain, $ip)
    Add DNS A record mapping domain name to an IP address

    AdminLTE API: "customdns" AdminLTE Function: "addCustomDNSEntry"

  remove_dns($domain, $ip)
    Remove a custom DNS A record

    ie. IP to domain name association

    AdminLTE API: "customdns" AdminLTE Function: "deleteCustomDNSEntry"

  get_dns()
    Get DNS records as an array of two-element arrays (IP and domain)

    AdminLTE API: "customdns" AdminLTE Function: "echoCustomDNSEntries"

  add_cname($domain, $target)
    Add DNS CNAME record effectively redirecting one domain to another

    AdminLTE API: "customcname"

    AdminLTE Function: "addCustomCNAMEEntry"

    See the func.php
    <https://github.com/pi-hole/AdminLTE/blob/master/scripts/pi-hole/php/fun
    c.php> script

    URL: http://localhost/admin/cname_records.php

  remove_cname($domain, $target)
    Remove DNS CNAME record

  get_cname()
    Get CNAME records as an array of two-element arrays (domain and target)

    AdminLTE API: "customcname" AdminLTE Function: "echoCustomDNSEntries"

AUTHOR
    Elvin Aslanov <rwp.primary@gmail.com>

COPYRIGHT AND LICENSE
    This software is copyright (c) 2023 by Elvin Aslanov.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.

