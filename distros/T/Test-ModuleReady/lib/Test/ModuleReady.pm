package Test::ModuleReady;
use strict; 
use warnings;
use Carp;
use Pod::Checker;    
use Test::More tests => 1;    
use Test::Spelling;

# add croak on all closes too

#/ probably ought to add ';´ to end of all regexps as it was picking out the damned description´s version of the $VERSION variable...

#/ doesn´t matter where the file/module is just need to execture from insdie the module to be tested

#/ there is an issue with dirs - i.e. checks that a thing is a dir -d but the if not assumes its a file - should use -f but this won´t be true for some files...?!?

=head1 NAME

Test::ModuleReady - Simple module for checking that a module is ready for submission.

=cut 

=head1 VERSION

This document describes Test::ModuleReady version 0.0.6

=cut

=head1 SYNOPSIS
    
First create a standard perl script that uses the module e.g. ~/module-check.pl

    #!/usr/bin/perl -w
 
    # use the module.
    use Test::ModuleReady;

    # Call the single exported subroutine.
    &module_ready; 

Enter the root directory of your module containing the MANIFEST, README, t/, lib/ etc. then run the perl scripts from
this directory e.g. perl ~/module-check.pl. The module will then perform each check in succession printing the result to
STDOUT and wait for your to enter carriage-return before proceeding to the next. Thus the initial output will be
something like:

    ------------------------------------------------------------
    CHECKING MODULE VERSION NUMBERS

    [*] Found module lib/Statistics/MVA/BayesianLinearDiscrimination.pm
    [*] Version number from README is 0.0.3 
    [*] Version number from module POD is 0.0.1 
    [*] Version number from module $VERSION variable is 0.0.2 

    [*] Version numbers in $VERSION variable, POD and README do not match

    Press carriage return to detect missing and excess files and 'n' carriage return to exit? 
    
Enter carriage-return to proceed.

    ------------------------------------------------------------
    CHECKING FOR EXCESS AND MISSING FILES

    [1] There is a excess file:    './i-exist-but-am-not-mentioned-in-manifest'

    Do you wish to delete the file (d), append (a) it to the MANIFEST or ignore it (i) or exit (q)? a

    Are you sure you wish to append file ./i-exist-but-am-not-mentioned-in-manifest to MANIFEST? y

    Appending file i-exist-but-am-not-mentioned-in-manifest to MANIFEST

    [2] There is a missing file:    './i-do-not-exist'

    Press carriage return to perform dependency check on Makefile.PL and Build.PL and 'n' carriage return to exit?

Just continue...

=cut  

=head1 DESCRIPTION

This module was written to help me prepare updates to modules. I have a nasty habit of over-looking tedious things like
checking that the version numbers in the README, POD and $VERSION variable in the module file are all equal. Also not
only checking that all the files listed in the MANIFEST but more importantly checking that I haven´t left old .svn
repositories, .Rhistory files Vim .swp files etc. have all been deleted. This modules is aimed at addressing these and
other house-keeping chores just before submitting a new module release (of course you can just use perl Build.PL;
./Build dist to avoid some of these issues).

    This module:

    (1) Pulls the version numbers from the README, Module POD and Module $VERSION variable and checks they are all equal.
    (2) Reads in the MANIFEST contents and checks that there are missing or extra files in the directory - see Below.
        For missing files it just prints the problem and continues. However, for excess files or directories it asks
        whether you want to ignore it, append it automatically to the MANIFEST file or delete it.
    (3) Scans the Module.pm file for use statements and then cross-references these against the dependencies arguments
        in Makefile.PL and Build.PL making sure you do not forget to include important dependencies. Specifically, for
        every 'use' statement found it prints whether or not it found the appropriate dependency in the PREREQ_PM or
        requires hashes for Makefile.PL and Build.PL respectively.
    (4) Extracts POD sections and checks the length of verbatim sections to make sure they do not have excessing length.
    (5) Runs POD syntax checking using the Pod::Checker module.
    (6) Prompts you for words to ignore before running spell-check using Test::Spelling/Test::More modules.
    (7) Checks the Module.pm syntax using the basic Perl interpreter syntax check.
    (8) Runs: perl Build.pl; ./Build disttest to use Builds much superior testing facilities and generate the META.yml.
    (9) If your happy with the results it runs: ./Build dist to generate the tar file.

This module does not recurse into the working directory and consequently if you choose to keep an excess directory it will totally
ignore everything below. Instead the module takes the MANIFEST file contents and generates a hash of directories as keys
and anonymous arrays containing the directory contents as values. It then enters each of those directories and checks the supposed 
contents against their actual contents thereby detecting missing and excess files/dirs. For example the MANIFEST file:

    Build.PL
    Changes
    MANIFEST
    Makefile.PL
    README
    lib/Statistics/MVA/BayesianLinearDiscrimination.pm
    t/00.load.t
    t/pod.t

Generates a hash of dirs to contents as (output generated using L<Data::TreeDraw>.

    HASH REFERENCE (0)
    |  
    |__'lib/'=>ARRAY REFERENCE (1) [ '->{lib/}' ]
    |    |  
    |    |__SCALAR = 'Statistics' (2)  [ '->{lib/}[0]' ]
    |  
    |__'lib/Statistics/'=>ARRAY REFERENCE (1) [ '->{lib/Statistics/}' ]
    |    |  
    |    |__SCALAR = 'MVA' (2)  [ '->{lib/Statistics/}[0]' ]
    |  
    |__'./'=>ARRAY REFERENCE (1) [ '->{./}' ]
    |    |  
    |    |__SCALAR = 'MANIFEST' (2)  [ '->{./}[0]' ]
    |    |  
    |    |__SCALAR = 'lib' (2)  [ '->{./}[1]' ]
    |    |  
    |    |__SCALAR = 'Changes' (2)  [ '->{./}[2]' ]
    |    |  
    |    |__SCALAR = 'Build.PL' (2)  [ '->{./}[3]' ]
    |    |  
    |    |__SCALAR = 'Makefile.PL' (2)  [ '->{./}[4]' ]
    |    |  
    |    |__SCALAR = 'README' (2)  [ '->{./}[5]' ]
    |    |  
    |    |__SCALAR = 't' (2)  [ '->{./}[6]' ]
    |  
    |__'lib/Statistics/MVA/'=>ARRAY REFERENCE (1) [ '->{lib/Statistics/MVA/}' ]
    |    |  
    |    |__SCALAR = 'BayesianLinearDiscrimination.pm' (2)  [ '->{lib/Statistics/MVA/}[0]' ]
    |  
    |__'t/'=>ARRAY REFERENCE (1) [ '->{t/}' ]
         |  
         |__SCALAR = '00.load.t' (2)  [ '->{t/}[0]' ]
         |  
         |__SCALAR = 'pod.t' (2)  [ '->{t/}[1]' ]


=cut

# close the sub dir handles immediately when you don´t need them
# open MANIFEST only when needed?!?

use version; our $VERSION = qv('0.0.6');

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(module_ready);

# level of syntax checking?!? i.e. h or l - 1/2

#y really lazy bad practice package-scoped lexical - just want a number for each missing and excess file
my $count = 1; # this is being global so needs to be before call to check in while
#&module_ready;

sub module_ready {

    #y open, read and close MANIFEST
    open my $man, q{<}, q{MANIFEST} or croak qq{cannot open MANIFEST};
    my @manifest_files = <$man>;
    close $man;
    # open my $man, q{>>}, q{MANIFEST} or croak qq{cannot open MANIFEST};

    my ($module, $module_name, $module_dir, $version) = &_check_versions(@manifest_files);
    &_wait(q{to detect missing and excess files});
    my %hasherton = &_generate_hash(@manifest_files);

    #draw(\%hasherton);

    #y iterate through all dirs in hash and their anon array values
    #while ( my ($k, $v) = each %hasherton ) { &_check_dir($v,$k,$man); }
    while ( my ($k, $v) = each %hasherton ) { &_check_dir($v,$k); }

    print qq{\n[*] There were no missing or excess files.} if $count == 1;

    &_wait(q{to perform dependency check on Makefile.PL and Build.PL});
    my @lines = &_check_dependencies($module, $module_name);

    &_wait(q{to check line length in verbatim sections of POD});
    &_check_verbatim(@lines);

    &_wait(q{to perform POD syntax check});
    &_check_pod_syntax($module, 2);
    &_wait(q{to perform POD spell check});
    &_check_pod_spelling($module);
    &_wait(q{to perform check module syntax});
    &_check_module_syntax($module);
    #&_wait(q{to tar the module with its version number});
    #my $tar = &tar($module,$version);
    &_wait(q{to run perl Build.PL and ./Build disttest to test the dist and generate META.yml});
    &build();
    &_wait(q{to tar the module using ./Build dist});
    &tar();

    $count = 1; # package-scoped so need to manually re-cycle value
    #close $man;
    return;
}

sub _versions {
    my $module = shift;

    #y version number from README
    my $readme_version;
    if ($readme_version = &_version_numbers_by_regexp(q{README})) { print qq{\n[*] Version number from README is $readme_version } }
    else { print qq{\n[*] There was a problem extracting version number from README}; }

    #y version number form MODULE pod
    my $pod_version;
    if ($pod_version = &_version_numbers_by_regexp($module)) { print qq{\n[*] Version number from module POD is $pod_version } }
    else { print qq{\n[*] There was a problem extracting version number from module POD}; }

    #y version number from $VERSION variable
    my $version_variable;
    if ($version_variable = &_version_variable($module)) { print qq{\n[*] Version number from module \$VERSION variable is $version_variable } }
    else { print qq{\n[*] There was a problem extracting version number from module \$VERSION varialbe}; }

    return ($readme_version, $pod_version, $version_variable);
}

sub _version_numbers_by_regexp {
    my $file = shift;
    open my $fh, q{<}, $file or croak qq{\n[*] There is a problem opening $file};
    while (<$fh>) {
        # use [^$] in case of module file version number description
        if (/version\s+(v?\d+\.\d+.\d+|\d\.\d)\s*/i) {close $fh; return $1 }
    }
    close $fh;
    return 0;
}

sub _version_variable {
    my $file = shift;
    open my $fh, q{<}, $file or croak qq{\n[*] There is a problem opening the module $file};
    while (<$fh>) {
        # use [^$] in case of module file version number description
        #y must be non-greedy matching on . after version - duh
        
        #/ was pulling the pod description version... should check its not in pod but that´s hassle so just check for ;
        #if (/\$VERSION.*?(v?\d+\.\d+.\d+|\d\.\d)\s*/i) {close $fh; return $1 }
        if (/\$VERSION.*?(v?\d+\.\d+.\d+|\d\.\d)\s*.*;/i) {close $fh; return $1 }
    }
    close $fh;
    return 0;
}

sub _array_difference {
        my ($first_ref, $second_ref) = @_;
    my %manifest_= map{$_ =>1} @{$first_ref};
    #my %blah=map{$_=>1} @blah;
    my @only_in_one= grep {!defined $manifest_{$_}} @{$second_ref};
    return @only_in_one;
    
}

sub _check_dir {

    my ($a_ref_contents, $dir_name, $man) = @_;

    my @contents = @{$a_ref_contents};

    opendir my $dir, $dir_name or croak qq{\ncannot open dir $dir_name};
    my @blah = readdir $dir;

    # remove ´.' and '..´
    @blah = grep { $_ !~ /\A\.\.?\z/xms } @blah;
    closedir $dir;

    #print qq{\nlets see - we are in $dir_name and have fh $dir and supposed contents @contents and actual contents @blah};

    #print qq{\n\nWTF\n\n} if (scalar @contents > scalar @blah);

    #/ we must subtract the names - i.e. can´t use numbers of files!!! if there is a real mess... - i.e. excess and missing!!!
    #y so we want files that are in blah that are not in manifest - i.e. already checked for missing stuff.
    my @excess = &_array_difference(\@contents,\@blah);
    my @missing = &_array_difference(\@blah,\@contents);
    #print qq{\n\nin $dir_name\nEXCESS: @excess\nMISSING: @missing\n};

    #if (scalar @contents < scalar @blah) {

    my $base = $dir_name eq q{.} ? q{/} : q{};

    #y/ this goes through all the excess in a dir and then below all the missing...
    if (scalar @excess > 0) {

        #my @only_in_one = &_array_difference(\@contents,\@blah);
        #my %manifest_= map{$_ =>1} @contents;
        #my %blah=map{$_=>1} @blah;
        #my @only_in_one= grep {!defined $manifest_{$_}} @blah;
        #my @only_in_one= grep(!defined $manifest_{$_}, @blah);
        #my @only_in_one = grep { ! grep { } @contents } @blah;
        #print qq{\nThe excess in base dir is }, scalar @only_in_one, qq{ and here they are: @only_in_one\n\n};
        #my $t = $dir_name eq q{.} ? q{/} : q{};


        for my $i (@excess) {

        #/ need full name generation here to check for dirs
        my $name = &_clean_name($dir_name, $base, $i);
            #if ( -d $i ) { &_problem_file_dir($dir_name, $base, $i, q{dir}, q{excess}, $man); 
            #if ( -d $i ) { &_problem_file_dir($dir_name, $base, $i, q{dir}, q{excess}); 
            if ( -d $name ) { &_problem_file_dir($dir_name, $name, $i, q{dir}, q{excess}); 
            }
            #else { &_problem_file_dir($dir_name, $base, $i, q{file}, q{excess}, $man); }
            else { &_problem_file_dir($dir_name, $name, $i, q{file}, q{excess}); }
        }   

    }
    if (scalar @missing > 0) {
    
        for my $i (@missing) {

        #/ need full name generation here to check for dirs
        my $name = &_clean_name($dir_name, $base, $i);

            #y there can be no missing dirs - MANIFEST has only file names
            #if ( -d $i ) { &_problem_file_dir($dir_name, $base, $i, q{dir}, q{missing}); }
            if ( -d $name ) { &_problem_file_dir($dir_name, $name, $i, q{dir}, q{missing}); }
            else { &_problem_file_dir($dir_name, $name, $i, q{file}, q{missing}); }
        }   
    }
}

sub _clean_name {
    my ($dir_name, $base, $file_name) = @_;
    my $name = $dir_name.$base.$file_name;
    $name =~ s/\/\//\//;
    $name =~ s/\A\.\///;
    return $name;
}

sub _problem_file_dir {
    my ( $dir_name, $full_path, $file_name, $type, $status) = @_;
    
    #my $name = $dir_name.$base.$file_name;
    #$name =~ s/\/\//\//;
    
    print qq{\n[$count] There is a $status $type:    \x27$full_path\x27\n};
    $count++;

    my $del = $type eq q{dir} ? q{recursively delete} : q{delete};

    if ($status eq q{excess}) {

        print qq{\nDo you wish to $del the $type (d), append (a) it to the MANIFEST or ignore it (i) or exit (q)? };
        #print qq{\nDo you wish to $del the $type (d), ignore it (i) or exit (q)? };
        PINK:
        while (my $response = <STDIN>) {
            chomp $response;
            last PINK if $response eq q{i};
            if ($response eq q{a}) {

                if ($type eq q{dir}) {
                    print qq{\nThere should be no raw directory names in the MANIFEST};
                    # return;
                    last PINK;
                }
                print qq{\nAre you sure you wish to append file $full_path to MANIFEST? };
                chomp (my $sure = <STDIN>);
                open my $man, q{>>}, q{MANIFEST} or croak qq{\nCannot open MANIFEST for appending};
                #/ never use comma between handle and output - duh!!!
                #print ${man}, qq{$name\n} or croak qq{\nCannot append $name to MANIFEST};
                if ($sure eq q{y}) { print ${man} qq{$full_path\n} or croak qq{\nCannot append $full_path to MANIFEST}; print qq{\nAppending file $full_path to MANIFEST\n}; }
                last PINK;

                #    &_append($name, $type, $manifest_fh);
                #last;
            }
            elsif ($response eq q{d}) {
                print qq{\nAre you sure you wish to $del the $type $full_path? };
                chomp (my $sure = <STDIN>);
                if ($type eq q{dir} and $sure eq q{y}) { system qq{rm -rf $full_path} and carp qq{\nCouldn´t not recursively delete directory $full_path}; }
                elsif ($type eq q{file} and $sure eq q{y}) { unlink $full_path }
                else { print qq{\nDo not recognise that option. Skipping}; }
                last PINK;
            }
            elsif ($response eq q{q}) { exit; }
            else { print qq{\nI don\x27t understand that option. }; }
        }
    }
}

sub _module_name_from_manifest {
    my @modules = @_;
    my $module;
    print qq{\n------------------------------------------------------------\nCHECKING MODULE VERSION NUMBERS\n};
    #y just pull module entry
    #/ eeew, was accidentally using package scoped lexical - never declare lexical at package level (gives many of same probs of globals)
    #my @modules = grep { /(.+\.pm)/  } @manifest_files; # don´t need $_ ~= as // defaults to $_
    @modules = grep { /(.+\.pm)/  } @modules; # don´t need $_ ~= as // defaults to $_
    if (scalar @modules == 0) { croak qq{\n[*] I cannot find a module file in the manifest} }
    elsif (scalar @modules > 1) { croak qq{\n[*] This program only handles directories with a single module file .pm} }
    else { $module = $modules[0]; }
    chomp $module;
    print qq{\n[*] Found module $module};
    my $module_name = $module;
    #y get dir of module file and basic name using greedy matching
    
    #if ($module !~ /(.+\/)(.+)/) { qq{\nProblem getting dir containing module}; } # use greedy matching
    #if ($module !~ /\A(.+\/)/) { qq{\nProblem getting dir containing module} } # use greedy matching
    $module =~ /(.+\/)(.+)/;
    my $inc = $1;

    #my $module_name = $2;
    $module_name =~ s/\Alib\///;
    $module_name =~ s/\//::/gxms; # \z prob- use $?!?

    #y clean name
    $module_name =~ s/\.pm//xms; # \z prob- use $?!?
    return ($module, $module_name, $inc);
}

sub unique {
    my %hash;
    #y use slice - clearly in hash non-unique keys over-write
    @hash{@_} = ();
    return (keys %hash);
}

sub _dir_names_and_contents_to_anon_array {
    my $g = shift;
    my @done;
    my @ddd = $g =~ /(.+?)\//g;
    my $buffer = q{};
    for my $i (0..$#ddd-1) { 
        $buffer .= $ddd[$i].q{/};
        my $next = $i + 1;
        push @done, [$buffer, $ddd[$next]];
    }
    return @done;
}

sub _append {
    my ($name, $type) = @_;
    open my $man, q{>>}, q{MANIFEST} or croak qq{\nCannot open MANIFEST for appending};

    if ($type eq q{dir}) {
        print qq{\nThere should not be raw directory names in the MANIFEST};
        return;
    }
    print qq{\nAppending file $name to MANIFEST};
    
    my $d = qq{wrap\n};
    print ${man} qq{$d};
    print ${man}, qq{$name\n} or croak qq{\nCannot append $name to MANIFEST};

    return;
}

sub _generate_hash {
    my @manifest_files = @_;

    print qq{\n------------------------------------------------------------\nCHECKING FOR EXCESS AND MISSING FILES};
    #y grab all files within subdirs in MANIFEST - i.e. anything with '/´
    my @dirs = grep { /\/.+/ } @manifest_files;
    # just copies for experimenting
    #my @dirs_important = @dirs;

    #y here we get the empty dirs and put them in an array with their sub dirs
    my @nested_dirs_with_sub_dir_in_anon_array;
    for my $i (@dirs) { 
        chomp $i;
        push @nested_dirs_with_sub_dir_in_anon_array, &_dir_names_and_contents_to_anon_array($i);
    }

    #@dirs = map { chomp; /(.+\/)/; $1 } @dirs;

    #my @dirs_unique = &unique(@dirs);
    #@dirs = &unique(@dirs); 

    #y split the dir path (greedy regexp) and the file and put into anon array
    @dirs = map { chomp; /(.+\/)(.+)/; [$1,$2] } @dirs;

    #y merge the two arrays of dir anon arrays
    @dirs = (@nested_dirs_with_sub_dir_in_anon_array, @dirs);

    my %hasherton;
    #y initialise a hash with ALL directories as empty anon arrays - its a hash clearly don´t need to apply unique - prob using slice - i.e. would need a list of equal length of []´s
    #my @full_list_of_dirs = ((map { $_->[0] } @nested_dirs_with_sub_dir_in_anon_array), (map { $_->[0] } @dirs_important));
    #for my $i (@full_list_of_dirs) { $hasherton{$i} = []; }
    for my $i ((map { $_->[0] } @nested_dirs_with_sub_dir_in_anon_array), (map { $_->[0] } @dirs)) { $hasherton{$i} = []; }

    #y now we populate the hash with dirs names as keys and push the contents to the annon array value
    for my $i (@dirs) { push @{$hasherton{$i->[0]}}, $i->[1]; }

    #r very strange remove this and you get probs - can´t be arsed to look at it atm.
    my @probs1;
    for my $file (@manifest_files) { chomp $file; push @probs1, $file if ! -e $file; }
#=fs old - used to use simple -f on manifest contents for missing files - no need the excess files procedure handles these too
#if (scalar @probs1 == 0) { print qq{\nThere are no missing files from MANIFEST} }
#else { 
#    print qq{\nThere are files missing from MANIFEST using old fashioned -f manner of detection};
#    for my $i (0..$#probs1) { my $n = $i + 1; print qq{\n[$n] missing: $probs1[$i]} }
#} 
#=fe
    print qq{\n};

    #y modified @dirs in place so just grab files base - i.e. with files in lower level dirs just grab the route dir
    for (@manifest_files) { if (/(.+?)\/.+/) { $_ = $1 } } # this must be non-greedy!

    #y remove repeats e.g. t/ will have multiple entries due to multiple files
    @manifest_files = &unique(@manifest_files);

    #y add base dir contents to hash
    $hasherton{q{./}} = [@manifest_files];

    #y remove repeats from the merging process?!?
    for my $i (values %hasherton) { @{$i} = &unique(@{$i}); }

    #y FindBin - Locate directory of original perl script

    #print Dumper \%hasherton;

    return %hasherton;
}

#sub tar {
#    my ($tar_name, $version) = @_;
#    print qq{\n------------------------------------------------------------\nCREATING TAR\n};
#    chomp $version;
#    chomp $tar_name;
#    $tar_name =~ s/\Alib\///;
#    $tar_name =~ s/\.pm//xms; # \z prob- use $?!?
#    #my $module = $tar_name;
#    #$tar_name =~ s/\//::/g;
#    $tar_name =~ s/\//-/g;
#    #my $final = qq{$tar_name-$version};
#    my $final = $tar_name.q{-}.$version;
#    #system qq{tar czf ../$tar_name-$version.tar.gz .} and croak qq{\nProblem creating tar file};
#    #print qq{\n[*] Creating tar: tar czf ../$tar_name-$version.tar.gz ../$tar_name};
#    # system qq{tar czf ../$tar_name-$version.tar.gz ../$tar_name} and croak qq{\nProblem creating tar file};
#    print qq{\n[*] BEST TO USE: perl Build.PL; ./Build; ./Build disttest; ./Build dist - dist automatically adds just MANIFEST files to higher level dir in tar so they do not spew out and creates Meta.yml too};
#    return $final;
#    # tar_czf_name-0.0.1.tar.gz_dir
#}

sub build {
    print qq{\n------------------------------------------------------------\nRUNNING Build distest\n};
    system q{perl Build.PL; ./Build disttest} and croak qq{\nCould not run test};
    return;
}

sub tar {
    print qq{\n------------------------------------------------------------\nRUNNING Build dist\n};
    system q{./Build dist} and croak qq{\nCould not tar};
    return;
}

#=fs notes
# seek FILEHANDLE,POSITION,WHENCE
# Sets FILEHANDLE's position, just like the fseek call of stdio . FILEHANDLE may be an expression whose value gives the
# name of the filehandle. The values for WHENCE are 0 to set the new position in bytes to POSITION, 1 to set it to the
# current position plus POSITION, and 2 to set it to EOF plus POSITION (typically negative). For WHENCE you may use the
# constants SEEK_SET , SEEK_CUR , and SEEK_END (start of the file, current position, end of the file) from the Fcntl
# module. Returns 1 upon success, 0 otherwise.
#=fe

#=fs Intersections, unions and differences
## the intersection of @females and @simpsons:
#my @female_simpsons = grep( $simpsons{$_}, @females );
## the difference of @females and @simpsons
#
#my @male_simpsons=grep(!defined $females{$_}, @simpsons);
## the union of @females and @simpsons
#foreach(@females,@simpsons){
#    $union{$_}=1;
#    }
#=fe

sub _check_pod_syntax {
    my ($module, $syn_level) = @_;
    print qq{\n------------------------------------------------------------\nRUNNIGN POD SYNTAX CHECKER\n\n};
    my $checker = Pod::Checker->new(-warnings => $syn_level);    
    #
    #y The POD file path is sent as a command line argument
    #my $pod_file = shift or die "Specify POD file as command line argumentn";    
    #
    #y Create checker object
    #
    #y Parse the POD file, with errors sent to STDERR
    #y $checker->parse_from_file($pod_file, *STDERR);
    $checker->parse_from_file($module, \*STDOUT);
    print qq{\nerrors: }, $checker->num_errors();
    #$checker->poderror;
    return;
}

sub _wait {
    my $mes = shift;
    print qq{\n\nPress carriage return $mes and \x27q\x27 carriage return to exit? };
    while ( my $wait = <STDIN> ) {
        chomp $wait;
        last if $wait eq q{};
        exit if $wait eq q{q};
    }
}

sub _check_pod_spelling {
    my $module = shift;

    print qq{\n------------------------------------------------------------\nRUNNING POD SPELL CHECKER\n};
    print qq{\n\tWARNING: errors of type \x27ERROR: Spurious text after =cut at line x\x27 from syntax checker\n}.
    qq{\t(due to no emtpy line below the \x27=cut\x27 tag) will probably cause spell check to ignore that POD\n}.
    qq{\tsection and give you an incorrect pass result.\n\n};

    print qq{\nAre there any words you wish to ignore from the spell check? Type each one followed by Carriage-Return (Just press carriage return to continue)\n };
    print qq{\nWord to ignore? };

    my @words;

    while ( my $word = <STDIN> ) {
        chomp $word;
        print qq{Word to ignore? };
        last if $word eq q{};
        push @words, $word;
        }

    print qq{\n\nWill ignore words: @words from spell check:\n\n} if scalar @words > 0; 

    #y to ignore words - i.e. could repeat with these?!?
    add_stopwords(@words) if @words > 0;

    #eval {pod_file_spelling_ok($module, 'POD spelling');};
    eval { pod_file_spelling_ok($module, qq{POD spelling on $module}) or croak; };

    return;
}

sub _check_module_syntax {
    my $module = shift;
    print qq{\n------------------------------------------------------------\nCHECKING MODULE SYNTAX\n\n};
    system qq{perl -c $module} and carp qq{\nCould not check syntax};
}

sub _check_versions {
    my @manifest_files = @_;

    #y grab module relative path, full module name and its local dir
    my ($module, $module_name, $module_dir) = &_module_name_from_manifest(@manifest_files);

    #y grab version numbers from README, POD and $VERSION
    my ($readme_version, $pod_version, $version) = &_versions($module);

#=fs old - used to load module and grab $VERSION directly - but have a syntax check later anyway
#/ probably best to change this part to simple regexp rather than using a dirty soft link
#y not sure why getting version number variable by loading module itself and not regexp - except it is also a check for compilation of module 
# push @INC, $module_dir; #push @INC, q{lib/Statistics/MVA}; #use lib q{lib/Statistics/MVA};
#   barewords to require result in auto-appending of .pm and conversion of / to :: - so 
# require $module or croak qq{\nThere appears to be a problem loading the module $module_name - syntax problem?}; # can pass @INC ´.´ and $module_name
#y version number - check first for 3-part type and next for decimal
#   my $module_variable = qq 
# my $symbolic_link = qq{{$module_name}::VERSION};
# $symbolic_link =~ /(\d+\.\d+\.\d+|\d+\.\d+)/xms or croak qq{\nCannot find Version number of moudle};
# my $version = $1;
# print qq{\n[*] Version number from Module \$VERSION varaible is $version};
#=fe

    if ($version eq $readme_version and $version eq $pod_version) { print qq{\n\n[*] Version numbers in Module \$VERSION variable, POD and README match} }
    else { print qq{\n\n[*] PROBLEM: Version numbers in \$VERSION variable, POD and README do not match}; }

    return ($module, $module_name, $module_dir, $version);
}

sub _check_dependencies {
    
    my ($module, $module_name) = @_;

    open my $fh, q{<}, $module or croak qq{\n[*] There is a problem opening $module};
    my @lines = <$fh>;
    close $fh or croak;

    my $which = q{Makefile.PL};
    &slurp_deps($which,$module_name,@lines);

    $which = q{Build.PL};
    &slurp_deps($which,$module_name,@lines);

    #y need to put the difference calc here
    #my $n = scalar @modules;
    #print qq{\n\n[*] $n Module dependencies found\n};

    #for my $i (@modules) {print qq{\n[*] Module requires $i}; }

    # return;
    return @lines;
}

sub slurp_deps {
    my ($which,$module_name,@lines) = @_;
    my @modules;

    for my $i (@lines) { if ( $i =~ /^\s*use\s+([\w\:]+)*;.*$/) { push @modules, $1 } }
    #print qq{\n@modules};

    @modules = &_array_difference([q{warnings},q{strict},$module_name],\@modules);


    open my $fh, q{<}, $which or croak qq{\n[*] There is a problem opening $which};
    my $slurp_readme = do { local $/; <$fh> };
    close $fh or croak qq{Problem closing file};;

    #y don´t bother removing \n it makes the next job more annoying just use ms
    #$slurp_readme =~ s/\n//g;
    #print $slurp_readme;
            
    &_search_deps($slurp_readme,$which, @modules);

    return;
}

sub _search_deps {
    # modules - everything left over - can´t be arsed with a ref
    my ($slurp_readme, $which, @modules) = @_;

    my $prereq_hash_contents;
    

    my $string = $which eq q{Makefile.PL} ? q{PREREQ_PM} : q{requires};
    # use non-greedy to get just the prereq hash contents
    if ($slurp_readme !~ /$string\s*=>\s*\{(.+?)\}/xms) { print qq{\n\n[*] Cannot find $string hash in $which}; return; }
    else {
        print qq{\n\n[*] Found $string hash in $which\n};
        $prereq_hash_contents= $1
    }

    #print $prereq_hash_contents;
    #/ subtract strict, warnings and $module_name in an array from this - thus have the list to ignore

    for my $i (@modules) {
        # greedy matching
        if ($prereq_hash_contents !~ /($i.*)/) { print qq{\n[*] PROBLEM: Module '$i' NOT found in $which hash - are you sure you added the dependencies} }
        else {print qq{\n[*] Module $i found in PREREQ_PM hash: '$1'};}
    }
    return;
}

sub _check_verbatim {
    my @lines = @_;

    my $file_slurped;

    #y sick of this let´s just put the line number into the actual array lines - could sub it out (but why)
    #for (@lines) { $file_slurped .= $_ }
    for (0..$#lines) { my $r = $_+1; $file_slurped .= q{[line: }.$r.q{]: }.$lines[$_] }
    #print $file_slurped;
    my @pods;
    
    #y non-greedy matching!?!
    while ($file_slurped =~ /=head(.+?)=cut\s*/xmsg) { push @pods, $1 }
     
    #print qq{\nhere }, scalar @pods;

    my $flag = 0;

    for my $entry (@pods) {
        my @entry_lines= split qq{\n}, $entry; 
        for my $line (@entry_lines) { 
            #if (length $line > 100) {
            if (length $line > 150 && $line =~ /\A\[line:\s\d{0,4}\]:\s+/) {
                
                #my $position = &_line_number(\@lines,$line);
                print qq{\n[*] Possbile long-line in POD verbatim section\n$line\n};
                $flag = 1;
                #if ($position == -1) { print qq{(problem finding line number):}; }
                #if ($position != -1) { print qq{ at line $position:};}
                #else { print qq{:} }
                #print qq{ \x27$line\x27\n};
            }
        }
    }

    print qq{\n[*] Line length of POD verbatim section seems okay.\n} if $flag == 0;
    return;
}


#sub _line_number {
#    my ($list_ref, $match) = @_;
#    #y need to compile once to speed things up and no x option! - non o here!!!
#    #for my $i (0.. $#{$list_ref}) { return $i if ($list_ref->[$i] =~ /$match/oms); print qq{\n\nhere $i: \x27$match\x27\nhere $i: \x27$list_ref->[$i]\x27}; }
#      
#    for my $i (0.. $#{$list_ref}) {
#        my $r = $i+1; 
#        #print qq{\ntesting\n$list_ref->[$i]\n$match\n}; 
#        my $test = $list_ref->[$i];
#        chomp $test;
#        $match =~ s/\A\s*//;
#        # return $r if ($list_ref->[$i] =~ /$match/ms); }
#        
#
#        return $r if ($test =~ /$match/); }
#    #for my $i (0.. $#{$list_ref}) { chomp $i; return $i if ($list_ref->[$i] eq $match); }
#    return -1;
#}

# open(F, '>/dev/null');
# *STDOUT = *F;

1; # Magic true value required at end of module
__END__

=head1 DEPENDENCIES
'Carp'              => '1.08',
'Pod::Checker'      => '1.45',
'Test::More'        => '0.94',
'Test::Spelling'    => '0.11',

=cut

=head1 BUGS

Let me know.

=cut

=head1 TO DO

Have a options to skip steps. Use a more powerful tar mechanism. Extract POD using proper module tools and not regexps.

=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cantab.net> >>

=cut

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut
