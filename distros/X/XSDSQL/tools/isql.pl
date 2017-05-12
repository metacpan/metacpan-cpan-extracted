#!/usr/bin/perl

package parser;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 9

sub new {
	my ($class,%params)=@_;
	$params{LINE}=0;
	return bless \%params,$class;
}

sub get_line { return $_[0]->{LINE} + 1; }

sub debug_token {
	my ($self,$tk,%params)=@_;
	return $self unless length($tk);
	print STDERR "token <$tk> line ",$self->get_line,"\n"
		if $self->{DEBUG};
	return $self;
}
sub whitespaces {
	my ($self,$p)=@_;
	my $c=$$p;
	return '' if $c=~/^\S$/;
	my $fd=$self->{FD};
	my $b=$c;
	++$self->{LINE} if $c eq "\n";	
	while(length($c=$fd->get_char)) {
		last if $c=~/^\S$/;
		$b.=$c;
		++$self->{LINE} if $c eq "\n";
	}
	$$p=$c;
	return $b;
}

sub multiline_comment { # /*   */
	my ($self,$p)=@_;
	my $c=$$p;
	return '' if $c ne '/';
	my $fd=$self->{FD};
	my $b=$c;
	$c=$fd->get_char;
	if ($c ne '*') {
		$fd->push_back;
		return '';
	}
	$b.=$c;
	while(length($c=$fd->get_char)) {
		$b.=$c;
		++$self->{LINE} if $c eq "\n";
		if ($c eq '*') {
			$c=$fd->get_char;
			$b.=$c;
			if ($c eq '/') {
				$c=$fd->get_char;
				last;
			}
			else {
				++$self->{LINE} if $c eq "\n";
			}
		}	
	}
	$$p=$c;
	return $b;
}

sub line_comment  {  # --
	my ($self,$p)=@_;
	my $c=$$p;
	return '' if $c ne '-';
	my $fd=$self->{FD};
	my $b=$c;
	$c=$fd->get_char;
	if ($c ne '-') {
		$fd->push_back;
		return '';
	}
	$b.=$c;
	while(length($c=$fd->get_char)) {
		$b.=$c;
		if ($c eq "\n") {
			$c=$fd->get_char;
			++$self->{LINE};
			last;
		}
	}
	$$p=$c;
	return $b;	
}

sub quote_string {
	my ($self,$p)=@_;
	my $c=$$p;
	return '' unless  $c =~/^['"]$/;	#'
	my $fd=$self->{FD};
	my $b=$c;
	while(length(my $c1=$fd->get_char)) {
		$b.=$c1;
		if ($c1 eq $c) {
			my $c2=$fd->get_char;
			if ($c2 eq $c) {
				$b.=$c2;
			}
			else {
				$c=$c2;
				++$self->{LINE} if $c2 eq "\n";
				last;
			}
		}
		else {
			++$self->{LINE} if $c1 eq "\n";
		}
	}
	$$p=$c;
	return $b;
}

sub end_command {
	my ($self,$p)=@_;
	my $c=$$p;
	return $c eq $self->{SQL_TERMINATOR} ? $c : '';
}

sub next_command {
	my $self=shift;
	my $fd=$self->{FD};
	my $c=$fd->get_char;
	while(length($c)) { #skip spaces and comments
		my $tk=$self->whitespaces(\$c);
		$tk=$self->multiline_comment(\$c) unless length($tk);
		$tk=$self->line_comment(\$c) unless length($tk);
		last unless length($tk);
		$self->debug_token($tk);
	}
	my $buff='';
	while(length($c)) {
		my $tk=$self->multiline_comment(\$c);
		$buff.=$tk;
		$self->debug_token($tk);
		$tk=$self->line_comment(\$c);
		$buff.= $tk;
		$self->debug_token($tk);
		$tk=$self->quote_string(\$c);
		$buff.= $tk;
		$self->debug_token($tk);
		$tk=$self->end_command(\$c);
		$self->debug_token($tk);
		last if length($tk);
		$buff.=$c;
		++$self->{LINE} if $c eq "\n"; 				
		$c=$fd->get_char;
	}
	return $buff;	
}

sub finish {  
	my $self=shift;
	return $self;	
}

package main;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 170

use DBI;
use Getopt::Std;
use Storable;

use blx::xsdsql::ut::ut qw(:all);
use blx::xsdsql::ios::istream;
use blx::xsdsql::connection;
use blx::xsdsql::schema_repository;

use constant {
	DEFAULT_TERMINATOR	=> ';'
};

sub query {
	my ($db,$query,%params)=@_;
	my $prep=$db->prepare($query) || return;
	$prep->execute || return;
	my @cols=map  {
						{
							NAME  		=> $_
							,MAXLENGTH 	=> length($_)
						}
			}	@{$prep->{NAME}};
	my @rows=();
	while(my $r=$prep->fetchrow_arrayref) {
		if (defined $params{COLUMN_HANDLE}) {
			for my $i(0..scalar(@$r) - 1) {
				my $v=$r->[$i];
				$v='<undef>' unless defined $v;
				$cols[$i]->{MAXLENGTH} = length($v) if length($v) > $cols[$i]->{MAXLENGTH};
				$r->[$i]=$v;
			}
		}	
		push @rows,Storable::dclone($r);
	}
	$prep->finish;
	my ($fd,$separator)=($params{FD},$params{SEPARATOR});
	if (defined $fd) {
		my $header=join($separator,map {  sprintf "%-".$_->{MAXLENGTH}."s",$_->{NAME} } @cols);
		print $fd $header,"\n";
		for my $r(@rows) {
			my $row=join($separator,map {  sprintf "%-".$cols[$_]->{MAXLENGTH}."s",$r->[$_]; } (0..scalar(@cols) -1));
			print $fd  $row,"\n";
		}
	}
	return unless defined wantarray;
	my @all=(@cols,@rows);
	return wantarray ? @all : \@all;
}

sub do_query {
	my ($sql,%params)=@_;
	if ($params{DEBUG}) {
		print STDERR "-- query ",$params{SQL_COUNT}," - line ",$params{LINE},"\n";
		print STDERR $sql,"\n";
	}
	if ($params{EXECUTE}) {
		return query($params{DB},$sql,FD => *STDOUT,SEPARATOR => ' | ',COLUMN_HANDLE => 1);
	}	
	return 1;
}

sub do_other {
	my ($sql,%params)=@_;
	if ($params{DEBUG}) {
		print STDERR "-- sql command ",$params{SQL_COUNT}," - line ",$params{LINE},"\n";
		print STDERR $sql,"\n";
	}
	if ($params{EXECUTE}) {
		my $n=$params{DB}->do($sql);
		return $n unless defined $n;
		$n=0 if $n eq '0E0';
		print STDERR "rows: $n\n";
	}
	return 1;		
}

my %Opt=();
unless (getopts ('hdc:n:lat:Is:XRu',\%Opt)) {
	print STDERR "invalid option or option not set - use $0 -h for help\n";
	exit 1;
}

if ($Opt{h}) {
	print STDOUT "
		$0  [<options>]  <file>... 
		<options>: 
			-h  - this help
			-d  - emit debug info 
			-c - connect string to database - the default is the value of the env var DB_CONNECT_STRING
				otherwise is an error
			     the form is  [<output_namespace>::]<db_namespace>:<user>/<password>\@<dbname>[:<hostname>[:<port>]]>
			-l - list the know namespaces and exit with 0 
			-X - not execute sql command
			-t <r|c> - on exit issue a rollback (r) or a commit (c) 
			           the default, without errors is a commit otherwise the default is rollback
			-I - not exit after a sql error - for default at the first error  the script exit with rc <> 0
			-s <term> - sql command terminator - the default is the env var SQL_COMMAND_TERMINATOR
						else a puntuation char ';'
			-R - issue a rollback on error  
			-u - set the utf8 mode on I/O streams
		<file> - read the sql commands for <file> - the default is the stdin
		the return code is 0 for ok with commit, 1 exit after a rollback, 2 exit after a sql error 
	"; 
    exit 0;
}


if ($Opt{l}) {
	my @namespaces=blx::xsdsql::schema_repository::get_namespaces;
	print STDOUT join("\n",@namespaces),"\n";
	exit 0;
}

$Opt{c}=$ENV{DB_CONNECT_STRING} unless defined $Opt{c};
unless ($Opt{c}) { print STDERR "connection string not spec - see c option\n"; exit 1; }

my $connection=blx::xsdsql::connection->new;
unless ($connection->do_connection_list($Opt{c})) {
	print STDERR $connection->get_last_error,"\n";
	exit 1;
}

$Opt{s}=$ENV{SQL_COMMAND_TERMINATOR} unless $Opt{s};
$Opt{s}=DEFAULT_TERMINATOR unless $Opt{s};
unless ($Opt{s} =~/^[;?^~$%@#]$/) { print STDERR $Opt{s},": invalid terminator char\n"; exit 1; }
$Opt{t}='c' unless $Opt{t};
unless ($Opt{t}=~/^[cr]$/i) {  print STDERR $Opt{t},": invalid option value - see t option\n"; exit 1; }
push @ARGV,'-'  unless scalar(@ARGV);  # - is stdin
for my $file(@ARGV) { #test the files 
	if ($file ne '-') {
		if (open(my $fd,'<',$file)) {
			close $fd;
		} else {
			print STDERR "$file: $!\n";
			exit 1;
		}
	}
}

my @dbi_params=$connection->get_connection_list;
my $conn=DBI->connect(@dbi_params) || exit 1;

if ($Opt{u}) {
	unless (binmode(*STDOUT,':encoding(utf8)')) {
		print STDERR "binmode not support encoding 'utf8' on STDOUT\n";
		exit 1;
	}
	unless (binmode(*STDERR,':encoding(utf8)')) {
		print STDERR "binmode not support encoding 'utf8' on STDERR\n";
		exit 1;
	}
}

			
for my $file(@ARGV) { #test the files
	my $fd=sub {
		return *STDIN if $file eq '-';		
		if (open(my $fd,'<',$file)) {
			if ($Opt{u}) {
				unless(binmode($fd,':encoding(utf8)')) {
					print STDERR "binmode not support encoding 'utf8' on file '$file'\n";
					close $fd;
					exit 1;
				}
			}
			return $fd;
		}
		print STDERR "$file: $!\n";
		exit 1;
	}->();
	my $parse=parser->new(
		SQL_TERMINATOR => $Opt{s}
		,FD => blx::xsdsql::ios::istream->new(INPUT_STREAM => $fd,MAX_PUSHBACK_SIZE => 1)
		,DEBUG => 0
	);
	my $sql_count=0;
	while(my $sql=$parse->next_command) {
		my %p=(
			DB => $conn
			,SQL_COUNT => $sql_count++
			,DEBUG => $Opt{d}
			,LINE => $parse->get_line
			,EXECUTE => !$Opt{X}
		);
		my $r=$sql=~/^select\s/i ? do_query($sql,%p) : do_other($sql,%p); 
		unless ($r) {
			print STDERR $file,":",$parse->get_line,"\n",$sql,"\n",$conn->errstr,"\n";
			unless ($Opt{I}) {
				$conn->rollback unless $conn->{AutoCommit};
				$conn->disconnect;
				exit 2;
			}
			$conn->rollback if $Opt{R};
			$Opt{t}='r';			
		} 
	}
	close $fd;
	$parse->finish;
}

unless ($conn->{AutoCommit}) {
	$Opt{t} eq 'c' ? $conn->commit : $conn->rollback;
}
$conn->disconnect;

exit ($Opt{t} eq 'c' ? 0 : 1);

__END__

=head1 NAME isql.pl

=cut


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
