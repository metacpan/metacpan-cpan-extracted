package WebService::MyGengo::Test::Util::Job;

use strict;
use warnings;

use WebService::MyGengo::Job;

use Test::More; # Just for diag routines
use Exporter;

use vars qw(@ISA @EXPORT);
use base qw(Exporter);

@EXPORT = qw(create_dummy_job teardown_jobs _dummy_job_struct);

=head2 \%_dummy_job_struct

A hash of parameters can be used to fabricate a new Job.

See L<http://mygengo.com/api/developer-docs/methods/translate-job-post/>

See L<http://mygengo.com/api/developer-docs/payloads/>

=cut
sub _dummy_job_struct {
    return {
        "mt"            => 0
        , "slug"        => "todo What is this?"
        , "lc_tgt"      => "ja"
        , "body_src"    => rand()." ba-weep-gra-na-weep-ninny-bong"
        , "tier"        => "standard"
        , "custom_data" => rand()." thar be custom de-ta heaaar"
        , "lc_src"      => "en"
        , "auto_approve"=> 0
        , "force"       => 0
        , comment       => rand()." Here's a comment for ya."
        };
}

=head2 create_dummy_job( $client, \%args? )

Create a new Job via the given $client.

If \%args are provided they will override the defaults from
_dummy_job_struct.

=cut
sub create_dummy_job {
    my ( $client, $args ) = ( shift, @_ );

    my $struct = _dummy_job_struct();

    $args and @$struct{ keys %$args } = values %$args;

    my $job = WebService::MyGengo::Job->new( $struct );
    $job = $client->submit_job( $job );

    return $job;
}


1;
