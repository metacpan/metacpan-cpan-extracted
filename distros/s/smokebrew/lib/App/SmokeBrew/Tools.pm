package App::SmokeBrew::Tools;
$App::SmokeBrew::Tools::VERSION = '0.48';
#ABSTRACT: Various utility functions for smokebrew

use strict;
use warnings;
use Archive::Extract;
use File::Fetch;
use File::Spec;
use List::MoreUtils qw[uniq];
use Module::CoreList;
use Perl::Version;
use URI;

my @mirrors = (
  'http://www.cpan.org/',
  'http://cpan.cpantesters.org/',
  'http://cpan.hexten.net/',
  'ftp://ftp.funet.fi/pub/CPAN/',
);

sub fetch {
  my $fetch = shift;
  $fetch = shift if $fetch->isa(__PACKAGE__);
  return unless $fetch;
  my $loc = shift || return;
  my $mirrors = shift;
  $mirrors = \@mirrors unless
    $mirrors and ref $mirrors eq 'ARRAY' and scalar @{ $mirrors };
  $loc = File::Spec->rel2abs($loc);
  my $stat;
  foreach my $mirror ( @{ $mirrors } ) {
    my $uri = URI->new( ( $mirror->isa('URI') ? $mirror->as_string : $mirror ) );
    $uri->path_segments( ( grep { $_ } $uri->path_segments ), split(m!/!, $fetch) );
    my $ff = File::Fetch->new( uri => $uri->as_string );
    $stat = $ff->fetch( to => $loc );
    last if $stat;
  }
  return $stat;
}

sub extract {
  my $file = shift;
  $file = shift if $file->isa(__PACKAGE__);
  return unless $file;
  my $loc = shift || return;
  $loc = File::Spec->rel2abs($loc);
  local $Archive::Extract::PREFER_BIN=1;
  my $ae = Archive::Extract->new( archive => $file );
  return unless $ae;
  return unless $ae->extract( to => $loc );
  return $ae->extract_path();
}

sub smokebrew_dir {
  return $ENV{PERL5_SMOKEBREW_DIR}
     if  exists $ENV{PERL5_SMOKEBREW_DIR}
     && defined $ENV{PERL5_SMOKEBREW_DIR};

  my @os_home_envs = qw( APPDATA HOME USERPROFILE WINDIR SYS$LOGIN );

  for my $env ( @os_home_envs ) {
      next unless exists $ENV{ $env };
      next unless defined $ENV{ $env } && length $ENV{ $env };
      return $ENV{ $env } if -d $ENV{ $env };
  }

  return cwd();
}

sub perls {
  my $type = shift;
  $type = shift if $type->isa(__PACKAGE__);
  if ( $type and $type eq 'latest' ) {
    my %perls;
    foreach my $pv ( map { Perl::Version->new($_) } perls('recent') ) {
      my $vers = $pv->version;
      unless ( exists $perls{$vers} ) {
        $perls{$vers} = $pv;
        next;
      }
      $perls{$vers} = $pv if $pv > $perls{$vers};
    }
    return map { _format_version($_) } map { $perls{$_} }
      sort { $perls{$a} <=> $perls{$b} } keys %perls;
    ;
  }
  unless ( $type and $type =~ /^(rel|dev|recent|modern)$/i ) {
    $type =~ s/[^\d\.]+//g if $type;
  }
  return
  uniq
  map { _format_version($_) }
  grep {
      if ( $type and $type eq 'rel' ) {
          _is_rel($_) and !_is_ancient($_);
      }
      elsif ( $type and $type eq 'dev' ) {
          _is_dev($_) and !_is_ancient($_);
      }
      elsif ( $type and $type eq 'recent' ) {
          _is_recent($_);
      }
      elsif ( $type and $type eq 'modern' ) {
          _is_modern($_);
      }
      elsif ( $type ) {
          $_->normal =~ /\Q$type\E$/;
      }
      else {
          _is_dev($_) or _is_rel($_) and !_is_ancient($_);
      }
  }
  map { Perl::Version->new($_) }
  map { $_ >= 5.006 ? sprintf('%.6f', $_) : $_ }
  sort keys %Module::CoreList::released;
}

sub _is_dev {
  my $pv = shift;
  return 0 if _is_ancient($pv);
  return $pv->version % 2;
}

sub _is_rel {
  my $pv = shift;
  return 0 if _is_ancient($pv);
  return !( $pv->version % 2 );
}

sub _is_recent {
  my $pv = shift;
  return 0 if _is_ancient($pv);
  return 0 if _is_dev($pv);
  return 1 if $pv->numify >= 5.008009;
  return 0;
}

sub _is_modern {
  my $pv = shift;
  return 0 if _is_ancient($pv);
  return 0 if _is_dev($pv);
  return 1 if $pv->numify >= 5.010000;
  return 0;
}

sub _is_ancient {
  my $pv = shift;
  ( my $numify = $pv->numify ) =~ s/_//g;
  return 1 if $numify < 5.006;
  return 0;
}

sub _format_version {
  my $pv = shift;
  my $numify = $pv->numify;
  $numify =~ s/_//g;
  return $pv if $numify < 5.006;
  my $normal = $pv->normal();
  $normal =~ s/^v//g;
  return $normal;
}

sub perl_version {
  my $vers = shift;
  $vers = shift if eval { $vers->isa(__PACKAGE__) };
  my $version = Perl::Version->new( $vers );
  ( my $numify = $version->numify ) =~ s/_//g;
  my $pv = 'perl'.( $numify < 5.006 ? $version->numify : $version->normal );
  $pv =~ s/perlv/perl-/g;
  return $pv;
}

sub devel_perl {
  my $perl = shift;
  $perl = shift if eval { $perl->isa(__PACKAGE__) };
  return unless $perl;
  return _is_dev( Perl::Version->new( $perl ) );
}

qq[Smoke tools look what's inside of you];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew::Tools - Various utility functions for smokebrew

=head1 VERSION

version 0.48

=head1 SYNOPSIS

  use strict;
  use warnings;
  use App::SmokeBrew::Tools;

  # Fetch a perl source tarball
  my $filename = App::SmokeBrew::Tools->fetch( $path_to_fetch, $where_to_fetch_to );

  # Extract a tarball
  my $extracted_loc = App::SmokeBrew::Tools->extract( $tarball, $where_to_extract_to );

  # Find the smokebrew directory
  my $dir = App::SmokeBrew::Tools->smokebrew_dir();

  # Obtain a list of perl versions
  my @perls = App::SmokeBrew::Tools->perls(); # All perls >= 5.006

  my @stables = App::SmokeBrew::Tools->perls( 'rel' );

  my @devs = App::SmokeBrew::Tools->perls( 'dev' );

  my @recents = App::SmokeBrew::Tools->perls( 'recent' );

  my $perl = '5.13.0';

  if ( App::SmokeBrew::Tools->devel_perl( $perl ) ) {
     print "perl ($perl) is a development perl\n";
  }

=head1 DESCRIPTION

App::SmokeBrew::Tools provides a number of utility functions for L<smokebrew>.

=head1 FUNCTIONS

=over

=item C<fetch>

Requires two mandatory parameters and one optional. The first two parameters are the path to
fetch from a CPAN mirror and the file system path where you want the file fetched to.
The third, optional parameter, is an arrayref of CPAN mirrors that you wish the file to fetched from.

Returns the path to the fetched file on success, false otherwise.

This function is a wrapper around L<File::Fetch>.

=item C<extract>

Requires two mandatory parameters, the path to a file that you wish to be extracted and the file system
path of where you wish the file to be extracted to. Returns the path to the extracted file on success,
false otherwise.

This function is a wrapper around L<Archive::Extract>.

=item C<smokebrew_dir>

Returns the path to where the C<.smokebrew> directory may be found.

=item C<perls>

Returns a list of perl versions. Without a parameter returns all perl releases >= 5.006

Specifying C<rel> as the parameter will return all C<stable> perl releases >= 5.006

Specifying C<dev> as the parameter will return only the C<development> perl releases >= 5.006

Specifying C<recent> as the parameter will return only the C<stable> perl releases >= 5.008009

=item C<devel_perl>

Takes one parameter a perl version to check.

Returns true if given perl is a development perl.

=item C<perl_version>

Takes one parameter a perl version.

Returns the version with the C<perl-> prefix.

=back

=head1 SEE ALSO

L<smokebrew>

L<Perl::Version>

L<File::Fetch>

L<Archive::Extract>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
