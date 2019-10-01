package XAO::DO::Indexer::IncrFoo;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Indexer::Base');

###############################################################################

sub analyze_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $coll=$args->{collection};
    my $foo=$args->{object};
    my $foo_id=$args->{object_id};
    my $kw_data=$args->{kw_data};

    my ($name,$text)=$foo->get('name','text');

    $kw_data->{sorting}->{name}->{$foo_id}=$name;
    $kw_data->{sorting}->{text}->{$foo_id}=$text;

    my $bar_list=$foo->get('Bar');
    my $bar_names='';
    my $bar_texts='';
    foreach my $bar_id ($bar_list->keys) {
        my ($n,$t)=$bar_list->get($bar_id)->get('name','text');
        $bar_names.=$n . ' ';
        $bar_texts.=$t . ' ';
    }

    $self->analyze_text($kw_data,$foo_id,$name,$text,$bar_names,$bar_texts);
}

###############################################################################

sub get_collection ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{'index_object'} ||
        throw $self "update - no 'index_object'";

    my $odb=$index_object->glue;
    my $collection=$odb->collection(class => 'Data::Foo');

    my $sr=$collection->search('indexed','eq',0, { limit => 18 });

    return {
        collection  => $collection,
        ids         => $sr,
        partial     => 1,
    };
}

###############################################################################

sub finish_collection ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $cinfo=$args->{collection_info} ||
        throw $self "finish_collection - no 'collection_info' given";

    return unless $cinfo->{partial};

    my $coll=$cinfo->{collection};
    foreach my $id (@{$cinfo->{ids}}) {
        $coll->get($id)->put(indexed => 1);
    }
}

###############################################################################

sub get_orderings ($) {
    my $self=shift;
    return {
        name    => {
            seq     => 1,
            sortall => sub {
                my $cinfo=shift;
                my $collection=$cinfo->{collection};
                return $collection->search({ orderby => 'name' });
            },
        },
        text    => {
            seq     => 2,
            sortall => sub {
                my $cinfo=shift;
                my $collection=$cinfo->{collection};
                return $collection->search({ orderby => 'text' });
            },
        },
    };
}

###############################################################################

sub ignore_limit ($) {
    return 120;
}

###############################################################################
1;
