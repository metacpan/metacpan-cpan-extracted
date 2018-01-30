use strict;
use warnings;
package WebService::Yamli;

# ABSTRACT: Perl wrapper for Yamli's Arabic translation service
our $VERSION = '0.004'; # VERSION

use Carp;
use LWP::UserAgent;
use URI;
use JSON;
use Carp;


=pod

=encoding utf8

=head1 NAME

WebService::Yamli - Perl wrapper for Yamli's Arabic transliteration service

=head1 SYNOPSIS

    use WebService::Yamli;

    # non-OO:
    my $tr = WebService::Yamli::tr('perl di 7aga la6eefa aslan');
    say $tr; # the whole sentence transliterated

    my @tr = WebService::Yamli::tr('perl');
    say "@tr"; # a list of candidates


=head1 DESCRIPTION

Franco-Arabic, aka Chat Arabic, Arabizy, is a transliteration of Arabic, commonly used on the internet. It restricts itself to the ASCII charset and substitutes numbers for the Arabic characters which have no equivalent in Latin.

This Module is an interface to L<Yamli.com>'s API.

=head1 IMPLEMENTATION

It seems there's no way to feed the Yamli API more than one word, so currently each word results in a HTTP request. Define $WebService::Yamli::HTTPS if HTTPS should be used instead.

=cut

our $HTTPS = 0;

=head1 METHODS AND ARGUMENTS

=over 4

=item tr($arg)

Transliterates argument. Returns transliterated string, except if input is a single word and subroutine is in list context, in that case it returns a candidate list

=cut

sub tr {
    my @words = split ' ', shift;
    my $s = $HTTPS ? 's' : '';

    my ($favorite, @candidates);
    for my $word (@words) {
        my $url = URI->new("http$s://api.yamli.com/transliterate.ashx");
        $url->query_form(
            word => $word,
            account_id => '000006',
            tool => 'api',
            prot => "http$s:",
            hostname => 'metacpan.org',
            path => '/pod/WebService::Yamli',
            build => '5515'
        );

        my $ua = LWP::UserAgent->new;
        $ua->agent(__PACKAGE__ . "/" . $WebService::Yamli::VERSION);

        my $response = $ua->get($url);
        croak "Error: ", $response->status_line unless $response->is_success;

        my $decoded = decode_json  $response->content;
        @candidates = split /\|/, $decoded->{r};

        # strip away the candidate score
        @candidates = map { s(/\d$)()r } @candidates;
        $favorite .= $candidates[0] . ' '; 
    }

    return @candidates if @words == 1 && wantarray;

    local $/ = ' ';
    chomp $favorite;
    return $favorite;
}





1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/WebService-Yamli>

=head1 SEE ALSO

L<http://yamli.com>

L<Encode::Arabic::Franco|Encode::Arabic::Franco>



=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
