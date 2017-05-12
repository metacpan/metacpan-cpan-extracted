package Vote::Controller::Admin;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

Vote::Controller::Admin - Catalyst Controller

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
    my $vote = $c->model('Vote');

    $vote->vote_info($id) or do {
        $c->res->redirect($c->uri_for('/'));
        return;
    };

    my $password = $c->session->{vpassword} || $c->req->param('vpassword');

    if (!$c->model('Vote')->auth_poll($id, $password)) {
        $c->stash->{page}{title} = $vote->vote_info($id)->{label} . ': Login d\'administration';
        $c->session->{vpassword} = undef;
        $c->stash->{template} = 'admin/login.tt';
        return;
    }

    $c->session->{vpassword} = $password;

    $c->stash->{page}{title} = $c->model('Vote')->vote_info($id)->{label} . ': Administration';

    for ($vote->vote_status($id) || '') {
    /^BEFORE$/ and do {
        if ($c->req->param('addch')) {
            $vote->vote_add_choice($id, $c->req->param('addch'))
                and $vote->db->commit;
        } elsif ($c->req->param('delch')) {
            $vote->delete_choice($c->req->param('delch'))
                and $vote->db->commit;
        } elsif ($c->req->param('label')) {
            if ($c->req->param('dstart')) {
                $c->req->param('start',
                    $c->req->param('dstart') . ' ' . ($c->req->param('hstart') || '')
                );
            }
            if ($c->req->param('dend')) {
                $c->req->param('end',
                    $c->req->param('dend') . ' ' . ($c->req->param('hend') || '')
                );
            }
            $vote->vote_param(
                $id,
                map { $_ => ($c->req->param($_) || undef) }
                qw(label description start end choice_count free_choice)
            ) and $vote->db->commit;
        }
    };

    /^(BEFORE|RUNNING)$/ and do {
        if (my ($upload) = $c->req->upload('votinglist')) {
            $vote->voting_from_file(
                $id,
                $upload->fh,
                $c->req->param('delete'),
            ) and $vote->db->commit;
        } elsif($c->req->param('delvoting')) {
            $vote->delete_voting($c->req->param('delvoting'))
                and $vote->db->commit;
        } elsif ($c->req->param('mail')) {
            $vote->addupd_voting($id, $c->req->param('mail'), $c->req->param('id'))
                and $vote->db->commit;
        } elsif($c->req->param('mailpasswd')) {
            $vote->mail_passwd_ifnul($id, {
                voteurl => $c->uri_for('/ballot', $id),
            });
        }
    };

    /^AFTER$/ and do {
        if ($c->req->param('mapfrom') && $c->req->param('mapto')) {
            $vote->vote_map_value(
                $id,
                $c->req->param('mapfrom'),
                $c->req->param('mapto'),
            );
        }
        foreach my $bid ($vote->list_vote_ballot_needvalid($id)) {
            if (!$c->req->param($bid)) {
                next;
            } elsif($c->req->param($bid) eq 'invalid') {
                $vote->mark_ballot_invalid($bid, 1);
                $vote->db->commit;
            } elsif($c->req->param($bid) eq 'valid') {
                $vote->mark_ballot_invalid($bid, 0);
                $vote->db->commit;
            }
        }
    };
    }

}

=head1 AUTHOR

Thauvin Olivier

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
