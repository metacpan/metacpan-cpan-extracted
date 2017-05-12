package Web::AssetLib::OutputEngine::S3;

# ABSTRACT: AWS S3 output engine for Web::AssetLib
our $VERSION = "0.042";

use strict;
use warnings;
use Kavorka;
use Moo;
use Carp;
use DateTime;
use Paws;
use Paws::Credential::Environment;
use Types::Standard qw/Str InstanceOf HashRef Maybe CodeRef/;
use Web::AssetLib::Output::Link;
use DateTime::Format::HTTP;

extends 'Web::AssetLib::OutputEngine';

use feature 'switch';
no if $] >= 5.018, warnings => "experimental";

has [qw/access_key secret_key/] => (
    is       => 'rw',
    isa      => Str,
    required => 1
);

has 'bucket_name' => (
    is       => 'rw',
    isa      => Str,
    required => 1
);

has 'region' => (
    is       => 'rw',
    isa      => Str,
    required => 1
);

# undef means no expiration tag is set
# callback recieves a hashref of put arguments
# and should return DateTime object
has 'object_expiration_cb' => (
    is      => 'rw',
    isa     => Maybe [CodeRef],
    default => sub {
        sub {
            my $args = shift;
            return DateTime->now( time_zone => 'local' )->add( years => 1 );
        };
    }
);

has 'link_url' => (
    is       => 'rw',
    isa      => Str,
    required => 1
);

has 's3' => (
    is      => 'rw',
    isa     => InstanceOf ['Paws::S3'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Paws->service(
            'S3',
            credentials => Paws::Credential::Environment->new(
                access_key => $self->access_key,
                secret_key => $self->secret_key
            ),
            region => $self->region
        );
    }
);

has '_s3_obj_cache' => (
    is      => 'lazy',
    isa     => HashRef,
    clearer => '_invalidate_s3_obj_cache',
    builder => '_build__s3_obj_cache'
);

method export (:$assets!, :$minifier?) {
    my $types  = {};
    my $output = [];

    # categorize into type groups, and seperate concatenated
    # assets from those that stand alone

    foreach my $asset ( sort { $a->rank <=> $b->rank } @$assets ) {
        if ( $asset->isPassthru ) {
            push @$output,
                Web::AssetLib::Output::Link->new(
                src  => $asset->link_path,
                type => $asset->type
                );
        }
        else {
            for ( $asset->type ) {
                when (/css|js/) {

                    # should concatenate
                    $$types{ $asset->type }{_CONCAT_}
                        .= $asset->contents . "\n\r\n\r";
                }
                default {
                    $$types{ $asset->type }{ $asset->digest }
                        = $asset->contents;
                }
            }
        }
    }

    my $cacheInvalid = 0;
    foreach my $type ( keys %$types ) {
        foreach my $id ( keys %{ $$types{$type} } ) {
            my $output_contents = $$types{$type}{$id};

            my $digest
                = $id eq '_CONCAT_'
                ? $self->generateDigest($output_contents)
                : $id;

            my $filename = "assets/$digest.$type";
            if ( $self->_s3_obj_cache->{$filename} ) {
                $self->log->debug("found asset in cache: $filename");
            }
            else {
                $self->log->debug("generating new asset: $filename");
                if ($minifier) {
                    $output_contents = $minifier->minify(
                        contents => $output_contents,
                        type     => $type
                    );
                }

                my %putargs = (
                    Bucket => $self->bucket_name,
                    Key    => $filename,
                    Body   => $output_contents,
                    ContentType =>
                        Web::AssetLib::Util::normalizeMimeType($type)
                );

                if ( $self->object_expiration_cb ) {
                    $putargs{Expires}
                        = DateTime::Format::HTTP->format_datetime(
                        $self->object_expiration_cb->( \%putargs ) );
                }

                my $put = $self->s3->PutObject(%putargs);

                $cacheInvalid = 1;
            }

            push @$output,
                Web::AssetLib::Output::Link->new(
                src  => sprintf( '%s/%s', $self->link_url, $filename ),
                type => $type
                );
        }
    }

    $self->_invalidate_s3_obj_cache()
        if $cacheInvalid;

    return $output;
}

method _build__s3_obj_cache (@_) {
    my $results = $self->s3->ListObjects( Bucket => $self->bucket_name );
    my $cache = { map { $_->Key => 1 } @{ $results->Contents } };

    $self->log->dump( 's3 object cache: ', $cache, 'debug' );

    return $cache || {};
}

# before '_export' => sub {
#     my $self = shift;
#     my %args = @_;

#     $self->_validateLinks( bundle => $args{bundle} );
# };

# # check css for links to other assets, and make
# # sure they are in the bundle
# method _validateLinks (:$bundle!) {
#     foreach my $asset ( $bundle->allAssets ) {
#         next unless $asset->contents;

#         if ( $asset->type eq 'css' ) {
#             while ( $asset->contents =~ m/url\([",'](.+)[",']\)/g ) {
#                 $self->log->warn("css contains url: $1");
#             }
#         }
#     }
# }

no Moose;
1;
__END__

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::OutputEngine::S3 - allows exporting an asset or bundle to an AWS S3 Bucket

On first usage, a cache will be generated of all files in the bucket. This way, we know
what needs to be uploaded and what's already there.

=head1 SYNOPSIS

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

=head1 USAGE

This is an output engine plugin for L<Web::AssetLib>.

Instantiate with C<< access_key >>, C<< secret_key >>, C<< bucket_name >>, 
and C<< region >> arguments, and include in your library's output engine list.

=head1 PARAMETERS
 
=head2 access_key

=head2 secret_key
 
AWS access & secret keys. Must have C<List> and C<Put> permissions for destination bucket. 
Required.

=head2 bucket_name

S3 bucket name. Required.

=head2 region

AWS region name of the bucket. Required.

=head2 region

AWS region name of the bucket

=head2 link_url

Used as the base url of any asset that gets exported to S3. Make sure it's public!
Your CDN may go here.

=head2 object_expiration_cb

Provide a coderef used to calculate the Expiration header. Currently, 
no arguments are passed to the callback. Defaults to:

    sub {
        return DateTime->now( time_zone => 'local' )->add( years => 1 );
    };

=head1 SEE ALSO

L<Web::AssetLib>
L<Web::AssetLib::OutputEngine>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut

