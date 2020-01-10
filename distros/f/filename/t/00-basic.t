#! /usr/bin/env perl

use FindBin ();

use Test2::V0;

ok( require filename, 'Can require filename module' );
ok( require pm,       'Can require pm module' );

@INC = ( $FindBin::Bin, @INC );

our %inc = %INC;
my ( %incs, %file, %core );
$incs{'filename->require'} = \%file;
$incs{'CORE::require'}     = \%core;

# This hack is because I need them to report the same error message,
# including filename and line number.
my ( $file, $core ) = do {
    ( my $test = <<'END' ) =~ s/\s+//g;
sub {
    local %INC = %inc;
    my $return = require;
    %{ $incs{'require'} } = %INC;
    return $return;
}
END
    eval( join(
        ',',
        map { ( my $sub = $test ) =~ s/require/$_/g; $sub } qw(
            filename->require
            CORE::require
        )
    ) );
};

foreach my $prefix ( "", "$FindBin::Bin/" ) {

    foreach my $pm (qw( good symlink )) {
        $_ = my $filename = sprintf( '%sTesting-%s.pm', $prefix, $pm );

        is( &$file, &$core, "Can filename->require $filename" );
        is( \%file, \%core, '%INC is the same for filename and CORE' );

        my $statname = ( $prefix ? "" : "$FindBin::Bin/" ) . $filename;
        my $mode = ( stat $statname )[2] & 07777
            || die "Cannot stat $statname";
        chmod( 00000, $statname ) or die "Could not chmod $statname: $!";
        is( dies {&$file}, dies {&$core},
            "Cannot file->require unreadable $filename" );
        is( \%file, \%core, '%INC is the same for file and CORE' );
        eval { file->require($filename) };
        local %inc = %INC;
        is( dies {&$file}, dies {&$core},
            "Trying to re-filename->require an unreadable file fails" );
        is( \%file, \%core, '%INC is the same for file and CORE' );
        chmod( $mode, $statname ) or die "Could not chmod $statname: $!";
    }

    foreach my $pm (qw(
        empty
        empty-string
        errno
        eval_error
        failure
        false
        undef
    )) {
        $_ = my $filename = sprintf( '%sTesting-%s.pm', $prefix, $pm );

        is( dies {&$file}, dies {&$core},
            "Cannot filename->require $filename" );
        is( \%file, \%core, '%INC is the same for file and CORE' );
        eval { filename->require($filename) };
        local %inc = %INC;
        is( dies {&$file}, dies {&$core},
            "Trying to re-filename->require $filename" );
        is( \%file, \%core, '%INC is the same for file and CORE' );
    }

}

done_testing();
