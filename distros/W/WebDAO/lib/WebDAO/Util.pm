#===============================================================================
#
#  DESCRIPTION:  Set of  service subs
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package WebDAO::Util;
use strict;
use warnings;
use Carp;
use WebDAO::Engine;
use WebDAO::Session;
our $VERSION = '0.03';

=head2  load_module <package>

Check if already loaded package and preload else

return :  0  - fail load class
          1  - suss loaded
          -1 - already loaded

=cut

sub load_module {
    my $class = shift || return;

    #check non loaded mods
    my ( $main, $module ) = $class =~ m/(.*\:\:)?(\S+)$/;
    $main ||= 'main::';
    $module .= '::';
    no strict 'refs';
    unless ( exists $$main{$module} ) {
        eval "use $class";
        if ($@) {
            croak "Error register class :$class with $@ ";
            return 0;
        }
        return 1;
    } 
    use strict 'refs';
    -1;
}

=head2 _parse_str_to_hash <str>

convert string like:

    config=/tmp/tests.ini;host=test.local

to hash:

    {
      config=>'/tmp/tests.ini',
      host=>'test.local'
    }

=cut 

sub _parse_str_to_hash {
    my $str = shift;
    return unless $str;
    my %hash = map { split( /=/, $_ ) } split( /\s*;\s*/, $str );
    foreach ( values %hash ) {
        s/^\s+//;
        s/\s+^//;
    }
    \%hash;
}

=head2 get_classes <hash with defaults>

Get classes by check ENV variables

    get_classes( wdEngine=> $def_eng_class) 

return ref to hash

=cut

sub get_classes {

    my %defaults = (
        wdEngine     => 'WebDAO::Engine',
        wdSession    => 'WebDAO::Session',
        wdSessionPar => undef,
        wdEnginePar  => undef,
        @_
    );
    my $env          = delete $defaults{__env}     || \%ENV;
    my $need_preload = delete $defaults{__preload} || 0;

    $defaults{wdSession} =
         $env->{WD_SESSION}
      || $env->{wdSession}
      || $defaults{wdSession};
    $defaults{wdEngine} =
         $env->{WD_ENGINE}
      || $env->{wdEngine}
      || $defaults{wdEngine};

    #init params
    $defaults{wdEnginePar} =
      WebDAO::Util::_parse_str_to_hash( $env->{WD_ENGINE_PAR}
          || $env->{wdEnginePar} )
      || {};
    $defaults{wdSessionPar} =
      WebDAO::Util::_parse_str_to_hash( $env->{WD_SESSION_PAR}
          || $env->{wdSessionPar} )
      || {};

    if ($need_preload) {
        for (qw/wdSession  wdEngine /) {
            WebDAO::Util::load_module( $defaults{$_} );
        }
    }

    \%defaults;
   
}

=head2  expire_calc <time shift str>

Calculate time from str

 expire_calc('+1d') # current time() + 1 day
 expire_calc('+1y') # current time() + 1 year
 expire_calc('+1M') # current time() + 1 Month
 expire_calc('+1m') # current time() + 1 minute

return :  <unix_timestamp>

=cut

# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from 
# Mark Fisher

sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
      $offset = 0;
    } elsif ($time=~/^\d+/) {
      return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
      $offset = ($mult{$2} || 1)*$1;
    } else {
      return $time;
    }
    my $cur_time = time; 
    return ($cur_time+$offset);
}


our %HTTPStatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518 (WebDAV)
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',                    # RFC 2518 (WebDAV)
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
);

1;

