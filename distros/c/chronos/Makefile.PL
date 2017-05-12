# $Id: Makefile.PL,v 1.4 2002/08/27 18:52:37 nomis80 Exp $
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# How to check for Apache::DBI provided by Stas Bekman <stas@stason.org>
my %prereq = (
    'Apache'            => 0,
    'Apache::Constants' => 0,
    'Apache::Request'   => 0,
    'Date::Calc'        => 0,
    'DBI'               => 0,
    'DBD::mysql'        => 0,
    'HTML::Entities'    => 0,
    'URI::Find'         => 0,
);

# Manually test whether Apache::DBI is installed and add it to the
# PREREQ_PM if it's not installed, so CPAN.pm will automatically fetch
# it. If Apache::DBI is already installed it will fail to get loaded by
# MakeMaker because it requires the mod_perl environment to load. 
eval { require Apache::DBI };
if ( $@ and $@ !~ /Can't locate object method/ ) {
    $prereq{Apache::DBI} = '';
}

WriteMakefile(
    'NAME'         => 'Chronos',
    'VERSION_FROM' => 'Chronos.pm',                  # finds $VERSION
    'PREREQ_PM'    => \%prereq,
    'EXE_FILES'    => [ grep { -f } <scripts/*> ],
);

sub MY::install {
    package MY;
    my $inherited = shift->SUPER::install(@_);
    $inherited =~ s/^(install ::.*)/$1 lang_install html_install/m;
    $inherited =~ s/^(uninstall ::.*)/$1 lang_uninstall html_uninstall/m;
    return $inherited;
}

sub MY::postamble {
    my $langfiles = join " ", grep { -f } <lang/*>;
    my @html_files = grep { -f } <html/*>;
    my $html_files = join " ", @html_files;
    s/html\/// foreach @html_files;
    my $html_files2 = join " ",
      map { "\$(PREFIX)/../var/www/ssl/chronos/$_" } @html_files;

    my $return = <<EOF;
lang_install:
	mkdir -p \$(PREFIX)/share/chronos/lang
	install -m 644 $langfiles \$(PREFIX)/share/chronos/lang

html_install:
	mkdir -p \$(PREFIX)/../var/www/ssl/chronos_static
	install -m 644 $html_files \$(PREFIX)/../var/www/ssl/chronos_static

lang_uninstall:
EOF
    $return .= "\trm -f "
      . ( join " ", map { "\$(PREFIX)/share/chronos/$_" } grep { -f } <lang/*> )
      . "\n";
    $return .= <<EOF;

html_uninstall:
	rm -f $html_files2
EOF
    return $return;
}
