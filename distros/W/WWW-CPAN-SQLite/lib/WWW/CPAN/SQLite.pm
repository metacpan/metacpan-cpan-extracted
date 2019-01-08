package WWW::CPAN::SQLite;

# $Id: SQLite.pm 68 2019-01-04 00:15:58Z stro $

use strict;
use warnings;

use File::Spec;
use FindBin::Real;
use Plack::Middleware::Static;
use Plack::MIME;
use MIME::Types;

Plack::MIME->add_type('.sqlite' => 'application/x-sqlite3');
Plack::MIME->set_fallback(sub { (MIME::Types::by_suffix $_[0])[0] });

our $VERSION = 1.001;

sub new {
    my $class = shift;

    my $static_dir = FindBin::Real::Bin();
    if ($static_dir =~ m!bin$!) {
        $static_dir = File::Spec->catfile(FindBin::Real::Bin(), '..');
    }

    return bless {
        'files_to_keep' => 10,
        'ttl'           => 180,
        'last_check'    => 0,
        'next_check'    => 0,
        'static_dir'    => File::Spec->catfile($static_dir, 'static'),
        'last_file'     => '',
    }, $class;
}

sub run {
    my $self = shift;

    my $app = sub { $self->psgi(@_) };

    return Plack::Middleware::Static->wrap(
        $app,
        'path' => sub { s!^/static/!! },
        'root' => 'static/',
    );
}

sub psgi {
    my $self = shift;
    my ($env) = @_;

    if (time > $self->{'next_check'}) {
        if (opendir my $DIR, $self->{'static_dir'}) {
            my @files = sort { $b cmp $a } grep { m!\.sqlite$! } readdir $DIR;
            closedir $DIR;
            while (my $path = shift @files) {
                if (-s File::Spec->catfile($self->{'static_dir'}, $path)) {
                    $self->{'last_file'} = $path;
                    $self->{'last_check'} = time;
                    $self->{'next_check'} = $self->{'last_check'} + $self->{'ttl'};
                    return [ 302, [ 'Location' => '/static/' . $path ], [ $path ] ];
                }
            }
            return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'No index files, build your own' ] ];
        } else {
            mkdir $self->{'static_dir'};
            return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'No index files, build your own' ] ];
        }
    } else {
        if (my $path = $self->{'last_file'}) {
            return [ 302, [ 'Location' => '/static/' . $path ], [ $path ] ];
        } else {
            return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'No index files, build your own' ] ];
        }
    }
}

1;

=head1 NAME

WWW::CPAN::SQLite - generate and provide precompiled CPAN::SQLite database

=head1 VERSION

version 1.001

=head1 DESCRIPTION

This package is used to generate and provide pre-compiled L<CPAN::SQLite> database.

If you use DarkPAN and multiple CPAN clients that shouldn't use too much
resources, or clients that have no access to the internet, you may want
to create your own database. Otherwise, there's little use for you as you
can use the existing database provided on cpansqlite.trouchelle.com.

=head1 AUTHOR

Serguei Trouchelle E<lt>stro@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019 by Serguei Trouchelle E<lt>stro@cpan.orgE<gt>.

Use and redistribution are under the same terms as Perl itself.

=cut
