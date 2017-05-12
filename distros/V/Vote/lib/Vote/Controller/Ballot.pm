package Vote::Controller::Ballot;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Vote::Controller::Ballot - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->model('Vote')->db->rollback;
}

sub index : Private {
    my ( $self, $c ) = @_;

    $c->res->redirect($c->uri_for('/'));
}

sub default : Private {
    my ( $self, $c, undef, $id ) = @_;

    $c->stash->{voteid} = $id;

    if ($c->model('Vote')->vote_status($id) ne 'RUNNING') {
        $c->stash->{template} = 'ballot/closed.tt';
        return;
    }

    my $mail = $c->session->{mail} || $c->req->param('mail');
    my $password = $c->session->{password} || $c->req->param('password');

    if (!$c->model('Vote')->auth_voting($id, $mail, $password)) {
        $c->stash->{page}{title} = $c->model('Vote')->vote_info($id)->{label} . ': Login';
        $c->delete_session('invalid user/pass');
        $c->stash->{template} = 'ballot/login.tt';
        if (defined($c->req->param('password'))) {
            $c->stash->{login_failure} = 1;
        }
        return;
    }

    $c->session->{mail} = $mail;
    $c->session->{password} = $password;

    $c->stash->{page}{title} = $c->model('Vote')->vote_info($id)->{label} . ': Bulletin';

    # login succeed, but those this user has already voted
    if (my $date = $c->model('Vote')->voting_has_sign($id, $mail)) {
        $c->stash->{mail} = $c->session->{mail};
        $c->stash->{template} = 'ballot/signed.tt';
        $c->stash->{signed_date} = $date;
        $c->delete_session('already signed');
        return;
    }

    my $vote = $c->model('Vote');
    my %choices;
    foreach ($vote->vote_choices($id)) {
        $choices{$vote->choice_info($_)->{key}} = $vote->choice_info($_)->{label};
    }
    $c->stash->{choices} = { %choices };
    $c->stash->{sbal} = { map { $_ => 1 } $c->req->param('sbal') };
    $c->stash->{fsbal} = [ grep { $_ } map {
        s/^\s+//;
        s/\s+$//;
        s/\s+/ /g;
        lc($_)
    } ($c->req->param('fsbal')) ];
    $c->request->parameters->{fsbal} = $c->stash->{fsbal};

    my @sbalval = grep { $_ } map { lc($choices{$_} || '') } $c->req->param('sbal');

    if (scalar(@sbalval) + scalar(@{$c->stash->{fsbal} || []})
        > $vote->vote_info($id)->{choice_count}) {
        $c->req->parameters->{'ballot'} = '';
        $c->stash->{vote_error} = 'Seulement ' .
            $vote->vote_info($id)->{choice_count} . ' choix possible';
        return;
    }
    {
        my %uniq;
        foreach(@sbalval, @{$c->stash->{fsbal} || []}) {
            $uniq{lc($_)} ||= 0; # avoid undef
            $uniq{lc($_)}++;
        }
        my @twices = grep { $uniq{$_} > 1 } (sort keys %uniq);
        if (scalar(@twices)) {
            $c->req->parameters->{'ballot'} = '';
            $c->stash->{vote_error} = 'Une ou plusieurs valeurs sont en double: ' .
                join(' ,', map { qq'"$_"' } @twices);
            return;
        }
    }

    if ($c->req->param('confirm')) {
        $c->stash->{ballotid} = $vote->register_ballot(
            $mail,
            $id,
            [ @sbalval ],
            [ @{ $c->stash->{fsbal} } ],
            $c->req->address,
        ); # TODO trap error
        $vote->mail_ballot_confirm($mail, $id, {
                ballotid => $c->stash->{ballotid},
                url => $c->uri_for('/vote', $id),
        });
        $c->stash->{template} = 'ballot/done.tt';
        $c->delete_session('Vote terminé');
    }
}

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
