package eris::log::context::static;
# ABSTRACT: Add static keys/values to every message

use Moo;
use Types::Standard qw(HashRef Maybe);
use namespace::autoclean;
with qw(
    eris::role::context
);

our $VERSION = '0.008'; # VERSION

our $SuppressWarnings = 1;


sub _build_field   { '*' }


sub _build_matcher { '*' }


has 'fields' => (
    is  => 'rw',
    isa => HashRef,
    default => sub { 'disable loading' },
);


sub sample_messages {
    my ($self) = @_;
    #$self->fields({ subject => 'testing', source => 'testing' });
    my @msgs = split /\r?\n/, <<'EOF';
Sep 10 19:59:05 ether sudo:     brad : TTY=pts/5 ; PWD=/home/brad ; USER=root ; COMMAND=/bin/grep -i sudo /var/log/secure
EOF
    return @msgs;
}


sub contextualize_message {
    my ($self,$log) = @_;
    # Simply add the fields
    $log->add_context(static => $self->fields)
        if $self->fields;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::static - Add static keys/values to every message

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This context exists to statically add key/value pairs to every message.

=head1 ATTRIBUTES

=head2 field

Set to C<*>

=head2 matcher

Set to C<*>

This combo causes this to match every message.

=head2 fields

A HashRef of keys/values to add to every message. To configure:

    ---
    contexts:
      config:
        static:
          fields:
            dc: DCA1
            env: prod

=head1 METHODS

=head2 contextualize_message

If configured, this context just takes the fields specified in it's config and
adds those fields to every message.

=for Pod::Coverage sample_messages

=head1 SEE ALSO

L<eris::log::contextualizer>, L<eris::role::context>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
