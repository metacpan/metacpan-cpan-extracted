package Test::Smoke::PostQueue;
use warnings;
use strict;

our $VERSION = '0.001';

use base 'Test::Smoke::ObjectBase';

use Carp;
use Cwd qw< abs_path >;
use Fcntl qw< :flock SEEK_SET >;
use File::Spec::Functions qw< catfile file_name_is_absolute >;
use Test::Smoke::LogMixin;

=head1 NAME

Test::Smoke::PostQueue - Queue mechanism for re-posting reports.

=head1 SYNOPSIS

    use Test::Smoke::PostQueue;
    my $queue = Test::Smoke::PostQueue->new(
        qfile  => $qfile,
        adir   => $adir,
        poster => $poster
    );

    $queue->add($patch);

    $queue->handle_queue();

=head1 DESCRIPTION

This is implemented as a singleton.

It can only work if archiving is true.

=cut

my $_singleton;
my %CONFIG = (
    df_qfile  => undef,
    df_adir   => undef,
    df_poster => undef,
    df_v      => 0,

    general_options => [qw< qfile adir poster v >],
);

=head2 Test::Smoke::PostQueue->new(%arguments)

Returns an instantiated object, if it was already created, return that one.

=head3 Arguments

Named, list:

=over

=item B<qfile>

The file we keep the queue in (one patchlevel per line)

=item B<adir>

The archive directory to get the report (jsn) from.

=item B<poster>

This must be an instance of L<Test::Smoke::Poster> with C<ddir> set to C<adir>.

=item B<v>

Verbosity.

=back

=cut

sub new {
    my $class = shift;

    return $_singleton if defined($_singleton);

    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } @{ $CONFIG{general_options} };
    for my $fld (qw< qfile adir >) {
        die __PACKAGE__ . " must have $fld as defined attribute in new()!\n"
            if !defined($fields{$fld});
    }
    die __PACKAGE__ . " must have $_ as a Test::Smoke::Poster in new!\n"
        unless defined($fields{poster})
            && UNIVERSAL::isa($fields{poster}, 'Test::Smoke::Poster::Base');

    _make_absolute($_) for @fields{qw< qfile adir >};

    $fields{ "_$_" } = delete($fields{$_}) for qw< qfile adir poster v >;
    $_singleton = bless(\%fields, $class);
    return $_singleton;
}

=head2 $queue->add($patchlevel)

Adds an item to the queue-file.

=cut

sub add {
    my $self = shift;
    my ($patchlevel) = @_;

    if (! -e $self->qfile) {
        open(my $chk, '>', $self->qfile) or confess("Cannot create(@{[$self->qfile]}: $!");
    }
    open(my $fh, '+<', $self->qfile) or do {
        $self->log_warn("Cannot open(@{[$self->qfile]}, r/w): $!");
        return 0;
    };

    flock($fh, LOCK_EX) or confess("Cannot flock(@{[$self->qfile]}): $!");
    chomp(my @q = <$fh>);
    seek($fh, 0, SEEK_SET);
    truncate($fh, 0);
    my %q = map { ($_ => undef) } @q;
    $q{$patchlevel}++;
    print {$fh} "$_\n" for keys %q;
    flock($fh, LOCK_UN) or confess("Cannot unflock(@{[$self->qfile]}: $!");
    close($fh);
    return 1;
}

=head2 $queue->handle()

This reads the queue-file and tries to post every report it can find in the
archive.

=cut

sub handle {
    my $self = shift;
    open(my $fh, '+<', $self->qfile) or do {
        $self->log_warn("Cannot read queuefile: $!");
        return;
    };

    flock($fh, LOCK_EX) or confess("Cannot flock(@{[$self->qfile]}): $!");
    chomp(my @q = <$fh>);
    my @left;
    my $orig_ddir = $self->poster->ddir;
    $self->poster->ddir($self->adir);
    my $orig_jsnfile = $self->poster->jsnfile;
    for my $patch (@q) {
        my $jsnfile = sprintf("jsn%s.jsn", $patch);
        $self->poster->jsnfile($jsnfile);

        my $id;
        eval { $id = $self->poster->post($jsnfile); 1; } or push @left, $patch;
        $self->log_warn("Posted $patch from queue: report_id = $id") if $id;
    }
    $self->poster->ddir($orig_ddir);
    $self->poster->jsnfile($orig_jsnfile);

    seek($fh, 0, SEEK_SET);
    truncate($fh, 0);
    print {$fh} "$_\n" for @left;
    flock($fh, LOCK_UN) or confess("Cannot unflock(@{[$self->qfile]}: $!");
    close($fh);
    return 1;
}

=head2 $queue->purge

Removes all entries that do not exist in C<adir>.

=cut

sub purge {
    my $self = shift;
    open(my $fh, '+<', $self->qfile) or do {
        $self->log_warn("Cannot read queuefile: $!");
        return;
    };

    flock($fh, LOCK_EX) or confess("Cannot flock(@{[$self->qfile]}): $!");
    chomp(my @q = <$fh>);
    my @left;
    for my $patch (@q) {
        my $jsnfile = sprintf("jsn%s.jsn", $patch);
        push(@left, $patch) if -e catfile($self->adir, $jsnfile);
    }
    seek($fh, 0, SEEK_SET);
    truncate($fh, 0);
    print {$fh} "$_\n" for @left;
    flock($fh, LOCK_UN) or confess("Cannot unflock(@{[$self->qfile]}: $!");
    close($fh);
    return 1;
}

# !NASTY, changes the argument
sub _make_absolute {
    return if file_name_is_absolute($_[0]);
    $_[0] = abs_path($_[0]);
}

1;

=head1 COPYRIGHT

E<copy> 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

See L<AUTHORS> for contributers.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
