package WWW::PGXN::Extension;

use 5.8.1;
use strict;

our $VERSION = v0.12.4;

BEGIN {
    # Hash accessors.
    for my $k (qw(
        stable
        testing
        unstable
    )) {
        no strict 'refs';
        *{"$k\_info"} = sub { +{ %{ shift->{$k} || {} } } };
    }
}

sub new {
    my ($class, $pgxn, $data) = @_;
    $data->{_pgxn} = $pgxn;
    bless $data, $class;
}

sub name   { shift->{extension} }
sub latest { shift->{latest} }

sub latest_info   {
    my $self = shift;
    return { %{ $self->{$self->{latest}} } };
}

sub stable_distribution   { shift->_dist_for_status('stable')   }
sub testing_distribution  { shift->_dist_for_status('testing')  }
sub unstable_distribution { shift->_dist_for_status('unstable') }

sub latest_distribution   {
    my $self = shift;
    $self->_dist_for_status($self->{latest});
}

sub distribution_for_version {
    my $self = shift;
    my $vdata = $self->info_for_version(shift) or return;
    return $self->{_pgxn}->get_distribution(@{ $vdata->[0] }{qw(dist version)});
}

sub info_for_version {
    my ($self, $version) = @_;
    $self->{versions}{$version};
}

sub _dist_for_status {
    my ($self, $status) = @_;
    my $vdata = $self->{$status} or return;
    return $self->{_pgxn}->get_distribution(@{ $vdata }{qw(dist version)});
}

sub download_stable_to {
    my $self = shift;
    $self->_download_to(shift, $self->{stable});
}

sub download_latest_to {
    my $self = shift;
    $self->_download_to(shift, $self->latest_info);
}

sub download_testing_to {
    my $self = shift;
    $self->_download_to(shift, $self->{testing});
}

sub download_unstable_to {
    my $self = shift;
    $self->_download_to(shift, $self->{unstable});
}

sub download_version_to {
    my ($self, $version, $file) = @_;
    my $info = $self->info_for_version($version) or return;
    $self->_download_to($file, $info->[0]);
}

sub _download_to {
    my ($self, $file, $info) = @_;
    return unless $info;
    $self->{_pgxn}->_download_to($file => {
        dist    => $info->{dist},
        version => $info->{version},
    });
}

1;

__END__

=head1 Name

WWW::PGXN::Extension - Extension metadata fetched from PGXN

=head1 Synopsis

  my $pgxn = WWW::PGXN->new( url => 'http://api.pgxn.org/' );
  my $ext  = $pgxn->get_extension('pgTAP');
  $ext->download_stable_to('.');

=head1 Description

This module represents PGXN extension metadata fetched from PGXN>. It is not
intended to be constructed directly, but via the L<WWW::PGXN/get_extension>
method of L<WWW::PGXN>.

=head1 Interface

=begin private

=head2 Constructor

=head3 C<new>

  my $extension = WWW::PGXN::Extension->new($pgxn, $data);

Construct a new WWW::PGXN::Extension object. The first argument must be an
instance of L<WWW::PGXN> that connected to the PGXN server. The second
argument must be the data fetched.

=end private

=head2 Instance Accessors

=head3 C<name>

  my $name = $extension->name;
  $extension->name($name);

The name of the extension.

=head3 C<latest>

  my $latest = $extension->latest;
  $extension->latest($latest);

The status of the latest release. Should be one of:

=over

=item stable

=item testing

=item unstable

=back

=head2 Instance Methods

=head3 C<stable_info>

=head3 C<testing_info>

=head3 C<unstable_info>

  my $stable_info   = $extension->stable_info;
  my $testing_info  = $extension->testing_info;
  my $unstable_info = $extension->unstable_info;

Returns a hash reference describing the latest version of the extension for
the named release status. The supported keys are:

=over

=item C<dist>

The name of the distribution in which the extension may be found.

=item C<version>

The version of the distribution in which the extension may be found.

=item C<abstract>

A brief description of the extension. Available only from PGXN API servers,
not mirrors.

=item C<sha1>

The SHA1 hash for the distribution archive file.

=item C<docpath>

A path to the documentation for the extension, if any.

=back

If no release has been made with the given status, an empty hash reference
will be returned. Here's an example of the structure for a distribution loaded
from an API server:

  {
      dist     => 'pair',
      version  => '0.1.1',
      abstract => 'A key/value pair data type',
      sha1     => 'c552c961400253e852250c5d2f3def183c81adb3',
      docpath  => 'doc/pair',
  }

=head3 C<latest_info>

  my $latest_info = $extension->latest_info;

Returns a hash reference describing the latest version of the extension.
Essentially a convenience method for:

    my $meth = $extension->latest . '_info';
    my $info = $extension->$meth;

=head3 C<info_for_version>

  my $version_info = $extension->info_for_version;

Returns a hash reference containing the distribution information for the named
version of the extension, if it exists. The supported keys are:

=over

=item C<dist>

The name of the distribution in which the version of the extension may be
found.

=item C<version>

The version of the distribution in which the version of the extension may be
found.

=item C<date>

The release date the distribution containing the version of the extension.
Available only from PGXN API servers, not mirrors.

Returns C<undef> if no such version of the extension exists.

=back

=head3 C<stable_distribution>

=head3 C<testing_distribution>

=head3 C<unstable_distribution>

  my $stable_distribution   = $extension->stable_distribution;
  my $testing_distribution  = $extension->testing_distribution;
  my $unstable_distribution = $extension->unstable_distribution;

Returns a L<WWW::PGXN::Distribution> object describing the distribution
containing the distribution with the named release status. Returns C<undef> if
no distribution contains the extension with that status.

=head3 C<latest_distribution>

Returns a L<WWW::PGXN::Distribution> object describing the distribution in
which the latest version of the extension is found. Essentially a convenience
method for:

    my $meth = $extension->latest . '_distribution';
    my $dist = $extension->$meth;

=head3 C<distribution_for_version>

  my $version_distribution = $extension->distribution_for_version($version);

Returns a L<WWW::PGXN::Distribution> object describing the distribution in
which the named version of the extension is found. Returns C<undef> if no such
version of the extension exists.

=head3 C<download_stable_to>

=head3 C<download_testing_to>

=head3 C<download_unstable_to>

  my $stable_file   = $extension->download_stable_to('/usr/src');
  my $testing_file  = $extension->download_testing_to('.');
  my $unstable_file = $extension->download_unstable_to('mfile.zip');

Downloads the distribution containing the latest version of the extension with
the named release status. Pass the name of the file to save to, or the name of
a directory. If a directory is specified, the file will be written with the
same name as it has on PGXN, such as C<pgtap-0.24.0.zip>. Either way, the name
of the file written will be returned. Regardless of the file's name, it will
always be a zip archive.

=head3 C<download_latest_to>

  my $file = $extension->download_latest_to($file);

Download the distribution containing the latest version of the distribution,
regardless of its release status. Essentially a convenience method for:

    my $meth = 'download_' . $extension->latest . '_to';
    my $file = $extension->$meth('.');

=head3 C<download_version_to>

  my $file = $extension->download_version_to($version, $file);

Download the distribution containing the specified version of the extension.

=head1 See Also

=over

=item * L<WWW::PGXN>

The main class to communicate with a PGXN mirror or API server.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/www-pgxn/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/www-pgxn/issues/> or by sending mail to
L<bug-WWW-PGXN@rt.cpan.org|mailto:bug-WWW-PGXN@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
