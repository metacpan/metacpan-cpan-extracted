package Test::Valgrind::Command::Perl;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Command::Perl - A Test::Valgrind command that invokes perl.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This command is the base for all C<perl>-based commands.
It handles the suppression generation and sets the main command-line flags.

=cut

use List::Util    ();
use Env::Sanctify ();

use Test::Valgrind::Suppressions;

use base qw<Test::Valgrind::Command Test::Valgrind::Carp>;

=head1 METHODS

This class inherits L<Test::Valgrind::Command>.

=head2 C<new>

    my $tvcp = Test::Valgrind::Command::Perl->new(
     perl       => $^X,
     inc        => \@INC,
     taint_mode => $taint_mode,
     %extra_args,
    );

The package constructor, which takes several options :

=over 4

=item *

The C<perl> option specifies which C<perl> executable will run the arugment list given in C<args>.

Defaults to C<$^X>.

=item *

C<inc> is a reference to an array of paths that will be passed as C<-I> to the invoked command.

Defaults to C<@INC>.

=item *

C<$taint_mode> is a boolean that specifies if the script should be run under taint mode.

Defaults to false.

=back

Other arguments are passed straight to C<< Test::Valgrind::Command->new >>.

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my $perl       = delete $args{perl} || $^X;
 my $inc        = delete $args{inc}  || [ @INC ];
 $class->_croak('Invalid INC list') unless ref $inc eq 'ARRAY';
 my $taint_mode = delete $args{taint_mode};

 my $trainer_file = delete $args{trainer_file};

 my $self = bless $class->SUPER::new(%args), $class;

 $self->{perl}       = $perl;
 $self->{inc}        = $inc;
 $self->{taint_mode} = $taint_mode;

 $self->{trainer_file} = $trainer_file;

 return $self;
}

sub new_trainer {
 my $self = shift;

 require File::Temp;
 my ($fh, $file) = File::Temp::tempfile(UNLINK => 0);
 {
  my $curpos = tell DATA;
  print $fh $_ while <DATA>;
  seek DATA, $curpos, 0;
 }
 close $fh or $self->_croak("close(tempscript): $!");

 $self->new(
  args         => [ '-MTest::Valgrind=run,1', $file ],
  trainer_file => $file,
  @_
 );
}

=head2 C<perl>

    my $perl = $tvcp->perl;

Read-only accessor for the C<perl> option.

=cut

sub perl { $_[0]->{perl} }

=head2 C<inc>

    my @inc = $tvcp->inc;

Read-only accessor for the C<inc> option.

=cut

sub inc { @{$_[0]->{inc} || []} }

=head2 C<taint_mode>

    my $taint_mode = $tvcp->taint_mode;

Read-only accessor for the C<taint_mode> option.

=cut

sub taint_mode { $_[0]->{taint_mode} }

sub args {
 my $self = shift;

 return $self->perl,
        (('-T') x!! $self->taint_mode),
        map("-I$_", $self->inc),
        $self->SUPER::args(@_);
}

=head2 C<env>

    my $env = $tvcp->env($session);

Returns an L<Env::Sanctify> object that sets the environment variables C<PERL_DESTRUCT_LEVEL> to C<3> and C<PERL_DL_NONLAZY> to C<1> during the run.

=cut

sub env {
 Env::Sanctify->sanctify(
  env => {
   PERL_DESTRUCT_LEVEL => 3,
   PERL_DL_NONLAZY     => 1,
  },
 );
}

sub suppressions_tag {
 my ($self) = @_;

 unless (defined $self->{suppressions_tag}) {
  my $env = Env::Sanctify->sanctify(sanctify => [ qr/^PERL/ ]);

  open my $pipe, '-|', $self->perl, '-V'
                     or $self->_croak('open("-| ' . $self->perl . " -V\"): $!");
  my $perl_v = do { local $/; <$pipe> };
  close $pipe or $self->_croak('close("-| ' . $self->perl . " -V\"): $!");

  require Digest::MD5;
  $self->{suppressions_tag} = Digest::MD5::md5_hex($perl_v);
 }

 return $self->{suppressions_tag};
}

sub check_suppressions_file {
 my ($self, $file) = @_;

 {
  open my $fh, '<', $file or return 0;

  local $_;
  while (<$fh>) {
   return 1 if /^\s*fun:(Perl|S|XS)_/
            or /^\s*obj:.*perl/;
  }

  close $fh;
 }

 return 0;
}

sub filter {
 my ($self, $session, $report) = @_;

 return $report if $report->is_diag
                or not $report->isa('Test::Valgrind::Report::Suppressions');

 my @frames = grep length, split /\n/, $report->data;

 # If we see the runloop, match from here.
 my $top = List::Util::first(sub {
  $frames[$_] =~ /^\s*fun:Perl_runops_(?:standard|debug)\b/
 }, 0 .. $#frames);
 --$top if $top;

 unless (defined $top) {
  # Otherwise, match from the latest Perl_ symbol.
  $top = List::Util::first(sub {
   $frames[$_] =~ /^\s*fun:Perl_/
  }, reverse 0 .. $#frames);
 }

 unless (defined $top) {
  # Otherwise, match from the latest S_ symbol.
  $top = List::Util::first(sub {
   $frames[$_] =~ /^\s*fun:S_/
  }, reverse 0 .. $#frames);
 }

 unless (defined $top) {
  # Otherwise, match from the latest XS_ symbol.
  $top = List::Util::first(sub {
   $frames[$_] =~ /^\s*fun:XS_/
  }, reverse 0 .. $#frames);
 }

 $#frames = $top if defined $top;

 my $data = join "\n", @frames, '';

 $data = Test::Valgrind::Suppressions->maybe_generalize($session, $data);

 $report->new(
  id   => $report->id,
  kind => $report->kind,
  data => $data,
 );
}

sub DESTROY {
 my ($self) = @_;

 my $file = $self->{trainer_file};
 return unless $file and -e $file;

 1 while unlink $file;

 return;
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Command>.

L<Env::Sanctify>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Command::Perl

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Command::Perl

__DATA__
use strict;
use warnings;

BEGIN { require Test::Valgrind; }

use Test::More;

eval {
 require XSLoader;
 XSLoader::load('Test::Valgrind', $Test::Valgrind::VERSION);
};

if ($@) {
 diag $@;
 *Test::Valgrind::DEBUGGING = sub { 'unknown' };
} else {
 Test::Valgrind::notleak("valgrind it!");
}

plan tests => 1;
fail 'should not be seen';
diag 'debbugging flag is ' . Test::Valgrind::DEBUGGING();

eval {
 require XSLoader;
 XSLoader::load('Test::Valgrind::Fake', 0);
};

diag $@ ? 'Ok' : 'Succeeded to load Test::Valgrind::Fake but should\'t';

require List::Util;

my @cards = List::Util::shuffle(0 .. 51);

{
 package Test::Valgrind::Test::Fake;

 use base qw<strict>;
}

eval 'use Time::HiRes qw<usleep>';
