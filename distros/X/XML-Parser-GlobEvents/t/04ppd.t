#!/usr/bin/perl -w

use Test::More tests => 1;

# parses the DBI ppd from http://www.bribes.org/perl/ppm/DBI.ppd

use XML::Parser::GlobEvents qw(parse);

(my $file = __FILE__) =~ s/[\w.]+$/DBI.ppd/;

my $data = parse_ppd($file, 'MSWin32-x86-multi-thread-5.8');

# use Data::Dumper; print Dumper $data;

is_deeply($data,
       {
          'ABSTRACT' => 'Database independent interface for Perl',
          'ARCHITECTURE' => 'MSWin32-x86-multi-thread-5.8',
          'AUTHOR' => 'Tim Bunce (dbi-users@perl.org)',
          'CODEBASE' => 'DBI-1.604-PPM58.tar.gz',
          'NAME' => 'DBI',
          'OS' => 'MSWin32',
          'TITLE' => 'DBI',
          'VERSION' => '1,604,0,0',
          'DEPENDENCY' => [
                            {
                              'version' => '0,0,0,0',
                              'dist' => 'Scalar-List-Utils'
                            },
                            {
                              'version' => '1,0,0,0',
                              'dist' => 'Storable'
                            }
                          ]
        },
  'parsed properly');


sub parse_ppd {
    my($file, $architecture) = @_;
    my(%data, $ok);
    parse($file,
    '/SOFTPKG' => {
        Start => sub {
            my($node) = @_;
            $data{NAME} = $node->{-attr}{NAME};
            $data{VERSION} = $node->{-attr}{VERSION};
        }
    },
    '/SOFTPKG/*' => sub {
    	my($node) = @_;
	    return if $node->{-name} eq 'IMPLEMENTATION';
        $data{ $node->{-name} } = $node->{-text};
    },
    '/SOFTPKG/IMPLEMENTATION' => sub {
        my($node) = @_;
        return unless $node->{ARCHITECTURE}{-attr}{NAME} eq $architecture;
        $ok = 1;
        $data{ARCHITECTURE} = $architecture;
        $data{CODEBASE} = $node->{CODEBASE}{-attr}{HREF};
        $data{OS} = $node->{OS}{-attr}{NAME};
        $data{DEPENDENCY} = [
        	map {
                { dist => $_->{-attr}{NAME}, version => $_->{-attr}{VERSION} }
            } @{ $node->{'DEPENDENCY[]'} || [] }
          ];
    }
    );
    return $ok ? \%data : undef;
}

