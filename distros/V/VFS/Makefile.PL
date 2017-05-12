use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'VFS',
	VERSION_FROM	=> 'lib/VFS.pm',
	ABSTRACT_FROM	=> "lib/VFS.pm",
	AUTHOR			=> 'Shevek <cpan@anarres.org>',
	PREREQ_PM		=> { },
);

sub MY::postamble {
	my $self = shift;
	my $old = $self->MM::postamble(@_);
	chomp($old);
	my $new = <<'EON';

.PHONY : aux readme

aux : readme

readme : lib/VFS.pm
	perldoc -t lib/VFS.pm > README

EON
	return $old . $new;
}

1;
