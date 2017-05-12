package Text::Karma;
BEGIN {
  $Text::Karma::AUTHORITY = 'cpan:HINRIK';
}
{
  $Text::Karma::VERSION = '0.05';
}

use 5.010;
use Any::Moose;
use Any::Moose 'X::StrictConstructor';
use Any::Moose '::Util::TypeConstraints';
use Carp 'croak';
use namespace::clean -except => 'meta';

subtype 'TablePrefix',
    as 'Str',
    where { $_ =~ /^\w+$/ },
    message { 'Table prefix must match /^\w+$/' };

has dbh => (
    isa => 'DBI::db',
    is  => 'ro',
);

has table_prefix => (
    isa => 'TablePrefix',
    is  => 'ro',
);

has _sth_add_karma => (
    isa => 'DBI::st',
    is  => 'rw',
);

has _sth_get_karma => (
    isa => 'DBI::st',
    is  => 'rw',
);

has _sth_get_karma_i => (
    isa => 'DBI::st',
    is  => 'rw',
);

sub BUILD {
    my ($self) = @_;
    $self->_init_db if $self->dbh;
    return;
}

sub _init_db {
    my ($self) = @_;
    my $dbh = $self->dbh;

    my $db = $dbh->get_info(17);
    my $text = $db =~ /mysql/ ? 'VARCHAR(255)' : 'TEXT';
    my $table = ($self->table_prefix // '').'karma';

    $dbh->do(<<"SQL"
CREATE TABLE IF NOT EXISTS $table (
    who       TEXT NOT NULL,
    'where'   TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    karma     TEXT NOT NULL,
    mode      BOOL NOT NULL,
    comment   TEXT,
    said      TEXT NOT NULL
)
SQL
    ) or die $dbh->errstr;

    $dbh->do("CREATE INDEX IF NOT EXISTS ${table}_karma ON ${table} (karma)") or die $dbh->errstr;
    $dbh->do("CREATE INDEX IF NOT EXISTS ${table}_mode ON ${table} (mode)") or die $dbh->errstr;

    my $sth_add_karma = $dbh->prepare(
        "INSERT INTO $table (who, 'where', timestamp, karma, mode, comment, said) "
        .'VALUES (?, ?, ?, ?, ?, ?, ?)'
    ) or die $dbh->errstr;
    $self->_sth_add_karma($sth_add_karma);

    # case-sensitive search or not?
    my $select   = "SELECT mode, count(mode) AS count FROM $table WHERE karma = ?";
    my $nocase   = ' COLLATE NOCASE';
    my $group_by = ' GROUP BY mode';

    my $get_sql = $select . $group_by;
    my $sth_get_karma = $dbh->prepare($get_sql) or die $dbh->errstr;
    $self->_sth_get_karma($sth_get_karma);

    my $get_sql_i = $select . $nocase . $group_by;
    my $sth_get_karma_i = $dbh->prepare($get_sql_i) or die $dbh->errstr;
    $self->_sth_get_karma_i($sth_get_karma_i);

    return;
}

sub process_karma {
    my ($self, %args) = @_;

    for my $arg (qw(nick who where str)) {
        croak("$arg argument missing") if !defined $args{$arg};
    }

    # get the list of karma matches
    my @matches = $args{str} =~ /(\([^\)]+\)|\S+)(\+\+|--)\s*(\#.+)?/g;
    my @changes;
    if (@matches) {
        while (my ($subject, $op, $comment) = splice @matches, 0, 3) {
            # clean the karma of spaces and () as we had to capture them
            $subject =~ s/^[\s\(]+//;
            $subject =~ s/[\s\)]+$//;

            # Is it a selfkarma?
            if (!$args{self_karma} && lc($subject) eq lc($args{nick})) {
                # TODO add selfkarma penalty?
                next;
            }
            else {
                # clean the comment
                $comment =~ s/^\s*\#\s*// if defined $comment;
                $op = $op eq '++' ? 1 : 0;
                my $time = time;

                push @changes, {
                    subject => $subject,
                    op      => $op,
                    comment => $comment,
                };

                if ($self->dbh) {
                    my $sth = $self->_sth_add_karma;
                    $sth->execute(
                        $args{who}, $args{where}, $time, $subject, $op, $comment, $args{str},
                    ) or die $sth->errstr;
                }
            }
        }
    }

    return \@changes;
}

sub get_karma {
    my ($self, %args) = @_;

    croak('No subject specified') if !defined $args{subject};
    croak('No database handle supplied') if !$self->dbh;

    # Get the score from the DB
    my $sth = $args{case_sens} ? $self->_sth_get_karma : $self->_sth_get_karma_i;
    $sth->execute($args{subject}) or die $sth->errstr;
    my ($up, $down) = (0, 0);

    while (my $row = $sth->fetchrow_arrayref) {
        if ($row->[0] == 1) {
            $up = $row->[1];
        }
        else {
            $down = $row->[1];
        }
    }

    return if $up == 0 && $down == 0;
    return {
        score => $up - $down,
        up    => $up,
        down  => $down,
    }
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

Text::Karma - Process (and optionally store) karma points

=head1 SYNOPSIS

 use 5.010;
 use strict;
 use warnings;
 use Text::Karma;
 use DBI;

 my $dbh = DBI->connect("dbi:SQLite:dbname=karma.sqlite","","");
 my $karma = Text::Karma(dbh => $dbh);

 $karma->process_karma(
     nick  => 'someone',
     who   => 'someone!from@somewhere',
     where => '#in_here',
     str   => "this thing++ is awesome # some cool comment",
 );

 say "Karma for thing: ".$karma->get_karma("thing");

=head1 METHODS

=head2 C<new>

Constructs and returns a Text::Karma object. Takes the following arguments:

B<'dbh'>, an optional database handle.

B<'table_prefix'>, a prefix to use for the table that will be created if
you supplied a database handle.

=head2 C<process_karma>

Processes karma from a string, and returns the results. They will also be
stored in the database if you supplied a database handle to L<C<new>|/new>.
Takes the following arguments:

B<'nick'>, the nickname of the person who wrote the text. Required.

B<'who'>, the full name of the person who wrote the text. Required.

B<'where'>, the place where the person wrote the text. Required.

B<'str'>, the text that the person wrote. Required.

B<'self_karma'>, whether to allow people to affect their own karma. Optional.
Defaults to false.

The return value will be an arrayref containing a hashref for each karma
operation. They will have the following keys:

B<'subject'>, the subject of the karma operation (e.g. 'foo' in 'foo++').

B<'op'>, the karma operation (0 if it was '--', 1 if it was '++').

B<'comment'>, a potential comment for the karma change.

=head2 C<get_karma>

This method returns the karma for a given subject from the database. Takes
one argument, a subject to look up. If the subject is unknown, nothing is
returns. Otherwise, you'll get a hashref with the following keys:

B<'up'>, number of karma upvotes for the subject.

B<'down'>, number of karma downvotes for the subject.

B<'score'>, the karma score for the subject (B<'up'> minus B<'down'>).

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson <hinrik.sig@gmail.com>

Apocalypse <APOCAL@cpan.org>

=head1 CONTACT

=head2 Email

You can email the authors of this module at C<hinrik.sig@gmail.com>
or C<APOCAL@cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC (Internet Relay Chat). If you don't know
what IRC is, please read this excellent guide:
L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please be courteous
and patient when talking to us, as we might be busy or sleeping! You can
join the following networks/channels and get help:

=over 4

=item * MAGnet

You can connect to the server at 'irc.perl.org', join the C<#perl-help>
channel, and talk to C<Hinrik> or C<Apocalypse>.

=item * FreeNode

You can connect to the server at 'irc.freenode.net', join the C<#perl>
channel, and talk to C<literal> or C<Apocal>.

=item * EFnet

You can connect to the server at 'irc.efnet.org', join the C<#perl>
channel, and talk to C<Hinrik> or C<Ap0cal>.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Hinrik E<Ouml>rn SigurE<eth>sson and Apocalypse

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
