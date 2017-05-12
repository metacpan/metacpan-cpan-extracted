package XML::TMX::CWB;
$XML::TMX::CWB::VERSION = '0.10';
use warnings;
use strict;
use Lingua::PT::PLNbase;
use XML::TMX::Reader;
use XML::TMX::Writer;
use CWB::CL::Strict;
use File::Spec::Functions;
use Encode;

use POSIX qw(locale_h);
setlocale(&POSIX::LC_ALL, "pt_PT");
use locale;

=head1 NAME

XML::TMX::CWB - TMX interface with Open Corpus Workbench

=head1 SYNOPSIS

    XML::TMX::CWB->toCWB( tmx => $tmxfile,
                          from => 'PT', to => 'EN',
                          corpora => "/corpora",
                          corpus_name => "foo",
                          tokenize_source => 1,
                          tokenize_target => 1,
                          verbose => 1,
                          registry => '/path/to/cwb/registry' );

    XML::TMX::CWB->toTMX( source => 'sourcecorpus',
                          target => 'targetcorpus',
                          source_lang => 'PT',
                          target_lang => 'ES',
                          verbose => 1,
                          output => "foobar.tmx");


=head1 METHODS

=head2 toTMX

Fetches an aligned pair of corpora on CWB and exports it as a TMX
file.

=cut

sub toTMX {
    shift if $_[0] eq 'XML::TMX::CWB';
    my %ops = @_;

    die "Source and target corpora names are required.\n" unless $ops{source} and $ops{target};

    my $Cs = CWB::CL::Corpus->new(uc $ops{source});
    die "Can't find corpus [$ops{source}]\n" unless $Cs;
    my $Ct = CWB::CL::Corpus->new(uc $ops{target});
    die "Can't find corpus [$ops{target}]\n" unless $Ct;

    my $align = $Cs->attribute(lc($ops{target}), "a");
    my $count = $align->max_alg;

    my $Ws = $Cs->attribute("word", "p");
    my $Wt = $Ct->attribute("word", "p");

    my $tmx = new XML::TMX::Writer();
    $tmx->start_tmx( $ops{output} ? (OUTPUT => $ops{output}) : (),
                     TOOL => 'XML::TMX::CWB',
                     TOOLVERSION => $XML::TMX::CWB::VERSION);
    for my $i (0 .. $count-1) {
        my ($s1, $s2, $t1, $t2) = $align->alg2cpos($i);
        my $source = join(" ",$Ws->cpos2str($s1 .. $s2));
        my $target = join(" ",$Wt->cpos2str($t1 .. $t2));
	Encode::_utf8_on($source);
	Encode::_utf8_on($target);
        $tmx->add_tu($ops{source_lang} => $source,
                     $ops{target_lang} => $target);
    }
    $tmx->end_tmx();
}

=head2 toCWB

Imports a TMX file (just two languages) to a parallel corpus on CWB.

=cut

sub _get_header_prop_list {
    my ($reader, $prop, $default) = @_;

    $default ||= [];

    return $default unless exists $reader->{header}{-prop}{$prop};

    my $value = (ref($reader->{header}{-prop}{$prop}) eq "ARRAY")
              ? join(",",@{$reader->{header}{-prop}{$prop}})
              : $reader->{header}{-prop}{$prop};

    return [ split /\s*,\s*/ => $value ];
}


sub _RUN {
    my $command = shift;
    print STDERR "Running [$command]\n";
    `$command`;
}

sub toCWB {
    shift if $_[0] eq 'XML::TMX::CWB';
    my %ops = @_;

    my $tmx = $ops{tmx} or die "tmx file not specified.\n";

    my $corpora = $ops{corpora} || "/corpora";
    die "Need a corpora folder" unless -d $corpora;

    die "Can't open [$tmx] file for reading\n" unless -f $tmx;

    # Create reader object
    my $reader = XML::TMX::Reader->new($tmx);

    my %tagged_languages = ();
    for my $language (@{ _get_header_prop_list($reader, "pos-tagged") }) {
        $tagged_languages{$language}++;
    }  

    my $has_tagged_languages = scalar(keys %tagged_languages);

    my $tag_data = undef;
    my $s_attributes = ['s'];
    my $pos_fields = [qw'word lemma pos'];

    if ($has_tagged_languages) {

        if ($ops{tok} || $ops{tokenize_source} || $ops{tokenize_target}) {
            warn "Can't tokenize tagged languages. Ignoring tagging request for ",
                join(", ", keys %tagged_languages);
        }

        $s_attributes = _get_header_prop_list($reader, 'pos-s-attributes', $s_attributes);
        $pos_fields   = _get_header_prop_list($reader, 'pos-fields', $pos_fields);

        $tag_data = {
            languages => \%tagged_languages,
            'pos-s-attributes' => $s_attributes,
            'pos-fields' => $pos_fields
        };
    }

    my ($source, $target);

    if ($ops{mono}) {
        # Detect what languages to use
        ($source) = _detect_language($reader,
                                     ($ops{mono} || undef));
        $ops{verbose} && print STDERR "Using language [$source]\n";
    } else {
        # Detect what languages to use
        ($source, $target) = _detect_languages($reader,
                                               ($ops{from} || undef),
                                               ($ops{to}   || undef));
        $ops{verbose} && print STDERR "Using languages [$source, $target]\n";
    }

    # Detect corpus registry
    my $registry = $ops{registry} || $ENV{CORPUS_REGISTRY};
    chomp( $registry = `cwb-config -r` ) unless $registry;
    die "Could not detect a suitable CWB registry folder.\n" unless $registry && -d $registry;

    # detect corpus name
    my $cname = $ops{corpus_name} || $tmx;
    $cname =~ s/[.-]/_/g;

    if ($ops{mono}) {
        _mtmx2cqpfiles($reader, $cname, $source,
                       $ops{tok} || 0,
                       $ops{verbose} || 0,
                       $tag_data
                      );
        _mencode($cname, $corpora, $registry, $source, $tag_data);
    } else {
        _tmx2cqpfiles($reader, $cname, $source, $target,
                      $ops{tokenize_source} || 0,
                      $ops{tokenize_target} || 0,
                      $ops{verbose} || 0,
                      $tag_data
                     );
        _encode($cname, $corpora, $registry, $source, $target, $tag_data);
        unlink "target.cqp";
        unlink "align.txt";
    }

    unlink "source.cqp";
}

sub _encode {
    my ($cname, $corpora, $registry, $l1, $l2, $tagged) = @_;

    my @languages = ($l1, $l2);
    my @files = (qw'source target');
    
    for my $i (0, 1) {
        my ($name, $folder, $reg);
        my ($posatt, $sattr) = ("", "");

        my $l = $languages[$i];
        my $f = $files[$i];

        if ($tagged && exists($tagged->{languages}{$l})) {
#           shift @{$tagged->{'pos-fields'}};
           my (undef, @tags) = @{$tagged->{'pos-fields'}};
           $posatt = join(" ", map { "-P $_" } @tags);
           $sattr  = join(" ", map { "-S $_" } @{$tagged->{'pos-s-attributes'}});
        }        
    
        $name  = lc("${cname}_$l");
        $folder = catfile($corpora,  $name);
        $reg    = catfile($registry, $name);

        mkdir $folder;

        _RUN("cwb-encode -c utf8 -d $folder -f $f.cqp -R $reg -S tu+id $sattr $posatt");
        _RUN("cwb-make -r $registry -v " . uc($name));
    }

    _RUN("cwb-align-import -r $registry -v align.txt");
    _RUN("cwb-align-import -r $registry -v -inverse align.txt");
}

sub _mencode {
    my ($cname, $corpora, $registry, $l1, $tagged) = @_;

    my $name   = lc("${cname}_$l1");
    my $folder = catfile($corpora,  $name);
    my $reg    = catfile($registry, $name);

    my ($posatt, $sattr) = ("", "");
    if ($tagged && $tagged->{languages}{$l1}) {
       shift @{$tagged->{'pos-fields'}};
       $posatt = join(" ", map { "-P $_" } @{$tagged->{'pos-fields'}});
       $sattr  = join(" ", map { "-S $_" } @{$tagged->{'pos-s-attributes'}});
    }

    mkdir $folder;
    _RUN("cwb-encode -c utf8 -d $folder -f source.cqp -R $reg -S tu+id $sattr $posatt");
    _RUN("cwb-make -r $registry -v " . uc($name));
}

sub _tmx2cqpfiles {
    my ($reader, $cname, $l1, $l2, $t1, $t2, $v, $tagged) = @_;
    open F1, ">:utf8", "source.cqp" or die "Can't create cqp outfile\n";
    open F2, ">:utf8", "target.cqp" or die "Can't create cqp outfile\n";
    open AL, ">:utf8", "align.txt"  or die "Can't create alignment file\n";
    my $i = 1;

    printf AL "%s\t%s\ttu\tid_{id}\n", uc("${cname}_$l1"), uc("${cname}_$l2");

    print STDERR "Processing..." if $v;

    my $proc = sub {
        my ($langs) = @_;
        return unless exists $langs->{$l1} && exists $langs->{$l2};

        my (@S, @T);
        
        # Language 1
        if ($tagged && exists($tagged->{languages}{$l1})) {
             @S = split /\n/, $langs->{$l1}{-seg};
        }
        else {
            for ($langs->{$l1}{-seg}) {
                s/&/&amp;/g;
                s/</&lt;/g;
                s/</&lt;/g;
            }
            @S = $t1 ? tokenize($langs->{$l1}{-seg}) : split /\s+/, $langs->{$l1}{-seg};
        }

        # Language 2
        if ($tagged && exists($tagged->{languages}{$l2})) {
            @T = split /\n/, $langs->{$l2}{-seg};
        }
        else {
            for ($langs->{$l2}{-seg}) {
                s/&/&amp;/g;
                s/</&lt;/g;
                s/</&lt;/g;
            }

            @T = $t2 ? tokenize($langs->{$l2}{-seg}) : split /\s+/, $langs->{$l2}{-seg};
        }

        print STDERR "\rProcessing... $i translation units" if $v && $i%1000==0;

        print AL "id_$i\tid_$i\n";
        print F1 "<tu id='$i'>\n", join("\n", @S), "\n</tu>\n";
        print F2 "<tu id='$i'>\n", join("\n", @T), "\n</tu>\n";
        ++$i;
    };

    $reader->for_tu( $proc );
    print STDERR "\rProcessing... $i translation units\n" if $v;
    close AL;
    close F1;
    close F2;
}

sub _mtmx2cqpfiles {
    my ($reader, $cname, $l1, $t1, $v, $tagged) = @_;
    open F1, ">:utf8", "source.cqp" or die "Can't create cqp outfile\n";
    my $i = 1;

    print STDERR "Processing..." if $v;

    my $proc = sub {
        my ($langs) = @_;
        return unless exists $langs->{$l1};

        my (@S);
        if ($tagged && exists($tagged->{languages}{$l1})) {
            @S = split /\n/, $langs->{$l1}{-seg};
        } else {
            for ($langs->{$l1}{-seg}) {
                s/&/&amp;/g;
                s/</&lt;/g;
                s/>/&gt;/g;
            }

            @S = $t1 ? tokenize($langs->{$l1}{-seg}) : split /\s+/, $langs->{$l1}{-seg};
        }
        print STDERR "\rProcessing... $i translation units" if $v && $i%1000==0;

        print F1 "<tu id='$i'>\n", join("\n", @S), "\n</tu>\n";
        ++$i;
    };

    $reader->for_tu( $proc );
    print STDERR "\rProcessing... $i translation units\n" if $v;
    close F1;
}

sub _detect_languages {
    my ($reader, $from, $to) = @_;
    my @languages = $reader->languages();

    die "Language $from not available\n" if $from and !grep{_ieq($_, $from)}@languages;
    die "Language $to not available\n"   if $to   and !grep{_ieq($_, $to)}  @languages;

    ($from) = grep { _ieq($_, $from) } @languages if $from;
    ($to)   = grep { _ieq($_, $to  ) } @languages if $to;

    return ($from, $to) if $from and $to;

    if (scalar(@languages) == 2) {
        $to   = grep { $_ ne $from } @languages if $from and not $to;
        $from = grep { $_ ne $to   } @languages if $to   and not $from;
        ($from, $to) = @languages if not ($to or $from);
        return ($from, $to) if $from and $to;
    }
    die "Can't guess what languages to use!\n";
}

sub _detect_language {
    my ($reader, $mono) = @_;
    my @languages = $reader->languages();

    die "Language $mono not available\n" if $mono and !grep {_ieq($_, $mono)} @languages;

    ($mono) = grep { _ieq($_, $mono) } @languages if $mono;

    return ($mono) if $mono;

    if (scalar(@languages) == 1) {
        ($mono) = @languages;
        return ($mono);
    }
    die "Can't guess what languages to use!\n";
}

sub _ieq {
    uc($_[0]) eq uc($_[1])
}



=head1 AUTHOR

Alberto Simoes, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-tmx-cwb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-TMX-CWB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::TMX::CWB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-TMX-CWB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-TMX-CWB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-TMX-CWB>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-TMX-CWB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Alberto Simoes.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XML::TMX::CWB
