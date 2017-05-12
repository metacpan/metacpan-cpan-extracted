# =============================================================================
# $Id: Win32-PerlExe-Env.pl 489 2006-09-09 20:07:31Z HVRTWall $
# Copyright (c) 2005-2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
# Test program for Win32::PerlExe::Env
# ==============================================================================

    use strict;
    use warnings;

    my $progname = $0;
    $progname =~ s|.*\\||;      # use basename only
    $progname =~ s|\.\w*$||;    # strip extension

    my $select   = $ARGV[0] || ':DEFAULT';
    my $filename = $ARGV[1] || 'PerlExe';

    print "Runs as '$progname $select $filename'\n";
    &usage unless ( my $vars ) = ( $select =~ /:(tmp|vars|all|DEFAULT)/ );

    use lib '../lib';                            # use distribution
    eval "use Win32::PerlExe::Env '$select'";    # module required dyn.
    die $@ if $@;

    print "Version '$Win32::PerlExe::Env::VERSION' [Win32::PerlExe::Env]\n";

    use Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;

    # -- Select names
    push my @names,

        $vars eq 'tmp'
        ? qw(tmpdir filename)

        : $vars eq 'vars' ? qw(BUILD PERL5LIB RUNLIB TOOL VERSION)

        : $vars eq 'all'
        ? qw(tmpdir filename BUILD PERL5LIB RUNLIB TOOL VERSION)

        # -- Default
        : qw(tmpdir);

    # -- Run selected functions
    my %vars = ( map { uc $_ => eval "get_$_(\$filename)" } map {lc} @names );
    die $@ if $@;

    print "Result is " . Data::Dumper->Dump( [ \%vars ], [$vars] );

    sub usage {
        die <<"EOT";
Test of Win32::PerlExe::Env
Option '$select' is unknown
Usage: $progname [:select] [filename]
    :tmp            Print tmpdir and filename (of default file)
    :vars           Print BUILD, PERL5LIB, RUNLIB, TOOL and VERSION
    :all            Print :tmp and :vars
    :DEFAULT        Print tmpdir
    filename        Use filename to extract bound file to identify tmpdir
    
    Defaults
        No select   Set :select to ':DEFAULT'
        No filename Set filename to defaults 'Win32|PerlExe|Env' 
EOT
    }

=pod

=head1 NAME

Win32-PerlExe-Env.pl -- Test program for Win32::PerlExe::Env

=head1 USAGE

    win32: Win32-PerlExe-Env.exe 
    win32: Win32-PerlExe-Env.exe :tmp 
    win32: Win32-PerlExe-Env.exe :tmp Win32
    win32: Win32-PerlExe-Env.exe :vars
    win32: Win32-PerlExe-Env.exe :all 
    win32: Win32-PerlExe-Env.exe :all Env
    win32: Win32-PerlExe-Env.exe :DEFAULT
    win32: Win32-PerlExe-Env.exe :DEFAULT Copyright
    
=head1 OPTIONS

    Win32-PerlExe-Env [selection] [filename]

=over 2

=item :tmp

Print tmpdir and filename (of default internal file)
    
=item :vars

Print BUILD, PERL5LIB, RUNLIB, TOOL and VERSION
    
=item :all

Print :tmp and :vars

=item :DEFAULT

Print tmpdir
    
=item filename

Use as bound file to identify tmpdir
    
=item Missing selection

Set selection to :DEFAULT

=item Missing filename

Set filename to defaults 'Win32|PerlExe|Env'

=back

=head1 DESCRIPTION

Test program for Win32::PerlExe::Env.

See also F<exe/Win32-PerlExe-Env.bat> of this distribution. 

=head1 DIAGNOSTICS

An Usage message is given if unkown options were supplied.

=head1 CONFIGURATION AND ENVIRONMENT

This distribution contains an executable Win32-PerlExe-Env.exe which
was packed with ActiveState PDK PerlApp 6.0.2. The size was optimized
with packer options set to 'Make dependent executable' and
'Exclude perl58.dll from executable'. To run this executable properly a
Win32 Perl Distribution (e. g. ActivePerl) must be installed.
    
This executable uses at runtime the local (uninstalled!) module
Win32::PerlExe::Env from the lib directory of this distribution.

You are welcome to pack you own freestanding executable which can run on
every (Perl free) Win32 platform.

=head1 DEPENDENCIES

L<Win32::PerlExe::Env>

=head1 INCOMPATIBILITIES

No known alternative denials.

=head1 BUGS

Only tested on Win32 XP.

Send bug reports to my email address or use the CPAN RT system.

=head1 AUTHOR

Thomas Walloschke E<lt>thw@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Thomas Walloschke (thw@cpan.org).All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DATE

Last changed $Date: 2006-09-09 22:07:31 +0200 (Sa, 09 Sep 2006) $.

=cut

