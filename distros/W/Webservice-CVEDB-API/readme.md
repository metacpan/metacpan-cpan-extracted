# NAME

Webservice::CVEDB::API - Fast Vulnerability lookups using CVE\_ID and CPE23

# SYNOPSIS
```perl
    use v5.40;
    use Webservice::CVEDB::API;


    my $ua = Webservice::CVEDB::API->new();

    my $response = $ua->get_cve('CVE-2016-10088');

    $response = $ua->get_cpes(
        product => 'linux',
        count => 'false',
        skip => 0,
        limit => 1000,
    );

    $response = $ua->get_cves(
        product => 'linux',
        count => 'false',
        skip => 0,
        limit => 2,
    );
```
# DESCRIPTION

This module provides an object oriented interface via the keyword "class" feature to the CVEDB free API endpoint provided by [https://cvedb.shodan.io/](https://cvedb.shodan.io/). Shodan also provides much more robust paid services with subscription that this module does not provide access to.

# METHODS

## get\_cve()

Accepts a string that is the CVE ID to be looked up.
Returns a hash reference with the results of the scan.

example response:
```json
    {
        "cve_id": "string",
        "summary": "string",
        "cvss": 10,
        "cvss_version": 0,
        "cvss_v2": 10,
        "cvss_v3": 10,
        "epss": 1,
        "ranking_epss": 1,
        "kev": true,
        "propose_action": "string",
        "ransomware_campaign": "string",
        "references": [
            "string"
        ],
        "published_time": "2024-09-15T21:14:54.534Z",
        "cpes": [
            "string"
        ]
    }
```
## get\_cves()

Retrieve information about CVEs based on a specified product name or CPE 2.3 identifier.

### Parameters:

- **cpe23** _(String, Optional)_:
The CPE version 2.3 identifier for CVE information retrieval.
- **product** _(String, Optional)_:
The name of the product for CVE information retrieval.
- **count _(Boolean, Default: false)_**: If set to true, this returns only the count of matching CVEs. This will help get a quick overview of how many CVEs are associated with the product or CPE identifier, especially if the total number exceeds the limit (by default the limit is 1000 but can be adjusted).
- **is\_kev _(Boolean, Default: false)_**: If set to true, this returns only CVEs with the kev flag set to true.
- **sort\_by\_epss _(Boolean, Default: false)_**: If set to true, this sorts CVEs by the epss score in descending order.
- **skip _(Integer, Default: 0)_**: Number of CVEs to skip in the result set.
- **limit _(Integer, Default: 1000)_**: The maximum number of CVEs to return in a single query. By default, up to 1000 CVEs can be returned, but you can adjust this value based on your specific needs.
- **start\_date _(str, optional)_**: Start date for filtering CVEs (inclusive, format YYYY-MM-DDTHH:MM:SS).
- **end\_date _(str, optional)_**: End date for filtering CVEs (inclusive, default is current date, format YYYY-MM-DDTHH:MM:SS).

### Returns:

- **if cpe23 and product are not specified**: Users can use the skip and limit parameters to paginate through the results effectively.

        B<Returns>: cves is a list of the newest CVEs based on published time.

- **if cpe23 and product are specified**: Raise a message indicating that you can only specify one of cpe23 or product.
- **if cpe23 is specified**:

        B<Returns>: cves is a list of CVEs matching the specified cpe23 identifier.

- **if product is specified**:

        B<Returns>: cves is a list of CVEs matching the specified product name. Please refer to the CVEs schema for more details.

Use start\_date and end\_date to filter CVEs based on published time. If start\_date is not specified, it defaults to 00:00:00 on the given date. If end\_date is not provided, it defaults to the current date and time.

example response:
```json
    {
        "cves": [
            {
               "cve_id": "string",
               "summary": "string",
               "cvss": 10,
               "cvss_version": 0,
               "cvss_v2": 10,
               "cvss_v3": 10,
               "epss": 1,
               "ranking_epss": 1,
               "kev": true,
               "propose_action": "string",
               "ransomware_campaign": "string",
               "references": [
                   "string"
               ],
          "published_time": "2024-09-15T21:20:31.377Z"
        }
      ]
    }
```
## get\_cpes()

Retrieve a CPE 2.3 dictionary based on a specified product.

### Parameters:

- **product _(String, Required)_**: The name of the product for which you want to retrieve CPE dictionary.
- **count _(Boolean, Default: false)_**:If set to true, this returns only the count of matching CPEs. This will help a quick overview of how many CPEs are associated with the product name, especially if the total number exceeds the limit (by default the limit is 1000 but can be adjusted).
- **skip _(Integer, Default: 0)_**: Number of CPEs to skip in the result set.
- **limit _(Integer, Default: 1000)_**: The maximum number of CPEs to return in a single query. By default, up to 1000 CPEs can be returned, but you can adjust this value based on your specific needs.

### Returns:

- **if product is specified**:

        Returns: cpes is a list of CPEs matching the specified product name. Please refer to the CPEs schema for more details.

example response:
```json
    {
      "cpes": [
        "string"
      ]
    }
```
# SEE ALSO

- Call for API implementations on PerlMonks: [https://perlmonks.org/?node\_id=11161472](https://perlmonks.org/?node_id=11161472)
- Listed at  freepublicapis.com: [https://www.freepublicapis.com/cvedb-api](https://www.freepublicapis.com/cvedb-api)
- Official api webpage: [https://cvedb.shodan.io/](https://cvedb.shodan.io/)

# AUTHOR

Joshua Day, <hax@cpan.org>

# SOURCECODE

Source code is available on Github.com : [https://github.com/haxmeister/perl-CVEDB](https://github.com/haxmeister/perl-CVEDB)

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
