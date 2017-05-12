#!/bin/zsh

function die { echo 1>&2 $*; exit 1 }

zmodload -i zsh/parameter

typeset -A repository
repository=(
    sf  http://yatt-pm.svn.sourceforge.net/svnroot
    bb  https://buribullet.net/svn
)

typeset -A repo_url
repo_url=(
    stable $repository[sf]/yatt-pm/trunk/yatt-pm
    devel  $repository[bb]/yatt-pm
)

INSTALL_MODE=${INSTALL_MODE:-stable}

function main {
    precheck || return 1
    
    local url e
    url=$repo_url[$INSTALL_MODE]
    if [[ $PWD == */cgi-bin ]]; then
	echo Installing into existing cgi-bin "($PWD)" ...
	# XXX: If $PWD is not writable, sudo to owner of $PWD.
	svn -q co $url yatt.co
	for e in cgi lib docs tmpl; do
	    ln -s yatt.co/web/cgi-bin/yatt.$e .
	done
	echo Please make sure $PWD is allowed to run CGI.
	echo See \'Options +ExecCGI\' in Apache manual.
    else
	if [[ -d cgi-bin ]]; then
	    die Sorry, you already have cgi-bin. Please retry in $PWD/cgi-bin.
	fi
	echo Creating new cgi-bin...
	svn -q co $url/web/cgi-bin
	add_apache_htaccess
	add_sample
    fi
}

function precheck {
    setopt err_return
    (($+commands[svn]))
}

function add_apache_htaccess {
    local url_base
    if [[ $PWD == $HOME/(public_html|Sites)/* ]]; then
	url_base=/~$USER${PWD#$HOME/*}
	echo Making sure it does not violate suexec policy.
	chmod -R g-w cgi-bin
    else
	url_base=${PWD#/var/www/html}
    fi

    {
	echo Modifying .htaccess ...
	cat <<-EOF >> .htaccess
	Action x-yatt-handler $url_base/cgi-bin/yatt.cgi
	AddHandler x-yatt-handler .html
	EOF
    }
}

function add_sample {
    local fn
    fn=index.html
    if [[ -r $fn ]]; then
	echo "(skipping $fn)"
    else
	echo Adding sample index.html ...
	cat <<-EOF > index.html
	<html>
	<head><title>YATT install result</title></head>
	<body>
	<h2><yatt:if "0">Install failed!</yatt:if><yatt:ok/></h2>
	</body></html>
	
	<!yatt:widget ok>
	<?perl=== "YATT works fine!"?>
	EOF
    fi
}

# XXX: option based dispatch of each action.

{ main "$@" } always {
    if (($TRY_BLOCK_ERROR)); then
	die "Install failed!"
    else
	echo OK!
    fi
}
