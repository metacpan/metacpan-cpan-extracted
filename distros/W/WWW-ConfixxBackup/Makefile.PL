use 5.006001;
use ExtUtils::MakeMaker;

for $i(0..scalar(@ARGV)-1){
  if($ARGV[$i] =~ /^--userfile$/){
    if(open(my $fh,">",'./t/userfile.txt')){
      if(open(my $read,"<",$ARGV[$i+1])){
        while(my $line = <$read>){
          print $fh $line;
        }
        close $read;
      }
      close $fh;
    }
    else{
      warn "Can't write userfile";
    }
  }
}

WriteMakefile(
    NAME              => 'WWW::ConfixxBackup',
    VERSION_FROM      => 'lib/WWW/ConfixxBackup.pm', # finds $VERSION
    PREREQ_PM         => {
                           WWW::Mechanize      => 0,
                           Net::FTP            => 0,
                           HTTP::Cookies       => 0,
                           Test::CheckManifest => 1.0,
                           Test::More          => 0,
                           FindBin             => 0,
                           B                   => 0,
                           Devel::Symdump      => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/ConfixxBackup.pm', # retrieve abstract from module
       AUTHOR         => 'Renee Baecker <module@renee-baecker.de>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE        => 'perl') : ()),
);
