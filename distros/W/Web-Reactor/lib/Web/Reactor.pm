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
package Web::Reactor;
use strict;
use Storable qw( dclone freeze thaw ); # FIXME: move to Data::Tools (data_freeze/data_thaw)
use Plack::Request;
use Cookie::Baker;
use MIME::Base64;
use Data::Tools 1.24;
use Exception::Sink;
use Data::Dumper;
use Encode;

use Web::Reactor::Utils;
use Web::Reactor::HTML::Form;

our $VERSION = '2.11';

##############################################################################

#minimum config:
#my %cfg = (
#          '' => ,
#          );

our @HTTP_VARS_CHECK = qw(
                           REMOTE_ADDR
                           HTTP_USER_AGENT
                         );

our @HTTP_VARS_SAVE  = qw(
                           REMOTE_ADDR
                           REMOTE_PORT
                           REQUEST_METHOD
                           REQUEST_URI
                           HTTP_REFERRER
                           QUERY_STRING
                           HTTP_COOKIE
                           HTTP_USER_AGENT
                         );

our %ENV_ALLOWED_KEYS = {

                        };

##############################################################################

sub new
{
  my $class = shift;
  my $env   = shift;
  my $cfg   = shift;

  $class = ref( $class ) || $class;
  my $self = {};
  bless $self, $class;

  $self->{ 'CFG' }                    = $cfg;
  $self->{ 'CFG' }{ 'APP_CHARSET' } ||= 'UTF-8';
  $self->{ 'IN'  }{ 'ENV'         }   = $env; # including headers

  $self->log_dumper( "debug: reactor[$self] setup (ENV & CFG): ", $env, $cfg );
  
  $self->{ 'PLACK' } = Plack::Request->new( $env );

  # FIXME: verify %env content! Data::Validate::Struct
  boom "fatal: configuration: request scheme [HTTP] does not match cookies security policy! either enable HTTPS scheme or set DISABLE_SECURE_COOKIES=1"
      if $self->get_request_scheme() eq 'http' and ! $cfg->{ 'DISABLE_SECURE_COOKIES' };
  
  data_tools_set_text_io_encoding( $self->{ 'CFG' }{ 'APP_CHARSET' } );

  # FIXME: common directories setup code?
  if( ! $cfg->{ 'LIB_DIRS' } or @{ $cfg->{ 'LIB_DIRS' } } < 1 )
    {
    my $root = $cfg->{ 'APP_ROOT' };
    $cfg->{ 'LIB_DIRS' } = [ "$root/lib" ];
    }

  for my $lib_dir ( @{ $cfg->{ 'LIB_DIRS' } || [] } )
    {
    next unless -d $lib_dir;
    push @INC, $lib_dir;
    }

  @INC = grep { $_ ne '.' } @INC;

  my $reo_ses_class = $cfg->{ 'REO_SES_CLASS' } ||= 'Web::Reactor::Sessions::Filesystem';
  my $reo_pre_class = $cfg->{ 'REO_PRE_CLASS' } ||= 'Web::Reactor::Preprocessor::Native';
  my $reo_act_class = $cfg->{ 'REO_ACT_CLASS' } ||= 'Web::Reactor::Actions::Native';

  my $reo_ses_class_file = perl_package_to_file( $reo_ses_class );
  my $reo_pre_class_file = perl_package_to_file( $reo_pre_class );
  my $reo_act_class_file = perl_package_to_file( $reo_act_class );

  require $reo_ses_class_file;
  require $reo_pre_class_file;
  require $reo_act_class_file;

  $self->{ 'REO_SES' } = new $reo_ses_class $self, $cfg;
  $self->{ 'REO_PRE' } = new $reo_pre_class $self, $cfg;
  $self->{ 'REO_ACT' } = new $reo_act_class $self, $cfg;

  return $self;
}

sub DESTROY
{
  my $self = shift;

  $self->log_debug( "debug: DESTROY: Reactor[$self] destroyed" );
}

##############################################################################

sub run
{
  my $self = shift;

  my $res;
  eval
    {
    $self->prepare_and_execute();
    };
  if( surface( 'RENDER' ) )
    {
    my $status  = $self->res_get_status() || 200;
    my $headers = $self->res_get_headers_ar();
    my $body    = $self->res_get_body();
    $body = [ $body ] unless ref $body;
    $res = [ $status, $headers, $body ];
    }
  elsif( surface( '*' ) )
    {
    $self->log( "error: prepare or execute code failed: $@" );
    $res = [ 200, [ 'content-type' => 'text/plain' ], [ 'system is currently unavailable (*)' ] ];
    }
  else
    {
    $self->log( "error: unknown or empty result or exception" );
    $res = [ 200, [ 'content-type' => 'text/plain' ], [ 'system is currently unavailable' ] ];
    }  

  $self->save();

  if( $self->is_debug() )
    {
    my $psid = $self->get_page_session_id( 0 ) || 'empty';
    my $rsid = $self->get_page_session_id( 1 ) || 'empty';
    my $usid = $self->get_user_session_id() || 'empty';
    $self->log_dumper( "USER INPUT -----------------------------------", $self->get_user_input() );
    $self->log_dumper( "SAFE INPUT -----------------------------------", $self->get_safe_input() );
    $self->log_dumper( "FINAL PAGE SESSION [$psid]-----------------------------------", $self->get_page_session() );
    $self->log_dumper( "FINAL REF  SESSION [$rsid]-----------------------------------", $self->get_page_session( 1 ) );
    $self->log_dumper( "FINAL USER SESSION [$usid]-----------------------------------", $self->get_user_session() );
    }

  # $self->log_dumper( 'RUN RESULT:', $res );
  return $res;
}

sub prepare_and_execute
{
  my $self = shift;

  my $cfg = $self->get_cfg();

  # 0. load/setup env/config defaults
  my $app_name = $cfg->{ 'APP_NAME' } or boom( "missing APP_NAME" );

  # 1. loading cookie
  my $cookie_name = lc( $cfg->{ 'COOKIE_NAME' } || "$app_name\_cookie" );
  my $user_sid = $self->get_cookie( $cookie_name );
  $self->log_debug( "debug: incoming USER_SID cookie name [$cookie_name] value [$user_sid]" );

  # 2. loading user session, setup new session and cookie if needed
  my $user_shr = {}; # user session hash ref
  if( ! ( $user_sid =~ /^[a-zA-Z0-9]+$/ and $user_shr = $self->ses->load( 'USER', $user_sid ) ) )
    {
    $self->log( "warning: invalid user session [$user_sid]" );
    ( $user_sid, $user_shr ) = $self->__create_new_user_session();
    }
  $self->{ 'SESSIONS' }{ 'SID'  }{ 'USER' } = $user_sid;
  $self->{ 'SESSIONS' }{ 'DATA' }{ 'USER' }{ $user_sid } = $user_shr;

  if( ( $user_shr->{ ':LOGGED_IN' } and $user_shr->{ ':XTIME' } > 0 and time() > $user_shr->{ ':XTIME' } )
      or
      ( $user_shr->{ ':CLOSED' } ) )
    {
    $self->log( "status: user session expired or closed, sid [$user_sid]" );
    # not logged-in sessions dont expire
    $user_shr->{ ':XTIME_STR'    } = scalar localtime() if time() > $user_shr->{ ':XTIME' };
    $user_shr->{ ':CLOSED'       } = 1;
    $user_shr->{ ':ETIME'        } = time();
    $user_shr->{ ':ETIME_STR'    } = scalar localtime();

    ( $user_sid, $user_shr ) = $self->__create_new_user_session();

    $self->render( PAGE => 'eexpired' );
    }

  for my $k ( keys %{ $user_shr->{ ":HTTP_CHECK_HR" } } )
    {
    # check if session parameters are changed, stealing session?
    next if $user_shr->{ ":HTTP_CHECK_HR" }{ $k } eq $self->{ 'IN' }{ 'ENV' }{ $k };

    $self->log( "status: user session parameter [$k] check failed, sid [$user_sid]" );
    # FIXME: move to function: close_session();
    $user_shr->{ ':CLOSED'       } = 1;
    $user_shr->{ ':ETIME'        } = time();
    $user_shr->{ ':ETIME_STR'    } = scalar localtime();

    ( $user_sid, $user_shr ) = $self->__create_new_user_session();

    $self->render( PAGE => 'einvalid' );
    last;
    }

  # read and save http environment data into user session, used for checks and info
  $user_shr->{ ":HTTP_ENV_HR"   } = { map { $_ => $self->{ 'IN' }{ 'ENV' }{ $_ } } @HTTP_VARS_SAVE  };

  # FIXME: move to single place
  my $user_session_expire = $cfg->{ 'USER_SESSION_EXPIRE' } || 600; # 10 minutes
  $self->set_user_session_expire_time_in( $user_session_expire );

  $self->save();

  # 3. get input data, CGI::params, postdata
  my $input_user_hr = $self->{ 'INPUT_USER_HR' } = {};
  my $input_safe_hr = $self->{ 'INPUT_SAFE_HR' } = {};

  # FIXME: TODO: handle and URL params here. only for EX?
  my $iconv;
  my $app_charset = uc $cfg->{ 'APP_CHARSET' } || 'UTF-8';
  my $incoming_charset = $app_charset;

  if( uc( $self->get_http_env->{ 'HTTP_X_REQUESTED_WITH' } ) eq 'XMLHTTPREQUEST' )
    {
    # TODO: it can be different, but nobody seems to use it, should be fixed eventually
    $incoming_charset = 'UTF-8';
    }

  my $plack = $self->{ 'PLACK' };

  # input parameters, GET + POST
  my $params = $plack->parameters();
  hash_uc_ipl( $params );
  my @params = keys %$params;

  # import plain parameters from GET/POST request
  for my $n ( @params )
    {
    if( $n !~ /^[A-Za-z0-9\-\_\.\:]+$/o )
      {
      $self->log( "error: invalid CGI/input parameter name: [$n]" );
      next;
      }

    my $v = decode( $incoming_charset, $params->{ $n } );

    if( $self->__input_cgi_skip_invalid_value( $n, $v ) )
      {
      $self->log( "error: invalid CGI/input value for parameter: [$n]" );
      next;
      }
    $self->log_debug( "debug: CGI input param [$n] value [$v]" );

    $v = $self->__input_cgi_make_safe_value( $n, $v );
    if ( $n =~ /BUTTON:([a-z0-9_\-]+)(:(.+?))?(\.[XY])?$/oi )
      {
      # regular button BUTTON:CANCEL
      # button with id BUTTON:REDIRECT:USERID
      $input_user_hr->{ 'BUTTON'    } = uc $1;
      $input_user_hr->{ 'BUTTON_ID' } =    $3;
      }
    elsif( $n eq '_BUTTON_NAME' )
      {
      my ( undef, $b, $i ) = split /:/, $v, 3;
      $input_user_hr->{ 'BUTTON'    } = uc $b;
      $input_user_hr->{ 'BUTTON_ID' } =    $i;
      }
    else
      {
      $input_user_hr->{ $n } = $v;
      }
    }

  # import uploads
  my $uploads = $plack->uploads();
  for my $n ( keys %$uploads )
    {
    my @u = $uploads->get_all( $n );
    $input_user_hr->{ "$n" } = @u; # count of the uploaded files
    if( @u > 0 )
      {
      $input_user_hr->{ "$n:UPLOADS" } = \@u;   # holds all uploads, even if there is just 1
      $input_user_hr->{ "$n:UPLOAD"  } = $u[0]; # holds first or single upload
      next;
      }
    }  

  my $safe_input_link_sess = $input_user_hr->{ '_' };
  
  # parse link session: link-sid.link-key
  if( $safe_input_link_sess =~ /^([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$/ )
    {
    my ( $link_sid, $link_key ) = ( $1, $2 );

    my $link_session_hr = $self->ses->load( 'LINK', $link_sid );

    my $link_data = $link_session_hr->{ $link_key };

    # merge safe input if valid
    %$input_safe_hr = ( %$input_safe_hr, %$link_data ) if $link_data;
    }
  elsif( $safe_input_link_sess ne '' )
    {
    $self->log( "warning: invalid safe input link session.key [$safe_input_link_sess]" );
    }

  # 4. loading page session
  my $page_sid = $input_safe_hr->{ '_P' };
  my $page_shr = {}; # user session hash ref
  if( ! ( $page_sid =~ /^[a-zA-Z0-9]+$/ and $page_shr = $self->ses->load( 'PAGE', $page_sid ) ) )
    {
    $self->log( "warning: invalid page session [$page_sid]" );
    $page_sid = $self->ses->create( 'PAGE', 8 );
    $self->log( "warning: new page session created [$page_sid]" );
    $page_shr = { ':ID' => $page_sid };
    }
  $self->{ 'SESSIONS' }{ 'SID'  }{ 'PAGE' } = $page_sid;
  $self->{ 'SESSIONS' }{ 'DATA' }{ 'PAGE' }{ $page_sid } = $page_shr;


  my $ref_page_sid = $input_safe_hr->{ '_R' };
  if( $ref_page_sid =~ /^[a-zA-Z0-9]+$/ )
    {
    $page_shr->{ ':REF_PAGE_SID' } = $ref_page_sid;
    }

  # 5. remap form input data, post to safe input
  my $form_name = $input_safe_hr->{ 'FORM_NAME' }; # FIXME: replace with _FO
  if( $form_name and exists $page_shr->{ ':FORM_DEF' }{ $form_name } )
    {
    my $rm = $page_shr->{ ':FORM_DEF' }{ $form_name }{ 'RET_MAP' };

    for my $k ( keys %$rm )
      {
      next unless exists $input_user_hr->{ $k };
      $input_safe_hr->{ $k } = $rm->{ $k }{ $input_user_hr->{ $k } };
      delete $input_user_hr->{ $k };
      }
    }

  my $frame_name = $input_safe_hr->{ '_FR' };
  if( $frame_name ne '' )
    {
    if( $frame_name =~ /^[a-zA-Z_0-9]+$/ )
      {
      $page_shr->{ ':FRAME_NAME' } = $frame_name;
      }
    else
      {
      $self->log( "error: invalid frame name [$frame_name]" );
      }
    }

  # 6. get action from input (USER/CGI) or page session
  my $action_name = lc( $input_safe_hr->{ '_AN' } || $input_user_hr->{ '_AN' } || $page_shr->{ ':ACTION_NAME' } );
  if( $action_name =~ /^[a-z_0-9]+$/ )
    {
    $page_shr->{ ':ACTION_NAME' } = $action_name;
    }
  else
    {
    # $self->log( "error: invalid action name [$action_name]" );
    }

  # 7. get page from input (USER/CGI) or page session
  my $page_name = lc( $input_safe_hr->{ '_PN' } || $input_user_hr->{ '_PN' } || $page_shr->{ ':PAGE_NAME' } || 'main' );
  if( $page_name ne '' )
    {
    if( $page_name =~ /^[a-z_0-9]+$/ )
      {
      $page_shr->{ ':PAGE_NAME' } = $page_name;
      }
    else
      {
      $self->log( "error: invalid page name [$page_name]" );
      }
    }

  # pre-8. print debug status...
  if( $self->is_debug() )
    {
    my $psid = $self->get_page_session_id( 0 ) || 'empty';
    my $rsid = $self->get_page_session_id( 1 ) || 'empty';
    $self->log_dumper( "USER INPUT-------------------------------------", $self->get_user_input()   );
    $self->log_dumper( "SAFE INPUT-------------------------------------", $self->get_safe_input()   );
    $self->log_dumper( "PAGE SESSION [$psid]-----------------------------------", $self->get_page_session() );
    $self->log_dumper( "REF  SESSION [$rsid]-----------------------------------", $self->get_page_session( 1 ) );
    # $self->log_dumper( "USER SESSION-----------------------------------", $self->get_user_session() );
    }

  # 8. render output action/page
  if( $action_name )
    {
    $self->render( ACTION => $action_name );
    }
  else
    {
    $self->render( PAGE => $page_name );
    }
}

sub __create_new_user_session
{
  my $self = shift;

  my $user_sid;
  my $user_shr;

  my $cfg = $self->get_cfg();

  # FIXME: move to function
  my $app_name = $cfg->{ 'APP_NAME' } or boom( "missing APP_NAME" );
  my $cookie_name = lc( $cfg->{ 'COOKIE_NAME' } || "$app_name\_cookie" );

  $user_sid = $self->ses->create( 'USER' );
  $user_shr = { ':ID' => $user_sid };
  $self->{ 'SESSIONS' }{ 'SID'  }{ 'USER' } = $user_sid;
  $self->{ 'SESSIONS' }{ 'DATA' }{ 'USER' }{ $user_sid } = $user_shr;

  my $path = $cfg->{ 'COOKIE_PATH' };
  if( ! $path )
    {
    $path = $self->get_request_uri();
    $path =~ s/^([^\?]*\/)([^\?\/]*)(\?.*)?$/$1/; # remove args: ?...
    }
  $path ||= '/';  

  my $secure_cookie = $cfg->{ 'DISABLE_SECURE_COOKIES' } ? 0 : 1;
  $self->res_set_cookie( $cookie_name, value => $user_sid, path => $path, httponly => 1, secure => $secure_cookie, samesite => 'strict' );
  $self->log( "debug: creating new user session [$user_sid]" );

  my $user_session_expire = $cfg->{ 'USER_SESSION_EXPIRE' } || 600; # 10 minutes

  $user_shr->{ ':CTIME'      } = time();
  $user_shr->{ ':CTIME_STR'  } = scalar localtime();

  $self->set_user_session_expire_time_in( $user_session_expire );

  $user_shr->{ ":HTTP_CHECK_HR" } = { map { $_ => $self->{ 'IN' }{ 'ENV' }{ $_ } } @HTTP_VARS_CHECK };
  $user_shr->{ ":HTTP_ENV_HR"   } = { map { $_ => $self->{ 'IN' }{ 'ENV' }{ $_ } } @HTTP_VARS_SAVE  };

  return ( $user_sid, $user_shr );
}


sub get_postdata_fh
{
  my $self = shift;
  
  return $self->{ 'PLACK' }->body();
}

sub get_postdata_body
{
  my $self = shift;
  
  my $fh = $self->get_postdata_fh();
  
  local $/ = undef;
  return <$fh>;
}

sub get_cfg
{
  my $self = shift;
  
  return $self->{ 'CFG' };
}

##############################################################################
#
# usual user visible api
#

sub get_user_session
{
  my $self = shift;

  my $user_sid = $self->{ 'SESSIONS' }{ 'SID'  }{ 'USER' };
  my $user_shr = $self->{ 'SESSIONS' }{ 'DATA' }{ 'USER' }{ $user_sid };

  return $user_shr;
}

sub get_user_session_id
{
  my $self = shift;

  my $user_sid = $self->{ 'SESSIONS' }{ 'SID'  }{ 'USER' };

  return $user_sid;
}

sub get_page_session
{
  my $self  = shift;
  my $level = shift;

  my $page_sid = $self->{ 'SESSIONS' }{ 'SID'  }{ 'PAGE' };
  my $page_shr = $self->{ 'SESSIONS' }{ 'DATA' }{ 'PAGE' }{ $page_sid };

  while( $level-- )
    {
    $page_sid = $page_shr->{ ':REF_PAGE_SID' };
    return undef unless $page_sid;
    $page_shr = $self->{ 'SESSIONS' }{ 'DATA' }{ 'PAGE' }{ $page_sid };
    if( ! $page_shr )
      {
      $page_shr = $self->ses->load( 'PAGE', $page_sid );
      $self->{ 'SESSIONS' }{ 'DATA' }{ 'PAGE' }{ $page_sid } = $page_shr;
      }
    }

  return $page_shr;
}

sub get_http_env
{
  my $self  = shift;

  # FIXME: TODO: remove or replace with http env from $reo?

  my $user_shr = $self->get_user_session();

  boom "missing HTTP_ENV inside user session" unless exists $user_shr->{ ':HTTP_ENV_HR' };

  return $user_shr->{ ':HTTP_ENV_HR' };
}

sub get_page_session_id
{
  my $self  = shift;
  my $level = shift;

  my $shr = $self->get_page_session( $level ) || {};

  return $shr->{ ':ID' };
}

sub get_ref_page_session_id
{
  my $self  = shift;
  my $level = shift;

  my $shr = $self->get_page_session( $level ) || {};

  return $shr->{ ':REF_PAGE_SID' };
}

sub get_safe_input
{
  my $self  = shift;

  my $input_safe_hr = $self->{ 'INPUT_SAFE_HR' };
  return $input_safe_hr;
}

sub get_user_input
{
  my $self  = shift;

  my $input_user_hr  = $self->{ 'INPUT_USER_HR'  };
  return $input_user_hr;
}

sub get_input_button
{
  my $self  = shift;

  my $input_user_hr = $self->get_user_input();
  my $input_safe_hr = $self->get_safe_input();
  return $input_safe_hr->{ 'BUTTON' } || $input_user_hr->{ 'BUTTON' };
}

sub get_input_button_id
{
  my $self  = shift;

  my $input_user_hr = $self->get_user_input();
  my $input_safe_hr = $self->get_safe_input();
  return $input_safe_hr->{ 'BUTTON_ID' } || $input_user_hr->{ 'BUTTON_ID' };
}

sub get_input_button_and_remove
{
  my $self  = shift;

  my $input_user_hr = $self->get_user_input();
  my $input_safe_hr = $self->get_safe_input();
  my $button = $input_safe_hr->{ 'BUTTON' } || $input_user_hr->{ 'BUTTON' };
  delete $input_user_hr->{ 'BUTTON' };
  delete $input_safe_hr->{ 'BUTTON' };
  return $button;
}

sub get_input_form_name
{
  my $self  = shift;

  my $input_safe_hr = $self->get_safe_input();
  my $form_name = $input_safe_hr->{ 'FORM_NAME' }; # FIXME: replace with _FN

  return $form_name;
}

sub get_page_frame
{
  my $self  = shift;

  my $page_shr  = $self->get_page_session();

  return exists $page_shr->{ ':FRAME_NAME' } ? $page_shr->{ ':FRAME_NAME' } : undef;
}

sub get_lang
{
  my $self  = shift;

  return $self->get_cfg->{ 'LANG' };
}

sub get_app_name
{
  my $self  = shift;

  return $self->get_cfg->{ 'APP_NAME' };
}

sub get_app_root
{
  my $self  = shift;

  return $self->get_cfg->{ 'APP_ROOT' };
}

sub args
{
  my $self = shift;
  my %args = @_;

  hash_uc_ipl( \%args );

  my $link_sid;
  my $link_shr;

  if( ! $self->{ 'SESSIONS' }{ 'SID'  }{ 'LINK' } )
    {
    $link_sid = $self->ses->create( 'LINK', 8 );
    $link_shr = { ':ID' => $link_sid };
    $self->{ 'SESSIONS' }{ 'DATA' }{ 'LINK' }{ $link_sid } = $link_shr;
    $self->{ 'SESSIONS' }{ 'SID'  }{ 'LINK' } = $link_sid;
    }
  else
    {
    $link_sid = $self->{ 'SESSIONS' }{ 'SID'  }{ 'LINK' };
    $link_shr = $self->{ 'SESSIONS' }{ 'DATA' }{ 'LINK' }{ $link_sid };
    }

  my $link_key;
  while(4)
    {
    $link_key = $self->ses->create_id( 8 ); # FIXME: length param env
    last if ! exists $link_shr->{ $link_key };
    }
  boom( "cannot create LINK key" ) unless $link_key;

  $link_shr->{ $link_key } = \%args;

  return $link_sid . '.' . $link_key;
}

sub args_back
{
  my $self = shift;
  my %args = @_;

  $args{ '_P'  } = $self->get_ref_page_session_id();
  $args{ '_PN' } = 'main' unless $args{ '_P' }; # return to 'main' if no referer given

  return $self->args( %args );
}

sub args_back_back
{
  my $self = shift;
  my %args = @_;

  $args{ '_P' } = $self->get_ref_page_session_id( 1 );
  $args{ '_PN' } = 'main' unless $args{ '_P' }; # return to 'main' if no referer given

  return $self->args( %args );
}

sub args_new
{
  my $self = shift;
  my %args = @_;

  $args{ '_R' } = $self->get_page_session_id();

  my $page_shr = $self->get_page_session();
  if( exists $page_shr->{ ':FRAME_NAME' } )
    {
    $args{ '_FR' } = $page_shr->{ ':FRAME_NAME' };
    }

  return $self->args( %args );
}

sub args_here
{
  my $self = shift;
  my %args = @_;

  $args{ '_P' } = $self->get_page_session_id();

  return $self->args( %args );
}

sub args_type
{
  my $self = shift;

  my $type = lc shift;

  return $self->args_new( @_ )  if $type eq 'new';
  return $self->args_here( @_ ) if $type eq 'here';
  return $self->args_back( @_ ) if $type eq 'back';
  return $self->args( @_ )      if $type eq 'none';
  boom( "unknown or not supported TYPE [$type]" );
}

##############################################################################

sub get_request_scheme
{
  my $self   = shift;
  
  return $self->{ 'IN' }{ 'ENV' }{ 'REQUEST_SCHEME' };
}

sub get_request_uri
{
  my $self   = shift;
  
  return $self->{ 'IN' }{ 'ENV' }{ 'REQUEST_URI' };
}

sub get_headers
{
  my $self  = shift;

  return $self->{ 'IN' }{ 'HEADERS' } ||= { map { lc( $_ ) => $self->{ 'IN' }{ 'ENV' }{ $_ } } grep /^(HTTPS?_|SSL_)/, keys %{ $self->{ 'IN' }{ 'ENV' } } };
}

sub get_header
{
  my $self = shift;
  my $name = shift;

  return $self->get_headers->{ $name };
}

sub get_cookies
{
  my $self = shift;
  return $self->{ 'IN' }{ 'COOKIES' } ||= crush_cookie( $self->get_header( 'http_cookie' ) );;
}  

sub get_cookie
{
  my $self = shift;
  my $name = shift;

  my $cookie = $self->get_cookies->{ $name };
  $self->log_debug( "get_cookie: name [$name] value [$cookie]" );
  return $cookie;
}

### RESULT/OUTPUT API ########################################################

sub res_set_status
{
  my $self   = shift;
  my $status = shift;
  
  return $self->{ 'OUT' }{ 'STATUS' } = $status;
}

sub res_get_status
{
  my $self   = shift;
  
  return $self->{ 'OUT' }{ 'STATUS' };
}

#-----------------------------------------------------------------------------

sub res_set_headers
{
  my $self = shift;
  my %h    = @_;

  hash_lc_ipl( \%h );

  if( exists $h{ 'status' } )
    {
    $self->res_set_status( $h{ 'status' } );
    delete $h{ 'status' };
    }

  return $self->{ 'OUT' }{ 'HEADERS' } = { %{ $self->{ 'OUT' }{ 'HEADERS' } || {} }, %h };
}

sub res_get_headers_ar
{
  my $self = shift;

  my $headers;

  $self->{ 'OUT' }{ 'HEADERS' }{ 'content-type' } ||= 'text/html';

  # postprocess headers, custom logic, etc.
  my %headers_out = %{ $self->{ 'OUT' }{ 'HEADERS' } };

  if( exists $headers_out{ 'content-charset' } )
    {
    if( $headers_out{ 'content-type' } !~ /;\s*charset=/i )
      {
      $headers_out{ 'content-type' } .= '; charset=' . $headers_out{ 'content-charset' };
      }
    delete $headers_out{ 'content-charset' };
    };

  if( exists $headers_out{ 'location' } )
    {
    delete $headers_out{ 'content-type' };
    }

  my @headers;
  while( my ( $k, $v ) = each %headers_out )
    {
    push @headers, $k, $v;
    }

  while( my ( $k, $v ) = each %{ $self->{ 'OUT' }{ 'COOKIES' } } )
    {
    push @headers, 'set-cookie', $v;
    }

  $self->log_dumper( 'RESULT HEADERS---------------------------------', \@headers );

  return \@headers;
}

#-----------------------------------------------------------------------------

sub res_set_cookie
{
  my $self = shift;
  my $name = shift;
  my %opt  = @_;

  $self->log( "debug: creating new cookie [$name]" );
  # FIXME: validate %opt  Data::Validate::Struct

  $self->{ 'OUT' }{ 'COOKIES' }{ $name } = bake_cookie( $name, \%opt );
}

#-----------------------------------------------------------------------------

sub res_set_body
{
  my $self = shift;
  my $body = shift;
  
  return $self->{ 'OUT' }{ 'BODY' } = $body;
}

sub res_get_body
{
  my $self = shift;
  my $body = shift;
  
  return $self->{ 'OUT' }{ 'BODY' };
}

##############################################################################

sub save
{
  my $self = shift;

  my $mod_cache = $self->{ 'CACHE' }{ 'SESSION_DATA_SHA1' } ||= {};
  for my $type ( qw( USER PAGE LINK ) )
    {
    while( my ( $sid, $shr ) = each %{ $self->{ 'SESSIONS' }{ 'DATA' }{ $type } } )
      {
      boom( "SESSION:DATA:$type:$sid is not hashref" ) unless ref( $shr ) eq 'HASH';

      my $sha1   = sha1_hex( freeze( $shr ) );
      my $cache1 = $mod_cache->{ $type }{ $sid };

      next if $sha1 eq $cache1;

      $self->log_debug( "saving session data [$type:$sid]" );

      $mod_cache->{ $type }{ $sid } = $sha1;

      $self->ses->save( $type, $sid, $shr );
      }
    }
}

##############################################################################
##
##  CRYPTO api :)
##

## FIXME: move most to Data::Tools or separate module

sub __new_crypto_object
{
  my $self = shift;

  # NOTE: RTFM says encryptor and decryptor must be different

  my $cfg = $self->get_cfg();

  # FIXME: read key from config file only!
  my $key = $cfg->{ 'ENCRYPT_KEY' };
  boom( "missing ENV:ENCRYPT_KEY" ) unless $key =~ /\S/;

  my $ci = $cfg->{ 'ENCRYPT_CIPHER' } || 'Twofish2'; # :)

  return Crypt::CBC->new( -key => $key, -cipher => $ci );
}

sub encrypt
{
  my $self = shift;
  my $data = shift;

  my $enc = $self->{ 'ENCRYPTOR' } ||= $self->__new_crypto_object();
  return $enc->encrypt( $data );
}

sub decrypt
{
  my $self = shift;
  my $data = shift;

  my $dec = $self->{ 'DECRYPTOR' } ||= $self->__new_crypto_object();
  return $dec->decrypt( $data );
}

sub encrypt_hex
{
  my $self = shift;

  return str_hex( $self->encrypt( @_ ) );
}

sub decrypt_hex
{
  my $self = shift;

  return $self->decrypt( str_unhex( @_ ) );
}

sub crypto_freeze_hex
{
  my $self = shift;
  my $data = shift; # reference to any data/scalar/hash/array

  return $self->encrypt_hex( freeze( $data ) );
}

sub crypto_thaw_hex
{
  my $self = shift;
  my $data = shift; # hex encoded data

  return thaw( $self->decrypt_hex( $data ) );
}

sub encrypt_base64u
{
  my $self = shift;

  return MIME::Base64::encode_base64url( $self->encrypt( @_ ) );
}

sub decrypt_base64u
{
  my $self = shift;

  return $self->decrypt( MIME::Base64::decode_base64url( @_ ) );
}

sub crypto_freeze_base64u
{
  my $self = shift;
  my $data = shift; # reference to any data/scalar/hash/array

  return $self->encrypt_base64u( freeze( $data ) );
}

sub crypto_thaw_base64u
{
  my $self = shift;
  my $data = shift; # base64u encoded data

  return thaw( $self->decrypt_base64u( $data ) );
}

##############################################################################

sub set_debug
{
  my $self  = shift;
  my $level = abs(int(shift));

  return $self->get_cfg->{ 'DEBUG' } = $level;
}

sub is_debug
{
  my $self = shift;

  return $self->get_cfg->{ 'DEBUG' } || 0;
}

#-----------------------------------------------------------------------------

sub log
{
  my $self = shift;

  print STDERR @_, "\n";
}

sub log_debug
{
  my $self = shift;

  return unless $self->is_debug();
  my @args = @_;
  chomp( @args );
  my $msg = join( "\n", @args );
  $msg = "debug: $msg" unless $msg =~ /^debug:/i;
  $self->log( $msg );
}

sub log_stack
{
  my $self = shift;

  $self->log_debug( @_, "\n", Exception::Sink::get_stack_trace() );
}

sub log_dumper
{
  my $self = shift;

  return unless $self->is_debug();

  local $Data::Dumper::Sortkeys = 1;

  $self->log_debug( Dumper( @_ ) );
}

##############################################################################
##
## sanity policies
## these are internal subs but are designed to be overriden if required
##

# fix/remove invalid parts of a CGI/input value
sub __input_cgi_make_safe_value
{
  my $self = shift;
  my $n = shift; # arg name
  my $v = shift; # arg value

  $v =~ s/[\000]//go;

  return $v;
}

# must return 1 for values which must be removed from input or 0 for ok
# this is called before __input_cgi_make_safe_value, default is pass all
sub __input_cgi_skip_invalid_value
{
  my $self = shift;
  # this is placeholder really
  # my $n = shift; # arg name
  # my $v = shift; # arg value
  return 0;
}

##############################################################################

sub html_content
{
  my $self = shift;
  my %hc   = @_;

  hash_lc_ipl( \%hc );
  $self->{ 'HTML_CONTENT' } ||= {};
  %{ $self->{ 'HTML_CONTENT' } } = ( %{ $self->{ 'HTML_CONTENT' } }, %hc );

  return $self->{ 'HTML_CONTENT' };
}

sub html_content_clear
{
  my $self = shift;

  $self->{ 'HTML_CONTENT' } ||= {};
}

sub html_content_set
{
  my $self = shift;

  $self->html_content_clear();
  return $self->html_content( @_ );
}

sub html_content_accumulator
{
  my $self = shift;
  my $name = shift;
  my $text = shift;

  $self->{ 'HTML_CONTENT' } ||= {};
  $self->{ 'HTML_CONTENT' }{ $name }{ $text }++;

  $self->html_content_set( $name, join '', keys %{ $self->{ 'HTML_CONTENT' }{ $name } } );
}

sub html_content_accumulator_js
{
  my $self = shift;
  my $text = shift;

  $text = "<script type='text/javascript' src='$text'></script>";
  $self->html_content_accumulator( "ACCUMULATOR_JS", $text );
}

sub html_content_accumulator_css
{
  my $self = shift;
  my $css = shift;

  my $text = qq{ <link href="$css" rel="stylesheet" type="text/css"> };
  $self->html_content_accumulator( "ACCUMULATOR_HEAD", $text );
}

##############################################################################

sub render_data
{
  my $self = shift;

  return $self->render( DATA   => $self->portray( @_ ) );
}

sub render_action
{
  my $self   = shift;
  my $action = shift;

  return $self->render( ACTION => $action, @_ );
}

sub render_page
{
  my $self = shift;
  my $page = shift;

  return $self->render( PAGE   => $page, @_ );
}

sub render
{
  my $self = shift;
  my %opt  = @_;

  boom "too many nesting levels in rendering, probable bug in actions or pages" if (caller(128))[0] ne ''; # FIXME: config option for max level

  my $action = $opt{ 'ACTION' };
  my $page   = $opt{ 'PAGE'   };
  my $data   = $opt{ 'DATA'   };

  # FIXME: content vars handling set_content()/etc.
  my $ah = $self->args_here();
  $self->html_content( 'FORM_INPUT_SESSION_KEEPER' => "<input type=hidden name=_ value=$ah>" );
  $self->html_content( %opt );

  my $portray_data;

  if( ref( $data ) eq 'HASH'  )
    {
    $portray_data = $data;
    $page = $action = undef;
    }
  elsif( $action )
    {
    # FIXME: handle content type also!
    $portray_data = $self->act->call( $action );
    $page = undef;
    }
  elsif( $page )
    {
    $portray_data = $self->pre->load_page( $page );
    $action = undef;
    }
  else
    {
    boom "render() needs PAGE or ACTION";
    }

  if( ref( $portray_data ) eq 'HASH' )
    {
    # as expected but no handling required
    }
  elsif( ref( $portray_data ) )
    {
    boom "expected portray data (i.e. HASHREF) but got different reference";
    }
  else
    {
    # default portray type is html
    $portray_data = $self->portray( $portray_data, 'text/html' );
    }

  my $page_data = $portray_data->{ 'DATA'      };
  my $page_fh   = $portray_data->{ 'FH'        }; # filehandle has priority
  my $page_type = $portray_data->{ 'TYPE'      };
  my $file_name = $portray_data->{ 'FILE_NAME' };
  my $disp_type = $portray_data->{ 'DISPOSITION_TYPE' } || 'inline'; # default, rest must be handled as 'attachment', ref: rfc6266#section-4.2

  # preparing headers --------------------------------------------------------
  # FIXME: charset
  $self->res_set_headers( 'content-type'        => $page_type );
  $self->res_set_headers( 'content-disposition' => "$disp_type; filename=$file_name" ) if $file_name;

  # handling Content Security Policy (CSP) -- https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
  my $http_csp = $self->get_cfg->{ 'HTTP_CSP' }; # || " default-src 'self' ";
  $self->res_set_headers( 'Content-Security-Policy' => $http_csp ) if $http_csp;

  my $app_charset = uc $self->get_cfg->{ 'APP_CHARSET' } || 'UTF-8';

  my $page_type_is_text = $page_type =~ /^text\//i;
  if( $page_type_is_text )
    {
    # set charset for TEXT only
    $self->res_set_headers( 'content-charset' => $app_charset );
    }

  # preparing body -----------------------------------------------------------

  if( $page_fh )
    {
    $self->res_set_body( $page_fh );
    }
  elsif( lc $page_type =~ /^text\/html/ )
    {
    my $prep_opt1 = {};
    $page_data = $self->pre->process( $page, $page_data, $prep_opt1 );

    my $prep_opt2 = {};
    $page_data = $self->pre->process( $page, $page_data, $prep_opt2 ) if $prep_opt1->{ 'SECOND_PASS_REQUIRED' };

    # FIXME: translation
    $self->load_trans();
    my $tr = $self->{ 'TRANS' }{ $self->get_cfg->{ 'LANG' } } || {};
    $page_data =~ s/\<~([^\<\>]*)\>/$tr->{ $1 } || $1/ge;
    $page_data =~ s/\[~([^\[\]]*)\]/$tr->{ $1 } || $1/ge;
    
    $self->res_set_body( encode( $app_charset, $page_data ) );
    }
  else
    {
    $self->res_set_body( $page_data );
    }  

  sink 'RENDER';
}

my %SIMPLE_PORTRAY_TYPE_MAP = (
                              html => 'text/html',
                              text => 'text/plain',
                              txt  => 'text/plain',
                              jpeg => 'image/jpeg',
                              png  => 'image/png',
                              bin  => 'application/octet-stream',
                              );

sub portray
{
  my $self = shift;
  my $data = shift;
  my $type = lc shift; # mime type text/html
  my %opt  = @_; # file name, charset, etc.

  $type = $SIMPLE_PORTRAY_TYPE_MAP{ $type } || $type;

  boom "portray needs mime type xxx/xxx as arg 2, got [$type]" unless $type =~ /^[a-z\-_0-9]+\/[a-z\-_0-9\.]+$/;

  return { DATA => $data, TYPE => $type, @_ };
}

##############################################################################

sub forward_url
{
  my $self = shift;
  my $url  = shift;

  # FIXME: use render+portray
  $self->res_set_headers( status => 302, location => $url );
  $self->res_set_body();

  sink 'RENDER';
}

sub forward
{
  my $self = shift;

  boom "expected even number of arguments" unless @_ % 2 == 0;

  my $fw = $self->args( @_ );
  return $self->forward_url( "?_=$fw" );
}

sub forward_type
{
  my $self = shift;

  boom "expected odd number of arguments" if @_ % 2 == 0;

  my $fw = $self->args_type( @_ );
  return $self->forward_url( "?_=$fw" );
}

sub forward_here
{
  my $self = shift;

  boom "expected even number of arguments" unless @_ % 2 == 0;

  my $fw = $self->args_here( @_ );
  return $self->forward_url( "?_=$fw" );
}

sub forward_back
{
  my $self = shift;

  boom "expected even number of arguments" unless @_ % 2 == 0;

  my $fw = $self->args_back( @_ );
  return $self->forward_url( "?_=$fw" );
}

sub forward_back_back
{
  my $self = shift;

  boom "expected even number of arguments" unless @_ % 2 == 0;

  my $fw = $self->args_back_back( @_ );
  return $self->forward_url( "?_=$fw" );
}

sub forward_new
{
  my $self = shift;

  boom "expected even number of arguments" unless @_ % 2 == 0;

  my $fw = $self->args_new( @_ );
  return $self->forward_url( "?_=$fw" );
}

sub forward_new_page
{
  my $self = shift;
  my $page = shift;

  boom "expected page name + even number of arguments" unless @_ % 2 == 0;

  return $self->forward_new( _PN => $page, @_ );
}

sub forward_new_action
{
  my $self = shift;
  my $actn = shift;

  boom "expected action name + even number of arguments" unless @_ % 2 == 0;

  return $self->forward_new( _AN => $actn, @_ );
}

##############################################################################
##
## helpers
##

sub __param
{
  my $self = shift;
  my $save = shift; # 0 not save, 1 save in cache, 2 save in cache and page session (ps)
  my $safe = shift; # 0 user (unsafe) input, 1 safe input

  my $input_hr;
  my $save_key;
  if( $safe )
    {
    $input_hr = $self->get_safe_input();
    $save_key = 'SAVE_SAFE_INPUT';
    }
  else
    {
    $input_hr = $self->get_user_input();
    $save_key = 'SAVE_USER_INPUT';
    }

  my $ps = $self->get_page_session();

  $ps->{ $save_key } ||= {} if $save > 0;

  my @res;
  while( @_ )
    {
    my $p = uc shift;
    if( $save > 0 )
      {  
      if( exists $input_hr->{ $p } )
        {
        $ps->{ $save_key }{ $p } = $input_hr->{ $p };
        $ps->{ $p } = $input_hr->{ $p } if $save > 1;
        }
      push @res, $ps->{ $save_key }{ $p };
      }
    else
      {
      push @res, $input_hr->{ $p };
      }
    }

  return wantarray ? @res : shift( @res );
}

sub param_unsafe
{
  my $self = shift;
  return $self->__param( 1, 0, @_ );
}

sub param
{
  my $self = shift;
  return $self->__param( 1, 1, @_ );
}

sub param_save
{
  my $self = shift;
  return $self->__param( 2, 1, @_ );
}

sub param_safe
{
  my $self = shift;
  return $self->param( @_ );
}

sub param_peek_unsafe
{
  my $self = shift;
  return $self->__param( 0, 0, @_ );
}

sub param_peek
{
  my $self = shift;
  return $self->__param( 0, 1, @_ );
}

sub param_peek_safe
{
  my $self = shift;
  return $self->param_peek( @_ );
}

sub param_clear_cache
{
  my $self = shift;

  my $ps = $self->get_page_session();

  while( @_ )
    {
    my $p = uc shift;
    delete $ps->{ 'SAVE_SAFE_INPUT' }{ $p };
    delete $ps->{ 'SAVE_USER_INPUT' }{ $p };
    }

  return 1;
}


sub is_logged_in
{
  my $self = shift;

  my $user_shr = $self->get_user_session();
  return $user_shr->{ ':LOGGED_IN' } ? 1 : 0;
}

sub login
{
  my $self = shift;

  my $user_shr = $self->get_user_session();
  $user_shr->{ ':LOGGED_IN'  } = 1;
  $user_shr->{ ':LTIME'      } = time();
  $user_shr->{ ':LTIME_STR'  } = scalar localtime();
  # FIXME: add more login info
}

sub logout
{
  my $self = shift;

  my $user_shr = $self->get_user_session();
  $user_shr->{ ':LOGGED_IN'    } = 0;
  $user_shr->{ ':CLOSED'       } = 1;
  $user_shr->{ ':ETIME'        } = time();
  $user_shr->{ ':ETIME_STR'    } = scalar localtime();
  # FIXME: add more logout info
  my ( $user_sid, $user_shr ) = $self->__create_new_user_session();
}

# FIXME: s?
sub need_login
{
  my $self = shift;

  return if $self->is_logged_in();

  my $fw = $self->args_new( _PN => 'login' );
  return $self->forward_url( "?_=$fw" );

  # return $self->forward( _PN => 'login' );
}

sub set_user_session_expire_time
{
  my $self  = shift;
  my $xtime = shift;

#use Exception::Sink;
#my $xtt = localtime( $xtime );
#print STDERR "set_user_session_expire_time($xtime)[$xtt]\n" . Exception::Sink::get_stack_trace();

  my $user_shr = $self->get_user_session();
  $user_shr->{ ':XTIME'     } = $xtime; # FIXME: sanity?
  $user_shr->{ ':XTIME_STR' } = scalar localtime $user_shr->{ ':XTIME' };
  return exists $user_shr->{ ':XTIME' } ? $user_shr->{ ':XTIME' } : undef;
}

sub set_user_session_expire_time_in
{
  my $self    = shift;
  my $seconds = shift;

#use Exception::Sink;
#print STDERR "set_user_session_expire_time_in($seconds)\n" . Exception::Sink::get_stack_trace();

  # FIXME: support for more user friendly time periods 10m 60s
  return $self->set_user_session_expire_time( time() + $seconds );
}

# returns unix time at which user session will expire, undef if no expire time specified
sub get_user_session_expire_time
{
  my $self = shift;

  my $user_shr = $self->get_user_session();

#use Exception::Sink;
#my $xtt = localtime( $user_shr->{ ':XTIME' } );
#print STDERR "get_user_session_expire_time($user_shr->{ ':XTIME' })[$xtt]\n" . Exception::Sink::get_stack_trace();

  return exists $user_shr->{ ':XTIME' } ? $user_shr->{ ':XTIME' } : undef;
}

# returns time period in seconds, in which user session will expire, undef if no expire time specified
sub get_user_session_expire_time_in
{
  my $self = shift;

  my $xi = $self->get_user_session_expire_time() - time();
  return $xi > 0 ? $xi : undef;
}

sub require_post_method
{
  my $self = shift;

  return if $self->get_request_method() eq 'POST';

  $self->logout();
  $self->render( PAGE => 'epostrequired' );
}

sub get_user_session_agent
{
  my $self = shift;

  my $user_session = $self->get_user_session();
  my $user_agent   = $user_session->{ ':HTTP_ENV_HR' }{ 'HTTP_USER_AGENT' };

  return $user_agent || 'n/a';
}

##############################################################################

sub load_trans
{
  my $self = shift;

  my $cfg = $self->get_cfg();

  my $lang = lc $cfg->{ 'LANG' };

  return 0 if $lang !~ /^[a-z][a-z]$/; # FIXME: move to init check! verofy hash etc. data::tools

  $self->{ 'TRANS' }{ 'LANG' } = $lang;

  return 1 if $self->{ 'TRANS' }{ $lang };

  my $tr = $self->{ 'TRANS' }{ $lang } = {};

  my $trans_dirs = $cfg->{ 'TRANS_DIRS' };
  my $trans_file = $cfg->{ 'TRANS_FILE' };

  my @tf;
  if( $trans_file )
    {
    # quick select single translation file, if specified
    @tf = ( $trans_file );
    }
  else
    {  
    for my $dir ( @$trans_dirs )
      {
      push @tf, glob( "$dir/$lang/*.tr" );
      push @tf, glob( "$dir/$lang/text/*.tr" );
      }
    }  

  for my $tf ( @tf )
    {
    my $hr = $self->load_trans_file( $tf );
    # trim whitespace
    my @temp = %$hr;
    for( @temp )
      {
      s/^\s*//;
      s/\s*$//;
      }
    %$hr = @temp;
    @temp = ();
    @{ $tr }{ keys %$hr } = values %$hr;
    }

  return 1;
}

sub load_trans_file
{
  my $self = shift;

  return hash_load( shift );
}

##############################################################################
##
## REO proxies
##

sub ses { my $self = shift; return $self->{ 'REO_SES' } };
sub pre { my $self = shift; return $self->{ 'REO_PRE' } };
sub act { my $self = shift; return $self->{ 'REO_ACT' } };

sub new_form
{
  my $self = shift;

  my $form = new Web::Reactor::HTML::Form( @_, REO_REACTOR => $self );

  return $form;
}

##############################################################################

sub set_browser_window_title
{
  my $self = shift;

  $self->html_content( 'BROWSER_WINDOW_TITLE', shift() );
}

##############################################################################

sub create_uniq_id
{
  my $self = shift;
  my $case = shift;

  my $nid;
  my $limit = 128;
  while( $limit-- )
    {
    my $nid = create_random_id( 8 );
    $nid = uc $nid if $case == 1;
    $nid = lc $nid if $case == 2;
    next if $self->{ 'CREATE_UNIQ_ID' }{ $nid }++;
    my $psid = $self->get_page_session_id();
    $self->{ 'CREATE_UNIQ_ID' }{ ':COUNT' }++;
    return $psid . $nid;
    }
  boom "cannot create new uniq html id";  
  return undef;
}

##############################################################################


=pod

=head1 NAME

Web::Reactor perl-based web application machinery.

=head1 SYNOPSIS

Startup CGI script example:

  #!/usr/bin/perl
  use strict;
  use lib '/opt/perl/reactor/lib'; # if Reactor is custom location installed
  use Web::Reactor;

  my %cfg = (
            'APP_NAME'     => 'demo',
            'APP_ROOT'     => '/opt/reactor/demo/',
            'LIB_DIRS'     => [ '/opt/reactor/demo/lib/'  ],
            'ACTIONS_SETS' => [ 'demo', 'Base', 'Core' ],
            'HTML_DIRS'    => [ '/opt/reactor/demo/html/' ],
            'SESS_VAR_DIR' => '/opt/reactor/demo/var/sess/',
            'DEBUG'        => 4,
            );

  eval { new Web::Reactor( %cfg )->run(); };
  if( $@ )
    {
    print STDERR "REACTOR CGI EXCEPTION: $@";
    print "content-type: text/html\n\nsystem is temporary unavailable";
    }

=head1 INTRODUCTION

Web::Reactor is a perl module which automates as much as possible of the all
routine tasks when implementing web applications, interactive sites, etc.
Main task is to handle all the repetative work and adding more comfortable
functionality like:

  * setting and recognising web browser cookies (for sessions or other data)
  * handling user and page sessions (storage, cookie management, etc.)
  * hiding html link data and forms data to rise page-to-page transfer safety.
  * preprocessing of text/html, including hiding data, calling actions etc.
  * on-demand loading of 'actions', perl code modules to handle dynamic pages.

Web::Reactor can be extended, though it was not supposed to. There are 4 main
parts of it which can be extended. See section EXTENDING below for details.

=head1 EXAMPLES

HTML page file example:

  <#html_header>

  <$app_name>

  <#menu>

  testing page html file

  action test: <&test>

  <#html_footer>

Action module example:

  package Reactor::Actions::demo::test;
  use strict;
  use Data::Dumper;
  use Web::Reactor::HTML::FormEngine;

  sub main
  {
    my $reo = shift; # Web::Reactor object. Provides all API and context.

    my $text; # result html text

    if( $reo->get_input_button() eq 'FORM_CANCEL' )
      {
      # if clicked form button is cancel,
      # return back to the calling/previous page/view with optional data
      return $reo->forward_back( ACTION_RETURN => 'IS_CANCEL' );
      }

    # add some html content
    $text .= "<p>Reactor::Actions::demo::test here!<p>";

    # create link and hide its data. only accessible from inside web app.
    my $grid_href = $reo->args_new( _PN => 'grid', TABLE => 'testtable', );
    $text .= "<a href=?_=$grid_href>go to grid</a><p>";

    # access page session. it will be auto-loaded on demand
    my $page_session_hr = $reo->get_page_session();
    my $fortune = $page_session_hr->{ 'FORTUNE' } ||= `/usr/games/fortune`;

    # access input (form) data. $i and $e are hashrefs
    my $i = $reo->get_user_input(); # get plain user input (hashref)
    my $e = $reo->get_safe_input(); # get safe data (never reach user browser)

    $text .= "<p><hr><p>$fortune<hr>";

    my $bc = $reo->args_here(); # session keeper, this is manual use

    $text .= "<form method=post>";
    $text .= "<input type=hidden name=_ value=$bc>";
    $text .= "input <input name=inp>";
    $text .= "<input type=submit name=button:form_ok>";
    $text .= "<input type=submit name=button:form_cancel>";
    $text .= "</form>";

    my $form = $reo->new_form();

    $text .= "<p><hr><p>";

    return $text;
  }

  1;

=head1 PAGE NAMES, HTML FILE TEMPLATES, PAGE INSTANCES

Web::Reactor has a notion of a "page" which represents visible output to the
end user browser. It has (i.e. uses) the following attributes:

  * html file template (page name)
  * page session data
  * actions code (i.e. callbacks) used inside html text

All of those represent "page instance" and produce end user html visible page.

"Page names" are strictly limited to be alphanumeric and are mapped to file
(or other storage) html content:

                   page name: example
  html file template will be: page_example.html

HTML content may include other files (also limited to be alphanumeric):

          include text: <#other_file>
         file included: other_file.html
  directories searched: 'HTML_DIRS' from Web::Reactor parameters.

Page names may be requested from the end user side, but include html files may
be used only from the pages already requested.

=head1 ACTIONS/MODULES/CALLBACKS

Actions are loaded and executed by package names. In the HTML source files they
can be called this way:

  <&test_action arg1=val1 arg2=val2 flag1 flag2...>
  <&test_action>

This will instruct Reactor action handler to look for this package name inside
standard or user-added library directories:

  Web/Reactor/Actions/*/test_action.pm

Asterisk will be replaced with the name of the used "action sets" give in config
hash:

       'ACTIONS_SETS' => [ 'demo', 'Base', 'Core' ],

So the result list in this example will be:

  Web/Reactor/Actions/demo/test_action.pm
  Web/Reactor/Actions/Base/test_action.pm
  Web/Reactor/Actions/Core/test_action.pm

This is used to allow overriding of standard modules or modules you dont have
write access to.

Another way to call a module is directly from another module code with:

  $reo->action_call( 'test_action', @args );

The package file will look like this:

   package Web/Reactor/Actions/demo/test_action;
   use strict;

   sub main
   {
     my $reo  = shift; # Web::Reactor object/instance
     my %args = @_; # all args passed to the action

     my $html_args = $args{ 'HTML_ARGS' }; # all
     ...
     return $result_data; # usually html text
   }

$html_args is hashref with all args give inside the html code if this action
is called from a html text. If you look the example above:

  <&test_action arg1=val1 arg2=val2 flag1 flag2...>

The $html_args will look like this:

  $html_args = {
               'arg1'  => 'val1',
               'arg2'  => 'val2',
               'flag1' => 1,
               'flag2' => 1,
               };



=head1 HTTP PARAMETERS NAMES

Web::Reactor uses underscore and one or two letters for its system http/html
parameters. Some of the system params are:

  _PN  -- html page name (points to file template, restricted to alphanumeric)
  _AN  -- action name (points to action package name, restricted to alphanumeric)
  _P   -- page session
  _R   -- referer (caller) page session

Usually those names should not be directly used or visible inside actions code.
More details about how those params are used can be found below.

=head1 USER SESSIONS

WR creates unique session for each connected user. The session is kept by a cookie.
Usually WR needs justthis cookie to handle all user/server interaction. Inside
WR action code, user session is represented as a hash reference. It may hold
arbitrary data. "System" or WR-specific data inside user session has colon as
prefix:

  # $reo is Web::Reactor object (i.e. context) passed to the action/module code
  my $user_session = $reo->get_user_session();
  print STDERR $user_session->{ ':CTIME_STR' };
  # prints in http log the create time in human friendly form

All data saved inside user session is automatically saved. When needed it can
be explicitly with:

  $reo->save();
  # saves all modified context to disk or other storage

=head1 PAGE SESSIONS

Each page presented to the user has own session. It is very similar to the user
session (it is hash reference, may hold any data, can be saved with $reo->save()).
It is expected that page sessions hold all context data needed for any page to
display properly. To preserve page session it is needed that it is included
in any link to this page instance or in any html form used.

When called for the first time, each page request needs page name (_PN). Afterwards
a unique page session is created and page name is saved inside. At this moment
this page instance can be accessed (i.e. given control to) only with a page
session id (_P):

  $page_sid = ...; # taken from somewhere
  # to pass control to the page instance:
  $reo->forward( _P => $page_sid );
  # the page instance will pull data from its page session and display in
  # its last known state

Not always page session are needed. For example, when forward to the caller is
needed, you just need to:

   $reo->forward_back();
   # this is equivalent to
   my $ref_page_sid = $reo->get_ref_page_session_id();
   $reo->forward( _P => $ref_page_sid );

Each page instance knows the caller page session and can give control back to.
However it may pass more data when returning back to the caller:

   $reo->forward_back( MORE_DATA => 'is here', OPTIONS_LIST => \@list );

When new page instance has to be called (created):


   $reo->forward_new( _PN => 'some_page_name' );

=head1 CONFIG ENTRIES

Upon creation, Web:Reactor instance gets hash with config entries/keys:

  * APP_NAME      -- alphanumeric application name (plus underscore)
  * APP_ROOT      -- application root dir, used for app components search
  * LIB_DIRS      -- directories from which actions and other libs are loaded
  * ACTIONS_SETS  -- list of action "sets", appended to ACTIONS_DIRS
  * HTML_DIRS     -- html file inlude directories
  * SESS_VAR_DIR  -- used by filesystem session handling to store sess data
  * DEBUG         -- positive number, enables debugging with verbosity level

Some entries may be omitted and default values are:

  * LIB_DIRS      -- [ "$APP_ROOT/lib"  ]
  * ACTIONS_SETS  -- [ $APP_NAME, 'Base', 'Core' ]
  * HTML_DIRS     -- [ "$APP_ROOT/html" ]
  * SESS_VAR_DIR  -- [ "$APP_ROOT/var"  ]
  * DEBUG         -- 0

=head1 API FUNCTIONS

  # TODO: input
  # TODO: sessions
  # TODO: arguments, constructing links
  # TODO: forwarding
  # TODO: html, forms, session keeping

=head1 DEPLOYMENT, DIRECTORIES, FILESYSTEM STRUCTURE

  # TODO: install, cpan, manual, github, custom locations
  # TODO: sessions dir, custom storage/session handling

=head1 EXTENDING

Web::Reactor is designed to allow extending or replacing the 4 main parts:

    * Session storage (data store on filesystem, database, remote or vmem)

      base module:    Web::Reactor::Sessions
      current in use: Web::Reactor::Sessions::Filesystem

    * HTML creation/expansion/preprocessing

      base module:    Web::Reactor::Preprocessor
      current in use: Web::Reactor::Preprocessor::Native

    * Actions/modules execution (can be skipped if custom HTML prep used)

      base module:    Web::Reactor::Actions
      current in use: Web::Reactor::Actions::Native

    * Main Web::Reactor modules, which controlls all the functionality.

      base module:    Web::Reactor
      current in use: Web::Reactor

Except main module (Web::Reactor) is is expected that base modules are
subclassed for extension. Inside each of them there are notes on what must
be extended and usage hints.

Current implementations of the modules, shipped with Web::Reactor, can also
be extended and/or modified. However it is suggested checking base modules
first.

Main module (Web::Reactor) handles all of the logic. It is not expected to
be modified since it is designed to handle tightly all the parts. However,
there are few things which can be modified but it is recommended to contact
authors for an advice first. On the other hand, the main module instance is
always passed as argument to all other modules/actions so it is good idea
to add specific functionality which will be readily available everywhere.

=head1 PROJECT STATUS

Web::Reactor is stable and it is used in many production sites including
banks, insurance, travel and other smaller companies.

API is frozen but it could be extended

If you are interested in the project or have some notes etc, contact me at:

  Vladi Belperchinov-Shabanski "Cade"
  <cade@noxrun.com>
  <cade@cpan.org>
  <shabanski@gmail.com>

further contact info, mailing list and github repository is listed below.

=head1 FIXME: TODO:

  * config examples
  * pages example
  * actions example
  * API description (input data, safe data, sessions, forwarding, actions, html)
  * ...

=head1 REQUIRED ADDITIONAL MODULES

Reactor uses mostly perl core modules but it needs few others:

    * CGI
    * Scalar::Util
    * Hash::Util
    * Data::Dumper (for debugging)
    * Exception::Sink
    * Data::Tools

All modules are available with the perl package or from CPAN.

Additionally, several are available and from github:

    * Exception::Sink
    https://github.com/cade-vs/perl-exception-sink

    * Data::Tools
    https://github.com/cade-vs/perl-data-tools

=head1 DEMO APPLICATION

Documentation will be improved. Meanwhile you can check 'demo'
directory inside distribution tarball or inside the github repository. This is
fully functional (however stupid :)) application. It shows how data is processed,
calling pages/views, inspecting page (calling views) stack, html forms automation,
forwarding.

Additionally you may check DECOR information systems infrastructure, which uses
Web::Reactor for its main web interface:

    https://github.com/cade-vs/perl-decor

=head1 MAILING LIST

  web-reactor@googlegroups.com

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-web-reactor

  git clone git://github.com/cade-vs/perl-web-reactor.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@bis.bg> <cade@cpan.org> <shabanski@gmail.com>

  http://cade.noxrun.com

  https://github.com/cade-vs

=head2 EOF

=cut


##############################################################################
1;
###EOF########################################################################
