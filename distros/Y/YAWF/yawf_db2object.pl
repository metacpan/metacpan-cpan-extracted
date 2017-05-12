#!/usr/bin/perl

use strict;
use warnings;

if ($#ARGV == -1) {
	print "Syntax: $0 lib/project/DB/Result/database_table_definition.pm\n";
	exit;
}

for (@ARGV) {
	print "----- $_ ------\n";
	eval {
	open my $fh,'<',$_ or die "$_: $!";

	my $package;
	
	while (<$fh>) {
		next unless /package ([\w\:]+);/;
		$package = $1;
		last;
	}
	die 'No package found' unless defined($package);
	
	$package =~ /^([\w\:]+)\:\:DB\:\:Result\:\:(\w+)$/ or die 'Invalid package syntax: '.$package;
	my $project = $1;
	my $table = $2;
	my $prefix = $project.'::';

	my $obj = $prefix.$table;
	my $output = <<_EOT_;
package $obj;

use 5.006;
use strict;
use warnings;

use YAWF;
use YAWF::Object;

our \$VERSION = '0.01';
our \@ISA = ( 'YAWF::Object', '$package' );

sub TABLE { return '$table'; }

_EOT_

	while(<$fh>) {
		if (/\Q__PACKAGE__->belongs_to(\E/) {
			scalar(<$fh>) =~ /\"(\w+)\",/ and my $col = $1;
			die 'No belogs_to - local - column found' unless defined($col);
			scalar(<$fh>) =~ /\"$project\:\:DB\:\:Result\:\:([\w\:]+)\",/ and my $reftable = $1;
			die 'No referenced table' unless defined($reftable);
			scalar(<$fh>) =~ /\{ (\w+?) \=\> \"(\w+)\" \},/ or die 'No referencing information found';
			my $remote_col = $1;
			my $local_col = $2;
			
			$output .= <<_EOT_
sub $col {
    my \$self = shift;
    
    \$self->{$col} ||= $prefix$reftable->new($remote_col => \$self->get_column('$local_col'));
    
    return \$self->{$col};
}

_EOT_
		}		elsif (/\_\_PACKAGE\_\_\-\>(has_many|might_have)\(/) {
			scalar(<$fh>) =~ /\"(\w+)\",/ and my $col = $1;
			die 'No belogs_to - local - column found' unless defined($col);
			scalar(<$fh>) =~ /\"$project\:\:DB\:\:Result\:\:([\w\:]+)\",/ and my $reftable = $1;
			die 'No referenced table' unless defined($reftable);
			scalar(<$fh>) =~ /\{ "foreign\.(\w+?)" \=\> \"self\.(\w+)\" \},/ or die 'No referencing information found';
			my $remote_col = $1;
			my $local_col = $2;
			
			$output .= <<_EOT_
sub $col {
    my \$self = shift;

    return $prefix$reftable->list( { $remote_col => \$self->get_column('$local_col') } ) if wantarray;
    return [$prefix$reftable->list( { $remote_col => \$self->get_column('$local_col') } )] ;
}

_EOT_
		}
	}
	close $fh;

	$output .= "1;\n";
	
	my $fn = 'lib/'.$project.'/'.$table.'.pm';
	die $fn.' already exists' if -e $fn;
	open my $out_fh,'>',$fn or die 'Unable to create '.$fn.': '.$!;
	print $out_fh $output;
	close $out_fh;
};
print "$@\n" if $@;
}
