
# $Id: Makefile.PL,v 1.0 2001/10/30 13:57:31 dada Exp $

use ExtUtils::MakeMaker qw/ WriteMakefile/;

# Must be a better way to do this, surely...
use Config;

my $is_64bit_build = ($Config{ptrsize} == 8);
my $is_msvc_compiler = ($Config{cc} =~ /cl/);

sub GS_flag {
    if($is_msvc_compiler
       && Win32::API::Test::compiler_version_from_shell() >= 14 ) {
        return ' -GS- ';
    }
    else {
        return '';
    }
}

sub no_stackprotector {
    if(!$is_msvc_compiler && $is_64bit_build) {
        return ' -fno-stack-protector ';
    } else {
        return '';
    }
}

package MY;

sub cflags {
    my($self) = shift;
    my $dlib = $self->SUPER::cflags(@_);
    my $pos = index($dlib,'CCFLAGS = ',0);
    die "bad CCFLAGS match" if $pos == -1;
    my $len = $pos+length('CCFLAGS = ');
    $dlib = substr($dlib, 0, $len)
        .main::GS_flag()
        .substr($dlib, $len, length($dlib)-$len);
    $dlib =~ s/(^OPTIMIZE = .+)$/$1 ${\main::no_stackprotector()}/m;
    return $dlib;
}

package main;

    WriteMakefile(
        'NAME'	=> 'Win32::API::Callback',
        ($] < 5.005 ? () : (
                'AUTHOR'        	=> 'Aldo Calpini <dada@perl.it> Daniel Dragan <bulkdd@cpan.org>',
                'ABSTRACT'      	=> 'Perl Win32 API Import Facility',
        )),
        'VERSION_FROM' => '../API.pm',
        'dist'	=> {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
         TYPEMAPS => [($] > 5.007000 ? () : '../typemap56'), '../TYPEMAP'],
    );

