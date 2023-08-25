package WWW::Suffit::Server::Suffit;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Server::Suffit - The Mojolicious controller of the suffit projects

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use WWW::Suffit::Server::Suffit;

=head1 DESCRIPTION

The Mojolicious controller of the suffit projects

=head1 METHODS

API methods

=head2 serverinfo

The route to show server information

=head1 SEE ALSO

L<WWW::Suffit::Server::ServerInfo>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Controller';

our $VERSION = "1.00";

use Mojo::File qw/ path /;

sub serverinfo {
    my $self = shift;
    my @o = ();

    # Filtered stash snapshot
    my $stash = $self->stash;
    my $snapshot;
    %{$snapshot = {}} = map { $_ => $_ eq 'app' ? 'DUMMY' : $stash->{$_} } grep { !/^mojo\./ and defined $stash->{$_} } keys %$stash;

    my $url = $self->req->url;
    my $params = $self->req->params->to_hash || {};
    my $s = sub {
        my $sec = shift; # sec   - gen, ext, dat
        my $typ = shift; # typ   - str, txt, obj, dmp
        my $key = shift; # key   - Key
        my $val = shift; # val   - Value
        push @o, {
            sec => $sec,
            typ => $typ,
            key => $key,
            val => $val,
        };
    };

    # General
    push @o, "-"x80 . " gen " . "---";
    $s->("gen", "str", 'Request ID' => $self->req->request_id);
    $s->("gen", "str", 'Method'     => $self->req->method);
    $s->("gen", "str", 'Base URL'   => $url->base->to_string);
    $s->("gen", "str", 'URL'        => $url->to_string);
    $s->("gen", "str", 'Router name'=> $self->match->endpoint->name);
    $s->("gen", "str", 'HTTP Version' => $self->req->version);
    $s->("gen", "str", 'Remote IP'  => $self->can('remote_ip') ? $self->remote_ip : $self->tx->remote_address);
    { # Headers
        my @obj;
        foreach my $n (sort @{$self->req->headers->names}) {
            push @obj, [$n, $self->req->headers->header($n)];
        }
        $s->("gen", "obj", 'Request headers', [@obj]);
    }
    { # Parameters
        my @obj;
        foreach my $n (sort keys %$params) {
            push @obj, [$n,  $params->{$n} // ''];
        }
        $s->("gen", "obj", 'Request parameters', [@obj]);
    }
    $s->("gen", "dmp", 'Stash'      => $snapshot);
    $s->("gen", "dmp", 'Session'    => $self->session);

    # Extends
    push @o, "-"x80 . " ext " . "---";
    $s->("ext", "str", 'Perl'           => "$^V ($^O)");
    $s->("ext", "str", 'Mojolicious'    => sprintf("%s (%s)", $Mojolicious::VERSION, $Mojolicious::CODENAME));
    $s->("ext", "str", 'Moniker'        => $self->app->moniker);
    $s->("ext", "str", 'Name'           => $0);
    $s->("ext", "str", 'Executable'     => $^X);
    $s->("ext", "str", 'PID'            => $$);
    $s->("ext", "str", 'Time'           => scalar localtime(time));
    $s->("ext", "str", 'Home'           => $self->app->home->to_string);
    $s->("ext", "str", 'Document root'  => $self->app->documentroot) if $self->app->can('documentroot');
    $s->("ext", "str", 'Data dir'       => $self->app->datadir) if $self->app->can('datadir');
    $s->("ext", "dmp", 'Template paths' => $self->app->renderer->paths);
    $s->("ext", "dmp", 'Template classes'=>$self->app->renderer->classes);
    $s->("ext", "dmp", 'Static paths'   => $self->app->static->paths);
    $s->("ext", "dmp", 'Namespaces'     => $self->app->routes->namespaces);
    $s->("ext", "dmp", 'Include'        => \@INC);
    $s->("ext", "dmp", 'Config'         => $self->app->config);

    { # Environment variables
        my @obj;
        foreach my $k (sort keys %ENV) {
            push @obj, [$k, $ENV{$k} // ''];
        }
        $s->("gen", "obj", 'Environment variables', [@obj]);
    }

    { # %INC
        my @obj;
        foreach my $k (sort keys %INC) {
            my $module = $k;
            if ($k =~ /.pm$/) {
                $module =~ s{\/}{::}gsmx;
                $module =~ s/.pm$//g;
            } else {
                $module = path($k)->basename;
            }
            push @obj, [$module, $INC{$k} // ''];
        }
        $s->("gen", "obj", 'Loaded modules', [@obj]);
    }

    # Data
    my $raw_data = $self->req->body // '';
    if (length($raw_data)) {
        push @o, "-"x80 . " dat " . "---";
        $s->("ext", "txt", 'Request data' => $raw_data);
    }

    # Text output
    my @text = ();
    foreach my $r (@o) {
        unless (ref($r) eq 'HASH') {
            push @text, $r, "\n";
            next;
        }
        my $typ = $r->{typ}; # typ   - str, txt, obj
        my $key = $r->{key}; # key   - Key
        my $val = $r->{val}; # val   - Value
        if ($typ eq 'str') {
            push @text, sprintf("%-*s: %s\n", 24, $key, $val);
        } elsif ($typ eq 'txt') {
            push @text, sprintf("%s:\n%s", $key, $val);
        } elsif ($typ eq 'dmp') {
            push @text, sprintf("%s: %s", $key, $self->dumper($val));
        } elsif ($typ eq 'obj' and ref($val) eq 'ARRAY') {
            push @text, sprintf("%s:\n", $key);
            foreach my $p (@$val) {
                push @text, sprintf("  %-*s: %s\n", 22, @$p);
            }
        }
    }

    # Json
    my %json = ();
    foreach my $r (@o) {
        next unless ref($r) eq 'HASH';
        my $key = $r->{key}; # key   - Key
        my $val = $r->{val}; # val   - Value
        $json{$key} = $val;
    }

    # HTML
    my (@html, @headers, @parameters, @environments, @modules) = ();
    foreach my $r (@o) {
        next unless ref($r) eq 'HASH';
        if ($r->{typ} eq 'obj') {
            if ($r->{key} eq 'Request headers') {
                @headers = @{$r->{val}};
            } elsif ($r->{key} eq 'Request parameters') {
                @parameters = @{$r->{val}};
            } elsif ($r->{key} eq 'Environment variables') {
                @environments = @{$r->{val}};
            } elsif ($r->{key} eq 'Loaded modules') {
                @modules = @{$r->{val}};
            }
        } else {
            next if $r->{key} eq 'Include';
            push @html, $r;
        }
    }

    # Render
    return $self->respond_to(
        json    => {
            json    => \%json,
        },
        text    => {
            text    => join("", @text),
        },
        html    => {
            template        => $self->app->{'__suffit_serverinfo_template'},
            general         => \@html,
            headers         => \@headers,
            parameters      => \@parameters,
            environments    => \@environments,
            atinc           => \@INC,
            modules         => \@modules,
        },
        any     => {
            text    => join("", @text),
        },
    );
    #return $self->render(template => $self->app->{'__suffit_serverinfo_template'});
}

1;

__END__
