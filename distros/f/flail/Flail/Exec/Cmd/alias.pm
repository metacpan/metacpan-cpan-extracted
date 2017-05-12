=pod

=head1 NAME

Flail::Exec::Cmd::alias - Flail "alias" command

=head1 VERSION

  Time-stamp: <2006-12-03 11:12:03 attila@stalphonsos.com>

=head1 SYNOPSIS

  use Flail::Exec::Cmd::alias;
  blah;

=head1 DESCRIPTION

Describe the module.

=cut

package Flail::Exec::Cmd::alias;
use strict;
use Carp;
use Flail::Utils qw(say);
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw(flail_alias);
@EXPORT = ();
%EXPORT_TAGS = ( 'cmd' => \@EXPORT_OK );

sub bind_alias_args {
    my $str = shift(@_);
    say "bind_alias_args(@_) str=$str";
    my $a = "@_";
    my $n = 1;
    $str =~ s/%\*/$a/g;
    foreach my $arg (@_) {
        $str =~ s/%$n/$arg/g;
        ++$n;
    }
    say "bind_alias_args => $str";
    return $str;
}
 
sub flail_alias {
    my $name = shift(@_);
    if (!defined($name)) {
        print "need at least an alias name\n";
        return;
    }
    my $def = "@_";
    my $old = $Flail::Exec::COMMANDS{$name};
    if (defined($old)) {
        if (($old->[1] !~ /^alias:/) && !$::AllowCommandOverrides) {
            print "cannot override built-in command $name with an alias\n";
            return;
        }
        if (!defined($_[0])) {
            my $doc = $old->[1];
            $doc =~ s/^alias:\s*//;
            print "$name: $doc\n";
            return;
        }
        delete($Flail::Exec::COMMANDS{$name});
    }
    my $func = sub { my $str = bind_alias_args($def, @_); flail_eval($str); };
    flail_defcmd($name, $func, "alias: $def");
}

1;

__END__

=pod

=head1 AUTHOR

  attila <attila@stalphonsos.com>

=head1 COPYRIGHT AND LICENSE

  (C) 2002-2006 by attila <attila@stalphonsos.com>.  all rights reserved.

  This code is released under a BSD license.  See the LICENSE file
  that came with the package.

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# time-stamp-line-limit: 40
# End:
##
