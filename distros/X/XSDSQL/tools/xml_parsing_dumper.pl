#!/usr/bin/perl

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use Getopt::Std;
use XML::Parser;
use File::Basename;

my %Opt=();


sub x {
	my ($cmd,$expat,@r)=@_;
	print STDOUT "$cmd: ",Dumper(\@r),"\n";
}



my %H=(
		Start => sub { x("Start",@_); }
		,End => sub { x("End",@_); }
		,Char => sub { x("Char",@_); }
		,Proc => sub { x("Proc",@_); }
		,Comment => sub { x("Comment",@_); }
		,CdataStart => sub { x("CdataStart",@_); }
		,CdataEnd => sub { x("CdataEnd",@_); }
		,Default => sub { x("Default",@_); }
#		,Unparsed => sub { x("Unparsed",@_); }
		,Notation => sub { x("Notation",@_); }
		,ExternEnt => sub { x("ExternEnt",@_); }
		,ExternEntFin => sub { x("ExternEntFin",@_); }
		,Entity => sub { x("Entity",@_); }
		,Element => sub { x("Element",@_); }
		,Attlist => sub { x("Attlist",@_); }
		,Doctype => sub { x("Doctype",@_); }
		,DoctypeFin => sub { x("DoctypeFin",@_); }
		,XMLDecl => sub { x("XMLDecl",@_); }
);


unless (getopts ('hi',\%Opt)) {
	print STDERR "option error\n";
	exit 1;
}

if ($Opt{h}) {
	print STDOUT "".basename($0)."  [<options>]  [<args>]..   
crossing an xml and print on stderr the handlers name and data 
    <options>: 
        -h  - this help
		-i  - use custom XML::Parser otherwise the standard XML::Parser
    <args>:
        <xml_file>...  - read files 
\n"; 
    exit 0;
}

if ($Opt{i}) {
	eval("use lib qw(../lib)"); ## no critic
	croak $@ if $@;
}

my $p=XML::Parser->new(Namespaces	=> 0,MYPARAM => 'myparam');
$p->setHandlers(%H);


my @files=@ARGV;

push @files,'-' unless scalar(@files);

for my $f(@files) {
	my $tag_file=scalar(@files) < 2  ? "" : "$f "; 
	my $fd=$f eq '-' ? *STDIN : undef;
	if (defined $fd || open($fd,'<',$f)) {
		$p->parse($fd,MY_PARSE_PARAM => 1);
		close($fd) if $f ne '-';
	}
	else {
		print STDERR "$f: open error: $!\n";
		exit 2;
	}
}

exit 0;


__END__

=head1 NAME xml_parsing_dumper.pl

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
