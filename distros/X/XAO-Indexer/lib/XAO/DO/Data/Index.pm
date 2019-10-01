=head1 NAME

XAO::DO::Data::Index - XAO Indexer storable index object

=head1 SYNOPSIS

 my $keywords=$cgi->param('keywords');
 my $cn_index=$odb->fetch('/Indexes/customer_names');
 my $sr=$cn_index->search_by_string('name',$keywords);

=head1 DESCRIPTION

XAO::DO::Data::Index is based on XAO::FS Hash object and provides
wrapper methods for most useful XAO Indexer functions.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Data::Index;
use strict;
use Error qw(:try);
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;
use base XAO::Objects->load(objname => 'FS::Hash');

###############################################################################

=item build_structure ()

If called without arguments creates initial structure in the object
required for it to function properly. Safe to call on already existing
data.

Will create a certain number data fields to be then used to store
specifically ordered object IDs according to get_orderings() method of
the corresponding indexer. The number is taken from site's configuration
'/indexer/max_orderings' parameter and defaults to 10.

Should be called from site config's build_structure() method in a way
similar to this:

 $odb->fetch('/Indexes')->get_new->build_structure;

Where '/Indexes' is a container objects with class 'Data::Index'. It
does not have to be named 'Indexes'.

=cut

sub build_structure ($@) {
    my $self=shift;

    if(@_) {
        my $args=get_args(\@_);
        $self->SUPER::build_structure($args);
    }
    else {
        $self->SUPER::build_structure($self->data_structure);
    }
}

###############################################################################

=item data_structure (;$$)

Returns data structure of Index data object, can be directly used in
build_structure() method.

The first optional argument is the number of fields to
hold orderings. If it is not given site configuration's
'/indexer/common/max_orderings' parameter is used, which defaults to 10.

Second parameter sets the maximum size of a single keyword data chunk
that lists all places where this word was found and their positions. The
value is taken from '/indexer/common/max_kwdata_length' configuration
parameter and defaults to 65000.

It depends highely on the type of text you index, but as a rough
estimate, for every 1,000 allowed words you need 20,000 for the
data. So, if your ignore_limit is set to 50,000 you might want to set
max_kwdata_length to 1,000,000. If you are using MySQL you might also
need to adjust max_allowed_packet accordingly -- to be slightly higher
than the max_kwdata_length. Using compression these values can be
reduced -- as the limit gets applied after compression.

=cut

sub data_structure ($;$$) {
    my ($self,$max_orderings,$max_kwdata_length)=@_;

    if(!$max_orderings) {
        my $config=XAO::Projects::get_current_project;
        $max_orderings=
            $config->get('/indexer/common/max_orderings') ||
            $config->get('/indexer/max_orderings') ||
            10;
    }

    if(!$max_kwdata_length) {
        my $config=XAO::Projects::get_current_project;
        $max_kwdata_length=
            $config->get('/indexer/common/max_kwdata_length') ||
            $config->get('/indexer/max_kwdata_length') ||
            65000;
    }

    return {
        Data => {
            type        => 'list',
            class       => 'Data::IndexData',
            key         => 'data_id',
            structure   => {
                count => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                create_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 1,
                },
                # Before we switch to 'utf8' here (if ever) this problem
                # needs to be solved:
                # MySQL treats "Muller" and "Müller" as identical words
                # not letting them happen twice in the "unique" keyword
                # field.
                # This is due to the fact that collation in MySQL uses
                # "level 1" differences, as this script shows:
                #
                # #!/usr/bin/env perl
                # use strict;
                # use warnings;
                # use utf8;
                # use Unicode::Collate;
                # use Encode;
                #
                # binmode(STDOUT,":utf8");
                #
                # my $c;
                #
                # my $u1='Muller';
                # my $u2='Müller';
                # my $u3='MULLER';
                # my $u4='MÜLLER';
                # my $u5='Buller';
                #
                # foreach my $lev (4,3,2,1) {
                #     print "---level=$lev\n";
                #
                #     $c=Unicode::Collate->new(
                #         level => $lev,
                #     );
                #
                #     sss($u1,$u1);
                #     sss($u2,$u2);
                #     sss($u1,$u2);
                #     sss($u1,$u3);
                #     sss($u2,$u4);
                #     sss($u1,$u4);
                #     sss($u1,$u5);
                #     sss($u2,$u5);
                # }
                #
                # sub sss {
                #     my ($a,$b)=@_;
                #     my $r=$c->eq($a,$b);
                #     print "a='$a' (".utf8::is_utf8($a).") ".
                #           "b='$b' (".utf8::is_utf8($b).") r='$r'\n";
                # }
                #
                # Perhaps the keyword should be left as binary to
                # avoid possible inconsistencies between perl and
                # mysql collation implementations and some kind of
                # normalization needs to be done before keywords are
                # inserted?
                #
                # Or, as another (slightly slower) idea, we can rely on
                # MySQL: before inserting a keyword we can search the
                # index not trusting the md5 by letting mysql literally
                # compare the keyword with all collations in place. And
                # then merge data into that keyword even when it's not a
                # literal equivalent of the one we have.
                #
                keyword => {
                    type        => 'text',
                    ### charset     => 'utf8', # see note above!
                    maxlength   => 50,
                    index       => 1,
                    unique      => 1,
                },
                map {
                    (   "id_$_" => {
                            type        => 'blob',
                            maxlength   => $max_kwdata_length,
                        },
                        "idpos_$_" => {
                            type        => 'blob',
                            maxlength   => $max_kwdata_length,
                        }
                    );
                } (1..$max_orderings),
            },
        },
        Ignore => {
            type        => 'list',
            class       => 'Data::IndexIgnore',
            key         => 'data_id',
            structure   => {
                count => {
                    type        => 'integer',
                    minvalue    => 0,
                },
                create_time => {
                    type        => 'integer',
                    minvalue    => 0,
                    index       => 1,
                },
                keyword => {
                    type        => 'text',
                    #charset     => 'utf8',
                    maxlength   => 50,
                    index       => 1,
                    unique      => 1,
                },
            },
        },
        compression => {
            type        => 'integer',
            minvalue    => 0,
            maxvalue    => 99,
        },
        indexer_objname => {
            type        => 'text',
            maxlength   => 100,
            charset     => 'latin1',
        },
    };
}

###############################################################################

=item get_collection_object ()

A shortcut to indexer's get_collection_object method. If there is no
such method, emulates it with a call to get_collection, which is usually
slower (for compatibility).

=cut

sub get_collection_object ($) {
    my $self=shift;

    my $indexer=$self->indexer;
    if($indexer->can('get_collection_object')) {
        $indexer->get_collection_object(
            index_object    => $self,
        );
    }
    else {
        dprint "No get_collection_object() method, resorting to slower get_collection()";
        return $self->indexer->get_collection(
            index_object    => $self,
        )->{'collection'};
    }
}

###############################################################################

=item get_collection ()

Simply a shortcut to indexer's get_collection() method.

=cut

sub get_collection ($) {
    my $self=shift;
    return $self->indexer->get_collection(
        index_object    => $self,
    );
}

###############################################################################

=item indexer (;$)

Returns corresponding indexer object, its name taken from
'indexer_objname' property.

=cut

# TODO: there is something inherently wrong with all this passing around
# of two different objects. Should be done differently. (am@, 3/21/2005)

sub indexer ($$) {
    my ($self,$indexer_objname)=@_;

    $indexer_objname||=$self->get('indexer_objname');

    $indexer_objname || throw $self "init - no 'indexer_objname'";

    return XAO::Objects->new(
        objname     => $indexer_objname,
        index_id    => $self->container_key,
        index_obj   => $self,
    ) || throw $self "init - can't load object '$indexer_objname'";
}

###############################################################################

=item search_by_string ($)

Most widely used method - parses string into keywords and performs a
search on them. Honors double quotes to mark words that have to be
together in a specific order.

Returns a reference to the list of collection IDs. IDs are not checked
against real collection. If index is not in sync with the content of the
actual data collection IDs of objects that don't exist any more can be
returned as well as irrelevant results.

Example:

 my $keywords=$cgi->param('keywords');
 my $cn_index=$odb->fetch('/Indexes/customer_names');
 my $sr=$cn_index->search_by_string('name',$keywords);

Optional third argument can refer to a hash. If it is present, the hash
will be filled with some internal information. Most useful of which is
the list of ignored words from the query, stored as 'ignored_words' in
the hash.

Example:
 my %sd;
 my $sr=$cn_index->search_by_string('name',$keywords,\%sd);
 if(keys %{$sd{ignored_words}}) {
     print "Ignored words:\n";
     foreach my $word (sort keys %{$sd{ignored_words}}) {
         print " * $word ($sd{ignored_words}->{$word}\n";
     }
 }

=cut

sub search_by_string ($$$;$) {
    my ($self,$ordering,$str,$rcdata)=@_;

    return $self->indexer->search(
        index_object    => $self,
        search_string   => $str,
        ordering        => $ordering,
        rcdata          => $rcdata,
    );
}

###############################################################################

=item search_by_string_oid ($)

The same as search_by_string() method, but translates results from
collection IDs to object IDs. Use it with care, on large result sets it
may take significant time!

=cut

sub search_by_string_oid ($$$;$) {
    my ($self,$ordering,$str,$rcdata)=@_;

    my $cids=$self->indexer->search(
        index_object    => $self,
        search_string   => $str,
        ordering        => $ordering,
        rcdata          => $rcdata,
    );

    my $coll_obj=$self->get_collection_object;
    my @oids;
    foreach my $cid (@$cids) {
        try {
            push(@oids,$coll_obj->get($cid)->container_key);
        }
        otherwise {
            my $e=shift;
            dprint "Stale cid=$cid while search for '$str': $e";
        };
    }

    return \@oids;
}

###############################################################################

=item suggest_alternative ($$$)

Returns an alternative search string by trying words found during
search_by_string and stored in the returned data array.

EXPERIMENTAL UNSTABLE API.

=cut

sub suggest_alternative ($$$$;$) {
    my ($self,$ordering,$str,$rcdata,$need_results)=@_;

    return $self->indexer->suggest_alternative(
        index_object    => $self,
        search_string   => $str,
        ordering        => $ordering,
        rcdata          => $rcdata,
        need_results    => $need_results,
    );
}

###############################################################################

=item update ($)

Updates the index with the current data. Exactly what data it is based
on depends entirely on the corresponding indexer object.

With drivers that support transactions the update is wrapped into a
transaction, so that index data is consistent while being updated.

=cut

sub update ($) {
    my $self=shift;

    $self->indexer->update(
        index_object    => $self,
    );
}

###############################################################################

=item build_dictionary (%)

Updates the dictionary of words stored in this index. Actual
implementation depends on the specific spellchecker, as configured for
the project.

=cut

sub build_dictionary ($) {
    my $self=shift;

    return $self->indexer->build_dictionary(
        index_object    => $self,
    );
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2003 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Indexer>,
L<XAO::DO::Indexer::Base>,
L<XAO::FS>,
L<XAO::Web>.
