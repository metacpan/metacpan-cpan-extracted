#WWW/monitor.pm. Written in 2007 by Yaron Kahanoitch.  This
# source code has been placed in the public domain by the author.
# Please be kind and preserve the documentation.

package WWW::Monitor;

use 5.005;
use warnings;
use strict;
use Carp;
use WWW::Monitor::Task;
use WWW::Mechanize;
use HTML::FormatText;
use File::HomeDir;

our(@ISA, @EXPORT, @EXPORT_OK, $VERSION);

$VERSION = 0.24;

use base qw(Exporter WWW::Mechanize);


@EXPORT = qw ();
@EXPORT_OK = qw ();

our $DEFAULT_CACHE_SUBDIR=".www-monitor";

=head1 NAME

WWW::Monitor - Monitor websites for updates and changes

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

     use MIME::Lite;
     use WWW::Monitor;
     sub notify {
       my ($url,$text) =@_;
       foreach my $recipient ('user1@host','user2@host2') {
         my $mail_obj =
           MIME::Lite->new(To=>$recipient,
                           From=>'from@myHost',
                           Subject=>"Web alert web page changed",
                           Type=>'Text',
                           Data=>'For details visit '.$url."\n".$text
                           );
         $mail_obj->send;
       }
       return 1;
     }
     my $mon = WWW::Monitor->new('MAIL_CALLBACK'=>\&notify);
     $mon->watch('http:://www.kahanovitch.com/');
     $mon->run;


Or:

     use WWW::Monitor;
     my $mon=WWW::Monitor->new('MAIL_CALLBACK'=>\&notify,'CACHE'=>$cache);
     my $task = $mon->watch("$url");
     $mon->run or die "Query ended with error";
     
     sun notify {
         my ($url,$task) =@_;
         print "$url has changed\n";
         while (my ($sub_url,$ref_http_response) = each %{$task->added_parts()}) {
           print "New part added: $sub_url \n";
         }
          
         while (my ($sub_url,$ref_http_response) = each %{$task->missing_parts()}) {
           print "Part deleted: $sub_url \n";
         }
        
        foreach my $sub_url ( $task->changed_parts()) {
           print "$sub_url has changed:\n";
           my ($old,$new) = $task->get_old_new_pair($sub_url);
           my $old_content = $old->content;
           my $new_content = $new->content;
        }
     }

=head1 Description

L<WWW::Monitor> ia a Web monitoring mechanism built to detect and
notify changes in web pages.  The module is designed to compare
existing, online versions and pre-cached matched version.  A web page
may include more than one file. A page may include some frames and
visible referenced data, which all together form a sigle visible page.
For now, WWW::Monitor compares only textual information. Images, and
non-HTML data are not being compared. To store information,
WWW::Monitor caches data with the "Cache" mechanism. By default,
Cache::File is being used, but the user may choose to use any Cache
object that implements the Cache module interface.  L<WWW::Monitor> is
a subclass of L<WWW::Mechanize>, so any of L<WWW::Mechanize> or its
super classes can be used.

=head1 EXPORT

=head1 FUNCTIONS

=head2 new ( [ OPTIONS ] )

A constructor.  OPTIONS are passed in a hash like fashion, using key
and value pairs. Possible options are: URL - A target URL to monitor.
CACHE_ROOT - A root directory under which all caching is being
managed. Default = <home directory>/.www-monitor CACHE - cache
object. The object must have get() and set() methods like the Cache
interface, as well as set_validity and validity.

=cut

sub new {
  my $this = shift;
  my  $class = ref($this) || $this;
  my %args;
  unless (@_ % 2) {
    %args = @_;
  } else {
    carp( "Parameters for WWW::Monitor should be given as pair of 'OPTION'=>'VAL'");
  }
  my $cache_root = delete $args{CACHE_ROOT};
  unless ($cache_root) {
    my $def_dir =  File::HomeDir->my_home."/".$DEFAULT_CACHE_SUBDIR;
    if (!-d $def_dir && !mkdir($def_dir)) { 
      carp("directory $def_dir does not exists and cannot be created.$!");
      return 0;
    }
    $cache_root = $def_dir;
  }
  my $cache = delete $args{CACHE};
  if ($cache) {
    unless ((ref($cache) ne "HASH") &&
	    $cache->can("get") &&
	    $cache->can("set") &&
	    $cache->can("set_validity") &&
	    $cache->can("get_validity") &&
	    $cache->can("exists")) {
      carp "The given CACHE object must implements Cache interface and must be initialized";
      $cache = "";
    }
  } else {
    require Cache::File;
    $cache  = Cache::File->new( cache_root =>  $cache_root);
  }
  my $mailcallback =  delete $args{MAIL_CALLBACK};
  my $self=$class->SUPER::new(%args);
  $self->{tasks} = [];
  $self->{cache_root} = $cache_root;
  $cache = ($cache)?$cache:Cache::File->new( cache_root =>  $self->{cache_root});
  $self->{cache} = $cache;
  $self->{errors_hash} = {};
  $self->{mailcallback} = $mailcallback if ($mailcallback);
  return $self;
}

=head2 watch  ( URL(S) )

Add URL to be watched.
watch returns a reference to a L<WWW::Monitor::Task> object.
for example $obj->watch('http://www.cnn.com' )

=cut

sub watch {
  my $self = shift;
  my $target = shift;
  my $task = WWW::Monitor::Task->new('URL',$target);
  push @{$self->{tasks}},$task;
  return $task;
}


=head2 notify_callback ( sub )

A code reference to be executed whenever a change is detected
(commonly used for sending mail).  The following parameters will be
passed to the code reference:
$url  -> a string that holds the url for which a change was detected.
$text -> A Message to be sent.
$task -> WWW::Monitor::Task object reference.
The given code reference should return true for success.

=cut

sub notify_callback {
  my $self = shift;
  $self->{mailcallback} = shift;
  return 1;
}

=head2 run

Watch all given web pages and report changes if detected. If a url is
first visited (i.e. the url is not in the cache db) than the url will
be cached and no report will be created.


=cut

sub run {
  my $self = shift;
  my $carrier = $self;
  my $cache  = $self->{cache};
  my $ret = 1;
  $self->{errors_hash} = {};
  foreach my $task (@{$self->{tasks}}) {
    $task->run($self,$carrier,$cache) or $ret = 0;
  }
  return $ret;
}

=head2 errors_table

Return a hash reference of errors updated to last execution (i.e. when
the run method was last executed).  The returned keys are the urls where
the values are error descriptions.

=cut

sub errors_table {
  my $self = shift;
  my $ret_hash = {};
  foreach my $task (@{$self->{tasks}}) {
    $ret_hash->{$task->{url}} = $task->{error} unless $task->success();
  }
  while (my($url,$error) = each %{$self->{errors_hash}}) {
    $ret_hash->{$url} = $error;
  }
  return $ret_hash;
}

=head2 errors

return a string that contains all errors. In array context return a list of errors.

=cut

sub errors {
  my $self=shift;
  my $all_errors_hash = $self->errors_table;
  my @list_of_errors;
  while (my($url,$error) = each %$all_errors_hash) {
    push @list_of_errors,$url.":".$error;
  }
  return @list_of_errors if (wantarray);
  return join("\n",@list_of_errors);
}

=head2 notify

(Private Method)
Activate notification callback

=cut

sub notify {
  my $self = shift;
  my ($url,$task) = @_;
  if (exists $self->{mailcallback} and $self->{mailcallback}) {
    return &{$self->{mailcallback}}($url,$task);
  }
  return 1;
}

=head2 targets

Return a list of strings out of watched targets.

=cut

sub targets {
  my $self = shift;
  my @res = ();
  foreach my $task (@{$self->{tasks}}) {
    push @res,$task->{url};
  }
  return @res;
}



=head1 AUTHOR

Yaron Kahanovitch, C<< <yaron-helpme at kahanovitch.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-monitor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Monitor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command. perldoc WWW::Monitor

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Monitor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Monitor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Monitor>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Monitor>

=back

=head1 ACKNOWLEDGMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Yaron Kahanovitch, all rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;				# End of WWW::Monitor
