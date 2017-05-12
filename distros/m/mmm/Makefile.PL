use 5.008;
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;

Getopt::Long::Configure(qw(pass_through));

my ($localstatedir, $sysconfdir) = qw(/var/lib /etc);

my @pod_in = qw(
    lib/mmm.cfg.pod
    lib/mmm-doc.pod
    );

my @config_in = qw(
    lib/MMM/Config.pm
    config/mmm.cfg
    );

my @files_in = (
    @pod_in,
    @config_in,
);

my @exefiles = qw(bin/mmm bin/mmmd bin/mmmb bin/mmm_status);
my %www_list = ();
foreach my $src (@pod_in, @exefiles) {
    my $dest = $src;
    $dest =~ s/\.pod$//;
    $www_list{$src} = 'www/' . $dest . '.html';
}

GetOptions(
    'localstatedir=s' => \$localstatedir,
    'sysconfdir=s'    => \$sysconfdir,
);

foreach my $file_in (@files_in) {
    open(my $hin, '<', $file_in . '.in') or die "missing lib/MMM/Config.pm.in\n";
    open(my $hout, '>', $file_in) or die "Cannot open lib/MMM/Config.pm: $!\n";
    print $hout <<EOF;
# This file is generated from $file_in.in
# Please change this file instead
EOF
    while (my $line = <$hin>) {
        $line =~ s/\@LOCALSTATEDIR@/$localstatedir/g;
        $line =~ s/\@SYSCONFDIR@/$sysconfdir/g;
        print $hout $line;
    }
    close($hin);
    close($hout);
}
if(($ARGV[0] || '') eq 'inonly') { exit(0); }

WriteMakefile(
    NAME	 => 'mmm',
    AUTHOR   => 'Olivier Thauvin <nanardon@nanardon.zarb.org>',
    VERSION_FROM => 'lib/MMM.pm',
    EXE_FILES => [ @exefiles ],
    # DIR => [ qw(doc/talk) ],
    PREREQ_PM => {
        'XML::Simple' => undef,
        'Config::IniFiles' => undef,
        'IO::Select' => undef,
        'File::Temp' => undef,
        'URI' => undef,
        'Digest::MD5' => undef,
        'CGI' => undef,
        'WWW::HostipInfo' => undef,
        'Net::DNS' => undef,
        'Mail::Send' => undef,
        'Digest::MD5' => undef,
        'Date::Calc' => undef,
    }
);

package MY;

sub constants {
    my $fin = join(' ', @files_in);
    <<EOF
LOCALSTATEDIR = $localstatedir
SYSCONFDIR = $sysconfdir
FILES_IN = $fin
POD2HTML_EXE = pod2html\$(EXE_EXT)
POD2HTML = \$(POD2HTML_EXE)

EOF
    . shift->SUPER::constants(@_)
}

sub clean {
    shift->SUPER::clean(@_) .
    "\t\$(RM) -f \$(FILES_IN)\n",
}

sub postamble {
    return join('', map
        { "$_ : $_.in\n\t\$(PERLRUN) Makefile.PL inonly\n\n" }
        @files_in
    ) .
    join('', map
        { 
            "$www_list{$_} : $_ Makefile www/bin/.exists www/lib/.exists\n" .
            "\t" . '$(POD2HTML) --htmlroot .. --podpath bin:lib --infile $< --outfile $@' . "\n\n"
        }
        keys %www_list
    ) . 
    sprintf("www : Makefile %s\n\n", join(' ', values(%www_list))) .
    "
www/bin/.exists :: Makefile.PL
\t\$(NOECHO) \$(MKPATH) www/bin
\t\$(NOECHO) \$(CHMOD) 755 www/bin
\t\$(NOECHO) \$(TOUCH) www/bin/.exists

www/lib/.exists :: Makefile.PL
\t\$(NOECHO) \$(MKPATH) www/lib
\t\$(NOECHO) \$(CHMOD) 755 www/lib
\t\$(NOECHO) \$(TOUCH) www/lib/.exists

mymanifest :
\tdarcs query manifest | sed 's:^./::' | sort > MANIFEST
";
}

