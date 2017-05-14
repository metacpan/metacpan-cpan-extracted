use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

mkdir 'build';
my $pkg = ExtUtils::Depends->new( 'ZeroMQ::Raw', 'XS::Object::Magic' );

# if you need to set -I or -L, do it via the arguments INC and LIBS:
#
# perl Makefile.PL INC="-I/opt/zeromq/include" LIBS="-L/opt/zeromq -lzmq"
#
# this is a standard and oft-unused ExtUtils::MakeMaker feature
# (though we reimplement it here for the benefit of ExtUtils::Depends)

my @argv = @ARGV;
@ARGV = ();

my %args;
for my $arg (@argv){
    if($arg =~ /^([A-Z]+)=(.+)$/ && $1 eq 'LIBS' || $1 eq 'INC'){
        $args{$1} = $2;
    }
    else {
        push @ARGV, $arg;
    }
}

$pkg->set_inc($args{INC}) if $args{INC};
$pkg->set_libs($args{LIBS} ? $args{LIBS}. ' -lzmq' : '-lzmq');
$pkg->add_xs('RawZMQ.xs');
$pkg->add_c('zmqxs.c');
$pkg->add_pm(
    './lib/ZeroMQ/Raw.pm'           => '$(INST_LIBDIR)/Raw.pm',
    './lib/ZeroMQ/Raw/Context.pm'   => '$(INST_LIBDIR)/Raw/Context.pm',
    './lib/ZeroMQ/Raw/Message.pm'   => '$(INST_LIBDIR)/Raw/Message.pm',
    './lib/ZeroMQ/Raw/Constants.pm' => '$(INST_LIBDIR)/Raw/Constants.pm',
    './lib/ZeroMQ/Raw/Socket.pm'    => '$(INST_LIBDIR)/Raw/Socket.pm',
);
$pkg->add_typemaps('typemap');
$pkg->save_config('build/IFiles.pm');

WriteMakefile(
  ABSTRACT => 'minimal ZeroMQ that follows the C API as closely as possible',
  AUTHOR => 'Jonathan Rockway <jrockway@cpan.org>',
  BUILD_REQUIRES => {
      'Test::More'      => '0',
      'Test::Exception' => '0',
  },
  CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.31',
      'ExtUtils::Depends'   => '0.300',
      'XS::Object::Magic'   => 0,
  },
  DISTNAME => 'ZeroMQ-Raw',
  LICENSE => 'lgpl',
  NAME => 'ZeroMQ::Raw',
  PREREQ_PM => {
      'XS::Object::Magic' => 0,
  },
  VERSION => '0.01',
  test => { 'TESTS' => 't/*.t' },
  $pkg->get_makefile_vars,
);
