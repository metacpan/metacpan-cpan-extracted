=head1 NAME

XAO::DO::Indexer::Base -- base class for all indexers

=head1 SYNOPSIS

 package XAO::DO::Indexer::Foo;
 use strict;
 use XAO::Utils;
 use XAO::Objects;
 use base XAO::Objects->load(objname => 'Indexer::Base');

 sub analyze_object ($%) {
    my $self=shift;
    ....

=head1 DESCRIPTION

Provides indexer functionality that can (and for some methods MUST) be
overriden by objects derived from it.

Methods are:

=over

=cut

###############################################################################
package XAO::DO::Indexer::Base;
use strict;
use Error qw(:try);
use Encode;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project);
use XAO::IndexerSupport;
use Digest::MD5 qw(md5_base64);
use base XAO::Objects->load(objname => 'Atom');

### use Data::Dumper;

sub sequential_helper ($$;$$$);

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Base.pm,v 1.47 2008/07/06 05:47:54 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item analyze_text ($@)

Splits given text strings into keywords and stores them into kw_data
hash (first argument) using unique id from the second argument.

=cut

sub analyze_text ($$$@) {
    my $self=shift;
    my $kw_data=shift;
    my $unique_id=0+shift;

    $kw_data->{'keywords'}||={};
    my $kw_info=$kw_data->{'keywords'};

    my $field_num=0;
    foreach my $text (@_) {
        my $kwlist=$self->analyze_text_split($field_num+1,$text);
        my $pos=1;
        foreach my $kw (@$kwlist) {
            $kw_data->{'count_uid'}->{$unique_id}->{$kw}++;
            if(! exists $kw_data->{'ignore'}->{$kw}) {
                my $kwt=$kw_info->{lc($kw)}->{$unique_id};
                if(! $kwt->[$field_num]) {
                    $kw_info->{lc($kw)}->{$unique_id}->[$field_num]=[ $pos ];
                }
                elsif(scalar(@{$kwt->[$field_num]}) < 15) {
                    push(@{$kwt->[$field_num]},$pos);
                }
                else {
                    ### dprint "Only first 15 same keywords in a field get counted ($kw, $field_num, $pos)";
                }
            }
            $pos++;
        }
        $field_num++;
    }
}

###############################################################################

sub analyze_text_split ($$$) {
    my ($self,$field_num,$text)=@_;
    my @a=split(/\W+/,lc($text));
    shift @a if @a && !$a[0];
    return \@a;
}

###############################################################################

sub config_param ($$) {
    my ($self,$param,$default)=@_;

    my $config=get_current_project();
    my $value;
    if($config) {
        my $index_id=$self->{'index_id'} ||
            throw $self "config_param - no index_id (improper creation?)";
        $value=$config->get("/indexer/$index_id/$param");
        $value||=$config->get("/indexer/default/$param");
    }

    return $value || $default;
}

###############################################################################

sub ignore_limit ($) {
    my $self=shift;
    return $self->config_param('ignore_limit',500);
}

###############################################################################

sub commit_interval ($) {
    my $self=shift;
    return $self->config_param('commit_interval',0);
}

###############################################################################

sub init ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{'index_object'} ||
        throw $self "init - no 'index_object'";

    dprint ref($self)."::init - XXX, nothing's in here yet....";
}

###############################################################################

sub search ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{'index_object'} ||
        throw $self "search - no 'index_object'";

    eval 'use Compress::LZO';
    dprint "No Compress::LZO, comression won't work" if $@;

    my $str=$args->{'search_string'};
    $str='' unless defined $str;
    $str=~s/^\s*(.*?)\s*$/$1/sg;
    if(!length($str)) {
        dprint ref($self)."::search - empty search string";
        return [ ];
    }

    my $ordering=$args->{'ordering'} ||
        throw $self "search - no 'ordering'";
    my $ordering_seq=$self->get_orderings->{$ordering}->{'seq'} ||
        throw $self "search - no sequence in '$ordering' ordering";

    ##
    # Optional hash reference to be filled with statistics
    #
    my $rcdata=$args->{'rcdata'};
    $rcdata->{'ignored_words'}={ } if $rcdata;

    ### dprint "Searching for '$str' (ordering=$ordering, seq=$ordering_seq)";

    ##
    # Preparing spellchecker if needed
    #
    my $use_spellchecker=$rcdata && $self->config_param('use_spellchecker');
    my $spellchecker;
    if($use_spellchecker) {
        $spellchecker=$self->get_spellchecker;
        $spellchecker->switch_index($index_object->container_key);
        $rcdata->{'spellchecker_words'}={ };
    }

    ##
    # We cache ignored words. Cache returns a hash reference with
    # ignored words.
    #
    my $i_cache=get_current_project()->cache(
        name        => 'indexer_ignored',
        coords      => [ 'index_id' ],
        expire      => 60,
        retrieve    => sub {
            my $index_list=shift;
            my $args=get_args(\@_);
            my $index_id=$args->{'index_id'};
            my $ign_list=$index_list->get($index_id)->get('Ignore');
            my %ignored=map {
                $ign_list->get($_)->get('keyword','count');
            } $ign_list->keys;
            return \%ignored;
        },
    );
    my $ignored=$i_cache->get($index_object->container_object, {
        index_id    => $index_object->container_key,
    });

    ##
    # Building multi-word sequences. If some words are in the
    # ignore-list we skip them, but assume that there is a word in
    # between in word sequences. For instance 'wag the dog' would become
    # { wag => 1, dog => 3 }, providing that 'the' is ignored.
    #
    my @mdata;
    $str=~s/"(.*?)"/push(@mdata,$1);" "/sge;
    my @multi;
    my @simple;
    foreach my $elt (@mdata) {
        my $s=$self->analyze_text_split(0,$elt);
        next unless @$s;
        if(@$s==1) {
            push(@simple,$s->[0]);
        }
        else {
            if($spellchecker) {
                my $pairs=$spellchecker->suggest_replacements(join(' ',@$s));
                @{$rcdata->{'spellchecker_words'}}{keys %$pairs}=values %$pairs;
            }
            my @t=map {
                if(exists $ignored->{$_}) {
                    if($rcdata) {
                        $rcdata->{'ignored_words'}->{$_}=$ignored->{$_};
                    }
                    undef;
                }
                else {
                    $_;
                }
            } @$s;
            shift(@t) while @t && !defined($t[0]);
            pop(@t) while @t && !defined($t[$#t]);
            if(@t==1) {
                push(@simple,$t[0]);
            }
            else {
                push(@multi,\@t);
            }
        }
    }
    undef @mdata;

    ##
    # Simple words
    #
    if($spellchecker) {
        my $pairs=$spellchecker->suggest_replacements($str);
        @{$rcdata->{'spellchecker_words'}}{keys %$pairs}=values %$pairs;
    }
    push(@simple,map {
        if(exists $ignored->{$_}) {
            if($rcdata) {
                $rcdata->{'ignored_words'}->{$_}=$ignored->{$_};
            }
            ();
        }
        else {
            $_;
        }
    } @{$self->analyze_text_split(0,$str)});

    ##
    # If we are asked to provide data, storing splitted words.
    #
    if($rcdata) {
        $rcdata->{'words_single'}=\@simple;
        $rcdata->{'words_multi'}=\@multi;
        $rcdata->{'results_count'}=0;
    }
    ### dprint Dumper(\@multi),Dumper(\@simple);

    ##
    # First we search for multi-words sequences in the assumption that
    # they will provide smaller result sets or no results at all.
    #
    my @results;
    my $data_list=$index_object->get('Data');
    foreach my $marr (sort { scalar(@$b) <=> scalar(@$a) } @multi) {
        my $res=$self->search_multi($data_list,$ordering_seq,$marr);
        ### dprint "Multi Results: ",Dumper($marr),Dumper($res);
        if(!@$res) {
            return [ ];
        }
        push(@results,$res);
    }

    ##
    # Searching for simple words, position independent. Longer words first.
    #
    foreach my $kw (sort { length($b) <=> length($a) } @simple) {
        my $res=$self->search_simple($data_list,$ordering_seq,$kw);
        ### dprint "Simple Results: '$kw' ",Dumper($res);
        if(!@$res) {
            return [ ];
        }
        push(@results,$res);
    }

    ##
    # Joining all results together
    #
    if($rcdata) {
        my $sr=XAO::IndexerSupport::sorted_intersection(@results);
        $rcdata->{'results_count'}=scalar(@$sr);
        return $sr;
    }
    else {
        return XAO::IndexerSupport::sorted_intersection(@results);
    }
}

###############################################################################

sub search_multi ($$$$) {
    my ($self,$data_list,$oseq,$marr)=@_;

    ##
    # Getting results starting from the longest set of words in the hope
    # that we get no match at all. On null results exit immediately.
    #
    my %rawdata;
    foreach my $kw (sort { length($b || '') <=> length($a || '') } @$marr) {
        last unless defined $kw;
        my $sr=$data_list->search('keyword','eq',$kw);
        return [ ] unless @$sr;

        use bytes;

        my $r=$data_list->get($sr->[0])->get("idpos_$oseq");

        my $compression_flag=unpack('w',$r);
        if(defined $compression_flag && $compression_flag == 0) {

            # The temporary variable is required. See the note on the
            # other decompress() use.
            #
            my $c=substr($r,1);
            $r=Compress::LZO::decompress($c);
        }

        $rawdata{$kw}=$r;
    }

    return XAO::IndexerSupport::sorted_intersection_pos($marr,\%rawdata);
}

###############################################################################

sub search_simple ($$$$) {
    my ($self,$data_list,$oseq,$keyword)=@_;

    my $sr=$data_list->search('keyword','eq',$keyword);
    return [ ] unless @$sr;

    my $iddata=$data_list->get($sr->[0])->get("id_$oseq");

    ##
    # Sometimes the data gets damaged or is in the process of being
    # updated. This can lead to unparsable results.
    #
    my $result;
    try {
        use bytes;

        my $compression_flag=unpack('w',$iddata);
        if(defined $compression_flag && $compression_flag==0) {

            # Directly passing substr(..) into decompress fails in perl
            # 5.22 with "buffer parameter is not a SCALAR". Likely this
            # is because substr is actually an lvalue and not a true
            # scalar. Worked fine in earlier versions of perl. Putting
            # it in a temporary variable fixes that.
            #
            my $c=scalar(substr($iddata,1));
            $iddata=Compress::LZO::decompress($c);

            defined $iddata ||
                throw $self "Can't decompress data";
        }

        $result=[ unpack('w*',$iddata) ];
    }
    otherwise {
        my $e=shift;
        eprint "Bad indexer data for kw='$keyword', sorting='$oseq': $e";
        $result=[ ];
    };

    return $result;
}

###############################################################################

sub suggest_alternative ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{'index_object'} ||
        throw $self "search - no 'index_object'";

    my $rcdata=$args->{'rcdata'} ||
        throw $self "suggest_alternatives - need rcdata";

    my $query=$args->{'search_string'} ||
        throw $self "suggest_alternatives - need search_string";

    my $spwords=$rcdata->{'spellchecker_words'};
    return '' unless $spwords;

    ##
    # This can be used to improve results when using a generic
    # dictionary on a small dataset, not a dictionary based on the
    # actual index content (which guarantees that we already get only
    # valid substitutes).
    #
    my %wcounts;
    my $max_alt_words=$self->config_param('spellchecker/max_alt_words') || 0;
    if($max_alt_words) {
        dprint "Using 'max_alt_words' slows down suggestion, consider building a custom dictionary";
        my $data_list=$index_object->get('Data');
        foreach my $word (keys %$spwords) {
            my $alist=$spwords->{$word};
            my @newlist;
            for(my $i=0; $i<$max_alt_words && $i<@$alist; ++$i) {
                my $altword=lc($alist->[$i]);
                ### dprint "Trying word '$word' -> '$altword'";

                my @aw=$self->analyze_text_split(0,$altword);
                my $found=0;
                foreach my $aw (@aw) {
                    my $sr=$data_list->search('keyword','eq',$aw);
                    next unless @$sr;
                    ++$found;
                    $wcounts{$aw}=scalar(@$sr);
                }

                if($found && $found==scalar(@aw)) {
                    push(@newlist,$altword);
                }
            }
            $spwords->{$word}=\@newlist;
        }
    }

    ##
    # Ordering the list of substitutions to try on the original query.
    # Fuzzy area, there could be multiple algorithms to do that.
    #
    my $algorithm=$self->config_param('spellchecker/algorithm') || 'sequential';
    my $max_alt_searches=$self->config_param('spellchecker/max_alt_searches') || 15;
    my $max_alt_results=$self->config_param('spellchecker/max_alt_results') || 2;
    my $max_result_distance=$self->config_param('spellchecker/max_result_distance') || 5;
    ### dprint ".algorithm=$algorithm max_alt_results=$max_alt_results max_alt_searches=$max_alt_searches";

    ##
    # In 'sequential' we scan through all words from most likely to
    # least likely, with all possible variations. If we have these variants:
    # A->(B,C)  K->(L,M)  X->(Y)
    # then the following will be tried
    # (A-B) (K-L) (X-Y) (A-B,K-L) (A-B,X-Y) (K-L,X-Y) (A-B,K-L,X-Y) (A-B,K-M)
    # (A-C,K-L) (A-C,X-Y) (K-M,X-Y) (A-C,K-M) (A-C,K-L,X-Y), etc..
    #
    # The idea is that we assign weight proportional to the distance
    # from the top of the list, make lists and then sort on the weight.
    #
    my @jobs;
    if($algorithm eq 'sequential') {

        if($self->config_param('spellchecker/try_word_removals')) {
            foreach my $word (keys %$spwords) {
                my $n=scalar(@{$spwords->{$word}});
                if($n>2) {
                    splice(@{$spwords->{$word}},2,0,'');
                }
                elsif($n) {
                    push(@{$spwords->{$word}},'');
                }
            }
        }

        my @list;
        sequential_helper($spwords,\@list);

        ### use Data::Dumper;
        ### dprint Dumper(\@list);

        foreach my $elt (@list) {
            my $distance=0;
            my $count=0;
            foreach my $pair (@{$elt->{'job'}}) {
                $distance+=$pair->[2];
                ++$count;
            }
            $elt->{'distance'}=$distance+$count-1;
        }

        @jobs=map {
            {
                pairs       => [ map { ($_->[0],$_->[1]) } @{$_->{'job'}} ],
                distance    => $_->{'distance'},
            }
        } sort {
            $a->{'distance'} <=> $b->{'distance'} ||
            scalar(@{$b->{'job'}}) <=> scalar(@{$a->{'job'}})
        } @list;

        ### use Data::Dumper;
        ### dprint Dumper(\@jobs);

        if(@jobs>$max_alt_searches) {
            splice(@jobs,$max_alt_searches);
        }
    }

    ##
    # In 'bycount' we keep completely dropping least likely words. Does
    # not work very well, probably should be removed altogether as unusable.
    #
    ### elsif($algorithm eq 'bycount') {
    ###     for(my $i=0; %words && $i<$max_alt_searches; ++$i) {
    ###         my @wlist=sort { $words{$b}->[0]->[1] <=> $words{$a}->[0]->[1] } keys %words;
    ###         my @pairs;
    ###         my $have_difference;
    ###         foreach my $word (@wlist) {
    ###             my $altword=$words{$word}->[0]->[0];
    ###             $have_difference=1 if $altword ne $word;
    ###             push(@pairs,$word => $altword);
    ###         }
    ###         push(@jobs,{
    ###             pairs       => @pairs,
    ###             distance    => 1,
    ###         }) if $have_difference;
    ###         my $word=$wlist[$#wlist];
    ###         if(@{$words{$word}}>1) {
    ###             shift(@{$words{$word}});
    ###         }
    ###         else {
    ###             delete $words{$word};
    ###         }
    ###     }
    ### }
    else {
        throw $self "suggest_alternative - '$algorithm' algorithm is not supported";
    }

    # Now building other alternative strings and returning them in order.
    #
    my $results_count=$rcdata->{'results_count'} || 0;
    my @alts;
    for(my $i=0; $i<@jobs; ++$i) {
        my $distance=$jobs[$i]->{'distance'} || 1;
        $distance<=$max_result_distance || next;

        my $newq=$query;
        my $pairs=$jobs[$i]->{'pairs'};
        my @finalpairs;
        for(my $j=0; $j<@$pairs; $j+=2) {
            my $word=$pairs->[$j];
            my $altword=$pairs->[$j+1];
            if($word ne $altword) {
                $newq=~s/\b$word\b/$altword/ig;
                $newq=~s/^\s*(.*?)\s*$/$1/s;
                $newq=~s/\s{2,}/ /s;
                push(@finalpairs,[ $word, $altword ]);
            }
        }
        next if $newq =~ /^\s+$/s;

        dprint "Trying query '$newq' instead of '$query'";
        my $sr=$self->search(
            index_object    => $index_object,
            search_string   => $newq,
            ordering        => $args->{'ordering'},
        );
        my $newcount=@$sr;
        if($newcount && $newcount>=$results_count) {
            dprint "Got a match on '$newq' ($newcount)";
            push(@alts,{
                query       => $newq,
                pairs       => \@finalpairs,
                results     => $args->{'need_results'} ? $sr : undef,
                count       => $newcount,
                distance    => $distance,
            });

            last if scalar(@alts)>=$max_alt_results;
        }
    }

    # Storing all variants and returning the first one.
    #
    $rcdata->{'spellchecker_alternatives'}=\@alts;
    return @alts ? $alts[0]->{'query'} : undef;
}

###############################################################################

sub update ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{'index_object'} ||
        throw $self "update - no 'index_object'";

    ##
    # Checking if we need to compress the data
    #
    my $compression=$index_object->get('compression');
    if($compression) {
        eval 'use Compress::LZO';
        if($@) {
            throw $self "update - need Compress::LZO for compression ($compression)";
        }
        if($compression<1 || $compression>9) {
            throw $self "update - compression level must be between 1 and 9";
        }
    }

    ##
    # For compatibility reasons we need to call it in array context.
    #
    my @carr=$self->get_collection($args);
    my $cinfo;
    if(@carr==2) {
        $cinfo={
            collection  => $carr[0],
            ids         => $carr[1],
        };
    }
    else {
        $cinfo=$carr[0];
    }

    ##
    # Maximum number of matches for a word for it to be completely
    # ignored.
    #
    my $ignore_limit=$self->ignore_limit;

    ##
    # Maximum number of keywords updated before a forced transaction
    # commit. This helps to deal with otherwise huge transaction that
    # have to be cached before being moved into binlogs for slave
    # updates in MySQL -- it is my understanding that it will require at
    # least tripple write, and at least one atomic huge write. Better
    # not do that.
    #
    my $commit_interval=$self->commit_interval;

    ##
    # If that's a partial update and we don't have any IDs to update
    # we return immediately. Otherwise proceed even with empty set to
    # remove records from the index.
    #
    my $is_partial=$cinfo->{'partial'};
    my $coll_ids=$cinfo->{'ids'};
    my $coll_ids_total=scalar(@$coll_ids);
    if($is_partial && !$coll_ids_total) {
        return 0;
    }
    my $coll=$cinfo->{'collection'};

    ##
    # For partial indexes we pre-load ignored words. Otherwise, as the
    # data entry gets removed for ignored words, they will start from
    # zero and become non-ignored again.
    #
    # It is possible, that ignore_limit is different now, so we only
    # take in those that really exceed it.
    #
    my $ignore_list=$index_object->get('Ignore');
    my %kw_data;
    if($is_partial) {
        dprint "Loading ignored keywords for partial update";
        foreach my $kwmd5 ($ignore_list->keys) {
            my ($kw,$count)=$ignore_list->get($kwmd5)->get('keyword','count');
            if($count>$ignore_limit) {
                $kw_data{ignore}->{$kw}=1;
            }
        }
    }

    ##
    # Getting keyword data
    #
    dprint "Analyzing data..";
    my $count=0;
    foreach my $coll_id (@$coll_ids) {
        dprint "..$count/$coll_ids_total" if (++$count%1000)==0;
        my $coll_obj=$coll->get($coll_id);
        $self->analyze_object(
            collection      => $coll,
            object          => $coll_obj,
            object_id       => $coll_id,
            kw_data         => \%kw_data,
        );

        ##
        # Checking if it's time to ignore some keywords
        #
        my $count_uid=$kw_data{count_uid}->{$coll_id};
        foreach my $kw (keys %$count_uid) {
            if(++$kw_data{'counts'}->{$kw} > $ignore_limit) {
                $kw_data{'ignore'}->{$kw}=1;
            }
        }
        delete $kw_data{'count_uid'}->{$coll_id};
    }

    ##
    # Sorting and storing
    #
    dprint "Sorting and storing..";
    my $now=time;

    $index_object->glue->transact_begin;
    my $transact_count=0;

    my $data_list=$index_object->get('Data');
    my $max_kw_length=$data_list->get_new->describe('keyword')->{'maxlength'};
    my $ni=$ignore_list->get_new;
    $ni->put(create_time => $now);

    my %o_prepare;
    my %o_finish;

    ##
    # Data length limits
    #
    my $maxlen_id=$data_list->get_new->describe('id_1')->{'maxlength'};
    my $maxlen_idpos=$data_list->get_new->describe('idpos_1')->{'maxlength'};

    ##
    # As the list can potentially be huge, we go one ordering at a time,
    # thus probably re-doing the same record -- which is fine for large
    # datasets we're dealing with.
    #
    my @keywords=keys %{$kw_data{keywords}};
    my $kw_total=scalar(@keywords);
    my $o_hash=$self->get_orderings;
    my $o_first=1;
    foreach my $o_name (keys %$o_hash) {
        my $o_data=$o_hash->{$o_name};
        my $o_seq=$o_data->{seq} ||
            throw $self "update - no ordering sequence number for '$o_name'";
        dprint ".ordering '$o_name' ($o_seq)";

        ##
        # Indexer implementation can provide optimized routine to get
        # pre-sorted list of all IDs in the collection. Using it if it's
        # available. Otherwise going through items manually using comparison
        # routine.
        #
        my $sorted_ids;
        if($o_data->{'sortall'}) {
            $sorted_ids=&{$o_data->{'sortall'}}($cinfo);
        }
        else {
            if($is_partial) {
                throw $self "update - manual sorting is not implemented for partial updates";
            }
            else {
                dprint "Manual sorting is slow, consider providing 'sortall' routine";
                my $sortsub=$o_data->{sortsub};
                if($o_data->{'sortprepare'}) {
                    &{$o_data->{'sortprepare'}}($self,$index_object,\%kw_data);
                }
                $sorted_ids=[ sort { &$sortsub(\%kw_data,$a,$b) } @$coll_ids ];
                if($o_data->{'sortfinish'}) {
                    &{$o_data->{'sortfinish'}}($self,$index_object,\%kw_data);
                }
            }
        }
        my $sorted_ids_total=scalar(@$sorted_ids);

        ##
        # Preparing template_sort to sort on these IDs quickly.
        #
        XAO::IndexerSupport::template_sort_prepare($sorted_ids);

        $count=0;
        my $tstamp_start=time;
        foreach my $kw (keys %{$kw_data{'keywords'}}) {

            ##
            # If the keyword is longer than we can safely store we
            # ignore it and issue a warning. Should not happen often --
            # if it does the field length should be extended.
            #
            if(length(Encode::encode('utf8',$kw)) > $max_kw_length) {
                eprint "Keyword '$kw' is longer than $max_kw_length, ignored";
                next;
            }

            ##
            # Estimate of when we're going to finish.
            #
            if((++$count%1000)==0) {
                my $tstamp=time;
                my $tstamp_end=$tstamp_start+int(($tstamp-$tstamp_start)/$count * $kw_total);
                dprint "..$count/$kw_total (".localtime($tstamp)." - ".localtime($tstamp_end).")";
            }

            ##
            # If it's time to commit - committing and starting a new
            # transaction. Yes, if we fail we can end up with a
            # partially update data, but nothing terribly bad -- it'll
            # join fine on next update anyway and will be usable in
            # between.
            #
            if($commit_interval && ++$transact_count>$commit_interval) {
                dprint "...forced transaction commit";
                $index_object->glue->transact_commit;
                $index_object->glue->transact_begin;
                $transact_count=0;
            }

            ##
            # Using md5 based IDs
            #
            my $kwmd5=md5_base64(Encode::encode_utf8($kw));
            $kwmd5=~s/\W/_/g;
            my $data_obj;
            if($data_list->exists($kwmd5)) {
                $data_obj=$data_list->get($kwmd5);
            }
            else {
                $data_obj=$data_list->get_new;
                $data_obj->put(keyword => $kw);
            }

            ##
            # To be ignored? When we go through first ordering it might
            # only be known after we merge data below, otherwise we know
            # instantly.
            #
            if($kw_data{'ignore'}->{$kw}) {
                $ni->put(
                    keyword => $kw,
                    count   => $kw_data{'counts'}->{$kw},
                );
                $ignore_list->put($kwmd5 => $ni);
                $data_list->delete($kwmd5) if $data_obj->container_key;
                next;
            }

            ##
            # For partial - joining with the existing data, otherwise --
            # replacing.
            #
            my $kwd=$kw_data{'keywords'}->{$kw};
            if($is_partial && $data_obj->container_key) {
                my $posdata=$data_obj->get("idpos_$o_seq");
                if(length($posdata)) {
                    my $kw_count=$kw_data{counts}->{$kw};
                    my $kwd_new=merge_refs($kwd);

                    if(unpack('w',$posdata) == 0) {
                        my $zz=substr($posdata,1);
                        $posdata=Compress::LZO::decompress($zz);
                    }

                    my @dstr=unpack('w*',$posdata);
                    my $i=0;
                    while($i<@dstr) {
                        my $id=$dstr[$i++];
                        last unless $id;
                        my @wd;
                        while($i<@dstr) {
                            my $fnum=$dstr[$i++];
                            last unless $fnum;
                            my @poslist;
                            while($i<@dstr) {
                                my $pos=$dstr[$i++];
                                last unless $pos;
                                push(@poslist,$pos);
                            }
                            $wd[$fnum-1]=\@poslist;
                        }
                        if(!$kwd_new->{$id}) {
                            $kwd_new->{$id}=\@wd;
                            ++$kw_count;
                        }
                    }

                    if($o_first) {
                        $kw_data{'counts'}->{$kw}=$kw_count;
                        if($kw_count > $ignore_limit) {
                            $kw_data{ignore}->{$kw}=$kw_count;
                            $ni->put(
                                keyword => $kw,
                                count   => $kw_count,
                            );
                            $ignore_list->put($kwmd5 => $ni);
                            $data_list->delete($kwmd5);
                            next;
                        }
                    }

                    $kwd=$kwd_new;
                }
            }

            ##
            # Preparing sorted list of IDs
            #
            my $kwids=XAO::IndexerSupport::template_sort([ keys %$kwd ]);

            ##
            # Posdata format
            #
            # |UID|FN|POS|POS|POS|0|FN|POS|POS|0|0|UID|FN|POS|
            #
            my $iddata='';
            my $posdata='';
            foreach my $id (@$kwids) {
                $iddata.=pack('w',$id);

                my $field_num=0;
                $posdata.=pack('ww',0,0) if length($posdata);
                $posdata.=
                    pack('w',$id) .
                    join(pack('w',0),
                        map {
                            ++$field_num;
                            defined($_) ? (pack('w',$field_num) . pack('w*',@$_))
                                        : ()
                        } @{$kwd->{$id}}
                    );
            }

            ##
            # Compressing the data if required
            #
            if($compression) {
                #dprint "COMPR.bef: id=".length($iddata)." idpos=".length($posdata);
                my $z=Compress::LZO::compress($iddata,$compression);
                $iddata=(pack('w',0) . $z) if defined $z && length($z)<length($iddata);
                $z=Compress::LZO::compress($posdata,$compression);
                $posdata=(pack('w',0) . $z) if defined $z && length($z)<length($posdata);
                #dprint "COMPR.aft: id=".length($iddata)." idpos=".length($posdata);
            }

            ##
            # Checking length before storing
            #
            length($iddata) <= $maxlen_id ||
                throw $self "update - id data too long (".length($iddata).">$maxlen_id), kw='$kw', count=".$kw_data{'counts'}->{$kw};
            length($posdata) <= $maxlen_idpos ||
                throw $self "update - pos data too long (".length($posdata).">$maxlen_idpos), kw='$kw', count=".$kw_data{'counts'}->{$kw};

            ##
            # Storing
            #
            my %data_hash=(
                "id_$o_seq"     => $iddata,
                "idpos_$o_seq"  => $posdata,
            );
            if($o_first) {
                $data_hash{'create_time'}=$now;
                $data_hash{'count'}=$kw_data{'counts'}->{$kw};
            }
            $data_obj->put(\%data_hash);
            $data_list->put($kwmd5 => $data_obj) unless $data_obj->container_key;
        }
    }
    continue {
        $o_first=0;
    }

    ##
    # Freeing template_sort internal structures
    #
    XAO::IndexerSupport::template_sort_free();

    ##
    # Deleting outdated records
    #
    dprint "Deleting older records..";
    if($is_partial) {
        dprint ".no deletion implementation yet for partials!";
    }
    else {
        my $sr=$data_list->search('create_time','ne',$now);
        foreach my $id (@$sr) {
            $data_list->delete($id);
        }
        $sr=$ignore_list->search('create_time','ne',$now);
        foreach my $id (@$sr) {
            $ignore_list->delete($id);
        }
    }

    ##
    # If indexer can we ask it to close the data set we were working
    # on. Essential for partial updates, so that we know what to update
    # next time.
    #
    dprint "Finishing collection";
    $self->finish_collection($args,{
        collection_info => $cinfo,
    });

    ##
    # Committing changes into the database
    #
    dprint "Done";
    $index_object->glue->transact_commit;

    return wantarray ? ($coll_ids_total,$is_partial) : $coll_ids_total;
}

###############################################################################

sub analyze_object ($%) {
    my $self=shift;
    throw $self "analyze_object - pure virtual method called";
}

###############################################################################

sub get_collection ($%) {
    my $self=shift;
    throw $self "get_collection - pure virtual method called";
}

###############################################################################

sub finish_collection ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $cinfo=$args->{'collection_info'} ||
        throw $self "finish_collection - no 'collection_info' given";

    ##
    # If it's partial and we're called -- we throw an exception to
    # indicate that this method must be overriden.
    #
    if($cinfo->{'partial'}) {
        throw $self "finish_collection - implementation required for partial collections";
    }
}

###############################################################################

sub build_dictionary ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $index_object=$args->{'index_object'} ||
        throw $self "build_dictionary - no 'index_object'";

    my $spellchecker=$self->get_spellchecker;

    $spellchecker->switch_index($self->{'index_id'});

    my $wlist=$spellchecker->dictionary_create;
    return unless $wlist;

    my $dict_req_count=$self->config_param('spellchecker/dictionary_req_count') || 3;
    my $dict_req_length=$self->config_param('spellchecker/dictionary_req_length') || 1;

    my $data_list=$index_object->get('Data');
    my @data_keys=$data_list->keys;
    my $datacount=0;
    my $datatotal=scalar(@data_keys);
    my $wcount=0;
    dprint ".words from search index ($datatotal)";
    foreach my $data_id (@data_keys) {
        dprint "..$datacount/$datatotal, word count $wcount" if (++$datacount%5000)==0;

        my ($keyword,$count)=$data_list->get($data_id)->get('keyword','count');

        next unless $count>=$dict_req_count &&
                    length($keyword)>=$dict_req_length;

        $wcount=$spellchecker->dictionary_add($wlist,$keyword,$count);
    }

    $data_list=$index_object->get('Ignore');
    @data_keys=$data_list->keys;
    $datacount=0;
    $datatotal=scalar(@data_keys);
    dprint ".words from ignore list ($datatotal)";
    foreach my $data_id (@data_keys) {
        dprint "..$datacount/$datatotal, word count $wcount" if (++$datacount%5000)==0;

        my ($keyword,$count)=$data_list->get($data_id)->get('keyword','count');

        next unless $count>=$dict_req_count &&
                    length($keyword)>=$dict_req_length;

        $wcount=$spellchecker->dictionary_add($wlist,$keyword,$count);
    }

    $spellchecker->dictionary_close($wlist);
}

###############################################################################

sub sequential_helper ($$;$$$) {
    my ($words,$list,$base,$level,$ixhash)=@_;

    $base||=[ ];
    $level||=0;
    $ixhash||={ };

    for(my $i=0; $i<5; ++$i) {
        my $newlevel=$level+$i;
        foreach my $word (keys %$words) {
            next if grep { $_->[0] eq $word } @$base;
            my $altlist=$words->{$word};
            next if $newlevel>=@$altlist;
            my $altword=$altlist->[$newlevel];
            next if $altword eq $word;

            my @newbase=(@$base, [ $word, $altword, $newlevel ]);

            my $ix=join('|',sort map { $_->[0].'-'.$_->[1] } @newbase);
            next if exists $ixhash->{$ix};
            $ixhash->{$ix}=1;

            push(@$list,{
                job         => \@newbase,
            });

            scalar(@$list)<100 &&
                sequential_helper($words,$list,\@newbase,$newlevel,$ixhash);
        }
    }
}

###############################################################################

sub get_spellchecker ($) {
    my $self=shift;

    return XAO::Objects->new(
        objname     => $self->config_param('spellchecker/objname') || 'SpellChecker::Aspell',
    );
}

###############################################################################
1;
