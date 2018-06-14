package Test::PAUSE::Permissions;

use strict;
use warnings;
use parent 'Exporter';
use Test::More;
use Parse::LocalDistribution;

our $VERSION = '0.07';

our @EXPORT = (@Test::More::EXPORT, qw/all_permissions_ok/);

sub all_permissions_ok {
  my ($author, $opts) = ref $_[0] ? (undef, @_) : @_;
  $opts ||= {};

  plan skip_all => 'Set RELEASE_TESTING environmental variable to test this.' unless $ENV{RELEASE_TESTING};

  # Get your id from .pause
  $author ||= _get_pause_user();

  plan skip_all => "Can't determine who is going to release." unless $author;

  # Get authority from META
  my $meta_authority ||= _get_authority_in_meta();

  local $Parse::PMFile::ALLOW_DEV_VERSION = 1 if $opts->{dev};

  # Get packages (respecting no_index)
  my $provides = Parse::LocalDistribution->new->parse();

  # Get maintainers from 06perms or MetaCPAN
  my $use_metacpan = $opts->{metacpan} || $ENV{TEST_PAUSE_PERMISSIONS_METACPAN};
  my $maintainers = _get_maintainers($use_metacpan, [keys %$provides]);

  # Iterate
  my $saw_errors;
  my @authorities = grep $_, $author, $meta_authority;
  my %new_packages;
  my %dist_maintainers = map {uc $_ => 1} @authorities;
SKIP:
  for my $package (keys %$provides) {
    my $authority = uc($meta_authority || $author || '');

    my $module_maintainers = $maintainers->{$package};

    if (!$module_maintainers) {
      pass "$package: no one has permissions ($authority should have the first come)";
      $new_packages{$package} = 1;
      next;
    }
    $dist_maintainers{uc $_} = 1 for @$module_maintainers;

    # Author should have permissions, regardless of the authority
    if (grep { uc $_ eq uc $author } @$module_maintainers) {
      pass "$package: $author has a permission";
    }
    else {
      fail "$package: maintained by ".join ', ', @$module_maintainers;
      $saw_errors = 1;
    }

    # $AUTHORITY has no effect in PAUSE.
    # just see if $AUTHORITY matches x_authority for information
    if ($meta_authority) {
      my $file_authority = _get_authority_in_file($package, $provides->{$package});
      if ($file_authority && $file_authority ne $meta_authority) {
        # XXX: should fail?
        diag "$package: \$AUTHORITY ($file_authority) doesn't match x_authority ($meta_authority)";
      }
    }
  }

  # There are several known IDs that won't maintain any package
  delete $dist_maintainers{$_} for qw/ADOPTME HANDOFF NEEDHELP LOCAL/;

  # GH #3: Adding a new module to an established distribution maintained by a large group may cause
  # an annoying permission problem.
  if (
    !$saw_errors  # having errors already means there's someone (ie. you) who can't upload it
    and %new_packages # no problem if no new module is added
    and (keys %new_packages < keys %$provides) # no problem if everything is new
    and (keys %dist_maintainers > @authorities) # no problem if maintainers are few and everyone gets permissions
  ) {
    delete $dist_maintainers{$_} for @authorities;
    my $message = "Some of the maintainers of this distribution (@{[sort keys %dist_maintainers]}) won't have permissions for the following package(s): @{[sort keys %new_packages]}.";
    if ($opts->{strict}) {
      fail $message;
    } else {
      diag "[WARNING] $message\n(This may or may not be a problem, depending on the policy of your team.)";
    }
  }

  done_testing;
}

sub _get_pause_user {
  # Get authority from ~/.pause
  require Config::Identity::PAUSE;
  my %config = Config::Identity::PAUSE->load;
  return $config{user};
}

sub _get_authority_in_meta {
  # Get authority from META
  my $meta = _parse_meta();
  if ($meta && $meta->{x_authority}) {
    my $authority = $meta->{x_authority};
    $authority =~ s/^cpan://i;
    return $authority;
  }
}

sub _parse_meta {
  for my $file (qw/META.json META.yml/) {
    next unless -f $file && -r _;
    my $meta = Parse::CPAN::Meta->load_file($file);
    return $meta if $meta && ref $meta eq ref {};
  }
}

sub _get_authority_in_file {
  my ($package, $package_info) = @_;
  my $file = $package_info->{infile};
  return unless $file && -f $file && -r _;

  open my $fh, '<', $file or return;
  my $in_pod = 0;
  while(<$fh>) {
    last if /__(DATA|END)__/;
    $in_pod = /^=(?!cut?)/ ? 1 : /^=cut/ ? 0 : $in_pod;
    next if $in_pod;

    if (/\$(?:${package}::)?AUTHORITY\s*=.+?(?i:cpan):([A-Za-z0-9]+)/) {
      return $1;
    }
  }
}

sub _get_maintainers {
  my ($use_metacpan, $modules) = @_;
  if ($use_metacpan) {
    eval { require PAUSE::Permissions::MetaCPAN };
    die "To use MetaCPAN permission API, "
      . "you need to install PAUSE::Permissions::MetaCPAN, $@" if $@;
    my $perms = PAUSE::Permissions::MetaCPAN->new->get(modules => $modules);
    my %maintainers;
    for my $module (@$modules) {
      $maintainers{$module} = $perms->{$module}
        ? [ $perms->{$module}{owner}, @{$perms->{$module}{co_maintainers}} ] : undef;
    }
    \%maintainers;
  } else {
    require PAUSE::Permissions;
    my $file = PAUSE::Permissions->new;
    my %maintainers;
    for my $module (@$modules) {
      my $mp = $file->module_permissions($module);
      $maintainers{$module} = $mp ? [$mp->all_maintainers] : undef;
    }
    \%maintainers;
  }
}

1;

__END__

=head1 NAME

Test::PAUSE::Permissions - tests module permissions in your distribution

=head1 SYNOPSIS

    # in your xt/perms.t

    use Test::PAUSE::Permissions;
    
    all_permissions_ok();

=head1 DESCRIPTION

This module is to test if modules in your distribution have proper
permissions or not. You need to set RELEASE_TESTING to test this.

If your distribution has modules/packages that should not be
indexed, you might want to generate META files before you run this
test to provide C<no_index> information to Test::PAUSE::Permissions.

You might also want to prepare C<.pause> file to show who is
releasing the distribution (you should have one to release
distributions anyway).

=head1 FUNCTION

This module exports only one function (yet):

=head2 all_permissions_ok

Looks for packages with L<Parse::LocalDistribution>, and tests
if you have proper permissions for them by L<PAUSE::Permissions>,
which downloads C<06perms.txt> from CPAN before testing.

By default, C<all_permissions_ok> looks into C<.pause> file
to find who is releasing the distribution.

You can also pass the author as an argument, though this is only
useful when you generate this test every time you release a
distribution.

    use Test::PAUSE::Permissions;
    
    # assumes ISHIGAKI is going to release the distribution
    all_permissions_ok('ISHIGAKI');

C<all_permissions_ok> also looks into META files for <x_authority>,
and each .pm file for C<$AUTHORITY> variable, for your information.

You can pass an optional hash reference to C<all_permissions_ok()>
to change its behavior.

=head3 strict mode

    all_permissions_ok({strict => 1});

If this is set, C<all_permissions_ok> would fail if the following
conditions should be met:

=over 4

=item the distribution is maintained by more than one person
(or two people if C<x_authority> is set).

=item the uploader has added a new indexable package.

=item and the distribution itself is not newly created.

=back

In the case above, if the uploader uploads the distribution,
permission to the new package is only given to the uploader
(and the author specified in C<x_authority> if applicable),
and other maintainers will not be able to upload the distribution
appropriately until they are given permission to the
new package. Strict mode is to prevent such an (accidental)
addtion so that everyone in a team can upload without a problem.

=head3 test also modules with a developer version

    all_permissions_ok({dev => 1});

This module ignores modules that won't be indexed (namely those
that have a version number with an underscore in it) by default.
If you do want to test them, set C<dev> to true.

=head3 use MetaCPAN API for testing permissions

    all_permissions_ok({metacpan => 1});

If C<metacpan> is true, this module tests permissions via MetaCPAN API
instead of C<06perms.txt> using L<PAUSE::Permissions::MetaCPAN>.
You can also set an environment variable C<TEST_PAUSE_PERMISSIONS_METACPAN> true
to use MetaCPAN API.

=head1 SEE ALSO

L<PAUSE::Permissions>, L<App::PAUSE::CheckPerms>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
