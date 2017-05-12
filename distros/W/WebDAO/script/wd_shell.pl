#!/usr/bin/perl
#===============================================================================
#
#         FILE: wd_shell.pl
#
#  DESCRIPTION:  shell script for WebDAO project
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================
package WebDAO::Shell::Writer;

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}
sub write   { print $_[1] }
sub close   { }
sub headers { }

package main;
use strict;
use warnings;
use Carp;
use WebDAO;
use WebDAO::SessionSH;
use WebDAO::CV;
use Data::Dumper;
use WebDAO::Lex;
use Getopt::Long;
use Pod::Usage;
use WebDAO::Util;
use MIME::Base64;

my ( $help, $man, $sess_id, $dump_headers );
my %opt = ( help => \$help, man => \$man, sid => \$sess_id, d=>\$dump_headers );
my @urls = ();
GetOptions( \%opt, 'help|?', 'man', 'd', 'f=s', 'wdEngine|M=s', 'wdEnginePar=s', 'c=s', 'u=s',
    'sid|s=s', '<>' => sub { push @urls, shift } )
  or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

if ($opt{u}) {
      $ENV{"HTTP_AUTHORIZATION"} =
      " " . encode_base64($opt{u});
}
my $evl_file = shift @urls;
pod2usage( -exitstatus => 2, -message => 'No path give or non exists ' )
  unless $evl_file;

#cut params from command line
( $ENV{PATH_INFO}, $ENV{QUERY_STRING} ) = split( /\?/, $evl_file );
$evl_file = $ENV{PATH_INFO};

foreach my $sname ('__DIE__') {
    $SIG{$sname} = sub {
        return if ( caller(1) )[3] =~ /eval/;
        push @_, "STACK:" . Dumper( [ map { [ caller($_) ] } ( 1 .. 3 ) ] );
        print STDERR "PID: $$ $sname: @_";
      }
}

$ENV{wdEngine} ||= $opt{wdEngine} || 'WebDAO::Engine';
$ENV{wdEnginePar} ||= $opt{wdEnginePar};
#overwrite wdEnginePar with config=...
if ( $opt{c} ) {
    $ENV{wdEnginePar}='config='.$opt{c};
}
$ENV{wdSession} ||= 'WebDAO::SessionSH';
$ENV{wdShell} = 1;
my $ini = WebDAO::Util::get_classes( __env => \%ENV, __preload => 1 );

#Make Session object
my $cv = WebDAO::CV->new(
    env    => \%ENV,
    writer => sub {
        my $fd = new WebDAO::Shell::Writer::
          status  => $_[0]->[0],
          headers => $_[0]->[1];
        my $str;
        if ( $dump_headers ) {
           while (my ($h, $v) = splice (@{$_[0]->[1]}, 0, 2 ) )   {
            $str .= "$h: $v\n"
           }
           $str.="\n\n";
           $fd->write($str)
        }
        return $fd;
    }
);

my $sess = "$ini->{wdSession}"->new(
    %{ $ini->{wdSessionPar} },
    cv    => $cv,
);

$sess->U_id($sess_id);

my $filename = exists $opt{f} ? $opt{f} : $ENV{wdIndexFile};

my %engine_args = ();
if ( $filename && $filename ne '-' ) {
    unless ( -r $filename && -f $filename ) {
        warn <<TXT;
ERR:: file not found or can't access (wdIndexFile): $filename
check -f option or env variable wdIndexFile;
TXT
        exit 1;
    }

    open FH, "<$filename" or die $!;
    my $content = '';
    {
        local $/ = undef;
        $content = <FH>;
    }
    close FH;
    my $lex = new WebDAO::Lex:: tmpl => $content;
    $engine_args{lex} = $lex;
}
my $eng = "$ini->{wdEngine}"->new(
    %{ $ini->{wdEnginePar} },
    session => $sess,
    %engine_args
);

$sess->ExecEngine( $eng, $evl_file );
$sess->destroy;
croak STDERR $@ if $@;
print "\n";

=head1 NAME

  wd_shell.pl  - command line tool for developing and debuging

=head1 SYNOPSIS

  wd_shell.pl [options] /some/url/query
  wd_shell.pl [options] '/some/url/query?param1=1'

   options:

    -help  - print help message
    -man   - print man page
    -f file    - set root [x]html file 
    -d     - dump HTTP headers
    -u login:password    - set HTTP_AUTHORIZATION variable

   examples:
    
    wd_shell.pl -wdEngine Test  -wdEnginePar config=../test.ini /some/url/query
    wd_shell.pl -M Test -c ../test.ini /some/url/query #the same


=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits

=item B<-man>

Prints manual page and exits

=item B<-f> L<filename>

Set L<filename> set root [x]html file  for load domain

=back

=head1 DESCRIPTION

B<wd_shell.pl>  - tool for debug .

=head1 SEE ALSO

http://sourceforge.net/projects/webdao, WebDAO

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2000-2013 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

