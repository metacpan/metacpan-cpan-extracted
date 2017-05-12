package WWW::Connpass::Session;
use strict;
use warnings;

use Carp qw/croak/;
use Web::Query qw/wq/;
use Text::CSV_XS;
use JSON 2;
use URI;

use WWW::Connpass::Agent;
use WWW::Connpass::Event;
use WWW::Connpass::Event::Questionnaire;
use WWW::Connpass::Event::Participants;
use WWW::Connpass::Group;
use WWW::Connpass::Place;
use WWW::Connpass::User;

use constant DEBUG => $ENV{WWW_CONNPASS_DEBUG};

my $_JSON = JSON->new->utf8;

sub new {
    my ($class, $user, $pass, $opt) = @_;

    my $mech = WWW::Connpass::Agent->new(%$opt, cookie_jar => {});
    $mech->get('https://connpass.com/login/');
    $mech->form_id('login_form');
    $mech->set_fields(username => $user, password => $pass);
    my $res = $mech->submit();
    _check_response_error_or_throw($res);

    my $error = wq($res->decoded_content)->find('.errorlist > li')->map(sub { $_->text });
    if (@$error) {
        my $message = join "\n", @$error;
        croak "Failed to login by user: $user. error: $message";
    }

    return bless {
        mech => $mech,
        user => $user,
    } => $class;
}

sub user { shift->{user} }

sub _check_response_error_or_throw {
    my $res = shift;
    unless ($res->is_success) {
        my $message = sprintf '[ERROR] %d %s: %s', $res->code, $res->message, $res->decoded_content;
        $message = "=REQUEST\n".$res->request->as_string."\nRESPONSE=\n".$res->as_string if DEBUG;
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        croak $message;
    }
    return $res;
}

sub new_event {
    my ($self, $title) = @_;

    my $res = $self->{mech}->request_like_xhr(POST => 'http://connpass.com/api/event/', {
        title => $title,
        place => undef,
    });
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Event->new(session => $self, event => $data);
}

sub fetch_event_by_id {
    my ($self, $event_id) = @_;
    my $uri = sprintf 'http://connpass.com/api/event/%d', $event_id;

    my $res = $self->{mech}->get($uri);
    return if $res->code == 404;
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Event->new(session => $self, event => $data);
}

sub refetch_event {
    my ($self, $event) = @_;
    return $self->fetch_event_by_id($event->id);
}

sub update_event {
    my ($self, $event, $diff) = @_;
    my $uri = sprintf 'http://connpass.com/api/event/%d', $event->id;

    my $res = $self->{mech}->request_like_xhr(PUT => $uri, {
        %{ $event->raw_data },
        $event->place ? (
            place => $event->place->{id},
        ) : (),
        %$diff,
    });
    _check_response_error_or_throw($res);

    $event = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Event->new(session => $self, event => $event);
}

sub update_waitlist_count {
    my ($self, $event, @waitlist_count) = @_;
    my %update = map { $_->id => $_ } grep { !$_->is_new } @waitlist_count;
    my @update = map { $_->raw_data } map { delete $update{$_->id} || $_ } $event->waitlist_count();
    push @update => map { $_->raw_data } grep { $_->is_new } @waitlist_count;

    my $uri = sprintf 'http://connpass.com/api/event/%d/participation_type/', $event->id;
    my $res = $self->{mech}->request_like_xhr(PUT => $uri, \@update);
    _check_response_error_or_throw($res);

    return $self->refetch_event($event);
}

sub fetch_questionnaire_by_event {
    my ($self, $event) = @_;
    my $uri = sprintf 'http://connpass.com/api/question/%d', $event->id;
    my $res = $self->{mech}->get($uri);
    # HTTP::Response
    if ($res->code == 404) {
        return WWW::Connpass::Event::Questionnaire->new(
            session       => $self,
            questionnaire => {
                id        => undef,
                questions => [],
                event     => $event->id,
            },
        );
    }
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Event::Questionnaire->new(session => $self, questionnaire => $data);
}

sub update_questionnaire {
    my ($self, $questionnaire, @question) = @_;

    my $method = $questionnaire->is_new ? 'POST' : 'PUT';
    my $uri = sprintf 'http://connpass.com/api/question/%d', $questionnaire->event;
    my $res = $self->{mech}->request_like_xhr($method => $uri, {
        %{ $questionnaire->raw_data },
        questions => [map { $_->raw_data } @question],
    });
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Event::Questionnaire->new(session => $self, questionnaire => $data);
}

sub register_place {
    my ($self, %data) = @_;

    my $res = $self->{mech}->request_like_xhr(POST => 'http://connpass.com/api/place/', \%data);
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Place->new(session => $self, place => $data);
}

sub add_owner_to_event {
    my ($self, $event, $user) = @_;
    my $uri = sprintf 'http://connpass.com/api/event/%d/owner/%d', $event->id, $user->id;
    my $res = $self->{mech}->request_like_xhr(POST => $uri, { id => $user->id });
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::User->new(user => $data);
}

sub update_place {
    my ($self, $place, %data) = @_;
    my $uri = sprintf 'http://connpass.com/api/place/%d', $place->id;
    my $res = $self->{mech}->request_like_xhr(PUT => $uri, {
        %{ $place->raw_data },
        %data,
    });
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Place->new(session => $self, place => $data);
}

sub fetch_all_places {
    my $self = shift;

    my $res = $self->{mech}->get('http://connpass.com/api/place/');
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return map { WWW::Connpass::Place->new(session => $self, place => $_) } @$data;
}

sub fetch_place_by_id {
    my ($self, $place_id) = @_;
    my $uri = sprintf 'http://connpass.com/api/place/%d', $place_id;

    my $res = $self->{mech}->get($uri);
    return if $res->code == 404;
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return WWW::Connpass::Place->new(session => $self, place => $data);
}

sub refetch_place {
    my ($self, $place) = @_;
    return $self->fetch_place_by_id($place->id);
}

sub search_users_by_name {
    my ($self, $name) = @_;
    my $uri = URI->new('http://connpass.com/api/user/');
    $uri->query_form(q => $name);

    my $res = $self->{mech}->get($uri);
    _check_response_error_or_throw($res);

    my $data = $_JSON->decode($res->decoded_content);
    return map { WWW::Connpass::User->new(user => $_) } @$data;
}

sub fetch_managed_events {
    my $self = shift;
    my $res = $self->{mech}->get('http://connpass.com/editmanage/');
    _check_response_error_or_throw($res);
    return map { WWW::Connpass::Event->new(session => $self, event => $_) }
        map { $_JSON->decode($_) } @{
            wq($res->decoded_content)->find('#EventManageTable .event_list > table')->map(sub { $_->data('obj') })
        };
}

sub fetch_organized_groups {
    my $self = shift;
    my $res = $self->{mech}->get('http://connpass.com/group/');
    _check_response_error_or_throw($res);

    my $groups = wq($res->decoded_content)->find('.series_lists_area .series_list .title a')->map(sub {
        my $title  = $_->text;
        my $url    = $_->attr('href');
        my ($id)   = wq(_check_response_error_or_throw($self->{mech}->get($url))->decoded_content)->find('.icon_gray_edit')->parent()->attr('href') =~ m{/series/([^/]+)/edit/$};
        my ($name) = $url =~ m{^https?://([^.]+)\.connpass\.com/};
        return unless $id;
        return {
            id    => $id,
            name  => $name,
            title => $title,
            url   => $url,
        };
    });

    return map { WWW::Connpass::Group->new(session => $self, group => $_) } @$groups;
}

sub fetch_participants_info {
    my ($self, $event) = @_;
    my $uri = sprintf 'http://connpass.com/event/%d/participants_csv/', $event->id;

    my $res = $self->{mech}->get($uri);
    _check_response_error_or_throw($res);

    # HTTP::Response
    my $content = $res->decoded_content;

    my $csv = Text::CSV_XS->new({ binary => 1, decode_utf8 => 0, eol => "\r\n", auto_diag => 1 });

    my @questions = $event->questionnaire->questions;
    my @params = qw/waitlist_name username nickname comment registration attendance/;
    push @params => map { 'answer_'.$_ } keys @questions;
    push @params => qw/updated_at receipt_id/;

    my @lines = split /\r\n/, $content;
    my %label; @label{@params} = do {
        my $header = shift @lines;
        my $success = $csv->parse($header);
        die "Invalid CSV syntax: $header" unless $success;
        $csv->fields;
    };

    my @rows;
    for my $line (@lines) {
        my $success = $csv->parse($line);
        die "Invalid CSV syntax: $line" unless $success;

        my %row;
        @row{@params} = $csv->fields;
        push @rows => \%row;
    }

    return WWW::Connpass::Event::Participants->new(
        label => \%label,
        rows  => \@rows,
    );
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Session - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Session;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
