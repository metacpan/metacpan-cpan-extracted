package testcases::Web::WebFS;
use strict;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_all {
    my $self=shift;

    my $odb=XAO::Objects->new(objname => 'Web::Page')->odb;
    $self->assert(ref($odb),
                  "Can't load database handler database");
    my $root=$odb->fetch('/');
    $root->put('project' => 'foo');
    $root->build_structure(
        List => {
            type        => 'list',
            class       => 'Data::Product',
            key         => 'product_id',
            structure   => {
                text => {
                    type        => 'text',
                    maxlength   => 50,
                },
                num => {
                    type        => 'integer',
                },
            },
        },
    );
    my $list=$root->get('List');
    my $l1=$list->get_new();
    $l1->put(text => 'ttt');
    $l1->put(num => 123);
    $list->put(l1 => $l1);
    $l1->put(text => 'kkk');
    $l1->put(num => 321);
    $list->put(l2 => $l1);

    my %matrix=(
        t1 => {
            template => '<%FS uri="/project"%>',
            expect   => 'foo',
        },
        t2 => {
            template => '<%FS base.database="/" uri="project"%>',
            expect  => 'foo',
        },
        t3 => {
            template => '<%FS base.database="/project"%>',
            expect  => 'foo',
        },
        t4 => {
            template => '<%FS base.database="/List/l1" uri="num"%>',
            expect  => '123',
        },
        t5 => {
            template => '<%FS mode="show-list"' .
                            ' base.database="/"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' fields="*"' .
                            ' header.path="/bits/WebFS/list-header"' .
                            ' path="/bits/WebFS/list-row"' .
                        '%>',
            expect => '[2]{l1-2-ttt-123}{l2-2-kkk-321}',
        },
        t6 => {
            template => '<%FS mode="show-list"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' fields="*"' .
                            ' path="/bits/WebFS/list-row"' .
                            ' footer.path="/bits/WebFS/list-header"' .
                        '%>',
            expect => '{l1-2-ttt-123}{l2-2-kkk-321}[2]',
        },
        t7 => {
            template => '<%FS mode="show-hash"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List/l2"' .
                            ' fields="*"' .
                            ' path="/bits/WebFS/hash"' .
                        '%>',
            expect => '{l2-kkk-321}',
        },
    );

    foreach my $tn (sort keys %matrix) {
        my $page=XAO::Objects->new(objname => 'Web::Page');
        my $got=$page->expand(template => $matrix{$tn}->{template});
        my $expect=$matrix{$tn}->{expect};
        $self->assert($got eq $expect,
                      "Test '$tn' failed: got '$got', expected '$expect'");
    }
}

###############################################################################

sub test_search {
    my $self=shift;

    my $odb=XAO::Objects->new(objname => 'Web::Page')->odb;
    $self->assert(ref($odb),
                  "Can't load database handler database");
    my $root=$odb->fetch('/');
    $root->put('project' => 'foo');
    $root->build_structure(
        List => {
            type        => 'list',
            class       => 'Data::Product',
            key         => 'product_id',
            structure   => {
                lcase => {
                    type        => 'text',
                    maxlength   => 50,
                },
                UCASE => {
                    type        => 'text',
                    maxlength   => 50,
                },
                mCaSe => {
                    type        => 'text',
                    maxlength   => 50,
                },
                num => {
                    type        => 'integer',
                },
            },
        },
    );
    my $list=$root->get('List');
    my $l1=$list->get_new();
    $l1->put(lcase => 'xyz1');
    $l1->put(num => '1');
    $list->put(l1 => $l1);
    my $l2=$list->get_new();
    $l2->put(UCASE => 'xyz2');
    $l2->put(num => '2');
    $list->put(l2 => $l2);
    my $l3=$list->get_new();
    $l3->put(mCaSe => 'xyz3');
    $l3->put(num => '3');
    $list->put(l3 => $l3);

    my %matrix=(
        t1 => {
            template => '<%FS mode="search"' .
                            ' base.database="/"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' index_1="lcase"' .
                            ' compare_1="eq"' .
                            ' value_1="xyz1"' .
                            ' fields="*"' .
                            ' template="found"' .
                            ' default.template="not found"' .
                        '%>',
            expect => 'found',
        },
        t2 => {
            template => '<%FS mode="search"' .
                            ' base.database="/"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' index_1="UCASE"' .
                            ' compare_1="eq"' .
                            ' value_1="xyz2"' .
                            ' fields="*"' .
                            ' template="found"' .
                            ' default.template="not found"' .
                        '%>',
            expect => 'found',
        },
        t3 => {
            template => '<%FS mode="search"' .
                            ' base.database="/"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' index_1="mCaSe"' .
                            ' compare_1="eq"' .
                            ' value_1="xyz3"' .
                            ' index_2="mCaSe"' .
                            ' compare_2="eq"' .
                            ' value_2="xyz3"' .
                            ' expression="1 and 2"' .
                            ' template="found"' .
                            ' default.template="not found"' .
                        '%>',
            expect => 'found',
        },
        t4 => {
            template => '<%FS mode="search"' .
                            ' base.database="/"' .
                            ' base.clipboard="fs_cache/test_fs"' .
                            ' uri="List"' .
                            ' index_1="mCaSe"' .
                            ' compare_1="eq"' .
                            ' value_1="xyz!"' .
                            ' index_2="mCaSe"' .
                            ' compare_2="eq"' .
                            ' value_2="xyz3"' .
                            ' expression="1 and 2"' .
                            ' template="found"' .
                            ' default.template="not found"' .
                        '%>',
            expect => 'not found',
        },
    );

    foreach my $tn (sort keys %matrix) {
        my $page=XAO::Objects->new(objname => 'Web::Page');
        my $got=$page->expand(template => $matrix{$tn}->{template});
        my $expect=$matrix{$tn}->{expect};
        $self->assert($got eq $expect,
                      "Test '$tn' failed: got '$got', expected '$expect'");
    }
}

###############################################################################

1;
