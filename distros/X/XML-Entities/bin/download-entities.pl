#!/usr/bin/perl

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use File::Basename;
use Fatal 'open';

sub parse_ent;
sub format_output_perlmod_hashsubs0;
sub download;
sub report_error;
sub c($) { return $_ eq $_[0] }

my $I = ' ' x 4;  # Indentation;
my $out_fn = $ENV{OUTPUT_FILE};
my $index_url;
my %OPTIONS = ();

if ($ENV{INTERACTIVE}) {
    $OPTIONS{interactive} = 1;
}
if (exists $ENV{DOWNLOAD_TIMEOUT}) {
    $OPTIONS{timeout} = int $ENV{DOWNLOAD_TIMEOUT};
}

ARG:
while (defined (local $_ = shift @ARGV)) {
    if (m{://}) {
        if (defined $index_url) {
            croak "Index doubly defined ('$index_url' and  '$_')"
        }
        $index_url = $_;
        next ARG
    }
    if (c '-i' || c '--interactive') {
        $OPTIONS{interactive} = 1;
        next ARG
    }
    if (c '--timeout') {
        $OPTIONS{timeout} = shift @ARGV;
        next ARG
    }
    if (defined $out_fn) {
        croak "Output file doubly defined ('$out_fn', '$_')"
    }
    $out_fn = $_;
    next ARG
}
if (not defined $index_url) {
    $index_url = 'http://www.w3.org/2003/entities/iso9573-2003doc/overview.html';
}

# load the entity declarations from the web
print STDERR "Downloading the list of documents\n";
my $index = download($index_url, {
    errmess => q/Couldn't download the index ('%s' where the .ent files are listed)/,
    unignorable => 1,
});
my @doc_hrefs_relative = $index =~ /(?<=href=") [^"]+\.ent (?=")/sgx;
my @doc_hrefs = map { m{://} ? $_ : dirname($index_url) . '/' . $_ } @doc_hrefs_relative;
my @doc_names = map { my ($name) = fileparse($_, '.ent'); $name } @doc_hrefs;
print STDERR "Downloading the documents\n";
my @ent_declarations = map ( (download($_, {errmess => q/Couldn't download the declarations for %s/})), @doc_hrefs );

# parse the .ent files and save them in arrays
print STDERR "Parsing the documents... ";
my %ent_definitions;
for my $i (0 .. $#doc_names) {
    $ent_definitions{ $doc_names[$i] } = parse_ent( \$ent_declarations[$i] );
}

# Decide where to output
my $out_fh; # output filehandle - STDOUT by default;
if (defined $out_fn) {
    open $out_fh, '>', $out_fn;
}
else {
    $out_fh = \*STDOUT;
}

print $out_fh format_output_perlmod_hashsubs0(\@doc_names, \%ent_definitions);
print STDERR "Done\n";

sub download {
    my ($url, $options) = @_;

    if ($OPTIONS{interactive}) {
        print STDERR "About to download '$url'\n";
        my $ignore_ok = ', enter whitespace to skip download';
        $ignore_ok = '' if $options->{unignorable};
        GETINPUT:
        {
            print STDERR "Hit enter to confirm$ignore_ok or enter another URL\n";
            my $input = <STDIN>;
            chomp($input);
            if ($input eq '') {
                # OK
            }
            elsif ($input =~ /^\s+$/) {
                if ($options->{unignorable}) {
                    redo GETINPUT
                }
                return '';
            }
            else {
                print STDERR "Downloading '$input' instead of '$url'\n";
                $url = $input;
            }
        }
    }
	
    my $response = do {
        # Creating a new LWP::UserAgent object for every download because otherwise
        # the timeout seems not to persist across downloads in some cases
        my $lwp = LWP::UserAgent->new;
        $lwp->env_proxy;
        $lwp->timeout($OPTIONS{timeout}) if exists $OPTIONS{timeout};
        $lwp->get($url);
    };
    my $content;

    if ($response->is_success) {
        $content = $response->content;
    }
    else {
        if ($OPTIONS{interactive}) {
            $content = report_error($url, $options);
        }
        else {
            die sprintf $options->{errmess}."\n", $url
        }
    }
    return $content
}

sub report_error {
    my ($url, $options) = @_;
    print STDERR sprintf $options->{errmess}."\n", $url;
    my $ignore_ok = $options->{unignorable} ? '' : ' Ignore?';
    GETINPUT:
    {
        print STDERR "Abort? Retry?$ignore_ok\n";
        my $input = <STDIN>;
        local $_ = $input;
           /^a(?:bort)?$/i  and die "Failed downloading '$url'"
        or /^r(?:etry)?$/i  and return download(@_)
        or /^i(?:gnore)?$/i and $ignore_ok and return ''
        or redo GETINPUT
    }
}

# Get (preferably a reference to) a string that contains lines like:
# <!ENTITY amp           "&#38;" >
# <!ENTITY apos          "&#x00027;" >
# Return [ ['amp', 'chr(38)'], ['apos', 'chr(0x0027)'] ]
sub parse_ent {
    my ($ent_file_ref) = @_;
    if (not ref $ent_file_ref) { $ent_file_ref = \$ent_file_ref }
    my @raw_defs = $$ent_file_ref =~ /(?<=<!ENTITY) \s* \w+ \s+ "&[^"]+" (?=\s*>)/sgx;
    my @name_value_pairs = map {my ($n, $v) = /(\w+) \s* "&\# ([^"]+) "/sx; [$n, $v]} @raw_defs;
    for (@name_value_pairs) {
        my $v = $$_[1];
        # For some reason, some entities like &lt; are defined like &#38;#60; instead of &#60; - just get rid of 38;#
        $v =~ s/38;#//g;
        $v =~ s/^x/0x/;
        $v =~ s/;$//;
        $v = "chr($v)";
        # Some entities have more than 1 char.
        $v =~ s/;&#x/).chr(0x/g;
        $v =~ s/;&#/).chr(/g;
        $v =~ /^ (?: \.? chr\( (?: 0x[0-9ABCDEF]+ | [1-9][0-9]* ) \) )+ $/ix
        or croak "The entity definition '$$_[0] => $v' doesn't seem sane";
        $$_[1] = $v;
    }
    return \@name_value_pairs;
}


sub format_output_perlmod_hashsubs0 {

my $header = <<'EOPERL';
package XML::Entities::Data;
use strict;
my @names;
EOPERL

my $footer = <<'EOPERL' . "\n__END__\n";

sub all {
    no strict 'refs';
    return {map %{$_->()}, @names}
}

sub names {
    return @names
}

sub char2entity {
    my ($subname) = @_;
    no strict 'refs';
    my $ent2char = $subname->();
    use strict;
    my %char2ent;
    local $/ = ';';
    while (my($entity, $char) = each(%$ent2char)) {
        chomp $entity;  # $/ eq ';' so this is just a faster version of s/;\z//
        $char2ent{$char} = "&$entity;";
    }
    return \%char2ent;
}

1
EOPERL

    # This is the actual beginning of sub format_output_perlmod_hashsubs0
    my ($doc_names, $ent_definitions, $I) = @_;
    # I as in Indentation
    $I = ' ' x 4 if not defined $I;
    my $rv = $header;
    for (0 .. $#$doc_names) {
        my $name = $doc_names->[$_];
        my $definition_array = $ent_definitions->{ $name };
        
        # Start of the entity set "$name"
        $rv .= 
            "\n# " . uc($name) . "\n"
          . "push \@names, '$name';\n"
          . "{ my \$rv; sub $name {\n"
          . "$I# Return cached value if there is one.\n"
          . "${I}if (\$rv) { return \$rv }\n"
          . "${I}return \$rv = {\n";
        
        # The entity definitions
        for my $definition (@$definition_array) {
            my $n = $definition->[0];
            my $v = $definition->[1];
            $rv .= "$I$I'$n' => $v,\n";
        }
        
        # End of the entity set
        $rv .= "$I}\n}}\n";
    }
    $rv .= $footer;
    
    return $rv
}

__END__

=encoding utf8

=head1 NAME

download-entities - download and parse XML Entity definitions

=head1 SYNOPSIS

 $ perl download-entities.pl -i # interactive
 $ perl download-entities.pl > output-file.pm
 $ perl download-entities.pl output-file.pm
 
 # instead of http://www.w3.org/2003/entities/iso9573-2003/
 $ perl download-entities.pl http://my.server.com/entities.html

=head1 DESCRIPTION

This script downloads the definitions of XML entities from
http://www.w3.org/2003/entities/iso9573-2003/ or from whatever
address you give it as an argument. The argument should be
an URL (that LWP::UserAgent::get can access) pointing to a document
with (absolute or relative) references to files ending with the
C<.ent> suffix. These files are expected to be DTD's with
lines like

 <!ENTITY amp "&#38;" >

The script parses these files and prints the perl module to the
standard output. If you wish, you can give "file" as another
argument to the script and it will then print it to "file".
You can also specify the output file in the environment variable
C<OUTPUT_FILE>.

The index and the output file are distinguished by the presence
of "://" substring.
If you want to use a locally stored index file (the one with the
.ent references), you can access it by saying

 perl download.pl file:///path/to/index.html

Note that the script currently distinguishes between relative
and absolute paths by looking at whether the href contains a "://"
substring. This can lead to crashes when the links look like
href="/path/file.ent".

Also, the script assumes the links have exactly the format
I<href="..."> - with double quotes.

=head2 Interactive download

In case you run into problems downloading the documents, you can try to run the
script with the C<-i> or C<--interactive> option. This will let you skip
downloads or enter alternative URLs for individual documents.

The interactive mode is also triggered when the C<INTERACTIVE> environment
variable is set to a true value (in Perl sense).

=head2 Options

Beside the C<--interactive> option, this script also accepts the C<--timeout>
option. It specifies the timeout for LWP::UserAgent in seconds when downloading.
The same is controlled by the C<DOWNLOAD_TIMEOUT> environment variable. The
defaule (180s) timeout is used when not specified.

 # 10 seconds timeout - croak on failure
 perl download-entities.pl --timeout 10 > XML/Entities/Data.pm
 # 5 seconds timeout - croak on failure
 DOWNLOAD_TIMEOUT=5 perl download-entities.pl > XML/Entities/Data.pm
 # 1 second timeout - ask on failure
 perl download-entities.pl --interactive --timeout 1 > XML/Entities/Data.pm

=head2 Dependencies

This script has dependencies that the C<XML::Entities> module does not and are
therefore not mentioned in the META.yml file. These are C<LWP::UserAgent>,
C<File::Basename> and C<Fatal>.

=head1 COPYRIGHT

Copyright 2010 Jan Oldrich Kruza E<lt>sixtease@cpan.orgE<gt>. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
