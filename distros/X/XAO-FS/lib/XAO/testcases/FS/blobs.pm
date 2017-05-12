package XAO::testcases::FS::blobs;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(XAO::testcases::FS::base);

###############################################################################

sub test_charsets {
    my $self=shift;

    my $odb=$self->get_odb();

    my $list=$odb->fetch('/Customers');
    $self->assert(ref($list), "Failure getting c1 reference");

    use bytes;
    for(my $len=3; $len<=999999; $len*=10) {
        ### dprint "Testing blobs, length=$len";
        my $obj=$list->get_new;

        $obj->add_placeholder(
            name        => 'blob',
            type        => 'blob',
            maxlength   => $len,
        );

        my %expect;
        for(my $t=1; $t<5; ++$t) {
            my $data='';
            for(my $i=0; $i<$len; ++$i) {
                $data.=chr(int(rand(256)));
            }
            $self->assert(length($data)==$len,
                          "Data block we built for len=$len is actually ".length($data)." long");
            $obj->put(blob => $data);
            my $id=$list->put($obj);
            $expect{$id}=$data;
        }

        foreach my $id (keys %expect) {
            my $got=$list->get($id)->get('blob');
            $self->assert($got eq $expect{$id},
                          "Got wrong blob content for id=$id, len=$len");
        }

        $obj->drop_placeholder('blob');
    }
}

###############################################################################
1;
