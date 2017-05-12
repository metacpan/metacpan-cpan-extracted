package True::Truth;

use 5.010;
use Cache::KyotoTycoon;
use Any::Moose;
use MIME::Base64 qw(encode_base64 decode_base64);
use Storable qw/nfreeze thaw/;
use Data::Dump qw/dump/;

# ABSTRACT: merge multiple versions of truth into one
#
our $VERSION = '1.1'; # VERSION

has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 },
    lazy    => 1,
);

has 'kt_server' => (
    is      => 'rw',
    isa     => 'Str',
    default => '127.0.0.1',
);

has 'kt_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 1978 },
);

has 'kt_db' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 0 },
);

has 'kt_timeout' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 5 },
);

has 'kt' => (
    is      => 'rw',
    isa     => 'Cache::KyotoTycoon',
    builder => '_connect_kt',
    lazy    => 1,
);

has 'expire' => (
    is      => 'rw',
    isa     => 'Int',
    default => '3600',
);


sub add_true_truth {
    my ($self, $key, $truth) = @_;

    return int $self->_add($key, $truth);
}


sub add_pending_truth {
    my ($self, $key, $truth) = @_;

    return unless ref $truth eq 'HASH';

    foreach my $ky (keys %$truth) {
        if (ref($truth->{$ky}) eq 'HASH') {
            $truth->{$ky}->{_locked} = 1;
        }
        else {
            $truth->{_locked} = 1;
        }
    }
    return int $self->_add($key, $truth);
}


sub persist_pending_truth {
    my ($self, $key, $index) = @_;

    my $truth = $self->_get($key, $index);

    return unless ref $truth eq 'HASH';

    foreach my $k (keys %$truth) {
        if (ref($truth->{$k}) eq 'HASH') {
            delete $truth->{$k}->{_locked};
        }
        else {
            delete $truth->{_locked};
        }
    }
    $self->_add($key, $truth, $index);
    return;
}


sub remove_pending_truth {
    my ($self, $key, $index) = @_;

    $self->_del($key, $index);
    return;
}


sub get_true_truth {
    my ($self, $key) = @_;

    my $all_truth = $self->_get($key);
    my $truth     = merge(@$all_truth);
    return $truth;
}


# This was stolen from Catalyst::Utils... thanks guys!
sub merge (@);

sub merge (@) {
    shift
        unless ref $_[0]
        ; # Take care of the case we're called like Hash::Merge::Simple->merge(...)
    my ($left, @right) = @_;

    return $left unless @right;

    return merge($left, merge(@right)) if @right > 1;

    my ($right) = @right;

    my %merge = %$left;

    for my $key (keys %$right) {

        my ($hr, $hl) = map { ref $_->{$key} eq 'HASH' } $right, $left;

        if ($hr and $hl) {
            $merge{$key} = merge($left->{$key}, $right->{$key});
        }
        else {
            $merge{$key} = $right->{$key};
        }
    }

    return \%merge;
}

#### internal stuff ####

sub _add {
    my ($self, $key, $val, $index) = @_;

    my $idx;
    if ($index) {
        $idx = $index;
    }
    else {
        $idx = scalar keys $self->kt->match_prefix("$key.");
    }
    $self->kt->set("$key.$idx", encode_base64(nfreeze($val)), $self->expire);
    return $idx;
}

sub _get {
    my ($self, $key, $index) = @_;

    if ($index) {
        my $val = $self->kt->get("$key.$index");
        return thaw(decode_base64($val))
            if $val;
    }
    else {
        my $data = $self->kt->match_prefix($key);
        my @res;
        foreach my $val (sort keys %{$data}) {
            push(@res, thaw(decode_base64($self->kt->get($val))));
        }
        return \@res;
    }
    return;
}

sub _del {
    my ($self, $key, $index) = @_;

    if ($index) {
        $self->kt->remove("$key.$index");
    }
    else {
        my $data = $self->kt->match_prefix($key);
        foreach my $val (sort keys %{$data}) {
            $self->kt->remove($val);
        }
    }
    return;
}

sub _connect_kt {
    my ($self) = @_;
    return Cache::KyotoTycoon->new(
        host    => $self->kt_server,
        port    => $self->kt_port,
        timeout => $self->kt_timeout,
        db      => $self->kt_db,
    );
}


1;    # This is the end of True::Truth

__END__

=pod

=encoding UTF-8

=head1 NAME

True::Truth - merge multiple versions of truth into one

=head1 VERSION

version 1.1

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use True::Truth;

    my $foo = True::Truth->new();
    ...

=head1 NAME

True::Truth - The one True::Truth!

=head1 VERSION

# VERSION

=head1 FUNCTIONS

=head2 add_true_truth

needs docs

=head2 add_pending_truth

needs docs

=head2 persist_pending_truth

needs docs

=head2 remove_pending_truth

needs docs

=head2 get_true_truth

needs docs

=head2 merge

needs docs

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-true-truth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=True-Truth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc True::Truth

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=True-Truth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/True-Truth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/True-Truth>

=item * Search CPAN

L<http://search.cpan.org/dist/True-Truth/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Lenz Gschwendtner <mail@norbu09.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by ideegeo Group Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
