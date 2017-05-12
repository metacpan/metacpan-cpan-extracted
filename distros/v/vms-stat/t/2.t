# Before `mmk install' is performed this script should be runnable with
# Either `perl "-Mblib" t/2.t' or `mmk test'.
# After `mmk install' it should work as `perl t/2.t'

#########################

use VMS::Stat; 
my %test_types;

BEGIN { 
    %test_types = (
        'ai'    => 'bool',
        'alq'   => 'int',
        'bi'    => 'bool',
#        'bdt'   => 'string',
        'bks'   => 'int',
        'bls'   => 'int',
        'cbt'   => 'bool',
#        'cdt'   => 'string',
        'ctg'   => 'bool',
        'deq'   => 'int',
        'erase' => 'bool',
        'fsz'   => 'int',
        'gbc'   => 'int',
#        'journal_file' => 'bool',
#        'known' => 'bool',
        'mrn'   => 'int',
        'mrs'   => 'int',
        'org'   => 'org',
        'rat'   => 'rat',
#        'rck'   => 'bool',
        'rfm'   => 'rfm',
#        'ru'    => 'bool',
#        'wck'    => 'bool',
    );
    $number_of_tests = scalar(keys(%test_types)) + 5;
    print "1..$number_of_tests\n";
};

# Under 5.8.1 we could use Test::More, but for earlier perl's that have not
# visited CPAN we could not.  Sorry Michael.
my $t = 1;
print "ok $t\n"; # The use statement compiled OK if we got this far.

++$t;
# The file that we will use for many tests:
my $filespec = 'SYS$DISK:[]Makefile.PL';
my %fab = VMS::Stat::get_fab( $filespec );
print + defined( $fab{'alq'} ) ? "ok $t\n" : "not ok $t # basic get_fab($filespec) call\n";
++$t;
# Oddly calls to stat ususally set ( $^E eq '%RMS-E-FNF, file not found' ), but I do not know why.
print + ( $^E eq '%RMS-S-NORMAL, normal successful completion' ) ? "ok $t\n" : "not ok $t # $^E after get_fab($filespec) call\n";

++$t;
my $non_existant_filespec = 'SYS$DISK:[]silly.name.that.is.not.ods-2.legal.$$.and.has.no.carets.hence.not-0ds-5.either';
my %non_fab = VMS::Stat::get_fab( $non_existant_filespec );
print + ( ! defined( $non_fab{'alq'} ) ) ? "ok $t\n" : "not ok $t # basic get_fab($non_existant_filespec) call\n";
++$t;
print + ( $^E eq '%RMS-E-ACC, ACP file access failed' ) ? "ok $t\n" : "not ok $t # $^E after get_fab($non_existant_filespec) call\n";


# Comparisons to f$file_attributes() DCL results:
foreach my $key ( sort( keys %test_types ) ) {
    ++$t;
    my $KEY = uc($key);
    chomp($file_attributes{$key} = `write sys\$output f\$file_attributes("$filespec","$KEY")`);
    # print "# $key, $fab{$key} $file_attributes{$key}\n";
    if ( $test_types{$key} eq 'bool' ) {
        $file_attributes{$key} = + ($file_attributes{$key} eq 'TRUE') ? 1 : '';
        print + ( $fab{$key} eq $file_attributes{$key} ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
    }
    elsif ( $test_types{$key} eq 'int' ) {
        print + ( $fab{$key} == $file_attributes{$key} ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
    }
    elsif ( $test_types{$key} eq 'org' ) {
           if ( $fab{$key} == 0 ) {
            print + ( $file_attributes{$key} eq 'SEQ' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 16 ) {
            print + ( $file_attributes{$key} eq 'REL' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 32 ) {
            print + ( $file_attributes{$key} eq 'IDX' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        else {
            print "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
    }
    elsif ( $test_types{$key} eq 'rat' ) {
           if ( $fab{$key} == 1 ) {
            print + ( $file_attributes{$key} eq 'FTN' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 2 ) {
            print + ( $file_attributes{$key} eq 'CR' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 4 ) {
            print + ( $file_attributes{$key} eq 'PRN' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        else {
            print "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
    }
    elsif ( $test_types{$key} eq 'rfm' ) {
           if ( $fab{$key} == 0 ) {
            print + ( $file_attributes{$key} eq 'UDF' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 1 ) {
            print + ( $file_attributes{$key} eq 'FIX' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 2 ) {
            print + ( $file_attributes{$key} eq 'VAR' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 3 ) {
            print + ( $file_attributes{$key} eq 'VFC' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 4 ) {
            print + ( $file_attributes{$key} eq 'STM' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 5 ) {
            print + ( $file_attributes{$key} eq 'STMLF' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        elsif ( $fab{$key} == 6 ) {
            print + ( $file_attributes{$key} eq 'STMCR' ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
        else {
            print "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
        }
    }
    elsif ( $test_types{$key} eq 'string' ) {
        print + ( $fab{$key} eq $file_attributes{$key} ) ? "ok $t\n" : "not ok $t # for $key obtained >$fab{$key}<, expected >$file_attributes{$key}<\n";
    }
}

