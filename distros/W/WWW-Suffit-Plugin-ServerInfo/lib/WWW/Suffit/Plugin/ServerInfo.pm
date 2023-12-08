package WWW::Suffit::Plugin::ServerInfo;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::Plugin::ServerInfo - The WWW::Suffit Plugin for show Server and Perl environment data

=head1 SYNOPSIS

    # in your startup
    $self->plugin('WWW::Suffit::Plugin::ServerInfo', {
        route => "/serverinfo",
    });

    ...or:

    # in your startup
    $self->plugin('WWW::Suffit::Plugin::ServerInfo');
    $self->routes->get('/serverinfo1')->to('ServerInfo#info');
    $self->routes->get('/serverinfo2' => sub { shift->serverinfo });

    # Curl Examples:
    curl -H "Accept: text/html" http://localhost:8080/serverinfo
    curl -H "Accept: text/plain" http://localhost:8080/serverinfo
    curl -H "Accept: application/json" http://localhost:8080/serverinfo

=head1 DESCRIPTION

The WWW::Suffit Plugin for show Server and Perl environment data

=head1 OPTIONS

This plugin supports the following options

=head2 debug

    debug => 1,

Switches on the debug mode. This mode performs show log history and dump of config

=head2 route

    route => "/serverinfo",

Sets route name and show server info by it

=head2 template

  template => "suffit_serverinfo",

Sets template for rendering. Default: suffit_serverinfo

=head1 METHODS

Internal methods

=head2 register

Do not use directly. It is called by Mojolicious.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.01';

use Mojo::File qw/ path /;

sub register {
    my ($plugin, $app, $opts) = @_; # $self = $plugin
    $opts //= {};

    # Add classes
    push @{$app->renderer->classes}, __PACKAGE__;
    push @{$app->static->classes},   __PACKAGE__;
    my $ns = 0;
    for (@{$app->routes->namespaces}) { $ns = 1 if $_ eq 'WWW::Suffit::Server' }
    push @{$app->routes->namespaces}, 'WWW::Suffit::Server' unless $ns;

    # Helpers
    $app->helper('serverinfo',    => \&_serverinfo);

    # Set template
    my $template = $opts->{template} || 'suffit_serverinfo';
       $app->{'__suffit_serverinfo_template'} = $template;

    # Set debug mode
    $app->{'__suffit_serverinfo_debug'} = $opts->{debug} ? 1 : 0;

    # Set ANY route to root:
    if (my $route_name = $opts->{routename} || $opts->{route}) { # '/serverinfo'
        #$app->routes->any($route_name => {template => $template} => sub { shift->render } );
        #$app->routes->any($route_name)->to('ServerInfo#info');
        $app->routes->any($route_name => sub { shift->serverinfo });
    }
}
sub _serverinfo {
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
    $s->("ext", "dmp", 'Config'         => $self->app->config) if $self->app->{'__suffit_serverinfo_debug'};

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

__DATA__

@@ suffit_serverinfo.css

html, body {
    height: 100%;
}
body {
    margin: 0;
    padding: 2rem;
    background-color: #001229;
    color: #EEEEEE;
    font-family: "Helvetica Neue", Helvetica, Tahoma, Verdana, Arial, sans-serif;
    font-size: 1.2rem;
}
hr {
    height: 1px;
    background-color: #555555;
    border: none;
    color: #555555;
    margin: 1rem 0;
}
header {
    max-width: 1024px;
    margin: 0 auto;

    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
}
header div.item {
    text-align: center;
}
main {
    max-width: 1024px;
    margin: 0 auto;
    padding-bottom: 3rem;
}
pre {
    text-wrap: wrap;
}

a:link {
    text-decoration: none;
    color: #00BFFF;
}
a:visited {
    text-decoration: none;
    color: #00BFFF;
}
a:active {
    text-decoration: underline;
    color: #005FFF;
}
a:hover {
    text-decoration: underline;
    color: #EEEEEE;
}

table.striped {
    /*.spy1xxx*/
    background-color: #002424;
    border: 1px solid #49373A;
    overflow: hidden;
    border-collapse: separate;
    border-spacing: 1px;
    width: 100%;
}
table.striped th,
table.striped td {
    line-height: 1.2rem;
    padding: .2rem;
    text-align: left;
    vertical-align: top;
    color: #EEEEEE;
}
table.striped > tbody > tr:nth-child(odd) {
    /*.spy1x*/
    background-color: #19373A;
}
table.striped > tbody > tr:nth-child(even) {
    /*.spy1xx*/
    background-color: #003333;
}

.break {
    /*overflow-wrap: break-word;*/
    overflow: hidden;
    word-break: break-all;
}
.nobreak {
    word-break: keep-all;
    overflow-wrap: normal;
    white-space: nowrap;
}

.mark {
    color: cyan;
}
.error {
    color: magenta;
}
.alert {
    color: magenta;
}
.warn {
    color: pink;
}

pre.terminal {
    display: block;
    background-color: #282c34;
    border: 1px solid #49373A;
    font-family: Consolas, Liberation Mono, Menlo, monospace;
    font-size: 1rem;
    padding: 1ex 1ex;

}
pre.terminal > code {
    display: block;
    color: #EEEEEE;
    font-family: Consolas, Liberation Mono, Menlo, monospace;
    font-size: 1rem;
    text-align: left;
    white-space: pre-wrap;
}

@@ suffit_serverinfo.html.ep
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Server Info</title>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <meta name="author" content="Serż Minus" />
    <meta name="description" content="Server Info" />
    <meta name="copyright" content="Copyright &copy; 1998-2023 D&amp;D Corporation. All Rights Reserved" />
    <meta name="theme-color" content="#001229" />
    <link media="screen, print, projection" type="text/css" rel="stylesheet" href="/suffit_serverinfo.css" />
</head>
<body>
<header>
<div class="item">
    <h1>Server Info</h1>
</div>
<div class="item">
    <img src="/suffit_serverinfo.svg" width="64" height="54" alt="[LOGO]" />
</div>
</header>
<main>
<table class="striped">
    <tbody>
    % for my $line (@{$general}) {
        <tr>
            <th class="nobreak"><%= $line->{key} %></th>
            <td class="break">
                % if ($line->{typ} eq 'dmp' ) {
                    <pre><%= dumper $line->{val} %></pre>
                % } elsif ($line->{typ} eq 'obj' ) {
                    <table>
                        <tbody>
                        % my $st = $line->{val};
                        % for my $kv (@{$st}) {
                            <tr>
                                <th><%= $kv->[0] %></th>
                                <td class="break"><%= $kv->[1] %></td>
                            </tr>
                        % }
                        </tbody>
                    </table>
                % } else {
                    <%= $line->{val} %>
                % }
            </td>
        </tr>
    % }
    </tbody>
</table>

<h2>Request Headers</h2>
<table class="striped">
    <thead>
        <tr>
            <th>Header name</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
    % for my $kv (@$headers) {
        <tr>
            <th class="nobreak"><%= $kv->[0] %></th>
            <td class="break"><%= $kv->[1] %></td>
        </tr>
    % }
    </tbody>
</table>

% if (scalar(@$parameters)) {
<h2>Request Parameters</h2>
<table class="striped">
    <thead>
        <tr>
            <th>Param</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
    % for my $kv (@{$parameters}) {
        <tr>
            <th class="nobreak"><%= $kv->[0] %></th>
            <td class="break"><%= $kv->[1] %></td>
        </tr>
    % }
    </tbody>
</table>
% }

<h2>Environment Variables (%ENV)</h2>
<table class="striped">
    <thead>
        <tr>
            <th>Key</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
    % for my $kv (@{$environments}) {
        <tr>
            <th class="nobreak"><%= $kv->[0] %></th>
            <td class="break"><%= $kv->[1] %></td>
        </tr>
    % }
    </tbody>
</table>

<h2>Libraries Paths (@INC)</h2>
<table class="striped">
    <thead>
        <tr>
            <th>Path</th>
        </tr>
    </thead>
    <tbody>
    % for my $path (@{$atinc}) {
        <tr>
            <td class="break"><%= $path // '' %></td>
        </tr>
    % }
    </tbody>
</table>

<h2>Loaded Modules (%INC)</h2>
<table class="striped">
    <thead>
        <tr>
            <th>Module/File</th>
            <th>Path</th>
        </tr>
    </thead>
    <tbody>
    % for my $kv (@{$modules}) {
        <tr>
            <td class="break"><%= $kv->[0] %></td>
            <td class="break"><%= $kv->[1] %></td>
        </tr>
    % }
    </tbody>
</table>
<p style="text-align: right">Number of loaded modules: <em class="mark"><%= scalar keys %INC %></em></p>

% if (app->{'__suffit_serverinfo_debug'}) {
<h2>Log (<%= app->log->level %>)</h2>
<div>
    % if (@{app->log->history}) {
        % my $log = join '', map { scalar app->log->format->(@$_) } @{app->log->history};
        <pre class="terminal"><code><%= $log %></code></pre>
    % } else {
        <p class="warn">The application log is empty</p>
    % }
</div>
% }

<h2>License</h2>
<p>
    This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See <em class="mark">LICENSE</em> file and <a href="https://dev.perl.org/licenses/">https://dev.perl.org/licenses/</a>
</p>

</main>
</body>
</html>


@@ suffit_serverinfo.svg
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="600px" height="499px" style="shape-rendering:geometricPrecision; text-rendering:geometricPrecision; image-rendering:optimizeQuality; fill-rule:evenodd; clip-rule:evenodd" xmlns:xlink="http://www.w3.org/1999/xlink">
<g><path style="opacity:0.964" fill="#040404" d="M 275.5,-0.5 C 292.833,-0.5 310.167,-0.5 327.5,-0.5C 350.456,1.39506 372.789,6.56173 394.5,15C 413.207,23.0469 429.04,34.8803 442,50.5C 453.782,41.0737 467.282,36.7403 482.5,37.5C 512.299,39.5328 540.632,47.0328 567.5,60C 584.963,69.6119 595.629,84.1119 599.5,103.5C 599.5,111.833 599.5,120.167 599.5,128.5C 593.575,166.852 576.242,199.019 547.5,225C 538.166,232.251 527.999,238.085 517,242.5C 518.219,283.959 508.886,322.959 489,359.5C 484.558,366.94 479.725,374.106 474.5,381C 479.562,389.513 483.062,398.68 485,408.5C 488.501,425.814 488.834,443.148 486,460.5C 480.142,478.355 467.975,489.188 449.5,493C 420.879,498.144 392.212,498.477 363.5,494C 349.082,492.044 337.249,485.544 328,474.5C 314.284,482.841 299.451,486.008 283.5,484C 268.831,492.392 253.165,497.225 236.5,498.5C 220.167,498.5 203.833,498.5 187.5,498.5C 174.746,497.475 162.413,494.308 150.5,489C 134.391,478.451 126.724,463.451 127.5,444C 127.456,427.805 129.79,411.972 134.5,396.5C 118.026,375.904 104.86,353.238 95,328.5C 85.6219,302.236 81.4552,275.236 82.5,247.5C 70.7743,243.609 60.1076,237.775 50.5,230C 22.3232,204.147 5.32321,172.314 -0.5,134.5C -0.5,125.833 -0.5,117.167 -0.5,108.5C 3.43724,90.3801 13.4372,76.5467 29.5,67C 60.5877,50.9776 93.5877,43.3109 128.5,44C 139.002,45.5058 148.502,49.3391 157,55.5C 177.386,29.5383 203.886,13.0383 236.5,6C 249.536,3.16072 262.536,0.994051 275.5,-0.5 Z"/></g>
<g><path style="opacity:1" fill="#929cab" d="M 464.5,148.5 C 464.856,156.238 464.356,163.905 463,171.5C 454.98,196.883 442.314,219.55 425,239.5C 420.574,244.434 415.74,248.767 410.5,252.5C 394.461,240.735 379.628,242.401 366,257.5C 360.547,265.819 360.047,274.486 364.5,283.5C 362.174,285.33 359.507,286.663 356.5,287.5C 355.614,286.675 355.281,285.675 355.5,284.5C 358.091,268.467 362.091,252.801 367.5,237.5C 366.658,233.077 364.492,232.41 361,235.5C 347.224,272.725 341.057,311.225 342.5,351C 342.432,369.866 343.098,388.7 344.5,407.5C 341.505,433.007 327.505,449.174 302.5,456C 277.64,459.999 257.973,451.833 243.5,431.5C 241.387,413.4 246.887,398.067 260,385.5C 259.428,398.169 258.762,410.835 258,423.5C 260.632,426.192 262.966,425.859 265,422.5C 271.047,376.102 270.714,329.769 264,283.5C 261.297,267.39 256.964,251.723 251,236.5C 247.75,232.316 245.25,232.649 243.5,237.5C 250.582,256.241 255.248,275.574 257.5,295.5C 257.5,296.5 257.5,297.5 257.5,298.5C 251.697,298.039 246.03,296.873 240.5,295C 238.881,294.764 237.881,293.931 237.5,292.5C 243.928,283.121 246.428,272.788 245,261.5C 235.941,245.255 222.441,239.755 204.5,245C 194.477,250.868 189.477,259.701 189.5,271.5C 177.939,265.109 167.439,257.109 158,247.5C 164.831,262.862 174.664,276.195 187.5,287.5C 187.611,289.648 186.944,289.981 185.5,288.5C 145.998,247.073 130.165,197.74 138,140.5C 146.122,57.3804 191.955,13.2137 275.5,8C 302.335,6.38176 329.001,7.7151 355.5,12C 381.487,16.4973 404.487,27.164 424.5,44C 446.752,67.7093 459.586,95.8759 463,128.5C 464.052,135.128 464.552,141.794 464.5,148.5 Z"/></g>
<g><path style="opacity:1" fill="#656c76" d="M 590.5,101.5 C 589.352,100.105 588.352,100.272 587.5,102C 576.669,102.236 566.002,100.903 555.5,98C 531.539,95.6061 509.205,100.606 488.5,113C 482.344,116.997 476.344,121.164 470.5,125.5C 467.588,101.267 459.588,78.7673 446.5,58C 456.375,49.2056 468.041,45.039 481.5,45.5C 512.723,47.6316 542.056,56.1316 569.5,71C 580.253,78.5859 587.253,88.7526 590.5,101.5 Z"/></g>
<g><path style="opacity:1" fill="#929cab" d="M 143.5,83.5 C 123.998,87.1673 105.331,93.334 87.5,102C 76.0265,107.784 67.8598,116.617 63,128.5C 61.9103,134.078 64.2436,136.411 70,135.5C 78.8251,134.002 87.6585,132.502 96.5,131C 107.899,130.2 119.233,130.7 130.5,132.5C 130.5,133.5 130.5,134.5 130.5,135.5C 129.482,153.822 129.315,172.155 130,190.5C 132.571,205.773 135.904,220.773 140,235.5C 118.296,247.324 96.4626,247.491 74.5,236C 49.6197,221.453 31.4531,200.953 20,174.5C 12.033,157.195 7.86638,139.028 7.5,120C 7.50676,100.315 15.8401,85.3155 32.5,75C 63.7859,58.1774 97.1192,50.8441 132.5,53C 140.434,54.628 147.1,58.2947 152.5,64C 149.349,70.4663 146.349,76.9663 143.5,83.5 Z"/></g>
<g><path style="opacity:1" fill="#656c76" d="M 143.5,83.5 C 137.026,100.387 132.692,117.72 130.5,135.5C 130.5,134.5 130.5,133.5 130.5,132.5C 119.233,130.7 107.899,130.2 96.5,131C 87.6585,132.502 78.8251,134.002 70,135.5C 64.2436,136.411 61.9103,134.078 63,128.5C 67.8598,116.617 76.0265,107.784 87.5,102C 105.331,93.334 123.998,87.1673 143.5,83.5 Z"/></g>
<g><path style="opacity:1" fill="#080809" d="M 242.5,88.5 C 271.965,85.3052 291.465,97.6386 301,125.5C 303.924,154.836 291.424,174.002 263.5,183C 234.234,186.048 215.401,173.548 207,145.5C 204.138,117.205 215.971,98.2048 242.5,88.5 Z"/></g>
<g><path style="opacity:1" fill="#080809" d="M 350.5,87.5 C 381.648,87.8868 399.648,103.387 404.5,134C 400.753,168.745 381.42,185.078 346.5,183C 317.68,173.547 305.513,153.714 310,123.5C 316.511,103.482 330.011,91.4821 350.5,87.5 Z"/></g>
<g><path style="opacity:1" fill="#fcfcfc" d="M 246.5,95.5 C 270.053,94.0111 285.553,104.344 293,126.5C 296.113,151.122 285.946,167.289 262.5,175C 233.571,177.528 217.238,164.362 213.5,135.5C 215.832,114.848 226.832,101.515 246.5,95.5 Z"/></g>
<g><path style="opacity:1" fill="#fcfcfc" d="M 352.5,95.5 C 374.812,95.6561 389.312,106.323 396,127.5C 398.298,151.416 388.131,167.25 365.5,175C 340.889,178.118 324.723,167.951 317,144.5C 314.7,117.724 326.533,101.39 352.5,95.5 Z"/></g>
<g><path style="opacity:1" fill="#929cab" d="M 590.5,101.5 C 592.585,148.427 576.252,187.594 541.5,219C 524.006,233.164 504.006,239.498 481.5,238C 478.053,237.471 474.719,236.638 471.5,235.5C 477.29,214.224 479.456,192.557 478,170.5C 477.103,161.508 475.27,152.841 472.5,144.5C 471.423,138.218 470.757,131.884 470.5,125.5C 476.344,121.164 482.344,116.997 488.5,113C 509.205,100.606 531.539,95.6061 555.5,98C 566.002,100.903 576.669,102.236 587.5,102C 588.352,100.272 589.352,100.105 590.5,101.5 Z"/></g>
<g><path style="opacity:1" fill="#040404" d="M 257.5,138.5 C 271.841,138.666 277.341,145.666 274,159.5C 269.841,166.67 263.674,169.17 255.5,167C 245.336,160.008 244.002,151.674 251.5,142C 253.432,140.541 255.432,139.375 257.5,138.5 Z"/></g>
<g><path style="opacity:1" fill="#060606" d="M 340.5,138.5 C 353.18,138.015 359.347,144.015 359,156.5C 354.277,167.602 346.444,170.436 335.5,165C 330.798,160.078 329.298,154.245 331,147.5C 333.406,143.592 336.572,140.592 340.5,138.5 Z"/></g>
<g><path style="opacity:1" fill="#646a74" d="M 472.5,144.5 C 475.27,152.841 477.103,161.508 478,170.5C 479.456,192.557 477.29,214.224 471.5,235.5C 468.04,234.605 465.04,232.938 462.5,230.5C 471.995,202.568 475.328,173.901 472.5,144.5 Z"/></g>
<g><path style="opacity:1" fill="#636a74" d="M 464.5,148.5 C 469.759,196.132 457.592,238.798 428,276.5C 425.333,279.167 422.667,281.833 420,284.5C 419.148,275.238 417.148,266.238 414,257.5C 413.003,255.677 411.836,254.01 410.5,252.5C 415.74,248.767 420.574,244.434 425,239.5C 442.314,219.55 454.98,196.883 463,171.5C 464.356,163.905 464.856,156.238 464.5,148.5 Z"/></g>
<g><path style="opacity:1" fill="#070808" d="M 296.5,198.5 C 312.264,197.699 326.098,202.366 338,212.5C 339.072,215.553 338.072,217.553 335,218.5C 327.483,213.325 319.316,209.491 310.5,207C 297.606,205.076 286.606,208.743 277.5,218C 274.138,219.293 272.138,218.293 271.5,215C 271.439,213.289 272.106,211.956 273.5,211C 280.376,205.231 288.042,201.065 296.5,198.5 Z"/></g>
<g><path style="opacity:1" fill="#444950" d="M 470.5,243.5 C 469.624,243.369 468.957,243.702 468.5,244.5C 465.715,252.071 462.381,259.405 458.5,266.5C 454.169,267.634 449.836,267.634 445.5,266.5C 450.269,257.799 454.935,248.966 459.5,240C 463.262,240.865 466.929,242.032 470.5,243.5 Z"/></g>
<g><path style="opacity:1" fill="#929cab" d="M 166.5,279.5 C 172.287,290.95 179.62,301.283 188.5,310.5C 189.43,316.314 190.93,321.981 193,327.5C 196.65,330.73 200.816,331.397 205.5,329.5C 206.552,329.351 207.552,329.517 208.5,330C 224.147,343.121 241.813,352.621 261.5,358.5C 261.666,364.176 261.499,369.843 261,375.5C 259.887,376.305 258.721,376.972 257.5,377.5C 254.688,375.592 251.688,373.925 248.5,372.5C 248.213,373.2 247.88,373.867 247.5,374.5C 225.869,363.175 202.869,357.675 178.5,358C 165.421,360.538 154.421,366.704 145.5,376.5C 139.273,373.111 133.439,369.111 128,364.5C 127.333,365.167 127.333,365.833 128,366.5C 132.802,372.122 136.969,378.122 140.5,384.5C 139.911,387.785 138.744,388.118 137,385.5C 105.698,346.1 90.1985,301.1 90.5,250.5C 109.095,254.048 126.762,251.381 143.5,242.5C 150.399,255.296 158.066,267.629 166.5,279.5 Z"/></g>
<g><path style="opacity:1" fill="#646b75" d="M 470.5,243.5 C 472.117,244.038 473.784,244.371 475.5,244.5C 455.819,307.182 414.153,346.515 350.5,362.5C 350.5,367.833 350.5,373.167 350.5,378.5C 349.504,364.677 349.171,350.677 349.5,336.5C 363.073,332.546 376.073,327.213 388.5,320.5C 393.39,324.881 398.723,328.714 404.5,332C 407.634,332.79 410.634,332.457 413.5,331C 418.695,320.133 420.861,308.633 420,296.5C 429.49,287.19 437.99,277.19 445.5,266.5C 449.836,267.634 454.169,267.634 458.5,266.5C 462.381,259.405 465.715,252.071 468.5,244.5C 468.957,243.702 469.624,243.369 470.5,243.5 Z"/></g>
<g><path style="opacity:1" fill="#929caa" d="M 475.5,244.5 C 479.353,245.803 483.353,246.469 487.5,246.5C 494.507,245.832 501.507,245.166 508.5,244.5C 508.789,259.989 507.456,275.322 504.5,290.5C 489.693,314.491 471.693,335.991 450.5,355C 448.559,356.903 446.226,357.736 443.5,357.5C 430.061,354.675 416.728,355.175 403.5,359C 384.408,363.912 366.908,372.078 351,383.5C 350.506,381.866 350.34,380.199 350.5,378.5C 350.5,373.167 350.5,367.833 350.5,362.5C 414.153,346.515 455.819,307.182 475.5,244.5 Z"/></g>
<g><path style="opacity:1" fill="#060707" d="M 296.5,248.5 C 306.639,247.967 316.305,249.8 325.5,254C 330.919,257.291 330.752,260.124 325,262.5C 320.892,260.529 316.725,258.696 312.5,257C 307.5,256.333 302.5,256.333 297.5,257C 293.619,257.607 290.286,259.274 287.5,262C 280.445,262.638 279.112,260.305 283.5,255C 287.647,252.26 291.98,250.093 296.5,248.5 Z"/></g>
<g><path style="opacity:1" fill="#656c76" d="M 189.5,271.5 C 188.346,276.73 187.68,282.064 187.5,287.5C 174.664,276.195 164.831,262.862 158,247.5C 167.439,257.109 177.939,265.109 189.5,271.5 Z"/></g>
<g><path style="opacity:1" fill="#fcfcfc" d="M 233.5,258.5 C 229.851,282.63 219.184,303.13 201.5,320C 200.552,320.483 199.552,320.649 198.5,320.5C 195.719,306.001 194.886,291.334 196,276.5C 196.79,269.465 198.79,262.798 202,256.5C 209.371,250.045 217.537,248.878 226.5,253C 229.266,254.371 231.599,256.204 233.5,258.5 Z"/></g>
<g><path style="opacity:1" fill="#fbfbfb" d="M 385.5,252.5 C 399.088,250.614 407.255,256.28 410,269.5C 413.299,286.171 413.299,302.838 410,319.5C 408.994,325.011 406.494,325.845 402.5,322C 388.874,309.716 378.374,295.216 371,278.5C 367.52,269.627 369.686,262.461 377.5,257C 380.099,255.205 382.766,253.705 385.5,252.5 Z"/></g>
<g><path style="opacity:1" fill="#a9a9a9" d="M 233.5,258.5 C 236.081,261.161 237.748,264.328 238.5,268C 232.121,289.718 220.121,307.718 202.5,322C 200.206,324.216 198.872,323.716 198.5,320.5C 199.552,320.649 200.552,320.483 201.5,320C 219.184,303.13 229.851,282.63 233.5,258.5 Z"/></g>
<g><path style="opacity:1" fill="#636a73" d="M 364.5,283.5 C 369.297,294.416 375.63,304.416 383.5,313.5C 373.221,319.723 362.388,324.723 351,328.5C 350.879,313.549 352.379,298.883 355.5,284.5C 355.281,285.675 355.614,286.675 356.5,287.5C 359.507,286.663 362.174,285.33 364.5,283.5 Z"/></g>
<g><path style="opacity:1" fill="#626973" d="M 166.5,279.5 C 173.131,286.632 179.964,293.632 187,300.5C 187.826,303.793 188.326,307.126 188.5,310.5C 179.62,301.283 172.287,290.95 166.5,279.5 Z"/></g>
<g><path style="opacity:1" fill="#646b75" d="M 504.5,290.5 C 499.105,320.276 487.939,347.61 471,372.5C 470.282,373.451 469.449,373.617 468.5,373C 461.516,365.488 453.182,360.321 443.5,357.5C 446.226,357.736 448.559,356.903 450.5,355C 471.693,335.991 489.693,314.491 504.5,290.5 Z"/></g>
<g><path style="opacity:1" fill="#656c76" d="M 237.5,292.5 C 237.881,293.931 238.881,294.764 240.5,295C 246.03,296.873 251.697,298.039 257.5,298.5C 257.5,297.5 257.5,296.5 257.5,295.5C 259.506,306.936 260.506,318.602 260.5,330.5C 246.873,327.606 234.04,322.606 222,315.5C 227.134,307.925 232.301,300.258 237.5,292.5 Z"/></g>
<g><path style="opacity:1" fill="#040405" d="M 295.5,294.5 C 303.651,294.009 311.651,294.842 319.5,297C 323.77,297.912 325.604,300.412 325,304.5C 324.261,305.574 323.261,306.241 322,306.5C 316.392,303.445 310.392,301.778 304,301.5C 297.635,302.625 291.468,304.125 285.5,306C 284.424,304.274 284.257,302.441 285,300.5C 288.351,298.079 291.851,296.079 295.5,294.5 Z"/></g>
<g><path style="opacity:1" fill="#646b75" d="M 261.5,358.5 C 241.813,352.621 224.147,343.121 208.5,330C 207.552,329.517 206.552,329.351 205.5,329.5C 208.859,326.727 212.359,324.06 216,321.5C 230.031,329.29 244.864,335.123 260.5,339C 261.478,345.41 261.811,351.91 261.5,358.5 Z"/></g>
<g><path style="opacity:1" fill="#929cab" d="M 441.5,365.5 C 451.426,377.36 457.593,391.027 460,406.5C 461.028,414.461 461.528,422.461 461.5,430.5C 461.718,438.4 461.051,446.066 459.5,453.5C 443.868,443.809 430.368,446.142 419,460.5C 407.475,450.848 395.475,450.181 383,458.5C 375.469,450.767 366.302,447.6 355.5,449C 352.804,449.765 350.304,450.932 348,452.5C 350.031,446.383 351.698,440.05 353,433.5C 353.755,421.617 353.255,409.783 351.5,398C 351.536,395.906 351.869,393.906 352.5,392C 378.807,371.505 408.474,362.672 441.5,365.5 Z"/></g>
<g><path style="opacity:1" fill="#929cab" d="M 178.5,365.5 C 203.749,365.417 227.249,371.751 249,384.5C 246.08,389.652 243.08,394.985 240,400.5C 233.107,419.034 234.274,437.034 243.5,454.5C 242.091,456.671 240.258,458.338 238,459.5C 226.411,450.604 214.578,450.271 202.5,458.5C 185.785,443.896 170.619,445.23 157,462.5C 153.513,469.144 153.68,475.644 157.5,482C 147.634,478.123 141.134,470.957 138,460.5C 136.037,445.514 136.037,430.514 138,415.5C 140.626,397.736 148.792,383.236 162.5,372C 167.744,369.315 173.077,367.148 178.5,365.5 Z"/></g>
<g><path style="opacity:1" fill="#646b75" d="M 441.5,365.5 C 456.228,369.723 466.395,379.056 472,393.5C 479.087,413.238 481.42,433.572 479,454.5C 477.5,461.835 474.167,468.168 469,473.5C 468.602,465.452 465.436,458.786 459.5,453.5C 461.051,446.066 461.718,438.4 461.5,430.5C 461.528,422.461 461.028,414.461 460,406.5C 457.593,391.027 451.426,377.36 441.5,365.5 Z"/></g>
<g><path style="opacity:1" fill="#666d78" d="M 145.5,376.5 C 143.83,379.175 142.164,381.841 140.5,384.5C 136.969,378.122 132.802,372.122 128,366.5C 127.333,365.833 127.333,365.167 128,364.5C 133.439,369.111 139.273,373.111 145.5,376.5 Z"/></g>
<g><path style="opacity:1" fill="#5e656e" d="M 257.5,377.5 C 257.189,378.478 256.522,379.145 255.5,379.5C 252.769,377.808 250.102,376.142 247.5,374.5C 247.88,373.867 248.213,373.2 248.5,372.5C 251.688,373.925 254.688,375.592 257.5,377.5 Z"/></g>
<g><path style="opacity:1" fill="#646b74" d="M 344.5,407.5 C 349.823,430.684 343.49,450.184 325.5,466C 309.505,476.29 292.505,478.29 274.5,472C 257.047,463.919 246.714,450.419 243.5,431.5C 257.973,451.833 277.64,459.999 302.5,456C 327.505,449.174 341.505,433.007 344.5,407.5 Z"/></g>
<g><path style="opacity:1" fill="#fbfbfb" d="M 456.5,462.5 C 449.849,474.131 439.849,481.131 426.5,483.5C 426.932,478.002 426.265,472.669 424.5,467.5C 430.739,455.559 440.072,452.392 452.5,458C 454.041,459.371 455.375,460.871 456.5,462.5 Z"/></g>
<g><path style="opacity:1" fill="#fafafa" d="M 174.5,456.5 C 183.043,454.797 190.21,457.131 196,463.5C 195.639,466.924 194.639,470.258 193,473.5C 192.371,477.871 192.537,482.204 193.5,486.5C 182.916,486.583 173.083,483.916 164,478.5C 161.853,473.673 162.186,469.006 165,464.5C 167.772,461.217 170.939,458.55 174.5,456.5 Z"/></g>
<g><path style="opacity:1" fill="#f9f9f9" d="M 355.5,456.5 C 364.498,455.17 371.831,458.003 377.5,465C 373.564,471.385 372.564,478.218 374.5,485.5C 363.283,486.821 353.116,484.154 344,477.5C 341.764,471.097 343.264,465.597 348.5,461C 350.898,459.476 353.231,457.976 355.5,456.5 Z"/></g>
<g><path style="opacity:1" fill="#fafafa" d="M 213.5,460.5 C 230.106,458.837 238.273,466.17 238,482.5C 236.272,485.953 233.438,487.786 229.5,488C 222.167,488.667 214.833,488.667 207.5,488C 202.66,486.663 200.327,483.496 200.5,478.5C 201.431,469.947 205.764,463.947 213.5,460.5 Z"/></g>
<g><path style="opacity:1" fill="#f9f9f9" d="M 394.5,460.5 C 408.123,458.965 416.456,464.798 419.5,478C 419.438,483.397 416.772,486.73 411.5,488C 403.833,488.667 396.167,488.667 388.5,488C 383.464,486.604 381.131,483.271 381.5,478C 382.211,469.458 386.545,463.624 394.5,460.5 Z"/></g>
<g><path style="opacity:1" fill="#efefef" d="M 251.5,465.5 C 250.522,468.478 248.522,470.478 245.5,471.5C 242.962,467.099 243.962,463.932 248.5,462C 249.71,463.039 250.71,464.206 251.5,465.5 Z"/></g>
<g><path style="opacity:1" fill="#acacac" d="M 456.5,462.5 C 461.715,468.029 461.715,473.529 456.5,479C 447.665,483.505 438.331,485.505 428.5,485C 427.584,484.722 426.918,484.222 426.5,483.5C 439.849,481.131 449.849,474.131 456.5,462.5 Z"/></g>
<g><path style="opacity:1" fill="#aaaaaa" d="M 251.5,465.5 C 257.605,472.062 264.938,476.895 273.5,480C 265.167,483.585 256.501,485.252 247.5,485C 246.745,480.538 246.078,476.038 245.5,471.5C 248.522,470.478 250.522,468.478 251.5,465.5 Z"/></g>
</svg>

__END__
