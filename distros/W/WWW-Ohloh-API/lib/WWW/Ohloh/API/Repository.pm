package WWW::Ohloh::API::Repository;

use strict;
use warnings;

use Carp;
use XML::LibXML;
use URI;

use Object::InsideOut qw/
  WWW::Ohloh::API::Role::Fetchable
  WWW::Ohloh::API::Role::LoadXML
  /;

our $VERSION = '0.3.2';

my @api_fields = qw/
  id
  type
  url
  module_name
  username
  password
  logged_at
  commits
  ohloh_job_status
  /;

#<<<
my @id_of               : Field 
                        : Set(_set_id) 
                        : Get(id)
                        ;
my @type_of             : Field 
                        : Set(_set_type) 
                        : Get(type);
my @url_of              : Field 
                        : Type(URI) 
                        : Get(url)
                        ;
my @module_name_of      : Field 
                        : Set(_set_module_name) 
                        : Get(module_name);
my @username_of         : Field 
                        : Set(_set_username) 
                        : Get(username);
my @password_of         : Field 
                        : Set(_set_password) 
                        : Get(password)
                        ;
my @logged_at_of        : Field 
                        : Set(_set_logged_at) 
                        : Get(logged_at)
                        ;
my @commits_of          : Field 
                        : Set(_set_commits) 
                        : Get(commits)
                        ;
my @ohloh_job_status_of : Field 
                        : Set(_set_ohloh_job_status) 
                        : Get(ohloh_job_status);
#>>>
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub load_xml {
    my ( $self, $dom ) = @_;

    for my $f (@api_fields) {
        my $m = "_set_$f";

        $self->$m( $dom->findvalue("$f/text()") );
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _set_url {
    my ( $self, $url ) = @_;
    $url_of[$$self] = URI->new($url);
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('repository');

    $w->dataElement( $_ => $self->$_ ) for @api_fields;

    $w->endTag;

    return $xml;
}

'end of WWW::Ohloh::API::Repository';

__END__

=head1 NAME

WWW::Ohloh::API::Repository - A code repository 

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my @enlistments = $ohloh->get_enlistments( 
        project_id => 12933,
    );
    my @repository = map { $_->repository } @enlistments;
    
=head1 DESCRIPTION

W::O::A::Repository contains the information associated with 
a code repository
as defined at http://www.ohloh.net/api/reference/repository. 

=head1 METHODS 

=head2 API Data Accessors

=head3 id

    my $id = $repository->id;

Return the id of the repository.

=head3 type

    my $is_git = $repository->type eq 'GitRepository';

Return the type of the repository, which can be
either C<SvnRepository>, C<CvsRepository> or
C<GitRepository>.

=head3 url

Return the repository's public url as a L<URI> object. If you 
just want the url, don't be scared by that: URI objects are
stringified into what you expect. E.g.:

    my $url = $repository->url;
    print $url;  # will print a good ol' "http://..." string

=head3 module_name

    my $module = $repository->module_name;

For CVS repositories, return the name of the module.

=head3 username,  password

    my $user     = $repository->username;
    my $password = $repository->password;

Return, if necessary, the username / password required to log to the repository.

=head3 logged_at

    my $last = $repository->logged_at;

Return the last time the Ohloh server successfully queried the repository.

=head3 commits

    my $nbr = $repository->commits;

Return the total number of commits downloaded by the Ohloh server.

=head3 ohloh_job_status
    
    my $ok = $repository->ohloh_job_status eq 'success';

Return the result of the last attempt of the Ohloh server to read the
repository, which can be either C<success> or C<failed>.

=head2 Other Methods

=head3 as_xml

Return the account information 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server.

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, L<WWW::Ohloh::API::KudoScore>,
L<WWW::Ohloh::API::ContributorFact>.

=item *

L<URI>.

=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference:
http://www.ohloh.net/api/reference/contributor_language_fact

=back

=head1 VERSION

This document describes WWW::Ohloh::API::ContributorLanguageFact 
version 0.0.6

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

The C<as_xml()> method returns a re-encoding of the account data, which
can differ of the original xml document sent by the Ohloh server.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.



