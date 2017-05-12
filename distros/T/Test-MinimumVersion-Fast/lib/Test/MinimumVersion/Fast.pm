package Test::MinimumVersion::Fast;
use 5.008005;
use strict;
use warnings;
use parent 'Exporter';

our $VERSION = "0.04";

use File::Find::Rule;
use File::Find::Rule::Perl;
use Perl::MinimumVersion::Fast 0.03;
use YAML::Tiny 1.40; # bug fixes
use version 0.70;

use Test::Builder;
our @EXPORT = qw(
  minimum_version_ok
  all_minimum_version_ok
  all_minimum_version_from_metayml_ok
);

sub import {
  my($self) = shift;
  my $pack = caller;

  my $Test = Test::Builder->new;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, @EXPORT);
}

sub _objectify_version {
  my ($version) = @_;
  $version = eval { $version->isa('version') } 
           ? $version
           : version->new($version);
}


sub minimum_version_ok {
  my ($file, $version) = @_;

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my $pmv = Perl::MinimumVersion::Fast->new($file);

  my $explicit_minimum = $pmv->minimum_version || 0;
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


sub all_minimum_version_ok {
  my ($version, $arg) = @_;
  $arg ||= {};
  $arg->{paths} ||= [ qw(lib t xt/smoke), glob ("*.pm"), glob ("*.PL") ];

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

  unless ($Test->has_plan or $arg->{no_plan}) {
    $Test->plan(tests => scalar @perl_files);
  }

  minimum_version_ok($_, $version) for @perl_files;
}


sub all_minimum_version_from_metayml_ok {
  my ($arg) = @_;
  $arg ||= {};

  my $Test = Test::Builder->new;

  $Test->plan(skip_all => "META.yml could not be found")
    unless -f 'META.yml' and -r _;

  my $documents = YAML::Tiny->read('META.yml');

  $Test->plan(skip_all => "no minimum perl version could be determined")
    unless my $version = $documents->[0]->{requires}{perl};

  all_minimum_version_ok($version, $arg);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::MinimumVersion::Fast - does your code require newer perl than you think?

=head1 SYNOPSIS

    #!perl
    use Test::MinimumVersion;
    all_minimum_version_from_metayml_ok();

=head1 DESCRIPTION

Test::MinimumVersion::Fast is a faster implementation of L<Test::MinimumVersion> using L<Perl::MinimumVersion::Fast>.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

