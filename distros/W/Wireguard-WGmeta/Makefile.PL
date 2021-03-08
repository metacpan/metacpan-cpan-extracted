use v5.20.0;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

sub get_version() {
    open my $fh, 'VERSION';
    chomp(my $v = <$fh>);
    close $fh;
    return $v;
}

my $version = get_version();

WriteMakefile(
    NAME           => 'Wireguard::WGmeta',
    VERSION        => $version,
    ABSTRACT       => 'An approach to add metadata to the main Wireguard config',
    AUTHOR         => 'Tobias Bossert <tobib at cpan.org>',
    LICENSE        => 'mit',
    PREREQ_PM      => {},
    BUILD_REQUIRES => {},
    MAKE           => 'gmake',
    EXE_FILES      => [
        "bin/wg-meta"
    ],
    META_MERGE     => {
        requires  => { perl => '5.020000' },
        resources => {
            license    => 'https://opensource.org/licenses/mit',
            repository => 'https://github.com/sirtoobii/wg-meta',
            bugtracker => 'https://github.com/sirtoobii/wg-meta/issues'
        },
        no_index  => { directory => [ 't' ] }
    },
    test           => { TESTS => 't/*.t' }
);

sub MY::postamble {
    my $self = shift;
    return <<"EOF";

VERSION_FILES := \$(shell grep -Rl 'our \$\$VERSION = ' .)
\$(VERSION_FILES): VERSION
	\$(PERL) -i -p -e 's/\$VERSION\\s*=\\s*"[\\d|\.]*[A-z]*"/\$VERSION = "\$(VERSION)"/;' \$\@

# # Unfortunately, this is (gnu-)make specific...
# ifeq (\$(EDITOR),)
# EDITOR=/usr/bin/vi
# endif

CHANGES: VERSION
	echo $self->{VERSION} `date +"%Y-%m-%d %H:%M:%S %z"` `git config user.name` '<'`git config user.email`'>' >> CHANGES.new
	\@echo >> CHANGES.new
	\@echo ' -' >> CHANGES.new
	\@echo >> CHANGES.new
	\@cat CHANGES >> CHANGES.new && mv CHANGES.new CHANGES
	\$(EDITOR) CHANGES

EOF
}
