package WebService::Avalara::AvaTax::Role::Dumper;

# ABSTRACT: Dump and restore compiled SOAP clients for AvaTax

use strict;
use warnings;

our $VERSION = '0.020';    # VERSION
use utf8;

#pod =head1 SYNOPSIS
#pod
#pod     use Moo;
#pod     with 'WebService::Avalara::AvaTax::Role::Dumper';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role handles the dumping of compiled SOAP client code to storage,
#pod and then restoring it later to save time without having to recompile.
#pod
#pod =cut

use English '-no_match_vars';
use Moo::Role;
use Package::Stash;
use Path::Tiny 0.018;
use Types::Path::Tiny qw(Dir Path);
use Types::Standard qw(Bool Str);
use XML::Compile::Dumper;
use namespace::clean;

#pod =attr use_wss
#pod
#pod This role overrides the value of the
#pod L<use_wss attribute from WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection/use_wss>
#pod to false, since L<XML::Compile::WSS|XML::Compile::WSS> does not seem to
#pod work cleanly with L<XML::Compile::Dumper|XML::Compile::Dumper>.
#pod
#pod =cut

around BUILDARGS => sub {
    return { @_[ 2 .. $#_ ], use_wss => 0 };
};

#pod =cut
#pod
#pod =attr recompile
#pod
#pod A boolean value you can set at construction to signal that the generated
#pod class files for this service should be deleted and recompiled.
#pod Defaults to false.
#pod
#pod =cut

has recompile => ( is => 'ro', isa => Bool, default => 0 );

#pod =attr dump_dir
#pod
#pod The directory in which to save and look for the generated class files.
#pod Defaults to a temporary directory provided by
#pod L<Path::Tiny::tempdir|Path::Tiny>.
#pod
#pod =head1 CAVEATS
#pod
#pod The generated class files in the L</dump_dir> directory will be read and
#pod executed, therefore it is B<critical> that this directory is in a secure
#pod location on the file system that cannot be written to by untrusted users
#pod or processes!
#pod
#pod =cut

has dump_dir => ( is => 'lazy', isa => Dir, coerce => 1 );

sub _build_dump_dir {
    my $self = shift;
    my $dump_dir = Path::Tiny->tempdir( TEMPLATE => 'AvalaraDumpXXXXX' );
    unshift @INC => "$dump_dir";
    return $dump_dir;
}

#pod =attr dump_file_name
#pod
#pod The path to the file in L</dump_dir> used to save/read the generated classes.
#pod Defaults to F<< lib/I<package-name-converted-to-path.pm> >>.
#pod
#pod =cut

has dump_file_name => ( is => 'lazy', isa => Path, coerce => 1 );

sub _build_dump_file_name {
    my $self     = shift;
    my $dump_dir = $self->dump_dir;

    my $dump_file = $self->_package_name;
    $dump_file =~ s/ :: /\//xmsg;
    $dump_file = Path::Tiny->new("lib/$dump_file.pm");

    $dump_dir->child($dump_file)->parent->mkpath;
    return $dump_file;
}

has _package_name => (
    is      => 'lazy',
    isa     => Str,
    default => sub { ref( $_[0] ) . q{::} . $_[0]->service },
);

#pod =attr clients
#pod
#pod This role wraps around the builder for the C<clients> attribute to either read
#pod in the generated class file (if it already exists) or generate it and then
#pod add it to the symbol table.
#pod
#pod =cut

around _build_clients => sub {
    my ( $orig, $self, @params ) = @_;

    my $package = $self->_package_name;
    my $path    = $self->dump_dir->child( $self->dump_file_name );

    if ( $path->is_file and not $self->recompile ) {
        require "$path";    ## no critic (Modules::RequireBarewordIncludes)
        my $stash = Package::Stash->new($package);
        return { map { ( $_ => $stash->get_symbol("&$_") ) }
                $stash->list_all_symbols('CODE') };
    }

    my %clients = %{ $self->$orig(@params) };
    $self->_write_dump_file( "$path", $package, %clients );
    return \%clients;
};

sub _write_dump_file {
    my ( $self, $path, $package, %clients ) = @_;

    my $dumper = XML::Compile::Dumper->new(
        package => ( $package || $self->_package_name ),
        filename => "$path",
    );

    my $dump_fh = $dumper->file;
    $dump_fh->print(<<'END_PERL');
use URI::https;
use LWPx::UserAgent::Cached;
use HTTP::Config;
use Mozilla::CA;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;

BEGIN { $ENV{HTTPS_CA_FILE} = Mozilla::CA::SSL_ca_file() }
END_PERL
    $dump_fh->print( 'use ' . ref($self) . ";\n" );

    $dumper->freeze(%clients);
    $dumper->close;

    local @ARGV         = ("$path");
    local $INPLACE_EDIT = '.bak';
    while (<>) { / weaken [(] [\$] s [)] /xms or print }
    Path::Tiny->new("$path$INPLACE_EDIT")->remove;

    return;
}

1;

__END__

=pod

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

WebService::Avalara::AvaTax::Role::Dumper - Dump and restore compiled SOAP clients for AvaTax

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Moo;
    with 'WebService::Avalara::AvaTax::Role::Dumper';

=head1 DESCRIPTION

This role handles the dumping of compiled SOAP client code to storage,
and then restoring it later to save time without having to recompile.

=head1 ATTRIBUTES

=head2 use_wss

This role overrides the value of the
L<use_wss attribute from WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection/use_wss>
to false, since L<XML::Compile::WSS|XML::Compile::WSS> does not seem to
work cleanly with L<XML::Compile::Dumper|XML::Compile::Dumper>.

=head2 recompile

A boolean value you can set at construction to signal that the generated
class files for this service should be deleted and recompiled.
Defaults to false.

=head2 dump_dir

The directory in which to save and look for the generated class files.
Defaults to a temporary directory provided by
L<Path::Tiny::tempdir|Path::Tiny>.

=head2 dump_file_name

The path to the file in L</dump_dir> used to save/read the generated classes.
Defaults to F<< lib/I<package-name-converted-to-path.pm> >>.

=head2 clients

This role wraps around the builder for the C<clients> attribute to either read
in the generated class file (if it already exists) or generate it and then
add it to the symbol table.

=head1 CAVEATS

The generated class files in the L</dump_dir> directory will be read and
executed, therefore it is B<critical> that this directory is in a secure
location on the file system that cannot be written to by untrusted users
or processes!

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc WebService::Avalara::AvaTax

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/WebService-Avalara-AvaTax>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/WebService-Avalara-AvaTax>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/WebService-Avalara-AvaTax>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/WebService-Avalara-AvaTax>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/WebService-Avalara-AvaTax>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/WebService-Avalara-AvaTax>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/WebService-Avalara-AvaTax>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=WebService-Avalara-AvaTax>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=WebService::Avalara::AvaTax>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
L<https://github.com/mjgardner/WebService-Avalara-AvaTax/issues>.
You will be automatically notified of any progress on the
request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/WebService-Avalara-AvaTax>

  git clone git://github.com/mjgardner/WebService-Avalara-AvaTax.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
