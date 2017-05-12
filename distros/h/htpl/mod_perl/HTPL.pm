package Apache::HTPL;

use strict qw(subs vars);
no strict qw(refs);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
#require DynaLoader;
#require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

#bootstrap Apache::HTPL $VERSION;


# Preloaded methods go here.


# Autoload methods go after =cut, and are processed by the autosplit program.


use Shell;

sub handler {
    my ($self, $r) = @_;
    $r = Apache->request unless (ref($r) =~ /Apache/);

    $| = 1;

    my $in_mod_htpl = 1;
    require HTML::HTPL::Lib;

    my $filename = $r->filename;

    if (-d $filename) {
        $filename =~ s|/$||;
        $filename .= "/index.htpl";
    }
    return 404 unless (-e $filename);

    %ENV = $r->cgi_env;


    my $ref = $Apache::HTPL::htpl_codes{$filename};

    my $script = &HTML::HTPL::Lib'tempfilename;

    my $ecode;

    if ($ref) {
        my $pagelm = (stat($filename))[10];
        my $scriptlm = $ref->{'lm'};
        undef $ref if ($pagelm > $scriptlm);
    }

    unless ($ref) {
	    open(READ, "$HTML::HTPL::Config'dbgbin -o $script $filename 2>&1 |");

            my @lines = <READ>;
            my $buff = join("", @lines);
            close(READ);

            if ($buff) {
                $r->content_type("text/plain");
                $r->send_http_header;
                $r->print("Error:\n$buff");
                return 0;
            }

        my $tcode = Shell::cat($script);
        unlink $script;
        my $scrfn = $filename;
        $scrfn =~ s/([^A-Za-z0-9])/"::c" . (unpack("C", $1))/ge;
        my $subname = "__htpl_doit";
        my $pkg = "Apache::ROOT$scrfn";
        my $precode = qq!
package $pkg;
no strict;
sub $subname {
use HTML::HTPL::Lib;
use HTML::HTPL::Sys;
\$HTML::HTPL::Lib'in_mod_htpl = 1;
\$HTML::HTPL::Lib'htpl_pkg = '$pkg';
use subs qw(exit);
sub exit { goto htpl_lblend; }
*0 = \'$filename';
$tcode
htpl_lblend:
}
1;
!;	


        $@ = undef;
        eval("undef \&$pkg\::$subname;"); 
        eval $precode;
        $ecode = !$@;
	$ref = undef;
        $ref = {'package' => $pkg,
                               'proc' => $subname,
                               'code' => \&{"$pkg\::$subname"},
                               'str' => "$pkg\::$subname",
                               'lm'   => time} if ($ecode);
        $Apache::HTPL::htpl_codes{$filename} = $ref;
    } else {
        $ecode = 1;
    }

    $ENV{'TEMP'} = '/tmp';
    my $out = &HTML::HTPL::Lib'tempfilename;
    my $head = &HTML::HTPL::Lib'tempfilename;
    $ENV{'HTTP_HEADERS'} = $head;
    open(O, ">$head");
    print O "Content-type: text/html\n";
    close(O);

    open(HTPL_MOD_OUT, ">$out");
    select(HTPL_MOD_OUT);
    my $package = $ref->{'package'};
    my %symbol = eval '%' . "${package}::";

    foreach (keys %symbol) {
        next if ($_ eq 'import');
        my $val = $symbol{$_};
        $val =~ s/^\*//;
        eval "undef \$$val";
        eval "undef \@$val";
        eval "undef \%$val";
    }

    %{"$package\::ENV"} = %ENV;
    my $init = "$package\::__sys_init";
    my $deinit = "$package\::__sys_deinit";
    my $str = $ref->{'str'};
    $ecode &&= eval("&$init; \&$str; &$deinit; 1;");

    select(STDOUT);
    close(HTPL_MOD_OUT);

    unless ($ecode) {
        $r->content_type("text/plain");
        $r->send_http_header;
        $r->print("Error: $@");
        return 0;
    }

    my $hthd = Shell::cat($head) . "\n";
    my $txt = Shell::cat($out);
    unlink $head;
    unlink $out;
    $r->send_cgi_header("$hthd\n");
    if ($HTML::HTPL::Lib'htpl_redirected) {
        return $Apache::Constants::MOVED;
    }
    $r->print($txt);

    return 0;
}


1;

__END__

=head1 NAME

Apache::HTPL - Apache mod_perl driver for HTPL.

=head1 SYNOPSIS


=head1 DESCRIPTION

After installed, this module will boost the performance of HTPL by having
pages compiled in memory and run again and again.
It utilizes the Apache mod_perl extension, and can't be otherwise used.

The HTPL page translator is compiled into this module as an XSUB
extension. (I could not execute the page translator as a child process -
any advices?)

=head1 INSTALLATION

The easiest way to install HTPL under mod_perl is to ask for it when
running the configure script:

./configure --enable-modperl

Suppose installation was done as root (which is highly recommended),
configuration file will be initialized.

Otherwise, add the following lines to httpd.conf:

PerlModule Apache::HTPL

<Files ~ "*.htpl">
SetHandler perl-script
PerlHandler Apache::HTPL
</Files>

=head1 FEATURES

=item Local variables

Apache::HTPL works similarly to Apache::Registry - it creates a namespace
and a subroutine for every page. It will attempt to clear the namespace
between page calls, to allow "dirty" scripting by assuming empty
variables. It does so by consulting the stash of a package.

=item Global variables

Consistent value can be stored on different namespaces - recommended is
Apache::HTPL::Vars or the alike. Do not use it for stateful sessions, as
Apache spawns several processes on a server. Use the internal persistent
objects to keep stateful sessions, via the %application and %session
hashes. Global variables can be used to initialized tables, for example.

=item Persistent database connections

The Database module will cache database connections and reuse them.
Since this uses up one database connection per Apache process, you can
disable this feature by editing you configuration file and changing the
value of $htpl_db_save.

=head1 Configuration

The htpl-config.pl file will still be stored on the cgi-bin directory
while using HTPL on mod_perl mode, as will be the htpldbg page translator.
The installation will always create htpl.cgi.

=cut
