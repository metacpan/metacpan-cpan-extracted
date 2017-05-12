package Test::Mojo::Trim;

use strict;

use Mojo::DOM;
use Mojo::Base 'Test::Mojo';
use Mojo::Util 'trim';

# ABSTRACT: Trim strings for Test::Mojo
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1000';

sub trimmed_content_is {
    my $self = shift;
    my $value = squish(Mojo::DOM->new(shift)->to_string);
    my $desc = shift;

    my $dom = $self->tx->res->dom;
    my $got = squish($dom->to_string);
    my $error = defined $dom->at('#error') ? $dom->at('#error')->text : undef;
    chomp $error if $error;

    $value =~ s{> <}{><}g;
    $got =~ s{> <}{><}g;
    $desc ||= 'exact match for trimmed content';

    if(defined $error && length $error) {
        $desc .= (defined $error && length $error ? " (Error: $error)" : '');
        my $table = $dom->find('#context table')->each(sub {
            $desc .= $_->find('td')->map(sub { $_->text })->join(' ');
        });
        $got = '<see error>';
    }

    return $self->_test('is', $got, $value, $desc);
}

sub squish {
    my $string = trim @_;
    $string =~ s{\s+}{ }g;
    return $string;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Mojo::Trim - Trim strings for Test::Mojo



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-test-mojo-trim"><img src="https://api.travis-ci.org/Csson/p5-test-mojo-trim.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Test-Mojo-Trim-0.1000"><img src="https://badgedepot.code301.com/badge/kwalitee/Test-Mojo-Trim/0.1000" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Test-Mojo-Trim%200.1000"><img src="https://badgedepot.code301.com/badge/cpantesters/Test-Mojo-Trim/0.1000" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-68.4%-red.svg" alt="coverage 68.4%" />
</p>

=end html

=head1 VERSION

Version 0.1000, released 2016-07-22.

=head1 SYNOPSIS

    use Mojo::Base -strict;
    use Mojolicious::Lite;
    use Test::More;
    use Test::Mojo::Trim;

    my $test = Test::Mojo::Trim->new;

    get '/test_1';

    my $compared_to = qq{ <div><h1>Header</h1><p>A paragraph.</p></div> };

    $test->get_ok('/test_1')->status_is(200)->trimmed_content_is($compared_to);

    done_testing();

    __DATA__
    @@ the_test.html.ep
    <div>
        <h1>Header</h1>
        <p>A paragraph.</p>
    </div>

=head1 DESCRIPTION

Test::Mojo::Trim is an extension to Test::Mojo, that adds an additional string comparison function.

=head1 METHODS

L<Test::Mojo::Trim> inherits all methods from L<Test::Mojo> and implements the following new one.

=head2 trimmed_content_is

    $test->get_ok('/test')->trimmed_content_is('<html></html>');

Removes all whitespace between tags from the two strings that are compared.
That is, if a E<gt> and E<lt> is separated only by whitespace, that whitespace is removed.
Any leading or trailing whitespace is also removed.

=head1 SEE ALSO

=over 4

=item *

L<Test::Mojo>

=item *

L<Test::Mojo::Most>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-test-mojo-trim>

=head1 HOMEPAGE

L<https://metacpan.org/release/Test-Mojo-Trim>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
