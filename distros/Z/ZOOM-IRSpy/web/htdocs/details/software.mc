     <div class="essay">
     <p>
      Index Data uses
      <b>IRSpy</b> to maintain a registry of information retrieval
      targets supporting the standard IR protocol
      <a href="http://lcweb.loc.gov/z3950/agency/"
	>ANSI/NISO Z39.50 (ISO 23950)</a>
      and
      <a href="http://www.loc.gov/sru"
	>the SRU/SRW web services</a>.
      Each registry entry consists of both database level information,
      such as the indexes supported for searching and the record
      syntax and schemas supported for retrieval, and record level
      metadata such as titles, authors and descriptions.
     </p>
     <p>
      IRSpy supports editing of record level metadata, and
      automatically discovers database level information by probing
      the registered targets using a set of feature-tests.  Tests are
      implemented by
%# Link to /doc.html?module=ZOOM/IRSpy/Test.pm is not ready yet
      individual plugins,
      so new tests can be added without changing the core code.
     </p>
     <p>
      For efficiency, probing of targets is done in parallel, using a
      pool of a few hundred concurrent connections which is refilled
      from a queue whenever a target in the pool completes its tests.
      Testing the entire current registry of 1908 targets takes about
      three elapsed hours on commodity hardware (Intel CPU, 2.8 GHz,
      256 Kb cache, 4 Mbit/s network connection).
     </p>
     <p>
      IRSpy's Web user interface allows users to
      <a href="/find.html">search</a>
      and
      <a href="/find.html?dc.title=^a*&amp;_sort=dc.title&amp;_count=9999&amp;_search=Search">browse</a>
      the registry, and to view
      <a href="/stats.html">statistics</a>.
      Authenticated users may also edit target data, run tests and add
      new targets from the Web UI.  A set of command-line tools is
      also provided, together with facilities for re-running the tests
      periodically.
     </p>
     <p>
      IRSpy is implemented in Perl, using the
      <a href="http://search.cpan.org/~mirk/Net-Z3950-ZOOM/"
	>ZOOM-Perl</a>
      module to access Z39.50 and SRU/SRW databases.  The registry
      database is implemented using
      <a href="http://indexdata.com/zebra/"
	>Zebra</a>,
      also accessed using ZOOM-Perl.  The database
      <a href="/doc.html?module=ZOOM/IRSpy/WebService.pod"
	>can be interrogated using SRU/SRW<a/>:
      it conforms to the
      <a href="http://srw.cheshire3.org/profiles/ZeeRex/"
	>ZeeRex application profile</a>,
      and can supply registry records both in extended
      <a href="http://explain.z3950.org/dtd/"
	>ZeeRex format</a>
      (now ratified as
      <a href="http://www.niso.org/standards/standard_detail.cfm?std_id=816"
	>ANSI/NISO Z39.92</a>
      and in
      <a href="http://www.loc.gov/standards/sru/record-schemas.html"
	>Dublin Core</a>
      summary format.
     </p>
     </div>
