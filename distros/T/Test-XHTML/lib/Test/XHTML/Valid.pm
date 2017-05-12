package Test::XHTML::Valid;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.13';

#----------------------------------------------------------------------------

=head1 NAME

Test::XHTML::Valid - test web page DTD validation.

=head1 SYNOPSIS

    my $txv = Test::XHTML::Valid->new();

    $txv->ignore_list(@IGNORE);             # patterns to ignore

    # dynamic pages
    $txv->process_root($opt{url});          # test all pages beneath root
    $txv->process_link($opt{link});         # test single link
    $txv->process_url_list($opt{ulist});    # test list of links

    # static pages
    $txv->process_path($opt{path});         # test all files within path
    $txv->process_file($opt{file});         # test single file
    $txv->process_file_list($opt{flist});   # test list of files

    # XML strings
    $txv->process_xml($xml);                # test XML as a string

    $txv->process_retries();                # retest any network failures
    my $results = $txv->process_results();

    $txv->content();            # for further testing of single page content
    $txv->errors();             # all current errors reported
    $txv->clear();              # clear all current errors and results

    $txv->retrieve_url($url);   # retrieve URL, no testing required
    $txv->retrieve_file($file); # retrieve file, no testing required

    $txv->logfile($file);       # logfile for verbose messages
    $txv->logclean(1);          # 1 = create/overwrite, 0 = append (default)

=head1 DESCRIPTION

Using either URLs or flat files, this module attempts to validate web pages
according to the DTD schema specified within each page.

=cut

# -------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use File::Basename;
use File::Find::Rule;
use File::Path;
use IO::File;
use WWW::Mechanize;
use XML::Catalogs::HTML -libxml;    # load DTDs and ENTs locally
use XML::LibXML '1.70';

# -------------------------------------
# Variables

my @IGNORE = (
    qr/^mailto/,
    qr/\.(xml|txt|pdf|doc|odt|odp|ods)$/i,
    qr/\.(tgz|gz|bz2|rar|zip)$/i,
    qr/\.(mp4|avi|wmv)$/i,
    qr/\.(jpg|jpeg|bmp|gif|png|tiff?)$/i,
);

my @RESULTS = qw( PAGES PASS FAIL NET );

# -------------------------------------
# Singletons

my $parser = XML::LibXML->new;
$parser->validation(1);

# -------------------------------------
# Public Methods

sub new {
    my $proto = shift; # get the class name
    my $class = ref($proto) || $proto;

    # private data
    my %hash  = @_;
    my $self  = {};
    $self->{RESULTS}{$_} = 0    for(@RESULTS);
    push @{ $self->{IGNORE} }, @IGNORE;

    # store access to a Mechanize object
    $self->{mech} = $hash{mech} || WWW::Mechanize->new();

    bless ($self, $class);
    return $self;
}

sub DESTROY {
    my $self = shift;
}

__PACKAGE__->mk_accessors(qw( logfile logclean ));

sub ignore_list         { _ignore_list(@_);     }

sub retrieve_url        { _retrieve_url(@_);    }
sub retrieve_file       { _retrieve_file(@_);   }

sub process_root        { _process_root(@_);    }
sub process_link        { _process_link(@_);    }
sub process_url_list    { _process_ulist(@_);   }

sub process_path        { _process_path(@_);    }
sub process_file        { _process_file(@_);    }
sub process_file_list   { _process_flist(@_);   }

sub process_xml         { _process_xml(@_);     }

sub process_retries     { _process_retries(@_); }
sub process_results     { _process_results(@_); }

sub content             { my $self = shift; return $self->{CONTENT}; }
sub errors              { my $self = shift; return $self->{ERRORS}; }
sub clear               { my $self = shift; $self->{ERRORS} = undef; $self->_reset_results(); }
sub errstr              { my $self = shift; return $self->_print_errors(); }

# -------------------------------------
# Private Methods

# single dynamic root, no additional processing required
sub _retrieve_url {
    my $self = shift;
    my $url  = shift || return;
    $self->{ROOT} = $url;
    $self->{mech}->get( $url );
    if($self->{mech}->success()) {
        $self->{CONTENT} = $self->{mech}->content;
    } else {
        $self->{CONTENT} = undef;
    }
}

# single dynamic root
sub _process_root {
    my $self = shift;
    my $url  = shift || return;
    $self->{ROOT} = $url;
    $self->_process_pages($url);
}

# single dynamic page
sub _process_link {
    my $self = shift;
    my $link = shift;
    $self->_process_page(type => 'url', page => $link);
}

# list of dynamic pages
sub _process_ulist {
    my $self = shift;
    my $file = shift;
    my $fh = IO::File->new($file,'r')  or die "Cannot open file [$file]: $!\n";
    while(<$fh>) {
        next    if(/^\s*$/ || /^\#/);
        chomp;
        $self->_process_page(type => 'url', page => $_);
    }
    $fh->close;
}

# single static page, no additional processing required
sub _retrieve_file {
    my $self = shift;
    my $file = shift || return;
    $self->{CONTENT} = undef;
    my $fh = IO::File->new($file,'r')  or die "Cannot open file [$file]: $!\n";
    while(<$fh>) {
        $self->{CONTENT} .= $_; 
    }
    $fh->close;
}

# static pages
sub _process_flist {
    my $self = shift;
    my $file = shift;
    my $fh = IO::File->new($file,'r')  or die "Cannot open file [$file]: $!\n";
    while(<$fh>) {
        next    if(/^\s*$/ || /^\#/);
        chomp;
        $self->_process_page(type => 'file', page => $_);
    }
    $fh->close;
}

sub _process_file {
    my $self = shift;
    my $file = shift;
    $self->_process_page(type => 'file', page => $file);
}

sub _process_path {
    my $self = shift;
    my $path = shift;
    my @files = File::Find::Rule->file()->name(qr/\.html?/)->in($path);
    $self->_process_page(type => 'file', page => $_) for(@files);
}

sub _process_xml {
    my $self = shift;
    my $text = shift;
    $self->_process_page(type => 'xml', content => $text);
}

sub _process_results {
    my $self = shift;
    my %results = map {$_ => $self->{RESULTS}{$_}} @RESULTS;
    $self->_log( sprintf "%8s%d\n", "$_:", $results{$_} ) for(@RESULTS);
    return \%results;
}

sub _reset_results {
    my $self = shift;
    $self->{RESULTS}{$_} = 0    for(@RESULTS);
}

sub _print_errors {
    my $self = shift;
    my $str = "\nErrors:\n" ;
    my $i = 1;
    for my $error (@{$self->{ERRORS}}) {
        $str .= "$i. $error->{message}\n";
        $i++;
    }
    return $str;
}

# -------------------------------------
# Subroutines

sub _process_pages {
    my $self = shift;
    my $url = shift;
    my (@links,%seen);

    push @links, $url;
    while(@links) {
        my $page = shift @links;
        next    if($seen{$page});
        $self->{mech}->get( $page );
        unless($self->{mech}->success()) {
            push @{ $self->{RETRIES} }, {type => 'url', page => $page};
            next;
        }

        $seen{$page} = 1;
        my @hrefs = map {$_->url_abs()} $self->{mech}->links();
        for my $href (reverse sort @hrefs) {
            next    if($seen{$href});
            next    if($self->_ignore($href));
            unshift @links, $href;
        }

        $self->_process_page(type => 'url', page => $page, content => $self->{mech}->content);
    }
}

sub _process_page {
    my $self = shift;
    my %page = @_;
    $self->{RESULTS}{PAGES}++;

    unless($page{type} && $page{type} =~ /^(file|url|xml)$/) {
        $self->{CONTENT} = undef;
        die "Unknown format type: $page{type}\n";
    }

    sleep(1);
    if($page{type} =~ /^(file|url)$/)   { $self->_log( "Parsing $page{page}: " ); }
    elsif($page{type} eq 'xml')         { $self->_log( "Parsing XML string: " );  }

    if($page{content}) {
        $self->{CONTENT} = $page{content};
    } else {

        if($page{type} eq 'file') {
            $self->_retrieve_file($page{page});
            $page{content} = $self->{CONTENT};

        } elsif($page{type} eq 'url') {
            eval { $self->{mech}->get( $page{page} ) };
            if($@) {
                push @{ $self->{ERRORS} }, {page => $page{page}, error => $@, message => _parse_message($@)};
                $self->_log( "FAIL\n$@\n" );
                $self->{RESULTS}{FAIL}++;
                return;
            }

            unless($self->{mech}->success()) {
                $self->{CONTENT} = undef;
                push @{ $self->{RETRIES} }, {type => 'url', page => $page{page}};
                return;
            } else {
				$page{content} = $self->{mech}->content;
                $self->{CONTENT} = $page{content};
			}
        } elsif($page{type} eq 'xml') {
            die "no content provided\n";
        }
    }

	eval {
		$parser->parse_string( $page{content} );
	};

    # XML::LibXML doesn't explain failures to access the external DTD, so
    # these lines are a reference to that fact.
    # See also - http://use.perl.org/~perigrin/journal/31137
    if($@ =~ /Operation in progress/i ||
       $@ =~ /validity error : No declaration for attribute xmlns of element (html|body|div)/) {
        $self->_log( "RETRY\n" );
        push @{ $self->{RETRIES} }, {type => $page{type}, page => $page{page}};
        $self->{RETRIES}->[-1]{content} = $page{content}    if($page{type} eq 'xml');
    } elsif($@) {
        push @{ $self->{ERRORS} }, {page => $page{page}, error => $@, content => $page{content}, message => _parse_message($@)};
        $self->_log( "FAIL\n$@\n" );
        $self->{RESULTS}{FAIL}++;
    } else {
        $self->_log( "PASS\n" );
        $self->{RESULTS}{PASS}++;
    }
}

sub _process_retries {
    my $self = shift;
    return  unless($self->{RETRIES});

    for my $page (sort @{ $self->{RETRIES} }) {
        sleep(1);

        if($page->{type} eq 'file') {
            $self->_log( "Parsing $page->{page}: " );
            eval {
                $parser->parse_file($page->{page});
            };
        } elsif($page->{type} eq 'url') {
            $self->_log( "Parsing $page->{page}: " );
            $self->{mech}->get( $page->{page} );
            unless($self->{mech}->success()) {
                $self->_log( "NET FAILURE\n" );
                $self->{RESULTS}{NET}++;
                next;
            }
            $page->{content} = $self->{mech}->{content};
            eval {
                $parser->parse_string($page->{content});
            };
        } elsif($page->{type} eq 'xml') {
            $self->_log( "Parsing XML string: " );
            eval {
                $parser->parse_string( $page->{content} );
            };
        } else {
            die "Unknown format type: $page->{type}\n";
        }

        # XML::LibXML doesn't explain failures to access the external DTD, so
        # these lines are a reference to that fact.
        # See also - http://use.perl.org/~perigrin/journal/31137
        if($@ =~ /Operation in progress/i ||
           $@ =~ /validity error : No declaration for attribute xmlns of element (html|body|div)/) {
            $self->_log( "NET FAILURE\n" );
            $self->{RESULTS}{NET}++;
        } elsif($@) {
            push @{ $self->{ERRORS} }, {page => $page->{page}, error => $@, content => $page->{content}, message => _parse_message($@)};
            $self->_log( "FAIL\n$@\n" );
            $self->{RESULTS}{FAIL}++;
        } else {
            $self->_log( "PASS\n" );
            $self->{RESULTS}{PASS}++;
        }
    }
}

sub _parse_message {
    my $e = shift;

    return $e   unless($e && ref($e));
    while (defined $e->{_prev}) { $e = $e->{_prev} };
    #return $e->{message};
    return "[$e->{line}:$e->{column}] $e->{message}";
}

sub _ignore {
    my $self = shift;
    my $url  = shift or return 1;   # ignore blank URLs

    for my $ignore (@{$self->{IGNORE}}) {
        return 1 if($url =~ $ignore);
    }

    # no non-http or external links
    return 1    if($url !~ /^http/);
    return 1    if($url =~ /^http/ && $url !~ /^$self->{ROOT}/);

    # ignore revisiting the base
    return 1    if(index("$self->{ROOT}",$url) == 0);

    return 0;
}

sub _ignore_list {
    my $self = shift;
    push @{ $self->{IGNORE} }, @_;
}

sub _log {
    my $self = shift;
    my $log = $self->logfile or return;
    mkpath(dirname($log))   unless(-f $log);

    my $mode = $self->logclean ? 'w+' : 'a+';
    $self->logclean(0);

    my $fh = IO::File->new($log,$mode) or die "Cannot write to log file [$log]: $!\n";
    print $fh @_;
    $fh->close;
}

1;

__END__

=head1 METHODS

=head2 Constructor

Enables test object to retain content, results and errors as appropriate.

=over 4

=item new()

Creates and returns a Test::XHTML::Valid object.

=back

=head2 Public Methods

=over 4

=item ignore_list(@LIST)

Patterns to ignore.

=item process_root(URL)

Test all pages beneath root URL.

=item process_link(URL)

Test a single link.

=item process_url_list(FILE)

Test list of links contained in FILE (one per line).

=item process_path(PATH)

Test all files within the local directory path.

=item process_file(FILE)

Test a single file.

=item process_file_list(FILE)

Test list of files contained in FILE (one per line).

=item process_xml(XML)

Test a single XML string, which is assumed to be a complete XHTML file.

=item process_retries()

Retest any network failures.

=item process_results()

Record results to log file (if given) and returns a hashref.

=item content()

Returns the single page content of the last processed page. Useful if
required for further testing.

=item errors()

Returns all the current errors reported as XML::LibXML::Error objects.

=item errstr()

Returns all the current errors reported as a single string.

=item clear()

Clear all current errors and results.

=item retrieve_url(URL)

Retrieve URL, no testing required.

=item retrieve_file(FILE)

Retrieve FILE, no testing required.

=item logfile(FILE)

Set output log file for verbose messages.

=item logclean(STATE)

Set STATE to 1 (create/overwrite) or 0 (append - the default)

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to barbie@cpan.org.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<XML::LibXML>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
