#! perl -Iblib/arch -Iblib/lib
use Tuxedo;

$numargs = @ARGV;
if ( $numargs == 0 )
{
    $ARGV[0] = "fld.tbl";
    $numargs = 1;
}

$index = 0;
while ( $index < $numargs )
{
    $fldtbl = $ARGV[$index];
    $fldpm  = ( $fldtbl . ".pm" );

    # check the file exists
    unless ( -e $fldtbl ) {
        die( "CMDFML_CAT:2:ERROR: Cannot find file " . $fldtbl . "\n" );
    }

    # open the fldtbl for reading
    unless ( open( FLDTBL, $fldtbl ) ) {
        die( "Cannot open file " . $fldtbl . " for reading.\n" );
    }

    # open the fldpm for writing
    unless ( open( FLDPM, ">" . $fldpm ) ) {
        die( "Cannot open file " . $fldpm . " for writing.\n" );
    }

    $base = 0;
    $fields;
    while ( $line = <FLDTBL> )
    {
        if ( $line =~ /^\s*[\#\$]/ || $line =~ /^\s*$/ )
        {
            # this is a comment, so ignore this line
            next;
        }

        if ( $line =~ /^\s*\*base\s+(\d+)/ )
        {
            $base = $1;
        }
        else
        {
            # line should be in the format...
            # <FLDNAME> <FLDNUM> <FLDTYPE> [# comment]
            @words = split( /\s+/, $line );
            if ( @words < 3 )
            {
                print $line . "WARNING: invalid line.\n";
                next;
            }

            $fldname = $words[0];
            $fldnum  = $words[1];
            $type = $words[2];
            $fldtype = 0;
            if ( $type eq "short" ) {
                $fldtype = FLD_SHORT;
            }
            elsif ( $type eq "long" ) {
                $fldtype = FLD_LONG;
            }
            elsif ( $type eq "char" ) {
                $fldtype = FLD_CHAR;
            }
            elsif ( $type eq "float" ) {
                $fldtype = FLD_FLOAT;
            }
            elsif ( $type eq "double" ) {
                $fldtype = FLD_DOUBLE;
            }
            elsif ( $type eq "string" ) {
                $fldtype = FLD_STRING;
            }
            elsif ( $type eq "carray" ) {
                $fldtype = FLD_CARRAY;
            }
            elsif ( $type eq "ptr" ) {
                $fldtype = FLD_PTR;
            }
            elsif ( $type eq "fml32" ) {
                $fldtype = FLD_FML32;
            }
            elsif ( $type eq "view32" ) {
                $fldtype = FLD_VIEW32;
            }
            else {
                # something is wrong, skip this line
                next;
            }

            $fldnum += $base;
            $fldid = Fmkfldid32( $fldtype, $fldnum );
            $fields{$fldname} = $fldid;
        }
    }

    print FLDPM "package " . $fldtbl . ";\n\n";
    print FLDPM "use strict;\n";
    print FLDPM "use vars qw(\$VERSION \@ISA \@EXPORT);\n";
    print FLDPM "require Exporter;\n\n";
    print FLDPM "\$VERSION = 1.00;\n\n";
    print FLDPM "\@ISA = qw(Exporter);\n";
    print FLDPM "\@EXPORT = qw(\n";
    foreach $fldname ( keys( %fields ) )
    {
        print FLDPM ( "\t$fldname\n" );
    }
    print FLDPM ( ");\n\n" );

    print FLDPM "# subs\n";
    foreach $fldname ( keys( %fields ) )
    {
        print FLDPM ( "sub $fldname { $fields{$fldname}; }\n" );
    }

    print FLDPM "\n1; #\n";

    close( FLDTBL );
    close( FLDPM );

    $index++;
}
