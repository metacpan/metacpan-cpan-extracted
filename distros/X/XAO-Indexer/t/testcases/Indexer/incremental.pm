package testcases::Indexer::incremental;
use strict;
use XAO::Utils;
use Data::Dumper;

use base qw(testcases::Indexer::base);

sub test_incremental {
    my $self=shift;
    my $odb=$self->siteconfig->odb;

    ##
    # Setting commit interval to test that it remains transparent
    #
    $self->siteconfig->put('/indexer/foo/commit_interval' => 789);

    ##
    # Checking if we have 'Compress::LZO'
    #
    my $have_compression=1;
    eval 'use Compress::LZO';
    if($@) {
        warn "No Compress::LZO, skipping compression\n";
        $have_compression=0;
    }

    $self->generate_content();

    $odb->fetch('/Foo')->get_new->add_placeholder(
        name        => 'indexed',
        type        => 'integer',
        minvalue    => 0,
    );

    ##
    # Creating index one baby step at a time.
    #
    my $index_list=$odb->fetch('/Indexes');
    my $index_new=$index_list->get_new;
    $index_new->put(
        indexer_objname => 'Indexer::IncrFoo',
        compression     => 0,
    );
    $index_list->put(foo => $index_new);
    my $foo_index=$index_list->get('foo');
    dprint "Updating foo index (incrementally)";
    my $iter_count=0;
    while($foo_index->update) {
        ++$iter_count;
        dprint "Iteration $iter_count";
        if($have_compression && $iter_count>0 && $iter_count<10) {
            dprint ".changing compression to ".$iter_count;
            $foo_index->put(compression => $iter_count);
        }
    }

    ##
    # Searching and checking if results we get are correct
    #
    my %matrix=(
        t01 => {
            query       => 'is',
            name        => '',
            text        => '',
        },
        t02 => {
            query       => '   "burden"',
            name        => '57,2,33,115,12,17,62,143,21,76',
        },
        t03 => {
            query       => ' BurDEN  ',
            text        => '2,76,62,33,57,12,17,21,115,143',
        },
        t05 => {
            query       => 'foo',
            name        => '',
        },
        t06 => {
            query       => 'should work with alien',
            name        => '93,66,14,33,133,28,129,17,120,46,88',
        },
        t07 => {
            query       => '"should work with alien"',
            name        => 17,
        },
        t08 => {
            query       => '"should the the alien"',
            name        => 17,
            ignored     => {
                the         => 1,
                should      => 0,
            }
        },
        t09 => {
            query       => '"glassy hypothesis" "A display calls"',
            name        => 147,
            ignored     => {
                a           => 1,
                display     => 0,
            },
        },
        t10 => {
            query       => 'believe',
            text        => '121,50,32,85,52,138,4,147,11,33,84,48,146,99,150,112,91,148,144,82',
        },
        t11 => {
            query       => 'believe rocket',
            text        => '32,147,146,112,91,144',
        },
        t12 => {
            query       => 'believe rocket space',
            text        => '32,147,112,91',
        },
        t13 => {
            query       => 'believe rocket space watch',
            text        => '32,147,91',
        },
        t14 => {
            query       => 'believe rocket space watch alien',
            text        => '32,91',
        },
        t15 => {
            query       => 'believe rocket space watch alien mice',
            text        => '',
        },
        t16 => {
            query       => 'they of be on',
            name        => '98,57,83,93,61,90,51,66,99,86,85,91,131,67,14,116,33,13,20,32,87,31,115,12,112,133,122,103,132,79,40,127,22,64,50,137,35,41,138,58,42,147,16,36,17,68,4,84,6,62,70,143,134,10,26,89,126,69,82,106,118,23,24,80,140,100,52,46,111,141,150,88,59,144,121,37,56,29,130',
            ignored     => {
                they        => 0,
                be          => 0,
                on          => 0,
                of          => 1,
            },
        },
    );
    foreach my $test_id (keys %matrix) {
        my $test=$matrix{$test_id};
        my $query=$test->{query};
        foreach my $oname (sort keys %$test) {
            next if $oname eq 'query';
            next if $oname eq 'ignored';
            my %rcdata;
            my $sr;
            if($test->{ignored}) {
                $sr=$foo_index->search_by_string($oname,$query,\%rcdata);
                foreach my $w (keys %{$test->{ignored}}) {
                    my $expect=$test->{ignored}->{$w};
                    my $got=$rcdata{ignored_words}->{$w};
                    if($expect) {
                        $self->assert(defined($got),
                                      "Expected '$w' to be ignored, but it is not");
                    }
                    else {
                        $self->assert(!defined($got),
                                      "Expected '$w' not to be ignored, but it is (count=".($got||'').")");
                    }
                }
            }
            else {
                $sr=$foo_index->search_by_string($oname,$query);
            }
            my $got=join(',',@$sr);
            my $expect=$test->{$oname};
            $self->assert($got eq $expect,
                          "Test $test_id, ordering $oname, expected $expect, got $got");
        }
    }
}

1;
