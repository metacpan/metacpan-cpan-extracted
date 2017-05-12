/********************************************************************************************************************************/
/* Created: 21-JUN-2005 11:49:10 by OpenVMS SDL EV1-69     */
/* Source:  16-JUN-2003 10:31:48 SYS$COMMON:[SYSHLP.EXAMPLES.CMS]CMS$ROUTINES.SD */
/********************************************************************************************************************************/
/*** MODULE CMS$ROUTINES IDENT V4.2 ***/
#ifndef _cms$routines_h
#define _cms$routines_h
	
/*                                                                          */
/* User Argument                                                            */
/*                                                                          */
/*                                                                          */
/* The user argument is defined as being of undefined type and mechanism.   */
/* CMS passes this on unchanged to the callback routine. For the purposes   */
/* of this SDL file it is necessary to give a type and reference and        */
/* a type of ANY and mechanism of REFERENCE has been selected as most likely */
/* to be correct. If the actual callback routine uses a different type or   */
/* mechanism this will need changing.                                       */
/*                                                                          */
typedef int cms$l_user_arg_type;
/*                                                                          */
/* Control Blocks                                                           */
/*                                                                          */
/*                                                                          */
/* The contents of a library data block (LDB) are designed to be used only  */
/* by CMS. Except that the "user_parameter" value may be modified by the user. */
/* Use of an LDB in which any other field has been modified may corrupt your */
/* library.                                                                 */
/*                                                                          */
typedef struct _ldb_cntrlblk {
    int ldb$l_reserved_for_cms1 [4];
    int ldb$l_user_parameter;
    int ldb$l_reserved_for_cms2 [55];
    } ldb_cntrlblk;
/*                                                                          */
/* The contents of a fetch data block (FDB) are designed to be used only    */
/* by CMS. Use of an FDB in which any field has been modified may corrupt   */
/* your library.                                                            */
/*                                                                          */
typedef struct _fdb_cntrlblk {
    int fdb$l_reserved_for_cms [12];
    } fdb_cntrlblk;
/*                                                                          */
/* Binary date and Time value.                                              */
/*                                                                          */
typedef int cms$q_date_time [2];
/*                                                                          */
/* Position type for cms$create_library and cms$set_library. Used to        */
/* describe order of libraries within a library library search list.        */
/*                                                                          */
typedef int position_type;
#define CMS$K_SUPERSEDE 0
#define CMS$K_AFTER 1
#define CMS$K_BEFORE 2
/*                                                                          */
/* Address type passed into callbacks to identify a string. Used with       */
/* cms$get_string for languages not directly supporting the descriptor.     */
/* For some languages can be used directly as an address.                   */
/*                                                                          */
typedef int *string_addr;
/*                                                                          */
/* Review action type for cms$review_generation. Used to identify action    */
/* taken on each specified generation.                                      */
/*                                                                          */
typedef int review_action_type;
#define CMS$K_ACCEPT 0
#define CMS$K_CANCEL 1
#define CMS$K_MARK 2
#define CMS$K_REJECT 3
#define CMS$K_REVIEW 4
/*                                                                          */
/* Object type for cms$set_acl and cms$show_acl. Used to identify the type  */
/* of object whose acl is being manipulated.                                */
/*                                                                          */
typedef int object_types;
#define CMS$K_ACL_ELEMENT 1
#define CMS$K_ACL_CLASS 2
#define CMS$K_ACL_GROUP 3
#define CMS$K_ACL_LIBRARY 4
#define CMS$K_ACL_COMMAND 5
/*                                                                          */
/* Output format for cms$annotate and cms$differences. Defines the type of  */
/* formatting performed on the data before it is put in the output file.    */
/*                                                                          */
typedef struct _format_type {
    unsigned CMS$M_ASCII : 1;
    unsigned CMS$M_DECIMAL : 1;
    unsigned CMS$M_HEXADECIMAL : 1;
    unsigned CMS$M_OCTAL : 1;
    unsigned CMS$v_spare1 : 12;
    unsigned CMS$M_BYTE : 1;
    unsigned CMS$M_LONGWORD : 1;
    unsigned CMS$M_RECORDS : 1;
    unsigned CMS$M_WORD : 1;
    unsigned CMS$v_spare2 : 3;
    unsigned CMS$M_GENERATION_DIF : 1;
    unsigned CMS$v_spare3 : 8;
    } format_type;
/*                                                                          */
/* Transaction mask for cms$delete_history and cms$show_history. Defines    */
/* the set of transcation records to be considered.                         */
/*                                                                          */
typedef struct _transaction_mask_type {
    unsigned CMS$M_CMD_COPY : 1;
    unsigned CMS$M_CMD_CREATE : 1;
    unsigned CMS$M_CMD_DELETE : 1;
    unsigned CMS$M_CMD_FETCH : 1;
    unsigned CMS$M_CMD_INSERT : 1;
    unsigned CMS$M_CMD_MODIFY : 1;
    unsigned CMS$M_CMD_REMARK : 1;
    unsigned CMS$M_CMD_REMOVE : 1;
    unsigned CMS$M_CMD_REPLACE : 1;
    unsigned CMS$M_CMD_RESERVE : 1;
    unsigned CMS$M_CMD_UNRESERVE : 1;
    unsigned CMS$M_CMD_VERIFY : 1;
    unsigned CMS$v_spare1 : 2;
    unsigned CMS$M_CMD_SET : 1;
    unsigned CMS$_spare2 : 1;
    unsigned CMS$M_CMD_ACCEPT : 1;
    unsigned CMS$M_CMD_CANCEL : 1;
    unsigned CMS$M_CMD_MARK : 1;
    unsigned CMS$M_CMD_REJECT : 1;
    unsigned CMS$M_CMD_REVIEW : 1;
    unsigned CMS$v_spare3 : 11;
    } transaction_mask_type;
/*                                                                          */
/* Ignore mask for cms$differences and cms$differences_class.               */
/* IGNORE_FORM to IGNORE_NOTES are only used for with cms$differences.      */
/* IGNORE_FIRST_VARIANTS is only used with cms$differences_class.           */
/*                                                                          */
#define CMS$M_IGNORE_FORM 0x1
#define CMS$M_IGNORE_LEAD 0x2
#define CMS$M_IGNORE_TRAIL 0x4
#define CMS$M_IGNORE_SPACE 0x8
#define CMS$M_IGNORE_CASE 0x10
#define CMS$M_IGNORE_HISTORY 0x20
#define CMS$M_IGNORE_NOTES 0x40
#define CMS$M_IGNORE_FIRST_VARIANT 0x80000000
typedef struct _ignore_mask_type {
    unsigned CMS$V_IGNORE_FORM : 1;
    unsigned CMS$V_IGNORE_LEAD : 1;
    unsigned CMS$V_IGNORE_TRAIL : 1;
    unsigned CMS$V_IGNORE_SPACE : 1;
    unsigned CMS$V_IGNORE_CASE : 1;
    unsigned CMS$V_IGNORE_HISTORY : 1;
    unsigned CMS$V_IGNORE_NOTES : 1;
    unsigned CMS$v_spare : 24;
    unsigned CMS$V_IGNORE_FIRST_VARIANT : 1;
    } ignore_mask_type;
/*                                                                          */
/* Show  mask for cms$differences_class.                                    */
/*                                                                          */
#define CMS$M_ELEMENT_DIF 0x1
#define CMS$M_GENERATIONAL_DIF 0x2
#define CMS$M_VARIANT_DIF 0x4
typedef struct _show_mask_type {
    unsigned CMS$V_ELEMENT_DIF : 1;
    unsigned CMS$V_GENERATIONAL_DIF : 1;
    unsigned CMS$V_VARIANT_DIF : 1;
    unsigned CMS$v_spare : 29;
    } show_mask_type;
/*                                                                          */
/* Library statistics provided by cms$show_library.                         */
/*                                                                          */
typedef struct _statistics_type {
    int CMS$L_ELEMENTS_COUNT;
    int CMS$L_GROUPS_COUNT;
    int CMS$L_CLASSES_COUNT;
    int CMS$L_RESERVATIONS_COUNT;
    int CMS$L_CONCURRENT_REPLACEMENTS_COUN;
    int CMS$L_REVIEWS_PENDING_COUNT;
    int CMS$l_reserved_for_CMS [4];
    } statistics_type;
/*                                                                          */
/* Creates an annotated listing file of the specifed element generation and  */
/* places it in your current default directory.                             */
/*                                                                          */
unsigned int cms$annotate() ;
/*                                                                          */
/*  Simulates a keyboard CTRL/C (cancel). The CMS$ASYNCH_TERMINATE routine  */
/*  allows calling programs to specify to the CMS function currently in     */
/*  progress that cancellation has been requested.                          */
/*                                                                          */
void cms$asynch_terminate() ;
/*                                                                          */
/* Parse and executes the command line and then returns to the calling program */
/*                                                                          */
unsigned int cms$cms() ;
/*                                                                          */
/* Copies an existing class to form a new one with a different name and     */
/* populates it with the same set of element generations as the original.   */
/*                                                                          */
unsigned int cms$copy_class() ;
/*                                                                          */
/* Copies an existing element to form a new one with a different name.      */
/*                                                                          */
unsigned int cms$copy_element() ;
/*                                                                          */
/* Copies an existing group to form a new one with a different name and     */
/* populates it with the same set of elements as the original.              */
/*                                                                          */
unsigned int cms$copy_group() ;
/*                                                                          */
/* Creates an empty class with the name specifed by the class_name argument. */
/*                                                                          */
unsigned int cms$create_class() ;
/*                                                                          */
/*  Creates a new element in a CMS library.                                 */
/*                                                                          */
unsigned int cms$create_element() ;
/*                                                                          */
/* Creates an empty group                                                   */
/*                                                                          */
unsigned int cms$create_group() ;
/*                                                                          */
/* Creates a new CMS library in an existing empty directory.                */
/*                                                                          */
unsigned int cms$create_library() ;
/*                                                                          */
/* Deletes a class or classes from a CMS library. There cannot be any element */
/* generations in the class when it is deleted, unless the remove_contents  */
/* is set.                                                                  */
/*                                                                          */
unsigned int cms$delete_class() ;
/*                                                                          */
/* Deletes an element or elements from a CMS library. The element cannot be */
/* in any group, and there can be no generations of it in any classes.      */
/*                                                                          */
unsigned int cms$delete_element() ;
/*                                                                          */
/* Deletes one or more generations of one or more elements from a CMS       */
/* library.                                                                 */
/*                                                                          */
unsigned int cms$delete_generation() ;
/*                                                                          */
/* Deletes a group or group from a CMS library. There can be no elements or */
/* or groups in the group, unless the remove_contents flag is set. Nor      */
/* can the group be in any other group.                                     */
/*                                                                          */
unsigned int cms$delete_group() ;
/*                                                                          */
/* Deletes all or part of the library History.                              */
/*                                                                          */
unsigned int cms$delete_history() ;
/*                                                                          */
/* Compares two elements, or two generations of elements, or an element     */
/* and a generation. If the files are different, it creates a file containing  */
/* the lines that differ between the two files. If the files are the same, it */
/* issues a message to that effect and does not create a differences file.  */
/*                                                                          */
unsigned int cms$differences() ;
/*                                                                          */
/* Compares the contents of two classes. If the contents of the classes are */
/* different, it creates a file containing the names of the generations     */
/* that differ between the two classes. If the files are the same, it       */
/* issues a message to that effect and does not create a differences file.  */
/*                                                                          */
unsigned int cms$differences_class() ;
/*                                                                          */
/* Retrieves a copy of an element from a CMS library. You can also specify an */
/* argument that directs CMS to establish a reservation for the element.    */
/*                                                                          */
unsigned int cms$fetch() ;
/*                                                                          */
/* Terminates a fetch transaction initiated by CMS$FETCH_OPEN.              */
/*                                                                          */
unsigned int cms$fetch_close() ;
/*                                                                          */
/* Retrieves one line of data from an element. Use the CMS$FETCH_GET routine */
/* in combination with the CMS$FETCH_OPEN and CMS$FETCH_CLOSE routines.     */
/*                                                                          */
unsigned int cms$fetch_get() ;
/*                                                                          */
/* Begins a line-by-line fetch transaction. Use the CMS$FETCH_OPEN routine in */
/* combination with the CMS$FETCH_GET and CMS$FETCH_CLOSE routines.         */
/*                                                                          */
unsigned int cms$fetch_open() ;
/*                                                                          */
/* Translates a string identifier.                                          */
/*                                                                          */
unsigned int cms$get_string() ;
/*                                                                          */
/* Places one or more elements in the specified group.                      */
/*                                                                          */
unsigned int cms$insert_element() ;
/*                                                                          */
/* Places one or more element generations in the specified class or classes. */
/*                                                                          */
unsigned int cms$insert_generation() ;
/*                                                                          */
/* Places one or more groups in the specifed groups.                        */
/*                                                                          */
unsigned int cms$insert_group() ;
/*                                                                          */
/* Changes the characteristics of the specified class or classes.           */
/*                                                                          */
unsigned int cms$modify_class() ;
/*                                                                          */
/* Changes the characteristices of an existing element.                     */
/*                                                                          */
unsigned int cms$modify_element() ;
/*                                                                          */
/* Alters information associated with one or more generations of an element. */
/*                                                                          */
unsigned int cms$modify_generation() ;
/*                                                                          */
/* Changes the characteristics of an existing group.                        */
/*                                                                          */
unsigned int cms$modify_group() ;
/*                                                                          */
/* Establishes or removes the connection between a CMS library and a reference */
/* copy directory.                                                          */
/*                                                                          */
unsigned int cms$modify_library() ;
/*                                                                          */
/* Alters information associated with one or more reservations of an element. */
/*                                                                          */
unsigned int cms$modify_reservation() ;
/*                                                                          */
/* Passes a string from a callback routine to CMS.                          */
/*                                                                          */
unsigned int cms$put_string() ;
/*                                                                          */
/* Places a remark in the library history.                                  */
/*                                                                          */
	
unsigned int cms$remark() ;
	
/*                                                                          */
/* Removes an element from one or more groups.                              */
/*                                                                          */
unsigned int cms$remove_element() ;
/*                                                                          */
/* Removes an element generation from one or more classes.                  */
/*                                                                          */
unsigned int cms$remove_generation() ;
/*                                                                          */
/* Removes one of more groups from another group or groups.                 */
/*                                                                          */
unsigned int cms$remove_group() ;
/*                                                                          */
/* Returns a reserved element or elements to the library and creates a new  */
/* generation of the element or element to identify the changes.            */
/*                                                                          */
unsigned int cms$replace() ;
/*                                                                          */
/* Retrieves one or more generations from one or more archive files.        */
/*                                                                          */
unsigned int cms$retrieve_archive() ;
/*                                                                          */
/* Associates a review comment with each specified element generation that is */
/* currently under review and allows changing the review status of each     */
/* specified generation.                                                    */
/*                                                                          */
unsigned int cms$review_generation() ;
/*                                                                          */
/* Manipulates the access control list (ACL) on various objects in the CMS  */
/* library.                                                                 */
/*                                                                          */
unsigned int cms$set_acl() ;
/*                                                                          */
/* Enables access to an existing CMS library. This routine initializes a library */
/* data block for use with other CMS callable routines.                     */
/*                                                                          */
unsigned int cms$set_library() ;
/*                                                                          */
/* Removes one or more libraries from the current library search list.      */
/*                                                                          */
unsigned int cms$set_nolibrary() ;
/*                                                                          */
/* Displays the ACL associated with one or more specified objects.          */
/*                                                                          */
unsigned int cms$show_acl() ;
/*                                                                          */
/* Displays information about the content of one or more archive files.     */
/*                                                                          */
unsigned int cms$show_archive() ;
/*                                                                          */
/* Provides information about one or more classes in a CMS library.         */
/*                                                                          */
unsigned int cms$show_class() ;
/*                                                                          */
/* Provides information about one or more elements in a CMS library.        */
/*                                                                          */
unsigned int cms$show_element() ;
/*                                                                          */
/* Displays information about one or more element generations in a CMS library. */
/*                                                                          */
unsigned int cms$show_generation() ;
/*                                                                          */
/* Provides information about one or more groups in a CMS library.          */
/*                                                                          */
unsigned int cms$show_group() ;
/*                                                                          */
/* Provides (in chronological order) records of transactions performed on a */
/* CMS library.                                                             */
/*                                                                          */
unsigned int cms$show_history() ;
/*                                                                          */
/* Provides information about the current library.                          */
/*                                                                          */
unsigned int cms$show_library() ;
/*                                                                          */
/* Provides information about all current reservations and concurrent       */
/* replacements in effect at the time the routine is called.                */
/*                                                                          */
unsigned int cms$show_reservations() ;
/*                                                                          */
/* Displays a list of element generations that currently have review        */
/* pending status. Also shows the associated review remarks.                */
/*                                                                          */
unsigned int cms$show_reviews_pending() ;
/*                                                                          */
/* Provides version identification of the CMS system currently in use.      */
/*                                                                          */
unsigned int cms$show_version() ;
/*                                                                          */
/* Cancels the reservation for one or more elements.                        */
/* The 4th parameter, "reserved", must be provided with the value 0.        */
/*                                                                          */
unsigned int cms$unreserve() ;
/*                                                                          */
/* Performs a series of consistency checks on the present library.          */
/*                                                                          */
unsigned int cms$verify() ;
/*                                                                          */
/* Message Definitions                                                      */
/*                                                                          */
#define CMS$_FACILITY 156
#define CMS$_ABSTIM 10256394
#define CMS$_ACCVIORD 10256404
#define CMS$_ACCVIOWT 10256412
#define CMS$_ALL 10256417
#define CMS$_ALPHACHAR 10256426
#define CMS$_ALRDYEXISTS 10256434
#define CMS$_ALRDYINCLS 10256442
#define CMS$_ALRDYINGRP 10256450
#define CMS$_ANNOTATED 10256457
#define CMS$_ANNOTATIONS 10256465
#define CMS$_ARGCONFLICT 10256474
#define CMS$_ARGCOUNTERR 10256482
#define CMS$_BADBUG 10256492
#define CMS$_BADCALL 10256500
#define CMS$_BADCRC 10256504
#define CMS$_BADLIB 10256516
#define CMS$_BADCRETIME 10256522
#define CMS$_BADLENSTR 10256530
#define CMS$_BADLSTSTR 10256538
#define CMS$_BADORDSTR 10256546
#define CMS$_BADPTR 10256554
#define CMS$_BADTYPSTR 10256562
#define CMS$_BADVERSTR 10256570
#define CMS$_BCKPTRSTR 10256578
#define CMS$_CNTSTR 10256586
#define CMS$_BADSTRING 10256594
#define CMS$_BADVERSION 10256602
#define CMS$_BUG 10256612
#define CMS$_CLASSGENEXP 10256619
#define CMS$_CMPSIGNAL 10256627
#define CMS$_COMPARED 10256633
#define CMS$_CONCLS 10256643
#define CMS$_CONCURRENT 10256649
#define CMS$_CONELE 10256659
#define CMS$_CONFIRM 10256665
#define CMS$_CONFLICTS 10256672
#define CMS$_CONGRP 10256683
#define CMS$_CONHIS 10256691
#define CMS$_CONRES 10256699
#define CMS$_CONVERTED 10256705
#define CMS$_CONVERTLIB 10256714
#define CMS$_COPIED 10256721
#define CMS$_COPIES 10256729
#define CMS$_CREATED 10256737
#define CMS$_CREATES 10256745
#define CMS$_DEFAULTDIR 10256754
#define CMS$_DELETED 10256761
#define CMS$_DELETIONS 10256769
#define CMS$_DIFFERENT 10256779
#define CMS$_DUPEDF 10256786            /*                                  */
#define CMS$_EDFMISS 10256794
#define CMS$_ELEEXISTS 10256802
#define CMS$_ELEEXP 10256811
#define CMS$_ELEXPIGN 10256816
#define CMS$_ENDOFLIST 10256826
#define CMS$_ENDPTRSTR 10256834
#define CMS$_EOF 10256840
#define CMS$_ERRANNOTATIONS 10256850
#define CMS$_ERRCLOSE 10256858
#define CMS$_ERRCOPIES 10256866
#define CMS$_ERRCREATES 10256874
#define CMS$_ERRDELETIONS 10256882
#define CMS$_ERRFETCHES 10256890
#define CMS$_ERRINSERTIONS 10256898
#define CMS$_ERRMODIFIES 10256906
#define CMS$_ERREMOVALS 10256914
#define CMS$_ERREPLACEMENTS 10256922
#define CMS$_ERRESERVATIONS 10256930
#define CMS$_ERRELEHIS 10256938
#define CMS$_ERRUNRESERVES 10256946
#define CMS$_ERRVER2 10256954
#define CMS$_ERRVERARC 10256962
#define CMS$_ERRVERCLS 10256970
#define CMS$_ERRVERCON 10256978
#define CMS$_ERRVEREDFS 10256986
#define CMS$_ERRVERELE 10256994
#define CMS$_ERRVERFRE 10257002
#define CMS$_ERRVERGRP 10257010
#define CMS$_ERRVERRES 10257018
#define CMS$_ERRVERSTR 10257026
#define CMS$_EXCLUDE 10257033
#define CMS$_EXIT 10257042
#define CMS$_FETCHED 10257049
#define CMS$_FETCHES 10257057
#define CMS$_FILEXISTS 10257067
#define CMS$_FILINUSE 10257075
#define CMS$_FIXCRC 10257083
#define CMS$_FIXHDR 10257091
#define CMS$_GENCREATED 10257097
#define CMS$_GENEXISTS 10257106
#define CMS$_GENINSERTED 10257113
#define CMS$_GENNOINSERT 10257122
#define CMS$_GENNOREMOVE 10257130
#define CMS$_GENNOTFOUND 10257138
#define CMS$_GENREMOVED 10257145
#define CMS$_GROUPEXP 10257155
#define CMS$_HASFILES 10257162
#define CMS$_HASMEMBERS 10257170
#define CMS$_HISNOTSTM 10257178
#define CMS$_HISTDEL 10257185
#define CMS$_IDENTICAL 10257193
#define CMS$_ILLCHAR 10257202
#define CMS$_ILLCLSNAM 10257210
#define CMS$_ILLCONREC 10257220
#define CMS$_ILLDATREC 10257228
#define CMS$_ILLEGALDEV 10257234
#define CMS$_ILLELENAM 10257242
#define CMS$_ILLELEXP 10257250
#define CMS$_ILLFORMAT 10257258
#define CMS$_ILLGEN 10257266
#define CMS$_ILLGRPNAM 10257274
#define CMS$_ILLHIST 10257284
#define CMS$_ILLNAME 10257290
#define CMS$_ILLNOTE 10257300
#define CMS$_ILLPAR 10257306
#define CMS$_ILLPOSVAL 10257314
#define CMS$_ILLREFDIR 10257322
#define CMS$_ILLRMK 10257330
#define CMS$_ILLSEQ 10257340
#define CMS$_ILLVAR 10257346
#define CMS$_INSERTED 10257353
#define CMS$_INSERTIONS 10257361
#define CMS$_INUSE 10257371
#define CMS$_INVFETDB 10257378
#define CMS$_INVLENGTH 10257388
#define CMS$_INVLIBDB 10257394
#define CMS$_INVOKERBK 10257403
#define CMS$_INVSTRDES 10257412
#define CMS$_ISMEMBER 10257418
#define CMS$_ISRESERVED 10257426
#define CMS$_LIBIS 10257435
#define CMS$_LIBSET 10257441
#define CMS$_MAXARG 10257452
#define CMS$_MERGECONFLICT 10257456
#define CMS$_MERGECOUNT 10257467
#define CMS$_MERGED 10257475
#define CMS$_MINARG 10257484
#define CMS$_MISBLKSTR 10257490
#define CMS$_MISMATCON 10257500
#define CMS$_MODIFIED 10257505
#define CMS$_MODIFICATIONS 10257513
#define CMS$_MSGBUILD 10257523
#define CMS$_MSGCANCEL 10257531
#define CMS$_MSGCONTINUE 10257539
#define CMS$_MSGPOST 10257547
#define CMS$_MSSBLKSTR 10257554
#define CMS$_MULTCALL 10257560
#define CMS$_MULTPAR 10257570
#define CMS$_MUSTBEDIR 10257578
#define CMS$_MUSTBEFIL 10257586
#define CMS$_MUSTBEPOS 10257594
#define CMS$_MUTEXC 10257602
#define CMS$_NEEDNUMBER 10257610
#define CMS$_NEEDPERIOD 10257618
#define CMS$_NETNOTALL 10257626
#define CMS$_NOALTDELETE 10257634
#define CMS$_NOANNOTATE 10257642
#define CMS$_NOBACKUP 10257652
#define CMS$_NOCHANGES 10257659
#define CMS$_NOCLOSE 10257668
#define CMS$_NOCLS 10257672
#define CMS$_NOCOMPARE 10257682
#define CMS$_NOCONCUR 10257690
#define CMS$_NOCONFIRM 10257696
#define CMS$_NOCONRES 10257706
#define CMS$_NOCONVERT 10257714
#define CMS$_NOCOPY 10257722
#define CMS$_NOCREATE 10257730
#define CMS$_NODELETE 10257738
#define CMS$_NODELFUTURE 10257746
#define CMS$_NOELE 10257752
#define CMS$_NOELEENT 10257762          /*                                  */
#define CMS$_NOERRLOG 10257770
#define CMS$_NOFETCH 10257778
#define CMS$_NOFILE 10257786
#define CMS$_NOGRP 10257792
#define CMS$_NOHIS 10257800
#define CMS$_NOHISPAR 10257810
#define CMS$_NOINSERT 10257818
#define CMS$_NOINPUT 10257826
#define CMS$_NOMATCH 10257834
#define CMS$_NOMODARG 10257842
#define CMS$_NOMODIFY 10257850
#define CMS$_NOMOREPARAM 10257858
#define CMS$_NORECOVER 10257866
#define CMS$_NOREF 10257874
#define CMS$_NOREMARK 10257882
#define CMS$_NOREMOVAL 10257890
#define CMS$_NOREPAIR 10257898
#define CMS$_NOREPEDF 10257906
#define CMS$_NOREPLACE 10257914
#define CMS$_NOREPRO 10257922
#define CMS$_NORES 10257928
#define CMS$_NORESERVATION 10257938
#define CMS$_NORESNOCON 10257946
#define CMS$_NORESRO 10257954
#define CMS$_NORMAL 10257961
#define CMS$_NOSINCE 10257970
#define CMS$_NOSRCHLST 10257978
#define CMS$_NOSUPERSEDE 10257986
#define CMS$_NOTBYCMS 10257994
#define CMS$_NOTCOMPLETED 10258002
#define CMS$_NOTCMSLIB 10258010
#define CMS$_NOTCRELIB 10258016
#define CMS$_NOTESVALREQ 10258024
#define CMS$_NOTFOUND 10258034
#define CMS$_NOTLOGGED 10258043
#define CMS$_NOTRESBYOU 10258050
#define CMS$_NOTSET 10258058
#define CMS$_NOTTHERE 10258066
#define CMS$_NOTWILD 10258073
#define CMS$_NOUNRESERVE 10258082
#define CMS$_NOVERIFY 10258090
#define CMS$_NOWLDCARD 10258098
#define CMS$_NULLARG 10258108
#define CMS$_NULLSTR 10258114
#define CMS$_NUMGENEXP 10258123
#define CMS$_OLDSYNTAX 10258131
#define CMS$_ONEPERIOD 10258138
#define CMS$_OPENIN 10258146
#define CMS$_OPENIN1 10258154
#define CMS$_OPENIN2 10258162
#define CMS$_OPENOUT 10258170
#define CMS$_OVERDRAFT 10258179
#define CMS$_POSVALREQ 10258186
#define CMS$_PROCEEDING 10258195
#define CMS$_QUALCONFLICT 10258202
#define CMS$_READERR 10258210
#define CMS$_READIN 10258218
#define CMS$_READONLY 10258226
#define CMS$_RECGRP 10258234
#define CMS$_RECNOTNEC 10258242
#define CMS$_RECOVERED 10258249
#define CMS$_REMARK 10258257
#define CMS$_REMOVALS 10258265
#define CMS$_REMOVED 10258273
#define CMS$_REPAIRED 10258281
#define CMS$_REPDEL 10258291
#define CMS$_REPEDF 10258299
#define CMS$_REPLACEMENTS 10258305
#define CMS$_RESERVATIONS 10258313
#define CMS$_RESERVED 10258321
#define CMS$_RESERVEDBYYOU 10258330
#define CMS$_SAMELINE 10258338
#define CMS$_SEQFAIL 10258348
#define CMS$_SEQUENCED 10258353
#define CMS$_STARTHIS 10258362
#define CMS$_STOPPED 10258369
#define CMS$_SYSTIMERR 10258378
#define CMS$_SYSTIMDIF 10258386
#define CMS$_TIMEORDER 10258394
#define CMS$_TOOLONG 10258402
#define CMS$_TRYAGNLAT 10258410
#define CMS$_UNDEFLIB 10258416
#define CMS$_UNFOUT 10258426
#define CMS$_UNRECTYPE 10258436
#define CMS$_UNRESERVED 10258441
#define CMS$_UNRESERVES 10258449
#define CMS$_UNSUPFRMT 10258458
#define CMS$_USERECOVER 10258466
#define CMS$_USEREPAIR 10258474
#define CMS$_USERERR 10258482
#define CMS$_USESETLIB 10258490
#define CMS$_VARLETTER 10258498
#define CMS$_VER2 10258507
#define CMS$_VERARC 10258515
#define CMS$_VERCLS 10258523
#define CMS$_VERCON 10258531
#define CMS$_VEREDF 10258539
#define CMS$_VEREDFERR 10258546
#define CMS$_VEREDFS 10258555
#define CMS$_VERELE 10258563
#define CMS$_VERFRE 10258571
#define CMS$_VERGRP 10258579
#define CMS$_VERIFIED 10258585
#define CMS$_VERLMTERR 10258594
#define CMS$_VERRES 10258603
#define CMS$_VERSTR 10258611
#define CMS$_WAITING 10258619
#define CMS$_WILDCONFLICT 10258626
#define CMS$_WILDMATCH 10258635
#define CMS$_WILDNOMATCH 10258642
#define CMS$_WILDVER 10258650
#define CMS$_WRITEERR 10258658
#define CMS$_ZEROADD 10258666
#define CMS$_ZLENBLK 10258674
#define CMS$_ERRHISLINE 10258682
#define CMS$_GENRECSIZE 10258690
#define CMS$_NOHISNOTES 10258699
#define CMS$_SIZEMISMAT 10258706
#define CMS$_CONTROLC 10258712
#define CMS$_INVFIXMRS 10258722
#define CMS$_REPGENMRS 10258731
#define CMS$_NOREPGENMRS 10258738
#define CMS$_GENNOTANC 10258746
#define CMS$_ERRPAREXP 10258754
#define CMS$_LIBALRINLIS 10258762
#define CMS$_LIBINSLIS 10258771
#define CMS$_LIBLISMOD 10258779
#define CMS$_LIBLISNOTMOD 10258786
#define CMS$_LIBNOTINLIS 10258794
#define CMS$_LIBREMLIS 10258803
#define CMS$_MSGUPDATE 10258811
#define CMS$_NOCOMMALIST 10258818
#define CMS$_NODELETIONS 10258826
#define CMS$_TOOMANYLIBS 10258834
#define CMS$_WILDNEEDED 10258842
#define CMS$_NOACCESS 10258850
#define CMS$_CONVNOTNEC 10258858
#define CMS$_MODACL 10258865
#define CMS$_NOMODACL 10258874
#define CMS$_MODACLS 10258881
#define CMS$_ERRMODACLS 10258890
#define CMS$_ILLSUBTYP 10258898
#define CMS$_ILLOBJTYP 10258906
#define CMS$_NOOBJTYP 10258914
#define CMS$_NODEFACL 10258922
#define CMS$_NOACE 10258928
#define CMS$_NOCMD 10258936
#define CMS$_ERRVERCMD 10258946
#define CMS$_VERCMD 10258955
#define CMS$_NOOBJ 10258960
#define CMS$_GENMULTRES 10258970
#define CMS$_ELEMULTRES 10258978
#define CMS$_IDENTNOTRES 10258986
#define CMS$_GENNOTRES 10258994
#define CMS$_REVPENDING 10259002
#define CMS$_NOREV 10259008
#define CMS$_ACCEPTED 10259017
#define CMS$_CANCELED 10259025
#define CMS$_MARKED 10259033
#define CMS$_REJECTED 10259041
#define CMS$_REVIEWED 10259049
#define CMS$_ACCEPTANCES 10259057
#define CMS$_CANCELATIONS 10259065
#define CMS$_MARKS 10259073
#define CMS$_REJECTIONS 10259081
#define CMS$_REVIEWS 10259089
#define CMS$_NOACCEPT 10259098
#define CMS$_NOCANCEL 10259106
#define CMS$_NOMARK 10259114
#define CMS$_NOREJECT 10259122
#define CMS$_NOREVIEW 10259130
#define CMS$_ERRACCEPTANCES 10259138
#define CMS$_ERRCANCELATIONS 10259146
#define CMS$_ERRMARKS 10259154
#define CMS$_ERRREJECTIONS 10259162
#define CMS$_ERRREVIEWS 10259170
#define CMS$_ALRDYMARKED 10259178
#define CMS$_NOREVPEND 10259186
#define CMS$_NOREVSPEND 10259194
#define CMS$_ILLACT 10259202
#define CMS$_AUTOREC 10259211
#define CMS$_AUTORECSUC 10259219
#define CMS$_GENDELETED 10259225
#define CMS$_NOGENDELETED 10259234
#define CMS$_GENDELETIONS 10259241
#define CMS$_ERRGENDELETIONS 10259250
#define CMS$_NOTDIRDES 10259258
#define CMS$_VARINRANGE 10259266
#define CMS$_GENRESREV 10259274
#define CMS$_INCRANGSPEC 10259282
#define CMS$_NODELGEN1 10259290
#define CMS$_NOGENS 10259298
#define CMS$_BADFORMAT 10259306
#define CMS$_OPENARC 10259314
#define CMS$_NORETRIEVE 10259322
#define CMS$_RETRIEVALS 10259329
#define CMS$_RETRIEVED 10259337
#define CMS$_ILLARCREC 10259346
#define CMS$_ERRETRIEVALS 10259354
#define CMS$_NOREFDIR 10259362
#define CMS$_DUPREF 10259370
#define CMS$_REFMISS 10259378
#define CMS$_NOREFELE 10259386
#define CMS$_REPREF 10259395
#define CMS$_NOREPREF 10259402
#define CMS$_VERREF 10259411
#define CMS$_VERREFERR 10259418
#define CMS$_VERREFS 10259427
#define CMS$_ERRVERREFS 10259434
#define CMS$_BADREF 10259442
#define CMS$_REFREPAIR 10259448
#define CMS$_NOTNOREF 10259458
#define CMS$_VERREFERRW 10259464
#define CMS$_REPCMD 10259475
#define CMS$_NOREPCMD 10259482
#define CMS$_REFMISMAT 10259490
#define CMS$_SUPERSEDE 10259499
#define CMS$_TOODEEP 10259506           /*                                  */
#define CMS$_EDFINWRONGDIR 10259514
#define CMS$_INVGENLRL 10259522
#define CMS$_NOEDFIWDREPAIR 10259530
#define CMS$_NOREPGENLRL 10259538
#define CMS$_REPGENLRL 10259547
#define CMS$_GENTOODEEP 10259554
#define CMS$_ANNSIGNAL 10259563
#define CMS$_VERILLDATREC 10259570
#define CMS$_REPILLDATREC 10259579
#define CMS$_SEQMISMAT 10259586
#define CMS$_NOREPSEQDATA 10259592
#define CMS$_MANCONLIB 10259602
#define CMS$_EXTFOUND 10259610
#define CMS$_EXTENDEDLIB 10259618
#define CMS$_NOEXTENDED 10259626
#define CMS$_NOEXTENDEDREF 10259634
#define CMS$_BADLST 10259642
#define CMS$_BADREFHDR 10259650
#define CMS$_DIFFCLASS 10259659
#define CMS$_ERRVERGEN 10259666
#define CMS$_FREBLKCON 10259675
#define CMS$_IDENTCLASS 10259681
#define CMS$_INCLIBVER 10259690
#define CMS$_LONGVARFOUND 10259698
#define CMS$_NOBCKPTR 10259706
#define CMS$_NODELACCESS 10259714
#define CMS$_NOGENBEFORE 10259722
#define CMS$_NOREPBCKPTR 10259730
#define CMS$_REPBADLST 10259739
#define CMS$_REPBADTYP 10259747
#define CMS$_REPBCKPTR 10259755
#define CMS$_REPCNTSTR 10259763
#define CMS$_REPENDPTR 10259771
#define CMS$_REPMISBLK 10259779
#define CMS$_TRUNCLST 10259786
	
#endif /* _cms$routines_h */
 
