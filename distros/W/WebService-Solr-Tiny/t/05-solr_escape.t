use Test2::V0;
use WebService::Solr::Tiny 'solr_escape';

like dies { solr_escape() },
    qr[^Too few arguments for subroutine ];

like warning { is solr_escape(undef), undef },
    qr[^Use of uninitialized value \$q in substitution \(s///\) at ];

is solr_escape(''), '';
is solr_escape('( -1 * +1 )'), '\( \-1 \* \+1 \)';
is solr_escape('{a|b}'), '\{a\|b\}';
is solr_escape('[0-9]'), '\[0\-9\]';
is solr_escape('\(1\)'), '\\\\\(1\\\\\)', 'The one true backslash';

done_testing;
