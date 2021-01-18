# DESCRIPTION

A Perl API for connecting with the Postex REST API

# SYNOPSIS

    use WebService::Postex;

    my $postex = WebService::Postex->new(
        base_uri     => 'https://demo.postex.com',
        generator_id => 1234,
        secret       => 'yoursecret',
    );

    my %args = ();
    $postex->generation_file_upload(%args);

# ATTRIBUTES

## base\_uri

Required. The endpoint to which to talk to

## generator\_id

Required. The generator ID you get from Postex

## secret

Required. The secret for the authorization token.

# METHODS

## generation\_file\_upload

## generation\_file\_upload\_check

## generation\_rest\_upload

## generation\_rest\_upload\_check

## generation\_session\_status

## profile\_file\_upload

# SEE ALSO

- [Postex](https://www.postex.com)
