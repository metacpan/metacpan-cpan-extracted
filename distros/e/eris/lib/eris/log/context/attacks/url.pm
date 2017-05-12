package eris::log::context::attacks::url;

use Const::Fast;
use Moo;

use namespace::autoclean;
with qw(
    eris::role::context
);

# Web Attack Detection
const my %WEIGHT => (
    sqli    => 3,
    xss     => 2,
);
my %_RAW = ();
# Not significant on their own
const my %NeedsMore => map { $_ => 1 } qw(select union update table sleep alter drop delete rand > \\), '&#';

# Generic Attack Strings
my @generic = map { quotemeta } qw(
    etc/passwd etc/shadow /* */
);
push @generic, q{\\\\(?!x)}, q{bin/[a-z]*sh}, q{\w+\.(?:php|exe|dll|bat|cgi)\b};
unshift @generic, q|\.\.(?:[\\\/]\.{0,2})+|;
$_RAW{generic} = join '|', @generic;

# SQL Injections
$_RAW{sqli} =  join '|', map { qr/(?<=[^a-z_\-=])$_(?![a-z_\-=])/ } map { quotemeta } qw(
    insert update delete drop alter select union table sleep concat rand
), 'group by';

# XSS Attempts
my @xss = map { qr/(?<=[^a-z_\-=])$_(?![a-z_\-=])/ } map { quotemeta } qw(
    script alert onerror onload
);
push @xss, map { quotemeta } qw(
    --> > ';
), '&#';
$_RAW{xss} = join('|', @xss);

my %_SUSPICIOUS = ();
foreach my $type (keys %_RAW) {
    $_SUSPICIOUS{$type} = qr/($_RAW{$type})/;
}
const %_SUSPICIOUS => %_SUSPICIOUS;

# Config this object
sub _build_priority { 100 }
sub _build_field { '_exists_' }
sub _build_matcher { [qw(resource referer)] }

sub sample_messages {
    my @msgs = split /\r?\n/, <<EOF;
EOF
    return @msgs;
}

sub contextualize_message {
    my ($self,$log) = @_;

    my $ctxt = $log->context;
    my %add = ();

    foreach my $f ( @{ $self->matcher } ) {
        next unless exists $ctxt->{$f};
        my %attack=();
        my $score = 0;
        # Normalize (Lower casing, Unescaping)
        my $url = $ctxt->{$f};
        $url =~ s/%([0-9a-f]{2})/chr(hex($1))/eg;
        $url=lc($url);
        my @allmatches = ();
        foreach my $type (keys %_SUSPICIOUS) {
            next unless my @matches = ($url =~ /$_SUSPICIOUS{$type}/g);
            my $weight = exists $WEIGHT{$type} ? $WEIGHT{$type} : 1;
            $score += $attack{"${type}_score"} = $weight * @matches;
            push @allmatches,@matches;
        }
        if( $score > 0 ) {
            my %uniq = map { lc($_) =>1 } @allmatches;
            my($t) = keys %uniq;
            if( keys(%uniq) == 1 && exists $NeedsMore{$t} ) {
                %attack=();
            }
            else {
                # Make sure alerting checks the server status
                my $multiplier = !exists $ctxt->{crit} ? 1 :
                                 $ctxt->{crit} >= 500 ? 10 :
                                 $ctxt->{crit} >= 400 ?  5 :
                                 $ctxt->{crit} >= 300 ?  2 : 1;

                $attack{score} = $score * $multiplier;
                $attack{triggers} = [ keys %uniq ],
            }
        }
        $add{$f} = \%attack if keys %attack;
    }

    $log->add_context($self->name,{ attacks => \%add }) if keys %add;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::attacks::url

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
