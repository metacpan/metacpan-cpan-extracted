use inc::Module::Install;

name 'Vote';
all_from 'lib/Vote.pm';

requires 'Catalyst' => '5.7015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;

package MY;

sub distdir {
    my $dist = shift->SUPER::distdir(@_);
    $dist =~ s/^(create_distdir :.*)/$1 md5sum/m;
    $dist
}

sub dist_core {
    my $dist = shift->SUPER::dist_core(@_);
    $dist =~ s/^(\S.* :.*)/$1 md5sum/mg;
    $dist
}

sub postamble {
    return "

md5sum:
\tcat MANIFEST | sed 's/\\t.*//' | grep -v control/md5sum | xargs md5sum > control/md5sum

checkmd5:
\tmd5sum -c control/md5sum

.PHONY: md5sum checkmd5

ChangeLog:
\tsvn log > ChangeLog

epoll.spec: epoll.spec.in Makefile
\tsed -e 's/\@VERSION@/\$(VERSION)/' < \$< > \$@

rpm: \$(DISTVNAME).tar.gz epoll.spec
\tmkdir ./noarch || :
\trpmbuild -ba --clean\\
\t --define \"_sourcedir `pwd`\" \\
\t --define \"_specdir `pwd`\" \\
\t --define \"_srcrpmdir `pwd`\" \\
\t --define \"_rpmdir `pwd`\" \\
\t epoll.spec
"
}
