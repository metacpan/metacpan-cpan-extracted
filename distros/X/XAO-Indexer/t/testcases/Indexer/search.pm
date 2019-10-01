package testcases::Indexer::search;
use strict;
use utf8;
use XAO::Utils;
use Encode;

use base qw(testcases::Indexer::base);

###############################################################################

sub test_search {
    my $self=shift;
    my $odb=$self->siteconfig->odb;

    $self->generate_content();

    ##
    # Creating a new index
    #
    my $index_list=$odb->fetch('/Indexes');
    my $index_new=$index_list->get_new;
    $index_new->put(indexer_objname => 'Indexer::Foo');
    $index_list->put(foo => $index_new);
    my $foo_index=$index_list->get('foo');
    dprint "Updating foo index";
    $foo_index->update;

    ##
    # Unicode words
    #
    my @ucwords=$self->unicode_words;
    binmode(STDERR,':utf8');

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
        t04 => {
            query       => 'burden',
            name_wnum   => '57,62,2,21,76,143,12,17,33,115',
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
                the         => 150,
                should      => undef,
            }
        },
        t09 => {
            query       => '"glassy hypothesis" "A display calls"',
            name        => 147,
            ignored     => {
                a           => 145,
                display     => undef,
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
            query       => 'believe rocket space watch',
            text        => 'foo_32,foo_147,foo_91',
            use_oid     => 1,
        },
        t20 => {
            query       => $ucwords[0],
            text        => '162,154,153,168,157,165,151,169,158,166,161,170,167,155,164,163',
        },
        t21 => {
            query       => $ucwords[1],
            text        => '162,154,168,169,158,152,161,170,160,156,167,155,164,163',
        },
        t22 => {
            query       => $ucwords[5],
            text        => '162,154,153,168,157,165,151,169,158,152,166,161,170,160,156,164',
        },
        t23 => {
            query       => $ucwords[6],
            text        => '162,154,153,168,165,151,169,166,160,156,167,155,164,163',
        },
        t24 => {
            query       => qq("$ucwords[5] $ucwords[5]"),
            text        => '154',
        },
        t25 => {
            query       => qq($ucwords[0] $ucwords[1]),
            text        => '162,154,168,169,158,161,170,167,155,164,163',
        },
        t26 => {
            query       => qq($ucwords[0] $ucwords[1] $ucwords[2]),
            text        => '168,158,161,170,167,155,164,163',
        },
        t27 => {
            query       => qq($ucwords[0] $ucwords[1] $ucwords[2] $ucwords[3]),
            text        => '168,158,161,167,164,163',
        },
        t28 => {
            query       => qq($ucwords[0] $ucwords[1] $ucwords[2] $ucwords[3] $ucwords[4] $ucwords[5] $ucwords[6]),
            text        => '168,164',
        },
        t29 => {
            query       => qq("$ucwords[3] $ucwords[4] $ucwords[5]"),
            text        => '161',
        },
        t30 => {
            query       => qq(birkh user),
            text        => '',
        },
        t31 => {
            query       => qq(trang),
            text        => '',
        },
    );

    foreach my $test_id (keys %matrix) {
        my $test=$matrix{$test_id};
        my $query=$test->{'query'};
        foreach my $oname (sort keys %$test) {
            next if $oname eq 'query';
            next if $oname eq 'ignored';
            next if $oname eq 'use_oid';
            my %rcdata;
            my $sr;
            if($test->{'ignored'}) {
                $sr=$test->{'use_oid'} ? $foo_index->search_by_string_oid($oname,$query,\%rcdata)
                                       : $foo_index->search_by_string($oname,$query,\%rcdata);
                foreach my $w (keys %{$test->{'ignored'}}) {
                    my $expect=$test->{'ignored'}->{$w};
                    my $got=$rcdata{'ignored_words'}->{$w};
                    if(defined $expect) {
                        $self->assert(defined($got),
                                      "Expected '$w' to be ignored, but it is not");
                        $self->assert($got == $expect,
                                      "Expected count $expect on ignored $w, got $got");
                    }
                    else {
                        $self->assert(!defined($got),
                                      "Expected '$w' not to be ignored, but it is (count=".($got||'').")");
                    }
                }
            }
            else {
                $sr=$test->{'use_oid'} ? $foo_index->search_by_string_oid($oname,$query)
                                       : $foo_index->search_by_string($oname,$query);
            }
            my $got=join(',',@$sr);
            my $expect=$test->{$oname};
            if($got ne $expect) {
                dprint "===>>>> test=$test_id o=$oname got='$got' expected='$expect'";
                dprint ">>>Q='$query'";
                if(@$sr && !$test->{'use_oid'}) {
                    my $coll=$foo_index->get_collection_object;
                    for(my $i=0; $i<5 && $i<@$sr; ++$i) {
                        my $obj=$coll->get($sr->[$i]);
                        my ($name,$text)=$obj->get('name','text');
                        dprint ">>>>i=$i, id=$sr->[$i]";
                        dprint ">>>>>name='$name'";
                        dprint ">>>>>text='$text'";
                    }
                }
            }
            $self->assert($got eq $expect,
                          "Test $test_id, ordering $oname, expected $expect, got $got");
        }
    }
}

###############################################################################
1;
