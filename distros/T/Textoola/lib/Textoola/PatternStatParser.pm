# PODNAME: Textoola::PatternStatParser
# ABSTRACT: Class to parse text into pattern-tokenline and creating at counting-hash of pattern-tokenline.

use strict;
use warnings;
use v5.14;

package Textoola::PatternStatParser;
$Textoola::PatternStatParser::VERSION = '0.003';
sub new {
    my $class = shift;
    my %args  = @_;

    my $self={
	separator       => '\s',
	separator_subst => ' ',
	path            => $args{path},
	patternstats    => {},
    };

    bless $self, $class;
    return $self;
}

sub parse_line {
    my $self = shift;
    my $line = shift;

    chomp $line;
    my $sep      = $self->{separator};
    my $sepsub   = $self->{separator_subst};
    my $patstats = $self->{patternstats};
    my @tokens   = split /$sep/,$line;

    my $pattern;
    if (scalar(@tokens)) {
	$pattern //= shift @tokens;
	$patstats->{$pattern}++;
	
	while (scalar(@tokens)) {
	    $pattern .= $sepsub.shift @tokens;
	    $patstats->{$pattern}++;
	}
    }
}

sub parse {
    my $self = shift;
    my $path = $self->{path};
    
    my $fh;
    if (defined $path) {
	open($fh,"<",$path) or die "File $path not found";
    } else {
	$fh=*STDIN;
    }

    while(my $line=<$fh>) {
	$self->parse_line($line);
    }
    
    close $fh;
}

sub patternstats {
    my $self = shift;
    return $self->{patternstats};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Textoola::PatternStatParser - Class to parse text into pattern-tokenline and creating at counting-hash of pattern-tokenline.

=head1 VERSION

version 0.003

=head1 AUTHOR

Sascha Dibbern <sacha@dibbern.info>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Sascha Dibbern.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
