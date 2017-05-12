package YAML::Perl;
use 5.005003;
use strict;
use warnings; # XXX requires 5.6+
use YAML::Perl::Base -base;

$YAML::Perl::VERSION = '0.02';

@YAML::Perl::EXPORT = qw'Dump Load';
@YAML::Perl::EXPORT_OK = qw'DumpFile LoadFile freeze thaw emit';

field dumper_class => -chain,
    -class => '-init',
    -init => '$YAML::Perl::DumperClass || $YAML::DumperClass || "YAML::Perl::Dumper"';
field dumper =>
    -class => '-init',
    -init => '$self->create("dumper")';

field loader_class => -chain,
    -class => '-init',
    -init => '$YAML::Perl::LoaderClass || $YAML::LoaderClass || "YAML::Perl::Loader"';
field loader =>
    -class => '-init',
    -init => '$self->create("loader")';

field resolver_class => -chain,
    -class => '-init',
    -init => '$YAML::Perl::ResolverClass || $YAML::ResolverClass || "YAML::Perl::Resolver"';
field resolver =>
    -class => '-init',
    -init => '$self->create("resolver")';

sub Dump {
    my $dumper = YAML::Perl->new()->dumper;
    $dumper->open();
    $dumper->dump(@_);
    $dumper->close;
    return $dumper->stream;
}

sub Load {
    my $loader = YAML::Perl->new->loader;
    $loader->open(@_);
    return ($loader->load());
}

{
    no warnings 'once';
    *YAML::Perl::freeze = \ &Dump;
    *YAML::Perl::thaw   = \ &Load;
}

sub DumpFile {
    my $OUT;
    my $filename = shift;
    if (ref $filename eq 'GLOB') {
        $OUT = $filename;
    }
    else {
        my $mode = '>';
        if ($filename =~ /^\s*(>{1,2})\s*(.*)$/) {
            ($mode, $filename) = ($1, $2);
        }
        open $OUT, $mode, $filename
          or YAML::Perl::Base->die('YAML_DUMP_ERR_FILE_OUTPUT', $filename, $!);
    }  
    local $/ = "\n"; # rset special to "sane"
    print $OUT Dump(@_);
}

sub LoadFile {
    my $IN;
    my $filename = shift;
    if (ref $filename eq 'GLOB') {
        $IN = $filename;
    }
    else {
        open $IN, $filename
          or YAML::Perl::Base->die('YAML_LOAD_ERR_FILE_INPUT', $filename, $!);
    }
    return Load(do { local $/; <$IN> });
}

# Ported EXPORT_OK top level functions from PyYaml

sub emit {
    my $events = shift;
    require YAML::Perl::Emitter;
    my $emitter = YAML::Perl::Emitter->new->open;
    for my $event (@$events) {
        $emitter->emit($event);
    }
    my $buffer = $emitter->writer->stream->buffer;
    $emitter->close;
    return $$buffer;
}

1;
