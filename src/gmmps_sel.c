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

/*$Id: gmmps_sel.c,v 1.2 2011/04/25 18:27:33 gmmps Exp $

 ************************************************************************
 ****      D A O   I N S T R U M E N T A T I O N   G R O U P        *****
 *
 * (c) 2000                         (c) 2000
 * National Research Council        Conseil national de recherches
 * Ottawa, Canada, K1A 0R6          Ottawa, Canada, K1A 0R6
 * All rights reserved              Tous droits reserves
 * 					
 * NRC disclaims any warranties,    Le CNRC denie toute garantie
 * expressed, implied, or statu-    enoncee, implicite ou legale,
 * tory, of any kind with respect   de quelque nature que se soit,
 * to the software, including       concernant le logiciel, y com-
 * without limitation any war-      pris sans restriction toute
 * ranty of merchantability or      garantie de valeur marchande
 * fitness for a particular pur-    ou de pertinence pour un usage
 * pose.  NRC shall not be liable   particulier.  Le CNRC ne
 * in any event for any damages,    pourra en aucun cas etre tenu
 * whether direct or indirect,      responsable de tout dommage,
 * special or general, consequen-   direct ou indirect, particul-
 * tial or incidental, arising      ier ou general, accessoire ou
 * from the use of the software.    fortuit, resultant de l'utili-
 *                                  sation du logiciel.
 *
 ************************************************************************
 *
 * FILENAME
 * gmmps_sel.c
 *
 * PURPOSE:
 * Routine for object selection
 *
 * FUNCTION NAME(S)
 * 
 *
 *# Originially created by:
 *# E.S.O. - VLT project
 *#
 *# Originially created by:
 *# bottini  24/01/00  created
 *
 * SYNOPSIS
 * gmmps_sel <input_cat> <ra> <dec> <radius1> <radius2> <nrows><ncols> 
 *            [for ncols, give the following:
 *		<searchCols, minVals, maxVals>
 * 
 * DESCRIPTION
 * Routine for object selection. Output is the search query.
 * Called by vmAstroQuery  do_query{}
 * This function will ALWAYS select row's whose priority is < 3
 * REGARDLESS of whether the line is within range or not.  This is REALLY
 * WEIRD, but someone thought it was a good idea.
 * 
 ********* HUGE WARNING, ASSUME RA&DEC COL'S ARE NEXT TO EACH OTHER.*
 * PARAMETER
 * <input> catalog input full file name
 * <posRa posDec> RA and DEC field position
 * <r1, r2 > area radius
 * <nrow> max number of objects
 * <nsearchcols> number of search columns
 * <searchcols> name of search columns
 * <minvalues> minimum values for search columns criterium
 * <maxvalues> maximun values for search columns criterium
 *
 *INDENT-OFF*
 * $Log: gmmps_sel.c,v $
 * Revision 1.2  2011/04/25 18:27:33  gmmps
 * Forked from 0.401.12 .
 *
 * Revision 1.1  2011/01/24 20:02:14  gmmps
 * Compiled for RedHat 5.5 32 and 64 bit.
 *
 * Revision 1.2  2007/03/20 04:32:16  callen
 * cast a variable to silence a warning
 *
 * Revision 1.1.1.1  2002/07/19 00:02:09  callen
 * importing gmmps as recieved from Jennifer Dunn
 * gmmps is a skycat plugin and processes for creating masks
 *
 * Revision 1.6  2002/05/07 22:31:43  dunn
 * *** empty log message ***
 *
 * Revision 1.5  2001/11/27 23:06:48  dunn
 * change of name.
 *
 * Revision 1.4  2001/10/11 21:04:06  dunn
 * Changed comment.
 *
 * Revision 1.3  2001/07/17 19:44:28  dunn
 * Got rid of some comments
 *
 * Revision 1.2  2001/04/25 17:01:01  dunn
 * Initial revisions.
 *
 *INDENT-ON*
 *
 ****      D A O   I N S T R U M E N T A T I O N   G R O U P        *****
 ************************************************************************
*/

/*
 *  Local Defines
 */


#if defined(__STDC__) && \
                         (defined(_H_STANDARDS) || \
                          defined(_SYS_STDSYMS_INCLUDED) || \
                          defined(_STANDARDS_H_))
#endif
#define _POSIX_SOURCE 1

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <astroCatalog.h>


/*
 *  Local Types
 */


/*
 *  Function Prototypes *** ALL LOCAL FUNCTIONS TO BE PROTOTYPED ***
 */


/*
 *  Data Structures
 */


/*
 *  Macros
 */

#define DEBUG_NONE       0       /* Indicates none debug level.   */
#define DEBUG_MIN        1       /* Indicates minimum debug level.*/
#define DEBUG_FULL       2       /* Indicates full debug level.   */
#define DEBUG_MAX        3       /* Indicates max debug level.    */

int	gmSelLocalDebugLevel = DEBUG_NONE;


#define DEBUG5(dbgLevel, FMT, V1, V2, V3, V4, V5)	\
  if (dbgLevel <= gmSelLocalDebugLevel ) {		\
    if (FMT != (char *) NULL) {				\
      (void) printf(FMT, V1, V2, V3, V4, V5 );		\
    }							\
  }

#define DEBUG4(dbgLevel, FMT, V1, V2, V3, V4)		\
  if (dbgLevel <= gmSelLocalDebugLevel ) {	 	\
    if (FMT != (char *) NULL) {				\
      (void) printf(FMT, V1, V2, V3, V4);		\
    }							\
  }

#define DEBUG3(dbgLevel, FMT, V1, V2, V3)		\
  if (dbgLevel <= gmSelLocalDebugLevel ) {	 	\
    if (FMT != (char *) NULL)	{			\
      (void) printf(FMT, V1, V2, V3);			\
    }							\
  }

#define DEBUG2(dbgLevel, FMT, V1, V2)			\
  if (dbgLevel <= gmSelLocalDebugLevel ) {	 	\
    if (FMT != (char *) NULL)	{			\
      (void) printf(FMT, V1, V2);			\
    }							\
  }

#define DEBUG1(dbgLevel, FMT, V1)			\
  if (dbgLevel <= gmSelLocalDebugLevel ) {	 	\
    if (FMT != (char *) NULL)	{			\
      (void) printf(FMT, V1);				\
    }							\
  }

#define DEBUG0(dbgLevel, FMT)				\
  if (dbgLevel <= gmSelLocalDebugLevel ) {	 	\
    if (FMT != (char *) NULL)	{			\
      (void) printf(FMT);				\
    }							\
  }

/*
 ************************************************************************
 *+
 * FUNCTION: gmmps_sel
 *
 * RETURNS: int [success or failure]
 *
 * DESCRIPTION: Main entry point to function.
 *
 * [NOTES:]:
 *-
 ************************************************************************
 */

/* main() in gmmps_sel.cc !! */
   
   /*
   * int main(argc, argv)
   */

int gmmps_sel (int argc, char *argv[])
{
  
  /*
   * DEFINE INTERNAL VARIABLES 
   */
  
  int selection();
  
  int n,i,j;
  int nrows, ncols, sign;
  char zero[2], segno[2];
  char pos_ra[14], pos_dec[14];
  float pos_ra_h=0, pos_ra_m=0, pos_ra_s=0;
  float pos_dec_d=0, pos_dec_m=0, pos_dec_s=0;
  float pos_ra_deg=0, pos_dec_deg=0;
  
  double r1, r2;
  int raCol;		/* Column number of ra.	*/
  //  int decCol;	/* Column number of dec.	*/
  int priority;		/* Index to the priority col.	*/
  
  int numCols;
  int numFound;
  char** colNames;
  char* s;
  WC pos;
  
  char* searchCols[20];
  char* minVals[20];
  char* maxVals[20];
  void* cat = NULL;
  void* result = NULL;
    
  /*
   *  VERIFY THE COMMAND LINE INPUT.
   *  Warning: No-data type checking.
   */
  
  if ( argc < 7 ) {
    printf("USAGE: argv[0] <params>\n\n");
    printf("PAR1: catalog\n");
    printf("PAR2: RA\n");
    printf("PAR3: DEC\n");
    printf("PAR4: something\n");
    printf("PAR5: something\n");
    printf("PAR6: number of rows\n");
    printf("PAR7: number of columns\n");
    return 0;
  }

  /*
   * Open the input catalog.
   */
  
  if ( ( cat = acOpen(argv[1])) == NULL )
    return 0;
  
  /*
   *  Read in ra&dec col#'s, ra&dec VAL's, radius1, radius2, #nrows, #ncols.
   */
  
  strncpy(pos_ra,argv[2], sizeof(pos_ra));
  strncpy(pos_dec,argv[3], sizeof(pos_dec));
  r1    = atof(argv[4]);
  r2    = atof(argv[5]);
  nrows = atoi(argv[6]);
  ncols = atoi(argv[7]);
  
  /*
   *  Read in ncols worth of searchCols, minVals, maxVals.
   *  These are the columns that you want to filter lines with.
   */
  
  if (ncols > 0 ) {
    for(n=0; n<ncols; n++) {
      searchCols[n] = argv[8+n];
      minVals[n]    = argv[8+n+ncols];
      maxVals[n]    = argv[8+n+2*ncols];
    }
  }
  
  /*
   *  from the ra passed in, split off hr, min, and sec and
   *  get the sign from the h.  Then convert to degrees.
   */
  
  sscanf(pos_ra,"%f:%f:%f",&pos_ra_h,&pos_ra_m,&pos_ra_s);
  if (pos_ra_h>=0) sign = 1;
  else sign = -1;

  /* @@cba cast pos_ra_h to int to silence warning */
  pos_ra_deg = sign*(abs((int)pos_ra_h)*15+pos_ra_m/4+pos_ra_s/240);
  
  /*
   *  from the dec passed in, split off d, min, and sec and
   *  get the sign from the dh.  Then convert to degrees.
   */
  
  sscanf(pos_dec,"%f:%f:%f",&pos_dec_d,&pos_dec_m,&pos_dec_s);
  if (pos_dec_d>=0) sign = 1; 
  else sign = -1;

  /* @@cba cast pos_dec_d to int to silence warning */
  pos_dec_deg = sign*(abs((int)pos_dec_d)+pos_dec_m/60+pos_dec_s/3600);
  
  
  /*
   *  Get the Description?,  aoColIndex, and acCircularSearch.
   */
  
  acGetDescription(cat, &numCols, &colNames);
  priority = acColIndex(cat,"priority");
  raCol    = acColIndex(cat,"RA");
  //  decCol   = acColIndex(cat,"DEC");

  acCircularSearch(cat, numCols, colNames, pos_ra_deg, 
		   pos_dec_deg, r1, r2, 0.0, 0.0, nrows, NULL, &numFound, &result);
  
  /*printf("NumFound = %d, Racol=%d, DecCol=%d\n", numFound, raCol, decCol );*/
  
  /*
   *  For all the results returned,  get it in the format desired.
   */
  
  for (i=0; i<numFound; i++) {
    /*
     *  For this line, check that the values in this line are within
     *  the min/max range for the columns passed in.
     */
    
    if (selection(result,i,ncols,searchCols,minVals,maxVals, priority) == 0) {
      /*
       *  This line is within range, 
       *  Put a curly bracket for the beginning of the line.
       *  Then cycle thru each column in the line, treating each items
       *  as a string, unless it is the ra/dec column, then 
       *  treat it differently, because it is printed differently.
       */
      
      printf("{");
      for (j=0; j<numCols; j++) {
	if ( j == raCol ) {
	  /*
	   *  This MAKES A HUGE ASSUMPTION, THAT
	   *  THE RA & DEC COL'S ARE NEXT TO EACH OTHER.
	   */
	  /************** This call assumes that ra & dec are col. 2 & 3 *******/
	  if (acrGetWC(result, i, &pos) == 0) {
	    if (pos.ra.sec<10) strcpy(zero,"0");
	    else strcpy(zero,"");
	    if (pos.ra.val<0) strcpy(segno,"-");
	    else strcpy(segno," ");
	    printf("%s%2.2d:%2.2d:%s%.3f ",
		   segno,pos.ra.hours,pos.ra.min,zero,pos.ra.sec);
	    if (pos.dec.sec<10) strcpy(zero,"0");
	    else strcpy(zero,"");
	    if (pos.dec.val<0) strcpy(segno,"-");
	    else strcpy(segno,"");
	    printf("%s%2.2d:%2.2d:%s%.2f ",
		   segno,pos.dec.hours,pos.dec.min,zero,pos.dec.sec);
	    j++;
	  }
	  else {
	    /*printf("BADd:");*/
	    acrGetString(result, i, j, &s);
	    printf("%s ",s);
	  }
	}
	else {
	  /*
	   *  This is not ra or dec, just print it.
	   */	  
	  acrGetString(result, i, j, &s);
	  printf("%s ",s);
	}
      }
      
      /* For all columns in the line.... */
      
      /*
       *  Put a curly bracket at the end of the line.
       */
      
      printf("} ");
    }/* If line is within range.... */
    
  }/* For each line(i) not found ... */
  
  acClose(cat);
  
  return(0);
}

/*
************************************************************************
*+
* FUNCTION: selection
*
* RETURNS: int , [0=line within range, 1=line not within range, don't print]
*
* DESCRIPTION:  Selection function
*  Determine if the current line has all the values in the search
*  columns within range.  
*
* [NOTES:]:
*-
************************************************************************
*/

int selection
(
 AcResult result,		/* (in)  Result of cat. query, its multiple lines. */
 int	  i,			/* (in)  Current index into result  */
 int	  ncols,		/* (in)	 Number of col's to search  */
 char	  *searchCols[20],	/* (in)	 Array to col's to look in. */
 char	  *minVals[20],		/* (in)  Min val in the col allowed.*/
 char	  *maxVals[20],		/* (in)  Max val in the col allowed.*/
 int	  priority		/* (in)  Index to priority col.	    */
 )
{
  int k;
  double d, d1, d2;
  int j, j1, j2;
  char* s;
  
  /*
   *  If the index for the priority col. is > 0, then try to
   *  get the value of that column, save as a string to s.
   *  If the priority is NOT"3"selected, then go no further just return.
   */
  
  if (priority >= 0) {
    acrGetNString(result, i, "priority", &s);
    if (strcmp(s,"3") != 0) return 0;
  }
  
  /*
   *  Cycle through the searchCol's passed in and check that for this current
   *  line that the value is within the min/max range for this column.
   */
  
  for(k=0;k<ncols;k++) {
    acrGetNString(result, i, searchCols[k], &s);
    
    /*
     *  Try long float, integer and then just string.
     */
    
    if (sscanf(s, "%lf", &d) == 1 &&
	sscanf(minVals[k], "%lf", &d1) == 1 && 
	sscanf(maxVals[k], "%lf", &d2) == 1) {
      /*printf(" sscanf failed to find within range.\n");*/
      if (d < d1 || d > d2) return 1;
    }
    else if (sscanf(s, "%d", &j) == 1 &&
	     sscanf(minVals[k], "%d", &j1) == 1 &&
	     sscanf(maxVals[k], "%d", &j2) == 1) {
      /*printf("2. sscanf failed to find within range.\n");*/
      if (j < j1 || j > j2) return 1;
    }
    else {
      /*printf("3. sscanf failed to find within range.\n");*/
      if (strcmp(s, minVals[k]) < 0 || strcmp(s, maxVals[k]) > 0) return 1;
    }
  }
  return 0;
}
