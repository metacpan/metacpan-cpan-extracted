package Text::Mining::Base;
use Class::Std;
use Class::Std::Utils;
use DBIx::MySperqlOO;
use File::Spec;
use YAML qw(DumpFile LoadFile);
use Module::Runtime qw(use_module);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

our $config_filename = '.corpus/config';
our $status_filename = '.tm-status';

{
	my %library_dbh_of     : ATTR();
	my %analysis_dbh_of    : ATTR();
	my %root_dir_of        : ATTR();
	my %root_url_of        : ATTR();

	sub library              { my ( $self ) = @_; return $library_dbh_of{ident $self}; }
	sub analysis             { my ( $self ) = @_; return $analysis_dbh_of{ident $self}; }

	sub get_root_url         { my ( $self ) = @_; return $root_url_of{ident $self}; }
	sub get_root_dir         { my ( $self ) = @_; return $root_dir_of{ident $self}; }
	sub get_data_dir         { my ( $self, $corpus_id ) = @_; return $self->get_root_dir() . "/documents/corpus_$corpus_id"; }
	sub get_config_filename  { return File::Spec->catfile( $ENV{HOME}, $config_filename ); }
	sub get_status_filename  { return File::Spec->catfile( $ENV{HOME}, $status_filename ); }

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		my $config = $self->_load_config();

		$root_dir_of{$ident}        = $config->{root_dir};
		$root_url_of{$ident}        = $config->{root_url};

		$library_dbh_of{$ident}     = DBIx::MySperqlOO->new( $config->{library} );
		$analysis_dbh_of{$ident}    = DBIx::MySperqlOO->new( $config->{analysis} );

		return;
	}

	sub get_corpus_id_from_name {
		my ( $self, $arg_ref ) = @_;
		my $sql = "select corpus_id from corpuses where corpus_name = '" . $arg_ref->{corpus_name} . "'";
	   	my ( $corpus_id ) = $self->library()->sqlexec( $sql, '@' );
	        return $corpus_id;
	}

	sub _load_config {
		my ( $self ) = @_;
		return LoadFile( $self->get_config_filename() );
	}

	sub _parse_file_name {
		my ( $self, $url ) = @_;
		my @path  = split(/\//, $url); 
		return pop(@path);
	}
	
	sub _download_file {
		my ( $self, $arg_ref ) = @_;
		my @stat;
		my $target_dir = defined $arg_ref->{target_dir} ? $arg_ref->{target_dir} : '';
		my $url        = defined $arg_ref->{url} ? $arg_ref->{url} : '';
		my $tries      = defined $arg_ref->{tries} ? $arg_ref->{tries} : 2;
		if ($target_dir && $url) {
			my $file_name  = $self->_parse_file_name( $url );
			my $wget  = "wget --tries=$tries --directory-prefix=$target_dir $url";
			`$wget`;
			@stat = stat("$target_dir/$file_name");
		}
	  	return $stat[7] || '0';
	}

	sub _sql_escape { 
		my ( $self, $string ) = @_;
		if ($string) { $string =~ s/(['"\\])/\\$1/g; }
		return $string; 
	}
	
	sub _html_to_sql {
		my ( $self, $string ) = @_;
		$string = $self->_html_unescape( $string );
		$string = $self->_sql_escape( $string );
		return $string;
	}
	
	sub _html_escape {
		my ( $self, $string ) = @_;
		$string =~ s/'/&#39;/g;
		$string =~ s/"/&#34;/g;
		return $string;
	}
		
	sub _html_encode {
		my ( $self, $string ) = @_;
		$string =~ s/ /%20/g;
		$string =~ s/'/%27/g;
		$string =~ s/\{/%7B/g;
		$string =~ s/\}/%7D/g;
		return $string;
	}
		
	sub _html_unescape {
		my ( $self, $string ) = @_;
		$string =~ s/&#39;/'/g;
		$string =~ s/&#34;/"/g;
		$string =~ s/%20/ /g;
		return $string;
	}
	
	sub _phone_format {
		my ( $self, $string ) = @_;
		$string =~ s/(\d{3})(\d{3})(\d{4})/($1) $2-$3/;
		return $string;
	}
	
	sub _phone_unformat {
		my ( $self, $string ) = @_;
		$string =~ s/[^\d]//g;
		return $string;
	}
	
	sub _commify { # Perl Cookbook 2.17
		my ( $self, $string ) = @_;
		my $text = reverse $string;
		$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
		return scalar reverse $text;
	}
	
	sub _get_files {
		my ( $self, $root_dir ) = @_;
		if (opendir(DIR, $root_dir)) {
			my (@files);
			my (@nodes) = (readdir(DIR));
	
			foreach my $node (@nodes) {
				if ($node =~ m/^\./) { next; }
	
	          		my $pathnode = $root_dir . "/" . $node;
				my @stat = stat($pathnode);
	
				my $value = defined $stat[2] ? $stat[2] : '';
				if ($value =~ /^[^1]/) {
					push(@files, $node);
			  	}
			}
			return @files;
		} else {
			return 0;
		}
	}
	
	sub _get_dirs {
		my ( $self, $path, $nestedflag) = @_;
		
		# If the directory opens
		if (opendir(DIR, $path)) {
			# Read it 
			my (@dirs);
			my (@nodes) = sort (readdir(DIR));
	
			foreach my $node (@nodes) {
			  # Drop any dirs (or files) that start with a period
			  if ($node =~ m/^\./) { next; }
	
			  # Get file system node status
			  my @stat = stat($path . '/' . $node);
	
			  # if the first character of $mode is 1, then it is a dir
			  if ($stat[2] =~ /^1/) {
			    my $newpath = $path . "/" . $node;
			    push(@dirs, $newpath);
	
			    if ($nestedflag) {
			      my @subnodes = &GetDirs($newpath, $nestedflag);
			      push(@dirs, @subnodes);
			    }
			  }
			}
			return @dirs;
		} else {
			return 0;
		}
	}
	
	sub _get_file_text {
		my ( $self, $path_file_name ) = @_;
		my ($text, $line);
		if (-e $path_file_name) {
			open  (my $IN, '<', $path_file_name) || $self->_status( "(Get) Cannot open $path_file_name: $!" );
			while ($line = <$IN>) { $text .= $line; }
			close ($IN)                          || $self->_status( "(Get) Cannot close $path_file_name: $!" );
		}
		return $text;
	}
	
	sub _set_file_text {
		my ( $self, $path_file_name, $text ) = @_;
		open  (my $OUT, '>', $path_file_name)        || $self->_status( "(Set) Cannot open $path_file_name: $!" );
		print {$OUT} $text                           || $self->_status( "(Set) Cannot write $path_file_name: $!" );
		close ($OUT)                                 || $self->_status( "(Set) Cannot close $path_file_name: $!" );
	}
	
	sub _add_file_text {
		my ( $self, $path_file_name, $text ) = @_;
		open  (my $OUT, '>>', $path_file_name)       || $self->_status( "(Add) Cannot open $path_file_name: $!" );
		print {$OUT} $text                           || $self->_status( "(Add) Cannot write $path_file_name: $!" );
		close ($OUT)                                 || $self->_status( "(Add) Cannot close $path_file_name: $!" );
	}
	
	sub _status {
		my ( $self, $msg ) = @_;
		my $status_file = $self->get_status_filename();
		open  (my $OUT, '>>', $status_file)          || croak( "(Status) Cannot open $status_file: $!" );
		print {$OUT} "  STATUS: $msg \n"             || croak( "(Status) Cannot write $status_file: $!" );
		close ($OUT)                                 || croak( "(Status) Cannot close $status_file: $!" );
		return;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Base - Perl Tools for Text Mining


=head1 VERSION

This document describes Text::Mining::Base version 0.0.8


=head1 SYNOPSIS

    use Text::Mining::Base;

    my $wizard = CatalystX::Wizard->new({attribute => 'value'});

    print $wizard->get_attribute(), "\n";

    $wizard->set_attribute('new value');

    print $wizard->get_attribute(), "\n";

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Text::Mining::Base requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining-base@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
