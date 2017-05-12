#!perl

use strict;
use warnings;
use Fatal qw(open close unlink select rename);
use English qw( -no_match_vars );
use Carp;

our $FH;

Carp::croak("usage: $PROGRAM_NAME: old_version new_version")
    unless scalar @ARGV == 2;

my ( $old, $new ) = @ARGV;

print {*STDERR} "$old $new\n"
    or Carp::croak("Cannot print to STDERR: $ERRNO");

sub check_version {
    my $version = shift;
    my ( $major, $minor1, $underscore, $minor2 ) =
        ( $version =~ m/^ ([0-9]+) [.] ([0-9.]{3}) ([_]?) ([0-9.]{3}) $/xms );
    if ( not defined $minor2 ) {
        Carp::croak("Bad format in version number: $version");
    }
    if ( $minor1 % 2 and $underscore ne '_' ) {
        Carp::croak("No underscore in developer's version number: $version");
    }
    if ( $minor1 % 2 == 0 and $underscore eq '_' ) {
        Carp::croak(
            "Underscore in official release version number: $version");
    }
} ## end sub check_version

check_version($old);
check_version($new);

## no critic (BuiltinFunctions::ProhibitStringyEval)
Carp::croak("$old >= $new") if eval $old >= eval $new;
## use critic

sub change {
    my ( $fix, @files ) = @_;
    for my $file (@files) {
        open my $fh, '<', $file;
        my $text = do { local ($RS) = undef; <$fh> };
        close $fh;
        my $backup = "save/$file";
        rename $file, $backup;
        open my $argvout, '>', $file;
        print {$argvout} ${ $fix->( \$text, $file ) }
            or Carp::croak("Could not print to argvout: $ERRNO");
        close $argvout;
    }
    return 1;
}

sub fix_META_yml {
    my $text_ref  = shift;
    my $file_name = shift;

    unless ( ${$text_ref} =~ s/(version:\s*)$old/$1$new/gxms ) {
        print {*STDERR}
            "failed to change version from $old to $new in $file_name\n"
            or Carp::croak("Could not print to argvout: $ERRNO");
    }
    return $text_ref;
}

sub fix_Weaken_pm {
    my $text_ref  = shift;
    my $file_name = shift;

    unless (
        ${$text_ref} =~ s{
            (
                our
                \s+
                [\$]
                VERSION
                \s*
                =
                \s*
                [']
            )
            $old
            [']
            [;]
        }{$1$new';}xms
        )
    {
        print {*STDERR}
            "failed to change VERSION from $old to $new in $file_name\n"
            or Carp::croak("Could not print to STDERR: $ERRNO");
    }
    return $text_ref;
}

sub update_changes {
    my $text_ref  = shift;
    my $file_name = shift;

    my $date_stamp = localtime;
    unless ( ${$text_ref}
        =~ s/(\ARevision\s+history\s+[^\n]*\n\n)/$1$new $date_stamp\n/xms )
    {
        print {*STDERR} "failed to add $new to $file_name\n"
            or Carp::croak("Could not print to STDERR: $ERRNO");
    }
    return $text_ref;
}

change( \&fix_META_yml,   'META.yml' );
change( \&fix_Weaken_pm,  'lib/Test/Weaken.pm' );
change( \&update_changes, 'Changes' );

print {*STDERR} "REMEMBER TO UPDATE Changes file\n"
    or Carp::croak("Could not print to STDERR: $ERRNO");
