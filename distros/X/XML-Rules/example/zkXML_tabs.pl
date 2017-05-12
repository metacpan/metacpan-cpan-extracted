use strict;
use warnings;
no warnings 'uninitialized';

use Storable qw(dclone);
use XML::Rules;

my $parser =XML::Rules->new(
	style => 'filter',
	start_rules => {
		views => sub {
			if (exists $_[4]->{parameters}{remove}) {
				if (ref($_[4]->{parameters}{remove}) eq 'ARRAY')  {
					my %tmp;
					@tmp{@{$_[4]->{parameters}{remove}}} = ();
					$_[4]->{parameters}{remove} = \%tmp;
				} elsif (ref($_[4]->{parameters}{remove}) ne 'HASH')  {
					die "The remove parameter must be either a HASH or ARRAY reference!\n";
				};
			}
			if (exists $_[4]->{parameters}{copy} and ref($_[4]->{parameters}{copy}) ne 'HASH')  {
				die "The copy parameter must be either a HASH or ARRAY reference!\n";
			}
			1;
		}
	},
	rules => {
		_default => 'raw',
		name => 'raw extended',
		listView => sub {
			my $name = $_[1]->{':name'}{_content};
			if (exists $_[4]->{parameters}{copy}{$name}) {
				if (exists $_[4]->{parameters}{remove}{$name}) {
					# rename
					$_[1]->{':name'}{_content} = $_[4]->{parameters}{copy}{$name};
					return $_[0] => $_[1];
				} else {
					# copy
					my $copy = dclone($_[1]);
					$copy->{':name'}{_content} = $_[4]->{parameters}{copy}{$name};
#					return $_[0] => $_[1], $_[0] => $copy;
					return [ [$_[0] => $_[1]], "\n    ", [$_[0] => $copy]];
				}
			} elsif (exists $_[4]->{parameters}{remove}{$name}) {
				# remove
				return;
			} else {
				# nothing
				return $_[0] => $_[1];
			}
		},
	}
);

$parser->filter(\*DATA, \*STDOUT, {
#	remove => [qw(Tab1)],
	copy => {Tab1 => 'NeTab'}
});

__DATA__
<hudson>
  <views>
    <listView>
      <owner reference="../../.."/>
      <jobNames class="tree-set">
        <comparator class="hudson.util.CaseInsensitiveComparator"/>
        <string>zip</string>
      </jobNames>
      <name>Tab1</name>
    </listView>
    <listView>
      <owner reference="../../.."/>
      <jobNames class="tree-set">
        <comparator class="hudson.util.CaseInsensitiveComparator" reference="../../../listView/jobNames/comparator"/>
        <string>zip1</string>
      </jobNames>
      <name>Tab2</name>
    </listView>
    <listView>
      <owner reference="../../.."/>
      <jobNames class="tree-set">
        <comparator class="hudson.util.CaseInsensitiveComparator" reference="../../../listView/jobNames/comparator"/>
        <string>zip</string>
        <string>zip1</string>
      </jobNames>
      <name>Tab3</name>
    </listView>
  </views>
  <slaveAgentPort>0</slaveAgentPort>
  <secretKey>6afc684a9a6f353335bd0f68beccc999f3adc88cac</secretKey>
</hudson>
