package Text::QueryString;
use strict;
use XSLoader;
our $VERSION;
BEGIN {
    $VERSION = '0.03';
    if ($ENV{PERL_TEXT_QUERYSTRING_BACKEND} eq 'PP') {
        require Text::QueryString::PP;
        no strict 'refs';
        *parse = \&Text::QueryString::PP::parse;
    } else {
        eval {
            XSLoader::load(__PACKAGE__, $VERSION);
            require constant;
            constant->import(BACKEND => "XS");
        };
        if ($@) {
            warn "Failed to require Text::QueryString XS backend: $@";
            require Text::QueryString::PP;
            no strict 'refs';
            *parse = \&Text::QueryString::PP::parse;
        }
    }
}

sub new { bless {}, shift }

1;

__END__

=head1 NAME

Text::QueryString - Fast QueryString Parser

=head1 SYNOPSIS

    use Text::QueryString;

    my $tqs = Text::QueryString->new;
    my @query;

    @query = $tqs->parse("foo=bar&bar=baz");
    @query = $tqs->parse("foo=bar;bar=baz");
    @query = $tqs->parse("foo"); # foo => ""

=head1 DISCLAIMER

When I wrote this module, I didn't know about L<URL::Encode>, which apparently
does the same thing I wanted to do via C<url_param_flat()> method. Upon closer
examination, L<URL::Encode> seems to be much faster, so if you came here
searching for "query string" or something, then go look at that module instead.

=head1 DESCRIPTION

WARNING: Still in ALPHA quality! Use at your own risk!

Text::QueryString is for when you need that speed to parse those annoying query strings that they send to your webapp.

The reason this came to be is that we have encountered cases where we got hit
by a relatively big performance degradation when moving from Apache based
solution to Perl based solution, and taking the run time profile lead us to
believe that URI / query parameter parsing was taking relative long time.

Normally just adding servers may be good enough, but since we were replacing
old code to new code in hopes that things would get better, we just...
expected better.

This performance degradation while understandable because obviously C is much
faster when working with simple string like query strings, really made us feel
sad, so much so that it made me want to just speed up parsing query parameters.

So here's Text::QueryString. By default the XS version is built and loaded.
It will parse a given string, and run URI decoding on those values
(URI decoding was completely stolen from Dan Kogai's URI::Escape::XS), and
all is good.

It's your reponsibility to feed the results to whatever framework you're using. 
As an example: with C<Plack::Request>, you might monkey patch the 
C<query_parameter()> method like so:

    use Plack::Request;
    use Text::QueryString;
    no strict 'refs';
    my $tqs = Text::QueryString->new;
    *Plack::Request::query_parameter = sub {
        my $self    = shift;
        my $env     = $self->env;
        my $query   = $env->{'plack.request.query'};
        if ($query) {
            return $query;
        }
        $env->{'plack.request.query'} = Hash::MultiValue->new($tqs->parse($env->{QUERY_STRING}));
    };

There's a fallback pure-perl implementation in Text::QueryString::PP, but
this is basically just there to provide a fallback when things just don't work.
The code in Text::QueryString::PP was taken from URI::_query and slightly
modified.

=head1 BENCHMARK

See tools/benchmark.pl for details:

    Building Text-QueryString
          Rate   pp   xs
    pp 13964/s   -- -76%
    xs 59077/s 323%   --

=head1 THANKS TO

Dan Kogai - For URI::Escape::XS

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=cut