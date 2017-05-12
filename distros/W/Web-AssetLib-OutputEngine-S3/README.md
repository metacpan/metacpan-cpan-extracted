# NAME

Web::AssetLib::OutputEngine::S3 - allows exporting an asset or bundle to an AWS S3 Bucket

On first usage, a cache will be generated of all files in the bucket. This way, we know
what needs to be uploaded and what's already there.

# SYNOPSIS

    my $library = My::AssetLib::Library->new(
        output_engines => [
            Web::AssetLib::OutputEngine::S3->new(
                access_key  => 'AWS_ACCESS_KEY',
                secret_key  => 'AWS_SECRET_KEY',
                bucket_name => 'S3_BUCKET_NAME',
                region      => 'S3_BUCKET_REGION'
            )
        ]
    );

    $library->compile( ..., output_engine => 'S3' );

# USAGE

This is an output engine plugin for [Web::AssetLib](https://metacpan.org/pod/Web::AssetLib).

Instantiate with `access_key`, `secret_key`, `bucket_name`, 
and `region` arguments, and include in your library's output engine list.

# PARAMETERS

## access\_key

## secret\_key

AWS access & secret keys. Must have `List` and `Put` permissions for destination bucket. 
Required.

## bucket\_name

S3 bucket name. Required.

## region

AWS region name of the bucket. Required.

## region

AWS region name of the bucket

## link\_url

Used as the base url of any asset that gets exported to S3. Make sure it's public!
Your CDN may go here.

## object\_expiration\_cb

Provide a coderef used to calculate the Expiration header. Currently, 
no arguments are passed to the callback. Defaults to:

    sub {
        return DateTime->now( time_zone => 'local' )->add( years => 1 );
    };

# SEE ALSO

[Web::AssetLib](https://metacpan.org/pod/Web::AssetLib)
[Web::AssetLib::OutputEngine](https://metacpan.org/pod/Web::AssetLib::OutputEngine)

# AUTHOR

Ryan Lang <rlang@cpan.org>
