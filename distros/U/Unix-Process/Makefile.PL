# vi:set syntax=perl:

use ExtUtils::MakeMaker;

my $ps = $ENV{PS_PATH} || "/bin/ps";

my $worked = 0;
if( -x $ps ) {
    if( open my $in, "$ps -o pid -p $$|" ) {
        while(<$in>) {
            $worked = 1 if m/^\s*$$\s*$/;
        }
        close $in;
    }
}

unless( $worked ) {
    warn "this module assumes you have a ps program in /bin/ps\n";
    warn "you can override it by setting an environment variable,\n";
    warn "  e.g. PS_PATH=/usr/local/bin/ps; export PS_PATH\n";
    exit 0;
}

WriteMakefile(
    NAME         => 'Unix::Process',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
    VERSION_FROM => 'Process.pm',
    PREREQ_PM    => { 
        'IPC::System::Simple' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'?
        (MIN_PERL_VERSION => 5.008,
            META_MERGE => {
                keywords => [qw(ps process unix)],
                resources=> {
                    repository => 'http://github.com/jettero/unix--process',
                },  
            },  

        LICENSE => 'lgpl',
    ) : ()),
);
