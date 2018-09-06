/*
** Copyright (C) 2014 Association of Universities for Research in Astronomy, Inc.
** Contact: mschirme@gemini.edu
**  
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
** 
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
** 
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software 
** Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

/*
static char rcsid[] = "$Id: gmConvert2Cat.c,v 1.2 2011/04/25 18:27:32 gmmps Exp $";
 ************************************************************************
 ****      D A O   I N S T R U M E N T A T I O N   G R O U P        *****
 *
 * (c) <year>				(c) <year>
 * National Research Council		Conseil national de recherches
 * Ottawa, Canada, K1A 0R6 		Ottawa, Canada, K1A 0R6
 * All rights reserved			Tous droits reserves
 * 					
 * NRC disclaims any warranties,	Le CNRC denie toute garantie
 * expressed, implied, or statu-	enoncee, implicite ou legale,
 * tory, of any kind with respect	de quelque nature que se soit,
 * to the software, including		concernant le logiciel, y com-
 * without limitation any war-		pris sans restriction toute
 * ranty of merchantability or		garantie de valeur marchande
 * fitness for a particular pur-	ou de pertinence pour un usage
 * pose.  NRC shall not be liable	particulier.  Le CNRC ne
 * in any event for any damages,	pourra en aucun cas etre tenu
 * whether direct or indirect,		responsable de tout dommage,
 * special or general, consequen-	direct ou indirect, particul-
 * tial or incidental, arising		ier ou general, accessoire ou
 * from the use of the software.	fortuit, resultant de l'utili-
 * 					sation du logiciel.
 *
 ************************************************************************
 *
 * FILENAME
 * gmFits2Cat
 *
 * PURPOSE:
 * Convert a fits binary table to ascii catalog.
 *
 * FUNCTION NAME(S)
 * setHeaderUnit	- Get ext. hdr info, and save extra keywords to 
 *			  catalog file.
 * getTableValue	- Get a tables value.
 * getDbValue		- Get a double keyword value.
 * saveColInfo		- Save column information.
 *
 *
 * gmFits2Cat [inputFileRootName, without fits extension in name]
 *
 * Input:
 *   Fits file, must have a binary table extension.  If there is more
 *   than one, it will take the first one.  This is the
 *   table that will be converted to an ascii catalog.
 *
 * Output:
 *   catalog file ( inputFileRootName.cat )
 *   - Contains important hdr information required by Skycat
 *
 *
 *INDENT-OFF*
 * $Log: gmConvert2Cat.c,v $
 * Revision 1.2  2011/04/25 18:27:32  gmmps
 * Forked from 0.401.12 .
 *
 * Revision 1.2  2011/01/25 22:44:50  gmmps
 * Wave_ccd .fits bug fixed.
 *
 * Revision 1.1  2011/01/24 20:02:13  gmmps
 * Compiled for RedHat 5.5 32 and 64 bit.
 *
 * Revision 1.10  2003/02/05 23:20:15  callen
 * added new "Convert and Load ODF from FITS" menuitem
 *
 * Revision 1.9  2003/02/05 01:21:03  callen
 * changes to the GUI
 *
 * Revision 1.8  2003/01/17 13:38:02  callen
 * these files changed tonight for these additions:
 * NODSIZE/SHUFSIZE or BANDSIZE/SHUFSIZE into FITS ODF header
 * slitwidth given via LabelEntry (not slider)
 * save and load *.bands files for values in bandGUI
 * clear bands:
 * debugging output for linux bug
 *
 * Modified Files:
 *  	band_def_UI.tcl gmConvert2Cat.c gmMakeMasks.cc gmmps_spoc.tcl
 *  	vmAstroCat.tcl vmTableList.tcl
 *
 * Revision 1.7  2002/10/14 08:28:33  callen
 * cleaning
 *
 * Revision 1.6  2002/10/09 00:07:45  callen
 * fixed two issues: one, the table headers needed to start at one
 * the other, was a duplication of the tableinfo headers due to processing
 * in the tcl code.
 *
 * Revision 1.5  2002/10/08 22:37:04  callen
 * this version stores the table related keywords in an accurate form that
 * does not interfere with the other processes that are a part of gmmps
 *
 * Revision 1.3  2002/08/24 04:00:20  callen
 * the main change was in gmCat2Fits.c so that RA stored in degrees in cat files
 * is converted to hours in the FITS file which the astronomers prefer (as requested
 * buy Inger and Kathy).  The change in gmConvert2Cat.c is just a comment to point
 * out where the RA is multiplied by 15, which is the conversion from hours to degrees.
 *
 * Revision 1.2  2002/08/20 00:20:27  callen
 * mapping "id" to "ID" regardless of the case in the input .fits file
 *
 * Revision 1.1.1.1  2002/07/19 00:02:09  callen
 * importing gmmps as recieved from Jennifer Dunn
 * gmmps is a skycat plugin and processes for creating masks
 *
 *INDENT-ON*
 *
 ****      D A O   I N S T R U M E N T A T I O N   G R O U P        *****
 ************************************************************************
*/

/*
 *  Includes
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <fitsio.h>


/*
 *  Local Defines
 */


/*
 *  Function Prototypes
 */

int	setHeaderUnit ( fitsfile   *fp, FILE *cat, int        num);
char *  getTableValue ( fitsfile *fp, long row, int order, int col);
int	getDbValue ( fitsfile	*fp, char *name, double *val, int *status);
int	saveColInfo ( int, char *, char *, char *, char *, int, int *);

/*
 *  Globals & Data Structures
 */

long headStart = 0;
long dataStart = 0;
long dataEnd = 0;
long hdrLen = 0;
long dataLen = 0;
double width = 0;
double pixScale = 0;
double height = 0;
double bscale = 0;
double xbzero = 0;
static char buf_[1024];

#define MAX_ID_LEN	16
#define MAX_NUM_COLS    100	
#define MAX_VALUE_LEN    128

typedef struct {
    int	      colNum;
    int	      flag;			/* If set, indicates its slittype*/
    char      name[MAX_ID_LEN];         /* name of columne */
    char      unit[MAX_VALUE_LEN];      /* unit name e.g. "arcsec" */     
    char      form[MAX_VALUE_LEN];      /* fits data type */              
    char      disp[MAX_VALUE_LEN];      /* display string for formating */
} COL_INFO;

static COL_INFO  columnOrder[MAX_NUM_COLS];


/*
 *  Macros
 */


#define TEST(x) {if (!(x)){    \
	printf("Converting fits file to catalog failed.\nFits function failed, line:%d\n", __LINE__);  \
	return(1) ;}}


#define GET (fp, name, val, stat )   \
    { if (fits_read_key(fp, TDOUBLE, (char*)name, &val, NULL, &stat) != 0)	\
	{ printf("Failed to get %s.\n", name); return (-1);} }					

/*
 ************************************************************************
 *+
 * FUNCTION: gmFits2Cat
 *
 * RETURNS: int [success or failure]
 *
 * DESCRIPTION: Main entry point to function.
 *
 * [NOTES:]:
 *-
 ************************************************************************
 */

int main (int argc, char *argv[]) {
  /*
   * Internal variables.
   */
  
  char fileRoot[248] = "test";
  char fileFits[248] = "test";
  char fileCat[248]  = "test";
  fitsfile *infits; /* Input fits file.	*/
  int  status=0;    /* Status .		*/
  long rows = 0;    /* Num rows in bin. tbl */
  int  cols = 0;    /* Num cols in bin. tbl */
  int  num = 0;	    /* Num hdu's in fits fil*/
  FILE *cat;	    /* Ptrs to catalog & fits header files.	*/
  int  i, j, k;	    /* Counters.		*/
  char keyword[16]; /* Store keyword name.  */
  char *p;	    /* Ptr.			*/
  char colname[16]; /* Name of a column.	*/
  char unitname[MAX_VALUE_LEN]; /* Unit type for column */
  char formstr[MAX_VALUE_LEN];  /* Form type for column (fits data type) */
  char dispstr[MAX_VALUE_LEN];  /* display type for column */
  int hdutype;		 /* Type of fits hdu.    */

  /* no idea why I need these here when i don't need to do that for the other columns? */
  COL_INFO slittype;	 /* Slittype column info. */
  COL_INFO priority;	 /* priority column info. */
  COL_INFO redshift;	 /* redshift column info. */
  COL_INFO specleft;	 /* specbox column info. */
  COL_INFO specright;	 /* specbox column info. */
  COL_INFO specbottom;	 /* specbox column info. */
  COL_INFO spectop;	 /* specbox column info. */

  /*
   *  Default test file is test.fits, or the first cmd line argument
   */

  if (argc == 2)
    (void) strncpy( fileRoot, argv[1], 243 );
  else {
    printf("USAGE: argv[0] <catalog>\n");
    printf("----------------------------------------------------\n");
    printf("PAR 1: Input ascii catalog that is converted to FITS.\n");
    return (-1);
  }


  /*
   *  Create the fits file name and catalog filename.
   */

  sprintf(fileFits,"%s.fits",fileRoot);
  sprintf(fileCat,"%s.cat",fileRoot);
  
  /*
   *  Open the input fits file for reading.
   */

  if ( ffopen( &infits, fileFits, READONLY, &status ) ) {
    printf( "Failed to ffopen %s <%d>.\n", fileFits, status );
    return(-1);
  }

  /*
   *  Open & Write the header to the cat file.
   *  First put in the standard catalog information.
   */

  if ( (cat = fopen( fileCat, "w" ))== NULL ) {
    printf("Cannot open %s catalog file for writing.\n", fileCat);
    return(-1);
  }
  fprintf( cat, "QueryResult\n\n" );
  fprintf( cat, "# Config entry for original catalog server:\n");
  fprintf( cat, "serv_type: local\n");
  fprintf( cat, "long_name: %s\n", "Joe");
  fprintf( cat, "short_name: %s\n", "Joe");
  fprintf( cat, "url: %s\n", "Joe");
  fprintf( cat, "# Fits keywords\n");

  /*
   *  Get the primary header type.  *  Remove later.
   *  Get the number of header units
   */
  
  num = 0;
  fits_get_hdu_type(infits, &hdutype, &status);
  TEST(! fits_get_num_hdus(infits, &num, &status ));
  if ( num > MAX_NUM_COLS ) {
    printf("Too many columns.\n");
    return(-1);
  }

  /* 
   *  Cycle thru till you find one that is a binary table.
   *  Copy all keywords in the extens. hdr to the cat file.
   */

  TEST(!setHeaderUnit(infits, cat, num) );

  /*
   *  Get # rows & columns.
   */
  
  if (fits_get_num_rows(infits, &rows, &status) != 0 ||
      fits_get_num_cols(infits, &cols, &status) != 0)
    return(-1);
  
  /*
   *  Clear out the array containing col information.
   */

  for(j=0; j<MAX_NUM_COLS ;j++ ) {
    columnOrder[j].colNum = 0;
    columnOrder[j].flag = 0;
  }

  /*
   *  Determine the column headers and put them in order.
   *  Set flags, then cycle thru column headings and save that
   *  information in an order that we can use.
   */

  slittype.colNum = 0;
  slittype.flag = 0;
  priority.colNum = 0;
  priority.flag = 0;
  redshift.colNum = 0;
  redshift.flag = 0;
  specleft.colNum = 0;
  specleft.flag = 0;
  specright.colNum = 0;
  specright.flag = 0;
  specbottom.colNum = 0;
  specbottom.flag = 0;
  spectop.colNum = 0;
  spectop.flag = 0;
  
  k=3;
  for(j = 1; j <= cols; j++) {
    /*	ffgrec(infits, 0, card, &status); 
	printf ("%s\n", card);
    */
    sprintf(keyword, "TTYPE%d", j);
    /*	if (fits_read_key(infits, TSTRING, (char*)keyword, colname, */
    if (fits_read_key(infits, TSTRING, (char*)keyword, colname, 
		      NULL, &status) != 0) { 
      printf("Failed to get %s.\n", keyword);
      return(-1);
    }
    
    /* the following we want but we do not fail if not present (although
       perhaps we should as we expect they must be present to have a
       valid fits file...
    */
    unitname[0]=0;
    formstr[0]=0;
    dispstr[0]=0;
    
    /*	fits_read_record(infits, 0, card, &status); */
    sprintf(keyword, "TUNIT%d", j);
    fits_read_key(infits, TSTRING, (char *)keyword, unitname, NULL, &status);
    status = 0;
    
    sprintf(keyword, "TFORM%d", j);
    fits_read_key(infits, TSTRING, (char *)keyword, formstr, NULL, &status);
    status = 0;
    
    sprintf(keyword, "TDISP%d", j);
    fits_read_key(infits, TSTRING, (char *)keyword, dispstr, NULL, &status);
    status = 0;
    
    printf("Column %d, TTYPE%d = %s, TUNIT%d = %s, TFORM%d = %s, TDISP%d = %s\n", j,
	   j, colname,
	   j, unitname,
	   j, formstr,
	   j, dispstr);
    
    
    /*
     * Check for the col's named:ID, RA, DEC
     */
    
    if ( strncmp( colname, "ID", 2 ) == 0 ||  
	 strncmp( colname, "id", 2 ) == 0 )
      (void) saveColInfo(j, "ID", unitname, formstr, dispstr, 0, &k );
    else if ( strncmp( colname, "ra", 2 ) == 0  ||
	      strncmp( colname, "RA", 2 ) == 0 )
      (void) saveColInfo(j, "RA", unitname, formstr, dispstr, 1, &k );
    else if ( strncmp( colname, "dec", 3 ) == 0  ||
	      strncmp( colname, "DEC", 3 ) == 0 )
      (void) saveColInfo(j, "DEC",  unitname, formstr, dispstr, 2, &k );
    /*
     *  Check for col's named: slittype, priority.
     */
    else if ( strncmp( colname, "slittype", 8 ) == 0  ) {
      if ( slittype.colNum == 0 ) {
	strncpy( slittype.name, colname, MAX_ID_LEN );
	slittype.colNum = j;
	slittype.flag = 1;
      }
      else {
	printf("Warning, duplicate slittype columns.\n");
	i = saveColInfo(j, colname,  unitname, formstr, dispstr, k, &k );
	k = (i)? k+1 : k ;
      }
    }
    else if ( strncmp( colname, "priority", 8 ) == 0  )	{
      if ( priority.colNum == 0 ) {
	strncpy( priority.name, colname, MAX_ID_LEN );
	priority.colNum = j;
	priority.flag = 1;
      }
      else {
	printf("Warning, duplicate priority columns.\n");
	i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
	k = (i) ? k+1 : k ;
      }
    }
    else if (strncmp( colname, "redshift", 8) == 0 ) {
      if ( redshift.colNum == 0 ) {
	strncpy( redshift.name, colname, MAX_ID_LEN );
	redshift.colNum = j;
	redshift.flag = 1;
      }
      else {
	printf("Warning, duplicate redshift columns.\n");
	i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
	k = (i)? k+1 : k ;
      }	
    }
    else if (strncmp( colname, "specleft", 8) == 0 ) {
      if ( specleft.colNum == 0 ) {
	strncpy( specleft.name, colname, MAX_ID_LEN );
	specleft.colNum = j;
	specleft.flag = 1;
      }
      else {
	printf("Warning, duplicate specleft columns.\n");
	i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
	k = (i)? k+1 : k ;
      }
    }
    else if (strncmp( colname, "specright", 8) == 0 ) {
      if ( specright.colNum == 0 ) {
	strncpy( specright.name, colname, MAX_ID_LEN );
	specright.colNum = j;
	specright.flag = 1;
      }
      else {
	printf("Warning, duplicate specright columns.\n");
	i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
	k = (i)? k+1 : k ;
      }
    }
    else if (strncmp( colname, "specbottom", 8) == 0 ) {
      if ( specbottom.colNum == 0 ) {
	strncpy( specbottom.name, colname, MAX_ID_LEN );
	specbottom.colNum = j;
	specbottom.flag = 1;
      }
      else {
	printf("Warning, duplicate specbottom columns.\n");
	i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
	k = (i)? k+1 : k ;
      }
    }
    else if (strncmp( colname, "spectop", 8) == 0 ) {
      if ( spectop.colNum == 0 ) {
	strncpy( spectop.name, colname, MAX_ID_LEN );
	spectop.colNum = j;
	spectop.flag = 1;
      }
      else {
	printf("Warning, duplicate spectop columns.\n");
	i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
	k = (i)? k+1 : k ;
      }
    }
    else {
      i = saveColInfo(j, colname, unitname, formstr, dispstr, k, &k );
      k = (i) ? k+1 : k ;
    }
  } /* Finished getting column order. */
  
  /*
   *  Do any re-ordering: if we have slittype column, then
   *  add then on to the end of the columnOrder array, AND
   *  if we have priority, then add that after slittype.
   *
   * wave_ccd needs to be in position 16. - dfennell
   */
  
  if ( priority.colNum != 0 )   columnOrder[k++] = priority;
  if ( slittype.colNum != 0 )   columnOrder[k++] = slittype;
  if ( redshift.colNum != 0 )   columnOrder[k++] = redshift;
  if ( specleft.colNum != 0 )   columnOrder[k++] = specleft;
  if ( specright.colNum != 0 )  columnOrder[k++] = specright;
  if ( specbottom.colNum != 0 ) columnOrder[k++] = specbottom;
  if ( spectop.colNum != 0 )    columnOrder[k++] = spectop;

  /*
   *  Check to make sure you have ID, RA, DEC.
   */
  
  if ( columnOrder[0].colNum==0 ||  columnOrder[1].colNum==0 ||
       columnOrder[2].colNum==0 ) {
    printf("Error, missing necessary column (ID, RA or DEC).\n");
    printf("Names for 0,1,2 are %s,%s,%s", 
	   columnOrder[0].name,
	   columnOrder[1].name,
	   columnOrder[2].name);
    
    return(-1);
  }
  
  /*
   *  Write out column headers.
   */
  
  for (j=0; j<cols; j++) {
    if (j!=0) fprintf( cat, "\t");
    printf("colHead=%s\n", columnOrder[j].name );
    fprintf(cat, "%s", columnOrder[j].name );
  }
  fprintf( cat, "\n");
  
  /*
   *  Write out underscores.
   */
  
  for (j=0; j<cols; j++) {
    if (j!=0) fprintf( cat, "\t");
    /*
     *  Make underlines 1 larger then name - incase any column
     *  name is just 1 character.  vmAstroCat looks for 2 underlines.
     */
    
    for (i=0; i<=((int)strlen(columnOrder[j].name)); i++)
      fprintf(cat, "-" );
  }
  fprintf( cat, "\n");
  
  /*
   *  Cycle thru the rows/cols, writing all the data to a file.
   *  Note, if we hit the slittype column and it is not last,
   *  then make it be the last column.
   */
  
  for(i = 1; i <= rows; i++) {
    for( k = 0; k < cols; k++) {
      p = getTableValue(infits, i, k, columnOrder[k].colNum );
      TEST(p != NULL);
      if ( k != 0 ) fprintf( cat, "\t" );
      fprintf(cat, "%s", p);
    } 
    fprintf(cat, "\n");
  }
  
  ffclos( infits, &status );
  fclose( cat );
  
  return 0;
}

/*
************************************************************************
*+
* FUNCTION: setHeaderUnit
*
* RETURNS: int [success or failure]
*
* DESCRIPTION: Find the binary table extension
*
* [NOTES:]:
*-
************************************************************************
*/

int setHeaderUnit
(
 fitsfile *fp,		/* (in)  File ptr.		*/
 FILE	*cat,		/* (in)  Catalog file ptr.	*/
 int    num		/* (in)  Number of header units	*/
 )
{
  int status = 0;
  int type = 0;		/* Type of extension.		*/
  int nkeys = 0;	/* Num of keywords in extension hdr.	*/
  int i;
  char	card[FLEN_CARD];
  char	value[FLEN_VALUE];
  char	comment[FLEN_COMMENT];

  while (num>0) {
    if (fits_movabs_hdu(fp, num, &type, &status) != 0) {
      printf("Failed to move to a fits header.\n");
      return ( 1 );
    }
    if (fits_get_hdu_type(fp, &type, &status) != 0 ) {
      printf("Failed to get type of fits header.\n");
      return ( 1 );
    }
    
    /*
     *  Check to see if we have found the correct extension.
     */
    
    if ( type == BINARY_TBL ) break;
    num--;
  }
  
  /*
   *  If num is zero, then we did not find a binary table.
   */
  
  if (num==0) return (1);
  
  /*
   *  Determine num of keywords in this extension hdr, cause
   *  we need to get the pixel scale out, and save "other"
   *  keywords for the final output.
   */
  
  if ( (fits_get_hdrspace(fp, &nkeys, NULL, &status )) != 0 )
    return( 1 );
  for ( i=1; i <= nkeys; i++ ) {
    status = 0;
    fits_read_record(fp, i, card, &status );
    
    if ( strlen(card) < 9 ) continue;
    if ( strncmp(card, "TTYPE", 5 )    != 0 &&
	 strncmp(card, "TUNIT", 5 )    != 0 &&
	 strncmp(card, "XTENSION", 8 ) != 0 &&
	 strncmp(card, "TFORM", 5 )    != 0 &&
	 strncmp(card, "TNULL7", 6 )   != 0 &&
	 strncmp(card, "TDISP", 5 )    != 0 &&
	 strncmp(card, "NAXIS", 5 )    != 0 &&
	 strncmp(card, "TFORM", 5 )    != 0 &&
	 strncmp(card, "TDISP", 5 )    != 0 &&
	 strncmp(card, "BITPIX", 6 )   != 0 &&
	 strncmp(card, "NAXIS", 5 )    != 0 &&
	 strncmp(card, "PCOUNT", 6 )   != 0 &&
	 strncmp(card, "PIXSCALE", 8 ) != 0 &&
	 strncmp(card, "GCOUNT", 6 )   != 0 &&
	 strncmp(card, "TFIELDS", 7 )  != 0 &&
	 strncmp(card, "EXTNAME", 7 )  != 0 &&
	 strncmp(card, "END", 3 )      != 0 ) {
      /*
       *  Got a valid keyword, save in the catalog file.
       *  Only write the card, it contains the keyword and
       *  sometimes a comment
       */
      printf("card=%s\n", card);
      fits_parse_value(card, value, comment, &status );
      fprintf( cat, "#fits %s\n", card );
      /*printf( "#fits %s....\n", card );*/
    }
  }

  /* 
   * Get the pixelScale, naxis1, naxis2.
   */
  
  width = height = pixScale = 0.0;
  TEST( !getDbValue(fp, "NAXIS1", &width, &status));
  TEST( !getDbValue(fp, "NAXIS2", &height, &status));

  /* pseudo-image OT tables don't always (?) have PIXSCALE, hence comment this out:
  fits_read_key(fp, TDOUBLE, "PIXSCALE", &pixScale, NULL, &status);
  if (pixScale == 0.0) {
    fprintf(stderr, "%s\n", "ERROR: gmConvert2Cat: PIXSCALE not found!");
    exit (1);
  }
  */
  
  /*printf("PixelScale=%f\n", pixScale );*/
  
  /* 
   * Write the end of the catalog file.
   */
  
  //  fprintf( cat, "#fits PIXSCALE = %f\n", pixScale );
  fprintf( cat, "# End fits keywords\n");
  fprintf( cat, "# Curved slits\n");
  fprintf( cat, "# End curved slits\n");
  fprintf( cat, "# End config entry\n\n");

  return 0;
}

/*
************************************************************************
*+
* FUNCTION: getTableValue
*
* RETURNS: int [success or failure]
*
* DESCRIPTION: Get a value from the table.
*
* [NOTES:]:
*-
************************************************************************
*/

char * getTableValue
(
 fitsfile *fp,		/* (in)  Fits file ptr.		*/
 long	row, 		/* (in)  Row number.		*/
 int	order,		/* (in)  Column order number.	*/
 int	col		/* (in)  Column number.		*/
 )
{
  int status = 0;
  int typecode = 0;
  int anynulls = 0;
  long repeat = 0;
  long Width = 0;
  char* p[1];
  const char *c2;
  long l;
  unsigned long ul;
  double d;
  char c;
  
  
  buf_[0] = '\0';
  
  /*
   *  Get the column type.
   */
  
  if (fits_get_coltype(fp, col, &typecode, &repeat, &Width, &status) != 0) {
    printf("Getting column type field, col#=%d.\n", col);
    return NULL;
  }
  
  /*
   *  Check that its not too big.
   */
  
  if ((int)Width > (int)(sizeof(buf_)-1) ) {
    printf("FITS table value at row %d, col %d is too long.\n", 
	   (int)row, col);
    return NULL;
  }
    
  /*
   *  Depending on the datatype, get the value.
   */
  
  switch(typecode) {
  case TSTRING:
    p[0] = buf_;
    if (fits_read_col(fp, TSTRING, col, row, 1, 1, (char *)"", 
		      p, &anynulls, &status) != 0) {
      printf("Failed to read string, col#=%d, row=%ld.\n", col, row);
      return NULL;
    }
    
    /*
     *  Check for slittype column, and convert if longer than 1
     *  character.
     */
    if ( columnOrder[order].flag && strlen(buf_)>1 ) {
      c2 = &buf_[0];
      c = toupper(*c2);
      buf_[0] = c;
      buf_[1] = '\0';
    }
    break;
    
  case TBYTE:
  case TSHORT:
  case TINT:
  case TLONG:
    if (fits_read_col(fp, TLONG, col, row, 1, 1, NULL, 
		      &l, &anynulls, &status) != 0) {
      printf("Failed to read long val, col#=%d, row=%ld.\n", col, row);
      return NULL;
    }
    /*
     *  If this is the ra column, then we need to 
     *  divide by 15.
     */
    
    if ( order == 1 ) l *= 15;
    
    sprintf(buf_, "%ld", l);
    break;
    
  case TUSHORT:
  case TUINT:
  case TULONG:
    if (fits_read_col(fp, TULONG, col, row, 1, 1, NULL, 
		      &ul, &anynulls, &status) != 0) 
      {
	printf("Failed to read ulong, col#=%d, row=%ld.\n", col, row);
	return NULL;
      }
    
    /*
     *  If this is the ra column, then we need to 
     *  divide by 15.
     */
    
    if ( order == 1 ) ul *= 15;
    sprintf(buf_, "%lu", ul);
    break;
    
  case TFLOAT:
  case TDOUBLE:
    if (fits_read_col(fp, TDOUBLE, col, row, 1, 1, NULL, 
		      &d, &anynulls, &status) != 0) {
      printf("Failed to read double, col#=%d, row=%ld.\n", col, row);
      return NULL;
    }
    
    /*
     *  If this is the ra column, then we need to 
     *  divide by 15.
     * @@note: @@cba: this is to convert from hours to degrees
     */
    
    if ( order == 1 ) d *= 15;
    
    sprintf(buf_, "%f", d);
    break;
    
  case TLOGICAL:
    if (fits_read_col(fp, TLOGICAL, col, row, 1, 1, NULL, 
		      &c, &anynulls, &status) != 0) 
      {
	printf("Failed to read logical, col#=%d, row=%ld.\n", col, row);
	return NULL;
      }
    buf_[0] = (c ? 'T' : 'F');
    buf_[1] = '\0';
    break;
    
  default:
    printf("Null data type, col#=%d, row=%ld.\n", col, row);
    return NULL;
  }
  
  /*
   *  Return a ptr to the value.
   */
  return buf_;
}

/*
************************************************************************
*+
* FUNCTION: getDbValue
*
* RETURNS: int [success or failure]
*
* DESCRIPTION: Get a double value from the table.
*
* [NOTES:]:
*-
************************************************************************
*/

int getDbValue
(
 fitsfile     *fp,		/* (in)  Input fits file.	*/
 char         *name,		/* (in)  Name of the col to get.*/
 double       *val, 		/* (out) Return value.          */
 int          *status		/* (out) Return status.		*/
 )
{
  if (fits_read_key(fp, TDOUBLE, (char*)name, val, NULL, status) != 0) {
    printf("Failed to get double value for %s, %d.\n", name, *status );
    *status = 0;
    return (1); 
  }
  return 0;
}

/*
************************************************************************
*+
* FUNCTION: saveColInfo
*
* RETURNS: int [success or failure]
*
* DESCRIPTION: Write the primary hdr unit for later.
*
* [NOTES:]:
*-
************************************************************************
*/

int	saveColInfo
(
 int	colNum,	     /* (in)  File ptr.		           */
 char   *name,	     /* (in)  File ptr.	      	           */
 char   *unit,       /* (in)  unit name e.g. "arcsec"      */     
 char   *form,	     /* (in)  fits data type               */              
 char   *disp,	     /* (in)  display string for formating */
 int	arrayIndex,  /* (in)  Index.			   */
 int    *backupIndex /* (in)  Index to write to if arrayIndex is already written to. */
 )
{
  if (columnOrder[arrayIndex].colNum==0) {
    columnOrder[arrayIndex].colNum = colNum;
    strncpy( columnOrder[arrayIndex].name, name, MAX_ID_LEN );
    strncpy( columnOrder[arrayIndex].unit, unit, MAX_VALUE_LEN );
    strncpy( columnOrder[arrayIndex].form, form, MAX_VALUE_LEN );
    strncpy( columnOrder[arrayIndex].disp, disp, MAX_VALUE_LEN );
    /*printf("Got %d: %s - arrayIndex=%d.\n", columnOrder[arrayIndex].colNum, columnOrder[arrayIndex].name,
      arrayIndex);*/
    return (1);
  }
  else {
    printf("Warning, duplicated column names: %s.\n", name );
    columnOrder[*backupIndex].colNum = colNum;
    strncpy( columnOrder[*backupIndex].name, name, MAX_ID_LEN );
    strncpy( columnOrder[*backupIndex].unit, unit, MAX_VALUE_LEN );
    strncpy( columnOrder[*backupIndex].form, form, MAX_VALUE_LEN );
    strncpy( columnOrder[*backupIndex].disp, disp, MAX_VALUE_LEN );
    /* printf("Got %d: %s - backupIndex=%d.\n", columnOrder[*backupIndex].colNum, columnOrder[*backupIndex].name,
     *backupIndex);*/
    *backupIndex=*backupIndex+1;
    return (0);
  }
}
