package testcases::Base::Cache;
use strict;
use XAO::SimpleHash;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;
use XAO::Cache;

use base qw(testcases::Base::base);

###############################################################################

sub test_backends {
    my $self=shift;

    eval {
        require JSON;
    };

    if($@) {
        warn "Skipping $self tests, need JSON\n";
        return;
    }

    my @backends=('Cache::Memory');
    ### my @backends=();

    my $have_memcached;
    eval {
        require Memcached::Client;
        $have_memcached=1;
    };
    if($@) {
        eval {
            require Cache::Memcached;
            $have_memcached=1;
        };
    }

    if($have_memcached) {
        my $toolout=`memcached-tool 127.0.0.1:11211 display 2>&1` // '';
        if($toolout !~ /Count/) {
            dprint "Memcached is not running, disabled testing";
            $have_memcached=0;
        }
    }
    else {
        warn "Install Memcached::Client for XAO::DO::Cache::Memcached backend\n";
    }

    if($have_memcached) {
        push(@backends,'Cache::Memcached');
    }

    my $config=XAO::Objects->new(
        objname     => 'Config',
        sitename    => 'cachetest',
    );

    XAO::Projects::create_project(
        name        => 'cachetest',
        object      => $config,
        set_current => 1,
    );

    $config->init();

    $config->embed('hash' => new XAO::SimpleHash());

    $config->embedded('hash')->put('cache' => {
        memcached   => {
            servers => [ '127.0.0.1:11211' ],
            ### debug   => 99,
        },
        config      => {
            common  => {
                ### debug       => 1,
            },
            withsep => {
                separator   => '!',
            },
            withns1 => {
                namespace   => '',
            },
            withns2 => {
                namespace   => ("Ns" x 100),
                separator   => ':',
            },
            withns3 => {
                namespace   => ("Lg" x 110),
                separator   => ':',
            },
            withdig => {
                digest_keys => 1,
            },
        },
    });

    use utf8;

    my %tests=(
        'null'          => undef,
        1               => "",
        2               => "string",
        binary           => Encode::encode("utf8","binary:\x01\x02\x{2122}"),
        'hash'          => { hash => 'reference' },
        'array'         => [ qw(simple array of data) ],
        'data'          => { complex => [ qw(data) ], with => undef, values => { foo => 'bar' } },
        ''              => 'emptykey',
        0               => 'zero',
        "\x{2122}"      => 'unicode key',
        'one two'       => 'key with a space',
        'unicode'       => "проверка",
        'zerochr'       => "\x00",
        ('.' x 50)      => 'very long key  50',
        ('.' x 230)     => 'very long key 230',
        ('.' x 240)     => 'very long key 240',
        ('.' x 250)     => 'very long key 250',
        ('.' x 260)     => 'very long key 260',
        ('.' x 300)     => 'very long key 300',
        ('.' x 400)     => 'very long key 400',
        ('.' x 500)     => 'very long key 500',
        'text00010'     => join('',map { chr(65+int(rand(26))) } (1..10)),
        'text00100'     => join('',map { chr(65+int(rand(26))) } (1..100)),
        'text01000'     => join('',map { chr(65+int(rand(26))) } (1..1000)),
        'text10000'     => join('',map { chr(65+int(rand(26))) } (1..10000)),
        'binr00010'     => join('',map { chr(int(rand(2000))) } (1..10)),
        'binr00100'     => join('',map { chr(int(rand(2000))) } (1..100)),
        'binr01000'     => join('',map { chr(int(rand(2000))) } (1..1000)),
        'binr10000'     => join('',map { chr(int(rand(2000))) } (1..10000)),
    );

    foreach my $backend (@backends) {

        my @cnames=(
            'default',
            grep { $_ ne 'common' } keys %{$config->get('/cache/config')},
        );

        foreach my $cachename (@cnames) {
            dprint "Testing backend '$backend', cache '$cachename'";

            my %buildcount;

            my $cache=XAO::Cache->new(
                backend     => $backend,
                name        => $cachename,
                retrieve    => sub {
                    my $args=get_args(\@_);
                    my $idx=$args->{'idx'};
                    ### dprint "..RETRIEVE $idx : ",$tests{$idx};
                    ++$buildcount{$idx};
                    return $tests{$idx};
                },
                coords      => ['idx'],
            );

            # For memcached we may have some data from previous runs.
            # Dropping only once to also check for cache
            # cross-contamination because of non-unique keys.
            #
            if($cachename eq 'default') {
                $cache->drop_all();
            }

            foreach my $round (1..5) {
                dprint ".test round $round";

                foreach my $idx (keys %tests) {

                    my $got=$cache->get(idx => $idx);

                    $self->assert($buildcount{$idx} == 1,
                        "Expected build count to be 1, got $buildcount{$idx} on test #$idx, round $round (MEMCACHED not running?)");

                    my $expect=$tests{$idx};

                    if(ref $expect) {
                        my $jgot=JSON::to_json($got,{ canonical => 1, utf8 => 1 });
                        my $jexpect=JSON::to_json($expect,{ canonical => 1, utf8 => 1 });

                        $self->assert($jgot eq $jexpect,
                            "Received '$jgot', expected '$jexpect' for test #$idx, round $round");

                        if($round>1) {
                            $self->assert($got ne $expect,
                                "Expected to receive a copy, not the original reference on test #$idx, round $round");
                        }
                    }
                    elsif(defined $expect) {
                        ### dprint "got=",$got," utf8=",utf8::is_utf8($got);
                        ### dprint "exp=",$expect," utf8=",utf8::is_utf8($expect);

                        if(utf8::is_utf8($expect)) {
                            $self->assert(utf8::is_utf8($got),
                                "Expected '$got' to be UNICODE on test $idx");
                        }
                        else {
                            $self->assert(!utf8::is_utf8($got),
                                "Expected '$got' to NOT be UNICODE on test $idx");
                        }

                        $self->assert(defined $got,
                            "Received 'undef' on test $idx (expected '$expect')");

                        $self->assert($got eq $expect,
                            "Received '$got' on test $idx (expected '$expect')");
                    }
                    else {
                        $self->assert(!defined $got,
                            "Received '".(defined $got ? $got : 'UNDEF')."' on test $idx (expected 'undef')");
                    }
                }
            }

            # Checking force_update
            #
            my $idx=(keys %tests)[0];
            my $count_before=$buildcount{$idx};
            my $got=$cache->get(idx => $idx, force_update => 1);
            my $count_after=$buildcount{$idx};
            $self->assert($count_after == $count_before + 1,
                "Count update with force_update expected to be ".($count_before+1).", got $count_after");
        }
    }
}

###############################################################################

sub test_everything {
    my $self=shift;

    my $count=0;
    my $cache=XAO::Cache->new(
        retrieve    => sub {
            my $self=ref($_[0]) && ref($_[0]) ne 'HASH' ? shift : '';
            my $args=get_args(\@_);
            my $value=$count++ . '-' .
                   $args->{name} . '-' .
                   ($args->{subname} || '');
            ### dprint "RETRIEVE: count=$count value=$value name=",$args->{'name'}," subname=",$args->{'subname'};
            return $value;
        },
        coords      => ['name','subname'],
        size        => 2,
        expire      => 3,
    );
    $self->assert(ref($cache),
                  "Can't create Cache");

    my $d1=$cache->get(name => 'd1');
    $self->assert($d1 eq '0-d1-',
                  "Got wrong value for d1 (expected '0-d1-', got '$d1')");

    my $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '1-d2-s2',
                  "Got wrong value for d2 (expected '1-d2-s2', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's3', foo => 123);
    $self->assert($d2 eq '2-d2-s3',
                  "Got wrong value for d2 (expected '1-d2-s3', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '1-d2-s2',
                  "Got wrong value for d2 (expected '1-d2-s2', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's3', foo => 123);
    $self->assert($d2 eq '2-d2-s3',
                  "Got wrong value for d2 (expected '1-d2-s3', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '1-d2-s2',
                  "Got wrong value for d2 (expected '1-d2-s2', got '$d2')");

    # Checking if it is expired
    #
    sleep(4);
    $d1=$cache->get(name => 'd1', bar => 234);
    $self->assert($d1 eq '3-d1-',
                  "Got wrong value for d1 (expected '3-d1-', got '$d1')");

    for(my $i=0; $i!=100; $i++) {
        $d2=$cache->get(name => 'd2', subname => $i);
    }

    $d1=$cache->get(name => 'd1', bar => 234);
    $self->assert($d1 eq '3-d1-',
                  "Got wrong value for d1 (expected '3-d1-', got '$d1')");

    for(my $i=100; $i!=300; $i++) {
        $d2=$cache->get(name => 'd2', subname => $i);
    }

    # At that point it should be thrown out because of size
    #
    $d1=$cache->get(name => 'd1', bar => 234);
    $self->assert($d1 eq '304-d1-',
                  "Got wrong value for d1 (expected '304-d1-', got '$d1')");

    # Rechecking that after removals the cache still works fine.
    #
    $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '305-d2-s2',
                  "Got wrong value for d2 (expected '305-d2-s2', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's3', foo => 123);
    $self->assert($d2 eq '306-d2-s3',
                  "Got wrong value for d2 (expected '306-d2-s3', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '305-d2-s2',
                  "Got wrong value for d2 (expected '305-d2-s2', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's3', foo => 123);
    $self->assert($d2 eq '306-d2-s3',
                  "Got wrong value for d2 (expected '306-d2-s3', got '$d2')");
    $d2=$cache->get($self, name => 'd2', subname => 's2', foo => 123);
    $self->assert($d2 eq '305-d2-s2',
                  "Got wrong value for d2 (expected '305-d2-s2', got '$d2')");
}

###############################################################################

sub test_size {
    my $self=shift;

    my $counter=0;
    my $cache=XAO::Cache->new(
        retrieve    => sub {
            my $args=get_args(\@_);
            return $args->{name} . '-' . $counter++;
        },
        expire      => 10,
        size        => 0.04,
        coords      => 'name',
    );

    my @matrix=(
        aaaa    => 'aaaa-0',
        aaaa    => 'aaaa-0',
        bbbb    => 'bbbb-1',
        aaaa    => 'aaaa-0',
        bbbb    => 'bbbb-1',
        cccc    => 'cccc-2',
        bbbb    => 'bbbb-1',
        dddd    => 'dddd-3',
        aaaa    => 'aaaa-0',
        bbbb    => 'bbbb-1',
        cccc    => 'cccc-2',
        dddd    => 'dddd-3',
        eeee    => 'eeee-4',
        aaaa    => 'aaaa-5',
        bbbb    => 'bbbb-6',
        cccc    => 'cccc-7',
        dddd    => 'dddd-8',
        eeee    => 'eeee-9',
    );

    for(my $i=0; $i!=@matrix; $i+=2) {
        my $expect=$matrix[$i+1];
        my $got=$cache->get(name => $matrix[$i]);
        $self->assert($got eq $expect,
                      "Test ".($i/2)." failed (expected '$expect', got '$got')");
    }
}

###############################################################################

sub test_drop {
    my $self=shift;

    my $count=0;
    my $cache=XAO::Cache->new(
        retrieve    => sub {
            my $self=ref($_[0]) && ref($_[0]) ne 'HASH' ? shift : '';
            my $args=get_args(\@_);
            return $count++ . '-' .
                   $args->{name} . '-' .
                   ($args->{subname} || '');
        },
        coords      => ['name','subname'],
        size        => 2,
        expire      => 3,
    );
    $self->assert(ref($cache),
                  "Can't create Cache");

    $cache->get(name => 'd1');
    $cache->get(name => 'd2');
    $cache->get(name => 'd3');
    $cache->get(name => 'd4');
    $cache->get(name => 'd5');

    my @matrix=(
        d1 => {
            d1  => '5-d1-',
            d2  => '1-d2-',
            d3  => '2-d3-',
            d4  => '3-d4-',
            d5  => '4-d5-',
        },
        d5 => {
            d1  => '5-d1-',
            d2  => '1-d2-',
            d3  => '2-d3-',
            d4  => '3-d4-',
            d5  => '6-d5-',
        },
        d3 => {
            d1  => '5-d1-',
            d2  => '1-d2-',
            d3  => '7-d3-',
            d4  => '3-d4-',
            d5  => '6-d5-',
        },
        d4 => {
        },
        d2 => {
        },
        d5 => {
        },
        d1 => {
        },
        d3 => {
            d1  => '8-d1-',
            d2  => '9-d2-',
            d3  => '10-d3-',
            d4  => '11-d4-',
            d5  => '12-d5-',
        },
    );

    for(my $i=0; $i<@matrix; $i+=2) {
        my $dn=$matrix[$i];
        my $expect=$matrix[$i+1];
        $cache->drop(name => $dn);
        foreach my $en (sort keys %$expect) {
            my $got=$cache->get(name => $en);
            $self->assert($got eq $expect->{$en},
                          "Got wrong value after dropping $dn (expect '$expect->{$en}', got '$got')");
        }
    }
}

###############################################################################
1;
