package Test::Lib;
use strict;
use warnings;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

use File::Spec;
use Cwd ();
use lib ();

sub import {
    my $class = shift;
    my $dir = shift;
    if (! defined $dir) {
        my $file = File::Spec->rel2abs((caller)[1]);
        $dir = File::Spec->catpath((File::Spec->splitpath($file))[0,1], '');
    }
    for my $i (0..5) {
        my $tdir = File::Spec->catdir($dir, (File::Spec->updir) x $i);
        my $abs_path = Cwd::abs_path($tdir);
        my $dirname = (File::Spec->splitdir($abs_path))[-1];

        if ($dirname eq 't') {
            my $tlib = File::Spec->catdir($tdir, 'lib');
            if (-d $tlib) {
                lib->import($tlib);
                return;
            }
        }
    }
    die "unable to find t/lib directory in $dir";
}

1;

__END__

=head1 NAME

Test::Lib - Use libraries from a t/lib directory

=head1 SYNOPSIS

    use Test::Lib;
    use Test::More;
    use Private::Testing::Module;
    
    ok 1, 'passing test';
    my_test 'test from private module';

=head1 DESCRIPTION

Searches upward from the calling module for a directory F<t> with
a F<lib> directory inside it, and adds it to the module search path.
Looks upward up to 5 directories.  This is intended to be used in
test modules either directly in F<t> or in a subdirectory to find
their included testing libraries located in F<t/lib>.

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Graham Knop.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
