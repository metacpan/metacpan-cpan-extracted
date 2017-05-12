package WWW::PGXN::Distribution;

use 5.8.1;
use strict;
use File::Spec;
use Carp;
our $VERSION = v0.12.4;

BEGIN {
    # XXX Use DateTime for release date?
    # XXX Use Software::License for license?
    # XXX Use SemVer for versions?
    for my $attr (qw(
        abstract
        license
        name
        version
        description
        generated_by
        date
        release_status
        sha1
        user
    )) {
        no strict 'refs';
        *{$attr} = sub {
            $_[0]->_merge_meta unless $_[0]->{version};
            $_[0]->{$attr}
        };
    }

    # Hash accessors.
    for my $attr (qw(
        no_index
        prereqs
        provides
        resources
    )) {
        no strict 'refs';
        *{$attr} = sub { +{ %{ shift->{$attr} || {} } } };
    }
}

sub new {
    my ($class, $pgxn, $data) = @_;
    $data->{_pgxn} = $pgxn;
    bless $data, $class;
}

# Merging accessors.
sub releases {
    my $self = shift;
    $self->_merge_by_dist unless $self->{releases};
    return +{ %{ $self->{releases} } };
}

sub docs {
    my $self = shift;
    $self->_merge_meta unless $self->{version};
    return +{ %{ $self->{docs} || {} } };
}

# List accessors.
sub tags          { @{ shift->{tags}             || [] } }
sub maintainers   { @{ shift->{maintainer}       || [] } }
sub special_files { @{ shift->{special_files}    || [] } }
sub versions_for  { map { $_->{version} } @{ shift->releases->{+shift} || [] } }

# Instance methods.
sub version_for  { shift->releases->{+shift}[0]{version} }
sub date_for     { shift->releases->{+shift}[0]{date} }

sub _merge_meta {
    my $self = shift;
    my $rel = $self->{releases};
    my $rels = $rel->{stable} || $rel->{testing} || $rel->{unstable};
    my $meta = $self->{_pgxn}->_fetch_json(meta => {
        version => lc $rels->[0]{version},
        dist    => lc $self->{name},
    }) || {};
    @{$self}{keys %{ $meta }} = values %{ $meta };
}

sub _merge_by_dist {
    my $self = shift;
    my $by_dist = $self->{_pgxn}->_fetch_json(dist => {
        dist => lc $self->{name}
    }) || {};
    @{$self}{keys %{ $by_dist }} = values %{ $by_dist };
}

sub download_url {
    my $self = shift;
    $self->{_pgxn}->_url_for(download => {
        dist    => lc $self->name,
        version => lc $self->version
    });
}

sub download_path {
    my $self = shift;
    $self->{_pgxn}->_path_for(download => {
        dist    => lc $self->name,
        version => lc $self->version
    });
}

sub download_to {
    my $self = shift;
    $self->{_pgxn}->_download_to(shift, {
        dist    => lc $self->name,
        version => lc $self->version
    });
}

sub source_url {
    my $self = shift;
    my $uri = $self->source_path or return;
    return URI->new($self->{_pgxn}->url . $uri);
}

sub source_path {
    my $self = shift;
    my $tmpl = $self->{_pgxn}->_uri_templates->{source} or return;
    return $tmpl->process(
        dist    => lc $self->name,
        version => lc $self->version
    );
}

sub url_for_html_doc {
    my $self = shift;
    my $uri = $self->path_for_html_doc(shift) or return;
    return URI->new($self->{_pgxn}->url . $uri);
}

sub path_for_html_doc {
    my ($self, $path) = @_;
    $self->_merge_meta unless $self->{version};
    return unless $self->{docs} && $self->{docs}{$path};

    my $tmpl = $self->{_pgxn}->_uri_templates->{htmldoc} or return;
    $tmpl->process(
        dist    => lc $self->name,
        version => lc $self->version,
        docpath => $path,
    );
}

sub body_for_html_doc {
    my $self = shift;
    my $url = $self->url_for_html_doc(shift) or return;
    my $res = $self->{_pgxn}->_fetch($url) or return;
    utf8::decode $res->{content};
    return $res->{content};
}

1;

__END__

=head1 Name

WWW::PGXN::Distribution - Distribution metadata fetched from PGXN

=head1 Synopsis

  my $pgxn = WWW::PGXN->new( url => 'http://api.pgxn.org/' );
  my $dist = $pgxn->get_distribution('pgTAP');
  $dist->download_to('.');

=head1 Description

This module represents PGXN distribution metadata fetched from PGXN>. It is
not intended to be constructed directly, but via the
L<WWW::PGXN/get_distribution> method of L<WWW::PGXN>.

=head1 Interface

=begin private

=head2 Constructor

=head3 C<new>

  my $distribution = WWW::PGXN::Distribution->new($distribution, $data);

Construct a new WWW::PGXN::Distribution object. The first argument must be
an instance of L<WWW::PGXN> that connected to the PGXN server. The second
argument must be the data fetched.

=end private

=head2 Instance Accessors

=head3 C<name>

  my $name = $distribution->name;
  $distribution->name($name);

The name of the distribution.

=head3 C<version>

  my $version = $distribution->version;
  $distribution->version($version);

The distribution version distribution. Returned as a string, but may be passed
to L<SemVer> for comparing versions.

  use SemVer;
  my $version = SemVer->new( $distribution->version );

This interface may be modified in the future to return a L<SemVer> object
itself.

=head3 C<abstract>

  my $abstract = $distribution->abstract;
  $distribution->abstract($abstract);

The abstract for the distribution, a very brief description.

=head3 C<license>

  my $license = $distribution->license;
  $distribution->license($license);

The license for the distribution, usually a simple string such as "gpl_3" or
"postgresql". See the L<PGXN Meta spec|http://pgxn.org/meta/spec.html#license>
for details.

=head3 C<user>

  my $user = $distribution->user;
  $distribution->user($user);

The nickname of the user who released the distribution. Use the
L<WWW::PGXN/get_user> method of L<WWW::PGXN> to get more info on the user:

  my $user = $pgxn->get_user( $distribution->user );
  say "Released by ", $user->name, ' <', $user->email, '>';

=head3 C<description>

  my $description = $distribution->description;
  $distribution->description($description);

The distribution description, longer than the abstract.

=head3 C<generated_by>

  my $generated_by = $distribution->generated_by;
  $distribution->generated_by($generated_by);

The name of the person or application that generated the metadata from which
this distribution object is created.

=head3 C<date>

  my $date = $distribution->date;
  $distribution->date($date);

The date the distribution was released on PGXN. Represented as a string in
strict L<ISO-8601|http://en.wikipedia.org/wiki/ISO_8601> format and in the UTC
time zone. It may be parsed into a L<DateTime> object like so:

  use DateTime::Format::Strptime;
  my $parser = DateTime::Format::Strptime->new(
      pattern   => '%FT%T',
      time_zone => 'Z'
  );
  my $date = $parser->parse_datetime( '2010-10-29T22:46:45Z' );

This interface may be modified in the future to return a L<DateTime> object
itself.

=head3 C<release_status>

  my $release_status = $distribution->release_status;
  $distribution->release_status($release_status);

The release_status of the distribution. Should be one of:

=over

=item stable

=item testing

=item unstable

=back

=head3 C<sha1>

  my $sha1 = $distribution->sha1;
  $distribution->sha1($sha1);

The SHA-1 digest for the distribution. You can validate the distribution file
like so:

  use Digest::SHA1;
  my $file = $distribution->download_to('.');
  open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
  my $sha1 = Digest::SHA1->new;
  $sha1->addfile($fh);
  warn $distribution->name . ' ' . $distribution->version
      . ' does not validate against SHA1'
      unless $sha1->hexdigest eq $distribution->sha1;

=head2 Instance Methods

=head3 C<maintainers>

  my @maintainers = $distribution->maintainers;

Returns a list of the maintainers of the module. By the recommendation of the
L<PGXN Meta spec|http://pgxn.org/meta/spec.html#maintainer>, each should be
formatted with a name and email address suitable for on the recipient line of
an email.

=head3 C<special_files>

  my @special_files = $distribution->special_files;

Returns a list of special files in the distribution, such as C<Changes>,
C<README>, C<Makefile>, and C<META.json>, among others. Available only from an
API server. Returns an empty list for distributions fetched from a mirror.

=head3 C<docs>

  my $docs = $distribution->docs;

Returns a hash reference describing the documentation in the distribution. The
keys are paths to documentation files, and the values are hashes with at least
one key, C<title> which contains the title, of course. A second key,
C<abstract>, is optional and contains an abstract of the document. The
documentation files are stored as HTML and may be fetched via
C<body_for_html_doc()>.

=head3 C<no_index>

  my $no_index = $distribution->no_index;

Returns a hash reference describing files and directories that should not be
indexed by search engines or the PGXN infrastructure. The L<PGXN Meta
spec|http://pgxn.org/meta/spec.html#no_index> specifies that the structure of
this hash contain only these keys:

=over

=item C<file>

An array of file names.

=item C<directory>

An array of directory names.

=back

The returned has will be empty if all files may be indexed.

=head3 C<prereqs>

  my $prereqs = $distribution->prereqs;

Returns a hash reference describing the prerequisites of the extension. The
L<PGXN Meta spec|http://pgxn.org/meta/spec.html#prereqs> dictates That the top
level keys of this hash may be any of:

=over

=item C<configure>

=item C<build>

=item C<test>

=item C<runtime>

=item C<develop>

=back

The value for each of these keys must be a hash reference describing the
prerequisites for that part of the extension lifecycle. The keys in this
secondary hash may be any of:

=over

=item C<requires>

=item C<recommends>

=item C<suggests>

=back

Each of these in turn points to another hash reference, the keys of which are
the names of the prerequisite extensions and the values are their minimum
required version numbers. See the
L<Prereq Spec|http://pgxn.org/meta/spec.html#Prereq.Spec> for further
explication of these phases and relationships. Here's an example of what a
typical C<prereqs> hash might look like:

  {
    prereqs => {
      runtime => {
        requires => {
          PostgreSQL => '8.0.0',
          PostGIS    => '1.5.0'
        },
        recommends => {
          PostgreSQL => '8.4.0'
        },
        suggests => {
          semver => 0
        },
      },
      build => {
        requires => {
          prefix => 0
        },
      },
      test => {
        recommends => {
          pgTAP   => 0
        },
      }
    }
  }

=head3 C<provides>

  my $provides = $distribution->provides;

Returns a hash reference describing the resources provided by the
distribution. The keys are the names of the resources (generally extension
names) and their values are hash references describing them. The keys
available in these hashes include:

=over

=item C<file>

The name of the file in which the resource is defined.

=item C<version>

The L<semantic version|SemVer> of the resource.

=item C<abstract>

A brief description of the resource.

=item C<docfile>

A path to the documentation file for the resource, if any.

=item C<docpath>

A path to the documentation for the resource, usually the same as C<docfile>
but without the file name extension. So if C<docfile> is F<docs/pair.txt>,
C<docpath> would be F<docs/pair>. Provided only by the API server. May be
present even if C<docfile> is not, since the API might have found the
documentation even if the release manager didn't specify it in the
F<META.json>.

=back

Here's an example of the structure for a simple distribution that provides a
single extension:

  {
     pair => {
        abstract => 'A key/value pair data type',
        file     => 'sql/pair.sql',
        version  => '0.1.1',
        docfile  => 'doc/pair.md',
        docpath  => 'doc/pair',
     }
  }

See the <spec|http://pgxn.org/meta/spec.html#provides> for more information.

=head3 C<releases>

  my $releases = $distribution->releases;

Returns a hash reference providing version and date information for all
releases of the distribution. The hash reference must have one or more of the
following keys:

=over

=item C<stable>

=item C<testing>

=item C<unstable>

An array reference containing hashes of versions and release dates of all
releases of the distribution with the named release status, ordered from most
to least recent.

=back

Here's an example of the C<releases> data structure:

  {
      stable => [
          { version => '0.1.1', date => '2010-10-22T16:32:52Z' },
          { version => '0.1.0', date => '2010-10-19T03:59:54Z' }
      ],
      testing => [
          { version => '0.0.1', date => '2010-09-23T14:23:52Z' }
      ]
  }

=head3 C<resources>

  my $resources = $distribution->resources;

Returns a hash reference describing the resources for the distribution. These
include source code repository information, bug reporting addresses, and the
like. Example:

  {
     bugtracker => {
        web => 'http://github.com/theory/kv-pair/issues/'
     },
     repository => {
        type => 'git',
        url  => 'git://github.com/theory/kv-pair.git',
        web  => 'http://github.com/theory/kv-pair/'
     },
  }

Read the
L<Resources section of the meta spec|http://pgxn.org/meta/spec.html#resources>
for all the details.

=head3 C<tags>

  my @tags = $distribution->tags;

Returns a list of the tags associated with the distribution. Each may be used
to look up further information about the tag via L<WWW::PGXN::Tag> objects
like so:

  for my $tag ( map { $pgxn->get_tag($_) } $distribution->tags ) {
      say $tag->name;
  }

=head3 C<download_url>

  my $url = $distribution->download_url;

The absolute URL for the distribution archive file on the mirror or API sever,
such as

  http://api.pgxn.org/dist/pair/pair-0.1.1.zip

Or, for a file system URL:

  file:/path/to/mirror/dist/pair/pair-0.1.1.zip

=head3 C<download_path>

  my $uri = $distribution->path;

The path to the distribution archive file. That is, the path relative to any
PGXN mirror root. So rather than the full URL you'd get from the C<url>
method, you just get the path as derived from the distribution URI template,
for example:

  /dist/pair/pair-0.1.1.zip

=head3 C<source_url>

  my $source_url = $distribution->source_url;

The absolute URL to the unzipped source on the API server, suitable for
browsing. For example:

  http://api.pgxn.org/src/pair/pair-0.1.1/

Or, for a file system URL:

  file:/path/to/mirror/src/pair/pair-0.1.1/

If connected to a mirror, rather than an API server, C<undef> will be
returned.

=head3 C<source_path>

  my $source_path = $distribution->source_path;

The path to the unzipped, browsable distribution. That is, the path relative
to any PGXN mirror root. So rather than the full URL you'd get from the
C<source_url> method, you just get the path as derived from the distribution
URI template, for example:

  /src/pair/pair-0.1.1/

=head3 C<download_to>

  my file = $distribution->download_to('.');
  $distribution->download_to('myfile.zip');

Downloads the distribution. Pass the name of the file to save to, or the name
of a directory. If a directory is specified, the file will be written with the
same name as it has on PGXN, such as C<pgtap-0.24.0.zip>. Either way, the name
of the file written will be returned. Regardless of the file's name, it will
always be a zip archive.

=head3 C<version_for>

  my $version = $distribution->version_for('testing');

Returns the most recent version for a release status, if any exists. The
supported release statuses are:

=over

=item C<stable>

=item C<testing>

=item C<unstable>

=back

These version numbers can be used to fetch information specific to a version:

  my $test_dist = $pgxn->get_distribution(
      $distribution->name,
      $distribution->version_for('testing'),
  );

=head3 C<date_for>

  my $date = $distribution->date_for('unstable');

Like C<version_for()>, but returns the release date of the most recent version
for the given release status. The supported release statuses are:

=over

=item C<stable>

=item C<testing>

=item C<unstable>

=back

=head3 C<versions_for>

  my @versions = $distributions->versions_for('stable');

Returns a list of the versions for a particular release status, if any. The
are returned in order from most to least recent.

=head3 C<url_for_html_doc>

  # returns http://api.pgxn.org/dist/pair/pair-0.1.1/doc/pair.html
  my $doc_url = $distribution->url_for_html_doc('doc/pair');

The absolute URL to an HTML documentation file. Pass a document path to get
its URL. The keys in the C<docs> hash reference represent all known document
paths. If connected to a mirror, rather than an API server, C<undef> will be
returned. Otherwise, if not document exists at that path, an exception will be
thrown.

=head3 C<path_for_html_doc>

  # returns /dist/pair/pair-0.1.1/doc/pair.html
  my $doc_url = $distribution->path_for_html_doc('doc/pair');

The path to an HTML documentation file. Pass a document path to get its URL.
The keys in the C<docs> hash reference represent all known document paths. If
connected to a mirror, rather than an API server, C<undef> will be returned.
Otherwise, if not document exists at that path, an exception will be thrown.

=head3 C<body_for_html_doc>

  my $body = $distribution->body_for_html_doc('README');

Returns the body of an HTML document. Pass in the path to the doc (minus a
suffix) to retrieve its contents. They keys in the hash returned by C<docs>
provide the paths for all docs included in a distribution.

Note that docs are formatted as HTML fragments with no C<< <head> >> or
C<< <body> >> element, though they may be assumed to constitute the contents
of a C<< <body> >> element. They are also always encoded as UTF-8.

The contents are all contained within a single C<< <div> >> element with the
ID C<pgxndoc>, and include a table of contents. Here's a simple example of the
body of a document:

  <div id="pgxndoc">
    <div id="pgxntoc">
      <h3>Contents</h3>
      <ul class="pgxntocroot">
        <li><a href="#Title">Title</a></li>
      </ul>
    </div>
    <div id="pgxnbod">
      <h1 id="Title"><a href="/">Title</a></h1>
      <p>Blah blah blah</p>
      <p>Body</p>
    </div>
  </div>

The IDs used for contents are generated from C<h1>, C<h2>, and C<h3> elements;
all other IDs and classes begin with "pgxn" as seen in this example.

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
