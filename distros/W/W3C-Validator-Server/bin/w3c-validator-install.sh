#!/bin/sh

ACTION=$1;

if [ "x$ACTION" = "x" ]; then
    echo "
Usage:

    $0 all

    # install libraries. Require sudo, apt-get and cpanm
    $0 libs

    # fetch files from http://validator.w3.org
    $0 files

    # rewrite config to defaults
    $0 config
";

    exit;
fi

if [ "x$W3C_HOME" != "x" ]; then
    DST="$W3C_HOME";
    mkdir -p $DST;
    echo "Installing to $DST ...";
elif [ -e 'Makefile.PL' ]; then
    DST=".";
    echo "Installing to current directory ...";
else
    DST="$HOME/.w3c-validator-server";
    mkdir -p $DST;
    echo "Installing to $DST ...";
fi

cd $DST;
echo "Working dir is $PWD";

if [ "x$ACTION" = "xall" -o "x$ACTION" = "xlibs" ]; then
    echo "Installing libraries as root";
    sudo apt-get install \
        opensp \
        libsgml-parser-opensp-perl \
        libhtml-tidy-perl \
        ;

    cpanm --sudo Bundle::W3C::Validator
fi

if [ "x$ACTION" = "xall" -o "x$ACTION" = "xfiles" ]; then
    echo "Fetching files from http://validator.w3.org";
    for d in "validator" "sgml-lib"; do
        f="$d.tar.gz";
        [ -e $f ] || wget "http://validator.w3.org/$f";
        echo "Got $f";
        tar xfz $f;
    done

    rsync -a validator*/htdocs root/;
    rsync -a validator*/httpd/cgi-bin root/;
    rsync -a validator*/share/templates root/;

    mv root/htdocs/config config && echo "Set up $DST/config/";
    rm -rf root/sgml-lib
    mv root/htdocs/sgml-lib root/sgml-lib && echo "Set up $DST/root/sgml-lib/";

    perl -pi -e'
        s,(\@import ".*style/\w+)",$1.css",;
    ' root/htdocs/*html root/templates/en_US/*tmpl
    echo "Rewrote '@import style/foo.css' statements";
fi

if [ "x$ACTION" = "xall" -o "x$ACTION" = "xconfig" ]; then
    echo "Rewriting config/validator.conf";
    perl -pi -e'
        s,#*Base\s*.*,Base = $ENV{PWD},;
        s,#*Templates\s*=.*,Templates = \$Base/root/templates,;
        s,#*TidyConf\s*=.*,TidyConf = \$Base/config/tidy.conf,;
        s,#*Library\s*=.*,Library = \$Base/root/sgml-lib,;
        s,#Allow Private IPs = .*,Allow Private IPs = yes,;
    ' config/validator.conf;
fi

exit 0;
