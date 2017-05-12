package App::Rgit::Policy::Interactive;

use strict;
use warnings;

use Cwd ();

use App::Rgit::Utils qw/:codes/;

use base qw/App::Rgit::Policy/;

=head1 NAME

App::Rgit::Policy::Interactive - A policy that asks what to do on error.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 DESCRIPTION

When a run exited with non-zero status, this policy asks the user whether he wants to ignore and continue with the next repository, ignore all future possible errors, retry this run or open a shell in the current repository.
In this last case, the user will be asked again what to do when he will close the shell.

=head1 METHODS

This class inherits from L<App::Rgit::Policy>.

It implements :

=head2 C<new>

The constructor will die if L<Term::ReadKey> can't be loaded.

=cut

my ($int_code, $shell);

sub new {
 my $class = shift;
 $class = ref $class || $class;

 eval "require Term::ReadKey"
      or die "You have to install Term::ReadKey to use the interactive mode.\n";

 unless (defined $int_code) {
  $int_code = { Term::ReadKey::GetControlChars() }->{INTERRUPT};
 }

 unless (defined $shell) {
  for (grep defined, $ENV{SHELL}, '/bin/sh') {
   if (-x $_) {
    $shell = $_;
    last;
   }
  }
 }

 $class->SUPER::new(@_);
}

=head2 C<handle>

=cut

my %codes = (
 'a' => [ LAST,        'aborting' ],
 'i' => [ NEXT,        'ignoring' ],
 'I' => [ NEXT | SAVE, 'ignoring all' ],
 'r' => [ REDO,        'retrying' ],
);

sub handle {
 my ($policy, $cmd, $conf, $repo, $status, $signal) = @_;

 return NEXT unless $status;

 while (1) {
  $conf->warn("[a]bort, [i]gnore, [I]gnore all, [r]etry, open [s]hell ?");

  Term::ReadKey::ReadMode(4);
  my $key = Term::ReadKey::ReadKey(0);
  Term::ReadKey::ReadMode(1);

  $conf->warn("\n");

  next unless defined $key;

  if ($key eq $int_code) {
   $conf->warn("Interrupted, aborting\n");
   return LAST;
  } elsif ($key eq 's') {
   if (defined $shell) {
    $conf->info('Opening shell in ', $repo->work, "\n");
    my $cwd = Cwd::cwd;
    $repo->chdir;
    system { $shell } $shell;
    chdir $cwd;
   } else {
    $conf->err("Couldn't find any shell\n");
   }
  } elsif (exists $codes{$key}) {
   my $code = $codes{$key};
   $conf->info('Okay, ', $code->[1], "\n");
   return $code->[0];
  }
 }
}

=head1 SEE ALSO

L<rgit>.

L<App::Rgit::Policy>.

L<Term::ReadKey>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-rgit at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=rgit>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Rgit::Policy::Interactive

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of App::Rgit::Policy::Interactive
