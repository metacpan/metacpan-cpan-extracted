#!/usr/bin/env perl

# Run this to auto generate the Util::Medley::Simple packages

use Modern::Perl;
use Data::Printer alias => 'pdump';
use Module::Load;
use Util::Medley::List;
use Util::Medley::File;
use Util::Medley::String;

my %classes = (

    # Cache => {subPrefix => 'cache'},
    Crypt    => { subPrefix => undef },
    DateTime => { subPrefix => undef },
    File     => { subPrefix => undef },
    Hash     => { subPrefix => undef },
    Hostname => { subPrefix => undef },
    List     => { subPrefix => undef },

    # Logger   => { subPrefix => undef },
    Number  => { subPrefix => undef },
    Package => { subPrefix => 'pkg' },
    Spawn   => { subPrefix => undef },
    String  => { subPrefix => undef },
    XML     => {
        subPrefix   => 'xml',
        skipMethods => [ 'xmlBeautifyString', 'xmlBeautifyFile' ]
    },
    YAML => { subPrefix => 'yaml' },
);

foreach my $className ( keys %classes ) {

    my $skipMethods = [];
    if ( $classes{$className}->{skipMethods} ) {
        $skipMethods = $classes{$className}->{skipMethods};
    }

    processClass( $className, $classes{$className}->{subPrefix}, $skipMethods );
}

########################

sub isPrivateMethod {
    my $name = shift;

    if ( $name =~ /^_/ ) {
        return 1;
    }

    return 0;
}

sub processClass {
    my $classBasename = shift;
    my $subPrefix     = shift;
    my $skipMethods   = shift;

    state $list = Util::Medley::List->new;
    state $file = Util::Medley::File->new;

    my $className = sprintf 'Util::Medley::%s', $classBasename;
    load $className;

    my @names;
    my $meta = $className->meta;
    foreach my $m ( $meta->get_all_methods ) {

        next if $m->package_name ne $className;
        next if ref($m) ne 'Moose::Meta::Method';
        next if isPrivateMethod( $m->name );
        next if $list->contains( $skipMethods, $m->name );

        push @names, $m->name;
    }

    my @sortedMethods = $list->nsort(@names);
    my $varName       = sprintf '$%s', lc($classBasename);

    my $dirname = 'lib/Util/Medley/Simple';
    $file->mkdir($dirname);

    my $simpleName = sprintf '%s::%s', 'Util::Medley::Simple', $classBasename;

    my $dest = sprintf '%s/%s.pm', $dirname, $classBasename;
    open my $fh, '>', $dest or die $!;

    print $fh getHeader( $simpleName, $className );
    print $fh getImports($className);
    print $fh getExporterEasy( \@sortedMethods, $subPrefix );
    print $fh getClassVar( $varName, $className );

    foreach my $methodName (@sortedMethods) {
        print $fh getSub( $varName, $methodName, $subPrefix );
    }

    print $fh "\n1;\n";
    close($fh);
}

sub getHeader {
    my $simpleName = shift;
    my $className  = shift;

    return "package $simpleName;\n\n",
      "#\n",
      "# Moose::Exporter exports everything into your namespace.  This\n",
      "# approach allows for importing individual functions.\n",
      "#\n",
      "\n",
      "=head1 NAME\n",
      "\n",
      "$simpleName - an exporter module for $className\n",
      "\n",
      "=cut\n",
      "\n";
}

sub getClassVar {
    my $varName   = shift;
    my $className = shift;

    return sprintf "my %s = %s->new;\n", $varName, $className;
}

sub getExporterEasy {
    my $methods = shift;
    my $prefix  = shift;

    my @methods;
    foreach my $method (@$methods) {
        push @methods, getExportedSubName( $method, $prefix );
    }

    my $methodsStr = join " ", @methods;

    my @ret;
    push @ret, "use Exporter::Easy (";
    push @ret, "    OK   => [qw($methodsStr)],";
    push @ret, "    TAGS => [";
    push @ret, "        all => [qw($methodsStr)],";
    push @ret, "    ]";
    push @ret, ");\n\n";

    return join "\n", @ret;
}

sub getImports {
    my $className = shift;

    my @imports;
    push @imports, "use Modern::Perl;";

    #    push @imports, "use Data::Printer alias => 'pdump';";
    push @imports, "use $className;\n\n";

    return join( "\n", @imports );
}

sub getExportedSubName {
    my $methodName = shift;
    my $prefix     = shift;

    state $string = Util::Medley::String->new;

    my $subName = $methodName;
    if ($prefix) {
        $subName =
          $string->camelize( $prefix . '_' . $string->snakeize($methodName) );
    }

    return $subName;
}

sub getSub {
    my $varName    = shift;
    my $methodName = shift;
    my $prefix     = shift;

    my $subName = getExportedSubName( $methodName, $prefix );

    return qq{ 
sub $subName {
    return $varName->$methodName(\@_);    
}        
    };
}
