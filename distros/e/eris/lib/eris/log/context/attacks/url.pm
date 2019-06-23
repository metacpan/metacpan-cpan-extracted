package eris::log::context::attacks::url;
# ABSTRACT: Inspects URL's for common attack patterns

use JSON::MaybeXS;
use Const::Fast;
use Moo;

use namespace::autoclean;
with qw(
    eris::role::context
);

our $VERSION = '0.008'; # VERSION


my %SUSPICIOUS = ();
# Not significant on their own
const my %NeedsMore => map { $_ => 1 } qw(select union update table sleep alter alert drop delete rand > \\), '&#';


sub BUILD {

    # Initialize things to prevent running code at compile time
    #
    # Generic Attack Strings
    my @Generic = map { quotemeta } qw(
        etc/passwd etc/shadow /* */
    );
    push @Generic, q{\\\\(?!x)}, q{bin/[a-z]*sh}, q{\w+\.(?:exe|dll|bat|cgi)\b};
    unshift @Generic, q|\.\.(?:[\\\/]\.{0,2})+|;
    $SUSPICIOUS{generic} = join '|', @Generic;

    # SQL Injections
    my @SQLI = map { qr/(?<=[^a-z_\-=])$_(?![a-z_\-=])/ } map { quotemeta } qw(
        insert update delete drop alter select union table sleep rand char chr
    );
    push @SQLI, qr/or\s+1=1\s*;\s*--/;
    $SUSPICIOUS{sqli} =  join '|', @SQLI;

    # XSS Attempts
    my @XSS = map { qr/(?<=[^a-z_\-=])$_(?![a-z_\-=])/ } map { quotemeta } qw(
        script alert onerror onload
    );
    push @XSS, map { quotemeta } qw(
        --> > ';
    ), '&#';
    $SUSPICIOUS{xss} = join('|', @XSS);

    const %SUSPICIOUS => %SUSPICIOUS;

}


sub _build_priority { 100 }


sub _build_field { '_exists_' }


sub _build_matcher { qr/(?:_ur[li]$)|(?:^resource$)/ }


sub sample_messages {
    my @msgs = map { encode_json($_) } (
        { resource => "https://www.example.com/?t='%20OR%201=1;--" },
        { resource => "https://www.example.com/../../../etc/passwd" },
        { resource => "https://www.example.com/?q='><script>alert(1);</script>" },
    );
    return @msgs;
}


sub contextualize_message {
    my ($self,$log) = @_;

    my $ctxt   = $log->context;
    my $re     = $self->matcher;
    my %add    = ();
    my $score  = 0;
    my %tokens = ();
    my %tags   = ();

    foreach my $f ( keys %{ $ctxt } ) {
        next unless $f =~ /$re/o; # Optimize here, this will always be the same pattern

        # Normalize (Lower casing, Unescaping)
        my $url = lc $ctxt->{$f} =~ s/%([0-9a-f]{2})/chr(hex($1))/reg;
        my %attack  = ();
        my @badness = ();

        # We need to call each of these one at a time.  Since our regexes live
        # in a hash, we can only optimize if they won't change.
        if( my @sqli = ($url =~ /$SUSPICIOUS{sqli}/go ) ) {
            push @badness, @sqli;
            $attack{tags} = 'sqli';
            $tags{sqli}   = 1;
        }
        elsif( my @xss = ($url =~ /$SUSPICIOUS{xss}/go ) ) {
            push @badness, @xss;
            $attack{tags} = 'xss';
            $tags{xss}    = 1;
        }
        elsif( my @generic = ($url =~ /$SUSPICIOUS{generic}/go ) ) {
            push @badness, @generic;
            $attack{tags}  = 'generic';
            $tags{generic} = 1;
        }
        next unless @badness;

        # Extract the unique tokens for this field and globally
        my %uniq;
        foreach my $token (@badness) {
            $uniq{$token} = $tokens{$token} = 1;
        }
        # Check that we're not squatting on a single english word
        my($t) = keys %uniq;
        if( keys(%uniq) == 1 && exists $NeedsMore{$t} ) {
            next;
        }
        # Store the Score and Tokens
        $score += $attack{score} = @badness;
        $attack{tokens} = [ sort keys %uniq ];
        $add{$f} = \%attack;
    }

    if( keys %add ) {
        # Continue summing incase other things added scores.
        $log->add_context($self->name, {
            attacks       => \%add,
            attack_score  => $score,
            attack_tokens => [ sort keys %tokens ],
            attack_type   => [ sort keys %tags ],
        });
        $tags{security} = 1;
        $log->add_tags(keys %tags);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::attacks::url - Inspects URL's for common attack patterns

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This context matches any field ending in '_url' and inspects the URL for common
attack patterns.  This is not sophisticated, but leverages the reconnaissance
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

Defaults to matching the fields ending with '_url', '_uri', or fields exact matching 'resource'.

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

=for Pod::Coverage BUILD

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
