package WWW::RobotRules::DBIC;

use strict;
use base qw(WWW::RobotRules);
use WWW::RobotRules::DBIC::Schema;
use DateTime;
use DateTime::Format::Strptime;

our $VERSION = '0.01';

sub new {
    my($class, @connect_info) = @_;
    my $self = bless {
        schema => WWW::RobotRules::DBIC::Schema->connect(@connect_info),
    }, $class;
    $self;
}

sub agent {
    my($self, $agent) = @_;
    my $old = $self->{agent};
    if (defined $agent && (!$old || $agent ne $old)) {
        $agent =~ s|/.*$||; # remove version number.
        my $new = $self->{schema}->resultset('UserAgent')->find_or_create({
            name => $agent,
        });
        $self->{agent} = $agent;
        $self->{agent_id} = $new->id;
        $self->{_netloc} = undef;
    }
    $old;
}

sub visit {
    my($self, $netloc, $time) = @_;
    return unless $netloc;
    $time ||= time;
    my $datetime = epoch2datetime($time);
    my $old = $self->_find_netloc($netloc);
    if ($old) {
        my $count = $old->count + 1;
        $old->count($count);
        $old->visited_on($datetime);
        $old->update;
    }
    else {
        $self->{schema}->resultset('Netloc')->create({
            user_agent_id => $self->{agent_id},
            netloc => $netloc,
            count => 1,
            visited_on => $datetime,
        });
    }
}

sub no_visits {
    my($self, $netloc) = @_;
    $netloc = $self->_find_netloc($netloc);
    return 0 unless $netloc;
    return $netloc->count;
}

sub last_visit {
    my($self, $netloc) = @_;
    $netloc = $self->_find_netloc($netloc);
    return unless $netloc && $netloc->visited_on;
    return datetime2epoch($netloc->visited_on);
}

sub fresh_until {
    my ($self, $netloc, $fresh) = @_;
    $netloc = $self->_find_netloc($netloc, 1);
    my $old = $netloc->fresh_until;
    if (defined $fresh) {
        my $datetime = epoch2datetime($fresh);
        $netloc->fresh_until($datetime);
        $netloc->update;
    }
    return datetime2epoch($old) if $old;
}

sub push_rules {
    my($self, $netloc, @rules) = @_;
    $netloc = $self->_find_netloc($netloc, 1);
    for my $rule(@rules) {
        $self->{schema}->resultset('Rule')->create({
            rule => $rule,
            netloc_id => $netloc->id,
        });
    }
}

sub clear_rules {
    my($self, $netloc) = @_;
    $netloc = $self->_find_netloc($netloc);
    if ($netloc) {
        $self->{schema}->resultset('Rule')->search({netloc_id => $netloc->id})->delete;
    }
}

sub rules {
    my($self, $netloc) = @_;
    my @rules = $self->{schema}->resultset('Rule')->search({
        'netloc.netloc' => $netloc,
        'netloc.user_agent_id' => $self->{agent_id},
    }, {
        join => [qw(netloc)],
    });
    return map { $_->rule } @rules;
}

sub dump {}

sub _find_netloc {
    my($self, $netloc, $create) = @_;
    my $old = $self->{_netloc};
    if ($old && $old->netloc eq $netloc) {
        return $old;
    }
    my $obj = $self->{schema}->resultset('Netloc')->find({
        netloc => $netloc,
        user_agent_id => $self->{agent_id},
    });
    if (!$obj && $create) {
        $obj = $self->{schema}->resultset('Netloc')->create({
            netloc => $netloc,
            user_agent_id => $self->{agent_id},
            count => '0',
        });
    }
    $self->{_netloc} = $obj;
    $obj;
}

sub datetime2epoch {
    my $str = shift;
    return unless $str;
    my $format = DateTime::Format::Strptime->new(
        pattern     => '%Y-%m-%d %H:%M:%S',
        time_zone   => 'local',
    );
    my $dt = $format->parse_datetime($str);
    return $dt->epoch if $dt;
}

sub epoch2datetime {
    my $epoch = shift;
    return unless $epoch;
    my $dt = DateTime->from_epoch(epoch => $epoch);
    $dt->set_time_zone('local');
    return $dt->strftime('%Y-%m-%d %H:%M:%S');
}

1;

__END__

=head1 NAME

WWW::RobotRules::DBIC - Persistent RobotRules which use DBIC.

=head1 DESCRIPTION

WWW::RobotRules::DBIC is a subclass of WWW::RobotRules, which use DBIx::Class to store robots.txt info to any RDBMS.

=head1 SYNOPSIS

    use WWW::RobotRules::DBIC;
    use LWP::RobotUA;

    my $rules = WWW::RobotRules::DBIC->new('dbi:mysql:robot_rules', 'root', '', \%options);
    my $ua = LWP::RobotUA->new(
       agent => 'YourRobot/1.0',
       from => 'you@example.com',
       rules => $rules,
    );

=head1 AUTHOR

Tomohiro IKEBE, C<< <ikebe@shebang.jp> >>

=head1 SEE ALSO

L<WWW::RobotRules> L<DBIx::Class>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Tomohiro IKEBE, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

