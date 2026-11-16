use v5.36;

package Text::Redact::Secrets::Rules::Dist;

# Rules of the distribution's own, for secrets gitleaks has no rule for,
# written by hand, as roadmap 2026-0001's D12 says. Each is given as
# Text::Redact::Secrets::Rules::Gitleaks gives gitleaks', and run as they
# are, after them, with gitleaks' global allowlists.

# The rules, each a hash as Text::Redact::Secrets::Rules::Gitleaks gives
# them.
sub rules () {
    return [{

        # A password in a URL's user information, as in
        # postgres://user:password@host/db, or redis://:password@host,
        # whatever the scheme: the user may be empty, the password
        # can't, and ends at the @.
        id       => 'url-userinfo-password',
        regex    => '\b[a-zA-Z][a-zA-Z0-9+.-]*://[^\s/?#@:]*:([^\s/?#@]+)@',
        keywords => ['://'],
    }];
}

1;

__END__

=encoding utf8

=for stopwords gitleaks gitleaks' allowlist allowlists regexes LICENSE-gitleaks

=head1 NAME

Text::Redact::Secrets::Rules::Dist - rules of Text::Redact::Secrets' own

=head1 DESCRIPTION

The rules Text::Redact::Secrets finds secrets by, beside gitleaks', for
secrets gitleaks has no rule for. Each is written as gitleaks writes its
rules, and run as they are, after them, with gitleaks' global
allowlists. Their ids are Text::Redact::Secrets' own:

=over

=item C<url-userinfo-password>

A password in a URL's user information, as in
C<postgres://user:password@host/db>, whatever the scheme. gitleaks
won't add one: its maintainer said in 2026 that no more rules would be
added, in L<its issue 2089|https://github.com/gitleaks/gitleaks/issues/2089>.

=back

=head1 FUNCTIONS

=head2 rules

A reference to a list of the rules, each a hash of its C<id>, its
C<regex>, and its C<keywords>, as
L<Text::Redact::Secrets::Rules::Gitleaks/rules> gives gitleaks'.

=head1 LICENSE

Copyright (c) 2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
