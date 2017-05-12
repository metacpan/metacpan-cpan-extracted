# NAME

WebService::DNSMadeEasy - Implements V2.0 of the DNSMadeEasy API

# SYNOPSIS

      use WebService::DNSMadeEasy;
    
      my $dns = WebService::DNSMadeEasy->new({
          api_key => $api_key,
          secret  => $secret,
          sandbox => 1,     # defaults to 0
      });

      # DOMAINS - see WebService::DNSMadeEasy::ManagedDomain
      my @domains = $dns->managed_domains;
      my $domain  = $dns->get_managed_domain('example.com');
      my $domain  = $dns->create_managed_domain('stegasaurus.com');
      $domain->update(...);
      $domain->delete;
      ...

      # RECORDS - see WebService::DNSMadeEasy::ManagedDomain::Record
      my $record  = $domain->create_record(...);
      my @records = $domain->records();                # Returns all records
      my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
      my @records = $domain->records(name => 'www');   # Returns all wwww records
      $record->update(...);
      $record->delete;
      ...

      # MONITORS - see WebService::DNSMadeEasy::Monitor
      my $monitor = $record->get_monitor;
      $monitor->disable;     # disable failover and system monitoring
      $monitor->update(...);
      ...

# DESCRIPTION

This distribution implements v2 of the DNSMadeEasy API as described in
[http://dnsmadeeasy.com/integration/pdf/API-Docv2.pdf](http://dnsmadeeasy.com/integration/pdf/API-Docv2.pdf).

# ATTRIBUTES

- api\_key

    You can find this here: [https://cp.dnsmadeeasy.com/account/info](https://cp.dnsmadeeasy.com/account/info).

- secret

    You can find this here: [https://cp.dnsmadeeasy.com/account/info](https://cp.dnsmadeeasy.com/account/info).

- sandbox

    Uses the sandbox api endpoint if set to true.  Creating a sandbox account is a
    good idea so you can test before messing with your live/production account.
    You can create a sandbox account here: [https://sandbox.dnsmadeeasy.com](https://sandbox.dnsmadeeasy.com).

- user\_agent\_header

    Here you can set the User-Agent http header.  

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>

This module started as a fork of Torsten Raudssus's WWW::DNSMadeEasy module,
but its pretty much a total rewrite especially since v1 and v2 of the DNS Made
Easy protocol are very different.
