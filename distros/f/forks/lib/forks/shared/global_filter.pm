package
    forks::shared::global_filter; # hide from PAUSE

# Some internal magic to force source filtering on modules
# Intended primarily for modules that aren't portable with perl < 5.8

use strict;
use IO::File;
use File::Spec;
use List::MoreUtils;

use vars '$VERSION';
$VERSION = '0.36';

our @FILTER = ();
my @_dummy = (*ARGVOUT);

sub import
{
    my $class = shift;
    @FILTER = List::MoreUtils::uniq @FILTER, @_;
    unshift @INC, \&forks_filter;
}

sub do_filter
{
    my ($module, $modfile) = @_;

    return unless grep {$module eq $_} @FILTER;

    my    $file;
    local @INC = @INC;

    my $p;
    for my $path (@INC)
    {
        local @ARGV = File::Spec->catfile( $path, $modfile );
        next unless -e $ARGV[0];

        $file = do { local $/; <> } or return;
        $p = $ARGV[0];
    }

    return unless $file;
    return if $module =~ m/^(forks|threads)\b/o;

#  Add use/require directive after each package declaration

    $file =~ s/(\bpackage[^;]+;)/$1 use forks; use forks::shared;\n/sgo;

#  Apply standard forks::shared source filter rules (for perl < 5.8)

    if ($] < 5.008) {
        $file =~ s#(\b(?:cond_wait)\b\s*(?!{)\(?\s*[^,]+,\s*)(?=[mo\$\@\%])#$1\\#sg;
        $file =~ s#(\b(?:cond_timedwait)\b\s*(?!{)\(?\s*[^,]+,[^,]+,\s*)(?=[mo\$\@\%])#$1\\#sg;
        $file =~ s#(\b(?:cond_broadcast|cond_wait|cond_timedwait|cond_signal|share|is_shared|threads::shared::_id|lock)\b\s*(?!{)\(?\s*)(?=[mo\$\@\%])#$1\\#sg;
        $file =~ s#((?:my|our)((?:\s|\()*[\$@%*]\w+(?:\s|\)|,)*)+\:\s*)\bshared\b#$1Forks_shared#sg;
    }

    return ($p, _fake_module_fh( $file ));
}

sub forks_filter
{
    my ($code, $module) = @_;
    $module =~ s{/}{::}g;
    $module =~ s/\.pm$//;
    (my $modfile        = $module) =~ s{::}{/}g;
    $modfile .= '.pm' unless $modfile =~ m/\.pm$/o;
    my ($path, $fh) = do_filter( $module, $modfile );

    return unless $fh;

    $INC{$modfile} = $path;
    $fh->seek( 0, 0 );

    return $fh;
}

sub _fake_module_fh
{
    my $text = shift;
    my $fh   = IO::File->new_tmpfile() or return;

    $fh->print( $text );
    $fh->seek( 0, 0 );

    return $fh;
}

1;
