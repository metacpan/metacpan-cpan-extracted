#===============================================================================
#
#  DESCRIPTION:  Test Controller
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================

package Test::Writer;

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}
sub write   { ${ $_[0]->{out} } . $_[1] }
sub close   { }
sub headers { return $_[0]->{headers} }

1;

use strict;
use warnings;

sub make_cv {
    my %args = @_;
    my $out;
    my $cv = WebDAO::CV->new(
        env    => $args{env},
        writer => sub {
            new Test::Writer::
              out     => \$out,
              status  => $_[0]->[0],
              headers => $_[0]->[1];
        }
    );

}

use Test::More tests => 14;                      # last test to print
use_ok('WebDAO::CV');
use_ok('WebDAO::Response');

my $out  = '';
my $fcgi = WebDAO::CV->new(
    env => {
        'FCGI_ROLE'      => 'RESPONDER',
        'REQUEST_URI'    => '/Envs/partsh.sd?23=23',
        'HTTP_HOST'      => 'example.com:82',
        'QUERY_STRING'   => '23=23',
        'REQUEST_METHOD' => 'GET',
        'HTTP_ACCEPT' =>
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'HTTP_COOKIE' => 'tesrt=val; Yert=Terst',

    },
    writer => sub {
        new Test::Writer::
          out     => \$out,
          status  => $_[0]->[0],
          headers => $_[0]->[1];
    }
);

is $fcgi->url( -path_info => 1 ), '/Envs/partsh.sd',       '-path-info';
is $fcgi->url( -base      => 1 ), 'http://example.com:82', '-base';
is $fcgi->url(), 'http://example.com:82/Envs/partsh.sd?23=23', 'url()';
is $fcgi->method(), 'GET', 'method()';
is_deeply $fcgi->accept,
  {
    'application/xhtml+xml' => undef,
    'application/xml'       => undef,
    'text/html'             => undef
  },
  'accept';
is_deeply {
    map { $_ => $fcgi->param($_) } $fcgi->param()
}, { '23' => '23' }, 'GET params';

$fcgi->set_header( "Content-Type" => 'text/html; charset=utf-8' );
my $wr = $fcgi->print_headers();

is_deeply $wr->{headers},
  [ 'Content-Type' => 'text/html; charset=utf-8' ], "set headers";
is $wr->{status}, 200, 'Status: 200';
my $cv1 = &make_cv;
my $r = new WebDAO::Response:: cv => $cv1;
$r->content_type('text/html; charset=utf-8');
$r->content_length(2345);
$r->set_cookie(  name => 'test', value => 1  );
$r->set_cookie(  name => 'test1', value => 2, expires => 1327501188  );
$r->print_header();
is_deeply {@{ $r->_cv_obj->{fd}->headers}} ,
  {
    'Content-Length' => 2345,
    'Content-Type'   => 'text/html; charset=utf-8',
    'Set-Cookie'     => 'test=1; path=/',
    'Set-Cookie'     => 'test1=2; path=/; expires=Wed, 25-Jan-2012 14:19:48 GMT'
  },
  'Set Cookies';

my $cv_2 = &make_cv;
my $r2 = new WebDAO::Response:: cv => $cv_2;
$r2->set_cookie(  name => 'test', value => 1, secure=>1, httponly=>1 , expires=>'+3M' );
$r2->print_header();

my $cokies_str = { @{ $r2->_cv_obj->{fd}->headers}}->{'Set-Cookie'};
ok $cokies_str =~ /secure/i, 'Secure option';
ok $cokies_str =~ /httponly/i, 'httponly option';

my $cv2 = $fcgi;

is_deeply $cv2->get_cookie(),{
           'tesrt' => 'val',
           'Yert' => 'Terst'
         }, "Get cookie";


1;

