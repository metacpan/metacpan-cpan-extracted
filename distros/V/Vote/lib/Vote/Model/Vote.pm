package Vote::Model::Vote;

use strict;
use warnings;
use base 'Catalyst::Model';
use Vote;
use DBI;
use Mail::Mailer;

=head1 NAME

Vote::Model::Vote - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=cut

sub new {
    my ($class) = @_;
    
    bless {
        db => _newdb(),
    }, $class;
}

sub _newdb {
    my $db = DBI->connect(
        'dbi:Pg:' . Vote->config->{db},
        undef, undef,
        {
            RaiseError => 0,
            AutoCommit => 0,
            PrintWarn => 0,
            PrintError => 1,
        }
    ) or return;
    $db->do(q{set DATESTYLE to 'DMY'});
    return $db;
}

sub db {
    return $_[0]->{db} && $_[0]->{db}->ping
        ? $_[0]->{db}
        : $_[0]->_newdb();
}

sub mail_header {
    return(
        'Content-Type' => 'text/plain; charset=UTF-8; format=flowed',
        'Content-Transfer-Encoding' => '8bit',
        'X-Epoll-version' => $Vote::VERSION,
    );
}

sub random_string {
    my $lenght = $_[-1] || 8;

    return join('', map { ('a'..'z', 'A'..'Z', 0..9)[rand 62] } (1..$lenght));
}

sub gen_enc_passwd {
    my ($self, $passwd) = @_;

    $passwd ||= random_string(8);
    return(crypt($passwd, '$1$' . random_string(8) . '$'));
}

sub dbtime {
    my ($self) = @_;
    my $sth = $self->db->prepare(
        q{select to_char(now(), 'DD/MM/YYYY HH24:MI:SS') as d}
    );

    $sth->execute();
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res->{d};
}

sub list_comming_vote {
    my ($self) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select id from poll where
        (start > now() and "end" > now()) or
        "end" is null or start is null
        }
    );

    $sth->execute;
    my @id;
    while(my $res = $sth->fetchrow_hashref) {
        push(@id, $res->{id});
    }

    @id
}


sub list_running_vote {
    my ($self) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select id from poll where start < now() and "end" > now()
        }
    );

    $sth->execute;
    my @id;
    while(my $res = $sth->fetchrow_hashref) {
        push(@id, $res->{id});
    }

    @id
}

sub list_closed_vote {
    my ($self) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select id from poll where
        start < now() and "end" < now()
        }
    );

    $sth->execute;
    my @id;
    while(my $res = $sth->fetchrow_hashref) {
        push(@id, $res->{id});
    }

    @id
}

sub vote_param {
    my ($self, $voteid, %attr) = @_;

    keys %attr or return;
    my @online_f = qw(label start end owner password);

    if (grep { exists($attr{$_}) } @online_f) {
        my $sth = $self->db->prepare_cached(
            q{update poll set } .
            join(',', map { qq("$_" = ?) } grep { exists $attr{$_} } @online_f) .
            q{ where id = ?}
        );
        $sth->execute((map { $attr{$_} } grep { exists $attr{$_} } @online_f), $voteid)
            or do {
            $self->db->rollback;
            return;
        };
    }

    # vote settings in settings table
    foreach my $var (keys %attr) {
        grep { $var eq $_ } @online_f and next;
        $self->vote_set_settings($voteid, $var, $attr{$var});
    }
    1
}

sub vote_status {
    my ($self, $id) = @_;
    
    my $sth = $self->db->prepare_cached(
        q{
        select (start > now() or start is null) as before,
               "end" < now() as after
        from poll
        where id = ?
        }
    );
    $sth->execute($id);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res or return;
    if ($res->{before}) {
        return 'BEFORE';
    } elsif ($res->{after}) {
        return 'AFTER';
    } else {
        return 'RUNNING';
    }
}

sub vote_info {
    my ($self, $id) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select *,
        to_char("start", 'DD/MM/YYYY') as dstart,
        to_char("start", 'HH24:MI:SS') as hstart,
        to_char("end", 'DD/MM/YYYY') as dend,
        to_char("end", 'HH24:MI:SS') as hend
        from poll where id = ?
        }
    );

    $sth->execute($id);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    if ($res) {
        my $get = $self->db->prepare_cached(
            q{select var, val from settings where poll = ?}
        );
        $get->execute($id);
        while (my $set = $get->fetchrow_hashref) {
            $res->{$set->{var}} = $set->{val};
        }
    }
    $res->{free_choice} ||= 0; # avoiding undef
    $res
}

sub vote_set_settings {
    my ($self, $poll, $var, $val) = @_;

    my $upd = $self->db->prepare_cached(
        q{update settings set val = ? where poll = ? and var = ?}
    );

    if ($upd->execute($val, $poll, $var) == 0) {
        my $add = $self->db->prepare_cached(
            q{insert into settings (poll, var, val) values (?,?,?)}
        );

        $add->execute($poll, $var, $val);
    }
}

sub vote_signing {
    my ($self, $id) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select *, voting.key as vkey from voting left join signing
        on signing.key = voting.key
        where poll = ? order by voting.mail
        }
    );
    $sth->execute($id);
    my @people;
    while (my $res = $sth->fetchrow_hashref) {
        push(@people, $res);
    }
    @people
}

sub vote_voting {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select key from voting
        where poll = ? order by voting.mail
        }
    );
    $sth->execute($voteid);
    my @people;
    while (my $res = $sth->fetchrow_hashref) {
        push(@people, $res->{key});
    }
    @people
}

sub voting_info {
    my ($self, $id) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select *, voting.key as vkey from voting left join signing
        on signing.key = voting.key
        where voting.key = ?
        }
    );
    $sth->execute($id);

    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res
}

sub vote_choices {
    my ($self, $id) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select key from choice where poll = ?
        order by label
        }
    );
    $sth->execute($id);
    my @ch;
    while (my $res = $sth->fetchrow_hashref) {
        push(@ch, $res->{key});
    }
    @ch
}

sub choice_info {
    my ($self, $chid) = @_;
    my $sth = $self->db->prepare_cached(
        q{select * from choice where key = ?}
    );
    $sth->execute($chid);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res
}

sub vote_add_choice {
    my ($self, $voteid, $label) = @_;

    my $sth = $self->db->prepare_cached(
        q{insert into choice (poll, label) values (?,?)}
    );

    $sth->execute($voteid, $label) or do {
        $self->db->rollback;
        return;
    };

    1
}

sub modify_choice {
    my ($self, $chid, $label) = @_;

    my $sth = $self->db->prepare_cached(
        q{update choice set label = ? where key = ?}
    );
    $sth->execute($label, $chid);
}

sub delete_choice {
    my ($self, $chid) = @_;

    my $sth = $self->db->prepare_cached(
        q{delete from choice where key = ?}
    );

    $sth->execute($chid);
}

sub voting_info_id {
    my ($self, $mail, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select * from voting where mail = ? and poll = ?
        }
    );
    $sth->execute($mail, $voteid);
    my $res = $sth->fetchrow_hashref();
    $sth->finish;
    $res
}

sub _register_signing {
    my ($self, $mail, $voteid, $referal) = @_;

    my $vinfo = $self->voting_info_id($mail, $voteid) or return;

    my $sth = $self->db->prepare_cached(
        q{
        insert into signing (key, referal) values (?,?)
        }
    );
    $sth->execute($vinfo->{key}, $referal) or do {
        $self->db->rollback;
        return;
    };

    1;
}

sub gen_uid {
    unpack("H*", join("", map { chr(rand(256)) } (0..15)))
}

sub _register_ballot {
    my ($self, $voteid, $choice, $fchoice) = @_;

    my $addb = $self->db->prepare_cached(
        q{
        insert into ballot (id, poll, invalid) values (?,?,?)
        }
    );
    my $uid = gen_uid;
    $addb->execute($uid, $voteid, scalar(@{$fchoice || []}) ? undef : 'f') or do {
        self->db->rollback;
        return;
    };

    my $addbc = $self->db->prepare_cached(
        q{
        insert into ballot_item (id, value, fromlist) values (?,?,?)
        }
    );
    foreach (@{ $choice || []}) {
        $addbc->execute($uid, $_, 't') or do {
            $self->db->rollback;
            return;
        };
    }
    foreach (@{ $fchoice || []}) {
        $_ or next;
        $addbc->execute($uid, $_, 'f') or do {
            $self->db->rollback;
            return;
        };
    }

    $uid;
}

sub register_ballot {
    my ($self, $vid, $voteid, $choice, $fchoice, $referal) = @_;

    my $uid;
    for (0..2) { # 3 try
    # First we register voting has voted
    $self->_register_signing($vid, $voteid, $referal) or return; # TODO error ?

    # registring choices
    $uid = $self->_register_ballot($voteid, $choice, $fchoice);
    defined($uid) and last;

    }
    # everything went fine, saving!
    $self->db->commit;

    
    $uid
}

sub mail_ballot_confirm {
    my ($self, $vid, $voteid, $info) = @_;
    my $voteinfo = $self->vote_info($voteid) or return;
    $info->{ballotid} or return;
    my $mailer = new Mail::Mailer 'smtp', Server => (Vote->config->{smtp} || 'localhost');
    $ENV{MAILADDRESS} = $vid;
    $mailer->open({
        From => $vid, # TODO allow to configure this
        To => $vid,
        Subject => 'Confirmation de vote: ' . $voteinfo->{label},
        mail_header(),
    });
    print $mailer <<EOF;

Vous venez de participer au vote:

--------
$voteinfo->{label}
--------

Votre bulletin est idéntifié sous le numéro:
$info->{ballotid}

Les résultats seront disponibles à cet url:
$info->{url}

Cordialement.
EOF
    $mailer->close
        or warn "couldn't send whole message: $!\n";

}

sub vote_voting_count {
    my ($self, $id) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select count(*) from voting
        where poll = ?
        }
    );
    $sth->execute($id);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res->{count}
}

sub signing_count { vote_signing_count(@_) }

sub vote_signing_count {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select count(*) from signing join voting
        on voting.key = signing.key where poll = ?
        }
    );

    $sth->execute($voteid);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res->{count}
}

sub ballot_count { vote_ballot_count(@_) }

sub vote_ballot_count {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select count(*) from ballot where poll = ?
        }
    );

    $sth->execute($voteid);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res->{count}
}

sub ballot_count_nonull { vote_ballot_count_nonull(@_) }

sub vote_ballot_count_nonull {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select count(*) from ballot where poll = ?
        and id in (select id from ballot_item) and
        (invalid = 'false' or invalid is null)
        }
    );

    $sth->execute($voteid);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res->{count}
}

sub auth_voting {
    my ($self, $poll, $mail, $password) = @_;
    my $userinfo = $self->voting_info_id($mail, $poll) or return;

    $userinfo->{passwd} or return;
    if (crypt($password, $userinfo->{passwd} || '') eq $userinfo->{passwd}) {
        return 1;
    } else {
        return 0;
    }
}

sub auth_poll {
    my ($self, $voteid, $passwd) = @_;

    my $vinfo = $self->vote_info($voteid) or return;

    $vinfo->{password} or return;
    $passwd or return;
    if (crypt($passwd, $vinfo->{password} || '') eq $vinfo->{password}) {
        return 1;
    } else {
        return 0;
    }
}

sub voting_has_sign {
    my ($self, $poll, $user) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select date from signing join voting
        on voting.key = signing.key
        where poll = ? and mail = ?
        }
    );

    $sth->execute($poll, $user);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    return $res->{date}
}

# Requete de decompte des voix:

sub vote_results_count {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare(
        q{
        select count(ballot.id), value from ballot left join ballot_item
        on ballot.id = ballot_item.id where ballot.poll = ? and invalid = 'false'
        group by value
        order by count
        }
    );
    $sth->execute($voteid);
    my @results;
    while (my $res = $sth->fetchrow_hashref) {
        push(@results, $res);
    }
    @results;
}

sub vote_results_nonull {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare(
        q{
        select count(ballot.id), coalesce(corrected, value) as value
        from ballot join ballot_item
        on ballot.id = ballot_item.id where ballot.poll = ? and
        (invalid = 'false' or invalid is null)
        group by coalesce(corrected, value)
        order by count desc
        }
    );
    $sth->execute($voteid);
    my @results;
    while (my $res = $sth->fetchrow_hashref) {
        push(@results, $res);
    }
    \@results;
}

sub list_vote_ballot {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select id from ballot where poll = ?
        order by id
        }
    );
    $sth->execute($voteid);
    my @ids;
    while (my $res = $sth->fetchrow_hashref) {
        push(@ids, $res->{id});
    }
    @ids
}

sub list_vote_ballot_needvalid {
    my ($self, $voteid) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        select id from ballot where poll = ?
        and invalid is null order by id
        }
    );
    $sth->execute($voteid);
    my @ids;
    while (my $res = $sth->fetchrow_hashref) {
        push(@ids, $res->{id});
    }
    @ids
}

sub ballot_info {
    my ($self, $ballotid) = @_;

    my $sth = $self->db->prepare_cached(
        q{ select * from ballot where id = ? }
    );

    $sth->execute($ballotid);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res
}

sub mark_ballot_invalid {
    my ($self, $ballotid, $invalid) = @_;

    my $sth = $self->db->prepare_cached(
        q{update ballot set invalid = ? where id = ?}
    );

    $sth->execute($invalid ? 't' : 'f', $ballotid);
}

sub ballot_items {
    my ($self, $ballotid) = @_;

    my $sth = $self->db->prepare_cached(
        q{select *, value as v from ballot_item where id = ?}
    );
    $sth->execute($ballotid);
    my @ids;
    while (my $res = $sth->fetchrow_hashref) {
        push(@ids, $res);
    }
    \@ids
}

sub vote_ballot_untrusted_values {
    my ($self, $voteid) = @_;

    my $getval = $self->db->prepare_cached(
        q{
        select value from ballot join ballot_item
        on ballot.id = ballot_item.id
        where poll = ? and fromlist = false and corrected is null
        group by value order by value
        }
    );
    $getval->execute($voteid);
    my @vals;
    while (my $res = $getval->fetchrow_hashref) {
        push(@vals, $res->{value});
    }
    @vals
}

sub vote_ballot_values {
    my ($self, $voteid) = @_;

    my $getval = $self->db->prepare_cached(
        q{
        select coalesce(corrected, value) as value from ballot join ballot_item
        on ballot.id = ballot_item.id
        where poll = ?
        group by coalesce(corrected, value) order by coalesce(corrected, value)
        }
    );
    $getval->execute($voteid);
    my @vals;
    while (my $res = $getval->fetchrow_hashref) {
        push(@vals, $res->{value});
    }
    @vals
}

sub vote_map_value {
    my ($self, $voteid, $from, $to) = @_;

    my $sth = $self->db->prepare_cached(
        q{
        update ballot_item set corrected = ? where
        id in (select id from ballot where poll = ?)
        and (value = ? or corrected = ?)
        }
    );

    $sth->execute($to, $voteid, $from, $from) or $self->db->rollback;
    $self->db->commit;
}

sub addupd_voting {
    my ($self, $voteid, $mail, $id) = @_;

    $mail =~ s/\s*$//;
    $mail =~ s/^\s*//;
    $mail = lc($mail);
    $id =~ s/\s*$//;
    $id =~ s/^\s//;
    my $upd = $self->db->prepare_cached(
        q{
        update voting set label = ? where mail = ? and poll = ?
        }
    );

    if ($upd->execute($id || '', $mail, $voteid) == 0) {
        my $add = $self->db->prepare_cached(q{
            insert into voting (poll, label, mail) values (?,?,?)
        });

        $add->execute($voteid, $id || '', $mail);
    }
}

sub delete_voting {
    my ($self, $key) = @_;

    $self->voting_has_sign($key) and return;
    my $sth = $self->db->prepare_cached(
        q{delete from voting where key = ?}
    );

    $sth->execute($key);
}

sub voting_from_file {
    my ($self, $voteid, $fh, $delete) = @_;

    if ($delete) {
        my $sth = $self->db->prepare(q{delete from voting where poll = ?});
        $sth->execute($voteid);
    }

    while (my $line = <$fh>) {
        chomp($line);
        my ($mail, $name) = split(';', $line);
        $mail or do {
            $self->db->rollback;
            return;
        };
        $self->addupd_voting($voteid, $mail, $name || '');
    }
    1;
}

sub mail_passwd_ifnul {
    my ($self, $voteid, $mailinfo) = @_;

    my $list_voting = $self->db->prepare_cached(
        q{select key from voting where poll = ? and passwd is null or passwd = ''}
    );

    $list_voting->execute($voteid);
    while (my $res = $list_voting->fetchrow_hashref) {
        $self->mail_voting_passwd($res->{key}, $mailinfo);
    }
}

sub mail_voting_passwd {
    my ($self, $id, $mailinfo) = @_;
    
    my $vinfo = $self->voting_info($id) or return;
    my $voteinfo = $self->vote_info($vinfo->{poll});
    $voteinfo->{description} ||= "";

    my $passwd = random_string(8);
    my $encpasswd = $self->gen_enc_passwd($passwd);

    my $upd_voting = $self->db->prepare_cached(
        q{update voting set passwd = ? where key = ?}
    );

    $upd_voting->execute($encpasswd, $id);

    my $date = $voteinfo->{dstart} && $voteinfo->{dend}
        ? sprintf("\n" . 'Vous pourrez voter entre le %s %s et le %s %s' . "\n",
            $voteinfo->{dstart}, $voteinfo->{hstart}, $voteinfo->{dend}, $voteinfo->{hend})
        : '';

    # TODO complete this properly:
    my $mailer = new Mail::Mailer 'smtp', Server => (Vote->config->{smtp} || 'localhost');
    $ENV{MAILADDRESS} = $voteinfo->{owner};
    $mailer->open({
        From => $voteinfo->{owner},
        To => $vinfo->{mail},
        Subject => 'Invitation a voter: ' . $voteinfo->{label},
        'X-Epoll-poll' => $id,
        mail_header(),
    });
    print $mailer <<EOF;
Vous êtes convié à participer a ce vote:

--------
$voteinfo->{label}
--------
$voteinfo->{description}
--------

à l'adresse:

$mailinfo->{voteurl}
$date

-- 
Votre identifiant est: $vinfo->{mail}
Votre mot de passe est: $passwd

Conservez précieusement ces identifiants, il ne vous seront pas retransmits.

Cordialement.
EOF
    $mailer->close or warn "couldn't send whole message: $!\n";

    $self->db->commit;
}

sub poll_request_info {
    my ($self, $rid) = @_;

    my $sth = $self->db->prepare_cached(
        q{select * from poll_request where id = ?}
    );

    $sth->execute($rid);
    my $res = $sth->fetchrow_hashref;
    $sth->finish;
    $res
}

sub poll_from_request {
    my ($self, $rid, $passwd) = @_;
    my $rinfo = $self->poll_request_info($rid) or return;

    my $encpasswd = $self->gen_enc_passwd($passwd);

    my $getpollid = $self->db->prepare_cached(
        q{select nextval('poll_id_seq')}
    );
    $getpollid->execute();
    my $newpollid = $getpollid->fetchrow_hashref->{nextval};
    
    my $newpoll = $self->db->prepare_cached(
        q{insert into poll (id, label, owner, password) values (?,?,?,?)}
    );

    $newpoll->execute($newpollid, $rinfo->{label}, $rinfo->{mail}, $encpasswd);
    # set some default
    $self->vote_param($newpollid,
        free_choice => 0,
        choice_count => 1,
    );     

    my $delreq = $self->db->prepare_cached(
        q{delete from poll_request where id = ?}
    );

    $delreq->execute($rid);
    $self->db->commit;

    $newpollid
}

sub create_poll_request {
    my ($self, %info) = @_;

    $info{mail} or return;
    my $addreq = $self->db->prepare_cached(
        q{insert into poll_request (id, label, mail) values (?,?,?)}
    );

    my $reqid = gen_uid;

    $addreq->execute($reqid, $info{label}, $info{mail});
    my $mailer = new Mail::Mailer 'smtp', Server => (Vote->config->{smtp} || 'localhost');
    $ENV{MAILADDRESS} = undef;
    $mailer->open({
        From => 'Voting system <nomail@nomail.com>', # TODO allow to configure this
        To => $info{mail},
        Subject => 'Votre nouveau vote',
        mail_header(),
    });
    print $mailer <<EOF;

Vous avez demandez la création d'un nouveau vote:
$info{label}

Pour valider votre demande, veuiller allez visitez la page:
$info{url}/$reqid

A bientôt
EOF
    $mailer->close
        or warn "couldn't send whole message: $!\n";
    $self->db->commit;
    1;
}

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
