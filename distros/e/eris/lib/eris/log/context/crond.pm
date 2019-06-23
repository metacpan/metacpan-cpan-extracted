package eris::log::context::crond;
# ABSTRACT: Parse crond messages to structured data

use Moo;
with qw(
    eris::role::context
);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


sub _build_matcher {
    [qw(crond cron CROND /usr/sbin/cron /USR/SBIN/CRON)]
}


sub sample_messages {
    my @msgs = split /\r?\n/, <<'EOF';
Nov 24 01:00:01 janus CROND[30472]: (root) CMD (/usr/lib64/sa/sa1 1 1)
Nov 24 01:01:01 janus CROND[30689]: (root) CMD (run-parts /etc/cron.hourly)
Nov 24 01:01:01 janus CROND[30690]: (root) CMD (/usr/local/bin/linux_basic_performance_data.sh)
EOF
    return @msgs;
}


sub contextualize_message {
    my ($self,$log) = @_;
    my $str = $log->context->{message};

    my %ctxt = ();
    if( $str =~ / CMD / ) {
        my @parts = map { s/(?:^\()|(?:\)$)//rg } split / CMD /, $str;
        $ctxt{src_user} = $parts[0];
        $ctxt{exe} = $parts[1];
        $ctxt{file} = (split /\s+/, $parts[1])[0];
        $ctxt{action} = 'execute';
    }

    $log->add_context($self->name,\%ctxt) if keys %ctxt;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::crond - Parse crond messages to structured data

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Parses the crond execution log file entries into structured data

=head1 ATTRIBUTES

=head2 matcher

Matches 'cron', 'CROND', '/usr/sbin/cron'

=head1 METHODS

=head2 contextualize_message

Parses the crond log messages specifying what was run into:

    src_user => User executing
    exe      => Full command as run by cron
    file     => Just the executeable without arguments

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
