=head1 NAME

XAO::DO::Web::Indexer -- XAO::Web interface for the indexer

=head1 SYNOPSIS

 <%Indexer
   mode='search'
   index_id='authors'
   orderby='name'
   keywords={<%CgiParam/f name='kw'%>}
   start_item={<%CgiParam/f name='start_item'%>}
   items_per_page='20'
   single.path='/bits/authors/list-single'
   default.path='/bits/authors/list-default'
   header.path='/bits/authors/list-header'
   path='/bits/authors/list-row'
   footer.path='/bits/authors/list-footer'
   ignored.header.path='/bits/common/indexer-ignored-header'
   ignored.separator.template=', '
   ignored.path='/bits/common/indexer-ignored-row'
   ignored.footer.path='/bits/common/indexer-ignored-footer'
   spelling.trigger='3'
   spelling.path='/bits/common/indexer-spelling'
 %>

=cut

###############################################################################
package XAO::DO::Web::Indexer;
use strict;
use Error qw(:try);
use XAO::Utils qw(:args :debug :html);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Indexer.pm,v 1.4 2008/07/05 07:02:46 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'path-map';

    if($mode eq 'search') {
        $self->search($args);
    }
    else {
        $self->SUPER::check_mode($args);
    }
}

###############################################################################

sub search ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_id=$args->{'index_id'} ||
        throw $self "search - no 'index_id' given";

    my $orderby=$args->{'orderby'} ||
        throw $self "search - no 'orderby' given";

    my $keywords;
    if($args->{'keywords.param'}) {
        $keywords=lc($self->cgi->param($args->{'keywords.param'}));
    }
    else {
        $keywords=lc($self->decode_charset($args->{'keywords'})) ||
            throw $self "search - no 'keywords' given";
    }
    $keywords=~s/^\s*(.*?)\s*$/$1/s;

    ### dprint ">>>$index_id >> $orderby >> '$keywords'";

    ##
    # Limit is not supported by the indexed search internally, we
    # enforce it manually below.
    # TODO: Support internally
    #
    my $limit=$args->{'limit'};

    ##
    # Searching. If we have ignored words templates then building the
    # list of ignored words as well.
    #
    my $index_obj=$self->odb->fetch('/Indexes')->get($index_id);
    my $obj_ids;
    my $page=$self->object;
    my $ignored_text='';
    my $spelling_text='';
    if($args->{'ignored.path'} || $args->{'ignored.template'} || $args->{'spelling.path'} || $args->{'spelling.template'}) {
        my %rcdata;
        $obj_ids=$index_obj->search_by_string($orderby,$keywords,\%rcdata);

        if($args->{'ignored.path'} || $args->{'ignored.template'}) {
            my $iw=$rcdata{'ignored_words'};
            my $iw_num=scalar keys %$iw;
            if($iw_num) {
                $ignored_text.=$page->expand($args,{
                    path        => $args->{'ignored.header.path'},
                    template    => $args->{'ignored.header.template'},
                    TOTAL_WORDS => $iw_num,
                }) if $args->{'ignored.header.path'} || $args->{'ignored.header.template'};

                my $first=1;
                foreach my $w (keys %$iw) {
                    if($first) {
                        undef $first;
                    }
                    elsif($args->{'ignored.separator.path'} || $args->{'ignored.separator.template'}) {
                        $ignored_text.=$page->expand($args,{
                            path        => $args->{'ignored.separator.path'},
                            template    => $args->{'ignored.separator.template'},
                        });
                    }
                    $ignored_text.=$page->expand($args,{
                        path        => $args->{'ignored.path'},
                        template    => $args->{'ignored.template'},
                        WORD        => $w,
                        COUNT       => $iw->{$w},
                        TOTAL_WORDS => $iw_num,
                    });
                }

                $ignored_text.=$page->expand($args,{
                    path        => $args->{'ignored.footer.path'},
                    template    => $args->{'ignored.footer.template'},
                    TOTAL_WORDS => $iw_num,
                }) if $args->{'ignored.footer.path'} || $args->{'ignored.footer.template'};
            }
        }

        my $trigger=$args->{'spelling.trigger'} || 3;
        if(@$obj_ids<$trigger && $args->{'spelling.path'} || $args->{'spelling.template'}) {
            $index_obj->suggest_alternative($orderby,$keywords,\%rcdata);

            my @alt_kw;
            my @alt_kw_html;
            foreach my $i (0,1) {
                my $spdata=$rcdata{'spellchecker_alternatives'}->[$i];
                last unless $spdata &&
                            $spdata->{'query'} &&
                            $spdata->{'distance'}<=3;

                my $alt_query=$spdata->{'query'};
                my $alt_query_html=t2ht($alt_query);
                foreach my $pair (@{$spdata->{'pairs'}}) {
                    my $altword=t2ht($pair->[1]);
                    next unless length($altword);
                    $alt_query_html=~s/\b($altword)\b/<em><strong>$1<\/em><\/strong>/sg;
                }

                $alt_kw[$i]=$alt_query;
                $alt_kw_html[$i]=$alt_query_html;
            }
            @alt_kw && dprint "Got alternative keyword '",$alt_kw[0],"' and '",$alt_kw[1],"' for '$keywords'";

            $spelling_text=$page->expand($args,{
                'path'                  => $args->{'spelling.path'},
                'template'              => $args->{'spelling.template'},
                'ALT_KEYWORDS_1'        => $alt_kw[0] || '',
                'ALT_KEYWORDS_1.HTML'   => $alt_kw_html[0] || '',
                'ALT_KEYWORDS_2'        => $alt_kw[1] || '',
                'ALT_KEYWORDS_2.HTML'   => $alt_kw_html[1] || '',
            });
        }
    }
    else {
        $obj_ids=$index_obj->search_by_string($orderby,$keywords);
    }
    dprint "Got ".scalar(@$obj_ids)." results searching $index_id for '$keywords', ordering by $orderby";

    ##
    # Removing some IDs if required. Unfortunately, we have to translate
    # IDs into Coll.IDs first.
    #
    my $obj_coll=$index_obj->get_collection_object;
    if($args->{'exclude.field'} && defined($args->{'exclude.value'})) {
        my $sr=$obj_coll->search($args->{'exclude.field'},'eq',$args->{'exclude.value'});
        if(@$sr) {
            my %e;
            foreach my $coll_id (@$sr) {
                $e{$obj_coll->get($coll_id)->collection_key}=1;
            }
            if($limit && scalar(@$obj_ids)>$limit) {
                splice(@$obj_ids,$limit+1);
            }
            my @new_ids;
            foreach my $coll_id (@$obj_ids) {
                next if $e{$coll_id};
                push(@new_ids,$coll_id);
            }
            dprint ".after exclusion ".scalar(@new_ids);
            $obj_ids=\@new_ids;
        }
    }

    ##
    # Dropping extra elements if there is a 'limit'
    #
    if($limit && scalar(@$obj_ids)>$limit) {
        splice(@$obj_ids,$args->{limit});
        dprint ".reduced to ".scalar(@$obj_ids);
    }

    ##
    # Calculating page browsing parameters..
    #
    my $items_per_page=$args->{items_per_page} || 0;
    my $start_item=($args->{start_item} || 1) - 1;
    my $total_items=scalar(@$obj_ids);
    my $page_items=$total_items-$start_item;
    $page_items=$items_per_page if $items_per_page && $page_items > $items_per_page;
    $page_items=0 if $page_items<0;
    my $limit_reached=($page_items != $total_items) ? 1 : 0;

    ##
    # Common data
    #
    my %common_data=(
        ITEMS_PER_PAGE  => $items_per_page,
        LIMIT_REACHED   => $limit_reached,
        PAGE_ITEMS      => $page_items,
        START_ITEM      => $start_item+1,
        TOTAL_ITEMS     => $total_items,
        IGNORED_TEXT    => $ignored_text,
        SPELLING_TEXT   => $spelling_text,
    );

    ##
    # What fields to retrieve from objects
    #
    my @fields;
    if($args->{fields}) {
        if($args->{fields} eq '*') {
            my $n=$obj_coll->get_new;
            @fields=map {
                $n->describe($_)->{type} eq 'list' ? () : $_
            } $n->keys;
        }
        else {
            @fields=split(/\W+/,$args->{fields});
            shift @fields unless length($fields[0]);
        }
    }

    ##
    # If we only got one item we display special template if it's given
    #
    if($total_items==1 && !$spelling_text && ($args->{'single.template'} || $args->{'single.path'})) {
        my $obj=$obj_coll->get($obj_ids->[0]);

        my %d;
        if(@fields) {
            @d{map { uc } @fields}=$obj->get(@fields);
        }

        $page->display($args,\%common_data,\%d,{
            path            => $args->{'single.path'},
            template        => $args->{'single.template'},
            ID              => $obj->container_key,
        });
        return;
    }

    ##
    # If nothing was found and we have a special 'default' template --
    # we display it and return.
    #
    if(!$total_items && (defined($args->{'default.template'}) || $args->{'default.path'})) {
        $page->display($args,\%common_data,{
            path            => $args->{'default.path'},
            template        => $args->{'default.template'},
        });
        return;
    }

    ##
    # Header
    #
    $page->display($args,\%common_data,{
        path            => $args->{'header.path'},
        template        => $args->{'header.template'},
    }) if $args->{'header.path'} || $args->{'header.template'};

    ##
    # Page content
    #
    foreach my $obj_coll_id ($items_per_page ? @{$obj_ids}[$start_item..($start_item+$page_items-1)] : @$obj_ids) {

        ##
        # The object can be just referenced by an out-of-date index, so
        # we have to check if it really exists in the database.
        #
        my $obj;
        try {
            $obj=$obj_coll->get($obj_coll_id);
        }
        otherwise {
            my $e=shift;
            dprint "Object $obj_coll_id does not exist any more, referenced by index $index_id ($e)";
        };#!
        next unless $obj;

        my %obj_data;
        if(@fields) {
            @obj_data{map { uc } @fields}=$obj->get(@fields);
        }

        $page->display($args,\%common_data,\%obj_data,{
            ID      => $obj->container_key,
        });
    }

    ##
    # Footer
    #
    $page->display($args,\%common_data,{
        path            => $args->{'footer.path'},
        template        => $args->{'footer.template'},
    }) if $args->{'footer.path'} || $args->{'footer.template'};
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2004-2006 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Indexer>,
L<XAO::Web::Intro>.
