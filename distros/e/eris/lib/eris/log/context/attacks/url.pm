package eris::log::context::attacks::url;
# ABSTRACT: Inspects URL's for common attack patterns

use Const::Fast;
use Moo;

use namespace::autoclean;
with qw(
    eris::role::context
);

our $VERSION = '0.004'; # VERSION


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


sub _build_priority { 100 }


sub _build_field { '_exists_' }


sub _build_matcher { qr/(?:_url$)|(?:^(?:resource|referer)$)/ }


sub sample_messages {
    my @msgs = split /\r?\n/, <<EOF;
EOF
    return @msgs;
}


sub contextualize_message {
    my ($self,$log) = @_;

    my $ctxt     = $log->context;
    my $re       = $self->matcher;
    my %add      = ();
    my $score    = 0;
    my $triggers = 0;

    foreach my $f ( keys %{ $ctxt } ) {
        next unless $f =~ /$re/o; # Optimize here, this will always be the same pattern
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
                # Total things up
                $score    += $attack{score} = $score * $multiplier;
                $triggers += $attack{triggers} = [ keys %uniq ];
            }
        }
        $add{$f} = \%attack if keys %attack;
    }

    if( keys %add ) {
        # Continue summing incase other things added scores.
        $score    += $ctxt->{attack_score}    if exists $ctxt->{attack_score};
        $triggers += $ctxt->{attack_triggers} if exists $ctxt->{attack_triggers};
        $log->add_context($self->name, {
            attacks         => \%add,
            attack_score    => $score,
            attack_triggers => $triggers,
        });
        $log->add_tags(qw(security));
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::attacks::url - Inspects URL's for common attack patterns

=head1 VERSION

version 0.004

=head1 SYNOPSIS

This context matches any field ending in '_url' and inspects the URL for common
attack patterns.  This is not sophisticated, but leverages the reconnaisance
stage of an attack in which attackers try unsophisticated things to look for
weak spots in your infrastructure.

It was built on the "least work for most reward" principle.  This context is
prone to false positives and false negatives, but works fast enough to be
inlined into the log processing pipeline.

=head1 ATTRIBUTES

=head2 priority

Defaults to 100, running after most other contexts so things can
end up in the right fields.

=head2 field

Defaults to '_exists_', meaning it's looking for the presence of certain
keys in the L<eris::log> context.

=head2 matcher

Defaults to matching the fields ending with '_url' or fields exact matching 'resource' or 'referer'

=head1 METHODS

=head2 contextualize_message

Takes an L<eris::log> instance, parses the fields 'resource' and 'referer' for
attack patterns.

Provides 3 top level keys to the context:

=over 2

=item B<attack_score>

The higher the number, the more likely an attack has been detected.  Takes the
HTTP response code into account if available.

=item B<attack_triggers>

This is the count of distinct tokens detected in the URL leading us to believe this
is an attack.

=item B<attacks>

This is a HashRef containing all the tokens and attack signatures tripped.

=back

Tags messages with 'security' if an attack string is detected.

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
