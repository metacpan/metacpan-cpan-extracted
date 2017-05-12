package Blosxom::Publish;

use strict;
use warnings;

use Error;
use Net::FTP;

use Twitter::Daily::Blog::Base;
use Exporter();
our (@ISA, $VERSION);
@ISA = qw(Exporter Twitter::Daily::Blog::Base);

$VERSION = "0.0.2";

use constant DEBUG_STR => "debug (" . __PACKAGE__ . ") => ";
use constant NO_DEBUG => 0;

use constant BASE_FOLDER => '/blosxom/entries';
use constant EXT_DEFAULT => 'txt';

use constant EXIT_ERROR => 0;
use constant EXIT_NO_ERROR => 1;

use constant ERR_NO_ERROR => "";
use constant ERR_NO_ERROR_NUM => 0;
use constant ERR_NO_USER_PWD => "User or password was not supplied";
use constant ERR_NO_USER_PWD_NUM => 1;
use constant ERR_NO_FTP_NUM => 2;
use constant ERR_NO_FTP_LOGIN => "Can't login : ";
use constant ERR_NO_FTP_LOGIN_NUM => 3;
use constant ERR_NO_FILENAME => "No filename parameter was passed";
use constant ERR_NO_FILENAME_NUM => 4;
use constant ERR_NO_CATEGORY => "No categoty parameter was passed";
use constant ERR_NO_CATEGORY_NUM => 5;
use constant ERR_NO_STORY => "No story parameter was passed";
use constant ERR_NO_STORY_NUM => 6;
use constant ERR_NO_FTP_PUT => "Can't store story in Blosxom site : ";
use constant ERR_NO_FTP_PUT_NUM => 7;

=pod

=head1 NAME

Blosxom::Publish - Publish stories in a Blosxom aware blog

=head1 VERSION

This document describes Blosxom::Publish v0.0.alpha

=head1 SYNOPSIS

 my $blosxom = Blosxom::Publish->new( server => 'myhost.mydomain.com' )
    || die ( "Can't instantiate Blosxom::Publish" );
    
 $blosxom->login( user => $user, password => $pwd )
    || die("Can't login to Blosxom server : " . $blosxom->errMsg );

 ## load the file path containing the story in $storyPath, giving that
 ## 1) destination filename (the one in the Blosxom site) corresponds to
 ## the name of the file in which the story will be stored and 
 ## 2) $category to the story category
 
 my $storyPath = '/home/bit-man/firstPost.txt';
 my $category = '/Misc/test';
 my $filename = 'newPost.txt';

 ## The story will be read from the local file  
 ## '/home/bit-man/firstPost.txt' and published under the category 
 ## '/Misc/test' in Blosxom, using the filename 'newPost.txt'
 
 $blosxom->publish( $filename, $category, $storyPath  )
      || die "Cannot publish story : " . $blosxom->errMsg;

 $blosxom->quit;
 
=head1 DESCRIPTION 

Blosxom (pronounced "blossom") is a lightweight yet feature-packed weblog 
application designed from the ground up with simplicity, usability, and 
interoperability in mind. 

This module allows the entries publishing in Blosxom aware blogs where 
the entries can be accessed using the FTP protocol. In the future more
mthods will be used.

=head1 INTERFACE

All methods return 1 on success or 0 in failure, and in such case the method
errMsg() returns an error description in English language, and errNumber() returns
the corresponding error number in case you don't want to print the description in
English of the error

=head2 new

Create a new Blosxom::Publish object.

=head3 options

=over 1

=item * server (mandatory)

specifies the FTP server to access the Blosxom files

=item * base

folder containing the stories. If not specified then '/blosxom/plugins' is
assumed as the base location for Blosxom posts


=item * category  (mandatory)

category where to pulish the enrty to

=item * ext

filename extension (a.k.a ending part) for Blosxom published files.
(default .txt)

=item * debug

set the flag to allow printing of debug messages (no implemented yet)

=back

=cut

sub new {
    my $class = shift;
    my %option = @_;

    my $self;
    
    $self->{'server'} = $option{'server'} || return undef;
    $self->{'base'} = $option{'base'} || BASE_FOLDER;
    $self->{'category'} = $option{'category'} || return undef;
    $self->{'ext'} = $option{'ext'} || EXT_DEFAULT;
    

    $self->{'debug'} = $option{'debug'} || NO_DEBUG;
    $self->{'errMsg'} = "";
    $self->{'errNumber'} = 0;

    if ( $option{'debug'} ) {
        foreach my $key ( keys %$self ) {
            print DEBUG_STR . "$key : " . $self->{$key} . "\n";
        };
    };

    return bless $self, $class;
};

=pod

=head2 login

Logins to the server where Blosxom is hosted

=head3 options

=over 1

=item * user

mandatory option that specifies the user to connect to the server

=item * password

mandatory option that specifies the password to connect to the server

=back

These options refer not to the Blosxom user/password (in case you have it
password protected) but to the ones to access the server using FTP.
Commonly the same one your hoster gives you tu upload your HTML or CGI files

=cut

sub login {
    my $self = shift;
    my %option = @_;

    ## new code
    ## call  $self->{'publishTo'}->login() and $self->{'publishTo'}->login() simpler !!!
    
	if ( ! defined $option{'user'} || ! defined $option{'password'}  ) {
		$self->_setError(ERR_NO_USER_PWD, ERR_NO_USER_PWD_NUM);
		return EXIT_ERROR;
	};
	
	$self->{'ftp'} = Net::FTP->new( $self->{'server'}, Debug => 0 ) 
    	or do {
        	$self->_setError( $@, ERR_NO_FTP_NUM);
        	return EXIT_ERROR;
      	};
      	
	$self->{'ftp'}->login( $option{'user'}, $option{'password'} )
		|| do {
			$self->_setError(ERR_NO_FTP_LOGIN . $self->{'ftp'}->message, ERR_NO_FTP_LOGIN_NUM);
        	return EXIT_ERROR;
		};
	
	$self->_setError(ERR_NO_ERROR, ERR_NO_ERROR_NUM);
	return 1;
};

=pod

=head2 publish

Publishes the given story

=head3 options

=over 1

=item * filename

mandatory option that specifies the remote story filename in the Blosxom site.
WARNING: if the file exists in the given category it will be overwriten

=item * category

mandatory option that specifies the Blosxom category for the new story

=item * filePath

mandatory option that specifies the local file path where the story is located

=back

=cut

sub publish {
	my $self = shift;
	my $filePath = shift || do {
		$self->_setError(ERR_NO_FILENAME, ERR_NO_FILENAME_NUM);
        return EXIT_ERROR;
	};
	
	my @path = split /\//, $filePath;
	
	my $filename = $path[ @path - 1 ] . '.' . $self->{'ext'};
	
	## TODO check if the file exists and that base/category path is a valid one
	## TODO chech if that path contains valid chars
	my $remotePath = $self->{'base'} .'/' . $self->{'category'} . '/' . $filename;
	$self->{'ftp'}->put( $filePath, $remotePath ) || do {
		$self->_setError(ERR_NO_FTP_PUT . $self->{'ftp'}->message, ERR_NO_FTP_PUT_NUM);
        return EXIT_ERROR;
	};
	
	$self->_setError(ERR_NO_ERROR, ERR_NO_ERROR_NUM);
	return 1;
}

=head2 quit

Ends the publishing process

=cut

sub quit {
	my $self = shift;
	
	## new code
	## call  $self->{'publishTo'}->quit()
	
        if ( $self->{'ftp'} ) {
	    $self->{'ftp'}->quit();
	    $self->_setError(ERR_NO_ERROR, ERR_NO_ERROR_NUM);
        }
}

=head2 errMsg

Returns the last error message in English language.
Will return an empty string if the last operation ended successfuly

=cut

sub errMsg {
	return $_[0]->{'errMsg'};
}

=head2 errNumber

Returns the last error number.
Will return zero if the last operation ended successfuly

=cut

sub errNumber {
	return $_[0]->{'errNumber'};
}

sub _setError {
	my $self = shift;

	$self->{'errMsg'} = $_[0];
	$self->{'errNumber'} = $_[1];
}

1;
