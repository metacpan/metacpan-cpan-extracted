package Test::Script::Shebang;

use strict;
use warnings;
use 5.006_002;
our $VERSION = '0.02';

use File::Spec;
use Test::Builder;

my $tb = Test::Builder->new;
my $ok = 1;

sub import {
    my $self = shift;
    my $caller = caller;

    for my $func (qw/check_shebang check_shebang_from_dir/) {
        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $tb->exported_to($caller);
    $tb->plan(@_);
}

sub check_shebang {
    my @files = @_;

    for my $file (@files) {
        unless (-f $file) {
            $tb->ok(0, $file);
            $tb->diag("$file dose not exists");
            next;
        }

        open my $fh, '<', $file or die "$file: $!";
        local $/ = "\n";
        chomp(my $line = <$fh>);
        close $fh or die "$file: $!";

        unless ($line =~ s/^\s*\#!\s*//) {
            $tb->ok(0, $file);
            $tb->diag("Not a shebang file: $file");
            next;
        }

        my ($cmd, $arg) = split ' ', $line, 2;
        $cmd =~ s|^.*/||;
        unless ($cmd =~ m{^perl(?:\z|[^a-z])}) {
            $tb->ok(0, $file);
            $tb->diag("$file is not perl script");
            next;
        }
        $tb->ok(1, $file);
    }

    return $ok;
}

sub check_shebang_from_dir {
    my @dirs = @_;

    for my $dir (sort @dirs) {
        unless (-d $dir) {
            $tb->ok(0, $dir);
            $tb->diag("$dir dose not exists");
            next;
        }

        opendir my $dh, $dir or die "$dir: $!";
        my @files = map { File::Spec->catfile($dir, $_) } grep !/^\.{1,2}$/, sort readdir $dh;
        closedir $dh or die "$dir: $!";

        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $tb->ok(check_shebang(@files), $dir);
    }

    return $ok;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Test::Script::Shebang - checking the perl script shebang

=head1 SYNOPSIS

  use Test::More;
  use Test::Script::Shebang;
  
  check_shebang('scripts/foo.pl');
  check_shebang_from_dir('bin');
  
  done_testing;

=head1 DESCRIPTION

Test::Script::Shebang is checking the perl script shebang.

=head1 FUNCTIONS

=head2 check_shebang(@files)

checking for each file(s).

into script/foo.pl

  #!perl
  use strict;
  use warnings;
  print "foo";
  ...

into xt/check_script_shebang.t

  use Test::More;
  use Test::Script::Shebang;
  check_shebang('script/foo.pl'); # success
  done_testing;

=head2 check_shebang_from_dir(@dirs);

checking for each files in directory.

  use Test::More;
  use Test::Script::Shebang;
  check_shebang_from_dir('script', 'bin');
  done_testing;

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
