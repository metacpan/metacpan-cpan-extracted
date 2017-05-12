package WSST;

use strict;
use base qw(Exporter);
use vars qw($VERSION @EXPORT);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use WSST::SchemaParserManager;
use WSST::Generator;

$VERSION = '0.1.1';

@EXPORT = qw(generate help version dumpschema);

sub generate {
    my $opts = {};
    GetOptions($opts,
               "outdir|o=s",
               "lang|l=s@",
               "var|v=s@");

    my $path = shift(@ARGV);
    die "not specified schema" unless $path;
    die "cannot read schema: '$path'" unless -r $path;
    
    my $odir = $opts->{outdir} || 'output';
    die "invalid output dir: '$odir'" unless -d $odir;
    
    my $spm = WSST::SchemaParserManager->instance;
    my $sp = $spm->get_schema_parser($path);
    my $schema = $sp->parse($path);
    
    my $g = WSST::Generator->new();
    
    $opts->{lang} ||= $g->generator_names;
    
    foreach my $gn (@{$opts->{lang}}) {
        print "[$gn]\n";
        my $paths = $g->generate($gn, $schema, $opts);
        print join("\n", @$paths), "\n\n";
    }
}

sub help {
    pod2usage(input=>$INC{'WSST.pm'});
}

sub version {
    print "WSST $WSST::VERSION\n";
    print "Copyright 2008 WSS Project Team\n";
    print "\n";

    no strict 'refs';
    my $list = [map {$WSST::{$_}} sort grep {/::$/} keys %WSST::];
    while (my $ent = shift(@$list)) {
        my $cls = "$ent";
        next if $cls =~ /ISA::CACHE::$/;
        $cls =~ s/^\*//;
        $cls =~ s/::$//;
        print "${cls}: ";
        if (${$ent}{VERSION}) {
            print ${${$ent}{VERSION}}, "\n";
        } else {
            print "(NO VERSION)\n";
        }
        push(@$list, map {${$ent}{$_}} sort grep {/::$/} keys %{$ent});
    }
}

sub dumpschema {
    my $path = shift(@ARGV);
    die "not specified schema" unless $path;
    die "cannot read schema: '$path'" unless -r $path;
    
    my $spm = WSST::SchemaParserManager->instance;
    my $sp = $spm->get_schema_parser($path);
    my $schema = $sp->parse($path);

    require Data::Dumper;
    print Data::Dumper::Dumper($schema);
}

=head1 NAME

WSST - WebService Specification Schema Tool(WSST)

=head1 SYNOPSIS

perl -MWSST -e command [wss_file] [options]

 Commands:
   generate         generate modules
   help             print help message
   version          print version message
   dumpschema       dump schema object

 Options of generate command:
   -o --outdir=dir      set the output directory
   -l --lang=lang       specify a generate language
   -v --var="name=val"  set a variable

=head1 OPTIONS

=over 8

=item B<-o,--outdir>

Set the output directory. (default="output")

=item B<-l,--lang>

Specify a generate language.

=item B<-v,--var>

Set a variable.
This variable can be used from Template.

=back

=head1 DESCRIPTION

WSST is a tool to generate libraries which manipulate web service.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
