package XUL::App::XULFile;

use lib 'lib';
use strict;
use warnings;
use File::Slurp;
use Encode;
#use Smart::Comments;
use XUL::App;
use File::ShareDir ();
use File::Copy ();
use File::Basename 'dirname';
#use File::Path ();
use File::Copy::Recursive ();

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw{
    name generated_from prereqs overlays
});

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    my $src = $self->generated_from;
    my ($module, $opts);
    if (ref $src eq 'HASH') {
        ($module, $opts) = %$src;
    } elsif (ref $src) {
        ($module, $opts) = @$src;
    } else {
        $module = $src;
        $opts = {};
    }
    $self->{module} = $module;
    $self->{template} = delete $opts->{template} || 'main';
    my $args = delete $opts->{arguments} || [];
    if (ref $args ne 'ARRAY') { $args = [$args]; }
    $self->{args} = $args;
    if (%$opts) {
        die "Unknown option for view class $self->{template}: ", join(" ", keys %$opts);
    }
   return $self;
}

sub go {
    my ($self, $file) = @_;
    my $module = $self->{module};
    my $args = $self->{args};
    my $template = $self->{template};
    eval "use $module;";
    if ($@) {
        warn $@;
        die "Can't load $module due to compilation errors.\n";
    }
    Template::Declare->init(roots => [$module]);
    # XXX $opts->{template}, $opts->{arguments}
    mkdir 'tmp' if !-d 'tmp';
    mkdir 'tmp/content' if !-d 'tmp/content';
    my @all_prereqs = find_all_prereqs($file);
    ### @all_prereqs
    my $xml = Template::Declare->show($template, @$args);
    my (@jsfiles, @cssfiles);
    for my $file (@all_prereqs) {
        if ($file =~ /\.js$/i) {
            push @jsfiles, $file;
        } else {
            push @cssfiles, $file;
        }
    }
    my $last_tag_pat = qr{ </ [^>]+ > \s* $}xs;
    for my $file (@jsfiles) {
        if ($file !~ /^\w+:\/\//) {
            check_js_file($file);
            $file = "chrome://$XUL::App::APP_NAME/content/$file";
        }
        $xml =~ s{$last_tag_pat}{<script src="$file" type="application/javascript;version=1.7"/>\n$&};
    }
    my $first_tag_pat = qr{ .* <\? [^>]+ \?> }xs;
    for my $file (reverse @cssfiles) {
        if ($file !~ /^\w+:\/\//) {
            check_css_file($file);
            $file = "chrome://$XUL::App::APP_NAME/content/$file";
        }
        $xml =~ s{$first_tag_pat}{$&\n<?xml-stylesheet href="$file" type="text/css"?>};
    }
    my $path = "tmp/content/$file";
    warn "Writing file $path\n";
    $xml = encode('UTF-8', $xml);
    write_file(
        $path,
        {binmode => ':raw'},
        $xml
    );
}

sub find_all_prereqs {
    my ($file, $visited) = @_;
    $visited ||= {};
    if ($visited->{$file}) { return () };
    $visited->{$file} = 1;
    ## File: $file
    my $obj = XUL::App->FILES->{$file};
    ## Obj: $obj
    return () unless $obj;
    my $prereqs = $obj->prereqs;
    ## $prereqs
    if ($prereqs and !ref $prereqs) { $prereqs = [$prereqs]; }
    if ($prereqs and @$prereqs) {
        return map {
            find_all_prereqs($_, $visited), $_
        } @$prereqs;
    }
    return ();
}

sub copy_file {
    my ($from, $to) = @_;
    print "cp $from $to\n";
    File::Copy::Recursive::fcopy($from, $to);
}

sub copy_dir {
    my ($from, $to) = @_;
    print "cp -r $from $to\n";
    File::Copy::Recursive::dircopy($from, $to);
}

sub check_js_file {
    my $file = shift;
    if (!-f "js/$file" and !-f "js/thirdparty/$file" and !-f "tmp/content/$file") {
        my $share_dir = File::ShareDir::module_dir('XUL::App');
        #warn $share_dir;
        my $default_js =  "$share_dir/js/$file";
        #warn $share_dir;
        if (-f $default_js) {
            my $dir = dirname($file);
            if ($dir =~ /jslib(\S*)/) {
                my $subdir = $1;
                #mkdir('tmp/content/jslib');
                my $outfile = "tmp/content/jslib/jslib.js";
                copy_file("$share_dir/js/jslib/jslib.js", $outfile) unless -f $outfile;
                fix_jslib_js($outfile);
                $outfile = "tmp/content/jslib/modules.js";
                copy_file("$share_dir/js/jslib/modules.js", $outfile) unless -f $outfile;
                my $outdir = "tmp/content/jslib/debug";
                copy_dir("$share_dir/js/jslib/debug", $outdir) unless -d $outdir;
                if ($subdir) {
                    copy_dir("$share_dir/js/$dir", "tmp/content/$dir");
                }
            } else {
                print "cp $default_js tmp/content/\n";
                File::Copy::copy($default_js, "tmp/content/$file");
            }
        } else {
            die "Can't find JavaScript file $file in either js/ or js/thirdparty/\n";
        }
    }
}

sub fix_jslib_js {
    my $path = shift;
    my $content = read_file($path);
    $content =~ s{\bchrome://jslib/content/}{chrome://$XUL::App::APP_NAME/content/}g;
    chmod(0644, $path);
    write_file($path, $content);
}

sub check_css_file {
    my $file = shift;
    if (!-f "css/$file") {
        die "Can't find CSS file $file in either js/ or js/thirdparty/\n";
    }
}

1;
