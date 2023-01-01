use v5.8;
use strict;
use warnings;
package Test::MinimumVersion;
$Test::MinimumVersion::VERSION = '0.101083';
# ABSTRACT: does your code require newer perl than you think?
use base 'Exporter';

#pod =head1 SYNOPSIS
#pod
#pod Example F<minimum-perl.t>:
#pod
#pod   #!perl
#pod   use Test::MinimumVersion;
#pod   all_minimum_version_ok('5.008');
#pod
#pod =cut

use CPAN::Meta;
use File::Find::Rule;
use File::Find::Rule::Perl;
use Perl::MinimumVersion 1.32; # numerous bugfies
use version 0.70;

use Test::Builder;
@Test::MinimumVersion::EXPORT = qw(
  minimum_version_ok
  all_minimum_version_ok
  all_minimum_version_from_metayml_ok
  all_minimum_version_from_metajson_ok
  all_minimum_version_from_mymetayml_ok
  all_minimum_version_from_mymetajson_ok
);

sub import {
  my($self) = shift;
  my $pack = caller;

  my $Test = Test::Builder->new;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, @Test::MinimumVersion::EXPORT);
}

sub _objectify_version {
  my ($version) = @_;
  $version = eval { $version->isa('version') }
           ? $version
           : version->new($version);
}

#pod =func minimum_version_ok
#pod
#pod   minimum_version_ok($file, $version);
#pod
#pod This test passes if the given file does not seem to require any version of perl
#pod newer than C<$version>, which may be given as a version string or a version
#pod object.
#pod
#pod =cut

sub minimum_version_ok {
  my ($file, $version) = @_;

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my $pmv = Perl::MinimumVersion->new($file);

  unless (defined $pmv) {
    $Test->ok(0, $file);
    $Test->diag(
      "$file could not be parsed: " . PPI::Document->errstr
    );
    return;
  }

  my $explicit_minimum = $pmv->minimum_explicit_version || 0;
  my $minimum = $pmv->minimum_syntax_version($explicit_minimum) || 0;

  my $is_syntax = 1
    if $minimum and $minimum > $explicit_minimum;

  $minimum = $explicit_minimum
    if $explicit_minimum and $explicit_minimum > $minimum;

  my %min = $pmv->version_markers;

  if ($minimum <= $version) {
    $Test->ok(1, $file);
  } else {
    $Test->ok(0, $file);
    $Test->diag(
      "$file requires $minimum "
      . ($is_syntax ? 'due to syntax' : 'due to explicit requirement')
    );

    if ($is_syntax and my $markers = $min{ $minimum }) {
      $Test->diag("version markers for $minimum:");
      $Test->diag("- $_ ") for @$markers;
    }
  }
}

#pod =func all_minimum_version_ok
#pod
#pod   all_minimum_version_ok($version, \%arg);
#pod
#pod Given either a version string or a L<version> object, this routine produces a
#pod test plan (if there is no plan) and tests each relevant file with
#pod C<minimum_version_ok>.
#pod
#pod Relevant files are found by L<File::Find::Rule::Perl>.
#pod
#pod C<\%arg> is optional.  Valid arguments are:
#pod
#pod   paths   - in what paths to look for files; defaults to (bin, script, t, lib,
#pod             xt/smoke, and any .pm or .PL files in the current working
#pod             directory) if it contains files, they will be checked
#pod   no_plan - do not plan the tests about to be run
#pod   skip    - files to skip; this can be useful in weird cases like gigantic
#pod             files, files falsely detected as Perl, or code that uses
#pod             a source filter; this should be an arrayref of filenames
#pod
#pod =cut

sub all_minimum_version_ok {
  my ($version, $arg) = @_;
  $arg ||= {};
  $arg->{paths} ||= [
    qw(bin script lib t xt/smoke),
    glob("*.pm"),
    glob("*.PL"),
  ];

  $arg->{skip} ||= [];

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my @perl_files;
  for my $path (@{ $arg->{paths} }) {
    if (-f $path and -s $path) {
      push @perl_files, $path;
    } elsif (-d $path) {
      push @perl_files, File::Find::Rule->perl_file->in($path);
    }
  }

  my %skip = map {; $_ => 1 } @{ $arg->{skip} };
  @perl_files = grep {; ! $skip{$_} } @perl_files;

  unless ($Test->has_plan or $arg->{no_plan}) {
    $Test->plan(tests => scalar @perl_files);
  }

  minimum_version_ok($_, $version) for @perl_files;
}

#pod =func all_minimum_version_from_metayml_ok
#pod
#pod   all_minimum_version_from_metayml_ok(\%arg);
#pod
#pod This routine checks F<META.yml> for an entry in F<requires> for F<perl>.  If no
#pod META.yml file or no perl version is found, all tests are skipped.  If a version
#pod is found, the test proceeds as if C<all_minimum_version_ok> had been called
#pod with that version.
#pod
#pod =cut

sub __version_from_meta {
  my ($fn) = @_;

  my $meta = CPAN::Meta->load_file($fn, { lazy_validation => 1 })->as_struct;
  my $version = $meta->{prereqs}{runtime}{requires}{perl};
}

sub __from_meta {
  my ($fn, $arg) = @_;
  $arg ||= {};

  my $Test = Test::Builder->new;

  $Test->plan(skip_all => "$fn could not be found")
    unless -f $fn and -r _;

  $Test->plan(skip_all => "no minimum perl version could be determined")
    unless my $version = __version_from_meta($fn);

  all_minimum_version_ok($version, $arg);
}

sub all_minimum_version_from_metayml_ok {
  __from_meta('META.yml', @_);
}

#pod =func all_minimum_version_from_metajson_ok
#pod
#pod   all_minimum_version_from_metajson_ok(\%arg);
#pod
#pod This routine checks F<META.json> for an entry in F<requires> for F<perl>.  If
#pod no META.json file or no perl version is found, all tests are skipped.  If a
#pod version is found, the test proceeds as if C<all_minimum_version_ok> had been
#pod called with that version.
#pod
#pod =cut

sub all_minimum_version_from_metajson_ok { __from_meta('META.json', @_); }

#pod =func all_minimum_version_from_mymetayml_ok
#pod
#pod   all_minimum_version_from_mymetayml_ok(\%arg);
#pod
#pod This routine checks F<MYMETA.yml> for an entry in F<requires> for F<perl>.  If
#pod no MYMETA.yml file or no perl version is found, all tests are skipped.  If a
#pod version is found, the test proceeds as if C<all_minimum_version_ok> had been
#pod called with that version.
#pod
#pod =cut

sub all_minimum_version_from_mymetayml_ok { __from_meta('MYMETA.yml', @_); }

#pod =func all_minimum_version_from_mymetajson_ok
#pod
#pod   all_minimum_version_from_mymetajson_ok(\%arg);
#pod
#pod This routine checks F<MYMETA.json> for an entry in F<requires> for F<perl>.  If
#pod no MYMETA.json file or no perl version is found, all tests are skipped.  If a
#pod version is found, the test proceeds as if C<all_minimum_version_ok> had been
#pod called with that version.
#pod
#pod =cut

sub all_minimum_version_from_mymetajson_ok { __from_meta('MYMETA.json', @_); }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::MinimumVersion - does your code require newer perl than you think?

=head1 VERSION

version 0.101083

=head1 SYNOPSIS

Example F<minimum-perl.t>:

  #!perl
  use Test::MinimumVersion;
  all_minimum_version_ok('5.008');

=head1 PERL VERSION

This library should run on perls released even an extremely long time ago.  It
should work on any version of perl released in the last ten years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 FUNCTIONS

=head2 minimum_version_ok

  minimum_version_ok($file, $version);

This test passes if the given file does not seem to require any version of perl
newer than C<$version>, which may be given as a version string or a version
object.

=head2 all_minimum_version_ok

  all_minimum_version_ok($version, \%arg);

Given either a version string or a L<version> object, this routine produces a
test plan (if there is no plan) and tests each relevant file with
C<minimum_version_ok>.

Relevant files are found by L<File::Find::Rule::Perl>.

C<\%arg> is optional.  Valid arguments are:

  paths   - in what paths to look for files; defaults to (bin, script, t, lib,
            xt/smoke, and any .pm or .PL files in the current working
            directory) if it contains files, they will be checked
  no_plan - do not plan the tests about to be run
  skip    - files to skip; this can be useful in weird cases like gigantic
            files, files falsely detected as Perl, or code that uses
            a source filter; this should be an arrayref of filenames

=head2 all_minimum_version_from_metayml_ok

  all_minimum_version_from_metayml_ok(\%arg);

This routine checks F<META.yml> for an entry in F<requires> for F<perl>.  If no
META.yml file or no perl version is found, all tests are skipped.  If a version
is found, the test proceeds as if C<all_minimum_version_ok> had been called
with that version.

=head2 all_minimum_version_from_metajson_ok

  all_minimum_version_from_metajson_ok(\%arg);

This routine checks F<META.json> for an entry in F<requires> for F<perl>.  If
no META.json file or no perl version is found, all tests are skipped.  If a
version is found, the test proceeds as if C<all_minimum_version_ok> had been
called with that version.

=head2 all_minimum_version_from_mymetayml_ok

  all_minimum_version_from_mymetayml_ok(\%arg);

This routine checks F<MYMETA.yml> for an entry in F<requires> for F<perl>.  If
no MYMETA.yml file or no perl version is found, all tests are skipped.  If a
version is found, the test proceeds as if C<all_minimum_version_ok> had been
called with that version.

=head2 all_minimum_version_from_mymetajson_ok

  all_minimum_version_from_mymetajson_ok(\%arg);

This routine checks F<MYMETA.json> for an entry in F<requires> for F<perl>.  If
no MYMETA.json file or no perl version is found, all tests are skipped.  If a
version is found, the test proceeds as if C<all_minimum_version_ok> had been
called with that version.

=head1 AUTHOR

Ricardo Signes

=head1 CONTRIBUTORS

=for stopwords Ricardo SIGNES Signes Steve Hay

=over 4

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Steve Hay <steve.m.hay@googlemail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
