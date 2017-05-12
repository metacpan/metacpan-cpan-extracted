package WWW::Freshmeat;

use 5.008;
use strict;
use warnings;

=head1 NAME

WWW::Freshmeat - automates usage of Freshmeat.net

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

use XML::Simple qw();
use WWW::Freshmeat::Project;
use Carp;


=head1 SYNOPSIS

    use WWW::Freshmeat;

    my $fm = WWW::Freshmeat->new(token=>'freshmeat_token');

    my $project = $fm->retrieve_project('project_id');

    foreach my $p ( @projects, $project ) {
        print $p->name(), "\n";
        print $p->version(), "\n";
        print $p->description(), "\n";
    }

=cut

package WWW::Freshmeat;

use base qw( LWP::UserAgent );

sub new {
  my $class=shift;
  my $self=LWP::UserAgent->new();
  bless $self,$class;
  my %data=@_;
  $self->{fm_token}=$data{token};
  return $self;
}

sub _token {
  my $self = shift;
  croak "No token" unless $self->{fm_token};
  return $self->{fm_token};
}

=head1 DESCRIPTION

C<WWW::Freshmeat> derives from C<LWP::UserAgent>, so it accepts all the methods
that C<LWP::UserAgent> does, notably C<timeout>, C<useragent>, C<env_proxy>...

=head2 Methods

=over 4

=item B<retrieve_project> I<STRING>

Query the freshmeat.net site for the project I<STRING> (should be the Freshmeat
ID of the requested project) and returns a C<WWW::Freshmeat::Project> object or
undef if the project entry cannot be found.

=cut

sub retrieve_project {
    my $self = shift;
    my $id   = shift;

    my $url = "http://freshmeat.net/projects/$id.xml?auth_code=".$self->_token;

    my $response = $self->get($url);
    if ($response->is_success) {
      my $xml = $response->content();
      return $self->project_from_xml($xml);
    } else {
      if ($response->code eq '404') {
        return undef;
      } else {
        die "Could not GET freshmeat project (".$response->status_line.")";
      }
    }
}

=item B<project_from_xml> I<STRING>

Receives Freshmeat project XML record and returns a C<WWW::Freshmeat::Project>
object or undef if the project entry cannot be found.

=cut

sub project_from_xml {
    my $self = shift;
    my $xml  = shift;

    if ($xml eq 'Error: project not found.') {
      return undef;
    }
    die "XML is empty" unless $xml;

    my $data = XML::Simple::XMLin($xml,ForceArray => ['approved-url','recent-release']);
    #die unless exists $data->{'project'};
    die unless $data->{'name'};

    return WWW::Freshmeat::Project->new($data, $self); #->{'project'}
}

sub retrieve_user {
    croak "'User' is temporarily removed";
    my $self = shift;
    my $id   = shift;
    require WWW::Freshmeat::User;
    return WWW::Freshmeat::User->new($self,$id);
}

=item B<redir_url> I<STRING>

Receives URL and returns URL which it redirects to.

=cut

sub redir_url {
    my $self = shift;
    my $url=shift;
    $self->requests_redirectable([]);
    my $response = $self->get($url) or return $url;
    if ($response->is_redirect) {
      #http://www.perlmonks.org/?node_id=147608
      my $referral_uri = $response->header('Location');
      {
          # Some servers erroneously return a relative URL for redirects,
          # so make it absolute if it not already is.
          local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
          my $base = $response->base;
          $referral_uri = $HTTP::URI_CLASS->new($referral_uri, $base)
                      ->abs($base)->as_string;
      }
      return $referral_uri;
    } else {
      return $url;
    }
}

=back

=head1 SEE ALSO

L<LWP::UserAgent>.

=head1 AUTHOR

Cedric Bouvier, C<< <cbouvi at cpan.org> >>. Alexandr Ciornii.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-freshmeat at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Freshmeat>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Freshmeat

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Freshmeat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Freshmeat>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Freshmeat>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Freshmeat>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Cedric Bouvier (version 0.01).
Copyright 2009-2012 Alexandr Ciornii.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Freshmeat
