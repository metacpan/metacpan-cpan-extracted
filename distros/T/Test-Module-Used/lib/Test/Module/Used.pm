package Test::Module::Used;
use base qw(Exporter);
use strict;
use warnings;
use File::Find;
use File::Spec::Functions qw(catfile);
use Module::Used qw(modules_used_in_document);
use Module::CoreList;
use Test::Builder;
use List::MoreUtils qw(any uniq all);
use PPI::Document;
use version;
use CPAN::Meta;
use Carp;
use 5.008001;
our $VERSION = '0.2.6';

=for stopwords versa

=head1 NAME

Test::Module::Used - Test required module is really used and vice versa between lib/t and META.yml

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use warnings;
  use Test::Module::Used;
  my $used = Test::Module::Used->new();
  $used->ok;


=head1 DESCRIPTION

Test dependency between module and META.yml.

This module reads I<META.yml> and get I<build_requires> and I<requires>. It compares required module is really used and used module is really required.

=cut

=head1 Important changes

Some behavior changed since 0.1.3_01.

=over 4

=item * perl_version set in constructor is prior to use, and read version from META.yml(not read from use statement in *.pm)

=item * deprecated interfaces are deleted. (module_dir, test_module_dir, exclude_in_moduledir and push_exclude_in_moduledir)

=back

=cut

=head1 methods

=cut

=head2 new

create new instance

all parameters are passed by hash-style, and optional.

in ordinary use.

  my $used = Test::Module::Used->new();
  $used->ok();

all parameters are as follows.(specified values are default, except I<exclude_in_testdir>)

  my $used = Test::Module::Used->new(
    test_dir     => ['t'],            # directory(ies) which contains test scripts.
    lib_dir      => ['lib'],          # directory(ies) which contains module libs.
    test_lib_dir => ['t'],            # directory(ies) which contains libs used ONLY in test (ex. MockObject for test)
    meta_file    => 'META.json' or
                    'META.yml' or
                    'META.yaml',      # META file (YAML or JSON which contains module requirement information)
    perl_version => '5.008',          # expected perl version which is used for ignore core-modules in testing
    exclude_in_testdir => [],         # ignored module(s) for test even if it is used.
    exclude_in_libdir   => [],        # ignored module(s) for your lib even if it is used.
    exclude_in_build_requires => [],  # ignored module(s) even if it is written in build_requires of META.yml.
    exclude_in_requires => [],        # ignored module(s) even if it is written in requires of META.yml.
  );

if perl_version is not passed in constructor, this modules reads I<meta_file> and get perl version.

I<exclude_in_testdir> is automatically set by default. This module reads I<lib_dir> and parse "package" statement, then found "package" statements and myself(Test::Module::Used) is set.
I<exclude_in_libdir> is also automatically set by default. This module reads I<lib_dir> and parse "package" statement, found "package" statement are set.(Test::Module::Used isn't included)

=cut

sub new {
    my $class = shift;
    my (%opt) = @_;
    my $self = {
        test_dir     => $opt{test_dir}     || ['t'],
        lib_dir      => $opt{lib_dir}      || ['lib'],
        test_lib_dir => $opt{test_lib_dir} || ['t'],
        meta_file    => _find_meta_file($opt{meta_file}),
        perl_version => $opt{perl_version},
        exclude_in_testdir        => $opt{exclude_in_testdir},
        exclude_in_libdir         => $opt{exclude_in_libdir},
        exclude_in_build_requires => $opt{exclude_in_build_requires} || [],
        exclude_in_requires       => $opt{exclude_in_requires}       || [],
    };
    bless $self, $class;
    $self->_get_packages();
    return $self;
}

sub _find_meta_file {
    my ($opt_meta_file) = @_;
    return $opt_meta_file  if ( defined $opt_meta_file );
    for my $file ( qw(META.json META.yml META.yaml) ) {
        return $file if ( -e $file );
    }
    croak "META file not found\n";
}


sub _test_dir {
    return shift->{test_dir};
}

sub _lib_dir {
    return shift->{lib_dir};
}

sub _test_lib_dir {
    return shift->{test_lib_dir};
}

sub _meta_file {
    return shift->{meta_file};
}

sub _perl_version {
    return shift->{perl_version};
}

=head2 ok()

check used modules are required in META file and required modules in META files are used.

  my $used = Test::Module::Used->new(
    exclude_in_testdir => ['Test::Module::Used', 'My::Module'],
  );
  $used->ok;


First, This module reads I<META.yml> and get I<build_requires> and I<requires>. Next, reads module directory (by default I<lib>) and test directory(by default I<t>), and compare required module is really used and used module is really required. If all these requirement information is OK, test will success.

It is NOT allowed to call ok(), used_ok() and requires_ok() in same test file.

=cut

sub ok {
    my $self = shift;
    return $self->_ok(\&_num_tests, \&_used_ok, \&_requires_ok);
}

=head2 used_ok()

Only check used modules are required in META file.
Test will success if unused I<requires> or I<build_requires> are defined.

  my $used = Test::Module::Used->new();
  $used->used_ok;


It is NOT allowed to call ok(), used_ok() and requires_ok() in same test file.

=cut

sub used_ok {
    my $self = shift;
    return $self->_ok(\&_num_tests_used_ok, \&_used_ok);
}

=head2 requires_ok()

Only check required modules in META file is used.
Test will success if used modules are not defined in META file.

  my $used = Test::Module::Used->new();
  $used->requires_ok;


It is NOT allowed to call ok(), used_ok() and requires_ok() in same test file.

=cut

sub requires_ok {
    my $self = shift;
    return $self->_ok(\&_num_tests_requires_ok, \&_requires_ok);
}

sub _ok {
    my $self = shift;
    my ($num_tests_subref, @ok_subrefs) = @_;

    croak('Already tested. Calling ok(), used_ok() and requires_ok() in same test file is not allowed') if ( !!$self->{tested} );

    my $num_tests = $num_tests_subref->($self);
    return $self->_do_test($num_tests, @ok_subrefs);
}

sub _do_test {
    my $self = shift;
    my ($num_tests, @ok_subrefs) = @_;

    my $test = Test::Builder->new();
    my $test_status = $num_tests > 0 ? $self->_do_test_normal($num_tests, @ok_subrefs) :
                                       $self->_do_test_no_tests();
    $self->{tested} = 1;
    return !!$test_status;
}

sub _do_test_normal {
    my $self = shift;
    my ($num_tests, @ok_subrefs) = @_;

    my $test = Test::Builder->new();
    $test->plan(tests => $num_tests);
    my @status;
    for my $ok_subref ( @ok_subrefs ) {
        push(@status, $ok_subref->($self, $test));
    }
    my $test_status =  all { $_ } @status;
    return !!$test_status;
}

sub _do_test_no_tests {
    my $self = shift;

    my $test = Test::Builder->new();
    $test->plan(tests => 1);
    $test->ok(1, "no tests run");
    return 1;
}

sub _used_ok {
    my $self = shift;
    my ($test) = @_;
    my $status_lib  = $self->_check_used_but_not_required($test,
                                                          [$self->_remove_core($self->_used_modules)],
                                                          [$self->_remove_core($self->_requires)],
                                                          "lib");
    my $status_test = $self->_check_used_but_not_required($test,
                                                          [$self->_remove_core($self->_used_modules_in_test)],
                                                          [$self->_remove_core($self->_build_requires)],
                                                          "test");
    return $status_lib && $status_test;
}

sub _requires_ok {
    my $self = shift;
    my ($test) = @_;
    my $status_lib  = $self->_check_required_but_not_used($test,
                                                          [$self->_remove_core($self->_used_modules)],
                                                          [$self->_remove_core($self->_requires)],
                                                          "lib");
    my $status_test = $self->_check_required_but_not_used($test,
                                                          [$self->_remove_core($self->_used_modules_in_test)],
                                                          [$self->_remove_core($self->_build_requires)],
                                                          "test");
    return $status_lib && $status_test;
}


=head2 push_exclude_in_libdir( @exclude_module_names )

add ignored module(s) for your module(lib) even if it is used after new()'ed.
this is usable if you want to use auto set feature for I<exclude_in_libdir> but manually specify exclude modules.

For example,

 my $used = Test::Module::Used->new(); #automatically set exclude_in_libdir
 $used->push_exclude_in_libdir( qw(Some::Module::Which::You::Want::To::Exclude) );#module(s) which you want to exclude
 $used->ok(); #do test

=cut

sub push_exclude_in_libdir {
    my $self = shift;
    my @exclude_module_names = @_;
    push @{$self->{exclude_in_libdir}},@exclude_module_names;
}



=head2 push_exclude_in_testdir( @exclude_module_names )

add ignored module(s) for test even if it is used after new()'ed.
this is usable if you want to use auto set feature for I<exclude_in_testdir> but manually specify exclude modules.

For example,

 my $used = Test::Module::Used->new(); #automatically set exclude_in_testdir
 $used->push_exclude_in_testdir( qw(Some::Module::Which::You::Want::To::Exclude) );#module(s) which you want to exclude
 $used->ok(); #do test

=cut

sub push_exclude_in_testdir {
    my $self = shift;
    my @exclude_module_names = @_;
    push @{$self->{exclude_in_testdir}},@exclude_module_names;
}

sub _version {
    my $self = shift;
    if ( !defined $self->{version} ) {
        $self->{version} = $self->_perl_version || $self->_version_from_meta || "5.008000";
    }
    return $self->{version};
}

sub _num_tests {
    my $self = shift;
    return $self->_num_tests_used_ok() + $self->_num_tests_requires_ok();
}

sub _num_tests_used_ok {
    my $self = shift;
    return scalar($self->_remove_core($self->_used_modules,
                                      $self->_used_modules_in_test));
}

sub _num_tests_requires_ok {
    my $self = shift;
    return scalar($self->_remove_core($self->_requires,
                                      $self->_build_requires));

}

sub _check_required_but_not_used {
    my $self = shift;
    my ($test, $used_aref, $requires_aref, $place) = @_;
    my @requires = @{$requires_aref};
    my @used     = @{$used_aref};

    my $result = 1;
    for my $requires ( @requires ) {
        my $status = any { $_ eq $requires } @used;
        $test->ok( $status, "check required module: $requires" );
        if ( !$status ) {
            $test->diag("module $requires is required in META file but not used in $place");
            $result = 0;
        }
    }
    return $result;
}

sub _check_used_but_not_required {
    my $self = shift;
    my ($test, $used_aref, $requires_aref, $place) = @_;
    my @requires = @{$requires_aref};
    my @used     = @{$used_aref};

    my $result = 1;
    for my $used ( @used ) {
        my $status = any { $_ eq $used } @requires;
        $test->ok( $status, "check used module: $used" );
        if ( !$status ) {
            $test->diag("module $used is used in $place but not required");
            $result = 0;
        }
    }
    return $result;
}

sub _pm_files {
    my $self = shift;
    if ( !defined $self->{pm_files} ) {
        my @files = $self->_find_files_by_ext($self->_lib_dir, qr/\.pm$/);
        $self->{pm_files} = \@files;
    }
    return @{$self->{pm_files}};
}

sub _pm_files_in_test {
    my $self = shift;
    if ( !defined $self->{pm_files_in_test} ) {
        my @files = $self->_find_files_by_ext($self->_test_lib_dir, qr/\.pm$/);
        $self->{pm_files_in_test} = \@files;
    }
    return @{$self->{pm_files_in_test}};
}

sub _test_files {
    my $self = shift;
    return (
        $self->_find_files_by_ext($self->_test_dir, qr/\.t$/),
        $self->_pm_files_in_test()
    );
}

sub _find_files_by_ext {
    my $self = shift;
    my ($start_dirs_aref, $ext_qr) = @_;
    my @result;
    find( sub {
              push @result, catfile($File::Find::dir, $_) if ( $_ =~ $ext_qr );
          },
          @{$start_dirs_aref});
    return @result;
}

sub _used_modules {
    my $self = shift;
    if ( !defined $self->{used_modules} ) {
        my @used = map { modules_used_in_document($self->_ppi_for($_)) } $self->_pm_files;
        my @result = uniq _array_difference(\@used, $self->{exclude_in_libdir});
        $self->{used_modules} = \@result;
    }
    return @{$self->{used_modules}};
}

sub _used_modules_in_test {
    my $self = shift;
    if ( !defined $self->{used_modules_in_test} ) {
        my @used = map { modules_used_in_document($self->_ppi_for($_)) } $self->_test_files;
        my @result = uniq _array_difference(\@used, $self->{exclude_in_testdir});
        $self->{used_modules_in_test} = \@result;
    }
    return @{$self->{used_modules_in_test}};
}

sub _array_difference {
    my ( $aref1, $aref2 ) = @_;
    my @a1 = @{$aref1};
    my @a2 = @{$aref2};

    for my $a2 ( @a2 ) {
        @a1 = grep { $_ ne $a2 } @a1;
    }
    my @result = sort @a1;
    return @result;
}

sub _version_from_meta {
    my $self = shift;
    return $self->{version_from_meta};
}

sub _remove_core {
    my $self = shift;
    my( @module_names ) = @_;
    my @result = grep {  !$self->_is_core_module($_) } @module_names;
    return @result;
}

sub _is_core_module {
    my $self = shift;
    my($module_name) = @_;
    my $first_release = Module::CoreList->first_release($module_name);
    return defined $first_release && $first_release <= $self->_version;
}

sub _read_meta {
    my $self = shift;
    my $meta = CPAN::Meta->load_file( $self->_meta_file );
    my $prereqs = $meta->prereqs();
    $self->{build_requires} = $prereqs->{build}->{requires};
    my $requires = $prereqs->{runtime}->{requires};
    $self->{version_from_meta} = version->parse($requires->{perl})->numify() if defined $requires->{perl};
    delete $requires->{perl};
    $self->{requires} = $requires;
}

sub _build_requires {
    my $self = shift;

    $self->_read_meta if !defined $self->{build_requires};
    my @result = sort keys %{$self->{build_requires}};
    return _array_difference(\@result, $self->{exclude_in_build_requires});
}

sub _requires {
    my $self = shift;

    $self->_read_meta if !defined $self->{requires};
    my @result = sort keys %{$self->{requires}};
    return _array_difference(\@result, $self->{exclude_in_requires});
}

# find package statements in lib
sub _get_packages {
    my $self = shift;
    my @packages = $self->_packages_in( $self->_pm_files );
    my @exclude_in_testdir = (__PACKAGE__, @packages, $self->_packages_in($self->_pm_files_in_test));
    $self->push_exclude_in_testdir(@exclude_in_testdir) if ( !defined $self->{exclude_in_testdir} );
    $self->push_exclude_in_libdir(@packages)            if ( !defined $self->{exclude_in_libdir} );
}

sub _packages_in {
    my $self = shift;
    my ( @filenames ) = @_;

    my @result;
    for my $filename ( @filenames ) {
        my @packages = $self->_packages_in_file($filename);
        push @result, @packages;
    }
    return @result;
}

sub _packages_in_file {
    my $self = shift;
    my ( $filename ) = @_;
    my @ppi_package_statements = $self->_ppi_package_statements($filename);
    my @result;
    for my $ppi_package_statement ( @ppi_package_statements ) {
        push @result, $self->_package_names_in($ppi_package_statement);
    }
    return @result;
}

sub _ppi_package_statements {
    my $self = shift;
    my ($filename) = @_;

    my $doc = $self->_ppi_for($filename);
    my $packages = $doc->find('PPI::Statement::Package');
    return if ( $packages eq '' );
    return @{ $packages };
}

sub _package_names_in {
    my $self = shift;
    my ($ppi_package_statement) = @_;
    my @result;
    for my $token ( @{$ppi_package_statement->{children}} ) {
        next if ( !$self->_is_package_name($token) );
        push @result, $token->content;
    }
    return @result;
}

sub _is_package_name {
    my $self = shift;
    my ($ppi_token) = @_;
    return $ppi_token->isa('PPI::Token::Word') && $ppi_token->content ne 'package';
}

# PPI::Document object for $filename
sub _ppi_for {
    my $self = shift;
    my ($filename) = @_;
    if ( !defined $self->{ppi_for}->{$filename} ) {
        my $doc = PPI::Document->new($filename);
        $self->{ppi_for}->{$filename} = $doc;
    }
    return $self->{ppi_for}->{$filename};
}


1;
__END__

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=head1 SEE ALSO

L<Test::Dependencies> has almost same feature.

=head1 REPOSITORY

L<http://github.com/tsucchi/Test-Module-Used>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2014 Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
