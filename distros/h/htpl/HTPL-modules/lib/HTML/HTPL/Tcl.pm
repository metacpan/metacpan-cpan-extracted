package HTML::HTPL::Tcl;

use HTML::HTPL::Sys qw(getpkg);
use Tcl;
use Tie::NormalArray;
use vars qw($Interp $Result);
use Exporter;
use Carp;
use strict qw(var subs);
use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(tclexec);
$HTML::HTPL::Sys::TCL_LOADED = 1;

sub import {
    my $pkg = &getpkg;
    $Interp = new Tcl;
    *{"${pkg}::tcl"} = \$Interp;
    *{"${pkg}::tcl_out"} = \$Result;
    HTML::HTPL::Tcl->export_to_level(1, @_);
    if ($HTML::HTPL::Sys::htpl_pkg) {
        &exportpackage('HTML::HTPL::Lib', qw($ % @ &));
    }
}

sub importvars {
    my $pkg = &getpkg;
    foreach (@_) {
        my $i = $_;
        $i =~ s/^(.)//;
        my $save = $1;
        my ($var, $tpk, $r) = &split_em($i, $pkg);
        my $tied = eval("tied($save$r)");
        next if ($tied);
        if ($save =~ /[\$\%]/) {
            eval "tie $save$r, 'Tcl::Var', \$Interp, '$var';";
        } elsif (undef && $save eq '@') {
            my %hash;
            my $t = tie %hash, 'Tcl::Var', $Interp, $var;
            tie @$r, 'Tie::NormalArray', $t;
        } else {
            Carp::croak("Can tie only scalars or hashes");
        }
    }
}

sub exportvars {
    &importvars(@_); return;
}

sub sendvars {
    foreach (@_) {
        my $i = $_;
        $i =~ s/^(.)//;
        my $save = $1;
        my ($var, $tpk, $r) = &split_em($i, $pkg);
        if ($1 eq '%') {
            $Interp->Eval(<<EOM);
if {[info exists $var]} {
    unset $var
}
EOM
            my ($k, $v);
            while (($k, $v) = each %$r) {
                $Interp->SetVar("$var($k)", $v);
            }
        } elsif ($1 eq '@') {
            $Interp->Eval(<<EOM);
if {[info exists $var]} {
    unset $var
}
EOM
            my $i;
            foreach (@$r) {
                $Interp->SetVar("$var($i)", $_);
                $i++;
            }
        } elsif ($1 eq '$') {
            my $val = $$r;
            $Interp->Eval(<<EOM);
if {[info exists $var]} {unset $var}
EOM
            $Interp->SetVar($var, $val);
        }
    }
}

sub exportprocs {
    my $pkg = &getpkg;
    foreach my $p (@_) {
        $_ = $p;
        s/^\&//;
        my $procname = $_;
        my $cmd;
        ($cmd, $pkg, $procname) = &split_em($procname, $pkg);
        my $code = "sub {
            shift; shift; shift;
            \$${pkg}::IN_TCL = 1;
            eval '&$procname(\@_)';
            \$${pkg}::IN_TCL = undef;
            return 1;
        };";
        my $ref = eval($code);
        $Interp->CreateCommand($cmd, $ref, undef, sub {});
    }
}

sub exportsubs {
    &exportprocs(@_);
}

sub importsubs {
    my $pkg = &getpkg;
    foreach my $p (@_) {
        $_ = $p;
        s/^\&//;
        my ($cmd, $tpk, $proc) = &split_em($_, $pkg);
        eval <<EOM;
package $tpk;
sub $cmd {
    \$HTML::HTPL::Tcl::Interp->call('$cmd', \@_);
}
EOM
    }
}

sub importprocs {
    &importsubs(@_);
}

sub exportpackage {
    my $pkg = shift;
    my %hash;
    @hash{@_} = @_;
    my @subs = HTML::HTPL::Sys::pkglist($pkg, '&', 1);
    my @vars = HTML::HTPL::Sys::pkglist($pkg, '$', 1);
    my @arrays = HTML::HTPL::Sys::pkglist($pkg, '%', 1);
    my @lists = HTML::HTPL::Sys::pkglist($pkg, '@', 1);
    &exportvars(@vars) if ($hash{'$'});
    &exportvars(@arrays) if ($hash{'@'});
    &exportsubs(@subs) if ($hash{'&'});
    &sendvars(@lists) if ($hash{'@'});
}

sub split_em {
   my ($sym, $pkg) = @_;
   $sym =~ s/'/::/g;
   my @tokens = split(/::/, $sym);
   my $it = pop @tokens;
   $pkg = join("::", @tokens) if (@tokens);
   return ($it, $pkg, "${pkg}::$it");
}

sub tclexec {
    $Result = $Interp->Eval(shift);
}

1;

