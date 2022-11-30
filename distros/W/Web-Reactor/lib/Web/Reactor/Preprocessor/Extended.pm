##############################################################################
##
##  Web::Reactor application machinery
##  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade"
##        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
##  http://cade.noxrun.com
##  
##  LICENSE: GPLv2
##  https://github.com/cade-vs/perl-web-reactor
##
##############################################################################
package Web::Reactor::Preprocessor::Extended;
use strict;
use Exception::Sink;
use Data::Dumper;
use Data::Tools;
use Web::Reactor::Preprocessor;

use parent 'Web::Reactor::Preprocessor';

sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;

  my $self = $class->SUPER::new( @_ );

  $self->{ 'FILE_CACHE' } = {};
  $self->{ 'DIR_CACHE'  } = {};

  my $cfg = $self->get_cfg();

  # FIXME: common directories setup code?
  if( ! $cfg->{ 'HTML_DIRS' } or @{ $cfg->{ 'HTML_DIRS' } } < 1 )
    {
    my $root = $cfg->{ 'APP_ROOT' };
    my $lang = $cfg->{ 'LANG' };
    if( $lang )
      {
      $cfg->{ 'HTML_DIRS' } = [ "$root/html/$lang", "$root/html/default" ];
      }
    else
      {
      $cfg->{ 'HTML_DIRS' } = [ "$root/html/default" ];
      }
    }

  my $html_dirs = $cfg->{ 'HTML_DIRS' } || [];
  @$html_dirs = grep { -d } @$html_dirs;

  return $self;
}

##############################################################################
##
##
##

sub load_page
{
  my $self = shift;

  my $pn = lc shift || 'main'; # page name

  return $self->load_file( $pn, 'index' );
}

sub load_file
{
  my $self = shift;

  my $pn = lc shift || 'main'; # page name
  my $fn = lc shift; # file name

  # sanitize page name
  $pn =~ s/^\/+//o;
  $pn =~ s/\/+$//o;
  $pn =~ s/\/+/\//go;

  boom "invalid page name, expected ALPHANUMERIC, got [$pn]" unless $pn =~ /^[a-z_\-0-9\/]+$/;
  boom "invalid file name, expected ALPHANUMERIC, got [$fn]" unless $fn =~ /^[a-z_\-0-9]+$/;

  my $cfg = $self->get_cfg();

  my $lang = $cfg->{ 'LANG' };

  if( exists $self->{ 'FILE_CACHE' }{ $lang }{ $pn }{ $fn } )
    {
    # FIXME: log: debug: file cache hit
    return $self->{ 'FILE_CACHE' }{ $lang }{ $pn }{ $fn };
    }

  my $dirs = [];

  if( exists $self->{ 'DIRS_CACHE' }{ $lang }{ $pn } )
    {
    # FIXME: log: debug: file cache hit
    $dirs = $self->{ 'DIRS_CACHE' }{ $lang }{ $pn };
    }
  else
    {
    my $orgs = $cfg->{ 'HTML_DIRS' };

    my @pn = grep { $_ } split /\/+/, $pn;

    for( @$orgs )
      {
      my $org = $_;
      #push @$dirs, $org;
      for my $pni ( @pn )
        {
        $org .= "/$pni";
        push @$dirs, $org;
        }
      }

    push @$dirs, @$orgs;
    @$dirs = grep { -d } @$dirs;
    # print STDERR Dumper( 'PREPROCESSOR EXTENDED LOAD FILE DIRS:', $orgs, $pn, \@pn, $dirs );

    $self->{ 'DIRS_CACHE' }{ $lang }{ $pn } = $dirs;
    }

  my $reo = $self->get_reo();

  my $fname;
  for my $dir ( @$dirs )
    {
    next unless -e "$dir/$fn.html";
    $fname = "$dir/$fn.html";
    last;
    }

  if( ! $fname )
    {
    if( $fn eq 'index' )
      {
      $reo->log( "error: cannot load file [$fn] for page [$pn] from [@$dirs]" );
      }
    else
      {
      $reo->log( "warning: cannot load file [$fn] for page [$pn] from [@$dirs]" ) if $reo->is_debug();
      }
    return undef;
    }

  my $fdata = file_text_load( $fname );

  $reo->log_debug( "debug: preprocessor load page [$pn] file [$fn] OK [$fname]" );
  $self->{ 'FILE_CACHE' }{ $lang }{ $pn }{ $fn } = $fdata;

  return $fdata;
}

sub process
{
  my $self = shift;

  my $pn   = lc shift; # page name
  my $text = shift;
  my $opt  = shift || {};
  my $ctx  = shift || {};

#print STDERR "DEBUG: PROCESS PAGE----------------------- [$pn]\n";

  boom "too many nesting levels at page [$pn], probable bug in actions or page files" if (caller(128))[0] ne ''; # FIXME: config option for max level

  $ctx = { %$ctx };
  $ctx->{ 'LEVEL' }++;

#print STDERR Dumper( 'PROCESS PRE --- ' x 7, $pn, $text );

  # FIXME: cache here? moje bi ne, zaradi modulite
  $text =~ s/<([\$\&\#]|\$\$)([a-zA-Z_\-0-9]+)(\s*[^>]*)?>/$self->__process_tag( $pn, $1, $2, $3, $opt, $ctx )/ge;
  $text =~ s/reactor_((new|back|here|none)_)?(href|src)=(["'])?([a-z_0-9]+\.([a-z]+)|\.\/?)?\?([^\n\r\s>"']*)(\4)?/$self->__process_href( $2, $3, $5, $7 )/gie;

#print STDERR Dumper( 'PROCESS POST --- ' x 7, $pn, $text );

  return $text;
}

sub __process_tag
{
  my $self = shift;

  my $pn   = lc shift; # page name
  my $type =    shift; # types are: $ variable, & callback, # template file include
  my $tag  =    shift;
  my $args =    shift; # the rest of the tag
  my $opt  =    shift;
  my $ctx  =    shift;

#print STDERR "DEBUG: PROCESS PAGE TAG ----------------------- [$pn] [$type] [$tag]\n";

#print STDERR Dumper( 'PROCESS ARGS --- ' x 7, ( $pn, $type, $tag, $args, $opt, $ctx ) );

  $ctx = { %$opt };
  $ctx->{ 'PATH' } .= ", $type$tag";
  my $path = $ctx->{ 'PATH' };

  die "preprocess loop detected, tag [$type$tag] path [$path]" if $ctx->{ 'SEEN:' . $type . $tag }++;
  die "empty or invalid tag" unless $tag =~ /^[a-zA-Z_\-0-9]+$/;

  my $reo = $self->get_reo();

  $tag = lc $tag;

  my $text;

  if( $type eq '$$' )
    {
    $opt->{ 'SECOND_PASS_REQUIRED' }++;
    return "<\$$tag>"; # shortcut to deferred eval
    }
  elsif( $type eq '$' )
    {
    # FIXME: get content from reactor?
    $text = undef unless exists $reo->{ 'HTML_CONTENT' }{ $tag };
    $text = $reo->{ 'HTML_CONTENT' }{ $tag };
    }
  elsif( $type eq '#' )
    {
    $text = $self->load_file( $pn, $tag );
    }
  elsif( $type eq '&' )
    {
    # FIXME: make args to a function?
    my %args;
    while( $args =~ /\s*([a-zA-Z_0-9]+)(=('([^']*)'|"([^"]*)"|(\S*)))?/g ) # "' # fix string colorization
      {
      my $k = uc $1;
      my $v = $4 || $5 || $6 || 1;
      $args{ $k } = $v;
      }
    # FIXME: action calls may return non-text data, however the preprocessor expects text data for now...
    $text = $reo->act->call( $tag, HTML_ARGS => \%args );
    }
  else
    {
    re_log( "debug: invalid tag: [$type$tag]" );
    }

# print STDERR Dumper( 'PROCESS TEXT --- ' x 7, ( $pn, $text, $opt, $ctx ) );
  $text = $self->process( $pn, $text, $opt, $ctx );

  return $text;
}

sub __process_href
{
  my $self   = shift;

  my $type   = lc shift || 'here';
  my $attr   = shift; # href or src
  my $script = shift;
  my $data   = shift;

  my $data_hr = url2hash( $data );

  my $reo = $self->get_reo();

  $type = 'new' if $attr eq 'src'; # images

  my $href = $reo->args_type( $type, %$data_hr );

  return "$attr=$script?_=$href";
}

##############################################################################
1;
###EOF########################################################################
