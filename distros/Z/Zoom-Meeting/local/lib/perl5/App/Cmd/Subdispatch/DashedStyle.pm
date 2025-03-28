use strict;
use warnings;

package App::Cmd::Subdispatch::DashedStyle 0.335;

use App::Cmd::Subdispatch;
BEGIN { our @ISA = 'App::Cmd::Subdispatch' };

# ABSTRACT: "app cmd --subcmd" style subdispatching

#pod =method get_command
#pod
#pod   my ($subcommand, $opt, $args) = $subdispatch->get_command(@args)
#pod
#pod A version of get_command that chooses commands as options in the following
#pod style:
#pod
#pod   mytool mycommand --mysubcommand
#pod
#pod =cut

sub get_command {
	my ($self, @args) = @_;

	my (undef, $opt, @sub_args)
    = $self->App::Cmd::Command::prepare($self->app, @args);

	if (my $cmd = delete $opt->{subcommand}) {
		delete $opt->{$cmd}; # useless boolean
		return ($cmd, $opt, @sub_args);
	} else {
    return (undef, $opt, @sub_args);
  }
}

#pod =method opt_spec
#pod
#pod A version of C<opt_spec> that calculates the getopt specification from the
#pod subcommands.
#pod
#pod =cut

sub opt_spec {
	my ($self, $app) = @_;

	my $subcommands = $self->_command;
	my %plugins = map {
		$_ => [ $_->command_names ],
	} values %$subcommands;

	foreach my $opt_spec (values %plugins) {
		$opt_spec = join("|", grep { /^\w/ } @$opt_spec);
	}

	my @subcommands = map { [ $plugins{$_} =>  $_->abstract ] } keys %plugins;

	return (
		[ subcommand => hidden => { one_of => \@subcommands } ],
		$self->global_opt_spec($app),
		{ getopt_conf => [ 'pass_through' ] },
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cmd::Subdispatch::DashedStyle - "app cmd --subcmd" style subdispatching

=head1 VERSION

version 0.335

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 get_command

  my ($subcommand, $opt, $args) = $subdispatch->get_command(@args)

A version of get_command that chooses commands as options in the following
style:

  mytool mycommand --mysubcommand

=head2 opt_spec

A version of C<opt_spec> that calculates the getopt specification from the
subcommands.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
