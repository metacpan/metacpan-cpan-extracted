package fallback;
use warnings;
use strict;

our $VERSION = 0.01;

use Config;
use File::Spec::Functions;

=head1 NAME

fallback - Like L<lib>, but pushes the dirs at the end of C<@INC>.

=head1 SYNOPSIS

    use fallback 'inc';
    use A::Module; # the user-installed version is found first

=head1 DESCRIPTION

=cut

my @inc_version_list = reverse split(/ /, $Config{inc_version_list});
my $archname = $Config{archname};
my $version  = $Config{version};

sub _unshift_if_dir (\@@) {
    my ($list, @dirs) = @_;
    for my $dir (reverse @dirs) {
        unshift @$list, $dir if -d $dir;
    }
};

=head2 import(@dirlist)

This creates a list of directories for each element in C<@dirlist> to add to
the searchpath and pushes it onto C<@INC>. This is the same list as L<lib.pm>
uses, but it's push()ed rather than unshift()ed.

=over

=item $dir

=item $dir/$inc_version (See $Config{inc_version_list})

=item $dir/$archname/auto

=item $dir/$archname

=item $dir/$version

=item $dir/$version/$archname

=back

=cut

sub import {
    my $class = shift;

    for my $libdir (@_) {
        # skip these special cases
        next if !defined($libdir) || ($libdir eq '');

        my @libgroup = ($libdir);
        for my $inc_version (@inc_version_list) {
            _unshift_if_dir(@libgroup, catdir($libdir, $inc_version));
        }
        for my $archdir ('auto', '') {
            _unshift_if_dir(@libgroup, catdir($libdir, $archname, $archdir));
        }
        for my $verdir ('', $archname) {
            _unshift_if_dir(@libgroup, catdir($libdir, $version, $verdir));
        }

        push @INC, @libgroup;
    }

    my %names;
    @INC = reverse( grep ++$names{$_} == 1, reverse @INC );

    return;
}

=head2 unimport(@dirlist)

Remove the set of subdirs represented by each element of C<@dirlist> from
C<@INC>.

=cut

sub unimport {
    my $class = shift;

    my %names;
    for my $libdir (@_) {
        $names{$libdir}++;

        my @libgroup = ($libdir);
        for my $inc_version (@inc_version_list) {
            $names{ catdir($libdir, $inc_version) }++;
        }
        for my $archdir ('auto', '') {
            $names{ catdir($libdir, $archname, $archdir) }++;
        }
        for my $verdir ('', $archname) {
            $names{ catdir($libdir, $version, $verdir) }++;
        }
    }

    @INC = grep !exists($names{$_}), @INC;

    return;
}

1;

=head1 COPYRIGHT

(c) 2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
