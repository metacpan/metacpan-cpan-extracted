package eris::log::context::sudo;
# ABSTRACT: Parses the sudo key=value pairs into structured documents

use Const::Fast;
use Moo;
with qw(
    eris::role::context
);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


sub sample_messages {
    my @msgs = split /\r?\n/, <<'EOF';
Sep 10 19:59:02 ether sudo:     brad : TTY=pts/5 ; PWD=/home/brad ; USER=root ; COMMAND=/bin/grep -i sudo /var/log/messages
Sep 10 19:59:05 ether sudo:     brad : TTY=pts/5 ; PWD=/home/brad ; USER=root ; COMMAND=/bin/grep -i sudo /var/log/secure
EOF
    return @msgs;
}


const my %MAP => (
    TTY     => 'dev',
    COMMAND => 'exe',
    PWD     => 'location',
    USER    => 'dst_user',
);

sub contextualize_message {
    my ($self,$log) = @_;
    my $c = $log->context;
    my $sdata = $c->{sdata};
    my $str   = $c->{message};

    my %ctxt = ();

    my ($user,$variables) = split ' : ', $str, 2;
    foreach my $k (sort keys %MAP) {
        if( exists $sdata->{$k} ) {
            $ctxt{$MAP{$k}} = $sdata->{$k};
        }
    }
    if( exists $ctxt{exe} ) {
        $ctxt{file} = (split /\s+/, $ctxt{exe})[0];
        $ctxt{action} = 'execute';
    }
    $ctxt{src_user} = $user if $user;

    $log->add_context($self->name,\%ctxt) if keys %ctxt;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::sudo - Parses the sudo key=value pairs into structured documents

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Translates the sudo syslog lines containing "key=value" to structured documents.

=head1 METHODS

=head2 contextualize_message

Transforms the sudo syslog messages into structured data.

    dev      => TTY
    exe      => COMMAND
    location => PWD
    dst_user => USER
    src_user => from the syslog header
    action   => literal string 'execute'
    file     => extracts just the executeable from the 'exe' parameter

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
