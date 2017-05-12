package WWW::OpenSVN;

use strict;
use warnings;

use LWP::UserAgent;
use LWP::Simple;
use HTTP::Cookies;

=head1 NAME

WWW::OpenSVN - An automated interface for OpenSVN.csie.org.

=cut

use vars qw($VERSION);

$VERSION = '0.1.5';

=head1 SYNOPSIS

    my $opensvn =
        WWW::OpenSVN->new(
            'project' => "myproject",
            'password' => "MySecretPassphrase",
        );

    $opensvn->fetch_dump('filename' => "/backup-dir/myproject-dump.gz");

=head1 FUNCTIONS

=cut

package WWW::OpenSVN::Base;

=head2 WWW::OpenSVN->new()

A constructor. Accepts these mandatory named arguments:

'project' - The OpenSVN Project ID.

'password' - The OpenSVN Project Management Password.

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init(@_);
    return $self;
}

sub project
{
    my $self = shift;
    return $self->{'project'};
}

package WWW::OpenSVN::Error;

use vars qw(@ISA);

@ISA=(qw(WWW::OpenSVN::Base));

sub _init
{
    my $self = shift;
    my (%args) = (@_);
    $self->{'project'} = $args{'project'};
    $self->{'phase'} = $args{'phase'};

    return 0;
}

sub phase
{
    my $self = shift;
    return $self->{'phase'};
}

package WWW::OpenSVN;

use vars qw(@ISA);

@ISA=(qw(WWW::OpenSVN::Base));

sub _init
{
    my $self = shift;
    my (%args) = (@_);
    $self->{'project'} = $args{'project'}
        or die "Project ID not specified!";
    $self->{'_password'} = $args{'password'}
        or die "Project Password not speicified!";
    return 0;
}


sub _password
{
    my $self = shift;
    return $self->{'_password'};
}

sub _gen_error
{
    my $self = shift;

    my (%args) = (@_);

    die
        WWW::OpenSVN::Error->new(
            'project' => $self->project(),
            'phase' => $args{'phase'}
        );
}

sub _get_repos_revision
{
    my $self = shift;
    if (exists($self->{'repos_revision'}))
    {
        return $self->{'repos_revision'};
    }
    my $project = $self->project();
    my $url = "http://opensvn.csie.org/$project/";
    my $page = get($url);
    if ($page =~ /Revision (\d+): \/<\/title>/)
    {
        return ($self->{'repos_revision'} = $1);
    }
    else
    {
        $self->_gen_error(
            'phase' => 'get_repos_rev',
        );
    }
}

=head2 $opensvn->fetch_dump('filename' => "myfile.dump.gz")

Fetches a subversion repository dump and stores it in a file. Accepts an
optional argument - 'filename' that is used to specify the filename to store
the dump into. If not specified, it defaults to "$project.dump.gz"

=cut

sub fetch_dump
{
    my $self = shift;
    my (%args) = (@_);

    my $url = "https://opensvn.csie.org/";

    my $repos_top_version = $self->_get_repos_revision();
    my %login_params =
    (
        'project' => $self->project(),
        'password' => $self->_password(),
        'action' => "login",
    );

    my $ua = LWP::UserAgent->new();
    $ua->cookie_jar({});
    my $response = $ua->post($url, \%login_params);

    if (!$response->is_success())
    {
        $self->_gen_error(
            'phase' => "login",
        );
    }

    # We only need the previous response for the cookie.

    my %backup_params =
    (
        'action' => "backup1",
        'r1' => 0,
        'r2' => $repos_top_version,
        'i' => 1,
        'd' => 1,
    );

    $response = $ua->post($url, \%backup_params);

    if (! $response->is_success())
    {
        $self->_gen_error(
            'phase' => "dump_request",
        );
    }

    my $server_return = $response->content();

    my $fetch_file_path;
    if ($server_return =~ m{<meta http-equiv="refresh" content="0;url=/([^"]+)"})
    {
        $fetch_file_path = $1;
    }
    else
    {
        $self->_gen_error(
            'phase' => "dump_wrong_redirect",
        );
    }

    $response =
        $ua->get(
            "$url$fetch_file_path",
            ":content_file" =>
                ($args{'filename'} || ($self->project() . ".dump.gz")),
        );

    if (! $response->is_success())
    {
        $self->_gen_error(
            'phase' => "dump_fetch"
        );
    }

    return 0;
}

1;

__END__
=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-opensvn@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-OpenSVN>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT X11 License.

=cut

