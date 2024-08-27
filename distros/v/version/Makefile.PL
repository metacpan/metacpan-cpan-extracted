# This Makefile.PL stolen from Params::Validate
#
# The perl/C checking voodoo is stolen from Graham Barr's
# Scalar-List-Utils distribution.

use strict;

use Config qw(%Config);
use ExtUtils::MakeMaker;
use File::Temp qw/tempdir tempfile/;

if ($] < 5.006002) {
    die <<'EOL'
Perl 5.006002 required.  Please install version-0.9906 if you need
to support an earlier Perl release.
EOL
}

my ($no_xs, $force_xs);

unlink 'pm_to_blib'; # belts and braces

if ($ENV{PERL_ONLY}) {
    $no_xs = 1;
}

for (@ARGV)
{
    /^--perl_only/ and $no_xs = 1;
    /^--perl-only/ and $no_xs = 1;
    /^--xs/ and $force_xs = 1;
}

if ($] < 5.010) { # support pure Perl only
    $no_xs = 1;
}

unless (defined $no_xs or $force_xs)
{
    check_for_compiler()
        or no_cc();

}

write_makefile();

sub write_makefile
{
    my %test_prereq = (
        'Test::More'            => 0.45,
        'File::Temp'            => 0.13,
        'base'                  => 0,
    );

    WriteMakefile( VERSION         => '0.9933',
                   NAME            => 'version',
                   LICENSE         => 'perl',
                   MIN_PERL_VERSION=> 5.006002,
                   TEST_REQUIRES   => \%test_prereq,
                   NORECURS        => $no_xs,
                   ABSTRACT    => 'Structured version objects',
                   AUTHOR      => 'John Peacock <jpeacock@cpan.org>',
                   ( $] >= 5.009001 && $] < 5.011000 ?
                     ( INSTALLDIRS => 'perl' ) :
                     ()
                   ),
		   ( ($] < 5.012
		       && ! $ENV{PERL_NO_HIGHLANDER}
		       && ! ( $ENV{PERL_MM_OPT}
			   && $ENV{PERL_MM_OPT} =~ /(?:INSTALL_BASE|PREFIX)/ )
		       && ! grep { /INSTALL_BASE/ || /PREFIX/ } @ARGV ) ?
		     ( UNINST => 1 ) :
		     ()
		   ),
                   PM              =>
                       {'lib/version.pm'  => '$(INST_LIBDIR)/version.pm',
                        'lib/version.pod' => '$(INST_LIBDIR)/version.pod',
                        'lib/version/regex.pm'  =>
                            '$(INST_LIBDIR)/version/regex.pm',
                        'lib/version/Internals.pod' =>
                            '$(INST_LIBDIR)/version/Internals.pod',
                        'vperl/vpp.pm' => '$(INST_LIBDIR)/version/vpp.pm',
                        },
                   PL_FILES        => {},
                   C               => [],
		   ( $no_xs ?
		       () :
		       ( DIR       => ['vutil'])
		   ),
                   dist            => {
                       COMPRESS => 'gzip -9f',
                       SUFFIX => 'gz',
                   },
                   META_MERGE => {
                       "meta-spec" => { version => 2 },
                       resources => {
                           repository => {
                               type => 'git',
                               url => 'git://github.com/Perl/version.pm.git',
                               web  => 'https://github.com/Perl/version.pm',
                           },
                           bugtracker => {
                               web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=version',
                               mailto => 'bug-version@rt.cpan.org',
                           },
                       },
                       no_index => {
                           package => ['charstar'],
                       },
                   },
                 );
}

sub no_cc
{
    $no_xs = 1;
    print <<'EOF';

 I cannot determine if you have a C compiler
 so I will install a perl-only implementation

 You can force installation of the XS version with

    perl Makefile.PL --xs

EOF

}

sub check_for_compiler
{
    # IMPORTANT NOTE:  This is NOT used to determine how to compile
    # extensions properly; EU::MM does that for us.  This is only
    # intended to see if that is likely to succeed.  We do not try
    # to do anything here except compile (not even link).  If you
    # want this to be a full featured test, feel free to submit a
    # patch or do something useful.

    print "Testing if you have a C compiler\n";

    eval { require ExtUtils::CBuilder };
    if ($@)
    {
        return _check_for_compiler_manually();
    }
    else
    {
        return _check_for_compiler_with_cbuilder();
    }
}

sub _check_for_compiler_with_cbuilder
{
    my $cb = ExtUtils::CBuilder->new( quiet => 1 );

    return $cb->have_compiler;
}

sub _check_for_compiler_manually
{
    unless ( open F, ">test.c" )
    {
        warn "Cannot write test.c, skipping test compilation and installing pure Perl version.\n";
        return 0;
    }

    print F <<'EOF';
int main() { return 0; }
EOF

    close F or return 0;

    my ($cc, $ccflags, $obj_ext) = map { $Config{$_} } qw/cc ccflags obj_ext/;

    my $command;
    if ($^O =~ /(dos|win32)/i && $Config{'cc'} =~ /^cl/) {
        $command = "$cc $ccflags /c test.c";
    }
    elsif ($Config{gccversion}) {
        $command = "$cc $ccflags -o test$obj_ext test.c";
    }
    else {
        warn "Unsupported system: can't test compiler availability. Patches welcome...";
        return 0;
    }

    my $retval = system( $command );
    map { unlink $_ if -f $_ } ('test.c',"test$obj_ext");

    return not($retval); # system returns -1
}
