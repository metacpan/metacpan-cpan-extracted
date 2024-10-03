use 5.022000;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FindBin;

WriteMakefile(
  NAME         => 'Test::Mojo::Role::Log',
  VERSION_FROM => 'lib/Test/Mojo/Role/Log.pm',
  ABSTRACT     => 'Testing Mojo Log messages',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'perl',
  PREREQ_PM    => {
    'Mojolicious' => '8.52',
    'Class::Method::Modifiers' => 0,
    'Role::Tiny' => 0,
  },
  BUILD_REQUIRES => {
    'CPAN::Uploader' => 0,
    'Pod::Markdown::Github' => 0,
  },
  META_MERGE   => {
    requires  => {perl => '5.022000'},
    resources => {
      repository  => 'https://github.com/oposs/test-mojo-role-log',
      bugtracker  => 'https://github.com/oposs/test-mojo-role-log/issues'
    },
    no_index => {directory => ['t']},
    x_contributors => [
      'Robert Rothenberg <rrwo@cpan.org>',
    ],
  },
  test => {TESTS => 't/*.t'}
);

sub MY::postamble {
   my $self = shift;
   my %r = (%{ $self->{PREREQ_PM} || {} }, %{ $self->{BUILD_REQUIRES} || {} }, %{ $self->{TEST_REQUIRES} || {} } );
   my $modules = join " ", grep !/^perl\~/, map { $r{$_} ? $_ .'~'. $r{$_} : $_ } keys %r;
   my $tpd = "$FindBin::RealBin/thirdparty";
   warn "** call 'make thirdparty' to build missing dependencies ...\n";
   return <<"EOF";

README.md: $self->{VERSION_FROM}
	\$(PERL) -I$tpd/lib/perl5 -MPod::Markdown::Github -e 'binmode(STDOUT, ":utf8");Pod::Markdown::Github->new->filter(q{$self->{VERSION_FROM}})' > README.md

thirdparty: $tpd/touch
	mkdir -p $tpd

CHANGES: $self->{VERSION_FROM} Makefile
	echo $self->{VERSION} `date +"%Y-%m-%d %H:%M:%S %z"` `git config user.name` '<'`git config user.email`'>' >> CHANGES.new
	\@echo >> CHANGES.new
	\@echo ' -' >> CHANGES.new
	\@echo >> CHANGES.new
	\@cat CHANGES >> CHANGES.new && mv CHANGES.new CHANGES
	\@\$\$EDITOR CHANGES

$tpd/touch: Makefile
	\$(NOECHO) \$(ECHO) "*** INSTALLING MISSING BITS FOR TESTING ***"
	curl -L https://cpanmin.us | PERL_CPANM_HOME=$tpd \$(PERL) - -q --notest --local-lib-contained $tpd $modules && touch $tpd/touch
EOF
}
