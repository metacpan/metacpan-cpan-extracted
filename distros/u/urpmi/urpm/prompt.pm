package urpm::prompt;


use strict;

sub new {
    my ($class, $title, $prompts, $defaults, $hidden) = @_;
    bless {
	title => $title,
	prompts => $prompts,
	defaults => $defaults,
	hidden => $hidden,
    }, $class;
}

sub write {
    my (undef, $msg) = @_;
    print STDOUT $msg;
}

sub prompt {
    my ($self) = @_;
    my @answers;
    $self->write($self->{title});
    foreach my $i (0 .. $#{$self->{prompts}}) {
	$self->write($self->{prompts}[$i]);
	$self->{hidden}[$i] and system("/bin/stty", "-echo");
	my $input = <STDIN>;
	$self->{hidden}[$i] and do { system("/bin/stty", "echo"); $self->write("\n") };
	defined $input or return @answers;
	chomp $input;
	$input eq '' and $input = defined $self->{defaults}[$i] ? $self->{defaults}[$i] : '';
	push @answers, $input;
    }
    @answers;
}

1;


=head1 NAME

urpm::prompt - base class to prompt the user for data

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
