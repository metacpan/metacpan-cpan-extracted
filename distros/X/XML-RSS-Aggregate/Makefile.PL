#!/usr/bin/perl
# $File: //member/autrijus/XML-RSS-Aggregate/Makefile.PL $ 
# $Revision: #1 $ $Change: 2920 $ $DateTime: 2002/12/25 14:43:18 $

# This Makefile.PL creates a pass-through Makefile that simply calls
# the equivalent Module::Build methods for each make target.  See the
# documentation for Module::Build::Compat for more information.

unless (eval "use Module::Build::Compat 0.02; 1" ) {
    require Cwd;
    require File::Spec;
    require ExtUtils::MakeMaker;

    my $yn = '';
    # Check if we're likely to have permission to install Module::Build
    if (-w $INC{'ExtUtils/MakeMaker.pm'}) {
        # Check if we're under the non-reentrant CPAN.pm
        require CPAN;
        CPAN::Config->load;

        my $cwd  = File::Spec->canonpath(Cwd::cwd());
        my $cpan = File::Spec->canonpath($CPAN::Config->{cpan_home});
        if (index($cwd, $cpan) == -1) {
            print "This module requires Module::Build to install itself.\n";

            $yn = ExtUtils::MakeMaker::prompt(
                '  Install Module::Build from CPAN?', 'y'
            );
        }
    }

    if ($yn =~ /^y/i) {
        # Save this 'cause CPAN will chdir all over the place.
        my $cwd = Cwd::cwd();
        my $makefile = File::Spec->rel2abs($0);

        if (eval { require CPANPLUS::Backend; 1 }) {
            CPANPLUS::Backend->new->install(
                modules => [ 'Module::Build' ]
            );
        }
        else {
            require CPAN;
            CPAN::Shell->install('Module::Build::Compat');
        }

        chdir $cwd or die "Cannot chdir() back to $cwd: $!";
        exec $^X, $makefile, @ARGV;  # Redo now that we have Module::Build
    } else {
        warn << '.';
This module requires Module::Build to install itself.
Please re-run Makefile.PL with root privilege to install it
automatically from CPAN, or manually download it from:

    http://search.cpan.org/author/KWILLIAMS/Module-Build/

.
        # Leave hints for CPAN.pm and CPANPLUS.pm
        ExtUtils::MakeMaker::WriteMakefile(
            PREREQ_PM   => { 'Module::Build' => 0.11 }
        );

        exit(0);
    }
}

Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();

__END__
# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
