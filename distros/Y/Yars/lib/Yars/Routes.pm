package Yars::Routes;

# ABSTRACT: set up the routes for Yars.
our $VERSION = '1.31'; # VERSION


use strict;
use warnings;
use Mojo::ByteStream qw/b/;
use Clustericious::Log;
use File::Path qw/mkpath/;
use File::Temp;
use Clustericious::RouteBuilder;
use if $^O ne 'MSWin32', 'Filesys::Df' => qw/df/;
use List::Util qw/ shuffle uniq /;
use Digest::file qw/digest_file_hex/;
use File::Basename qw/basename/;
use JSON::MaybeXS qw( encode_json );
use Yars::Util qw( format_tx_error );

BEGIN {
  if($^O eq 'MSWin32')
  {
    # Filesys::Df is not available for MSWin32,
    # so we use Filesys::DfPortable on that platform
    require Filesys::DfPortable;
    *df = sub {
      my $df = Filesys::DfPortable::dfportable(@_);
      $df->{used} = $df->{bused};
      $df;
    };
  }
}


get '/' => sub { shift->render(text => "welcome to Yars", format => 'txt', status => 200 ) } => 'index';


get  '/file/#filename/:md5' => [ md5 => qr/[a-f0-9]{32}/ ] => \&_get;
get  '/file/:md5/#filename' => [ md5 => qr/[a-f0-9]{32}/ ] => \&_get => "file";
sub _get {
    my $c        = shift;
    my $filename = $c->stash("filename");
    my $md5      = $c->stash("md5");

    return _head($c, @_) if $c->req->method eq 'HEAD';

    my $url = $c->tools->server_for($md5);
    if ($url ne $c->tools->server_url) {
        TRACE "$md5 should be on $url";
        # but check our local stash first, just in case.
        _get_from_local_stash($c,$filename,$md5) and return;
        $c->res->headers->add("X-Yars-Cache" => 0);
        return $c->render_moved("$url/file/$md5/$filename");
    }

    my $dir = $c->tools->storage_path($md5);
    -r "$dir/$filename" or do {
        return
             _get_from_local_stash( $c, $filename, $md5 )
          || _redirect_to_remote_stash( $c, $filename, $md5 )
          || $c->reply->not_found;
    };

    if($c->config->download_md5_verify(default => 1) || !$c->req->headers->header('X-Yars-Skip-Verify')) {
        my $computed = digest_file_hex("$dir/$filename",'MD5');
        unless($computed eq $md5) {
            WARN "Content mismatch, possible disk corruption ($filename), $md5 != $computed";
            return $c->render(text => "content-mismatch", status => 500);
        }
    }

    if ($c->req->headers->header('X-Yars-Use-X-Accel')) {
        return _x_accel_redirect($c, "$dir/$filename", $md5);
    }

    $c->res->headers->add("Content-MD5", $c->tools->hex2b64($md5));
    $c->app->static->paths([$dir])->serve($c,$filename);
    _set_static_headers($c,"$dir/$filename");
    $c->rendered;
};

sub _x_accel_redirect
{
    my ($c, $localfile, $md5) = @_;

    my $b64 = $c->tools->hex2b64($md5);
    $c->res->headers->add("Content-MD5", $b64);
    my $types = $c->app->types;
    my $type  = $localfile =~ /\.(\w+)$/ ? $types->type($1) : undef;
    $c->res->headers->content_type($type || $types->type('bin'));
    $c->res->headers->add('X-Accel-Redirect', "/static$localfile");

    return $c->render(status => 200, text => '');
}

sub _set_static_headers {
    # Based on Mojolicious::Static.  Probably should support if-modified..?
    my $c = shift;
    my $filepath = shift;
    my ($size, $modified) = (stat $filepath)[7, 9];
    my $rsh = $c->res->headers;
    $rsh->content_length($size);
    $rsh->last_modified(Mojo::Date->new($modified));
    $rsh->accept_ranges('bytes');
    my $types = $c->app->types;
    my $type  = $filepath =~ /\.(\w+)$/ ? $types->type($1) : undef;
    $c->res->headers->content_type($type || $types->type('bin'));
    return 1;
}



sub _head {
    my $c        = shift;
    my $filename = $c->stash("filename");
    my $md5      = $c->stash("md5");

    # Just check the local stash and return?
    my $check_stash = $c->req->headers->header("X-Yars-Check-Stash") ? 1 : 0;
    my $url;
    $url = $c->tools->server_for($md5) unless $check_stash;

    # Check the local stash if we are asked to, or if it doesn't belong here.
    if ($check_stash or $url ne $c->tools->server_url) {
        if (my $found_dir = $c->tools->local_stashed_dir($filename,$md5)) {
            _set_static_headers($c,"$found_dir/$filename");
            return $c->render(status => 200, text => 'found');
        }
        return $c->reply->not_found if $check_stash;
        return $c->render_moved("$url/file/$md5/$filename");
    }

    # It belongs here.  But it might still be stashed locally or remotely.
    my $dir = $c->tools->storage_path($md5);
    my $found_dir = -r "$dir/$filename" ? $dir : undef;
    $found_dir ||= $c->tools->local_stashed_dir( $filename, $md5 );
    return if _redirect_to_remote_stash($c, $filename, $md5 );
    return $c->reply->not_found unless $found_dir;
    _set_static_headers($c,"$found_dir/$filename");
    $c->render( status => 200, text => 'found' );
}

sub _get_from_local_stash {
    my ($c,$filename,$md5) = @_;
    # If this is stashed locally, serve it and return true.
    # Otherwise return false.
    my $dir = $c->tools->local_stashed_dir($filename,$md5) or return 0;

    if($c->config->download_md5_verify(default => 1) || !$c->req->headers->header('X-Yars-Skip-Verify')) {
        my $computed = digest_file_hex("$dir/$filename",'MD5');
        unless($computed eq $md5) {
            WARN "Content mismatch, possible disk corruption ($filename), $md5 != $computed";
            return $c->render(text => "content-mismatch", status => 500);
        }
    }

    if ($c->req->headers->header('X-Yars-Use-X-Accel')) {
        return _x_accel_redirect($c, "$dir/$filename", $md5);
    }

    $c->res->headers->add("Content-MD5", $c->tools->hex2b64($md5));
    $c->app->static->paths([$dir])->serve($c,$filename);
    $c->rendered;
    return 1;
}

sub _redirect_to_remote_stash {
    my ($c,$filename,$digest) = @_;
    DEBUG "Checking remote stashes";
    if (my $server = $c->tools->remote_stashed_server($filename,$digest)) {
        $c->res->headers->location("$server/file/$digest/$filename");
        $c->res->headers->content_length(0);
        $c->rendered(307);
        return 1;
    };
    return 0;
}


put '/file/#filename/:md5' => { md5 => 'calculate' } => sub {
    my $c        = shift;
    my $filename = $c->stash('filename');
    my $md5      = $c->stash('md5');

    my $asset    = $c->req->content->asset;
    my $digest;
    if ($asset->isa("Mojo::Asset::File")) {
        TRACE "Received file asset with size ".$asset->size;
        $digest = digest_file_hex($asset->path,'MD5');
        TRACE "Md5 of ".$asset->path." is $digest";
    } else {
        TRACE "Received memory asset with size ".$asset->size;
        $digest = b($asset->slurp)->md5_sum->to_string;
    }

    $md5 = $digest if $md5 eq 'calculate';

    if ($digest ne $md5) {
        WARN "md5 mismatch : $md5 != $digest for $filename which isa ".(ref $asset);
        return $c->render(text => "incorrect digest, $md5!=$digest", status => 400);
    }

    if ($c->req->headers->header('X-Yars-Stash')) {
        DEBUG "Stashing a file that is not ours : $digest $filename";
        _stash_locally($c, $filename, $digest, $asset) and return;
        return $c->reply->exception("Cannot stash $filename locally");
    }

    DEBUG "Received NoStash for $filename" if $c->req->headers->header('X-Yars-NoStash');

    my $assigned_server = $c->tools->server_for($digest);

    if ( $assigned_server ne $c->tools->server_url ) {
        TRACE "assigned $assigned_server != ".$c->tools->server_url;
        return _proxy_to( $c, $assigned_server, $filename, $digest, $asset, 0 )
              || _stash_locally( $c, $filename, $digest, $asset )
              || _stash_remotely( $c, $filename, $digest, $asset )
              || $c->render(status => 507, text => "Unable to proxy or stash");
    }

    my $assigned_disk = $c->tools->disk_for($digest);

    DEBUG "Received $filename assigned to $assigned_server ($assigned_disk), this is ".$c->tools->server_url;

    unless (-d $assigned_disk) {
        INFO "$assigned_disk does not exist, creating it now";
        mkdir $assigned_disk or WARN "Failed to mkdir $assigned_disk : $!";
    }
    if ( $c->tools->disk_is_up($assigned_disk) ) {
        my $assigned_path = $c->tools->storage_path($digest, $assigned_disk);
        my $abs_path = join '/', $assigned_path, $filename;
        my $location = $c->url_for("file", md5 => $digest, filename => $filename)->to_abs;
        if (-e $abs_path) {
            TRACE "Found another file at $abs_path, comparing content";
            my $old_md5 = digest_file_hex($abs_path,"MD5");
            if ($old_md5 eq $digest) {
                if ($c->tools->content_is_same($abs_path,$asset)) {
                    $c->res->headers->location($location);
                    return $c->render(status => 200, text => 'exists');
                } else {
                    WARN "Same md5, but different content for $filename";
                    return $c->render(status => 409, text => 'md5 collision');
                }
            }
            DEBUG "md5 of content in $abs_path was incorrect; replacing corrupt file"
        }
        if (my $existing = _other_files_in_path( $assigned_path ) ) {
            if (_make_link($existing,"$assigned_path/$filename")) {
                $c->res->headers->location($location);
                return $c->render(status => 201, text => 'ok'); # CREATED
            }
        }
        if (_atomic_write( $assigned_path , $filename, $asset ) ) {
            # Normal situation.
            $c->res->headers->location($location);
            return $c->render(status => 201, text => 'ok'); # CREATED
       }
    } else {
        DEBUG "Disk $assigned_disk is not up";
    }

    # Local designated disk is down.
    _stash_locally( $c, $filename, $digest, $asset )
      or _stash_remotely( $c, $filename, $digest, $asset )
      or $c->render(status => 507, text => "Unable to proxy or stash");
};

sub _other_files_in_path {
    my $path = shift;
    opendir( DR, $path ) or return;
    my $found;
    while ( $_ = readdir DR ) {
        next if /^\.\.?$/;
        $found = $_;
        last;
    }
    closedir DR;
    return unless $found;
    return "$path/$found";
}

sub _make_link {
    my ($old,$new) = @_;
    DEBUG "Making a hard link for $new";
    my $status = link($old,$new);
    WARN "Failed to link $old to $new : $!" unless $status;
    return $status;
}

sub _proxy_to {
    my ($c, $url,$filename,$digest,$asset,$temporary) = @_;
    # Proxy a file to another url.
    # On success, render the response and return true.
    # On failure, return false.
   my $res;
   DEBUG "Proxying file $filename with md5 $digest to $url/file/$filename/$digest"
      . ( $temporary ? " temporarily" : "" );
   my $headers = $temporary ? { 'X-Yars-Stash' => 1 } : {};
   $headers->{"Content-MD5"} = $c->tools->hex2b64($digest);
   $headers->{Connection} = "Close";
   my $tx = $c->tools->_ua->build_tx(PUT => "$url/file/$filename/$digest", $headers );
   $tx->req->content->asset($asset);
   $tx = $c->tools->_ua->start($tx);
   if ($res = $tx->success) {
       my $headers = $c->res->headers;
       $headers->location($tx->res->headers->location);
       $headers->add("X-Yars-Cache" => 0) unless $temporary;
       $c->render(status => $tx->res->code, text => 'ok');
       return 1;
   }
   ERROR "failed to proxy $filename to $url : " . format_tx_error($tx->error);
   return 0;
}

sub _atomic_write {
    my ($dir, $filename, $asset) = @_;
    TRACE "Writing $dir/$filename";
    # Write a file atomically.  Return 1 on success, 0 on failure.
    my $failed;
    eval {
        mkpath $dir; # dies on error
        $asset->move_to("$dir/$filename") or LOGDIE "failed to write $dir/$filename: $!";
    }; if($@) {
        WARN "Could not write $dir/$filename : $@";
        $failed = 1;
    };
    return 0 if $failed;
    TRACE "Wrote $dir/$filename";
    return 1;
}

sub _stash_locally {
    my ($c, $filename,$digest, $asset) = @_;
    # Stash this file on a local disk.
    # Returns false or renders the response.

    return 0 if $c->req->headers->header('X-Yars-NoStash');

    DEBUG "Stashing $filename locally";
    my $assigned_root = $c->tools->disk_for($digest);
    $assigned_root //= '';
    my $wrote;
    for my $root (shuffle($c->tools->disk_roots)) {
        TRACE "Trying $root (assigned : $assigned_root)";
        next if $assigned_root && ($root eq $assigned_root);
        unless ($c->tools->disk_is_up($root)) {
            DEBUG "local disk $root is down, cannot stash $filename there.";
            next;
        }
        my $dir = $c->tools->storage_path( $digest, $root );
        _atomic_write( $dir, $filename, $asset ) and do {
            $wrote = $root;
            last;
        };
        TRACE "write failed";
    }
    WARN "Help, all my disks are unwriteable!" unless $wrote;
    # I'm not dead yet!  It's only a flesh wound!
    return 0 unless $wrote;
    my $location = $c->url_for("file", md5 => $digest, filename => $filename)->to_abs;
    $c->res->headers->location($location);
    $c->render(status => 201, text => 'ok'); # CREATED
    DEBUG "Stashed $filename ($digest) locally on $wrote";
    return 1;
}

sub _stash_remotely {
    my ($c, $filename,$digest,$asset) = @_;
    # Stash this file on a remote disk.
    # Returns false or renders the response.

    return 0 if $c->req->headers->header('X-Yars-NoStash');

    DEBUG "Stashing $filename remotely.";
    my $assigned_server = $c->tools->server_for($digest);
    for my $server (shuffle($c->tools->server_urls)) {
        next if $server eq $c->tools->server_url;
        next if $server eq $assigned_server;
        _proxy_to( $c, $server, $filename, $digest, $asset, 1 ) and return 1;
    }
    return 0;
}


del '/file/#filename/:md5' => [ md5 => qr/[a-f0-9]{32}/ ] => \&_del;
del '/file/:md5/#filename' => [ md5 => qr/[a-f0-9]{32}/ ] => \&_del;

sub _del {
    my $c        = shift;
    my $md5      = $c->stash("md5");
    my $filename = $c->stash('filename');
    TRACE "Delete request for $filename, $md5";

    # Delete locally or proxy the delete if it is stashed somewhere else.

    my $server = $c->tools->server_for($md5);
    if ($server eq $c->tools->server_url) {
        DEBUG "This is our file, we will delete it.";
        my $dir  = $c->tools->storage_path( $md5 );
        if (-r "$dir/$filename") {
            unlink "$dir/$filename" or return $c->reply->exception($!);
            $c->tools->cleanup_tree($dir);
            return $c->render(status => 200, text =>'ok');
        }

        $server = $c->tools->remote_stashed_server($filename, $md5);
        return $c->reply->not_found unless $server;
        # otherwise fall through...
    }

    if (my $dir = $c->tools->local_stashed_dir($filename,$md5)) {
        unlink "$dir/$filename" or return $c->reply->exception($!);
        $c->tools->cleanup_tree($dir);
        return $c->render(status => 200, text =>'ok');
    }

    DEBUG "Proxying delete to $server";
    my $tx = $c->tools->_ua->delete("$server/file/$md5/$filename");
    if (my $res = $tx->success) {
        return $c->render(status => 200, text => "ok");
    } else  {
        my $error = $tx->error;
        my ($msg,$code) = ($error->{message}, $error->{code});
        return $c->render(status => $code, text => $msg) if $code;
        return $c->reply->exception("Error deleting from $server ".format_tx_error($tx->error));
    }
};


get '/disk/usage' => sub {
    my $c = shift;
    my $count = $c->param("count") ? 1 : 0;
    if ( my $server = $c->param('server') ) {
        if (    $c->tools->server_exists($server)
            and $c->tools->server_url ne $server ) {
            return $c->redirect_to("$server/disk/usage?count=$count");
        }
    }

    my %r;
    for my $disk ($c->tools->disk_roots) {
        if (defined( my $df = df($disk))) {
            $r{$disk} = {
                    '1K-blocks'  => $df->{blocks},
                    blocks_used  => $df->{used},
                    blocks_avail => $df->{bavail},
                    space        => $c->tools->human_size($df->{blocks}*1024),
                    space_used   => $c->tools->human_size($df->{used}*1024),
                    space_avail  => $c->tools->human_size($df->{bavail}*1024),
                    percent_used => sprintf('%02d',(100*($df->{blocks} - $df->{bavail})/($df->{blocks}))).'%',
                };
        } else {
            WARN "Error getting usage for disk $disk" if -d $disk;
            DEBUG "$disk does not exist" unless -d $disk;
        }
        $r{$disk}{count} = $c->tools->count_files($disk) if $count;
    }
    return $c->render(autodata => \%r) unless $c->param('all');
    my %all = ( $c->tools->server_url => \%r );
    for my $server ($c->tools->server_urls) {
        next if exists $all{$server};
        my $tx = $c->tools->_ua->get("$server/disk/usage?count=$count");
        my $res = $tx->success or do {
            $all{$server} = 'down';
            next;
        };
        $all{$server} = $res->json;
    }
    return $c->render(autodata => \%all);
};


post '/disk/status' => sub {
    my $c = shift;
    my $got = $c->parse_autodata;
    my $root = $got->{root} || $got->{disk};
    my $state = $got->{state} or return $c->reply->exception("no state found in request");
    my $server = $got->{server};
    if ($server && $server ne $c->tools->server_url) {
        unless ($c->tools->server_exists($server)) {
            return $c->render( status => 400, text => "Server $server does not exist" );
        }
        WARN "Sending ".$c->req->body;
        my $tx = $c->tools->_ua->post("$server/disk/status", $c->req->headers->to_hash, ''.$c->req->body );
        return $c->render( text => $tx->success ? $tx->res->body : 'failed '.format_tx_error($tx->error) );
    }
    $c->tools->disk_is_local($root) or return $c->render->exception("Disk $root is not on ".$c->tools->server_url);
    my $success;
    for ($state) {
        /down/ and $success = $c->tools->mark_disk_down($root);
        /up/   and $success = $c->tools->mark_disk_up($root);
    }
    $c->render(text => $success ? "ok" : "failed" );
};


post '/check/manifest' => sub {
    my $c = shift;
    my $got = $c->parse_autodata;
    my $files = $got->{files} || [];
    if (my $manifest = $got->{manifest}) {
        for my $line (split /\n/, $manifest) {
            my ($md5,$filename) = split /\s+/, $line;
            push @$files, +{ md5 => $md5, filename => $filename };
        }
    }
    my %ret = ( missing => [], found => [] );
    my %remote;
    for my $entry (@$files) {
        my ($filename,$md5) = @$entry{qw/filename md5/};
        next unless $md5 && $md5 =~ /^[0-9a-fA-F]+$/;
        next unless $filename && $filename =~ /\w/;
        $filename = basename($filename);
        next if $filename =~ m[/];
        TRACE "checking for $md5 and $filename";
        my $server = $c->tools->server_for($md5);
        if ($server eq $c->tools->server_url) {
            my $dir = $c->tools->storage_path($md5);
            my $which = -r "$dir/$filename" ? "found" : "missing";

            if ($which eq 'found' && $c->param('show_corrupt')) {
                # Check md5, and maybe set $which to "corrupt".
                my $computed_md5 = digest_file_hex("$dir/$filename",'MD5');
                if ($computed_md5 ne $md5) {
                    $which = 'corrupt';
                    $md5 = $computed_md5;
                }
            }

            push @{ $ret{$which} }, { filename => $filename, md5 => $md5 };
        } else {
            push @{ $remote{$server} }, { filename => $filename, md5 => $md5 };
        }
    }

    for my $server (keys %remote) {
        TRACE "Looking for manifest files on $server";
        my $content = encode_json { files => $remote{$server} };
        my $tx = $c->tools->_ua->post(
            "$server/check/manifest?show_found=1&show_corrupt=".($c->param("show_corrupt")//''),
            { "Content-type" => "application/json", "Connection" => "Close" }, $content );
        if (my $res = $tx->success) {
            my $got = $res->json;
            push @{ $ret{missing} }, @{ $got->{missing} };
            push @{ $ret{found}   }, @{ $got->{found} };
            push @{ $ret{corrupt} }, @{ $got->{corrupt} || [] } if $c->param("show_corrupt");
        } else {
            ERROR "Failed to connect to $server";
            push @{ $ret{missing} }, @{ $remote{$server} };
        }
    }

    # Check stashes for missing ones to be sure.
    my $missing = $ret{missing};
    my @are_missing;
    my @not_missing;
    for my $m (@$missing) {
        my $found = $c->tools->local_stashed_dir( $m->{filename}, $m->{md5} )
         || $c->tools->remote_stashed_server( $m->{filename}, $m->{md5} );
        if ($found) {
            push @not_missing, $m;
        } else {
            push @are_missing, $m;
        }
    }
    if (@not_missing) {
        push @{ $ret{found} }, @not_missing;
        $ret{missing} = \@are_missing;
    }

    $ret{found} = scalar @{ $ret{found} } unless $c->param("show_found");
    $c->render(autodata => \%ret);
};


get '/servers/status' => sub {
    my $c = shift;
    my %disks =
      map { $_ => $c->tools->disk_is_up_verified($_) ? "up" : "down" }
      $c->tools->disk_roots;
    my %all;
    $all{$c->tools->server_url} = \%disks;
    for my $server ($c->tools->server_urls) {
        next if exists($all{$server});
        my $tx = $c->tools->_ua->get("$server/server/status");
        if (my $res = $tx->success) {
            $all{$server} = $res->json;
        } else {
            WARN "Could not reach $server : ".format_tx_error($tx->error);
            $all{$server} = "down";
        }
    }
    $c->render(autodata => \%all);
};


get '/server/status' => sub {
    my $c = shift;
    my %disks =
      map { $_ => $c->tools->disk_is_up_verified($_) ? "up" : "down" }
      $c->tools->disk_roots;
    $c->render(autodata => \%disks);
};


get '/bucket_map' => sub {
    my $c = shift;
    $c->render(autodata => $c->tools->bucket_map)
};


get '/bucket/usage' => sub {
    my $c = shift;
    if ( my $server = $c->param('server') ) {
        if (    $c->tools->server_exists($server)
            and $c->tools->server_url ne $server ) {
            return $c->redirect_to("$server/bucket/usage");
        }
    }
    my %used;
    my %assigned = $c->tools->local_buckets;

    # NB: this assumes homogeneous buckets and doesn't
    # work for > 256 buckets.
    my $bucket_size = 1;
    for (keys %assigned) {
        for (@{ $assigned{$_} }) {
            $bucket_size = length($_) if length($_) > $bucket_size;
        }
    }

    for my $disk ($c->tools->disk_roots) {
        my @dirs = map /\/([0-9a-f]+)$/, glob "$disk/*";
        my @buckets = uniq map substr($_,0,$bucket_size), @dirs;
        $used{$disk} = \@buckets;
    }
    $c->render(autodata => { used => \%used, assigned => \%assigned } );
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Yars::Routes - set up the routes for Yars.

=head1 VERSION

version 1.31

=head1 SYNOPSIS

 % curl http://localhost:9001/file/764efa883dda1e11db47671c4a3bbd9e/test_file1

=head1 DESCRIPTION

This document provides information on the Yars specific REST API (the 
HTTP "routes") provided by Yars servers.  For a Perl interface to this 
API, see L<Yars::Client>.  For a command line interface see 
L<yarsclient>.  For the generic L<Clustericious> REST API that comes 
with all L<Clustericious> services, see 
L<Clustericious::RouteBuilder::Common>.

=head1 ROUTES

=head2 GET /

Get a welcome message.  This is usually simply the text string "welcome 
to Yars".

=head2 GET /file/#filename/:md5, GET /:md5/#filename

Retrieve a file with the given name and md5.

You can also make a HEAD request on the same route to determine if the 
file is available without making the yars server send the file.

=head2 PUT /file/#filename/#md5

PUT a file with the given name and md5.

=head2 DELETE /file/#filename/:md5, /file/:md5/#filename

Delete a file with the given name and md5.

=head2 GET /disk/usage

Get a summary of the disk usage.

Send the CGI parameters count=1 to also count the files.

=head2 POST /disk/status

Mark disks up or down.  Send the disk root and state (up or down)
as JSON encoded in the body.

=head2 POST /check/manifest

Given JSON with 'manifest' which is a return-delimited string of 
filenames and md5s (like the output of md5sum), check each file for 
existence on the server (or proxy to the right server)

=head2 GET /servers/status

Get the status of all the disks on all the servers/

=head2 GET /server/status

Get the status of just this server.

=head2 GET /bucket_map

Get a mapping from buckets to hosts.

=head2 GET /bucket/usage

Find the disk usage per bucket.

=head1 SEE ALSO

L<Yars>, L<Yars::Client>, L<yarsclient>, L<Clustericious>

=head1 AUTHOR

Original author: Marty Brandon

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brian Duggan

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
