#! /usr/bin/env perl

use Array::RefElem ();    #qw( hv_store );
use File::Spec     ();
use FindBin        ();    #qw( $Bin );
use Scalar::Util   ();    #qw( blessed );

use Test2::V0;

ok( require filename, "Can require filename module" );
ok( require pm,       "Can require pm module" );

my %core = %INC;
my %file = %INC;
my %inc  = %INC;
my %incs = (
    "CORE::require"     => \%core,
    "filename->require" => \%file,
    "inc"               => \%inc,
);

# This hack is because I need them to report the same error message,
# including filename and line number.
my ( $core, $file ) = do {
    ( my $test = <<'END' ) =~ s/\s+//g;
sub {
    local $_ = shift() if @_;
    _restore_INC('require');
    my $return = eval { require };
    _save_INC('require');
    die $@ if $@;
    return $return;
}
END
    eval( join(
        ",",
        map { ( my $sub = $test ) =~ s/require/$_/g; $sub } qw(
            CORE::require
            filename->require
        )
    ) );
};

sub _save_INC {
    @_ = ("inc") unless @_;
    local $_;
    %{ $incs{$_} } = %INC foreach @_;
}
sub _restore_INC {
    %INC = %{ $incs{ shift() // "inc" } };
    local $_;
    Array::RefElem::hv_store( %INC, $_, undef )
        foreach grep { not defined $INC{$_} } keys %INC;
    return %INC;
}

my $noinc = bless {}, "Testing::WithoutINC";

# Negative tests
foreach my $inc (
    # CODE
    # CODE: Emtpy return
    "inc_func_0",

    # CODE: Single value return
    "inc_func_scalar",

    # Object
    $noinc,
) {
    diag "\@INC now includes ", ref($inc) || $inc;
    local @INC = ( ref($inc) ? $inc : ( __PACKAGE__->can($inc) || $inc ) );
    #push @INC, \&looking_for;

    foreach my $pm (qw( good symlink )) {

        my $module
            = v5.18.0 <= $^V && $^V < v5.26.0
            ? sprintf(
                "(you may need to install the Testing-%s module) ", $pm )
            : "";
        $_ = my $filename = sprintf( "Testing-%s.pm", $pm );

        {
            _save_INC(qw( CORE::require filename->require ));

            is( dies {&$file}, dies {&$core},
                "Cannot require $filename with $inc" );
            is( \%file, \%core,
                "%INC is the same for filename and CORE" );

            _restore_INC();
        }

        {
            _save_INC(qw( CORE::require filename->require ));

            my $expected_error
                = Scalar::Util::blessed($inc)
                ? sprintf(
                      qq!Can't locate object method "INC" via package "%s"!
                    . qq! at %s line %d.\n!,
                    ref($inc), __FILE__, __LINE__ + 9
                )
                : sprintf(
                      "Can't locate %s in \@INC "
                    . $module
                    . "(\@INC contains: %s)"
                    . " at %s line %d.\n",
                    $filename, "@INC", __FILE__, __LINE__ + 2
                );
            is( dies { CORE::require($filename) }, $expected_error,
                "Failed to require $filename with $inc" );
            is( exists $INC{$filename}, "",
                "%INC has not been updated for $filename" )
                || diag(
                    "\$INC{$filename} is ",
                    defined( $INC{$filename} )
                        ? $INC{$filename}
                        : "undefined"
                );

            is( dies {&$file}, dies {&$core},
                "Trying to re-require $filename" );
            is( \%file, \%core,
                "%INC is the same for filename and CORE" );

            _restore_INC();
        }
    }
}

my $withinc = bless {}, "Testing::INC";

# Positive tests
foreach my $inc (

    # CODE

    # CODE: Single value return
    "inc_func_scalarref",
    "inc_func_fh",
    "inc_func_coderef",

    # CODE: Two value return
    "inc_func_scalarref_fh",
    "inc_func_scalarref_coderef",
    "inc_func_fh_coderef",
    "inc_func_coderef_state",

    # CODE: Three value return
    "inc_func_scalarref_fh_coderef",
    "inc_func_scalarref_coderef_state",

    # CODE : Four value return
    "inc_func_scalarref_fh_coderef_state",

    # ARRAY
    [ \&inc_func_coderef, "Testing", 123 ],

    # Object
    $withinc,

) {
    diag "\@INC now includes ", ref($inc) || $inc;
    local @INC = ( ref($inc) ? $inc : ( __PACKAGE__->can($inc) || $inc ) );

    # Tests with good files
    foreach my $pm (qw( good symlink )) {
        $_ = my $filename = sprintf( "Testing-%s.pm", $pm );

        _save_INC(qw( CORE::require filename->require ));

        is( &$file, &$core, "Can require $filename" );
        is( \%file, \%core, "%INC is the same for filename and CORE" );

        _restore_INC();
    }

    # Tests with bad files
    foreach my $pm (qw(
        empty
        empty-string
        errno
        eval_error
        false
        undef
    )) {
        my $module = sprintf( "Testing-%s", $pm );
        $_ = my $filename = sprintf( "%s.pm", $module );

        {
            _save_INC(qw( CORE::require filename->require ));

            my ( $fdie, $cdie ) = ( dies {&$file}, dies {&$core} );
            if ( $inc !~ /_scalarref_/ ) {
                s!/loader/0x[[:xdigit:]]+/!/loader/0xXXX/!
                    for ( $fdie, $cdie );
            }
            is( $fdie, $cdie,
                "Cannot require $filename with $inc" );
            is( \%file, \%core,
                "%INC is the same for filename and CORE" );

            _restore_INC();
        }

        {
            _save_INC(qw( CORE::require filename->require ));

            my $expected_error = sprintf(
                "%s did not return a true value at %s line %d.\n",
                $filename, __FILE__, __LINE__ + 2
            );
            is( dies { CORE::require($filename) }, $expected_error,
                "Failed to require $filename with $inc" );
            is( exists $INC{$filename}, "",
                "%INC has not been updated for $filename" )
                || diag(
                    "\$INC{$filename} is ",
                    defined( $INC{$filename} )
                        ? $INC{$filename}
                        : "undefined"
                );

            is( dies {&$file}, dies {&$core},
                "Trying to re-require $filename" );
            is( \%file, \%core,
                "%INC is the same for filename and CORE" );

            _restore_INC();
        }
    }

    # The bad file Testing-failure.pm has a difference in the error message,
    # so setup some special testing for that case.
    foreach my $pm (qw(
        failure
    )) {
        my $module = sprintf( "Testing-%s", $pm );
        $_ = my $filename = sprintf( "%s.pm", $module );

        _save_INC(qw( CORE::require filename->require ));

        is( { map { $_ => $INC{$_} } grep /Testing/, keys %INC }, {},
            "%INC has no Testing" );

        my $load_file
            = $inc =~ /_scalarref_/
            ? quotemeta( sprintf( "%s/%s", __FILE__, $filename ) )
            : sprintf( "\\/loader\\/0x[[:xdigit:]]+\\/%s",
                quotemeta($filename) );
        my @expected_errors = (
            sprintf(
                  "syntax error at %s line \\d, at EOF\n"
                . "Compilation failed in require at %s line %d.\n",
                $load_file, map quotemeta, __FILE__, __LINE__ + 9
            ),
            sprintf(
                  "Attempt to reload %s aborted.\n"
                . "Compilation failed in require at %s line %d.\n",
                map quotemeta, $filename, __FILE__, __LINE__ + 4
            ),
        );
        for my $expected_error (@expected_errors) {
            like( dies { CORE::require }, qr/\A$expected_error\z/,
                "Failed to require $filename with $inc" );
            is( exists $INC{$filename}, 1,
                "%INC has been updated for $filename" );
            is( $INC{$filename}, undef,
                "\$INC{$filename} is undef" );
        }

        my $die = sprintf(
              "syntax error at %s line \\d+, at EOF\n"
            . "Compilation failed in require at \\(eval \\d+\\) line 1\\.\n",
            $load_file
        );
        my ( $fdie, $cdie ) = ( dies {&$file}, dies {&$core} );
        like( $fdie, qr/\A$die\z/,
            "Cannot require $filename with $inc" );
        like( $fdie, qr/\A$die\z/,
            "Cannot require $filename with $inc" );
        is( \%file, \%core, "%INC is the same for filename and CORE" );

        is( dies {&$file}, dies {&$core},
            "Trying to re-require $filename" );
        is( \%file, \%core, "%INC is the same for filename and CORE" );

        _restore_INC();
    }
}

done_testing();


# Four value return
sub inc_func_scalarref_fh_coderef_state {
    my ( $sub, $filename ) = @_;
    my $precode = sprintf( "#line 0 %s/%s\n", __FILE__ , $filename );
    return \$precode, inc_func_fh( \&inc_func_fh, $filename ),
        inc_func_coderef( \&inc_func_coderef, $filename ), {};
}

# Three value return
sub inc_func_scalarref_fh_coderef {
    my ( $sub, $filename ) = @_;
    my $precode = sprintf( "#line 0 %s/%s\n", __FILE__ , $filename );
    return \$precode, inc_func_fh( \&inc_func_fh, $filename ),
        inc_func_coderef( \&inc_func_coderef, $filename );
}
sub inc_func_scalarref_coderef_state {
    my ( $sub, $filename ) = @_;
    my $precode = sprintf( "#line 0 %s/%s\n", __FILE__ , $filename );
    return \$precode, inc_func_coderef( \&inc_func_coderef, $filename ), {};
}

# Two value return
sub inc_func_scalarref_fh {
    my ( $sub, $filename ) = @_;
    my $precode = sprintf( "#line 0 %s/%s\n", __FILE__ , $filename );
    return \$precode, inc_func_fh( \&inc_func_fh, $filename );
}
sub inc_func_scalarref_coderef {
    my ( $sub, $filename ) = @_;
    my $precode = sprintf( "#line 0 %s/%s\n", __FILE__ , $filename );
    return \$precode, inc_func_coderef( \&inc_func_coderef, $filename );
}
sub inc_func_fh_coderef {
    my ( $sub, $filename ) = @_;
    return inc_func_fh( \&inc_func_fh, $filename ),
        inc_func_coderef( \&inc_func_coderef, $filename );
}
sub inc_func_coderef_state {
    my ( $sub, $filename ) = @_;
    return inc_func_coderef( \&inc_func_coderef, $filename ), {};
}

# Single value return
sub inc_func_scalar {
    my ( $sub, $filename ) = @_;
    my $fullpath = File::Spec->catfile( $FindBin::Bin, $filename );
    return -r -f $fullpath ? $fullpath : ();
}
sub inc_func_scalarref {
    my ( $sub, $filename ) = @_;
    my $scalar = do {
        local $/;
        my $fh = inc_func_fh( \&inc_func_fh, $filename ) or die $!;
        <$fh>;
    };
    return \$scalar;
}
sub inc_func_fh {
    my ( $sub, $filename ) = @_;
    my $fh;
    return
        open( $fh, "<", File::Spec->catfile( $FindBin::Bin, $filename ) )
        ? $fh
        : ();
}
sub inc_func_coderef {
    my ( $sub, $filename ) = @_;
    my $fh = inc_func_fh( \&inc_func_fh, $filename );
    return $fh ? sub { $_ = <$fh>; return 0+ !!length() } : ();
}

# Empty return
sub inc_func_0 {
    my ( $sub, $filename ) = @_;
    ( $sub, my @params ) = ref($sub) eq "ARRAY" ? @$sub : ( undef, $sub );
    return;
}

package Testing::INC;

BEGIN { *Testing::INC::INC = \&::inc_func_scalarref; }

package Testing::WithoutINC;

