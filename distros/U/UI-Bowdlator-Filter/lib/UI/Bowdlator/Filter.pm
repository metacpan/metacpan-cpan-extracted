use strict;
use warnings;
package UI::Bowdlator::Filter;
use IO::Socket::UNIX;

# ABSTRACT: Provides convenience function for specifing input Filters to Bowdlator
our $VERSION = '0.002'; # VERSION

use Carp;
my $DEFAULT_SOCK = '/usr/local/var/run/bowdlator.sock';

=pod

=head1 NAME

UI::Bowdlator::Filter - Helper for specifying input filters to Bowdlator


=head1 SYNOPSIS

    # maps all typed characters to uppercase
    use UI::Bowdlator::Filter;

    # connect to Bowdlator server
    my $bowdlator = UI::Bowdlator::Filter->new()
        or die "Bowdlator server not online\n";

    my $composed = '';
    while ($bowdlator->getKey(handle_backspace => \$composed)) {

        if (/^[^[:graph:]]/a) { # non graphical character ends composition
            $bowdlator->commit(\$composed);
            next;
        }

        $composed .= uc;

        $bowdlator->suggest($composed);
    }

=head1 DESCRIPTION

Makes writing filters for Bowdlator (L<http://github.com/a3f/Bowdlator>) easier.


=head1 METHODS AND ARGUMENTS

=over 4

=item new([$sock])

Connects to a running Bowdlator C<AF_UNIX> socket. Returns C<undef> on connection failure.
Default socket is C</usr/local/var/run/bowdlator.sock>. Optionally, an actual socket or a path to one can be specified.

=cut

sub new {
	my $type = shift;
    my $sock = shift || $DEFAULT_SOCK;
    $sock = IO::Socket::UNIX->new(
            Type => SOCK_STREAM,
            Peer => $sock,
    ) if ref($sock) ne 'IO::Socket::UNIX';
    return undef unless $sock;

    binmode $sock, ":encoding(UTF-8)";
    my $self->{sock} = $sock;
	bless $self, $type;
	return $self;
}

=item getKey([keep_nul => 0, buffer_size => 160, handle_backspace => undef])

Blocks till the user types a Key while Bowdlator is selected. Accepts following optional arguments:

=over 4

=item handle_backspace

User code can offload backspace handling to the module. On backspace receipt, the module will discard the composed string's last character, and chop and return the one before it, so it can be rehandled. If the buffer is empty, a backspace (C<\b>) is returned.

=item keep_nul

Bowdlator sends NUL-terminated strings. The module strips them unless instructed otherwise.

=item buffer_size

The recv buffer size. This shouldn't need changing. Default is 160.


=back

C<undef> is returned on socket error.

=cut

sub getKey {
    my $self = shift;
    my %opts = (
        keep_nul => 0,
        buffer_size => 160,
        handle_backspace => undef,

        @_
    );

    my $data;
    defined $self->{sock}->recv($data, $opts{buffer_size}) or return $_ = undef;
    chop $data if !$opts{keep_nul}; # strips NUL, so client doesn't have to
    $_ = $data;
    
    # handle backspace
    if (defined $opts{handle_backspace} && /^[\b]/) {
        chop ${$opts{handle_backspace}};
        $_ = chop ${$opts{handle_backspace}};
        $_ = $_ || "\b"; # return backspace if deleting beyond buffer
    }

    return $_;
}

=item suggest($display, @candidates)

Sends off a suggestion to C<$display> and a list of C<@candidates> to choose from. (Candidates list support not immplemented yet).

=cut

sub suggest {
	my $self = shift;
    my ($displayed, @candidates) = @_;

    $self->{sock}->write($displayed);
}

=item commit(\$commit)

Sends off the final string to C<$commit>. If C<$commit> is a C<ref>, it will be cleared.

=cut

sub commit {
	my $self = shift;
    my $commit =  $_[0] || '';
    $commit = $$commit, ${$_[0]} = '' if ref $commit;

	$self->{sock}->write("$commit\0\4\0");
}

1;

__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/UI-Bowdlator-Filter>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
