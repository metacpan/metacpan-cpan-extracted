# NAME

WebService::MinFraud - API for MaxMind's minFraud Score, Insights, and Factors services

# VERSION

version 1.009001

# SYNOPSIS

    use 5.010;

    use WebService::MinFraud::Client;

    # The Client object can be re-used across several requests.
    # Your MaxMind account_id and license_key are available at
    # https://www.maxmind.com/en/my_license_key
    my $client = WebService::MinFraud::Client->new(
        account_id  => 42,
        license_key => 'abcdef123456',
    );

    # For the fraud services, the request HashRef must contain a 'device' key, with a value that is a
    # HashRef containing an 'ip_address' key with a valid IPv4 or IPv6 address.
    # All other keys/values are optional; see other modules in minFraud Perl API
    # distribution for details.

    my $request = { device => { ip_address => '24.24.24.24' } };

    # Use the 'score', 'insights', or 'factors' client methods, depending on
    # the minFraud web service you are using.

    my $score = $client->score( $request );
    say $score->risk_score;

    my $insights = $client->insights( $request );
    say $insights->shipping_address->is_high_risk;

    my $factors = $client->factors( $request );
    say $factors->subscores->ip_tenure;

    # For the chargeback service, the request HashRef must contain an 'ip_address' key
    # with a valid IPv4 or IPv6 address.
    # All other keys/values are optional; see other modules in minFraud Perl API
    # distribution for details.

    $request = { ip_address => '24.24.24.24' };

    # Use the 'chargeback' method. The chargeback api does not return
    # any content from the server.

    my $chargeback = $client->chargeback( $request );
    if ($chargeback->isa('WebService::MinFraud::Model::Chargeback')) {
      say 'Successfully submitted chargeback';
    }

# DESCRIPTION

This distribution provides an API for the
[MaxMind minFraud Score, Insights, and Factors web services](https://dev.maxmind.com/minfraud/)
and the [MaxMind minFraud Chargeback web service](https://dev/maxmind.com/minfraud/chargeback/).

See [WebService::MinFraud::Client](https://metacpan.org/pod/WebService::MinFraud::Client) for details on using the web service client
API.

# INSTALLATION

The minFraud Perl API and its dependencies can be installed with
[cpanm](https://metacpan.org/pod/App::cpanminus). `cpanm` itself has no
dependencies.

    cpanm WebService::MinFraud

# VERSIONING POLICY

The minFraud Perl API uses [Semantic Versioning](https://semver.org/).

# PERL VERSION SUPPORT

The minimum required Perl version for the minFraud Perl API is 5.10.0.

The data returned from the minFraud web services includes Unicode characters
in several locales. This may expose bugs in earlier versions of Perl. If
Unicode is important to your work, we recommend that you use the most recent
version of Perl available.

# SUPPORT

This module is deprecated and will only receive fixes for major bugs and
security vulnerabilities. New features and functionality will not be added.

Please report all issues with this distribution using the GitHub issue tracker
at [https://github.com/maxmind/minfraud-api-perl/issues](https://github.com/maxmind/minfraud-api-perl/issues).

If you are having an issue with a MaxMind service that is not specific to the
client API please visit [https://www.maxmind.com/en/support](https://www.maxmind.com/en/support) for details.

Bugs may be submitted through [https://github.com/maxmind/minfraud-api-perl/issues](https://github.com/maxmind/minfraud-api-perl/issues).

# AUTHOR

Mateu Hunter <mhunter@maxmind.com>

# CONTRIBUTORS

- Andy Jack <ajack@maxmind.com>
- Christopher Bothwell <christopher.bothwell@endurance.com>
- Dave Rolsky <drolsky@maxmind.com>
- Florian Ragwitz <rafl@debian.org>
- Greg Oschwald <goschwald@maxmind.com>
- Mark Fowler <mark@twoshortplanks.com>
- Narsimham Chelluri <nchelluri@maxmind.com>
- Olaf Alders <oalders@maxmind.com>
- Patrick Cronin <pcronin@maxmind.com>
- Ruben Navarro <rnavarro@maxmind.com>
- William Storey <wstorey@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
