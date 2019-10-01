# Copyright (c) 1997-2002 XAO Inc.
###############################################################################
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

##
# Reading configuration
#
my %d;
if(open(F,'.config')) {
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
}
while(!$d{test_dsn}) {
    print <<EOT;

XAO Content will need access to a XAO::FS database in order to run tests.
That database will be COMPLETELY DESTROYED AND OVERRIDEN every time you
run 'make test'.

The database have to be created, but it does not matter what it contains.

Please enter access information (brackets contain default values), entering
'none' will disable tests:

EOT
    my $dsn=prompt('DSN:','none');

    $dsn eq 'none' || $dsn =~ /^\s*(OS:(\w+):(\w+)(;.*?)?)\s*$/ ||
        die "Incorrect DSN entered!\n";

    my $user='';
    my $pass='';
    my $confirm='n';

    if($dsn eq 'none') {
        $confirm='y';
        print <<EOT;

Ok, tests will be skipped per your request.

EOT
    }
    else {
        chomp(my $default_user=`whoami`);
        $user=prompt('User name:',$default_user);
        $pass=prompt('Password:','');

        print <<EOT;

Here is what will be used to connect to the test database
(and DESTROY it):
   DSN:      $dsn
   User:     $user
   Password: $pass

EOT

        $confirm=prompt('Does it make sense ?','y');
    }

    if(!$confirm || lc($confirm)=~/y/) {
        open(F,">.config") || die "Can't open .config: $!\n";
        print F <<EOT;
## Feel free to remove or edit that file. It will be re-created on `perl
## Makefile.PL' if removed.
\$d{test_dsn}='$dsn';
\$d{test_user}='$user';
\$d{test_password}='$pass';
EOT
        last;
    }
}

WriteMakefile(
    'AUTHOR'         => 'Andrew Maltsev, http://ejelta.com/xao/',
    'ABSTRACT'       => 'XAO::Web plugin for managing dynamic content',
    'NAME'           => 'XAO::DO::Web::Content',
    'DISTNAME'       => 'XAO-Content',
    'VERSION_FROM'   => 'Content.pm',
    'PREREQ_PM'      => {
        'XAO::FS'       => '1.03',
        'XAO::Web'      => '1.03',
    }
);

sub MY::postamble
{ <<EOT;
config::	README

README:	Content.pm
	\@COLUMNS=80 pod2text Content.pm > README

install::
	\$(PERL) -MXAO::PluginUtils=install_templates \\
		 -e'install_templates("MANIFEST",1)'
	\@echo
	\@echo "Please read the XAO::DO::Web::Content manpage"
	\@echo "for usage instructions."
	\@echo
	\@echo "Good luck!"
	\@echo
EOT
}
