#!/usr/bin/perl -w

# parses the DBI ppd from http://www.bribes.org/perl/ppm/DBI.ppd

use XML::Parser::GlobEvents qw(parse);

(my $file = __FILE__) =~ s/[\w.]+$/DBI.ppd/;

my $data = parse_ppd($file);

use Data::Dumper; print Dumper $data;

sub parse_ppd {
    my($file, $architecture) = @_;
    my %data;
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
        my %info;
        $info{ARCHITECTURE} = $node->{ARCHITECTURE}{-attr}{NAME};
        $info{CODEBASE} = $node->{CODEBASE}{-attr}{HREF};
        $info{OS} = $node->{OS}{-attr}{NAME};
        $info{DEPENDENCY} = [
        	map {
                { dist => $_->{-attr}{NAME}, version => $_->{-attr}{VERSION} }
            } @{ $node->{'DEPENDENCY[]'} || [] }
          ];
        $data{IMPLEMENTATIONS}{ $node->{ARCHITECTURE}{-attr}{NAME} } = \%info;
    }
    );
    return \%data;
}

