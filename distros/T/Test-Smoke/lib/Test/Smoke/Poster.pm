package Test::Smoke::Poster;
use warnings;
use strict;
use Carp;

our $VERSION = '0.001';

use Cwd qw/:DEFAULT abs_path/;
use File::Spec::Functions qw/:DEFAULT rel2abs/;
use Test::Smoke::Poster::Curl;
use Test::Smoke::Poster::HTTP_Tiny;
use Test::Smoke::Poster::LWP_UserAgent;

=head1 NAME

Test::Smoke::Poster - Factory for poster objects.

=head1 SYNOPSIS

    use Test::Smoke::Poster;
    my $poster = Test::Smoke::Poster->new(
        'LWP::UserAgent',
        ddir => '.',
        smokedb_url => 'http://perl5.test-smoke.org/report',
    );
    $poster->post();

=head1 DESCRIPTION

Returns a instance of the object-class requested.

=cut

my %CONFIG = (
    df_poster  => 'HTTP::Tiny',
    df_ddir    => undef,
    df_jsnfile => 'mktest.jsn',
    df_qfile   => undef,
    df_v       => 0,

    df_smokedb_url => 'https://perl5.test-smoke.org/api/report',

    df_ua_timeout => undef,

    df_curlargs => [ ],

    'LWP::UserAgent' => {
        allowed  => [qw/ua_timeout/],
        required => [],
        class    => 'Test::Smoke::Poster::LWP_UserAgent',
    },
    'HTTP::Tiny' => {
        allowed => [qw/ua_timeout/],
        required => [],
        class => 'Test::Smoke::Poster::HTTP_Tiny',
    },
    'curl' => {
        allowed => [qw/curlbin curlargs ua_timeout/],
        required => [qw/curlbin/],
        class => 'Test::Smoke::Poster::Curl',
    },

    valid_type => {
        'LWP::UserAgent' => 1,
        'HTTP::Tiny'     => 1,
    },

    general_options => [qw/ddir jsnfile qfile v smokedb_url poster/],
);

=head2 Test::Smoke::Poster->new($poster_type, %arguments)

Check arguments and return an instance of $poster_type.

=cut

sub new {
    my $factory = shift;
    my $poster = shift || $CONFIG{df_poster};

    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my %fields = map {
        my $value = exists $args{$_} ? $args{ $_ } : $CONFIG{ "df_$_" };
        ( $_ => $value )
    } ( @{ $CONFIG{general_options} }, @{ $CONFIG{$poster}{allowed} } );
    if ( ! file_name_is_absolute( $fields{ddir} ) ) {
        $fields{ddir} = catdir( abs_path(), $fields{ddir} );
    }
    $fields{ddir} = rel2abs( $fields{ddir}, abs_path() );
    $fields{poster} = $poster;

    my @missing;
    for my $required (@{ $CONFIG{$poster}{required} }) {
        push(
            @missing,
            "option '$required' missing for '$CONFIG{$poster}{class}'"
        ) if !defined $fields{$required};
    }
    if (@missing) {
        croak("Missing option:\n\t", join("\n\t", @missing));
    }

    my $class = $CONFIG{$poster}{class};
    return $class->new(%fields);
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
