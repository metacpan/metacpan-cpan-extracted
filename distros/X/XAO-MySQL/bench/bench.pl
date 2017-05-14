#!/usr/bin/perl -w
use strict;
use blib;
use XAO::Objects;
use XAO::Utils;
use Benchmark;

XAO::Utils::set_debug(1);

if(@ARGV<1) {
    print <<EOT;
Usage: $0 DSN [user [password [count]]]

The database you give will be COMPLETELY DESTROYED!

EOT
    exit 1;
}

my $odb=XAO::Objects->new(objname           => 'FS::Glue',
                          dsn               => $ARGV[0],
                          user              => $ARGV[1],
                          password          => $ARGV[2],
                          empty_database    => 'confirm');
my $count=$ARGV[3] || 10000;

$odb->fetch('/')->build_structure(
    int0 => {
        type        => 'integer',
    },
    int0_255 => {
        type        => 'integer',
        maxvalue    => 255,
        minvalue    => 0,
    },
    str0_100 => {
        type        => 'text',
        maxlength   => 100,
    },
    str0_10000 => {
        type        => 'text',
        maxlength   => 10000,
    },
    List1 => {
        type        => 'list',
        class       => 'Data::Customer',
        key         => 'list0_key',
        structure   => {
            int1 => {
                type        => 'integer',
            },
            int1_255 => {
                type        => 'integer',
                maxvalue    => 255,
                minvalue    => 0,
            },
            str1_100 => {
                type        => 'text',
                maxlength   => 100,
            },
            str1_10000 => {
                type        => 'text',
                maxlength   => 10000,
            },
            List2 => {
                type        => 'list',
                class       => 'Data::Order',
                key         => 'list0_key',
                structure   => {
                    int2 => {
                        type        => 'integer',
                    },
                    int2_255 => {
                        type        => 'integer',
                        maxvalue    => 255,
                        minvalue    => 0,
                    },
                    str2_100 => {
                        type        => 'text',
                        maxlength   => 100,
                    },
                    str2_10000 => {
                        type        => 'text',
                        maxlength   => 10000,
                    },
                    List3 => {
                        type        => 'list',
                        class       => 'Data::Product',
                        key         => 'list0_key',
                        structure   => {
                            int3 => {
                                type        => 'integer',
                            },
                            int3_255 => {
                                type        => 'integer',
                                maxvalue    => 255,
                                minvalue    => 0,
                            },
                            str3_100 => {
                                type        => 'text',
                                maxlength   => 100,
                            },
                            str3_10000 => {
                                type        => 'text',
                                maxlength   => 10000,
                            },
                        },
                    },
                },
            },
        },
    },
);

print "============= /proc/cpuinfo\n";
system '/bin/cat /proc/cpuinfo';
print "============= uname -a\n";
system '/bin/uname -a';
print "============= args\n";
print "$0 ",join(' ',@ARGV),"\n";
print "============= date\n";
print scalar(localtime),"\n";
print "============= benchmark\n";

my $root=$odb->fetch('/');
my $t=123;
timethese($count * 5, {
    wr_i0 => sub {
        $root->put(int0 => 123123123);
    },
    wr_i0_c => sub {
        $root->put(int0 => $t++);
    },
    wr_i0_s => sub {
        $root->put(int0_255 => 123);
    },
    rd_i0 => sub {
        $root->get('int0');
    },
    rd_i0_s => sub {
        $root->get('int0_255');
    },
});

my $list1=$root->get('List1');
my $list1_obj=$list1->get_new;
$list1_obj->put(int1 => 123123123);
$list1_obj->put(int1_255 => 123);
$list1_obj->put(str1_100 => 'x' x 50);
$list1_obj->put(str1_10000 => 'x' x 5000);

$list1->put('xxx' => $list1_obj);
my $list2=$list1->get('xxx')->get('List2');
my $list2_obj=$list2->get_new;
$list2_obj->put(int2 => 123123123);
$list2_obj->put(int2_255 => 123);
$list2_obj->put(str2_100 => 'x' x 50);
$list2_obj->put(str2_10000 => 'x' x 5000);

$list2->put('zzz' => $list2_obj);
my $list3=$list2->get('zzz')->get('List3');
my $list3_obj=$list3->get_new;
$list3_obj->put(int3 => 123123123);
$list3_obj->put(int3_255 => 123);
$list3_obj->put(str3_100 => 'x' x 50);
$list3_obj->put(str3_10000 => 'x' x 5000);

my $i1=0;
my $i2=0;
my $i3=0;
timethese($count, {
    wr_l1_r => sub {
        $list1->put($list1_obj);
    },
    wr_l1_c => sub {
        $list1->put(++$i1 => $list1_obj);
    },
    wr_l2_r => sub {
        $list2->put($list2_obj);
    },
    wr_l2_c => sub {
        $list2->put(++$i2 => $list2_obj);
    },
    wr_l3_r => sub {
        $list3->put($list3_obj);
    },
    wr_l3_c => sub {
        $list3->put(++$i3 => $list3_obj);
    },
});

$i1=$i2=$i3=0;
timethese($count, {
    rd_l1_c => sub {
        $list1->get(++$i1);
    },
    rd_l2_c => sub {
        $list2->get(++$i2);
    },
    rd_l3_c => sub {
        $list3->get(++$i3);
    },
});

$i1=$i2=$i3=0;
timethese($count, {
    rd_l1_v => sub {
        my $obj=$list1->get(++$i1);
        my @a=$obj->get(qw(int1 int1_255 str1_100 str1_10000));
    },
    rd_l2_v => sub {
        my $obj=$list2->get(++$i2);
        my @a=$obj->get(qw(int2 int2_255 str2_100 str2_10000));
    },
    rd_l3_v => sub {
        my $obj=$list3->get(++$i3);
        my @a=$obj->get(qw(int3 int3_255 str3_100 str3_10000));
    },
});

exit 0;
