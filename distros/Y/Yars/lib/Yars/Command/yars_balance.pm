package Yars::Command::yars_balance;

use strict;
use warnings;
use 5.010;
use Yars;
use Yars::Client;
use Path::Class qw( dir file );
use Getopt::Long qw( GetOptions );
use Pod::Usage qw( pod2usage );
use Digest::file qw( digest_file_hex );
use Mojo::URL;

# PODNAME: yars_balance
# ABSTRACT: Fix all files
our $VERSION = '1.33'; # VERSION


our @end;

sub _recurse 
{
  my($root, $cb) = @_;
  foreach my $child ($root->children)
  {
    if($child->is_dir)
    {
      _recurse($child,$cb);
    }
    else
    {
      $cb->($child);
    }
  }
  
  my $count = do {
    use autodie;
    my $dh;
    opendir $dh, $root;
    my $count = scalar grep !/^\.\.?$/, readdir $dh;
    closedir $dh;
    $count;
  };
  
  if($count == 0)
  {
    rmdir $root;
  }
}

sub _rebalance_dir
{
  my($yars, $client, $disk, $server, $opt) = @_;

  my $root = dir( $disk->{root} );
  
  my $cleanup_file = $opt->{backup}
    ? sub {
        my($filename, $md5) = @_;
        my $dir = $root->subdir('balance-backup', @$md5);
        $dir->mkpath;
        my $basename = $filename->basename;
        my $to = $dir->file($basename);
        say "MVX @$md5[0] $basename";
        rename "$filename", "$to"
          or warn "unable to rename $filename => $to $!";
      }
    : sub {
      my($filename, $md5) = @_;
      say "RMX @$md5[0] @{[ $filename->basename ]}";
      unlink "$filename"
        or warn "error removing $filename";
    };
  
  my $max_load = $opt->{load};
  my $cooldown = $max_load
    ? sub {
        while(1)
        {
          my($load) = split /\s+/, file('/proc/loadavg')->slurp;
          return if $load < $max_load;
          say "PAS pausing for high load: $load > $max_load";
          sleep 60;
        }
      }
    : sub {
        # do nothing
      };
  
  if($opt->{delay})
  {
    my $original_cleanup_file = $cleanup_file;
    my @list;
    
    my $cleanup_old = sub {
      my $now = time;
      my @new;
      foreach my $item (@list)
      {
        my($filename, $md5, $time) = @$item;
        if($now > $time + 5)
        {
          $original_cleanup_file->($filename, $md5);
        }
        else
        {
          push @new, $item;
        }
      }
      @list = @new;
    };
    
    $cleanup_file = sub {
      my($filename, $md5) = @_;
      $cleanup_old->();
      push @list, [ $filename, $md5, time ];
    };
    
    push @end, sub {
      while(@list)
      {
        say '...';
        sleep 1;
        $cleanup_old->();
      }
    };
  }
  
  my $compute_md5_as_list = sub {
    my($filename) = @_;
    # compute the md5 to ensure that the file isn't corrupt
    my $md5 = digest_file_hex("$filename", "MD5");
    my @md5 = ($md5 =~ /(..)/g);
            
    # verify that the file itself is in the right place
    my $expected_file = $root->subdir(@md5, $filename->basename);
    if("$expected_file" ne "$filename")
    {
      warn "file: $filename (md5 $md5) is stored at $filename instead of $expected_file.  May be corrupt.";
      return;
    }
    ($md5, @md5);
  };
  
  foreach my $dir (sort grep { $_->basename =~ /^[a-f0-9]{1,2}$/ } $root->children)
  {
    my $expected_dir = $yars->tools->disk_for($dir->basename);
        
    # If disk_for returns a value, then it means the file belongs on the current
    # server.  If it returns undef it should be uploaded to a different server.
    # so we do either a filesystem level move, or a http remote move for each
    # file in the stashed directory.

    if(defined $expected_dir)
    {
      $expected_dir = dir( $expected_dir );
      $expected_dir->subdir('tmp')->mkpath(0,0700);
          
      # if the expected dir is where it is stored, then it is already in the right place.
      next if $expected_dir eq $dir->parent;

      _recurse $dir, sub {
        my($from) = @_;
        
        my($md5, @md5) = $compute_md5_as_list->($from);
        return unless $md5;
           
        say "LCL $md5[0] @{[ $from->basename ]}";
        $cooldown->();

        # temporary filename to copy to first
        my(undef,$tmp) = $expected_dir->subdir('tmp')->tempfile( "balanceXXXXXX", SUFFIX => '.tmp' );
        $tmp = file($tmp);
        $tmp->parent->mkpath(0,0700);
            
        # final filename to move file once the transfer to the new
        # partition is complete.
        my $to = $expected_dir->subdir(@md5, $from->basename);
            
        $from->copy_to($tmp) or do {
          warn "error copying $from => $tmp $!";
          unlink "$tmp";
          return;
        };
            
        # verify that the copied file still has the same MD5 in its
        # new location.
        my $md5_verify = digest_file_hex("$tmp", "MD5");
        if($md5 ne $md5_verify)
        {
          warn "file: $tmp does not match original md5.  May be corrupt.";
          return;
        }
            
        $to->parent->mkpath(0,0700);
        $tmp->move_to($to) or do {
          warn "error moving $tmp => $to $!";
          return;
        };
        
        $cleanup_file->($from, \@md5);
      };
    }
    else
    {
      _recurse $dir, sub {
        my($file) = @_;

        my($md5,@md5) = $compute_md5_as_list->($file);
        return unless $md5;

        say "RMT $md5[0] @{[ $file->basename ]}";
        $cooldown->();

        $client->upload('--nostash' => 1, "$file") or do {
          warn "unable to upload $file @{[ $client->errorstring ]}";
          return;
        };
          
        # we did a bucket map check above, but doublecheck the header returned
        # to us for the server doesn't match the old server location.  If
        # there is a server restart between the original check and here it
        # could otherwise cause problems.
        my $new_location = Mojo::URL->new($client->res->headers->location);
        my $old_location = Mojo::URL->new($yars->config->url);
        $old_location->path($new_location->path);
        if("$new_location" eq "$old_location")
        {
          die "uploaded to the same server, probably configuration mismatch!";
        }
        
        $cleanup_file->($file, \@md5);
      };
    }
  }
}

sub main
{
  my $class = shift;
  local @ARGV = @_;
  my $threads = 1;
  my $backup  = 0;
  my $delay   = 0;
  my $load    = 0;
  
  GetOptions(
    'threads|t=i' => \$threads,
    'backup|b'    => \$backup,
    'delay|d'     => \$delay,
    'load|l=i'      => \$load,
    'help|h' => sub { pod2usage({ -verbose => 2 }) },
    'version' => sub {
      say 'Yars version ', ($Yars::Command::yars_fast_balance::VERSION // 'dev');
      exit 1;
    },
  ) || pod2usage(1);
  
  if($load && ! -e '/proc/loadavg')
  {
    die "--load | -l is unsupported on systems without a /proc filesystem";
  }
  
  my $yars = Yars->new;
  my $client = Yars::Client->new;
  my @work_list;

  foreach my $server ($yars->config->servers)
  {

    # doublecheck that the local bucket map and the
    # server bucketmaps match.  Otherwise we could
    # migrate a file to the same server, and then
    # delete it, thus loosing the file!  Not good.
    my $bucket_map_url = Mojo::URL->new($server->{url});
    $bucket_map_url->path('/bucket_map');
    my $tx = $client->ua->get($bucket_map_url);
    if(my $res = $tx->success)
    {
      my %server_bucket_map = %{ $res->json };
      my %my_bucket_map = %{ $yars->tools->bucket_map };
      
      foreach my $key (keys %my_bucket_map)
      {
        my $other = (delete $server_bucket_map{$key})//'';
        if($my_bucket_map{$key} ne $other)
        {
          die "client/server mismatch on bucket $key";
        }
      }
      foreach my $key (keys %server_bucket_map)
      {
        die "client/server mismatch on bucket $key";
      }
    }
    else
    {
      die "unable to get bucket map from ", $server->{url};
    }
  
    # only rebalance disks that we are responsible for...
    # even if perhaps those disks are available to us...
    next unless $yars->config->url eq $server->{url};
    foreach my $disk (@{ $server->{disks} })
    {
      push @work_list, [$yars,$client,$disk,$server, { backup => $backup, delay => $delay, load => $load } ];
    }
  }

  @end = ();

  local $SIG{'INT'} = sub {
    $_->() for @end;
    exit;
  };

  if($threads > 1)
  {
    say "running with $threads threads";
    if(eval { require Parallel::ForkManager; 1 })
    {
      my $pm = Parallel::ForkManager->new($threads);
      foreach my $work (@work_list)
      {
        $pm->start;
        _rebalance_dir(@$work);
        $pm->finish;
      }
      $pm->wait_all_children;
      return;
    }
    else
    {
      warn "Unable to fork without Parallel::ForkManager";
    }
  }

  foreach my $work (@work_list)
  {
    _rebalance_dir(@$work);
    $_->() for @end;
    @end = ();
  }
}

1;

__END__

=pod

=head1 NAME

Yars::Command::yars_balance - code for yars_balance

=head1 DESCRIPTION

This module contains the machinery for the command line program L<yars_balance>

=head1 SEE ALSO

L<yars_disk_scan>

=cut