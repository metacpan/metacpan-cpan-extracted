package Zonemaster::GUI::Dancer::NoJsFrontend;

use warnings;
use 5.14.2;

use Dancer ':syntax';
use Plack::Builder;
use HTML::Entities;
use Zonemaster::GUI::Dancer::Client;

our $VERSION = '1.0.7';

my $backend_port = 5000;
$backend_port = $ENV{ZONEMASTER_BACKEND_PORT} if ($ENV{ZONEMASTER_BACKEND_PORT});
my $url = "http://localhost:$backend_port";

sub params_backend2template {
    my ( $params ) = @_;

    my %template_params;
    no warnings 'uninitialized';

    $template_params{domain} = encode_entities( $params->{domain} ) if ( $params->{domain} );
    $template_params{ipv4} = ( $params->{ipv4} ) ? ( 'checked' ) : ( 'unchecked' );
    $template_params{ipv6} = ( $params->{ipv6} ) ? ( 'checked' ) : ( 'unchecked' );

    if ( $params->{profile} eq 'test_profile_1' ) {
        $template_params{profile_1_selected} = 'selected="selected"';
    }
    elsif ( $params->{profile} eq 'test_profile_2' ) {
        $template_params{profile_2_selected} = 'selected="selected"';
    }
    else {
        $template_params{default_profile_selected} = 'selected="selected"';
    }

    my $ns_id = 0;
    my @nameservers;
    foreach my $ns ( @{ $params->{nameservers} } ) {
        $ns_id++;
        push( @nameservers,
            { ns_id => $ns_id, ns => encode_entities( $ns->{ns} ), ip => encode_entities( $ns->{ip} ) } );
    }
    $template_params{nameservers} = \@nameservers if ( @nameservers );

    my $ds_id = 0;
    my @ds_info;
    foreach my $ds ( @{ $params->{ds_info} } ) {
        $ds_id++;
        push(
            @ds_info,
            {
                ds_id		=> $ds_id,
                keytag		=> encode_entities( $ds->{keytag} ),
                algorithm	=> encode_entities( $ds->{algorithm} ),
                digtype		=> encode_entities( $ds->{digtype} ),
                digest		=> encode_entities( $ds->{digest} ),
            }
        );
    }
    $template_params{ds_info} = \@ds_info if ( @ds_info );

    return \%template_params;
}

sub params_template2backend {
    my ( $params ) = @_;

    my %backend_params;
    $backend_params{domain}  = $params->{domain_name};
    $backend_params{ipv4}    = $params->{ipv4} if ( $params->{ipv4} );
    $backend_params{ipv6}    = $params->{ipv6} if ( $params->{ipv6} );
    $backend_params{profile} = $params->{profile} if ( $params->{profile} );

    $backend_params{client_id}      = 'Zonemaster NoJS Frontend';
    $backend_params{client_version} = $VERSION;

    my $ns_id = 1;
    while ( defined $params->{"ns$ns_id"} ) {
        push( @{ $backend_params{nameservers} }, { ns => $params->{"ns$ns_id"}, ip => $params->{"ip$ns_id"} } );
        $ns_id++;
    }

    my $ds_id = 1;
    while ( defined $params->{"algorithm$ds_id"} ) {
        push(
            @{ $backend_params{ds_info} },
            { keytag => $params->{"keytag$ds_id"}, algorithm => $params->{"algorithm$ds_id"}, digtype => $params->{"digtype$ds_id"}, digest => $params->{"digest$ds_id"} }
        );
        $ds_id++;
    }

    return \%backend_params;
}

any [ 'get', 'post' ] => '/nojs' => sub {
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );
    my %allparams = params;
    no warnings 'uninitialized';

    if ( $allparams{'button'} eq 'Add NS' ) {
        my $backend_params = params_template2backend( \%allparams );
        push(
            @{ $backend_params->{nameservers} },
            { ns_id => scalar( @{ $backend_params->{nameservers} } ) + 1, ns => '', ip => '' }
        );
        template 'nojs_main_view', params_backend2template( $backend_params ), { layout => undef };
    }

    elsif ( $allparams{'button'} =~ /^Delete NS\s+([\d]+)/ ) {
        my $backend_params = params_template2backend( \%allparams );
        splice( @{ $backend_params->{nameservers} }, $1 - 1, 1 );
        template 'nojs_main_view', params_backend2template( $backend_params ), { layout => undef };
    }

    elsif ( $allparams{'button'} =~ /^NS IP\s+([\d]+)/ ) {
        my $c = Zonemaster::GUI::Dancer::Client->new( { url => $url } );

        my $backend_params = params_template2backend( \%allparams );
        if ( length( $backend_params->{nameservers}->[ $1 - 1 ]->{ns} ) < 255 ) {
            my $ns_to_resolve = $backend_params->{nameservers}->[ $1 - 1 ]->{ns};
            my $ips           = $c->get_ns_ips( $ns_to_resolve );
            my @new_ns_ip_list;
            my $inserted = 0;
            foreach my $ns_ip ( @{ $backend_params->{nameservers} } ) {
                if ( $ns_ip->{ns} eq $ns_to_resolve ) {
                    push( @new_ns_ip_list, map { { ns => $ns_to_resolve, ip => $_->{$ns_to_resolve} } } @$ips )
                      unless ( $inserted );
                    $inserted = 1;
                }
                else {
                    push( @new_ns_ip_list, $ns_ip );
                }
            }
            $backend_params->{nameservers} = \@new_ns_ip_list;
            template 'nojs_main_view', params_backend2template( $backend_params ), { layout => undef };
        }
        else {
            template 'nojs_error_page', { error => 'ERROR 1: Invalid NS name' }, { layout => undef };
        }
    }

    elsif ( $allparams{'button'} eq 'Add DS' ) {
        my $backend_params = params_template2backend( \%allparams );
        push(
            @{ $backend_params->{ds_info} },
            { ds_id => scalar( @{ $backend_params->{ds_info} } ) + 1, keytag => '', algorithm => '', digtype => '', digest => '' }
        );
        template 'nojs_main_view', params_backend2template( $backend_params ), { layout => undef };
    }

    elsif ( $allparams{'button'} =~ /^Delete DS\s+([\d]+)/ ) {
        my $backend_params = params_template2backend( \%allparams );
        splice( @{ $backend_params->{ds_info} }, $1 - 1, 1 );
        template 'nojs_main_view', params_backend2template( $backend_params ), { layout => undef };
    }

    elsif ( $allparams{'button'} eq 'Fetch' ) {
        my $c = Zonemaster::GUI::Dancer::Client->new( { url => $url } );

        my $backend_params = params_template2backend( \%allparams );
        if ( length( $backend_params->{domain} ) < 255 ) {
            my $parent_zone_data = $c->get_data_from_parent_zone( $backend_params->{domain} );
            $backend_params->{nameservers}     = $parent_zone_data->{ns_list} if ( $parent_zone_data->{ns_list} );
            $backend_params->{ds_info} = $parent_zone_data->{ds_list} if ( $parent_zone_data->{ds_list} );
            template 'nojs_main_view', params_backend2template( $backend_params ), { layout => undef };
        }
        else {
            template 'nojs_error_page', { error => 'ERROR 2: Invalid domain name' }, { layout => undef };
        }
    }

    elsif ( $allparams{'button'} eq 'Run tests' ) {
        my $c              = Zonemaster::GUI::Dancer::Client->new( { url => $url } );
        my $backend_params = params_template2backend( \%allparams );
        my $syntax         = $c->validate_syntax( $backend_params );
        if ( $syntax->{status} eq 'ok' ) {
            my $test_id         = $c->start_domain_test( $backend_params );
            my $template_params = params_backend2template( $backend_params );
            $template_params->{test_running}  = 1;
            $template_params->{test_id}       = $test_id;
            $template_params->{test_progress} = '0';
            template 'nojs_main_view', $template_params, { layout => undef };
        }
        else {
            template 'nojs_error_page', { error => "ERROR 3: parameters are invalid ->[$syntax->{message}]" },
              { layout => undef };
        }
    }

    elsif ( request->method() eq 'GET' ) {
        if ( defined $allparams{'test_id'} ) {
            my $c              = Zonemaster::GUI::Dancer::Client->new( { url => $url } );
            my $backend_params = $c->get_test_params( $allparams{'test_id'} );
            my $progress       = $c->test_progress( $allparams{'test_id'} );
            if ( $progress < 100 ) {
                my $template_params = params_backend2template( $backend_params );
                $template_params->{test_running}  = 1;
                $template_params->{test_id}       = $allparams{'test_id'};
                $template_params->{test_progress} = $progress;
                template 'nojs_main_view', $template_params, { layout => undef };
            }
            else {
                my $test_result     = $c->get_test_results( { id => $allparams{'test_id'}, language => 'en' } );
                my $backend_params  = $test_result->{params};
                my $previous_module = '';
                my $template_params = params_backend2template( $backend_params );
                my @test_results;
                my $last_module_index = 0;
                my $module_type;
                my %severity = ( INFO => 0, NOTICE => 1, WARNING => 2, ERROR => 3 );

                foreach my $result ( @{ $test_result->{results} } ) {
                    if ( $previous_module ne $result->{module} ) {
                        push( @test_results, { is_module => 1, message => $result->{module} } );
                        $test_results[$last_module_index]->{type} = lc( $module_type );
                        $last_module_index                        = $#test_results;
                        $previous_module                          = $result->{module};
                        undef( $module_type );
                    }
                    $module_type = $result->{level} if ( $severity{$module_type} < $severity{ $result->{level} } );

                    push( @test_results,
                        { is_module => 0, message => $result->{message}, type => lc( $result->{level} ) } );
                }
                $test_results[$last_module_index]->{type} = lc( $module_type );

                $template_params->{test_results}  = \@test_results;
                $template_params->{test_running}  = 0;
                $template_params->{test_id}       = $allparams{'test_id'};
                $template_params->{test_progress} = 100;
                template 'nojs_main_view', $template_params, { layout => undef };
            }
        }
        else {
            template 'nojs_main_view', {}, { layout => undef };
        }
    }

    else {
        template 'nojs_error_page', { error => 'ERROR' }, { layout => undef };
    }
};

true;
