use strict;
use warnings;
package Win32::MSI::HighLevel::ErrorTable;

=head1 NAME

Win32::MSI::HighLevel::ErrorTable - Helper module for Win32::MSI::HighLevel.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


our %ErrMsgs = (
    1101 => 'Could not open file stream: [2]. System error: [3]',
    1301 =>
        'Cannot create the file\'[2]\'. A directory with this name already exists.',
    1302 => 'Please insert the disk: [2]',
    1303 =>
        'The Installer has insufficient privileges to access this directory: [2].',
    1304 => 'Error writing to File: [2]',
    1305 => 'Error reading from File: [2]; System error code: [3]',
    1306 =>
        'The file\'[2]\' is in use. If you can, please close the application that is using the file, then click Retry.',
    1307 =>
        'There is not enough disk space remaining to install this file: [2]. If you can, free up some disk space, and click Retry, or click Cancel to exit.',
    1308 => 'Source file not found: [2]',
    1309 =>
        'Error attempting to open the source file: [3]. System error code: [2]',
    1310 =>
        'Error attempting to create the destination file: [3]. System error code: [2]',
    1311 => 'Could not locate source file cabinet: [2].',
    1312 =>
        'Cannot create the directory\'[2]\'. A file with this name already exists. Please rename or remove the file and click Retry, or click Cancel to exit.',
    1313 => 'The volume [2] is currently unavailable. Please select another.',
    1314 => 'The specified path\'[2]\' is unavailable.',
    1315 => 'Unable to write to the specified folder: [2].',
    1316 =>
        'A network error occurred while attempting to read from the file: [2]',
    1317 => 'An error occurred while attempting to create the directory: [2]',
    1318 =>
        'A network error occurred while attempting to create the directory: [2]',
    1319 =>
        'A network error occurred while attempting to open the source file cabinet: [2].',
    1320 => 'The specified path is too long:\'[2]\'',
    1321 =>
        'The Installer has insufficient privileges to modify this file: [2].',
    1322 =>
        'A portion of the folder path\'[2]\' is invalid. It is either empty or exceeds the length allowed by the system.',
    1323 =>
        'The folder path\'[2]\' contains words that are not valid in folder paths.',
    1324 => 'The folder path\'[2]\' contains an invalid character.',
    1325 => '\'[2]\' is not a valid short file name.',
    1326 => 'Error getting file security: [3] GetLastError: [2]',
    1327 => 'Invalid Drive: [2]',
    1328 =>
        'Error applying patch to file [2]. It has probably been updated by other means, and can no longer be modified by this patch. For more information contact your patch vendor. System Error: [3]',
    1329 =>
        'A file that is required cannot be installed because the cabinet file [2] is not digitally signed. This may indicate that the cabinet file is corrupt.',
    1330 =>
        'A file that is required cannot be installed because the cabinet file [2] has an invalid digital signature. This may indicate that the cabinet file is corrupt.{ Error [3] was returned by WinVerifyTrust.}',
    1331 => 'Failed to correctly copy [2] file: CRC error.',
    1332 => 'Failed to correctly move [2] file: CRC error.',
    1333 => 'Failed to correctly patch [2] file: CRC error.',
    1334 =>
        'The file\'[2]\' cannot be installed because the file cannot be found in cabinet file\'[3]\'. This could indicate a network error, an error reading from the CD-ROM, or a problem with this package.',
    1335 =>
        'The cabinet file\'[2]\' required for this installation is corrupt and cannot be used. This could indicate a network error, an error reading from the CD-ROM, or a problem with this package.',
    1336 =>
        'There was an error creating a temporary file that is needed to complete this installation. Folder: [3]. System error code: [2]',
    1401 => 'Could not create key: [2]. System error [3].',
    1402 => 'Could not open key: [2]. System error [3].',
    1403 => 'Could not delete value [2] from key [3]. System error [4].',
    1404 => 'Could not delete key [2]. System error [3].',
    1405 => 'Could not read value [2] from key [3]. System error [4].',
    1406 => 'Could not write value [2] to key [3]. System error [4].',
    1407 => 'Could not get value names for key [2]. System error [3].',
    1408 => 'Could not get sub key names for key [2]. System error [3].',
    1409 =>
        'Could not read security information for key [2]. System error [3].',
    1410 =>
        'Could not increase the available registry space. [2] KB of free registry space is required for the installation of this application.',
    1500 =>
        'Another installation is in progress. You must complete that installation before continuing this one.',
    1501 =>
        'Error accessing secured data. Please make sure the Windows Installer is configured properly and try the install again.',
    1502 =>
        'User\'[2]\' has previously initiated an install for product\'[3]\'. That user will need to run that install again before they can use that product. Your current install will now continue.',
    1503 =>
        'User\'[2]\' has previously initiated an install for product\'[3]\'. That user will need to run that install again before they can use that product.',
    1601 =>
        'Out of disk space -- Volume:\'[2]\'; required space: [3] KB; available space: [4] KB',
    1602 => 'Are you sure you want to cancel?',
    1603 =>
        'The file [2][3] is being held in use by the following process: Name: [4], Id: [5], Window Title:\'[6]\'.',
    1604 =>
        'The product\'[2]\' is already installed, and has prevented the installation of this product.',
    1605 =>
        'Out of disk space -- Volume:\'[2]\'; required space: [3] KB; available space: [4] KB. If rollback is disabled, enough space is available. Click Cancel to quit, Retry to check available disk space again, or Ignore to continue without rollback.',
    1606 => 'Could not access location [2].',
    1607 =>
        'The following applications should be closed before continuing the install:',
    1608 =>
        'Could not find any previously installed compliant products on the machine for installing this product',
    1609 =>
        'An error occurred while applying security settings. [2] is not a valid user or group. This could be a problem with the package, or a problem connecting to a domain controller on the network. Check your network connection and click Retry, or Cancel to end the install. Unable to locate the user\'s SID, system error [3] Available in Windows Installer version 2.0.',
    1610 =>
        'The setup must update files or services that cannot be updated while the system is running. If you choose to continue, a reboot will be required to complete the setup.',
    1611 =>
        'The setup was unable to automatically close all requested applications. Please ensure that the applications holding files in use are closed before continuing with the installation.',
    1651 =>
        'Admin user failed to apply patch for a per-user managed or a per-machine application which is in advertise state.',
    1701 => '[2] is not a valid entry for a product ID.',
    1702 =>
        'Configuring [2] cannot be completed until you restart your system. To restart now and resume configuration click Yes, or click No to stop this configuration.',
    1703 =>
        'For the configuration changes made to [2] to take effect you must restart your system. To restart now click Yes, or click No if you plan to manually restart at a later time.',
    1704 =>
        'An install for [2] is currently suspended. You must undo the changes made by that install to continue. Do you want to undo those changes?',
    1705 =>
        'A previous install for this product is in progress. You must undo the changes made by that install to continue. Do you want to undo those changes?',
    1706 => 'No valid source could be found for product [2].',
    1707 => 'Installation operation completed successfully.',
    1708 => 'Installation operation failed.',
    1709 => 'Product: [2] -- [3]',
    1710 =>
        'You may either restore your computer to its previous state or continue the install later. Would you like to restore?',
    1711 =>
        'An error occurred while writing installation information to disk. Check to make sure enough disk space is available, and click Retry, or Cancel to end the install.',
    1712 =>
        'One or more of the files required to restore your computer to its previous state could not be found. Restoration will not be possible.',
    1713 =>
        '[2] cannot install one of its required products. Contact your technical support group. System Error: [3].',
    1714 =>
        'The older version of [2] cannot be removed. Contact your technical support group. System Error [3].',
    1715 => 'Installed [2].',
    1716 => 'Configured [2].',
    1717 => 'Removed [2].',
    1718 => 'File [2] was rejected by digital signature policy.',
    1719 =>
        'Windows Installer service could not be accessed. Contact your support personnel to verify that it is properly registered and enabled.',
    1720 =>
        'There is a problem with this Windows Installer package. A script required for this install to complete could not be run. Contact your support personnel or package vendor. Custom action [2] script error [3], [4]: [5] Line [6], Column [7], [8] Available in Windows Installer version 2.0.',
    1721 =>
        'There is a problem with this Windows Installer package. A program required for this install to complete could not be run. Contact your support personnel or package vendor. Action: [2], location: [3], command: [4] Available in Windows Installer version 2.0.',
    1722 =>
        'There is a problem with this Windows Installer package. A program run as part of the setup did not finish as expected. Contact your support personnel or package vendor. Action [2], location: [3], command: [4] Available in Windows Installer version 2.0.',
    1723 =>
        'There is a problem with this Windows Installer package. A DLL required for this install to complete could not be run. Contact your support personnel or package vendor. Action [2], entry: [3], library: [4] Available in Windows Installer version 2.0.',
    1724 => 'Removal completed successfully.',
    1725 => 'Removal failed.',
    1726 => 'Advertisement completed successfully.',
    1727 => 'Advertisement failed.',
    1728 => 'Configuration completed successfully.',
    1729 => 'Configuration failed.',
    1730 =>
        'You must be an Administrator to remove this application. To remove this application, you can log on as an administrator, or contact your technical support group for assistance. Available on Windows Installer version 2.0.',
    1731 =>
        'The source installation package for the product [2] is out of sync with the client package. Try the installation again using a valid copy of the installation package\'[3]\'.',
    1732 =>
        'In order to complete the installation of [2], you must restart the computer. Other users are currently logged on to this computer, and restarting may cause them to lose their work. Do you want to restart now?',
    1801 => 'The path [2] is not valid',
    1802 => 'Out of memory',
    1803 =>
        'There is no disk in drive [2]. Please, insert one and click Retry, or click Cancel to go back to the previously selected volume.',
    1804 =>
        'There is no disk in drive [2]. Please, insert one and click Retry, or click Cancel to return to the browse dialog and select a different volume.',
    1805 => 'The path [2] does not exist',
    1806 => 'You have insufficient privileges to read this folder.',
    1807 =>
        'A valid destination folder for the install could not be determined.',
    1901 => 'Error attempting to read from the source install database: [2]',
    1902 =>
        'Scheduling restart operation: Renaming file [2] to [3]. Must restart to complete operation.',
    1903 =>
        'Scheduling restart operation: Deleting file [2]. Must restart to complete operation.',
    1904 => 'Module [2] failed to register. HRESULT [3].',
    1905 => 'Module [2] failed to unregister. HRESULT [3].',
    1906 => 'Failed to cache package [2]. Error: [3]',
    1907 =>
        'Could not register font [2]. Verify that you have sufficient permissions to install fonts, and that the system supports this font.',
    1908 =>
        'Could not unregister font [2]. Verify that you have sufficient permissions to remove fonts.',
    1909 =>
        'Could not create shortcut [2]. Verify that the destination folder exists and that you can access it.',
    1910 =>
        'Could not remove shortcut [2]. Verify that the shortcut file exists and that you can access it.',
    1911 =>
        'Could not register type library for file [2]. Contact your support personnel.',
    1912 =>
        'Could not unregister type library for file [2]. Contact your support personnel.',
    1913 =>
        'Could not update the .ini file [2][3]. Verify that the file exists and that you can access it.',
    1914 =>
        'Could not schedule file [2] to replace file [3] on restart. Verify that you have write permissions to file [3].',
    1915 =>
        'Error removing ODBC driver manager, ODBC error [2]: [3]. Contact your support personnel.',
    1916 =>
        'Error installing ODBC driver manager, ODBC error [2]: [3]. Contact your support personnel.',
    1917 =>
        'Error removing ODBC driver: [4], ODBC error [2]: [3]. Verify that you have sufficient privileges to remove ODBC drivers.',
    1918 =>
        'Error installing ODBC driver: [4], ODBC error [2]: [3]. Verify that the file [4] exists and that you can access it.',
    1919 =>
        'Error configuring ODBC data source: [4], ODBC error [2]: [3]. Verify that the file [4] exists and that you can access it.',
    1920 =>
        'Service\'[2]\' ([3]) failed to start. Verify that you have sufficient privileges to start system services.',
    1921 =>
        'Service\'[2]\' ([3]) could not be stopped. Verify that you have sufficient privileges to stop system services.',
    1922 =>
        'Service\'[2]\' ([3]) could not be deleted. Verify that you have sufficient privileges to remove system services.',
    1923 =>
        'Service\'[2]\' ([3]) could not be installed. Verify that you have sufficient privileges to install system services.',
    1924 =>
        'Could not update environment variable\'[2]\'. Verify that you have sufficient privileges to modify environment variables.',
    1925 =>
        'You do not have sufficient privileges to complete this installation for all users of the machine. Log on as administrator and then retry this installation.',
    1926 =>
        'Could not set file security for file\'[3]\'. Error: [2]. Verify that you have sufficient privileges to modify the security permissions for this file.',
    1927 => 'The installation requires COM+ Services to be installed.',
    1928 => 'The installation failed to install the COM+ Application.',
    1929 => 'The installation failed to remove the COM+ Application.',
    1930 => 'The description for service\'[2]\' ([3]) could not be changed.',
    1931 =>
        'The Windows Installer service cannot update the system file [2] because the file is protected by Windows. You may need to update your operating system for this program to work correctly. Package version: [3], OS Protected version: [4]',
    1932 =>
        'The Windows Installer service cannot update the protected Windows file [2]. Package version: [3], OS Protected version: [4], SFP Error: [5]',
    1933 =>
        'The Windows Installer service cannot update one or more protected Windows files. SFP Error: [2]. List of protected files:\r\n[3]',
    1934 => 'User installations are disabled through policy on the machine.',
    1935 =>
        'An error occurred during the installation of assembly component [2]. HRESULT: [3]. {{assembly interface: [4], function: [5], assembly name: [6]}}',
    1935 =>
        'An error occurred during the installation of assembly\'[6]\'. Please refer to Help and Support for more information. HRESULT: [3]. {{assembly interface: [4], function: [5], component: [2]}}',
    1936 =>
        'An error occurred during the installation of assembly\'[6]\'. The assembly is not strongly named or is not signed with the minimal key length. HRESULT: [3]. {{assembly interface: [4], function: [5], component: [2]}}',
    1937 =>
        'An error occurred during the installation of assembly\'[6]\'. The signature or catalog could not be verified or is not valid. HRESULT: [3]. {{assembly interface: [4], function: [5], component: [2]}}',
    1938 =>
        'An error occurred during the installation of assembly\'[6]\'. One or more modules of the assembly could not be found. HRESULT: [3]. {{assembly interface: [4], function: [5], component: [2]}}',
    2101 => 'Shortcuts not supported by the operating system.',
    2102 => 'Invalid .ini action: [2]',
    2103 => 'Could not resolve path for shell folder [2].',
    2104 => 'Writing .ini file: [3]: System error: [2].',
    2105 => 'Shortcut Creation [3] Failed. System error: [2].',
    2106 => 'Shortcut Deletion [3] Failed. System error: [2].',
    2107 => 'Error [3] registering type library [2].',
    2108 => 'Error [3] unregistering type library [2].',
    2109 => 'Section missing for .ini action.',
    2110 => 'Key missing for .ini action.',
    2111 =>
        'Detection of running applications failed, could not get performance data. Registered operation returned : [2].',
    2112 =>
        'Detection of running applications failed, could not get performance index. Registered operation returned : [2].',
    2113 => 'Detection of running applications failed.',
    2200 => 'Database: [2]. Database object creation failed, mode = [3].',
    2201 => 'Database: [2]. Initialization failed, out of memory.',
    2202 => 'Database: [2]. Data access failed, out of memory.',
    2203 => 'Database: [2]. Cannot open database file. System error [3].',
    2204 => 'Database: [2]. Table already exists: [3].',
    2205 => 'Database: [2]. Table does not exist: [3].',
    2206 => 'Database: [2]. Table could not be dropped: [3].',
    2207 => 'Database: [2]. Intent violation.',
    2208 => 'Database: [2]. Insufficient parameters for Execute.',
    2209 => 'Database: [2]. Cursor in invalid state.',
    2210 =>
        'Database: [2]. Invalid update data type in column [3]. Null value or unquoted 0 supplied for required field perhaps?',
    2211 => 'Database: [2]. Could not create database table [3].',
    2212 => 'Database: [2]. Database not in writable state.',
    2213 => 'Database: [2]. Error saving database tables.',
    2214 => 'Database: [2]. Error writing export file: [3].',
    2215 => 'Database: [2]. Cannot open import file: [3].',
    2216 => 'Database: [2]. Import file format error: [3], Line [4].',
    2217 => 'Database: [2]. Wrong state to CreateOutputDatabase [3].',
    2218 => 'Database: [2]. Table name not supplied.',
    2219 => 'Database: [2]. Invalid Installer database format.',
    2220 => 'Database: [2]. Invalid row/field data.',
    2221 => 'Database: [2]. Code page conflict in import file: [3].',
    2222 =>
        'Database: [2]. Transform or merge code page [3] differs from database code page [4].',
    2223 => 'Database: [2]. Databases are the same. No transform generated.',
    2224 => 'Database: [2]. GenerateTransform: Database corrupt. Table: [3].',
    2225 =>
        'Database: [2]. Transform: Cannot transform a temporary table. Table: [3].',
    2226 => 'Database: [2]. Transform failed.',
    2227 => 'Database: [2]. Invalid identifier\'[3]\' in SQL query: [4].',
    2228 => 'Database: [2]. Unknown table\'[3]\' in SQL query: [4].',
    2229 => 'Database: [2]. Could not load table\'[3]\' in SQL query: [4].',
    2230 => 'Database: [2]. Repeated table\'[3]\' in SQL query: [4].',
    2231 => 'Database: [2]. Missing \')\' in SQL query: [3].',
    2232 => 'Database: [2]. Unexpected token\'[3]\' in SQL query: [4].',
    2233 => 'Database: [2]. No columns in SELECT clause in SQL query: [3].',
    2234 => 'Database: [2]. No columns in ORDER BY clause in SQL query: [3].',
    2235 =>
        'Database: [2]. Column\'[3]\' not present or ambiguous in SQL query: [4].',
    2236 => 'Database: [2]. Invalid operator\'[3]\' in SQL query: [4].',
    2237 => 'Database: [2]. Invalid or missing query string: [3].',
    2238 => 'Database: [2]. Missing FROM clause in SQL query: [3].',
    2239 => 'Database: [2]. Insufficient values in INSERT SQL statement.',
    2240 => 'Database: [2]. Missing update columns in UPDATE SQL statement.',
    2241 => 'Database: [2]. Missing insert columns in INSERT SQL statement.',
    2242 => 'Database: [2]. Column\'[3]\' repeated.',
    2243 => 'Database: [2]. No primary columns defined for table creation.',
    2244 => 'Database: [2]. Invalid type specifier\'[3]\' in SQL query [4].',
    2245 => 'IStorage::Stat failed with error [3].',
    2246 => 'Database: [2]. Invalid Installer transform format.',
    2247 => 'Database: [2] Transform stream read/write failure.',
    2248 =>
        'Database: [2] GenerateTransform/Merge: Column type in base table does not match reference table. Table: [3] Col #: [4].',
    2249 =>
        'Database: [2] GenerateTransform: More columns in base table than in reference table. Table: [3].',
    2250 => 'Database: [2] Transform: Cannot add existing row. Table: [3].',
    2251 =>
        'Database: [2] Transform: Cannot delete row that does not exist. Table: [3].',
    2252 => 'Database: [2] Transform: Cannot add existing table. Table: [3].',
    2253 =>
        'Database: [2] Transform: Cannot delete table that does not exist. Table: [3].',
    2254 =>
        'Database: [2] Transform: Cannot update row that does not exist. Table: [3].',
    2255 =>
        'Database: [2] Transform: Column with this name already exists. Table: [3] Col: [4].',
    2256 =>
        'Database: [2] GenerateTransform/Merge: Number of primary keys in base table does not match reference table. Table: [3].',
    2257 => 'Database: [2]. Intent to modify read only table: [3].',
    2258 => 'Database: [2]. Type mismatch in parameter: [3].',
    2259 => 'Database: [2] Table(s) Update failed',
    2260 => 'Storage CopyTo failed. System error: [3].',
    2261 => 'Could not remove stream [2]. System error: [3].',
    2262 => 'Stream does not exist: [2]. System error: [3].',
    2263 => 'Could not open stream [2]. System error: [3].',
    2264 => 'Could not remove stream [2]. System error: [3].',
    2265 => 'Could not commit storage. System error: [3].',
    2266 => 'Could not rollback storage. System error: [3].',
    2267 => 'Could not delete storage [2]. System error: [3].',
    2268 =>
        'Database: [2]. Merge: There were merge conflicts reported in [3] tables.',
    2269 =>
        'Database: [2]. Merge: The column count differed in the\'[3]\' table of the two databases.',
    2270 =>
        'Database: [2]. GenerateTransform/Merge: Column name in base table does not match reference table. Table: [3] Col #: [4].',
    2271 => 'SummaryInformation write for transform failed.',
    2272 =>
        'Database: [2]. MergeDatabase will not write any changes because the database is open read-only.',
    2273 =>
        'Database: [2]. MergeDatabase: A reference to the base database was passed as the reference database.',
    2274 =>
        'Database: [2]. MergeDatabase: Unable to write errors to Error table. Could be due to a non-nullable column in a predefined Error table.',
    2275 =>
        'Database: [2]. Specified Modify [3] operation invalid for table joins.',
    2276 => 'Database: [2]. Code page [3] not supported by the system.',
    2277 => 'Database: [2]. Failed to save table [3].',
    2278 =>
        'Database: [2]. Exceeded number of expressions limit of 32 in WHERE clause of SQL query: [3].',
    2279 => 'Database: [2] Transform: Too many columns in base table [3].',
    2280 => 'Database: [2]. Could not create column [3] for table [4].',
    2281 => 'Could not rename stream [2]. System error: [3].',
    2282 => 'Stream name invalid [2].',
    2302 => 'Patch notify: [2] bytes patched to far.',
    2303 => 'Error getting volume info. GetLastError: [2].',
    2304 => 'Error getting disk free space. GetLastError: [2]. Volume: [3].',
    2305 => 'Error waiting for patch thread. GetLastError: [2].',
    2306 => 'Could not create thread for patch application. GetLastError: [2].',
    2307 => 'Source file key name is null.',
    2308 => 'Destination file name is null.',
    2309 => 'Attempting to patch file [2] when patch already in progress.',
    2310 => 'Attempting to continue patch when no patch is in progress.',
    2315 => 'Missing path separator: [2].',
    2318 => 'File does not exist: [2].',
    2319 => 'Error setting file attribute: [3] GetLastError: [2].',
    2320 => 'File not writable: [2].',
    2321 => 'Error creating file: [2].',
    2322 => 'User canceled.',
    2323 => 'Invalid file attribute.',
    2324 => 'Could not open file: [3] GetLastError: [2].',
    2325 => 'Could not get file time for file: [3] GetLastError: [2].',
    2326 => 'Error in FileToDosDateTime.',
    2327 => 'Could not remove directory: [3] GetLastError: [2].',
    2328 => 'Error getting file version info for file: [2].',
    2329 => 'Error deleting file: [3]. GetLastError: [2].',
    2330 => 'Error getting file attributes: [3]. GetLastError: [2].',
    2331 => 'Error loading library [2] or finding entry point [3].',
    2332 => 'Error getting file attributes. GetLastError: [2].',
    2333 => 'Error setting file attributes. GetLastError: [2].',
    2334 =>
        'Error converting file time to local time for file: [3]. GetLastError: [2].',
    2335 => 'Path: [2] is not a parent of [3].',
    2336 =>
        'Error creating temp file on path: [3]. GetLastError: [2]. Available on Windows Installer version 1.2 and earlier.',
    2337 => 'Could not close file: [3] GetLastError: [2].',
    2338 => 'Could not update resource for file: [3] GetLastError: [2].',
    2339 => 'Could not set file time for file: [3] GetLastError: [2].',
    2340 => 'Could not update resource for file: [3], Missing resource.',
    2341 => 'Could not update resource for file: [3], Resource too large.',
    2342 => 'Could not update resource for file: [3] GetLastError: [2].',
    2343 => 'Specified path is empty.',
    2344 => 'Could not find required file IMAGEHLP.DLL to validate file:[2].',
    2345 => '[2]: File does not contain a valid checksum value.',
    2347 => 'User ignore.',
    2348 => 'Error attempting to read from cabinet stream.',
    2349 => 'Copy resumed with different info.',
    2350 => 'FDI server error',
    2351 =>
        'File key\'[2]\' not found in cabinet\'[3]\'. The installation cannot continue. Available on Windows Installer version 1.2 and earlier.',
    2352 =>
        'Could not initialize cabinet file server. The required file \'CABINET.DLL\' may be missing.',
    2353 => 'Not a cabinet.',
    2354 => 'Cannot Win32::MSI::HighLevel::Handle cabinet.',
    2355 =>
        'Corrupt cabinet. Available on Windows Installer version 1.2 and earlier.',
    2356 => 'Could not locate cabinet in stream: [2].',
    2357 => 'Cannot set attributes.',
    2358 => 'Error determining whether file is in-use: [3]. GetLastError: [2].',
    2359 => 'Unable to create the target file - file may be in use.',
    2360 => 'Progress tick.',
    2361 => 'Need next cabinet.',
    2362 => 'Folder not found: [2].',
    2363 => 'Could not enumerate subfolders for folder: [2].',
    2364 => 'Bad enumeration constant in CreateCopier call.',
    2365 => 'Could not BindImage exe file [2].',
    2366 => 'User failure.',
    2367 => 'User abort.',
    2368 =>
        'Failed to get network resource information. Error [2], network path [3]. Extended error: network provider [5], error code [4], error description [6].',
    2370 =>
        'Invalid CRC checksum value for [2] file.{ Its header says [3] for checksum, its computed value is [4].}',
    2371 =>
        'Could not apply patch to file [2]. GetLastError: [3]. Available on Windows Installer version 1.2 and earlier.',
    2372 =>
        'Patch file [2] is corrupt or of an invalid format. Attempting to patch file [3]. GetLastError: [4]. Available on Windows Installer version 1.2 and earlier.',
    2373 =>
        'File [2] is not a valid patch file. Available on Windows Installer version 1.2 and earlier.',
    2374 =>
        'File [2] is not a valid destination file for patch file [3]. Available on Windows Installer version 1.2 and earlier.',
    2375 =>
        'Unknown patching error: [2]. Available on Windows Installer version 1.2 and earlier.',
    2376 => 'Cabinet not found.',
    2379 => 'Error opening file for read: [3] GetLastError: [2].',
    2380 => 'Error opening file for write: [3]. GetLastError: [2].',
    2381 => 'Directory does not exist: [2].',
    2382 => 'Drive not ready: [2].',
    2401 =>
        '64-bit registry operation attempted on 32-bit operating system for key [2]. Available on Windows Installer version 2.0.',
    2402 => 'Out of memory. Available on Windows Installer version 2.0.',
    2501 => 'Could not create rollback script enumerator.',
    2502 => 'Called InstallFinalize when no install in progress.',
    2503 => 'Called RunScript when not marked in progress.',
    2601 => 'Invalid value for property [2]:\'[3]\'',
    2602 =>
        'The [2] table entry\'[3]\' has no associated entry in the Media table.',
    2603 => 'Duplicate table name [2].',
    2604 => '[2] Property undefined.',
    2605 => 'Could not find server [2] in [3] or [4].',
    2606 => 'Value of property [2] is not a valid full path:\'[3]\'.',
    2607 =>
        'Media table not found or empty (required for installation of files).',
    2608 => 'Could not create security descriptor for object. Error:\'[2]\'.',
    2609 => 'Attempt to migrate product settings before initialization.',
    2611 =>
        'The file [2] is marked as compressed, but the associated media entry does not specify a cabinet.',
    2612 => 'Stream not found in\'[2]\' column. Primary key:\'[3]\'.',
    2613 => 'RemoveExistingProducts action sequenced incorrectly.',
    2614 => 'Could not access IStorage object from installation package.',
    2615 =>
        'Skipped unregistration of Module [2] due to source resolution failure.',
    2616 => 'Companion file [2] parent missing.',
    2617 => 'Shared component [2] not found in Component table.',
    2618 => 'Isolated application component [2] not found in Component table.',
    2619 => 'Isolated components [2], [3] not part of same feature.',
    2620 => 'Key file of isolated application component [2] not in File table.',
    2621 =>
        'Resource DLL or Resource ID information for shortcut [2] set incorrectly.',
    2701 =>
        'The depth of a feature exceeds the acceptable tree depth of [2] levels. The maximum depth of any feature is 16. This error is returned if a feature that exceeds the maximum depth exists.',
    2702 =>
        'A Feature table record ([2]) references a non-existent parent in the Attributes field.',
    2703 => 'Property name for root source path not defined: [2]',
    2704 => 'Root directory property undefined: [2]',
    2705 => 'Invalid table: [2]; Could not be linked as tree.',
    2706 =>
        'Source paths not created. No path exists for entry [2] in Directory table.',
    2707 =>
        'Target paths not created. No path exists for entry [2] in Directory table.',
    2708 => 'No entries found in the file table.',
    2709 =>
        'The specified Component name (\'[2]\') not found in Component table.',
    2710 => 'The requested \'Select\' state is illegal for this Component.',
    2711 => 'The specified Feature name (\'[2]\') not found in Feature table.',
    2712 => 'Invalid return from modeless dialog: [3], in action [2].',
    2713 =>
        'Null value in a non-nullable column (\'[2]\' in\'[3]\' column of the\'[4]\' table.',
    2714 => 'Invalid value for default folder name: [2].',
    2715 => 'The specified File key (\'[2]\') not found in the File table.',
    2716 => 'Could not create a random subcomponent name for component\'[2]\'.',
    2717 => 'Bad action condition or error calling custom action\'[2]\'.',
    2718 => 'Missing package name for product code\'[2]\'.',
    2719 => 'Neither UNC nor drive letter path found in source\'[2]\'.',
    2720 => 'Error opening source list key. Error:\'[2]\'',
    2721 => 'Custom action [2] not found in Binary table stream.',
    2722 => 'Custom action [2] not found in File table.',
    2723 => 'Custom action [2] specifies unsupported type.',
    2724 =>
        'The volume label \'[2]\' on the media you\'re running from does not match the label \'[3]\' given in the Media table. This is allowed only if you have only 1 entry in your Media table.',
    2725 => 'Invalid database tables',
    2726 => 'Action not found: [2].',
    2727 => 'The directory entry\'[2]\' does not exist in the Directory table.',
    2728 => 'Table definition error: [2]',
    2729 => 'Install engine not initialized.',
    2730 =>
        'Bad value in database. Table:\'[2]\'; Primary key:\'[3]\'; Column:\'[4]\'',
    2731 =>
        'Selection Manager not initialized. The selection manager is responsible for determining component and feature states. It is initialized during the costing actions ( CostInitialize action, FileCost action, and CostFinalize action.) A standard action or custom action made a call to a function requiring the selection manager before the initialization of the selection manager. This action should be sequenced after the costing actions.',
    2732 =>
        'Directory Manager not initialized. The directory manager is responsible for determining the target and source paths. It is initialized during the costing actions (CostInitialize action, FileCost action, and CostFinalize action). A standard action or custom action made a call to a function requiring the directory manager before the initialization of the directory manager. This action should be sequenced after the costing actions.',
    2733 => 'Bad foreign key (\'[2]\') in\'[3]\' column of the\'[4]\' table.',
    2734 => 'Invalid reinstall mode character.',
    2735 =>
        'Custom action\'[2]\' has caused an unhandled exception and has been stopped. This may be the result of an internal error in the custom action, such as an access violation.',
    2736 => 'Generation of custom action temp file failed: [2].',
    2737 =>
        'Could not access custom action [2], entry [3], library [4] Available in Windows Installer versions 1.0, 1.1, and 1.2.',
    2738 => 'Could not access VBScript run time for custom action [2].',
    2739 => 'Could not access JScript run time for custom action [2].',
    2740 =>
        'Custom action [2] script error [3], [4]: [5] Line [6], Column [7], [8]. Available in Windows Installer versions 1.0, 1.1, and 1.2.',
    2741 =>
        'Configuration information for product [2] is corrupt. Invalid info: [2].',
    2742 => 'Marshaling to Server failed: [2].',
    2743 =>
        'Could not execute custom action [2], location: [3], command: [4]. Available in Windows Installer versions 1.0, 1.1, and 1.2.',
    2744 =>
        'EXE failed called by custom action [2], location: [3], command: [4]. Available in Windows Installer versions 1.0, 1.1, and 1.2.',
    2745 =>
        'Transform [2] invalid for package [3]. Expected language [4], found language [5].',
    2746 =>
        'Transform [2] invalid for package [3]. Expected product [4], found product [5].',
    2747 =>
        'Transform [2] invalid for package [3]. Expected product version < [4], found product version [5].',
    2748 =>
        'Transform [2] invalid for package [3]. Expected product version <= [4], found product version [5].',
    2749 =>
        'Transform [2] invalid for package [3]. Expected product version == [4], found product version [5].',
    2750 =>
        'Transform [2] invalid for package [3]. Expected product version >= [4], found product version [5].',
    2751 =>
        'Transform [2] invalid for package [3]. Expected product version > [4], found product version [5].',
    2752 =>
        'Could not open transform [2] stored as child storage of package [4].',
    2753 => 'The File\'[2]\' is not marked for installation.',
    2754 => 'The File\'[2]\' is not a valid patch file.',
    2755 =>
        'Server returned unexpected error [2] attempting to install package [3].',
    2756 =>
        'The property\'[2]\' was used as a directory property in one or more tables, but no value was ever assigned.',
    2757 => 'Could not create summary info for transform [2].',
    2758 => 'Transform [2] does not contain an MSI version.',
    2759 =>
        'Transform [2] version [3] incompatible with engine; Min: [4], Max: [5].',
    2760 =>
        'Transform [2] invalid for package [3]. Expected upgrade code [4], found [5].',
    2761 => 'Cannot begin transaction. Global mutex not properly initialized.',
    2762 => 'Cannot write script record. Transaction not started.',
    2763 => 'Cannot run script. Transaction not started.',
    2765 => 'Assembly name missing from AssemblyName table : Component: [4].',
    2766 => 'The file [2] is an invalid MSI storage file.',
    2767 => 'No more data{ while enumerating [2]}.',
    2768 => 'Transform in patch package is invalid.',
    2769 => 'Custom Action [2] did not close [3] MSIHANDLEs.',
    2770 => 'Cached folder [2] not defined in internal cache folder table.',
    2771 => 'Upgrade of feature [2] has a missing component. .',
    2772 => 'New upgrade feature [2] must be a leaf feature.',
    2801 => 'Unknown Message -- Type [2]. No action is taken.',
    2802 => 'No publisher is found for the event [2].',
    2803 => 'Dialog Win32::MSI::HighLevel::View did not find a record for the dialog [2].',
    2804 =>
        'On activation of the control [3] on dialog [2] CMsiDialog failed to evaluate the condition [3].',
    2805 => '<no error message provided>',
    2806 => 'The dialog [2] failed to evaluate the condition [3].',
    2807 => 'The action [2] is not recognized.',
    2808 => 'Default button is ill-defined on dialog [2].',
    2809 =>
        'On the dialog [2] the next control pointers do not form a cycle. There is a pointer from [3] to [4], but there is no further pointer.',
    2810 =>
        'On the dialog [2] the next control pointers do not form a cycle. There is a pointer from both [3] and [5] to [4].',
    2811 =>
        'On dialog [2] control [3] has to take focus, but it is unable to do so.',
    2812 => 'The event [2] is not recognized.',
    2813 =>
        'The EndDialog event was called with the argument [2], but the dialog has a parent',
    2814 =>
        'On the dialog [2] the control [3] names a nonexistent control [4] as the next control.',
    2815 =>
        'ControlCondition table has a row without condition for the dialog [2].',
    2816 =>
        'The EventMapping table refers to an invalid control [4] on dialog [2] for the event [3].',
    2817 =>
        'The event [2] failed to set the attribute for the control [4] on dialog [3].',
    2818 =>
        'In the ControlEvent table EndDialog has an unrecognized argument [2].',
    2819 => 'Control [3] on dialog [2] needs a property linked to it.',
    2820 => 'Attempted to initialize an already initialized Win32::MSI::HighLevel::Handler.',
    2821 => 'Attempted to initialize an already initialized dialog: [2].',
    2822 =>
        'No other method can be called on dialog [2] until all the controls are added.',
    2823 =>
        'Attempted to initialize an already initialized control: [3] on dialog [2].',
    2824 => 'The dialog attribute [3] needs a record of at least [2] field(s).',
    2825 =>
        'The control attribute [3] needs a record of at least [2] field(s).',
    2826 =>
        'Control [3] on dialog [2] extends beyond the boundaries of the dialog [4] by [5] pixels.',
    2827 =>
        'The button [4] on the radio button group [3] on dialog [2] extends beyond the boundaries of the group [5] by [6] pixels.',
    2828 =>
        'Tried to remove control [3] from dialog [2], but the control is not part of the dialog.',
    2829 => 'Attempt to use an uninitialized dialog.',
    2830 => 'Attempt to use an uninitialized control on dialog [2].',
    2831 =>
        'The control [3] on dialog [2] does not support [5] the attribute [4].',
    2832 => 'The dialog [2] does not support the attribute [3].',
    2833 => 'Control [4] on dialog [3] ignored the message [2].',
    2834 => 'The next pointers on the dialog [2] do not form a single loop.',
    2835 => 'The control [2] was not found on dialog [3].',
    2836 => 'The control [3] on the dialog [2] cannot take focus.',
    2837 => 'The control [3] on dialog [2] wants the winproc to return [4].',
    2838 => 'The item [2] in the selection table has itself as a parent.',
    2839 => 'Setting the property [2] failed.',
    2840 => 'Error dialog name mismatch.',
    2841 => 'No OK button was found on the error dialog.',
    2842 => 'No text field was found on the error dialog.',
    2843 => 'The ErrorString attribute is not supported for standard dialogs.',
    2844 => 'Cannot execute an error dialog if the Errorstring is not set.',
    2845 =>
        'The total width of the buttons exceeds the size of the error dialog.',
    2846 => 'SetFocus did not find the required control on the error dialog.',
    2847 =>
        'The control [3] on dialog [2] has both the icon and the bitmap style set.',
    2848 =>
        'Tried to set control [3] as the default button on dialog [2], but the control does not exist.',
    2849 =>
        'The control [3] on dialog [2] is of a type, that cannot be integer valued.',
    2850 => 'Unrecognized volume type.',
    2851 => 'The data for the icon [2] is not valid.',
    2852 =>
        'At least one control has to be added to dialog [2] before it is used.',
    2853 =>
        'Dialog [2] is a modeless dialog. The execute method should not be called on it.',
    2854 =>
        'On the dialog [2] the control [3] is designated as first active control, but there is no such control.',
    2855 =>
        'The radio button group [3] on dialog [2] has fewer than 2 buttons.',
    2856 => 'Creating a second copy of the dialog [2].',
    2857 =>
        'The directory [2] is mentioned in the selection table but not found.',
    2858 => 'The data for the bitmap [2] is not valid.',
    2859 => 'Test error message.',
    2860 => 'Cancel button is ill-defined on dialog [2].',
    2861 =>
        'The next pointers for the radio buttons on dialog [2] control [3] do not form a cycle.',
    2862 =>
        'The attributes for the control [3] on dialog [2] do not define a valid icon size. Setting the size to 16.',
    2863 =>
        'The control [3] on dialog [2] needs the icon [4] in size [5]x[5], but that size is not available. Loading the first available size.',
    2864 =>
        'The control [3] on dialog [2] received a browse event, but there is no configurable directory for the present selection. Likely cause: browse button is not authored correctly.',
    2865 =>
        'Control [3] on billboard [2] extends beyond the boundaries of the billboard [4] by [5] pixels.',
    2866 => 'The dialog [2] is not allowed to return the argument [3].',
    2867 => 'The error dialog property is not set.',
    2868 => 'The error dialog [2] does not have the error style bit set.',
    2869 =>
        'The dialog [2] has the error style bit set, but is not an error dialog.',
    2870 =>
        'The help string [4] for control [3] on dialog [2] does not contain the separator character.',
    2871 => 'The [2] table is out of date: [3].',
    2872 =>
        'The argument of the CheckPath control event on dialog [2] is invalid. Where "CheckPath" can be the CheckTargetPath, SetTargetPath or the CheckExistingTargetPath control events.',
    2873 =>
        'On the dialog [2] the control [3] has an invalid string length limit: [4].',
    2874 => 'Changing the text font to [2] failed.',
    2875 => 'Changing the text color to [2] failed.',
    2876 => 'The control [3] on dialog [2] had to truncate the string: [4].',
    2877 => 'The binary data [2] was not found',
    2878 =>
        'On the dialog [2] the control [3] has a possible value: [4]. This is an invalid or duplicate value.',
    2879 => 'The control [3] on dialog [2] cannot parse the mask string: [4].',
    2880 => 'Do not perform the remaining control events.',
    2881 => 'CMsiHandler initialization failed.',
    2882 => 'Dialog window class registration failed.',
    2883 => 'CreateNewDialog failed for the dialog [2].',
    2884 => 'Failed to create a window for the dialog [2].',
    2885 => 'Failed to create the control [3] on the dialog [2].',
    2886 => 'Creating the [2] table failed.',
    2887 => 'Creating a cursor to the [2] table failed.',
    2888 => 'Executing the [2] Win32::MSI::HighLevel::View failed.',
    2889 => 'Creating the window for the control [3] on dialog [2] failed.',
    2890 => 'The Win32::MSI::HighLevel::Handler failed in creating an initialized dialog.',
    2891 => 'Failed to destroy window for dialog [2].',
    2892 => '[2] is an integer only control, [3] is not a valid integer value.',
    2893 =>
        'The control [3] on dialog [2] can accept property values that are at most [5] characters long. The value [4] exceeds this limit, and has been truncated.',
    2894 => 'Loading RICHED20.DLL failed. GetLastError() returned: [2].',
    2895 => 'Freeing RICHED20.DLL failed. GetLastError() returned: [2].',
    2896 => 'Executing action [2] failed.',
    2897 => 'Failed to create any [2] font on this system.',
    2898 =>
        'For [2] textstyle, the system created a\'[3]\' font, in [4] character set.',
    2899 => 'Failed to create [2] textstyle. GetLastError() returned: [3].',
    2901 => 'Invalid parameter to operation [2]: Parameter [3].',
    2902 => 'Operation [2] called out of sequence.',
    2903 => 'The file [2] is missing.',
    2904 => 'Could not BindImage file [2].',
    2905 => 'Could not read record from script file [2].',
    2906 => 'Missing header in script file [2].',
    2907 => 'Could not create secure security descriptor. Error: [2].',
    2908 => 'Could not register component [2].',
    2909 => 'Could not unregister component [2].',
    2910 => 'Could not determine user\'s security ID.',
    2911 => 'Could not remove the folder [2].',
    2912 => 'Could not schedule file [2] for removal on restart.',
    2919 => 'No cabinet specified for compressed file: [2].',
    2920 => 'Source directory not specified for file [2].',
    2924 =>
        'Script [2] version unsupported. Script version: [3], minimum version: [4], maximum version: [5].',
    2927 => 'ShellFolder id [2] is invalid.',
    2928 => 'Exceeded maximum number of sources. Skipping source\'[2]\'.',
    2929 => 'Could not determine publishing root. Error: [2].',
    2932 => 'Could not create file [2] from script data. Error: [3].',
    2933 => 'Could not initialize rollback script [2].',
    2934 => 'Could not secure transform [2]. Error [3].',
    2935 => 'Could not unsecure transform [2]. Error [3].',
    2936 => 'Could not find transform [2].',
    2937 =>
        'Windows Installer cannot install a system file protection catalog. Catalog: [2], Error: [3].',
    2938 =>
        'Windows Installer cannot retrieve a system file protection catalog from the cache. Catalog: [2], Error: [3].',
    2939 =>
        'Windows Installer cannot delete a system file protection catalog from the cache. Catalog: [2], Error: [3].',
    2940 => 'Directory Manager not supplied for source resolution.',
    2941 => 'Unable to compute the CRC for file [2].',
    2942 => 'BindImage action has not been executed on [2] file.',
    2943 =>
        'This version of Windows does not support deploying 64-bit packages. The script [2] is for a 64-bit package.',
    2944 => 'GetProductAssignmentType failed.',
    2945 => 'Installation of ComPlus App [2] failed with error [3].',
    3001 =>
        'The patches in this list contain incorrect sequencing information: [2][3][4][5][6][7][8][9][10][11][12][13][14][15][16].',
    3002 => 'Patch [2] contains invalid sequencing information.',
    );

1;
