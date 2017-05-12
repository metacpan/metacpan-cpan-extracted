package xt::Util;
use strict;
use warnings;
use Exporter qw/import/;
use Time::Piece qw/gmtime/;

our %EXPORT_TAGS = (
    cmp_deeply => [qw(
        cmp_deeply
        hash
        array_of_hashes
        uri
        integer
        real
        datetime
        game_result
        user_name
        user_rank
    )],
);

our @EXPORT_OK = ( 'build_gokgs', map { @$_ } values %EXPORT_TAGS );

sub build_gokgs {
    my $gokgs = do {
        if ( $ENV{WWW_GOKGS_LIBXML} ) {
            require WWW::GoKGS::LibXML;
            WWW::GoKGS::LibXML->new( from => 'anazawa@cpan.org' );
        }
        else {
            require WWW::GoKGS;
            WWW::GoKGS->new( from => 'anazawa@cpan.org' );
        }
    };

    $gokgs->user_agent->delay( 1/60 );

    $gokgs;
}

sub cmp_deeply {
    my ( $got, $expected, $name ) = @_;

    Test::More::subtest(
        $name || 'unknown',
        sub { $expected->( $got ) }
    );

    return;
}

sub hash {
    my %expected = @_;

    sub {
        my $got = shift;
        my $name = shift || '$hash';

        Test::More::isa_ok( $got, 'HASH', $name );

        for my $key ( keys %$got ) {
            my $value = $got->{$key};
            my $n = "$name\->{$key}";

            if ( ref $expected{$key} eq 'CODE' ) {
                local $_ = $value;
                my $bool = $expected{$key}->( $value, $n );
                Test::More::ok( $bool, $n ) if defined $bool;
            }
            elsif ( ref $expected{$key} eq 'ARRAY' ) {
                for my $e ( @{$expected{$key}} ) {
                    local $_ = $value;
                    my $bool = $e->( $value, $n );
                    Test::More::ok( $bool, $n ) if defined $bool;
                }
            }
        }

        return;
    };
}

sub array_of_hashes {
    my $expected = hash( @_ );

    sub {
        my $got = shift;
        my $name = shift || '$array';

        Test::More::isa_ok( $got, 'ARRAY', $name );

        my $i = 0;
        for my $g ( @$got ) {
            local $_ = $g;
            my $n = "$name\->[$i]";
            my $bool = $expected->( $g, $n );
            Test::More::ok( $bool, $n ) if defined $bool;
            $i++;
        }

        return;
    };
}

sub uri {
    sub {
        my ( $got, $name ) = @_;
        Test::More::isa_ok( $got, 'URI', $name );
        return;
    };
}

sub integer {
    sub {
        my ( $got, $name ) = @_;

        Test::More::like(
            $got,
            qr{^(?:0|\-?[1-9][0-9]*)$},
            "'$name' should be integer"
        );

        return;
    };
}

sub real {
    sub {
        my ( $got, $name ) = @_;

        Test::More::like(
            $got,
            qr{^(?:0|\-?[1-9][0-9]*(?:\.[0-9]*[1-9])?)$},
            "'$name' should be real"
        );

        return;
    };
}

sub datetime {
    my $format = shift;

    sub {
        my ( $got, $name ) = @_;
        eval { gmtime->strptime( $got, $format ) };
        Test::More::ok( !$@, "'$name' ($got) should be '$format': $@" );
        return;
    };
}

sub game_result {
    sub {
        my ( $got, $name ) = @_;

        Test::More::like(
            $got,
            qr{^(?:
                Unfinished
              | Draw 
              | (?:B|W)\+(?:
                    Resign
                  | Forfeit
                  | Time
                  | (?:0|[1-9][0-9]*)(?:\.5)? )
            )$}x,
            $name
        );

        return;
    };
}

sub user_name {
    sub {
        my ( $got, $name ) = @_;
        Test::More::like( $got, qr/^[a-zA-Z][a-zA-Z0-9]{0,9}$/, $name );
        return;
    };
}

sub user_rank {
    sub {
        my ( $got, $name ) = @_;

        Test::More::like(
            $got,
            qr{^(?:
                \-
              | \?
              | [1-9](?:p|d\??|k\??)
              | [12][0-9]k\??
              | 30k\??
            )$}x,
            $name
        );

        return;
    };
}

1;
