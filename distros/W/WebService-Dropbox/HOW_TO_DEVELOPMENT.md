
## 開発環境を作る

```sh
export MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion | cut -d. -f-2)
xbuild/perl-install 5.26.0 ~/local/perl-5.26
export PATH=/Users/aska/local/perl-5.26/bin:$PATH
carton install
> Installing modules using /Users/aska/Documents/Perl/p5-WebService-Dropbox/cpanfile
> Successfully installed Module-Build-0.4218
> Successfully installed ExtUtils-Config-0.008
> Successfully installed ExtUtils-InstallPaths-0.011
> Successfully installed ExtUtils-Helpers-0.026
> Successfully installed Module-Build-Tiny-0.039
> Successfully installed Test-Simple-1.302085 (upgraded from 1.302073)
> Successfully installed Net-SSLeay-1.74
> Successfully installed Mozilla-CA-20160104
> Successfully installed IO-Socket-SSL-2.029
> Successfully installed URI-1.71
> Successfully installed Net-HTTP-6.09
> Successfully installed HTML-Tagset-3.20
> Successfully installed HTML-Parser-3.72
> Successfully installed LWP-MediaTypes-6.02
> Successfully installed Encode-Locale-1.05
> Successfully installed HTTP-Date-6.02
> Successfully installed IO-HTML-1.001
> Successfully installed HTTP-Message-6.11
> Successfully installed HTTP-Daemon-6.01
> Successfully installed HTTP-Cookies-6.01
> Successfully installed Try-Tiny-0.28
> Successfully installed File-Listing-6.04
> Successfully installed HTTP-Negotiate-6.01
> Successfully installed WWW-RobotRules-6.02
> Successfully installed libwww-perl-6.26
> Successfully installed LWP-Protocol-https-6.07
> Successfully installed JSON-2.94
> 27 distributions installed
> Complete! Modules were installed into /Users/aska/Documents/Perl/p5-WebService-Dropbox/local
```

## バージョン番号の更新

lib/WebService/Dropbox.pm

```perl
our $VERSION = '2.06';
```

## Test

```sh
carton exec -- prove -I lib t
```

## Test for with Furl

```sh
cpanm -L local-furl  --with-recommends ./
PERL_CARTON_PATH=local-furl carton exec -- prove -I lib t
```

## README.md の更新

```sh
cpanm Minilla
minil dist --no-test
```

## Release

```sh
$EDITOR ~/.pause
minil release --no-test
```
