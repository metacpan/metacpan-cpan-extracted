package MyInstall;

use ExtUtils::Install;
use File::Find;

use vars qw (@ISA @EXPORT @EXPORT_OK);

@ISA = @ExtUtils::Install::ISA;
@EXPORT = @ExtUtils::Install::EXPORT;
@EXPORT_OK = @ExtUtils::Install::EXPORT_OK;

sub ExtUtils::Install::directory_not_empty ($) {
	my($dir) = @_;

	return 0 if $dir eq 'blib/arch';

	my $files = 0;
  	find(sub {
        	return if $_ eq ".exists";
           	if (-f) {
             		$File::Find::prune++;
             		$files = 1;
           	}
       	}, $dir);
  	return $files;
}

sub AUTOLOAD
{
        print STDERR "AUTOLOAD: $AUTOLOAD\n";
                                                                                
        my $name = 'func';
        my $code;
        my $string = "\$code = \\&ExtUtils::Install::$name";
                                                                                
        eval $string;
        *$AUTOLOAD = $code;
                                                                                
        goto &$AUTOLOAD;
}

1;

