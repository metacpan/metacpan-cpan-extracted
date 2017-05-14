package WWW::Xunlei::Downloader;

# ABSTRACT: Downloader Object for Xunlei Remote Service.

use strict;
use warnings;

sub new {
    my $class = shift;
    my ( $client, $downloader ) = @_;

    my $self = { 'client' => $client, };
    $self->{$_} = $downloader->{$_} for (%$downloader);

    bless $self, $class;
    return $self;
}

sub is_online {
    my $self = shift;

    return $self->{'online'};
}

sub login {
    my $self = shift;

    my $res = $self->_request('login');
}

sub get_config {
    my $self = shift;

    my $res = $self->_request('settings');
}

sub set_config {
    my $self   = shift;
    my $config = shift;

    my $parameters;

    # Todo: validate the keys of $config.
    for my $k ( keys %$config ) {
        $parameters->{$k} = $config->{$k};
    }

    my $res = $self->_request( 'settings', $parameters );
}

sub unbind {
    my $self = shift;

    my $res = $self->_request('unbind');
}

sub rename {
    my $self = shift;
    my ( $pid, $new_name ) = @_;
    my $parameters = { 'boxname' => $new_name, };

    my $res = $self->_request( 'rename', $parameters );
}

sub get_box_space {
    my $self = shift;

    my $res = $self->_request('boxSpace');
    return wantarray ? @{ $res->{'space'} } : $res->{'space'};
}

sub list_running_tasks {
    my $self = shift;
    my ($number) = @_;
    return $self->list_tasks( 'running', $number );
}

sub list_completed_tasks {
    my $self = shift;
    my ($number) = @_;
    return $self->list_tasks( 'completed', $number );
}

sub list_recycled_tasks {
    my $self = shift;
    my ($number) = @_;
    return $self->list_tasks( 'recycled', $number );
}

sub list_failed_tasks {
    my $self = shift;
    my ($number) = @_;
    return $self->list_tasks( 'failed', $number );
}

sub list_tasks {
    my $self = shift;
    my ( $type, $pos, $number );

    $type = shift || 'running';
    if ( @_ > 0 ) {
        ( $pos, $number ) = @_;
    }
    else {
        ($number) = @_;
    }

    my %types = (
        'running'   => 0,
        'completed' => 1,
        'recycled'  => 2,
        'failed'    => 3,
    );

    $type = $types{$type};
    $number ||= 20;
    $pos    ||= 0;

    my $parameters = {
        'type'   => $type,
        'pos'    => $pos,
        'number' => $number,
    };

    my $res = $self->_request( 'list', $parameters );
    return wantarray ? @{ $res->{'tasks'} } : $res->{'tasks'};
}

sub start {
    my $self  = shift;
    my $tasks = shift;
    return $self->_control_tasks( 'start', $tasks );
}

sub pause {
    my $self  = shift;
    my $tasks = shift;
    return $self->_control_tasks( 'pause', $tasks );
}

sub delete {
    my $self = shift;
    my ( $tasks, $delete_file ) = @_;
    my $parameters = {
        'deleteFile'  => \1,
        'recycleFile' => 1,
    };

    $parameters->{'deleteFile'} = $delete_file ? \1 : \0;

    return $self->_control_tasks( 'del', $tasks );
}

sub _control_tasks {
    my $self = shift;
    my ( $action, $tasks, $parameters ) = @_;
    if ( ref $tasks ne 'ARRAY' ) {
        $tasks = [$tasks];
    }

    my @ids;
    for my $t (@$tasks) {
        push @ids, join( '_', $t->{'id'}, $t->{'state'} );
    }

    $parameters->{'tasks'} = join( ',', @ids );

    my $res = $self->_request( $action, $parameters );
    return wantarray ? @{ $res->{'tasks'} } : $res->{'tasks'};
}

sub open_lixian_channel {
    my $self       = shift;
    my $task_id    = shift;
    my $parameters = {
        'open'   => \1,
        'taskid' => $task_id,
    };

    return $self->_request( 'openLixianChannel', $parameters );
}

sub open_vip_channel {
    my $self       = shift;
    my $task_id    = shift;
    my $parameters = { 'taskid' => $task_id, };

    return $self->_request( 'openVipChannel', $parameters );
}

sub url_check {
    my $self = shift;
    my ( $url, $type ) = @_;

    my $parameters = {
        'url'  => $url,
        'type' => $type,
    };

    my $res = $self->_request( 'urlCheck', $parameters );
}

sub url_resolve {
    my $self = shift;
    my $url  = shift;

    my $data = { 'url' => $url };

    my $res = $self->_request( 'urlResolve', undef, $data );
    return $res;
}

sub get_general_task_info {
    my $self = shift;

    my ( $url, $filename ) = @_;

    unless ( $url =~ /^(http|https|ftp|magnet|ed2k|thunder|mms|rtsp)\:.+/ ) {
        die "Not a valid URL.";
    }

    my $task = {
        'gcid'     => "",
        'cid'      => '',
        'filesize' => 0,
        'ext_json' => { 'autoname' => 1 },
    };

    my $res = $self->url_resolve($url)->{'taskInfo'};
    $task = {
        'url'      => $res->{'url'},
        'name'     => $res->{'name'},
        'filesize' => $res->{'size'},
    };

    if ( $filename && $task->{'name'} ne $filename ) {
        $task->{'name'} = $filename;
        $task->{'ext_json'}->{'autoname'} = 0;
    }

    return $task;
}

sub create_task {
    my $self = shift;
    my ( $url, $filename, $path ) = @_;

    my $task = $self->get_general_task_info( $url, $filename );

    my $res = $self->_create_general_tasks( [$task], $path );
    return wantarray ? @{ $res->{'tasks'} } : $res->{'tasks'};
}

sub create_tasks {
    my $self = shift;
    my ( $urls, $path ) = @_;

    my @tasks;
    for my $url (@$urls) {
        my $task_info = $self->url_resolve($url);
        if ( $task_info->{'taskInfo'}->{'type'} == 2 ) {
            my @btsub = map { $_->{'id'} }
                grep { auto_select($_) }
                @{ $task_info->{'taskInfo'}->{'subList'} };

            $self->_create_bt_task(
                $task_info->{'taskInfo'}->{'name'},
                $task_info->{'infohash'},
                \@btsub, $path
            );
        }
        else {
            push @tasks, $self->get_general_task_info($url);
        }
    }

    $self->_create_general_tasks( \@tasks, $path );

    #return wantarray ? @{ $res->{'tasks'} } : $res->{'tasks'};
}

sub _create_general_tasks {
    my $self = shift;
    my ( $tasks, $path ) = @_;

    my $data;
    $data->{'tasks'} = $tasks;
    $data->{'path'} = $path || $self->get_config->{'defaultPath'};

    my $res = $self->_request( 'createTask', undef, $data );
}

sub _create_bt_task {
    my $self = shift;
    my ( $name, $infohash, $btsub, $path ) = @_;

    $path ||= $self->get_config->{'defaultPath'};
    my $data = {
        'name'     => $name,
        'infohash' => $infohash,
        'btSub'    => $btsub,
        'path'     => $path,
    };

    my $res = $self->_request( 'createBtTask', undef, $data );
}

sub auto_select {
    my $btsub = shift;

    return 0 if $btsub->{'size'} < 15360;
    return 0 if $btsub->{'name'} =~ /txt|html|htm|url$/i;
    return 1;
}

sub _request {
    my $self = shift;
    my ( $action, $parameters, $data ) = @_;

    $parameters->{'pid'} = $self->{'pid'};

    unless ( $self->is_online ) {
        die "Downloader is not Online. Please check Xunlei Remote Service.";
    }

    my $res = $self->{'client'}->_yc_request( $action, $parameters, $data );
    if ( $res->{'rtn'} != 0 ) {

        # Todo: Handling not login failed here.
        die "Request Error: $res->{'rtn'}";
    }

    return $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Xunlei::Downloader - Downloader Object for Xunlei Remote Service.

=head1 VERSION

version 0.03

=head1 AUTHOR

Zhu Sheng Li <zshengli@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Zhu Sheng Li.

This is free software, licensed under:

  The MIT (X11) License

=cut
