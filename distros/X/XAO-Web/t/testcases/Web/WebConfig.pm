package testcases::Web::WebConfig;
use strict;
use XAO::Projects;
use XAO::Utils;
use Data::Dumper;

use base qw(XAO::testcases::Web::base);

sub test_all {
    my $self=shift;

    my $config=XAO::Projects::get_current_project();
    $config->clipboard->put('test' => 'foo');
    $self->assert($config->clipboard->get('test') eq 'foo',
                  "Clipboard does not work");

    # Making sure that get returns the actual stored hash, not its copy.
    #
    $config->put('/test/count' => 123);
    $self->assert($config->get('/test/count') == 123,
                  "Failed to get stored value (1)");
    $self->assert($config->get('/test')->{'count'} == 123,
                  "Failed to get stored value (2)");
    $self->assert($config->get('test')->{'count'} == 123,
                  "Failed to get stored value (3)");

    ++$config->get('/test')->{'count'};

    $self->assert($config->get('/test/count') == 124,
                  "Failed to get incremented value (1)");
    $self->assert($config->get('/test')->{'count'} == 124,
                  "Failed to get incremented value (2)");
    $self->assert($config->get('test')->{'count'} == 124,
                  "Failed to get incremented value (3)");

    ### use Data::Dumper;
    ### print Dumper($config->get('test'));

    $config->cleanup();

    ### print Dumper($config->get('test'));

    $self->assert(!defined($config->clipboard->get('test')),
                  "Cleanup does not work");
}

###############################################################################

sub test_header_args ($) {
    my $self=shift;

    my $config=XAO::Projects::get_current_project();

    foreach my $v (qw(-cache_control Cache-Control cache-control Cache_control)) {
        my $a=$config->header_args($v => $v);

        $self->assert(ref($a) eq 'HASH',
            "Expected to get a hash from header_args(), got $a");

        ### dprint "Headers after '$v': ".Dumper($a);

        my $key='cache_control';
        my $got=$a->{'cache_control'};

        $self->assert(defined $got,
            "Expected to have a value on '$key', got undef");

        $self->assert($got eq $v,
            "Expected value on '$key' be '$v', got '$got'");
    }
}

###############################################################################
1;
