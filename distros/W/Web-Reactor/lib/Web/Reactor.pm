##############################################################################
##
##  Web::Reactor application machinery
##  2013-2017 (c) Vladi Belperchinov-Shabanski "Cade"
##  <cade@bis.bg> <cade@biscom.net> <cade@cpan.org>
##
##  LICENSE: GPLv2
##
##############################################################################
package Web::Reactor;
use strict;
use Storable qw( dclone freeze thaw ); # FIXME: move to Data::Tools (data_freeze/data_thaw)
use CGI 4.08;
use CGI::Cookie;
use Data::Tools;
use Exception::Sink;
use Data::Dumper;

use Web::Reactor::Utils;
use Web::Reactor::HTML::Form;

our $VERSION = '2.06';

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
  my %env = @_;

  # FIXME: verify %env content! Data::Validate::Struct

  $class = ref( $class ) || $class;
  my $self = {
             'ENV' => \%env,
             };
  bless $self, $class;

#  my $root = $self->{ 'ENV' }{ 'ROOT' };
#  # autosetup defaults
#  if( ! $self->{ 'ENV' }{ 'HTML_DIRS' } )
#    {
#    $self->{ 'ENV' }{ 'HTML_DIRS' } = [ "$root/html" ];
#    }

  # FIXME: common directories setup code?
  if( ! $env{ 'LIB_DIRS' } or @{ $env{ 'LIB_DIRS' } } < 1 )
    {
    my $root = $env{ 'APP_ROOT' };
    $env{ 'LIB_DIRS' } = [ "$root/lib" ];
    }

  my $lib_dirs = $env{ 'LIB_DIRS' } || [];
  my $lib_dirs_ok = 0;
  for my $lib_dir ( @$lib_dirs )
    {
    next unless -d $lib_dir;
    push @INC, $lib_dir;
    $lib_dirs_ok++;
    }
  boom "invalid or not accessible LIB_DIR's [@$lib_dirs]" unless $lib_dirs_ok;

  # sanity, remove '.' from include list, TODO: optionally remove other entries by config (%env)
  for my $z ( 0 .. scalar( @INC ) - 1 )
    {
    next unless $INC[ $z ] eq '.';
    splice @INC, $z, 1;
    last;
    }

  my $reo_sess_class = $env{ 'REO_SESS_CLASS' } ||= 'Web::Reactor::Sessions::Filesystem';
  my $reo_prep_class = $env{ 'REO_PREP_CLASS' } ||= 'Web::Reactor::Preprocessor::Native';
  my $reo_acts_class = $env{ 'REO_ACTS_CLASS' } ||= 'Web::Reactor::Actions::Native';

  my $reo_sess_class_file = perl_package_to_file( $reo_sess_class );
  my $reo_prep_class_file = perl_package_to_file( $reo_prep_class );
  my $reo_acts_class_file = perl_package_to_file( $reo_acts_class );

  require $reo_sess_class_file;
  require $reo_prep_class_file;
  require $reo_acts_class_file;

  # new objects for part slots
  # FIXME: pass %env reference to use the same env hash
  $self->{ 'REO_SESS' } = new $reo_sess_class %env;
  $self->{ 'REO_PREP' } = new $reo_prep_class %env;
  $self->{ 'REO_ACTS' } = new $reo_acts_class %env;

  # set backlinks to reactor
  $self->{ 'REO_SESS' }->__set_reo( $self );
  $self->{ 'REO_PREP' }->__set_reo( $self );
  $self->{ 'REO_ACTS' }->__set_reo( $self );

  # debug setup
  $self->log_debug( "debug: setup: " . Dumper( $self->{ 'ENV' } ) );

  return $self;
}

#sub DESTROY
#{
# my $self = shift;
#
# print "DESTROY: Reactor: $self\n";
#}

##############################################################################

sub run
{
  my $self = shift;

  eval
    {
    $self->main_process();
    };
  if( surface( 'CONTENT' ) )
    {
    # nothing, should be ok
    }
  elsif( surface( '*' ) )
    {
    $self->log( "error: main process failed: $@" );
    }
  $self->save();

  if( $self->is_debug() )
    {
    my $psid = $self->get_page_session_id( 0 ) || 'empty';
    my $rsid = $self->get_page_session_id( 1 ) || 'empty';
    $self->log_dumper( "USER INPUT -----------------------------------", $self->get_user_input() );
    $self->log_dumper( "SAFE INPUT -----------------------------------", $self->get_safe_input() );
    $self->log_dumper( "FINAL PAGE SESSION [$psid]-----------------------------------", $self->get_page_session() );
    $self->log_dumper( "FINAL REF  SESSION [$rsid]-----------------------------------", $self->get_page_session( 1 ) );
    #$self->log_dumper( "FINAL USER SESSION [$psid]-----------------------------------", $self->get_user_session() );
    }

}

sub main_process
{
  my $self = shift;

  # 0. load/setup env/config defaults
  my $app_name = $self->{ 'ENV' }{ 'APP_NAME' } or $self->boom( "missing APP_NAME" );

  # 1. loading request header

  # 2. loading cookie
  my $cookie_name = lc( $self->{ 'ENV' }{ 'COOKIE_NAME' } || "$app_name\_cookie" );
  my $user_sid = $self->get_cookie( $cookie_name );

  # 3. loading user session, setup new session and cookie if needed
  my $user_shr = {}; # user session hash ref
  if( ! ( $user_sid =~ /^[a-zA-Z0-9]+$/ and $user_shr = $self->sess_load( 'USER', $user_sid ) ) )
    {
#    print STDERR Dumper( $user_sid, $user_shr );

    $self->log( "warning: invalid user session [$user_sid]" );

    ( $user_sid, $user_shr ) = $self->__create_new_user_session();
    }
  $self->{ 'SESSIONS' }{ 'SID'  }{ 'USER' } = $user_sid;
  $self->{ 'SESSIONS' }{ 'DATA' }{ 'USER' }{ $user_sid } = $user_shr;

  # read http environment data, used for checks and info
  $user_shr->{ ":HTTP_ENV_HR"   } = { map { $_ => $ENV{ $_ } } @HTTP_VARS_SAVE  };

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
    next if $user_shr->{ ":HTTP_CHECK_HR" }{ $k } eq $ENV{ $k };

    $self->log( "status: user session parameter [$k] check failed, sid [$user_sid]" );
    # FIXME: move to function: close_session();
    $user_shr->{ ':CLOSED'       } = 1;
    $user_shr->{ ':ETIME'        } = time();
    $user_shr->{ ':ETIME_STR'    } = scalar localtime();

    ( $user_sid, $user_shr ) = $self->__create_new_user_session();

    $self->render( PAGE => 'einvalid' );
    last;
    }

  # FIXME: move to single place
  my $user_session_expire = $self->{ 'ENV' }{ 'USER_SESSION_EXPIRE' } || 600; # 10 minutes
  $self->set_user_session_expire_time_in( $user_session_expire );

  $self->save();

  # 4. get input data, CGI::params, postdata
  my $input_user_hr = $self->{ 'INPUT_USER_HR' } = {};
  my $input_safe_hr = $self->{ 'INPUT_SAFE_HR' } = {};

  # FIXME: TODO: handle and URL params here. only for EX?
  my $iconv;
  my $app_charset = uc $self->{ 'ENV' }{ 'APP_CHARSET' } || 'UTF-8';

  if( $app_charset )
    {
    my $incoming_charset;
    if( uc( CGI::http( 'HTTP_X_REQUESTED_WITH' ) ) eq 'XMLHTTPREQUEST' )
      {
      $incoming_charset = 'UTF-8';
      }
    if( $incoming_charset and $incoming_charset ne $app_charset )
      {
      eval
        {
        # FIXME: use Encode; instead
        require 'Text/Iconv.pm';
        $iconv = Text::Iconv->new( $incoming_charset, $app_charset );
        };
      if( $@ )
        {
        $self->log( "error: cannot convert charset from [$incoming_charset] to [$app_charset] error: $@" );
        }
      }
    }

  # import plain parameters from GET/POST request
  for my $n ( CGI::param() )
    {
    if( $n !~ /^[A-Za-z0-9\-\_\.\:]+$/o )
      {
      $self->log( "error: invalid CGI/input parameter name: [$n]" );
      next;
      }
    my $v = CGI::param( $n );
    my @v = CGI::multi_param( $n );

    if( $iconv )
      {
      $v = $iconv->convert( $v );
      $_ = $iconv->convert( $_ ) for @v;
      }

    $n = uc $n;

    $self->log_debug( "debug: CGI input param [$n] value [$v] [@v]" );

    if( $self->__input_cgi_skip_invalid_value( $n, $v ) )
      {
      $self->log( "error: invalid CGI/input value for parameter: [$n]" );
      next;
      }
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
      $n = uc $n;
      $input_user_hr->{ $n } = $v;
      if( ref( $v ) eq 'Fh' )
        {
        # this is file upload, get more info
        $input_user_hr->{ "$n:UPLOAD_INFO" } = CGI::uploadInfo( $v );
        }
      }
    }

  my $safe_input_link_sess = $input_user_hr->{ '_' };
  # parse link session: link-sid.link-key
  if( $safe_input_link_sess =~ /^([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)$/ )
    {
    my ( $link_sid, $link_key ) = ( $1, $2 );

    my $link_session_hr = $self->sess_load( 'LINK', $link_sid );

    my $link_data = $link_session_hr->{ $link_key };

    # merge safe input if valid
    %$input_safe_hr = ( %$input_safe_hr, %$link_data ) if $link_data;
    }
  elsif( $safe_input_link_sess ne '' )
    {
    $self->log( "warning: invalid safe input link session.key [$safe_input_link_sess]" );
    }

  # 5. loading page session
  my $page_sid = $input_safe_hr->{ '_P' };
  my $page_shr = {}; # user session hash ref
  if( ! ( $page_sid =~ /^[a-zA-Z0-9]+$/ and $page_shr = $self->sess_load( 'PAGE', $page_sid ) ) )
    {
    $self->log( "warning: invalid page session [$page_sid]" );
    $page_sid = $self->sess_create( 'PAGE', 8 );
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

  # 6. remap form input data, post to safe input
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

  # 7. get action from input (USER/CGI) or page session
  my $action_name = lc( $input_safe_hr->{ '_AN' } || $input_user_hr->{ '_AN' } || $page_shr->{ ':ACTION_NAME' } );
  if( $action_name =~ /^[a-z_0-9]+$/ )
    {
    $page_shr->{ ':ACTION_NAME' } = $action_name;
    }
  else
    {
    # $self->log( "error: invalid action name [$action_name]" );
    }

  # 8. get page from input (USER/CGI) or page session
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

  # pre-9. print debug status...
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

  # 9. render output action/page
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

  # FIXME: move to function
  my $app_name = $self->{ 'ENV' }{ 'APP_NAME' } or $self->boom( "missing APP_NAME" );
  my $cookie_name = lc( $self->{ 'ENV' }{ 'COOKIE_NAME' } || "$app_name\_cookie" );

  $user_sid = $self->sess_create( 'USER' );
  $user_shr = { ':ID' => $user_sid };
  $self->{ 'SESSIONS' }{ 'SID'  }{ 'USER' } = $user_sid;
  $self->{ 'SESSIONS' }{ 'DATA' }{ 'USER' }{ $user_sid } = $user_shr;

  my $secure_cookie = $self->{ 'ENV' }{ 'DISABLE_SECURE_COOKIES' } ? 0 : 1;
  $self->set_cookie( $cookie_name, -value => $user_sid, -httponly => 1, -secure => $secure_cookie );
  $self->log( "debug: creating new user session [$user_sid]" );

  my $user_session_expire = $self->{ 'ENV' }{ 'USER_SESSION_EXPIRE' } || 600; # 10 minutes

  $user_shr->{ ':CTIME'      } = time();
  $user_shr->{ ':CTIME_STR'  } = scalar localtime();

  $self->set_user_session_expire_time_in( $user_session_expire );

  $user_shr->{ ":HTTP_CHECK_HR" } = { map { $_ => $ENV{ $_ } } @HTTP_VARS_CHECK };

  return ( $user_sid, $user_shr );
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
      $page_shr = $self->sess_load( 'PAGE', $page_sid );
      $self->{ 'SESSIONS' }{ 'DATA' }{ 'PAGE' }{ $page_sid } = $page_shr;
      }
    }

  return $page_shr;
}

sub get_http_env
{
  my $self  = shift;

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

  return $self->{ 'ENV' }{ 'LANG' };
}

sub get_app_root
{
  my $self  = shift;

  return $self->{ 'ENV' }{ 'APP_ROOT' };
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
    $link_sid = $self->sess_create( 'LINK', 8 );
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
    $link_key = $self->{ 'REO_SESS' }->create_id( 8 ); # FIXME: length param env
    last if ! exists $link_shr->{ $link_key };
    }
  $self->boom( "cannot create LINK key" ) unless $link_key;

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
  $self->boom( "unknown or not supported TYPE [$type]" );
}

##############################################################################

sub get_cookie
{
  my $self = shift;
  my $name = shift;

  my $cookie = CGI::cookie( $name );
  $self->log_debug( "get_cookie: name [$name] value [$cookie]" );
  return $cookie;
}

sub set_cookie
{
  my $self = shift;
  my $name = shift;
  my %opt  = @_;

  $self->log( "debug: creating new cookie [$name]" );
  # FIXME: validate %opt  Data::Validate::Struct

  $opt{ -name } = $name;

  $self->{ 'OUTPUT' }{ 'COOKIES' }{ $name } = new CGI::Cookie( %opt );
}

##############################################################################

sub get_headers
{
  my $self  = shift;

  my %h = map { $_ => CGI::http( $_ ) } CGI::http();

  return \%h;
}

sub set_headers
{
  my $self  = shift;
  my %h = @_;

  hash_lc_ipl( \%h );

  $self->{ 'OUTPUT' }{ 'HEADERS' } ||= {};
  $self->{ 'OUTPUT' }{ 'HEADERS' } = { %{ $self->{ 'OUTPUT' }{ 'HEADERS' } }, %h };
}

sub __make_headers
{
  my $self = shift;

  my $headers;

  $self->{ 'OUTPUT' }{ 'HEADERS' }{ 'content-type' } ||= 'text/html';

  # postprocess headers, custom logic, etc.
  my %headers_out = %{ $self->{ 'OUTPUT' }{ 'HEADERS' } };

  if( $headers_out{ 'content-charset' } )
    {
    if( $headers_out{ 'content-type' } !~ /;\s*charset=/i )
      {
      $headers_out{ 'content-type' } .= '; charset=' . $headers_out{ 'content-charset' };
      }
    delete $headers_out{ 'content-charset' };
    };

  while( my ( $k, $v ) = each %headers_out )
    {
    $headers .= "$k: $v\n";
    }

  while( my ( $k, $v ) = each %{ $self->{ 'OUTPUT' }{ 'COOKIES' } } )
    {
    $k = 'set-cookie';
    $headers .= "$k: $v\n";
    }

  $headers .= "\n"; # just single newline separator

  $self->log_dumper( 'HEADERS----------------------------------------', $headers );

  return $headers;
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
      $self->boom( "SESSION:DATA:$type:$sid is not hashref" ) unless ref( $shr ) eq 'HASH';

      my $sha1   = sha1_hex( freeze( $shr ) );
      my $cache1 = $mod_cache->{ $type }{ $sid };

      next if $sha1 eq $cache1;

      $self->log_debug( "saving session data [$type:$sid]" );

      $mod_cache->{ $type }{ $sid } = $sha1;

      $self->sess_save( $type, $sid, $shr );
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

  # FIXME: read key from config file only!
  my $key = $self->{ 'ENV' }{ 'ENCRYPT_KEY' };
  $self->boom( "missing ENV:ENCRYPT_KEY" ) unless $key =~ /\S/;

  my $ci = $self->{ 'ENV' }{ 'ENCRYPT_CIPHER' } || 'Twofish2'; # :)

  return new Crypt::CBC->new( -key => $key, -cipher => $ci );
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

##############################################################################

sub set_debug
{
  my $self  = shift;
  my $level = int(shift);

  if( $level > 0 )
    {
    $self->{ 'ENV' }{ 'DEBUG' } = $level > 0 ? $level : 0;
    }
  return $self->{ 'ENV' }{ 'DEBUG' };
}

sub is_debug
{
  my $self = shift;

  return $self->{ 'ENV' }{ 'DEBUG' };
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

  boom "too many nesting levels in rendering, probable bug in actions or pages" if (caller(512))[0] ne ''; # FIXME: config option for max level

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
    $portray_data = $self->action_call( $action );
    $page = undef;
    }
  elsif( $page )
    {
    $portray_data = $self->prep_load_page( $page );
    $action = undef;
    }
  else
    {
    boom "render() needs PAGE or ACTION";
    }

  if( ref( $portray_data ) eq 'HASH' )
    {
    # nothing, ok
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

#print STDERR Dumper( 'PORTRAY --- ' x 11, $page, $portray_data );

  my $page_data = $portray_data->{ 'DATA'      };
  my $page_type = $portray_data->{ 'TYPE'      };
  my $file_name = $portray_data->{ 'FILE_NAME' };

  if( lc $page_type =~ /^text\/html/ )
    {
    my $prep_opt1 = {};
    $page_data = $self->prep_process( $page, $page_data, $prep_opt1 );

#print STDERR Dumper( 'OPT1 PREP --- ' x 11, $prep_opt1);

    my $prep_opt2 = {};
    $page_data = $self->prep_process( $page, $page_data, $prep_opt2 ) if $prep_opt1->{ 'SECOND_PASS_REQUIRED' };

#print STDERR Dumper( 'PAGE DATA --- ' x 11, $page, $page_data );

    # FIXME: translation
    $self->load_trans();
    my $tr = $self->{ 'TRANS' }{ $self->{ 'ENV' }{ 'LANG' } } || {};
    $page_data =~ s/\<~([^\<\>]*)\>/$tr->{ $1 } || $1/ge;
    $page_data =~ s/\[~([^\[\]]*)\]/$tr->{ $1 } || $1/ge;
    }

  # FIXME: charset
  $self->set_headers( 'content-type'        => $page_type );
  $self->set_headers( 'content-disposition' => "attachment; filename=$file_name" ) if $file_name;

  my $http_csp = $self->{ 'ENV' }{ 'HTTP_CSP' }; # || " default-src 'self' ";
  $self->set_headers( 'Content-Security-Policy' => $http_csp );

  my $app_charset = uc $self->{ 'ENV' }{ 'APP_CHARSET' } || 'UTF-8';
  $self->set_headers( 'content-charset' => $app_charset );

  my $page_headers = $self->__make_headers();

  print $page_headers;
  print $page_data;

  $self->log_debug( "debug: page response content: page, action, type, headers, data: " . Dumper( $page, $action, $page_type, $page_headers, $page_type =~ /^text\// ? $page_data : '*binary*' ) ) if $self->is_debug() > 2;

  if( $self->is_debug() > 1 and lc $page_type =~ /^text\/html/ )
    {
    my $psid = $self->get_page_session_id( 0 ) || 'empty';
    my $rsid = $self->get_page_session_id( 1 ) || 'empty';
    print "<hr><pre>[$rsid] << [$psid]</pre>";
    }
  if( $self->is_debug() > 2 and lc $page_type =~ /^text\/html/ )
    {
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 3;
    print "<hr><pre>";
    print Dumper( 'USER INPUT:'.'_'x80, $self->{ 'INPUT_USER_HR' } );
    print Dumper( 'SAFE INPUT:'.'_'x80, $self->{ 'INPUT_SAFE_HR' } );
    print Dumper( 'PAGE SESSION:'.'_'x80, $self->{ 'SESSIONS' }{ 'DATA' }{ 'PAGE' }{ $self->{ 'SESSIONS' }{ 'SID' }{ 'PAGE' } } );
    print Dumper( 'USER SESSION:'.'_'x80, $self->{ 'SESSIONS' }{ 'DATA' }{ 'USER' }{ $self->{ 'SESSIONS' }{ 'SID' }{ 'USER' } } );
#    print "<hr>";
#    print Dumper( $self );
    print "</pre><hr>";
    }

  sink 'CONTENT';
}

my %SIMPLE_PORTRAY_TYPE_MAP = (
                              html => 'text/html',
                              text => 'text/plain',
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

  boom "portray needs mime type xxx/xxx as arg 2, got [$type]" unless $type =~ /^[a-z\-_0-9]+\/[a-z\-_0-9]+$/;

  return { DATA => $data, TYPE => $type, @_ };
}

##############################################################################

sub forward_url
{
  my $self = shift;
  my $url  = shift;

  # FIXME: use render+portray
  $self->set_headers( location => $url );

  my $page_headers = $self->__make_headers();
  print $page_headers;

  sink 'CONTENT';
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
  my $safe = shift; # 1 safe_input, 0 user_input

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

  $ps->{ $save_key } ||= {};

  my @res;
  while( @_ )
    {
    my $p = uc shift;
    if( exists $input_hr->{ $p } )
      {
      $ps->{ $save_key }{ $p } = $input_hr->{ $p };
      }
    push @res, $ps->{ $save_key }{ $p };
    }

  return wantarray ? @res : shift( @res );
}

sub param_unsafe
{
  my $self = shift;
  return $self->__param( 0, @_ );
}

sub param
{
  my $self = shift;
  return $self->__param( 1, @_ );
}

sub param_safe
{
  my $self = shift;
  return $self->param( @_ );
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
  return exists $user_shr->{ ':XTIME' } ? $user_shr->{ ':XTIME' } : undef;
}

# returns time period in seconds, in which user session will expire, undef if no expire time specified
sub get_user_session_expire_time_in
{
  my $self = shift;

  my $xi = $self->get_user_session_expire_time() - time();
  return $xi > 0 ? $xi : undef;
}

sub need_post_method
{
  my $self = shift;

  my $he = $self->get_http_env();

  return if $he->{ 'REQUEST_METHOD' } eq 'POST';

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

  my $lang = lc $self->{ 'ENV' }{ 'LANG' };

  return 0 if $lang !~ /^[a-z][a-z]$/; # FIXME: move to init check! verofy hash etc. data::tools

  $self->{ 'TRANS' }{ 'LANG' } = $lang;

  return 1 if $self->{ 'TRANS' }{ $lang };

  my $tr = $self->{ 'TRANS' }{ $lang } = {};

  my $trans_dirs = $self->{ 'ENV' }{ 'TRANS_DIRS' };

  my @tf;
  for my $dir ( @$trans_dirs )
    {
    push @tf, glob( "$dir/$lang/*.tr" );
    push @tf, glob( "$dir/$lang/text/*.tr" );
    }

  for my $tf ( @tf )
    {
    my $hr = hash_load( $tf );
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

##############################################################################
##
## REO proxies
##

# FIXME: should actions have access to low-level session handling?
sub sess_create    { my $self = shift; $self->{ 'REO_SESS' }->create(  @_ ) };
sub sess_delete    { my $self = shift; $self->{ 'REO_SESS' }->delete(  @_ ) };
sub sess_load      { my $self = shift; $self->{ 'REO_SESS' }->load(    @_ ) };
sub sess_save      { my $self = shift; $self->{ 'REO_SESS' }->save(    @_ ) };
sub sess_exists    { my $self = shift; $self->{ 'REO_SESS' }->exists(  @_ ) };

#sub prep_render    { my $self = shift; $self->{ 'REO_PREP' }->render(    @_ ) };
sub prep_load_page { my $self = shift; $self->{ 'REO_PREP' }->load_page( @_ ) };
sub prep_load_file { my $self = shift; $self->{ 'REO_PREP' }->load_file( @_ ) };
sub prep_process   { my $self = shift; $self->{ 'REO_PREP' }->process(   @_ ) };

sub action_call    { my $self = shift; $self->{ 'REO_ACTS' }->call(  @_ ) };

sub new_form
{
  my $self = shift;

  my $form = new Web::Reactor::HTML::Form( @_, REO_REACTOR => $self );

  return $form;
}

##############################################################################

sub html_new_id
{
  my $self = shift;

  my $psid = $self->get_page_session_id();
  $self->{ 'HTML_ID_COUNTER' }++;
  # FIXME: hash $psid once more to hide...
  return "REO_EID_$psid\_" . $self->{ 'HTML_ID_COUNTER' };
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

At the moment Web::Reactor is in beta. API is mostly frozen but it is possible
to be changed and/or extended. However drastic changes are not planned :)

If you are interested in the project or have some notes etc, contact me at:

  Vladi Belperchinov-Shabanski "Cade"
  <cade@bis.bg>
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

=head1 MAILING LIST

  web-reactor@googlegroups.com

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-web-reactor

  git clone git://github.com/cade-vs/perl-web-reactor.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@bis.bg> <cade@cpan.org> <shabanski@gmail.com>

  http://cade.datamax.bg

  https://github.com/cade-vs

=head2 EOF

=cut


##############################################################################
1;
###EOF########################################################################
