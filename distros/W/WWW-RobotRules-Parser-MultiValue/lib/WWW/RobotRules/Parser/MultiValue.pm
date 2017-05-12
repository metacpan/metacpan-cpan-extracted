package WWW::RobotRules::Parser::MultiValue;
use strict;
use warnings;
use 5.014;

our $VERSION = '0.02';

# core
use Scalar::Util qw(blessed);

# cpan
use URI;
use Text::Glob qw(match_glob);
use Hash::MultiValue;
use Class::Accessor::Lite (
    new => 1,
    ro => [qw(agent ignore_default)],
);

use constant {
    WILDCARD => 'wc',
    ME       => 'me',
    TRANSLATOR => {
        allow          => '_translate_path_pattern',
        disallow       => '_translate_path_pattern',
        'crawl-delay'  => '_translate_delay',
        'request-rate' => '_translate_rate',
    },
};

sub _uri {
    my ($uri) = @_;
    $uri = URI->new($uri.q()) unless blessed($uri) && $uri->isa('URI');
    return unless $uri->can('host') && $uri->can('port');
    return $uri;
}

sub _domain {
    my ($uri) = @_;
    return sprintf '%s:%d', $uri->host, $uri->port;
}

sub _rules {
    my ($self, $domain) = @_;
    return $self->{rules}->{$domain} //= Hash::MultiValue->new;
}

sub rules_for {
    my ($self, $uri) = @_;
    $uri = _uri($uri)
        or return Hash::MultiValue->new;
    my $path_query = $uri->path_query;
    my $domain = _domain($uri);
    return $self->_rules($domain);
}

sub parse {
    my ($self, $robots_txt_uri, $txt) = @_;
    $robots_txt_uri = _uri($robots_txt_uri)
        or return;
    my $domain = _domain($robots_txt_uri);

    my $ua = WILDCARD;
    my $anon_rules = Hash::MultiValue->new;

    $txt = ($txt//'') =~ s|\r\n|\n|gr;
    for my $line (split /[\r\n]/, $txt) {
        $line =~ s/(?:^\s*|\s*$|\s*[#].*$)//g;
        next if $line =~ /^\s*$/; # skip empty line

        if ($line =~ /^User-Agent\s*:\s*(.*)$/i) {
            $ua = $self->match_ua($1);
        } else {
            next unless $ua; # skip directives for other UA

            if ($line =~ /^([^:]+?)\s*:\s*(.*)$/) {
                my ($rule, $value) = (lc $1, $2);
                if (my $method = TRANSLATOR->{$rule}) {
                    ($rule, $value) = $self->$method(
                        $rule, $value, $robots_txt_uri,
                    );
                }
                next unless $rule;

                if ($ua eq ME) {
                    $self->_rules($domain)->add($rule => $value);
                } else {
                    $anon_rules->add($rule => $value);
                }
            }
        }
    }

    unless ($self->ignore_default) {
        # Add rules for default UA as a lower precedence
        $self->_rules($domain)->add($_ => $anon_rules->get_all($_))
            for $anon_rules->keys;
    }

    return $self;
}

sub match_ua {
    my ($self, $pattern) = @_;
    return WILDCARD if $pattern eq '*';
    return ME if index(lc $self->_short_agent, lc($pattern)) >= 0;
    return undef;
}

sub _match_path ($$) {
    my ($str, $pattern) = @_;
    local $Text::Glob::strict_leading_dot = 0;
    local $Text::Glob::strict_wildcard_slash = 0;
    return match_glob($pattern.'*', $str);
}

sub allows {
    my ($self, $uri) = @_;
    $uri = _uri($uri)
        or return;
    my $path_query = $uri->path_query;
    my $domain = _domain($uri);
    for my $pattern ($self->_rules($domain)->get_all('allow')) {
        return 1 if _match_path $path_query, $pattern;
    }
    for my $pattern ($self->_rules($domain)->get_all('disallow')) {
        return 0 if _match_path $path_query, $pattern;
    }
    return 1;
}

sub delay_for {
    my ($self, $uri, $base) = @_;
    my ($delay) = $self->rules_for($uri)->get_all('crawl-delay');
    $delay *= ( $base || 1 ) if defined $delay;
    return $delay;
}

sub _short_agent {
    my ($self) = @_;
    my $name = $self->agent;
    $name = $1 if $name =~ m!^(\S+)!; # first word
    $name =~ s!/.*$!!; # no version
    return $name;
}

sub _translate_path_pattern {
    my ($self, $key, $value, $base_uri) = @_;

    my $ignore;
    eval {
        my $uri = URI->new_abs($value, $base_uri);
        $ignore++ unless $uri->scheme eq $base_uri->scheme;
        $ignore++ unless lc($uri->host) eq lc($base_uri->host);
        $ignore++ unless $uri->port eq $base_uri->port;
    };
    return () if $@;
    return () if $ignore;

    return ($key, $value);
}

sub _translate_delay { # into delay in milliseconds
    my ($self, $key, $value) = @_;
    return () unless $value =~ qr!\A[0-9.]+\z!;
    return ('crawl-delay', $value);
}

sub _translate_rate { # into delay in milliseconds
    my ($self, $key, $value) = @_;
    return () unless $value =~ qr!\A([0-9.]+)\s*/\s*([0-9.]+)\z!;
    return () unless $1+0;
    return ('crawl-delay', $2 / $1);
}

1;
__END__

=head1 NAME

WWW::RobotRules::Parser::MultiValue - Parse robots.txt

=head1 SYNOPSIS

    use WWW::RobotRules::Parser::MultiValue;
    use LWP::Simple qw(get);

    my $url = 'http://example.com/robots.txt';
    my $robots_txt = get $url;

    my $rules = WWW::RobotRules::Parser::MultiValue->new(
        agent => 'TestBot/1.0',
    );
    $rules->parse($url, $robots_txt);

    if ($rules->allows('http://example.com/some/path')) {
        my $delay = $rules->delay_for('http://example.com/');
        sleep $delay;
        ...
    }

    my $hash = $rules->rules_for('http://example.com/');
    my @list_of_allowed_paths = $hash->get_all('allow');
    my @list_of_custom_rule_value = $hash->get_all('some-rule');

=head1 DESCRIPTION

C<WWW::RobotRules::Parser::MultiValue> is a parser for C<robots.txt>.

Parsed rules for the specified user agent is stored as a
L<Hash::MultiValue>, where the key is a lower case rule name.

C<Request-rate> rule is handled specially.  It is normalized to
C<Crawl-delay> rule.

=head1 METHODS

=over 4

=item new

    $rules = WWW::RobotRules::Parser::MultiValue->new(
        aget => $user_agent
    );
    $rules = WWW::RobotRules::Parser::MultiValue->new(
        aget => $user_agent,
        ignore_default => 1,
    );

Creates a new object to handle rules in C<robots.txt>.  The object
parses rules match with C<$user_agent>.  The rules of C<User-agent: *>
always match and have a lower precedence than the rules explicitly
matched with C<$user_agent>.  If C<ignore_default> option is
specified, rules of C<User-agent: *> are simply ignored.

=item parse

    $rules->parse($uri, $text);

Parses a text content C<$text> whose URI is C<$uri>.

=item match_ua

    $rules->match_ua($pattern);

Test if the user agent matches with C<$pattern>.

=item rules_for

    $hash = $rules->rules_for($uri);

Returns a C<Hash::MultiValue>, which describes the rules of the domain
of C<$uri>.

=item allows

    $test = $rules->allows($uri);

Tests if the user agent is allowed to visit C<$uri>.  If there is
'Allow' rule for the path of C<$uri>, then the C<$uri> is allowed to
visit.  If there is 'Disallow' rule for the path of C<$uri>, then the
C<$uri> is not allowed to visit.  Otherwise, the C<$uri> is allowed to
visit.

=item delay_for

    $delay = $rules->delay_for($uri);
    $delay_in_milliseconds = $rules->delay_for($uri, 1000);

Calculate a crawl delay for the specified C<$uri>.  The value is
determined by 'Crawl-delay' rule or 'Request-rate' rule.  The second
argument specifies the base of the return value.

=back

=head1 SEE ALSO

L<Hash::MultiValue>

=head1 LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut
