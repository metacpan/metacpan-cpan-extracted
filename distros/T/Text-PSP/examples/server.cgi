#!/usr/bin/perl -wT
use strict;
use Text::PSP;
use CGI;
use CGI::HTMLError trace => 1;

my $psp = Text::PSP->new(
	templatedir => '/home/joost/templates',
	workdir => '/home/joost/pspserver/work',
);

my $q = CGI->new;
$ENV{PATH_INFO} ||= 'index.psp';
$ENV{PATH_INFO} =~ /^(([\/.]?\w+)+)$/;
my $path = $1;
die "Not a valid file" if $path eq '';
my $template = $psp->template($path);
my $out = $template->run( headers => [] );
print $template->{headers} ? @{$template->{headers}} : $q->header;
print @$out;

1;


