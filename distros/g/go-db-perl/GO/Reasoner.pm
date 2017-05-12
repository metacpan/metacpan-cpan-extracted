package GO::Reasoner;

use strict;
use Carp;
use base qw(GO::Model::Root);

my $REL_ID_COL = "id";
my $REL_TBL = "term";
my $ACC_COL = "acc";
my $CLASS_TABLE="term";
my $LINK_TABLE="graph_path";
my $ASSERTED_LINK_TABLE="term2term";
my $LINK_ID_COL="id";
my $SUBJECT_COL="term2_id";
my $TARGET_COL="term1_id";
my $REL_COL="relationship_type_id";
my %time_in_view_h = ();

our $sth_link;
our $sth_store;
our $is_a;

sub _valid_params {
    return qw(dbh skip ruleconf verbose);
}

sub run {
    my $self = shift;
    my $dbh = $self->dbh;
    my %skip = %{$self->skip || {}};
    # make sure relations are correctly indicated
    $dbh->do("UPDATE term SET is_relation=1 WHERE id IN (SELECT DISTINCT relationship_type_id FROM term2term)");

    my @is_a_nodes = 
        $dbh->selectrow_array("SELECT $REL_ID_COL FROM $REL_TBL WHERE $ACC_COL='OBO_REL:is_a'");
    if (@is_a_nodes != 1) {
        @is_a_nodes = 
            $dbh->selectrow_array("SELECT $REL_ID_COL FROM $REL_TBL WHERE $ACC_COL='is_a'");
    }
    if (@is_a_nodes != 1) {
        die "@is_a_nodes";
    }
    $is_a = shift @is_a_nodes;
    $self->logmsg("is_a node id: $is_a");

    my $isa_term_ids = 
        $dbh->selectcol_arrayref("SELECT relationship_type_id FROM relation_properties WHERE is_transitive=1");
    my $isa_id = shift @$isa_term_ids;

    if (!@{$dbh->selectcol_arrayref("SELECT relationship_type_id FROM relation_properties WHERE relationship_type_id=$isa_id")}) {
        $dbh->do("UPDATE relation_properties SET is_transitive=1, is_reflexive=1 WHERE relationship_type_id=$isa_id");
    }

    my $transitive_relation_node_ids = 
        $dbh->selectcol_arrayref("SELECT relationship_type_id FROM relation_properties WHERE is_transitive=1");

    # hard-wire is_a just to be safe
    my $reflexive_relation_node_ids = 
        $dbh->selectcol_arrayref("SELECT relationship_type_id FROM relation_properties WHERE is_reflexive=1 UNION SELECT id FROM term WHERE acc='is_a'");

    my $inheritable_relation_node_ids = 
        $dbh->selectcol_arrayref("SELECT relationship_type_id FROM relation_properties WHERE is_metadata_tag != 1 or is_metadata_tag IS NULL");

    $self->logmsg("inheritable relations: @$inheritable_relation_node_ids");
    my $superrelation_h = {};
    foreach my $sid (@$inheritable_relation_node_ids) {
        my $parent_rids =
            $dbh->selectcol_arrayref("SELECT term1_id FROM $ASSERTED_LINK_TABLE WHERE relationship_type_id=$is_a AND term2_id = $sid ");
        $superrelation_h->{$sid} = $parent_rids;
        #print STDERR "SUPERREL: $sid @$parent_rids\n";
    }

    $self->logmsg("finding transitive closure of relation hierarchy");
    my $t_superrelation_h = {};
    foreach my $sid (keys %$superrelation_h) {
        my @pids = @{$superrelation_h->{$sid}};
        my %done = ();
        while (my $pid = shift @pids) {
            next if $done{$pid};
            push(@{$t_superrelation_h->{$sid}}, $pid);
            push(@pids, @{$superrelation_h->{$pid}});
            $done{$pid} = 1;
            $self->logmsg("  super: $sid $pid");
        }
    }

    my $t_subrelation_h = {};
    foreach my $sid (keys %$superrelation_h) {
        foreach my $pid (@{$superrelation_h->{$sid}}) {
            push(@{$t_subrelation_h->{$pid}}, $sid);
        }
    }

    $self->logmsg("retrieving relation_properties");
    my $relation_property_h = 
        $dbh->selectall_hashref("SELECT * FROM relation_properties","relationship_type_id");

    my $relation_compositions = 
        $dbh->selectall_arrayref("SELECT relation1_id,relation2_id,inferred_relation_id FROM relation_composition");

    my $rc_h = {};
    foreach my $rc (@$relation_compositions) {
        my $key = join('-',@$rc);
        $rc_h->{$key} = 1;
        #print STDERR "In db <$key> $rc->[0] $rc->[1] $rc->[2]\n";
    }

    my @new_rcs = ();

# transitivity over and under is_a
    foreach my $id (@$inheritable_relation_node_ids) {
        push(@new_rcs, [$id, $is_a, $id]);
        push(@new_rcs, [$is_a, $id, $id]);
    }

# transitivity: is_a should be pre-declared transitive
    foreach my $id (@$transitive_relation_node_ids) {
        push(@new_rcs, [$id, $id, $id]);
    }

    foreach my $rc (@new_rcs, @$relation_compositions) {
        $self->logmsg("relation_composition: @$rc");
        foreach my $r0 ($rc->[0], @{$t_subrelation_h->{$rc->[0]}}) {
            #print STDERR "  subrel: $r0 < $rc->[0]\n";
            
            foreach my $r1 ($rc->[1], @{$t_subrelation_h->{$rc->[1]}}) {
                $self->logmsg("    subrel: $r1 < $rc->[1]");
                my $new_rc = [$r0, $r1, $rc->[2]];
                unless ($rc_h->{"@$new_rc"}) {
                    push(@new_rcs, $new_rc);
                }
            }
        }
    }

# complete relation composition table in db. TODO: make this configurable?
    foreach my $rc (@new_rcs) {
        my $key = join('-',@$rc);
        if ($rc_h->{$key}) {
            next;
        }
        $dbh->do("INSERT INTO relation_composition (relation1_id, relation2_id, inferred_relation_id) VALUES ($rc->[0],$rc->[1],$rc->[2])");
        $rc_h->{$key} = 1;
    }
    push(@$relation_compositions, @new_rcs);

    $self->logmsg("seeding graph_path");

# seed graph_path table
# todo: no dupes
    $dbh->do("INSERT INTO $LINK_TABLE (distance,relation_distance,term1_id,term2_id,relationship_type_id) SELECT 1,1,term1_id,term2_id,relationship_type_id FROM $ASSERTED_LINK_TABLE AS alt WHERE NOT EXISTS (SELECT * FROM $LINK_TABLE AS lt WHERE lt.term1_id=alt.term1_id AND term2_id=alt.term2_id AND lt.relationship_type_id=alt.relationship_type_id)")
        unless $skip{seed};

    my $lj=qq[
  LEFT JOIN $LINK_TABLE AS existing_link
        ON (x.$SUBJECT_COL=existing_link.$SUBJECT_COL AND
            x.$REL_COL=existing_link.$REL_COL AND
            y.$TARGET_COL=existing_link.$TARGET_COL)
];
    my $lj_cond = "AND existing_link.$LINK_ID_COL IS NULL";

# TODO: transitive_over and relation compositions
    my @views = ();

    unless ($skip{chain}) {

        my %done = ();
        foreach my $rc (@$relation_compositions) {
            my $r1id = $rc->[0];
            my $r2id = $rc->[1];
            my $rid = $rc->[2];
            my $relation_distance = "1";
            if ($r1id == $r2id && $r2id == $rid) {
                $relation_distance = "x.relation_distance+y.relation_distance";
            }
            elsif ($r1id == $rid) {
                $relation_distance = "x.relation_distance";
            }
            elsif ($r2id == $rid) {
                $relation_distance = "y.relation_distance";
            }
            else {
                $relation_distance = "x.relation_distance+y.relation_distance";
            }
            my $sql =
                qq[
 SELECT DISTINCT
  x.$SUBJECT_COL             AS node_id,
  $rid                  AS predicate_id,
  y.$TARGET_COL           AS object_id,
  x.distance+y.distance   AS distance,
  $relation_distance   AS relation_distance
 FROM $LINK_TABLE              AS x
  INNER JOIN $LINK_TABLE       AS y ON (x.$TARGET_COL=y.$SUBJECT_COL)
  $lj
 WHERE x.$REL_COL = $r1id
  AND y.$REL_COL = $r2id
  $lj_cond 
];
            my $view_id = "chain: @$rc";
            if ($done{$view_id}) {
                next;
            }
            $done{$view_id} = 1;
            push(@views,
                 {id=>$view_id,
                  type=>'composition',
                  rule=>"@$rc",
                  sql=>$sql});
        }
    }

    for my $rid (@$reflexive_relation_node_ids) {
        $self->logmsg("reflexive_relation: $rid");
        push(@views,
             {id=>"reflexive: $rid",
              type=>'reflexive',
              rule=>"reflexivity",
              sql=>qq[
                  SELECT DISTINCT
                  $CLASS_TABLE.id          AS node_id,
                  $rid                       AS predicate_id,
                  $CLASS_TABLE.id          AS object_id,
                  0   AS distance,
                  0   AS relation_distance
                  FROM $CLASS_TABLE
                  LEFT JOIN  $LINK_TABLE AS existing_link
                  ON ($CLASS_TABLE.id=existing_link.$SUBJECT_COL AND
                      $rid=existing_link.$REL_COL AND
                      $CLASS_TABLE.id=existing_link.$TARGET_COL)
                  WHERE $CLASS_TABLE.is_relation=0
                  $lj_cond
                  ],
             });
    }

    for my $sid (keys %$t_superrelation_h) {
        for my $pid (@{$t_superrelation_h->{$sid}}) {
            #print STDERR "  SUBREL: $sid < $pid\n";

            push(@views,
                 {id=>"subrelation $sid $pid",
                  type=>'subrelation',
                  rule=>"A R B, R is_a R2 => A R2 B: reflexivity",
                  sql=>qq[
                      SELECT DISTINCT
                      x.$SUBJECT_COL          AS node_id,
                      $pid               AS predicate_id,
                      x.$TARGET_COL        AS object_id,
                      x.distance         AS distance,
                      x.relation_distance         AS relation_distance
                      FROM  $LINK_TABLE AS x
                      LEFT JOIN  $LINK_TABLE AS existing_link
                      ON (x.$SUBJECT_COL=existing_link.$SUBJECT_COL AND
                          $pid=existing_link.$REL_COL AND
                          x.$TARGET_COL=existing_link.$TARGET_COL)
                      WHERE x.$REL_COL = $sid
                      $lj_cond
                      ],
                 });
            
        }
        
    }

    my %ruleconf = %{$self->{ruleconf} || {}};
    if (%ruleconf) {
        $self->logmsg("applying only: ".join(" ",keys %ruleconf));
        @views = grep {$ruleconf{$_->{type}}} @views;
    }
    $self->logmsg("total views: ".scalar(@views));


    $sth_link = $dbh->prepare_cached("SELECT $LINK_ID_COL FROM $LINK_TABLE WHERE $SUBJECT_COL=? AND $REL_COL=? AND $TARGET_COL=?");
#my $sth_store = $dbh->prepare_cached("INSERT INTO $LINK_TABLE ($SUBJECT_COL,$REL_COL,$TARGET_COL,is_inferred) VALUES (?,?,?,'t')");
    $sth_store = $dbh->prepare_cached("INSERT INTO $LINK_TABLE ($SUBJECT_COL,$REL_COL,$TARGET_COL,distance,relation_distance) VALUES (?,?,?,?,?)");

    my $i_by_node_id = $self->get_intersections();
    foreach my $node_id (keys %$i_by_node_id) {
        my $intersection_h = $i_by_node_id->{$node_id};
        my $sql = $self->intersection_to_query($node_id,$intersection_h);
        #print STDERR "$sql\n";
        # we do this at the start - unless new intersections can be added
        unshift(@views,
                {id=>"intersection_for_$node_id",
                 type=>'intersection',
                 sql=>$sql});
    }

    my $done = 0;
    my $sweep = 0;
    unless ($skip{sweep}) {
        while (!$done) {
            $self->logmsg( "Sweep: $sweep" );
            my $links_added_this_sweep = 0;
            foreach my $view (@views) {
                my $links_added = $self->cache_view($view);
                $links_added_this_sweep += $links_added;
            }
            $self->logmsg( "Sweep: $sweep total_added: $links_added_this_sweep" );
            $done = 1 unless $links_added_this_sweep;
        }
    }
    unless ($skip{equivalence}) {
        $self->assert_sameas();
    }


    foreach my $view (@views) {
        my $view_id = $view->{id};
        print STDERR "  View: $view_id. Total time: $time_in_view_h{$view_id}\n";
    }

}

# TODO: insert and select in same step; or temp table
sub cache_view {
    my $self = shift;
    my $dbh = $self->dbh;
    my $view = shift;
    my $view_links_added = 0;
    my $offset = 0;
    my $init_time = time;

    my $view_id = $view->{id};
    $self->logmsg( "  View: $view_id" );
    my $done_with_view;
    while (!$done_with_view) {

        my $sql = $view->{sql};
        #$sql.= "ORDER BY x.$LINK_ID_COL,y.$LINK_ID_COL";
        #$sql.= " LIMIT $limit OFFSET $offset";
        my $sth = 
            $dbh->prepare_cached($sql);

        #$self->logmsg( "    Executing [$offset,$limit]" );
        $self->logmsg( "    Executing $sql" );
        
        $sth->execute;
        $self->logmsg( "    EXECUTED" );
        my $links_added = 0;
        my $links_in_db = 0;
        my $n_rows = 0;
        while (my $link = $sth->fetchrow_hashref) {
            $n_rows++;
            my @triple =
                ($link->{node_id},
                 $link->{predicate_id},
                 $link->{object_id});
            if ($triple[0] == $triple[2] && $view_id ne 'isa*' && $view->{type} ne 'reflexive') {
                # TODO: proper reflexivity rules. hardcode OK for is_a for now
                # also: will report cycles for intersections to self, which is normal?
                #
                # this gives us lots of spurious messages for GALEN, since the obo translation
                # uses anonymous IDs and class expression syntax
                $self->logmsg("    Cycle detected for node: $triple[0] pred: $triple[1]");
                next;
            }
            my $rv = $sth_link->execute(@triple);
            if ($n_rows % 1000 == 0) {
                $self->logmsg("    Checked $n_rows links. Current: @triple");
            }
            if ($sth_link->fetchrow_array) {
                $links_in_db++;
            }
            else {
                #print STDERR "NEW @triple\n";
                $sth_store->execute(@triple,                
                                    $link->{distance},
                                    $link->{relation_distance},
                    );
                $links_added++;
            }
        }
        #$offset += $limit;
        $done_with_view=1 unless $links_added;
        $view_links_added += $links_added;
        $self->logmsg( "    Links added: $links_added [in_view: $view_links_added] already_there: $links_in_db" );
    }
    my $end_time = time;
    my $time_in_view = $end_time-$init_time;
    $time_in_view_h{$view_id} += $time_in_view;
    return $view_links_added;
}

sub assert_sameas {
    my $self = shift;
    my $dbh = $self->dbh;
    $self->logmsg("fetching reciprocal subclass links");
    my $eqs =
        $dbh->selectall_arrayref("SELECT DISTINCT x.$SUBJECT_COL, x.$TARGET_COL FROM $LINK_TABLE AS x INNER JOIN $LINK_TABLE AS y ON (y.$TARGET_COL=x.$SUBJECT_COL AND x.$TARGET_COL=y.$SUBJECT_COL) WHERE x.$REL_COL=$is_a AND y.$REL_COL=$is_a AND x.$SUBJECT_COL != x.$TARGET_COL", {Slice=>{}});
    $self->logmsg("got reciprocal subclass links: ".scalar(@$eqs));
    foreach (@$eqs) {
        $dbh->do("INSERT INTO sameas ($SUBJECT_COL,$TARGET_COL,is_inferred) VALUES ($_->{node_id},$_->{object_id},'t')");
        $dbh->do("INSERT INTO sameas ($TARGET_COL,$SUBJECT_COL,is_inferred) VALUES ($_->{node_id},$_->{object_id},'t')");
    }
    $self->logmsg("done sameas");
}

# TODO: port this
sub get_intersections {
    my $self = shift;
    my $dbh = $self->dbh;
    my %skip = %{$self->skip || {}};
    my $i_by_node_id = {};
    unless ($skip{intersections}) {
        #my $ilinks = $dbh->selectall_arrayref("SELECT DISTINCT $SUBJECT_COL,$REL_COL,$TARGET_COL,combinator FROM $LINK_TABLE WHERE combinator='I'",{Slice=>{}});
        my $ilinks = $dbh->selectall_arrayref("SELECT DISTINCT $SUBJECT_COL,$REL_COL,$TARGET_COL FROM $ASSERTED_LINK_TABLE WHERE complete=1",{Slice=>{}});
        foreach (@$ilinks) {
            push(@{$i_by_node_id->{$_->{node_id}}}, $_);
        }
    }
    return $i_by_node_id;
}

sub intersection_to_query {
    my $self = shift;
    my $dbh = $self->dbh;
    my $defined_node_id = shift;
    my $i_h = shift;
    my @conds = @$i_h;
    my $linknum=0;
    my @links = ();

    # TODO: remember, is_a is reflexive..
    # TODO: sub-relations
    my $where =
        join(" AND ",
             map {
                 $linknum++;
                 my $link = "link_".$linknum;
                 push(@links,"link AS $link");
                 # TODO: omit negation links
                 my $q = "$link.$SUBJECT_COL=subsumed_node.$SUBJECT_COL AND $link.$REL_COL = $_->{predicate_id} AND $link.$TARGET_COL = $_->{object_id} AND $link.combinator!='U'";
                 $q;
             } @conds);
    my $from = join(', ',@links);
    
    my $sql =
        qq[
 SELECT DISTINCT
  subsumed_node.$SUBJECT_COL  AS node_id,
  $is_a                  AS predicate_id,
  $defined_node_id       AS object_id
 FROM node AS subsumed_node, $from
 WHERE
   $where
  ];
    return $sql;
}

sub delete_inferred_links {
    my $self = shift;
    my $dbh = $self->dbh;
    my $link_ids = $dbh->selectcol_arrayref("SELECT $LINK_ID_COL FROM $LINK_TABLE WHERE is_inferred='t'");
    $dbh->{AutoCommit}=0;
    my $n=0;
    foreach my $link_id (@$link_ids) {
        print STDERR "Deleting $link_id\n";
        $dbh->do("DELETE FROM $LINK_TABLE WHERE $LINK_ID_COL=$link_id");
        $n++;
        if ($n % 1000 == 0) {
            print STDERR "COMMITTING\n";
            $dbh->commit;
        }
    }
    $dbh->commit;
    print STDERR "Deleted all inferred links\n";
}

sub get_or_put_relation {
    my $self = shift;
    my $dbh = $self->dbh;
    my $rel = shift;
    my @nids = 
        $dbh->selectrow_array("SELECT $SUBJECT_COL FROM node WHERE $ACC_COL='$rel'");
    if (@nids == 1) {
        return $nids[0];
    }
    elsif (@nids > 1) {
        die "@nids";
    }
    else {
        $dbh->do("INSERT INTO node ($ACC_COL,metatype) VALUES ('$rel','R')");
        return $self->get_or_put_relation($rel);
    }
    
}

sub logmsg {
    my $self = shift;
    return unless $self->verbose;
    my $msg = shift;
    my $t = time;
    print STDERR "LOG $t : $msg\n";
}


1;
