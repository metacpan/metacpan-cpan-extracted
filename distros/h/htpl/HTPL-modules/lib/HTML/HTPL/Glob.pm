package HTML::HTPL::Glob;
use Symbol;
use strict;
use HTML::HTPL::Orig;
use HTML::HTPL::Result;

sub files {
	my ($base, $col) = @_;
	&create(1, @_);
}

sub dirs {
	my ($base, $col) = @_;
	&create(0, @_);
}

sub create {
	my ($files, $base, $col) = @_;
	my $sym = gensym;
	opendir($sym, $base);
	my $orig = new HTML::HTPL::Glob::Files($sym, $files, $base);
	my $result = new HTML::HTPL::Result($orig, $col);
	$result;
}

sub tree {
	my ($base, $col) = @_;
	require File::FTS;
	my $fts = new File::FTS($base);
	my $orig = new HTML::HTPL::Glob::FTS($fts);
	my $result = new HTML::HTPL::Result($orig, $col);
	$result
}

package HTML::HTPL::Glob::Files;

use HTML::HTPL::Lib;
use vars qw(@ISA);
@ISA = qw(HTML::HTPL::Orig);

sub new {
	my ($class, $fd, $files, $base) = @_;
	bless {'fd' => $fd, 'files' => $files, 
		 'base' => $base}, $class;
}

sub realfetch {
	my $self = shift;
	return undef unless $self->{'fd'};
	my $candidate;
	while ($candidate = readdir($self->{'fd'})) {
		my $abs = $self->{'base'} . &slash . $candidate;
		my $bit = -d $abs ? 1 : 0;
		next if $bit == $self->{'files'};
		last;
	}
	return [$candidate] if $candidate;
	close($self->{'fd'});
	delete $self->{'fd'};	
	undef;
}

package HTML::HTPL::Glob::FTS;

use vars qw(@ISA);
@ISA = qw(HTML::HTPL::Orig);

sub new {
	my ($class, $fts) = @_;
	bless {'fts' => $fts}, $class;
}

sub realfetch {
	my $self = shift;
	my $fts = $self->{'fts'};
	my $candidate = $fts->Dive;
	return [$candidate] if $candidate;
	undef;
}

1;
