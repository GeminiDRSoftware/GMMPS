/*
  gmMakeMasks.cc

  AUTHOR: Dustin Fennell - University of Victoria - Feb 2010
  Based partially on gmMakeMasks.cc by B. Ottini, Craig Allen, Jennifer Dunn
  DATE CREATED:
  DATE UPDATED: August 18, 2011, Bryan Miller

  PURPOSE: To fit as many slits as possible onto a GMOS or F2 mask prototype.
  ( and write the data from those slits into an ODF file(s) )

  OVERVIEW:
  gmMakeMasks.cc is part of the larger GMMPS software, and is
  invoked from gmmps_spoc.tcl.

  The program reads data from a temporary data file created by GMMPS, and
  outputs at least one ODF file in a format that is understood by the rest
  of the GMMPS program.

  gmMakeMasks.cc is loosely based on gmMakeMasks.cc, and provides most of
  the functionality of that file. It is lacking GMOS nod-and-shuffle and
  microshuffle support, and as such gmMakeMasks.cc is still maintained and
  invoked within the GMMPS systems.

  ALGORITHM SUMMARY:
  The algorithm chosen for slit selection is reasonably simple, but seems to
  be also fairly effective (especially if compared to the previous algorithm
  used in gmMakeMasks).

  Slits on the mask are first represented as a graph, with each slit as a
  vertex. Edges are then placed where two slits cannot be placed on the
  same graph (ie when their spectra, or the slits themselves, overlap). After
  the slits are represented this way the slit selection process begins.
  For each priority (In order: Acquisition, Priority 1, 2, and 3) the slit
  with the least edges is placed on the graph. Then all slits that were
  adjacent to the placed slit are removed from the graph, and the graph
  is updated (edges to slits no longer on the graph are cleared). This
  process is repeated until all slits in the priority level have been placed
  or excluded from placement, at which point the next priority level is
  processed.

  POSSIBLE FUTURE OPTIMIZATIONS:
  There are several places where this program can be optimized, both in
  run-time efficiency and in terms of the number of slits placed by the
  algorithm.
  As of this moment (08-Mar-2010) the program runs in polynomial time. It
  is able to do its computations for reasonably sized data sets very quickly,
  therefor code optimizations are not in my opinion required at this
  point in time.

  Improving the slit-placement algorithm itself is always welcome, however..
  especially in the situation where we have clock-cycles to spare.
  I had a few ideas as to how this code might be improved, which I will
  outline below:

  1.) Brute-force slit selection for small data sets.
  - If the set of slits to be placed/excluded is below a certain threshold
  then a brute-force algorithm (looking at all possible slit placement
  combinations and picking the one with most slits placed) could improve
  things a bit. I was thinking that a threshold of 10-20 slits would be
  optimal, though once the algorithm is in place perhaps the appropriate
  number could be found by experiment.

  NOTE: I've implemented a version of 'brute force' below... it doesn't
  seem to work that well.

  2.) Same-degree slit selection improvement.
  - Currently (08-Mar-2010) when more than one slit of the same degree is
  found in a graph gmMakeMasks.cc places the first slit of this degree
  encountered (as things stand this will be the slit with the lowest id).
  This algorithm can perhaps be improved... perhaps looking for slits
  within this same-degree set that are themselves connected, and selecting
  the slit with the lowest degree from within those (though this may not be
  of that large a benefit).

  3.) Finding and exploiting sub-graphs.
  - It is very likely (especially in lower priorities) that the generated
  graph will not be a connected graph. As such it will consist of a number
  of sub-graphs.
  If the algorithm were smart enough to separate the slits into their
  respective sub-graphs, it could preform more efficient operations on those
  graphs (for example, if a set of 100 slits is in fact 20 sets of 5 slits,
  then a brute-force approach would be feasible and optimal).

  4.) Cut-vertices. (or similar effects)
  - By the nature of the problem, each time a slit is placed a cut will be
  made in the graph. If we were to select slits such that efficient cuts
  were made to the graph (using, perhaps, a combination of point 2 and 3,
  above) that could lead to efficiency improvements in both time and
  slit selection. We should exercise some caution here, as we wouldn't want
  to concentrate only on making good cuts at the expense of selecting more
  slits, but, if all things were equal we might as well make a better cut,
  than worse (probably).


  There are, I'm sure, many more optimizations that could be made to this code.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cmath>
#include <string>
#include <vector>
#include <algorithm>
#include <map>
#include <utility>
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

// The minimum distance between two spectra (in arcsec, 4 old unbinned GMOS pixels)
float MIN_SPEC_DIST = 0.300;
string instType;
/*
 * ---------------- Helper Class Prototypes ----------------
 */

class Slit {
public:
  int id;
  float slitStart, slitEnd, slitTop, slitBottom, ccdL, ccdW, slitLength,
    slitWidth, specPosL, specPosW, angle, wiggleRoom, maxWiggle, specStart,
    specEnd, redshift, slitFovMin, slitFovMax;
  char priority;
  string line;
  bool wiggleUsed, locked_up, locked_down;

  Slit();
  Slit(int, char);
  Slit(int, char, float, float);
  Slit(int, char, float, float, float, float, float, float, float, float,
       float, float, float, float, string, float, float);
  int changePosition(float, float, float, string);
  bool stringToFloat(const string&, float&);
  vector<string> stringSplit(string, string);
};

class GraphNode {
public:
  int id, degree;
  vector<int> adjList;

  GraphNode();
  GraphNode(int);
  void addAdj(int);
  void removeAdj(int);
  vector<int> getList();
  int getDegree();
};

class Graph {
public:
  map<int, GraphNode> elements;

  void addNode(int);
  void removeNode(int);
  void clear();
  void addEdge(GraphNode*, GraphNode*);
  void removeEdge(GraphNode*, GraphNode*);
  GraphNode * getNode(int nid);
  void clearEdges(GraphNode * node);
  bool empty();
  int size();
  vector<int> getMinDegree();
};

typedef struct {
  // Vectors contain the vertices defining the illuminated field of view
  // and the overall detector dimensions.
  // We assume that the first entry represents the lowest left corner, 
  // and we step through the polygons clockwise
  vector<float> vertx;
  vector<float> verty;
  // Same as above, but in terms of spatial and spectral dimension
  vector<float> vert_spatial;
  vector<float> vert_spectral;
  // The overall extent of the detector array in x and y, disregarding any vignetting
  vector<float> dimx, dimy;
  // The overall extent of the detector array in x and y (same as dimx and dimy),
  // but expressed in terms of spatial and dispersion direction (dimx may become dimy and vice versa) 
  float totalwidth_spectral; 
  // the center of the illuminated area
  float illumarea_spatial_center, illumarea_spectral_center;
  // The minima and maxima of the illuminated area
  float illumarea_spectral_min, illumarea_spectral_max;
  float illumarea_spatial_min, illumarea_spatial_max;
} _fov_;

// A global (yes, I know...) containing the fov
_fov_ fov;


// A struct that holds the Nod & Shuffle parameters
typedef struct {
  string shuffleMode;
  float binning;
  float bandSize;
  float msSlitLen;
  float shufflePix;   // pixels, but as float because we have to calculate with it.
  float shuffleAmt;   // same for all the others ...
  bool  microShuffle;
  bool  bandShuffle;
  int   numBands;
  vector<float> shuffleBands;
  // yoffset is not needed, as the shuffleBands vector includes it already.
  // Nonetheless, we want to propagate the yoffset into the output catalog
  // where we don't explicitly list all the bands.
  int   yoffset; 
  float shuffleUnbPx;
  float shuffleMagnitude;
} _banddef_;

_banddef_ banddef;

/**
 * ------------------- Slit Selection Function Prototypes -----------------------
 **/

void initOutputFile(char*, ofstream&, string, float, char*, char*, char*, char*);
float loadSlits(map<int, Slit>*, char*, string, float, string, float, bool);
map<int, Slit> getSlits(map<int, Slit>, char);
void mapConflicts(Graph*, map<int, Slit>, float, string, float);
void placeSlits(map<int, Slit>*, map<int, Slit>*, map<int, Slit>*,
		map<int, Slit>*, Graph*, float, string, float);
void removeConflicts(map<int, Slit>*, map<int, Slit>*, map<int, Slit>*, Graph);
void loadFov(char*, float, float, float, string);
bool bandShuffleCheck(float, float, float);
void removeSlit(int, map<int, Slit>*, map<int, Slit>*);
void writeSlits(map<int, Slit>&, ofstream&);
void maxSlitMode(map<int, Slit>&, float, string);
void maxOptProcessLine(map<int, Slit>&, int, string, float);
void expandSlitToFOV(Slit&);
bool conflicts(Slit, Slit, float, string, float);
int findMaxSpectrumSid(vector<int>*, map<int, Slit>*, float);
bool wiggleNear(int, map<int, Slit>*, map<int, Slit>*, float, string);
int wiggleUnplaced(map<int, Slit>*, map<int, Slit>*, map<int, Slit>*, float, string, float);
bool checkConflicts(Slit, Slit, map<int, Slit>, float, string, float);
void printIntro(char);
void printIntroError(int);
vector<string> stringSplit(string, string);
bool stringToInt(const string&, int&);
bool stringToFloat(const string&, float&);
void stringclean(string&);
float get_keyvalue(string);
vector<float> calc_intercept(float);
float min(vector<float> const &);
float max(vector<float> const &);
void printSlit(map<int, Slit>, int, int, float);
string RemoveChars(string, string);
vector<string> getword(string, char);
void trim(string &, const string&);
bool checkTilt(map<int, Slit> &);

/**
 * ------------------- Slit Selection Code -----------------------
 **/

/*
************************************************************************
*+
* FUNCTION: main
*
* RETURNS: int [success or failure]
*
* DESCRIPTION: Main entry point to function.
*
* [NOTES:]:
*-
************************************************************************
*/
int main(int argc, char *argv[]) {
  // Input variables (set from argv).
  char inFile[256];      // Input file
  char outFile[256];     // Output file
  char outFileRoot[256]; // Output root path
  char fovFile[256];     // Field-of-View file
  string dispDirection;  // Dispersion direction of the spectra
  char slitMode;         // Determines whether to expand slits into empty space or not.
  float pixelScale;      // pixel scale    (arcseconds/pixel)
  float crpix1, crpix2;  // The fiducial center point
  float minpixsep = 4.0; // the minimum separation of spectra in pixels for auto expansion
  int numMasks;          // number of masks to be made
  bool pack_spectra = true;  // Whether packing of short spectra is allowed 
  char det_img[256];
  char det_spec[256];
  char ra_imag[256];
  char dec_imag[256];
  float wiggleVal;
  string bandConfig = "";

  // Slit containers.
  map<int, Slit> slits;    // holds all slits
  map<int, Slit> acqSlits; // holds acquisition objects
  map<int, Slit> p1Slits;  // holds p1 objects
  map<int, Slit> p2Slits;  // holds p2 objects
  map<int, Slit> p3Slits;  // holds p3 objects
  map<int, Slit> placed;   // holds objects which to be placed in the ODF
  map<int, Slit> removed;  // holds objects not in ODF
  
  // Holds band boundaries in nod and shuffle mode (band shuffle).
  banddef.shuffleMagnitude = 0;
  banddef.shuffleUnbPx = 0;
  banddef.shuffleMode = "None";

  // Conflict graphs.
  // Nodes represent slits, and edge between two nodes indicates 
  // conflicting spectra between the two represented slits. 
  Graph allSlitsG;
  Graph acqSlitsG;
  Graph p1SlitsG;
  Graph p2SlitsG;
  Graph p3SlitsG;

  // Number of slits placed for each priority.
  int numberPlacedAcq;
  int numberPlacedPrio1;
  int numberPlacedPrio2;
  int numberPlacedPrio3;

  ofstream outStream;

  // Holds the microShuffle distance in pixels if in microshuffle mode.
  float microshufflePix = 0;

  // Load values from argv.
  if (argc >= 18) {
    strcpy(inFile, argv[1]);
    strcpy(outFileRoot, argv[2]);
    instType = argv[3];
    strcpy(fovFile, argv[4]);
    
    // pixel scale (arcseconds / pixel)
    pixelScale = atof(argv[5]);

    // number of ODF masks to construct
    numMasks = atoi(argv[6]);

    // Max or Normal mode ('M' or 'N')
    slitMode = argv[7][0];

    // dispersion direction ('horizontal' or 'vertical')
    dispDirection = argv[8];

    strcpy(det_img, argv[9]);
    strcpy(det_spec, argv[10]);

    // Coordinates of the preimage used for mask making
    strcpy(ra_imag, argv[11]);
    strcpy(dec_imag, argv[12]);

    crpix1 = atof(argv[13]);
    crpix2 = atof(argv[14]);

    minpixsep = atof(argv[15]);

    // This value determines how much a slit can be moved along its
    // length-wise axis when attempting to 'wiggle' more slits onto the mask
    wiggleVal = atof(argv[16]);

    pack_spectra = atoi(argv[17]);
    // Print some introductory information. 
    // In normal GMMPS operation this will be displayed in the "Design Mask"
    // window defined in gmmps_spoc.tcl.
    // printIntro(slitMode);
  } 
  else {
    // Too few input parameters.
    printIntroError(argc);
    return (-1);
  }

  if (argc >= 19 && argv[18][0] != 0) {
    bandConfig = argv[18];
    // Clean bandConfig from unwanted characters that I could not remove in TclTk
    bandConfig = RemoveChars(bandConfig,"{} ");
    replace( bandConfig.begin(), bandConfig.end(), '_', ' ');
    trim(bandConfig," ");
  }

  // determine the minimum split separation based on the instrument type:
  // 4 pixels minimum
  MIN_SPEC_DIST = minpixsep * pixelScale;

  // Load field of view information, put it into the global 'fov' variable
  loadFov(fovFile, pixelScale, crpix1, crpix2, dispDirection);

  // Load in slit data from temporary data file generated in gmmps_spoc.tcl
  microshufflePix = loadSlits(&slits, inFile, bandConfig, pixelScale, 
			      dispDirection, wiggleVal, pack_spectra);

  // Search slit container for acquisition slits.
  acqSlits = getSlits(slits, '0');

  // Select slits for each mask up to numMasks.
  for (int i=0; i<numMasks; i++) {

    // Leave if no objects left! Otherwise the program will hang
    if (int(slits.size()) <= 0) break;

    numberPlacedAcq   = 0;
    numberPlacedPrio1 = 0;
    numberPlacedPrio2 = 0;
    numberPlacedPrio3 = 0;

    // Init output stream.
    sprintf(outFile, "%s%d.cat", outFileRoot, i + 1);
    outStream.open(outFile);

    char outShortFile[128];
    if (strrchr(outFile, '/') != 0)
      sprintf(outShortFile, "%s", strrchr(outFile, '/') + 1);
    else
      sprintf(outShortFile, "%s", outFile);

    printf("\nMASK %d (of %d): %s\n", i + 1, numMasks, outShortFile);
    int nobj_tot = int(slits.size());

    // Write ODF header.
    initOutputFile(outFile, outStream, dispDirection, pixelScale, det_img,
		   det_spec, ra_imag, dec_imag);

    // Acquisition slit processing.
    // Generate conflict map using only acquisition slits.
    mapConflicts(&acqSlitsG, acqSlits, microshufflePix, dispDirection, pixelScale);

    // Place as many acquisition slits as we can.
    placeSlits(&acqSlits, &placed, &removed, &acqSlits, &acqSlitsG,
	       microshufflePix, dispDirection, pixelScale);
    numberPlacedAcq = placed.size();

    // Generate conflict map using all slits.
    mapConflicts(&allSlitsG, slits, microshufflePix, dispDirection, pixelScale);

    // Remove any slits from "slits" which have been placed and add them to "removed".
    removeConflicts(&slits, &placed, &removed, allSlitsG);

    // Priority 1 slit processing.

    // Fetch all priority 1 slits.
    p1Slits = getSlits(slits, '1');
    // Generate conflict graph using priority 1 slits only.
    mapConflicts(&p1SlitsG, p1Slits, microshufflePix, dispDirection, pixelScale);
    // Place as many priority 1 slits as we can.
    placeSlits(&slits, &placed, &removed, &p1Slits, &p1SlitsG, 
	       microshufflePix, dispDirection, pixelScale);
    numberPlacedPrio1 = placed.size() - numberPlacedAcq;
    // Remove slits which now cannot be placed from consideration.
    removeConflicts(&slits, &placed, &removed, allSlitsG);

    // Priority 2 slit processing.
    p2Slits = getSlits(slits, '2');
    mapConflicts(&p2SlitsG, p2Slits, microshufflePix, dispDirection, pixelScale);
    placeSlits(&slits, &placed, &removed, &p2Slits, &p2SlitsG, 
	       microshufflePix, dispDirection, pixelScale);
    numberPlacedPrio2 = placed.size() - numberPlacedAcq - numberPlacedPrio1;
    removeConflicts(&slits, &placed, &removed, allSlitsG);

    // Priority 3 slit processing.
    p3Slits = getSlits(slits, '3');
    mapConflicts(&p3SlitsG, p3Slits, microshufflePix, dispDirection, pixelScale);
    placeSlits(&slits, &placed, &removed, &p3Slits, &p3SlitsG, 
	       microshufflePix, dispDirection, pixelScale);
    numberPlacedPrio3 = placed.size() - numberPlacedAcq - numberPlacedPrio1 - numberPlacedPrio2;
    removeConflicts(&slits, &placed, &removed, allSlitsG);

    // Adjust slit positions slightly to try to place more slits on the mask
    // BUGGY IF MORE THAN ONE MASK PRODUCED! FIRST MASK IS FINE, SUBSEQUENT MASKS MAY HAVE SPECTRA
    // OVERLAP WITH (OVERLAPPING?) ACQ SOURCES. Hence only for i=0.
    // We may wiggle slits that have been placed already, though (see other wiggle scripts)
    if (wiggleVal > 0. && i==0) {
      wiggleUnplaced(&slits, &placed, &removed, microshufflePix, dispDirection, pixelScale);
    }

    // Expand slits length-wise into each other, to maximize sky.
    // Expansion will be asymmetric, i.e. the object will in general 
    // not be centered along the slitlet hereafter
    if (slitMode == 'M' && microshufflePix == 0) {
      maxSlitMode(placed, pixelScale, dispDirection);
    }

    // Write slits to ODF file.
    writeSlits(placed, outStream);

    // Print placement summary to the 'Design Masks' window.
    printf("  %d of %d available objects included.\n", int(placed.size()), nobj_tot);
    printf("  Thereof priority 0/1/2/3: %d / %d / %d / %d\n", numberPlacedAcq,
	   numberPlacedPrio1, numberPlacedPrio2, numberPlacedPrio3);
    if (numberPlacedAcq < 2) {
      printf("  WARNING: Less than 2 acquisition objects!\n");
    }

    // If we're constructing another ODF file, rearrange data to do so.
    if (i + 1 != numMasks) {
      // Removed is a list of all unplaced slits. This becomes our new input data. 
      // NOTE : 'slits' container should be empty at this point. 
      slits.swap(removed);

      // Clear all other containers. 
      // NOTE: Except 'acqSlits', those slits are re-used for each mask.
      removed.clear();
      placed.clear();
      p1Slits.clear();
      p2Slits.clear();
      p3Slits.clear();
    }

    outStream.close();
  }

  return 0;
}


/*
************************************************************************
*+
* FUNCTION: initOutputFile
*
* RETURNS: n/a
*
* DESCRIPTION: Writes some preliminary data to the output file.  
*
* [NOTES:]: 
*
*-
************************************************************************
*/
void initOutputFile(char * outFile, ofstream & outStream, string dispDirection, 
		    float pixelScale, char * det_img,
		    char * det_spec, char * ra_imag, char * dec_imag) {
  char outShortFile[128];
  char temp[1024];

  if (strrchr(outFile, '/') != 0) sprintf(outShortFile, "%s", strrchr(outFile, '/') + 1);
  else sprintf(outShortFile, "%s", outFile);

  // This writes to the .cat file.
  outStream.write("QueryResult\n\n", strlen("QueryResult\n\n"));
  outStream.write("# Config entry for original catalog server:\n",
		  strlen("# Config entry for original catalog server:\n"));
  outStream.write("serv_type: local\n", strlen("serv_type: local\n"));
  sprintf(temp, "long_name: %s\n", outFile);
  outStream.write(temp, strlen(temp));
  sprintf(temp, "short_name: %s\n", outShortFile);
  outStream.write(temp, strlen(temp));
  sprintf(temp, "url: %s\n", outFile);
  outStream.write(temp, strlen(temp));
  sprintf(temp,
	  "symbol: {x_ccd y_ccd priority} {diamond magenta {} {} {} {$priority == \"0\"}} {20 {}}:{x_ccd y_ccd priority} {circle red {} {} {} {$priority == \"1\"}} {15 {}}:{x_ccd y_ccd priority} {square green {} {} {} {$priority == \"2\"}} {15 {}}:{x_ccd y_ccd priority} {triangle turquoise {} {} {} {$priority == \"3\"}} {15 {}}:{x_ccd y_ccd priority} {cross yellow {} {} {} {$priority == \"X\"}} {15 {}}\n");
  outStream.write(temp, strlen(temp));
  //  sprintf(temp, "#SpectrumLength: %d\n", (int) specLen);
  //  outStream.write(temp, strlen(temp));
  outStream.write("# Fits keywords\n", strlen("# Fits keywords\n"));
  sprintf(temp, "#fits INSTRUME= %s / Mask defined for this instrument\n", instType.c_str());
  outStream.write(temp, strlen(temp));
  sprintf(temp, "#fits DISPDIR = %s / Dispersion direction\n", dispDirection.c_str());
  outStream.write(temp, strlen(temp));

  // The pixel scale isn't relevant for GMMPS itself. It is alsno not constant across the image.
  // However, odf2mdf needs the nominal values, and we lock them in here so that IRAF doesn't do nonsense:
  float pixelScaleOut = 0.0;
  if (instType == "F2") pixelScaleOut = 0.1792;
  if (instType == "GMOS-N") {
    if      (pixelScale >  0.071 && pixelScale < 0.075) pixelScaleOut = 0.0727; // EEV 1x1, old pseudo-image
    else if (pixelScale >= 0.075 && pixelScale < 0.085) pixelScaleOut = 0.0807; // Hamamatsu 1x1
    else if (pixelScale >  0.142 && pixelScale < 0.150) pixelScaleOut = 0.1454; // EEV 2x2, old pseudo-image
    else if (pixelScale >= 0.150 && pixelScale < 0.170) pixelScaleOut = 0.1614; // Hamamatsu 2x2
    else {
      cout << "ERROR: Pixel scale " << pixelScale << " could not be matched with valid GMOS-N configurations!";
      exit (1);
    }
  }
  if (instType == "GMOS-S") {
    if      (pixelScale >  0.071 && pixelScale < 0.075) pixelScaleOut = 0.0730; // EEV 1x1, old pseudo-image
    else if (pixelScale >= 0.075 && pixelScale < 0.085) pixelScaleOut = 0.0800; // Hamamatsu 1x1
    else if (pixelScale >  0.142 && pixelScale < 0.150) pixelScaleOut = 0.1460; // EEV 2x2, old pseudo-image
    else if (pixelScale >= 0.150 && pixelScale < 0.170) pixelScaleOut = 0.1600; // Hamamatsu 2x2
    else {
      cout << "ERROR: Pixel scale " << pixelScale << " could not be matched with valid GMOS-N configurations!";
      exit (1);
    }
  }
  sprintf(temp, "#fits PIXSCALE= %f / Nominal pixel scale for IRAF (odf2mdf)\n", pixelScaleOut);
  outStream.write(temp, strlen(temp));
  sprintf(temp, "#fits DET_IMG = %s / Detector ID for pre-image \n", det_img);
  outStream.write(temp, strlen(temp));
  sprintf(temp, "#fits DET_SPEC= %s / Detector ID for the spectrograph\n", det_spec);
  outStream.write(temp, strlen(temp));
  sprintf(temp, "#fits RA_IMAG = %s / Right ascension of pointing center\n", ra_imag);
  outStream.write(temp, strlen(temp));
  sprintf(temp, "#fits DEC_IMAG= %s / Declination of pointing center\n", dec_imag);
  outStream.write(temp, strlen(temp));

  // Add Nod&Shuffle parameters
  if (banddef.microShuffle || banddef.bandShuffle) {
    sprintf(temp, "#fits SHUFMODE= %s / Microshuffling or bandshuffling\n", banddef.shuffleMode.c_str());
    outStream.write(temp, strlen(temp));
    sprintf(temp, "#fits SHUFSIZE= %d / Shuffle distance [unbinned pixel]\n", int(banddef.shuffleUnbPx));
    outStream.write(temp, strlen(temp));
    sprintf(temp, "#fits BINNING = %d / Binning\n", int(banddef.binning));
    outStream.write(temp, strlen(temp));

    // Microshuffling
    if (banddef.microShuffle) {
      sprintf(temp, "#fits SLITLEN = %.2f / Slit length for microshuffling [arcsec]\n", banddef.msSlitLen);
      outStream.write(temp, strlen(temp));
      sprintf(temp, "#fits YOFFSET = %d / Band offset [unbinned pixel]\n", banddef.yoffset);
      outStream.write(temp, strlen(temp));
    }

    // Bandshuffling
    if (banddef.bandShuffle) {
      sprintf(temp, "#fits BANDSIZE= %d / Height of the science band [unbinned pixel]\n", 
	      int(banddef.bandSize * banddef.binning));
      outStream.write(temp, strlen(temp));
      sprintf(temp, "#fits YOFFSET = %d / Band offset [unbinned pixel]\n", banddef.yoffset);
      outStream.write(temp, strlen(temp));
    }
  }
}

/*
************************************************************************
*+
* FUNCTION: loadSlits
*
* RETURNS: Zero if not in microShuffle mode, the microShuffle distance
*          (in arcseconds) otherwise.
*
* DESCRIPTION: Loads all slit data from the input file.
*
* [NOTES:]:
*-
************************************************************************
*/
float loadSlits(map<int, Slit> *slits, char *inFileName, 
		string bandConfig, float pixelScale, string dispDirection,
		float wiggleFactor, bool pack_spectra) {

  ifstream inFile;

  // Nod and Shuffle variables.
  banddef.binning = 0;      // Image binning value. 
  banddef.bandSize = 0.0; // The size of each band in pixels.
  banddef.shuffleAmt = 0.0;
  banddef.shufflePix = 0.0; // The magnitude of the shuffling, in pixels. 
  banddef.msSlitLen = 0.0;
  banddef.yoffset = 0;
  banddef.bandShuffle = false;  // bandShuffle mode flag.
  banddef.microShuffle = false; // microShuffle mode flag. 
  banddef.numBands = 1;

  // Slit data variables.

  // Useful vars for calculations:
  int id, j;
  float ccdW, ccdL;            // width-wise and length-wise ccd slit position
  float slitOffsetW, slitOffsetL;
  float slitLength, slitWidth;
  float ccdW_orig, ccdL_orig;            // backups
  float slitOffsetW_orig, slitOffsetL_orig;
  float slitLength_orig, slitWidth_orig;
  char priority;
  float slitStart; // The length-wise pixel coordinate of the start of the slit
  float slitEnd;   // The length-wise pixel coordinate of the end of the slit
  float slitTop, slitBottom;
  float bandPos;
  string line;
  char lineChar[512];

  // These we only need because we need to output them later:
  float ra, dec, angle, mag, redshift;
  char type;
  float specPosW, specPosL; // need to be calculated 
  //  float wlambdac, lambda1, lambda2;
  float spec_begin; // starting position of spectrum (lower value, pixels)
  float spec_end; // end position of spectrum (higher value, pixels)
  
  vector<string>bandArgs;

  // Disentangle the Nod & Shuffle parameters
  if (bandConfig.compare("") != 0) {
    // Split the string into words
    bandArgs = getword(bandConfig,' ');
    
    banddef.binning    = atof(bandArgs[0].c_str());
    banddef.bandSize   = atof(bandArgs[2].c_str());   // if in bandshuffle mode
    banddef.msSlitLen  = atof(bandArgs[2].c_str());   // if in microshuffle mode
    banddef.shufflePix = atof(bandArgs[3].c_str());
    banddef.shuffleAmt = atof(bandArgs[4].c_str());
    banddef.shuffleMode = bandArgs[1];

    if (bandArgs[1].compare("microShuffle") == 0) 
      banddef.microShuffle = true;
    else
      banddef.bandShuffle = true;

    if (banddef.bandShuffle) {
      banddef.numBands = atoi(bandArgs.back().c_str());
      j = 0;
      while (j<banddef.numBands) {
	bandPos = atof(bandArgs[j+5].c_str()) / banddef.binning;
	banddef.shuffleBands.push_back(bandPos);
	j++;
      }
      banddef.yoffset = atoi(bandArgs[bandArgs.size()-2].c_str());
    }

    banddef.shuffleUnbPx = banddef.shufflePix;
      
    // Convert to _binned_ pixels
    banddef.shufflePix = banddef.shuffleAmt / pixelScale;
    // Set shuffle magnitude for access in 'main' function;
    banddef.shuffleMagnitude = banddef.shufflePix;
    // shufflePix = shufflePix / binning;
    banddef.bandSize /= banddef.binning;
  }


  inFile.open(inFileName, ios::in);
  if (inFile.is_open()) {
    // File has been opened correctly, begin data processing.

    vector <string> lineData;

    // Read slits from input file.
    while (getline(inFile, line)) {
      // Remove leading and trailing white space, tabs, and multiple blanks:
      stringclean(line);
      // Parse line data.
      lineData = stringSplit(line, " ");
      // For some reason it seems to read beyond the end of the file producing
      // a line with zero length, that's why there is this if condition:
      if (lineData.size() == 16) {
	stringToInt(lineData[0], id);
	stringToFloat(lineData[1], ra);
	stringToFloat(lineData[2], dec);
	stringToFloat(lineData[9], angle);
	stringToFloat(lineData[10], mag);
	priority = lineData[11][0];
	type = lineData[12][0];
	stringToFloat(lineData[13], redshift);
	stringToFloat(lineData[14], spec_begin);
	stringToFloat(lineData[15], spec_end);

	// Dependency on dispersion direction
	if (dispDirection == "horizontal") {
	  stringToFloat(lineData[3], ccdW);
	  stringToFloat(lineData[4], ccdL);
	  stringToFloat(lineData[5], slitOffsetW);
	  stringToFloat(lineData[6], slitOffsetL);
	  stringToFloat(lineData[7], slitWidth);
	  stringToFloat(lineData[8], slitLength);
	} else {
	  stringToFloat(lineData[3], ccdL);
	  stringToFloat(lineData[4], ccdW);
	  stringToFloat(lineData[5], slitOffsetL);
	  stringToFloat(lineData[6], slitOffsetW);
	  stringToFloat(lineData[7], slitLength);
	  stringToFloat(lineData[8], slitWidth);
	}

	// Slits have a constant length if we are in microshuffle mode.
	if (banddef.microShuffle && priority != '0') {
	  slitLength = banddef.msSlitLen;
	}

	// Acq Objects have to be 2.0 x 2.0 arcseconds.
	if (priority == '0') {
	  slitLength = 2.0;
	  slitWidth = 2.0;
	}

	// Make the spectra as long as the detector array to prevent packing
	if (!pack_spectra) {
	  spec_begin = 1.;
	  spec_end = fov.totalwidth_spectral;
	}

	// Center of spectrum footprint (only used in the print function for debugging purposes)
	specPosW = (spec_begin + spec_end) / 2.;

	// Only used to find the slit that is most central to the mask
	specPosL = slitOffsetL / pixelScale;

	// make a backup copy (for the ODF output)
	slitOffsetL_orig = slitOffsetL;
	slitOffsetW_orig = slitOffsetW;
	slitLength_orig  = slitLength;
	slitWidth_orig   = slitWidth;
	ccdL_orig        = ccdL;
	ccdW_orig        = ccdW;

	// Convert slit dimensions into pixels.
	slitOffsetL /= pixelScale;
	slitOffsetW /= pixelScale;
	slitLength  /= pixelScale;
	slitWidth   /= pixelScale;

	// Calculate slit centers and dimensions (in pixels)
	ccdL += slitOffsetL;
	ccdW += slitOffsetW;
	slitStart  = ccdL - (slitLength / 2.0);
	slitEnd    = ccdL + (slitLength / 2.0);
	slitTop    = ccdW + (slitWidth / 2.0);
	slitBottom = ccdW - (slitWidth / 2.0);

	if (dispDirection == "horizontal") {
	  sprintf(lineChar,
		  "%6d\t%10.5f\t%10.5f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%c\t%c\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\n",
		  id, ra, dec, ccdW_orig, ccdL_orig, slitOffsetW_orig, slitOffsetL_orig, slitWidth_orig, slitLength_orig,
		  angle, mag, priority, type, redshift, spec_begin, spec_end, slitStart, slitEnd);
	} else {
	  sprintf(lineChar,
		  "%6d\t%10.5f\t%10.5f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%c\t%c\t%8.6f\t%8.6f\t%8.6f\t%8.6f\t%8.6f\n",
		  id, ra, dec, ccdL_orig, ccdW_orig, slitOffsetL_orig, slitOffsetW_orig, slitLength_orig, slitWidth_orig,
		  angle, mag, priority, type, redshift, slitStart, slitEnd, spec_begin, spec_end);
	}

	// convert char* to string for storage.
	// 'line' is what will be written to the ODF if this slit is chosen
	line = lineChar;

	// Add the slit to the slit list.
	// If in band shuffling mode make sure the slit is in a band.
	if (!banddef.bandShuffle || bandShuffleCheck(banddef.bandSize, slitLength, ccdL)) {
	  slits->insert(pair<int, Slit>(id, 
					Slit(id, priority, slitStart, slitEnd, slitLength, ccdL, 
					     ccdW, slitWidth, slitTop, slitBottom, specPosL, 
					     specPosW, angle, wiggleFactor, line, spec_begin, spec_end)));
	}
      }
    }

    inFile.close();
    
    //    printf("Total number of objects available: %d\n", int(slits->size()));
  } 
  else {
    printf("Unable to open input file. Exiting.\n");
    exit(1);
  }

  // Return microshuffle distance value if in microshuffle mode.
  if (banddef.microShuffle) {
    return banddef.shufflePix;
  } 
  else {
    return 0;
  }
}

/*
************************************************************************
*+
* FUNCTION: getSlits
*
* RETURNS: A vector<Slit> of Slit objects
*
* DESCRIPTION: Scans vector<Slit> 'slitData' for slits of 'priority',
*               and returns a vector<Slit> of those found objects.
*
* [NOTES:]: O(n)
*-
************************************************************************
*/
map<int, Slit> getSlits(map<int, Slit> slitData, char priority) {
  char prioCur;
  map<int, Slit> foundSlits;
  map<int, Slit>::iterator it; // Iterator object.

  // Loop through 'slit' container to find slits of the given prio.
  for (it = slitData.begin(); it != slitData.end(); it++) {
    prioCur = (*it).second.priority;

    if (prioCur == priority) {
      // Found a slit, insert into 'foundSlits' container. 
      foundSlits.insert(pair<int, Slit>((*it).first, Slit((*it).second)));
    }
  }

  return foundSlits;
}

/*
************************************************************************
*+
* FUNCTION: mapConflicts
*
* RETURNS: A Graph object conflict map.
*
* DESCRIPTION: Maps all conflicts in 'slitData' into 'conflicts' Graph.
*
* [NOTES:]: Two slits conflict when the spectra of these two slits 
*            overlap. Conflicts between slits are represented in the 
*            graph edges between the conflicting slits.
*            O(n^2) <
*-
************************************************************************
*/
void mapConflicts(Graph * slitConflicts, map<int, Slit> slitData,
		  float microshufflePix, string dispDirection, float pixelScale) {

  map<int, Slit>::iterator slitOne; // Iterator object.
  map<int, Slit>::iterator slitTwo;

  // Add nodes to conflict graph.
  for (slitOne = slitData.begin(); slitOne != slitData.end(); slitOne++) {
    slitConflicts->addNode((*slitOne).second.id);
  }

  // Search for conflicts between slits.
  for (slitOne = slitData.begin(); 1; slitOne++) {

    // Point slitTwo iterator at the position after slitOne.
    slitTwo = slitData.begin();
    while ((*slitTwo).first <= (*slitOne).first && slitTwo != slitData.end()) {
      slitTwo++;
    }

    // This means we're at the end of the data, exit loop.
    if (slitTwo == slitData.end())
      break;

    // See if data at slitOne conflicts with the remaining slits.
    for (; slitTwo != slitData.end(); slitTwo++) {
      if (conflicts((*slitOne).second, (*slitTwo).second, 
		    microshufflePix, dispDirection, pixelScale)) {
	slitConflicts->addEdge(slitConflicts->getNode((*slitOne).first), 
			       slitConflicts->getNode((*slitTwo).first));
      }
    }
  }
}

/*
************************************************************************
*+
* FUNCTION: placeSlits
*
* RETURNS: none.
*
* DESCRIPTION: Select slits to place on the ODF. 
*
* [NOTES:]:
*-
************************************************************************
*/

void placeSlits(map<int, Slit> *slits, map<int, Slit> *placed,
		map<int, Slit> *removed, map<int, Slit> *current,
		Graph *conflictGraph, float microshufflePix,
		string dispDirection, float pixelScale) {

  GraphNode *slitNode;

  vector<int> conflictList;
  vector<int> minDegSlits;
  vector<int>::iterator it;
  map<int, Slit>::iterator slitIterator;
  Slit slit;
  int sid;

  // Place slits until conflict graph is empty.
  // NOTE: this could be more efficient. 
  while (!conflictGraph->empty()) {
    // Gather cardinality list.
    minDegSlits = conflictGraph->getMinDegree();

    // Find slit with max spectrum.
    sid = findMaxSpectrumSid(&minDegSlits, slits, fov.illumarea_spatial_center);

    (*placed)[sid] = (*slits)[sid];

    // Remove conflicting slits.
    slitNode = conflictGraph->getNode(sid);
    conflictList = (*slitNode).getList();

    // Only remove slits if not acquisition stars
    for (it = conflictList.begin(); it != conflictList.end(); it++) {
      conflictGraph->removeNode((*it));
      removeSlit((*it), slits, removed);
    }

    // Remove references to the placed node within the conflictGraph.
    conflictGraph->removeNode(sid);

    // Try to cozy the placed slit into its neighbors, if allowed.    
    if (wiggleNear(sid, slits, placed, pixelScale, dispDirection)) {
      // If we've wiggled then update the conflict graph.
      mapConflicts(conflictGraph, (*current), microshufflePix, dispDirection, pixelScale);
    }
  }

  // After slits have been placed wiggle them a bit more.  
  for (slitIterator = (*placed).begin(); slitIterator != (*placed).end();
       slitIterator++) {
    slit = (*slitIterator).second;
    wiggleNear(slit.id, slits, placed, pixelScale, dispDirection);
  }
  
}

/*
************************************************************************
*+
* FUNCTION: checkConflicts
*
* RETURNS: True if there is a conflict, false otherwise.
*
* DESCRIPTION: Checks if a given slit conflicts with a given set of slits.
*
* [NOTES:]: 
*-
************************************************************************
*/
bool checkConflicts(Slit test, Slit except, map<int, Slit> slits,
		    float msPix, string dispDirection, float pixelScale) {
  map<int, Slit>::iterator slitIterator;
  Slit test2;

  for (slitIterator = slits.begin(); slitIterator != slits.end();
       slitIterator++) {
    test2 = (*slitIterator).second;
    if (test2.id != except.id &&
	conflicts(test, test2, msPix, dispDirection, pixelScale)) {
      return true;
    }
  }

  return false;
}


/*
************************************************************************
*+
* FUNCTION: maxSlitMode
*
* RETURNS: n/a
*
* DESCRIPTION: If in 'Max_Opt' mode, we expand slits to fill empty 
*              space, this is what this function does. 
*
* [NOTES:]:
*-
************************************************************************
*/
void maxSlitMode(map<int, Slit> &placed, float pixelScale, string dispDirection) {

  map<int, Slit>::iterator slit1;
  map<int, Slit>::iterator slit2;

  // Initiate the lock flags
  for (slit1 = placed.begin(); slit1 != placed.end(); slit1++) {
    if ((*slit1).second.priority == '0' || (*slit1).second.angle != 0.0) {
      // Tilted slits and acq stars cannot be expanded:
      (*slit1).second.locked_up   = true; // Cannot expand slit in increasing spatial dim
      (*slit1).second.locked_down = true; // Cannot expand slit in decreasing spatial dim
    } else {
      (*slit1).second.locked_up   = false;
      (*slit1).second.locked_down = false;
    }
  }

  // Calculate the min/max values for each slit, set by the slit placement area boundary
  for (slit1 = placed.begin(); slit1 != placed.end(); slit1++) {
    expandSlitToFOV((*slit1).second);
  }

  // Slits must be contained within science bands
  // Calculate more restrictive boundaries than the slit placement area
  if (banddef.shuffleBands.size() != 0) {
    // loop over slits
    for (slit1 = placed.begin(); slit1 != placed.end(); slit1++) {
      // loop over bands
      for (unsigned int bandIndex = 0; bandIndex < banddef.shuffleBands.size(); bandIndex++) {
	float bandStart = banddef.shuffleBands[bandIndex];
	float bandEnd = bandStart + banddef.shuffleMagnitude;
	// slitStart and slitEnd must obey the band
	// At this point, slits are definitely within a science band,
	// so case distinctions are easy:
	if ((*slit1).second.slitStart >= bandStart && (*slit1).second.slitEnd <= bandEnd) {
	  // slit within band.
	  // Pick whatever is more conservative (slit placement area border or band, diagonal GMOS cutoffs, barcode)
	  (*slit1).second.slitFovMin = ((*slit1).second.slitFovMin > bandStart) ? (*slit1).second.slitFovMin : bandStart;
	  (*slit1).second.slitFovMax = ((*slit1).second.slitFovMax < bandEnd) ? (*slit1).second.slitFovMax : bandEnd;
	}
      }
    }
  }
  
  // Compare each slit with all other slits, to see if it can be expanded.
  // If yes, expand.
  float d1, d2;
  bool expanded1 = true, expanded2 = true;
  int counter = 1;
  while (expanded1 || expanded2) {
    expanded1 = false;
    expanded2 = false;

    for (slit1 = placed.begin(); slit1 != placed.end(); slit1++) {
      // skip this slit if already fully locked
      if ((*slit1).second.locked_up && (*slit1).second.locked_down) continue;

      for (slit2 = placed.begin(); slit2 != placed.end(); slit2++) {

	// Do not compare slit with itself
	if (slit1 == slit2) continue;

	// Does the spectrum of slit2 overlap in the spatial direction with the
	// spectrum of slit1, i.e. does it constrain the expansion of slit1?
	// If not, skip slit2
	if ((*slit1).second.specEnd < (*slit2).second.specStart || 
	    (*slit2).second.specEnd < (*slit1).second.specStart) continue;
	
	// Check if space between slit1 and slit2 is sufficient to expand slit 1
	d1 = (*slit2).second.slitStart - (*slit1).second.slitEnd; // > 0: slit2 above slit1
	d2 = (*slit1).second.slitStart - (*slit2).second.slitEnd; // > 0: slit1 above slit2
	//	if ((*slit1).first == 34 && (*slit2).first == 35) 
	//  cout << d1 << " " << d2 << endl;

	// Lock slit1 upwards/downwards if within 1 pixel of the min separation
	// or the slit placement area boundary (or storage bands)
	if ((d1 > 0 && d1 < MIN_SPEC_DIST / pixelScale + 1.) ||
	    (*slit1).second.slitEnd >= (*slit1).second.slitFovMax - 1.) {
	  (*slit1).second.locked_up = true;
	}
	if ((d2 > 0 && d2 < MIN_SPEC_DIST / pixelScale + 1.) ||
	    (*slit1).second.slitStart <= (*slit1).second.slitFovMin + 1.) {
	  (*slit1).second.locked_down = true;
	}

	// Leave inner for loop when both directions are locked
	if ((*slit1).second.locked_up == true && (*slit1).second.locked_down == true &&
	    ((*slit1).first == 34 || (*slit1).first == 35)) {
	  //	  cout << (*slit1).first << " locked in counter " << counter << endl;
	  break;
	}
      }

      // Expand slit1 by 1 pixel if not locked
      if (!(*slit1).second.locked_up) {
	(*slit1).second.slitEnd += 1.;
	expanded1 = true;
	//	cout << "expanding " << (*slit1).first << " up" << endl;
      }
      if (!(*slit1).second.locked_down) {
	(*slit1).second.slitStart -= 1.;
	expanded2 = true;
	// cout << "expanding " << (*slit1).first << " down" << endl;
      }
    }

    // Failsafe, we certainly don't have more than 10000 pixel available
    if (counter++ == 10000) {
      expanded1 = false;
      expanded2 = false;
    }
  }
  
  // Update the output lines
  for (slit1 = placed.begin(); slit1 != placed.end(); slit1++) {
    maxOptProcessLine(placed, (*slit1).first, dispDirection, pixelScale);
  }
}


/*
************************************************************************
*+
* FUNCTION: expandSlitToFOV
*
* RETURNS: none.
*
* DESCRIPTION: Expands slitlength of a given slit to the Field of view.
* This is called for the first and last slits in the mask, only
*
* [NOTES:]: Used in Max Mode.
*-
************************************************************************
*/

void expandSlitToFOV(Slit &slit) {
  
  float obj_spec_pos = slit.ccdW;
  float obj_spat_pos = slit.ccdL;

  // Calculate all possible intercepts with the bounding fov polygon
  vector<float> intercept = calc_intercept(obj_spec_pos);

  int i;
  int nvert = intercept.size();
  vector<float> diff(nvert,0);
  vector<float> tmp;

  // For vertical slits (horizontal dispersion), and a start (end) slit, the relevant
  // intercepts are all below (above) the spatial position of the slit. We just need to find the 
  // one that is closest. Likewise for horizontal start (end) slits, we must find the closest
  // intercept to the left (right). The code is symmetric and we don't need to distinguish
  // between dispersion direction.

  for (i=0; i<nvert; i++) {
    diff[i] = intercept[i] - obj_spat_pos;
  }

  // Lower limit: keep negative numbers only and find the largest thereof
  float max = -1.e9;
  int max_index = 0;
  for (i=0; i<nvert; i++) {
    if (diff[i] < 0. && diff[i] > max) {
      max = diff[i];
      max_index = i;
    }
  }
  slit.slitFovMin = intercept[max_index];

  // Upper limit: keep positive numbers only and find the smallest thereof
  float min = 1.e9;
  int min_index = 0;
  for (i=0; i<nvert; i++) {
    if (diff[i] > 0. && diff[i] < min) {
      min = diff[i];
      min_index = i;
    }
  }
  slit.slitFovMax = intercept[min_index];
}


//************************************************************************
// Calculates all possible intercepts of a slit with the boundary 
//************************************************************************
vector<float> calc_intercept(float obj_spec_pos) {

  int nvert = fov.vertx.size(); // The number of vertices in the fov polygon.

  vector<float> intercept(nvert,0.);
  float cut, slope, numerator, denominator;
  int i, k1 = 0, k2 = 0;

  // Calculate the intercepts for all boundary lines
  for (i=0; i<nvert; i++) {
    if (i<nvert-1) {
      k1 = i;
      k2 = i+1;
    }
    // For the last boundary line, we need to "wrap around"
    if (i==nvert-1) {
      k1 = i;
      k2 = 0;
    }

    numerator = fov.vert_spatial[k1] - fov.vert_spatial[k2];
    denominator = fov.vert_spectral[k1] - fov.vert_spectral[k2];

    if (denominator != 0.) {
      slope = numerator / denominator;
      cut = slope * (obj_spec_pos - fov.vert_spectral[k1]) + fov.vert_spatial[k1];
      // ignore the intercept if the finite boundary line does not overlap with the slit
      // e.g. bar code
      if ((obj_spec_pos < fov.vert_spectral[k1] && obj_spec_pos < fov.vert_spectral[k2]) ||
	  (obj_spec_pos > fov.vert_spectral[k1] && obj_spec_pos > fov.vert_spectral[k2])) {
	cut = 1.e9;
      }	
    }
    else {
      // No intercept, just put very large number:
      cut = 1.e9;
    }
    intercept.push_back(cut);
  }

  return intercept;
}


/*
************************************************************************
*+
* FUNCTION: maxOptProcessLine
*
* RETURNS: n/a
*
* DESCRIPTION: Process a line that has been expanded. 'ccdL', as well as 
*              'slitLength' need to be recalculated. 
*
* [NOTES:]:
*-
************************************************************************
*/
void maxOptProcessLine(map<int, Slit> &placed, int id1, string dispDirection,
		       float pixelScale) {
  // Unpack 'line'; recalc 'ccdL' and 'slitLength'; repack 'line'

  // Used for packing/unpacking each slit's line.
  string id, ra, dec, ccdW;
  string slitWidth, angle, mag, prio, type, redshift, specLeft, specRight, specBottom, specTop;
  string slitOffsetW;
  float ccdL = 0.0, slitLength = 0.0, slitOffsetL = 0.0;
  vector < string > lD; // (formerly "lineData")

  // Unpack line.
  lD = stringSplit(placed[id1].line, "\t");

  // Clean up last entry
  lD[17].erase(lD[17].find_last_not_of(" \t\r\n") + 1);

  // Some fields are different based on dispDirection.
  if (dispDirection == "horizontal") {
    stringToFloat(lD[4], ccdL);
  } 
  else {
    stringToFloat(lD[3], ccdL);
  }

  // Done unpacking line. 
  // Recalc slitlength and slitoffset (because of wiggling and auto-expansion)
  slitLength = (placed[id1].slitEnd - placed[id1].slitStart) * pixelScale;
  slitOffsetL = ((placed[id1].slitEnd + placed[id1].slitStart) / 2. - ccdL) * pixelScale;

  // Repack line. 
  char lineChar[512];

  if (dispDirection == "horizontal") {
    sprintf(lineChar,
	    "%s\t%s\t%s\t%s\t%s\t%s\t%8.6f\t%s\t%8.6f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	    lD[0].c_str(), lD[1].c_str(), lD[2].c_str(), lD[3].c_str(), lD[4].c_str(), lD[5].c_str(), slitOffsetL,
	    lD[7].c_str(), slitLength, lD[9].c_str(), lD[10].c_str(), lD[11].c_str(), lD[12].c_str(),
	    lD[13].c_str(), lD[14].c_str(), lD[15].c_str(), lD[16].c_str(), lD[17].c_str());
  } 
  else {
    sprintf(lineChar,
	    "%s\t%s\t%s\t%s\t%s\t%8.6f\t%s\t%8.6f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	    lD[0].c_str(), lD[1].c_str(), lD[2].c_str(), lD[3].c_str(), lD[4].c_str(), slitOffsetL, lD[6].c_str(),
	    slitLength, lD[8].c_str(), lD[9].c_str(), lD[10].c_str(), lD[11].c_str(), lD[12].c_str(),
	    lD[13].c_str(), lD[14].c_str(), lD[15].c_str(), lD[16].c_str(), lD[17].c_str());
  }

  placed[id1].line = lineChar;
}

/*
************************************************************************
*+
* FUNCTION: wiggleUnplaced
*
* RETURNS: Sucess code.
*
* DESCRIPTION: Tries to fit more slits on the mask by moving slits up or down.
*
* [NOTES:]:
*-
************************************************************************
*/
int wiggleUnplaced(map<int, Slit> * slits, map<int, Slit> * placed,
		   map<int, Slit> * removed, float microshufflePix,
		   string dispDirection, float pixelScale) {
  // Conflict graph between all slits.
  Graph conflictGraph;

  // The slits (placed and unplaced).
  map<int, Slit> allSlits;
  map<int, Slit>::iterator placedIterator;

  // The number of placed slits each removed slits conflicts with.
  map<int, int> conflictNum;

  // Used for holding conflict lists of loaded placed slits.
  vector<int> slitConflictList;

  Slit placedSlit;
  Slit cur;
  unsigned int i;
  int remId;

  // Possible wiggle room for the already placed slit.
  float placedWiggleRoom = 0;

  // Possible wiggle room for the unplaced slit.
  float curWiggleRoom = 0;

  // How much a placed slit has wiggled.
  float placedWiggleMag = 0;
  float curWiggleMag = 0;

  // True if each respective slits can be wiggled successfully.
  bool placedMove = false;
  bool curMove = false;

  allSlits.insert((*placed).begin(), (*placed).end());
  allSlits.insert((*removed).begin(), (*removed).end());

  // Map conflicts between all slits.
  mapConflicts(&conflictGraph, allSlits, microshufflePix, dispDirection, pixelScale);

  // Count how many times each removed slit conflicts with a placed slit.
  // We need to keep track of this because we are not going to place removed
  // slits that conflict with more than one placed slit.
  for (placedIterator = (*placed).begin(); placedIterator != (*placed).end();
       placedIterator++) {
    placedSlit = (*placedIterator).second;
    slitConflictList = (*conflictGraph.getNode(placedSlit.id)).getList();

    for (i = 0; i < slitConflictList.size(); i++) {
      remId = slitConflictList[i];

      if (conflictNum.count(remId) == 1) {
	conflictNum[remId]++;
      } 
      else {
	conflictNum[remId] = 1;
      }
    }
  }

  // Search for slits that can be moved, and move them.
  // NOTE: Only two slits are considered at a time.
  for (placedIterator = (*placed).begin(); placedIterator != (*placed).end();
       placedIterator++) {

    placedSlit = (*placedIterator).second;

    // Find valid wiggle amount for this slit.
    if (placedSlit.wiggleUsed == false) {
      placedWiggleRoom = placedSlit.wiggleRoom;
    } 
    else {
      // We can only wiggle once, so no dice.
      placedWiggleRoom = 0;
    }

    // Find list of slits excluded by this slit.
    slitConflictList = (*conflictGraph.getNode(placedSlit.id)).getList();

    // Try to place this slit if possible.
    // NOTE: Should be taking priority into account here?
    for (i = 0; i < slitConflictList.size(); i++) {
      remId = slitConflictList[i];

      if (conflictNum[remId] > 1) {
	// Can't add slits with more than one conflict.
	continue;
      }

      cur = (*removed)[remId];
      curWiggleRoom = cur.wiggleRoom;

      // Determine how the removed slit conflicts with the placed slit.
      if (placedSlit.slitEnd < cur.slitEnd &&
	  placedSlit.slitEnd > cur.slitStart && 
	  cur.slitStart > placedSlit.slitStart) {
	// Removed slit conflicts with the 'end' edge of the placed slit.

	// Test if it can be wiggled.
	if (placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST / pixelScale < curWiggleRoom) {
	  // Can fit while wiggling only removed slit.
	  curWiggleMag = placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST / pixelScale;
	  cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);

	  // Make sure mask is still valid.
	  if (checkConflicts(cur, placedSlit, (*placed), microshufflePix, dispDirection, pixelScale)) {
	    // Movement causes conflict, undo wiggle.
	    curWiggleMag *= -1;
	    cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);
	  } 
	  else {
	    // Movement does not cause conflict, flag for placement.
	    curMove = true;
	  }
	} 
	else if (placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST / pixelScale 
		 < curWiggleRoom + placedWiggleRoom) {
	  // Must wiggle both slits to fit.

	  // Determine relative wiggle magnitudes over both slits.
	  if (curWiggleRoom / 2.0 >= (placedSlit.slitEnd - cur.slitStart
				      + MIN_SPEC_DIST / pixelScale) / 2.0) {
	    if (placedWiggleRoom >= (placedSlit.slitEnd - cur.slitStart
				     + MIN_SPEC_DIST / pixelScale) / 2.0) {
	      // Can wiggle in equal parts.
	      curWiggleMag = (placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST / pixelScale) / 2.0;
	      placedWiggleMag = (placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST) / 2.0 * -1;
	    } 
	    else {
	      // Need more cur wiggle.
	      placedWiggleMag = placedWiggleRoom * -1;
	      curWiggleMag = placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST / pixelScale -
		placedWiggleRoom;
	    }
	  } 
	  else {
	    // Need more placed wiggle.
	    curWiggleMag = curWiggleRoom;
	    placedWiggleMag = (placedSlit.slitEnd - cur.slitStart + MIN_SPEC_DIST / 
			       pixelScale - curWiggleRoom) * -1;
	  }
	  
	  placedSlit.changePosition(0, placedWiggleMag, pixelScale, dispDirection);
	  cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);

	  // Make sure mask is still valid.
	  if (checkConflicts(cur, placedSlit, (*placed), microshufflePix, dispDirection, pixelScale) ||
	      checkConflicts(placedSlit, placedSlit, (*placed), microshufflePix, dispDirection, pixelScale)) {
	    curWiggleMag *= -1;
	    cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);
	    placedWiggleMag *= -1;
	    placedSlit.changePosition(0, placedWiggleMag, pixelScale, dispDirection);
	  } 
	  else {
	    curMove = true;
	    placedMove = true;
	  }
	}
      } 
      else if (placedSlit.slitStart > cur.slitStart &&
	       placedSlit.slitStart < cur.slitEnd &&
	       cur.slitEnd < placedSlit.slitEnd) {
	// Removed slit conflicts with the 'start' edge of the placed slit.

	// Test if slit can be wiggled.
	if (cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale < curWiggleRoom) {
	  // Can fit while wiggling only removed slit.

	  curWiggleMag = (cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale) * -1;
	  cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);

	  // Make sure mask is still valid.
	  if (checkConflicts(cur, placedSlit, (*placed), microshufflePix, dispDirection, pixelScale)) {
	    // Movement causes conflict, undo wiggle.
	    
	    curWiggleMag *= -1;
	    cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);
	  } 
	  else {
	    // Movement does not cause conflict, flag for placement.
	    curMove = true;
	  }

	} 
	else if (cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale <
		 curWiggleRoom + placedWiggleRoom) {
	  // Need to wiggle both slits to fit.

	  /*
	   * Determine relative wiggle magnitudes for the placed and
	   * unplaced slits.
	   */
	  if (curWiggleRoom / 2.0 >= 
	      (cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale) / 2.0) {

	    if (placedWiggleRoom >= 
		(cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale) / 2.0) {
	      // Can wiggle in equal parts.
	      curWiggleMag = (cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale) / 2.0 * (-1.);
	      placedWiggleMag = (cur.slitEnd - placedSlit.slitStart + MIN_SPEC_DIST / pixelScale) / 2.0;
	    }
	    else {
	      // Need more cur wiggle.
	      placedWiggleMag = placedWiggleRoom;
	      curWiggleMag = (cur.slitEnd - placedSlit.slitStart
			      + MIN_SPEC_DIST / pixelScale - placedWiggleRoom) * -1;
	    }
	  } 
	  else {
	    // Need more placed wiggle.
	    curWiggleMag = curWiggleRoom * -1;
	    placedWiggleMag = cur.slitEnd - placedSlit.slitStart
	      + MIN_SPEC_DIST / pixelScale - curWiggleRoom;
	  }

	  placedSlit.changePosition(0, placedWiggleMag, pixelScale, dispDirection);
	  cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);

	  // Make sure mask is still valid.
	  if (checkConflicts(cur, placedSlit, (*placed), microshufflePix, dispDirection, pixelScale)
	      || checkConflicts(placedSlit, placedSlit, (*placed), microshufflePix, dispDirection, pixelScale)) {
	    curWiggleMag *= -1;
	    cur.changePosition(0, curWiggleMag, pixelScale, dispDirection);
	    placedWiggleMag *= -1;
	    placedSlit.changePosition(0, placedWiggleMag, pixelScale, dispDirection);
	  } 
	  else {
	    curMove = true;
	    placedMove = true;
	  }
	}
      } 
      else {
	// Other cases, ignore.
	continue;
      }

      // Save changes into slit maps.
      if (curMove) {
	cur.wiggleUsed = true;
	(*removed).erase(cur.id);
	(*placed)[cur.id] = cur;
	(*slits)[cur.id] = cur;
      }
      if (placedMove) {
	placedSlit.wiggleUsed = true;
	(*placed)[placedSlit.id] = placedSlit;
	(*slits)[placedSlit.id] = placedSlit;
      }

      curMove = false;
      placedMove = false;
    }
  }

  return 0;
}

/*
************************************************************************
*+
* FUNCTION: wiggleNear
*
* RETURNS: None.
*
* DESCRIPTION: Create more space by moving placed slits closer to each other
*               (within the permitted wiggle space)
*
* [NOTES:]:
*-
************************************************************************
*/
bool wiggleNear(int sid, map<int, Slit> * slits, map<int, Slit> * placed,
		float pixelScale, string dispDirection) {
  map<int, Slit>::iterator slitIterator;

  // Gather information on slit to wiggle.
  Slit slit = (*slits)[sid];

  Slit cur;
  float curWiggleRoom;

  float wiggleMag = 0;
  float wiggleMagSlit = 0;
  float wiggleMagCur = 0;

  // If wiggle has been used then don't wiggle.
  if (slit.wiggleUsed) {
    return 0;
  }

  // Try to wiggle.
  for (slitIterator = (*placed).begin(); slitIterator != (*placed).end(); slitIterator++) {
    cur = (*slitIterator).second;

    if (cur.id == sid) {
      // Don't compare slit to itself.
      continue;
    }

    // If this cur hasn't been wiggled already then we can wiggle it here.
    if (cur.wiggleUsed == true) curWiggleRoom = 0;
    else curWiggleRoom = cur.wiggleRoom;

    // Detect and execute wiggle, if able.
    if (slit.slitEnd < cur.slitStart && 
	slit.slitEnd + slit.wiggleRoom > cur.slitStart - curWiggleRoom) {
      // Check top edge of slit to bottom edge of cur.

      wiggleMag = cur.slitStart - slit.slitEnd - MIN_SPEC_DIST / pixelScale;

      // Determine slit movement magnitudes.
      if (curWiggleRoom >= wiggleMag / 2.0 && slit.wiggleRoom >= wiggleMag / 2.0) {
	// Both slits can meet in the middle.
	wiggleMagCur  = wiggleMag / 2.0;
	wiggleMagSlit = wiggleMag / 2.0;
      } 
      else if (curWiggleRoom < wiggleMag / 2.0) {
	// cur cannot wiggle enough.
	wiggleMagCur  = curWiggleRoom;
	wiggleMagSlit = wiggleMag - curWiggleRoom;
      } 
      else if (slit.wiggleRoom < wiggleMag / 2.0) {
	// slit cannot wiggle enough.
	wiggleMagSlit = slit.wiggleRoom;
	wiggleMagCur  = wiggleMag - wiggleMagCur;
      }

      wiggleMagCur *= -1;

      // Apply changes to slit objects.
      slit.changePosition(0, wiggleMagSlit, pixelScale, dispDirection);
      cur.changePosition(0, wiggleMagCur, pixelScale, dispDirection);
      slit.wiggleUsed = true;
      cur.wiggleUsed = true;

      (*slits)[slit.id]  = slit;
      (*placed)[slit.id] = slit;
      (*slits)[cur.id]   = cur;
      (*placed)[cur.id]  = cur;
    } 
    else if (slit.slitStart > cur.slitEnd && 
	     slit.slitStart - slit.wiggleRoom < cur.slitEnd + curWiggleRoom) {

      // Check bottom edge of slit to top edge of cur.
      wiggleMag = slit.slitStart - cur.slitEnd - MIN_SPEC_DIST / pixelScale;

      // Determine slit movement magnitudes.
      if (curWiggleRoom >= wiggleMag / 2.0 && 
	  slit.wiggleRoom >= wiggleMag / 2.0) {
	// Both slits can meet in the middle.
	wiggleMagCur  = wiggleMag / 2.0;
	wiggleMagSlit = wiggleMag / 2.0;
      } 
      else if (curWiggleRoom < wiggleMag / 2.0) {
	// cur cannot wiggle enough.
	wiggleMagCur  = curWiggleRoom;
	wiggleMagSlit = wiggleMag - curWiggleRoom;
      } 
      else if (slit.wiggleRoom < wiggleMag / 2.0) {
	// slit cannot wiggle enough.
	wiggleMagSlit = slit.wiggleRoom;
	wiggleMagCur  = wiggleMag - wiggleMagCur;
      }

      wiggleMagSlit *= -1;

      // Apply changes to slit objects.
      slit.changePosition(0, wiggleMagSlit, pixelScale, dispDirection);
      cur.changePosition(0, wiggleMagCur, pixelScale, dispDirection);
      slit.wiggleUsed = true;
      cur.wiggleUsed = true;

      (*slits)[slit.id] = slit;
      (*placed)[slit.id] = slit;
      (*slits)[cur.id] = cur;
      (*placed)[cur.id] = cur;
    }
  }

  return 0;
}

/*
************************************************************************
*+
* FUNCTION: conflicts
*
* RETURNS: true or false
*
* DESCRIPTION: Returns true if the two slits conflict, false otherwise.
*
* [NOTES:]: msPix represents the movement in Microshuffle mode. 
*-
************************************************************************
*/
bool conflicts(Slit slitOne, Slit slitTwo, float msPix,
	       string dispDirection, float pixelScale) {
  float laserPad;

  // Uncomment the following line if you need to switch off conflict resolution for whatever purpose.
  // return false;

  // Return false if we are comparing two acq objects.
  // That is, spectra of acq sources may overlap
  if (slitOne.priority == '0' && slitTwo.priority == '0') {
    return false;
  }

  // Set minimum slit separation based on instrument type. (in pixels)
  if (dispDirection == "vertical") 
    laserPad = 2.685; // For F2. Not sure why!
  else 
    laserPad = 2.7;


  // Test spectra overlap in slitLength-wise direction.
  if ((slitTwo.slitEnd   >= slitOne.slitStart - msPix - MIN_SPEC_DIST / pixelScale &&
       slitTwo.slitEnd   <= slitOne.slitEnd   + msPix + MIN_SPEC_DIST / pixelScale) ||     
      (slitTwo.slitStart >= slitOne.slitStart - msPix - MIN_SPEC_DIST / pixelScale &&
       slitTwo.slitStart <= slitOne.slitEnd   + msPix + MIN_SPEC_DIST / pixelScale) || 
      (slitTwo.slitStart <= slitOne.slitStart + msPix + MIN_SPEC_DIST / pixelScale && 
       slitTwo.slitEnd   >= slitOne.slitEnd   - msPix - MIN_SPEC_DIST / pixelScale)) {
    
    // The slits overlap length-wise, now test if the spectra overlap width-wise.
    float s1SpectraEdge2 = slitOne.specEnd;
    float s1SpectraEdge1 = slitOne.specStart;
    float s2SpectraEdge2 = slitTwo.specEnd;
    float s2SpectraEdge1 = slitTwo.specStart;
    
    if ((s2SpectraEdge1 <= s1SpectraEdge2 + MIN_SPEC_DIST / pixelScale &&
	 s2SpectraEdge1 >= s1SpectraEdge1 - MIN_SPEC_DIST / pixelScale) ||   // slit 2 (right) overlaps with slit 1 (left)
	(s2SpectraEdge2 >= s1SpectraEdge1 - MIN_SPEC_DIST / pixelScale && 
	 s2SpectraEdge2 <= s1SpectraEdge2 + MIN_SPEC_DIST / pixelScale) ||   // slit 2 (left) overlaps with slit 1 (right)
	(s2SpectraEdge1 <= s1SpectraEdge1 + MIN_SPEC_DIST / pixelScale && 
	 s2SpectraEdge2 >= s1SpectraEdge2 - MIN_SPEC_DIST / pixelScale) ||   // slit 1 entirely contained in slit 2
	(s2SpectraEdge1 >= s1SpectraEdge1 + MIN_SPEC_DIST / pixelScale && 
	 s2SpectraEdge2 <= s1SpectraEdge2 - MIN_SPEC_DIST / pixelScale)) {   // slit 2 entirely contained in slit 1; probably unnecessary
      
      //      cout << "CONFLICT_______: " << slitOne.ccdW << " " << slitOne.ccdL << " " << slitTwo.ccdW << " " << slitTwo.ccdL << " " << s1SpectraEdge1 << " " << s1SpectraEdge2 << " " << s2SpectraEdge1 << " " << s2SpectraEdge2 << endl;
      
      // These slits conflict with eachother! 
      return true;
      
      // why not check that slit 2 is entirely contained in slit 1? -mischa
    } else {
      //cout << "NO_____CONFLICT: " << slitOne.ccdW << " " << slitOne.ccdL << " " << slitTwo.ccdW << " " << slitTwo.ccdL << " " << s1SpectraEdge1 << " " << s1SpectraEdge2 << " " << s2SpectraEdge1 << " " << s2SpectraEdge2 << endl;
    }
  }
  else if (((slitTwo.slitEnd   < slitOne.slitStart && slitOne.slitStart - laserPad < slitTwo.slitEnd) || 
	    (slitTwo.slitStart > slitOne.slitEnd   && slitOne.slitEnd   + laserPad > slitTwo.slitStart)) && 
	   ((slitTwo.slitTop   < slitOne.slitTop + laserPad || slitTwo.slitBottom < slitOne.slitTop + laserPad) &&
	    (slitTwo.slitTop   > slitOne.slitBottom - laserPad || slitTwo.slitBottom > slitOne.slitBottom - laserPad))) {
    //cout << "LaserPad conflict" << slitOne.ccdW << " " << slitOne.ccdL << " " << slitTwo.ccdW << " " << slitTwo.ccdL << endl;
    // why is this a problem? this should not be flagged if the spectra don't overlap in wavelengths -mischa
    return true;
  } else {
    //cout << "NO_SLIT_OVERLAP: " << slitOne.ccdW << " " << slitOne.ccdL << " " << slitTwo.ccdW << " " << slitTwo.ccdL << " " << slitOne.slitStart << " " << slitOne.slitEnd << " " << slitTwo.slitStart << " " << slitTwo.slitEnd << endl;
  }
  
  return false;
}

/*
************************************************************************
*+
* FUNCTION: removeConflicts
*
* RETURNS: A vector<Slit> containing the Slits that were not removed.
*
* DESCRIPTION: Scan conflictGraph for Slits that conflict with slits in 
*               placedSlits, remove those slits from slitData.
*
* [NOTES:]: O(n*m)
*-
************************************************************************
*/
void removeConflicts(map<int, Slit> * slits, map<int, Slit> * placed,
		     map<int, Slit> * removed, Graph conflictGraph) {
  map<int, Slit>::iterator it;
  vector<int>::iterator conIt;
  vector<int> conflictList;

  // Loop through placed slits, removing conflicts.
  for (it = placed->begin(); it != placed->end(); it++) {
    // Retreive list of slits (their ID's really) conflicting with placed slit.
    conflictList = conflictGraph.getNode((*it).first)->getList();

    // Loop through slits and remove. 
    for (conIt = conflictList.begin(); conIt != conflictList.end(); conIt++) {
      conflictGraph.removeNode((*conIt));
      removeSlit((*conIt), slits, removed);
    }
  }
}

/*
************************************************************************
*+
* FUNCTION: loadFov
*
* RETURNS: A vector containing field of view dimensions and vertices
*
* DESCRIPTION: Loads the data contained in the fov file.
*
* [NOTES:]:
*-
************************************************************************
*/
void loadFov(char *fovFile, float pixelScale, float crpix1, float crpix2, string dispDirection) {

  int num_fov = 0; // how many vertices for the field of view
  int num_dim = 0; // how many vertices for the overall dimensions (must be 4) 

  ifstream file;
  string line;
  vector<string> values;

  file.open(fovFile);
  if (!file.is_open()) {
    cout << "ERROR: Could not open file with FoV vertices: " << fovFile << endl; 
    exit (-1);
  }
  else {
    while (getline(file, line)) {
      // Read a line and trim leading and trailing white space, if any
      stringclean(line);
      // Extract the keyword values
      if (line.compare(0,10,"DIM_CORNER") == 0) {
	values = stringSplit(line, " ");
	fov.dimx.push_back( atof( values[1].c_str()) / pixelScale + crpix1);
	fov.dimy.push_back( atof( values[2].c_str()) / pixelScale + crpix2);
	num_dim++;
      }
      // WARNING: The following assumes that the vertices defining the polygon are 
      // defined sequentially in the fov file!
      if (line.compare(0, 10, "FOV_CORNER") == 0) {
	values = stringSplit(line, " ");
	fov.vertx.push_back( atof( values[1].c_str()) / pixelScale + crpix1);
	fov.verty.push_back( atof( values[2].c_str()) / pixelScale + crpix2);
	num_fov++;
      }
    }
  }

  // Check that we got the right number of vertices
  if (num_dim != 4) {
    cout << "ERROR! Found " << num_dim << " vertices for the overall detector dimensions" << endl;
    cout << "in " << fovFile << ". Must be 4!" << endl;
    exit (-1);
  }

  /*
  * Define, depending on dispersion direction:
  * -- the total spatial and the spectral width
  * -- the spatial and spectral centers of the illuminated area
  * -- the min and max points of the illuminated area (spectral and spatial)
  *
  *       X4-Y4 ---- X5-Y5
  *       /	        \
  *      /               \
  *   X3-Y3             X6-Y6
  *     |                 | 
  *     |                 | 
  *   X2-Y2             X7-Y7
  *      \               /
  *       \             /
  *       X1-Y1 ---- X8-Y8
  */

  // The boundaries are the boundaries of the min/max values of the corresponding vertices' x and y values
  float illumarea_xmin = min(fov.vertx);
  float illumarea_xmax = max(fov.vertx);
  float illumarea_ymin = min(fov.verty);
  float illumarea_ymax = max(fov.verty);
  float illumcenter_x  = (illumarea_xmin + illumarea_xmax) / 2.;
  float illumcenter_y  = (illumarea_ymin + illumarea_ymax) / 2.;

  if (dispDirection == "horizontal") {
    fov.vert_spatial  = fov.verty;
    fov.vert_spectral = fov.vertx;
    fov.totalwidth_spectral = (fov.dimx[3] + fov.dimx[2] - fov.dimx[1] - fov.dimx[0]) / 2.; // "average"
    fov.illumarea_spatial_min  = illumarea_ymin;
    fov.illumarea_spatial_max  = illumarea_ymax;
    fov.illumarea_spectral_min = illumarea_xmin;
    fov.illumarea_spectral_max = illumarea_xmax;
    fov.illumarea_spatial_center  = illumcenter_y;
    fov.illumarea_spectral_center = illumcenter_x;
  }
  else {
    fov.vert_spatial  = fov.vertx;
    fov.vert_spectral = fov.verty;
    fov.totalwidth_spectral = (fov.dimy[1] + fov.dimy[2] - fov.dimy[0] - fov.dimy[3]) / 2.; // "average"
    fov.illumarea_spatial_min  = illumarea_xmin;
    fov.illumarea_spatial_max  = illumarea_xmax;
    fov.illumarea_spectral_min = illumarea_ymin;
    fov.illumarea_spectral_max = illumarea_ymax;
    fov.illumarea_spatial_center  = illumcenter_x;
    fov.illumarea_spectral_center = illumcenter_y;
  }
}


/*
************************************************************************
*+
* FUNCTION: removeSlit
*
* RETURNS: n/a
*
* DESCRIPTION: Removes a slit from the 'slit' container and copies it 
*              into the 'removed' container for possible later use. 
*
* [NOTES:]: 
*
*-
************************************************************************
*/
void removeSlit(int sid, map<int, Slit> * slits, map<int, Slit> * removed) {
  // copy slit to 'removed' container, for possible future use. 
  removed->insert(pair<int, Slit>(sid, Slit((*slits)[sid])));
  // delete slit from 'slits' container.
  slits->erase(sid);
}

/*
************************************************************************
*+
* FUNCTION: writeSlits
*
* RETURNS: n/a
*
* DESCRIPTION: Writes slit data in the 'placed' container to the output
*              file.  
*
* [NOTES:]:
*-
************************************************************************
*/
void writeSlits(map<int, Slit> &placed, ofstream &outStream) {

  map<int, Slit>::iterator itSlits;
  string line;
  char temp[1024];

  // check if slits are tilted
  if (checkTilt(placed)) {
    sprintf(temp, "#fits TILTSLIT= 1 / Non-zero if tilted slits are present\n");
  } else {
    sprintf(temp, "#fits TILTSLIT= 0 / Non-zero if tilted slits are present\n");
  }
  outStream.write(temp, strlen(temp));

  // write the rest of the header
  outStream.write("# End fits keywords\n", strlen("# End fits keywords\n"));
  outStream.write("# End config entry\n\n", strlen("# End config entry\n\n"));
  sprintf(temp,
	  "ID	RA	DEC	x_ccd	y_ccd	slitpos_x	slitpos_y	slitsize_x	slitsize_y	slittilt	MAG	priority	slittype	redshift	specleft	specright	specbottom	spectop\n");
  outStream.write(temp, strlen(temp));
  sprintf(temp,
	  "------	---------	---------	---------	---------	------	------	---------	---------	--------	---	--------	--------	--------	--------	---------	----------	-------\n");
  outStream.write(temp, strlen(temp));
  
  // Write placed slits to file...
  for (itSlits = placed.begin(); itSlits != placed.end(); itSlits++) {
    line = (*itSlits).second.line;
    outStream.write(line.c_str(), strlen(line.c_str()));
  }
}

// Check if any of the placed slits is tilted
bool checkTilt(map<int, Slit> &placed) {

  map<int, Slit>::iterator itSlits;
  bool tilted = false;

  for (itSlits = placed.begin(); itSlits != placed.end(); itSlits++) {
    if ((*itSlits).second.angle != 0.0) {
      tilted = true;
      break;
    }
  }

  return tilted;
}

/*
************************************************************************
*+
* FUNCTION: bandShuffleCheck
*
* RETURNS: bool -- True if the slit is within a valid band, false otherwise.
*
* DESCRIPTION: See return value.
*
* [NOTES:]:
*-
************************************************************************
*/
bool bandShuffleCheck(float bandSize, float slitLength, float ccdL) {
  vector<float>::iterator bands;
  float slitStart, slitEnd, bandStart, bandEnd;

  slitStart = ccdL - slitLength / 2;
  slitEnd   = ccdL + slitLength / 2;

  for (bands = banddef.shuffleBands.begin(); bands != banddef.shuffleBands.end(); bands++) {
    bandStart = (*bands);
    bandEnd = bandStart + bandSize;
    if (slitStart > bandStart && slitEnd < bandEnd) {
      return true;
    }
  }

  return false;
}

/*
************************************************************************
*+
* FUNCTION: findMaxSpectrumSid
*
* RETURNS: The slit id of the slit with the most spectral coverage on the CCD.
*
* DESCRIPTION: Given a list of slit ids and a vector of slit objects return
*  the one which is most likely to have the most of its spectrum fall on the
*  detector.
*
* [NOTES:]:
*-
************************************************************************
*/
int findMaxSpectrumSid(vector<int> *slitIds, map<int, Slit> *slits, float fovMid) {

  int sid = 0;
  unsigned int i;
  float minDist = 32000;
  Slit cur;
  float curSpec;
  float curDist;
  int curId;

  // Find the slit whose spectrum is closest to being in the center of the
  // field of view (center refers to the spatial dimension, i.e. y-axis for GMOS)
  for (i = 0; i < (*slitIds).size(); i++) {
    curId = (*slitIds)[i];
    cur = (*slits)[curId];
    curSpec = cur.ccdL + cur.specPosL;
    curDist = (int) abs(fovMid - curSpec);

    if (curDist < minDist) {
      minDist = curDist;
      sid = curId;
    }
  }

  return sid;
}

/*
************************************************************************
*+
* FUNCTION: printIntro
*
* RETURNS: void
*
* DESCRIPTION: Print some introductory mask information to stdout.
*
* [NOTES:]: 
*
*-
************************************************************************
*/
void printIntro(char slitMode) {

  printf("----------------------------------------------------\n");
  printf("SPOC: SLIT POSITIONING OPTIMIZATION CODE\n");

  if (slitMode == 'M') {
    printf("SLIT SELECTION MODE: Max Sky\n\n");
  } 
  else {
    printf("SLIT SELECTION MODE: Normal\n\n");
  }
}

void printIntroError(int argc) {
  //Invalid input params.
  printf("----------------------------------------------------\n");
  printf("SPOC: SLIT POSITIONING OPTIMIZATION CODE\n\n");
  printf("ERROR: Invalid command line arguments: EXIT\n\n");
  printf(
	 "USAGE: gmMakeMasks <inFilename> <outFilename> <slitWidth> <specLen> <anamorphic>, argc=%d\n",
	 argc);
  printf(
	 "\t<centralWavelength> <linear dispersion> <lambda1Max> <lambda2Min> \n");
  printf("\t<pixelScale> <numMasks> <option> <debugLevel> \n");
  printf("DETAILS:\nPARM 1: input file name\n");
  printf("PARM 2: output file name without extention\n");
  printf("PARM 3: field of view config filename\n");
  printf("PARM 4: slitWidth(pix), 0 indicates used input file values\n");
  printf("PARM 5: spectra length(pix)\n");
  printf("PARM 6: spectra anamorphic factor\n");
  printf("PARM 7: central wavelength\n");
  printf("PARM 8: Linear dispersion\n");
  printf("PARM 9: Lambda 1 max\n");
  printf("PARM 10: Lambda 2 min\n");
  printf("PARM 11: pixelScale conversion factor\n");
  printf("PARM 12: number of masks\n");
  printf("PARM 13: type of algorithm:N/n=Normal_Opt M/m=Max_Opt\n");
  printf("    N=do not change object X-dimension distribution\n");
  printf("    M=get more objects but small ones are favored\n");
  printf("PARM 14: Debug level, 0=none, to 3=max\n");
  printf("PARM 15: Dispersion direction (horizontal or vertical)\n");
  printf("PARM 16: DET_IMG (detector ID)\n");
  printf("PARM 17: DET_SPEC (detector ID)\n");
  printf("PARM 18: RA of the preimage\n");
  printf("PARM 19: DEC of the preimage\n");
  printf("----------------------------------------------------\n");
}

/*
************************************************************************
*+
* FUNCTION: stringSplit
*
* RETURNS: vector<string>
*
* DESCRIPTION: Splits the string by one or more instances of 'delim'.
*
* [NOTES:]: I found this algorithm on an internet message board. 
*
*-
************************************************************************
*/
vector<string> stringSplit(string str, string delim) {
  vector < string > results;

  int cutAt;
  while (int((cutAt = str.find_first_of(delim))) != int(str.npos)) {
    if (cutAt > 0) {
      results.push_back(str.substr(0, cutAt));
    }
    str = str.substr(cutAt + 1);
  }

  if (str.length() > 0) {
    results.push_back(str);
  }

  return results;
}

/*
************************************************************************
*+
* FUNCTION: stringToInt
*
* RETURNS: A pass/fail bool
*
* DESCRIPTION: Takes a string and converts it to an int. Pass-by-reference. 
*
* [NOTES:]: I found this algorithm on an internet message board. 
*
*-
************************************************************************
*/
bool stringToInt(const string &s, int &i) {
  istringstream myStream(s);

  if (myStream >> i)
    return true;
  else
    return false;
}

/*
************************************************************************
*+
* FUNCTION: stringToFloat
*
* RETURNS: A pass/fail bool
*
* DESCRIPTION: Takes a string and converts it to a float. Pass-by-reference. 
*
* [NOTES:]: I found this algorithm on an internet message board.
*
*-
************************************************************************
*/
bool stringToFloat(const string &s, float &i) {
  istringstream myStream(s);

  if (myStream >> i)
    return true;
  else
    return false;
}

/**
 * ------------------- Helper Class Function Definitions -----------------------
 * (Maybe this should be in its own file, but these functions haven't caused
 *   any problems since they were created, and now they are out of the way)
 **/

/************************************************************************
 *+
 * CLASS: Slit
 *
 * DESCRIPTION: Defines a slit object to be used in the slit selection
 * algorithm.
 *
 *-
 ************************************************************************
 */
Slit::Slit() {
  this->id = 0;
  this->priority = ' ';
  this->slitStart = this->slitEnd = this->slitLength = -1;
}

Slit::Slit(int Id, char Priority) {
  this->id = Id;
  this->priority = Priority;
  this->slitStart = this->slitEnd = this->slitLength = -1;
}

Slit::Slit(int Id, char Priority, float start, float end) {
  this->id = Id;
  this->priority = Priority;
  this->slitStart = start;
  this->slitEnd = end;
  this->slitLength = end - start;
}

Slit::Slit(int Id, char Priority, float start, float end, float len, float posL,
	   float posW, float width, float top, float bottom, float specPL,
	   float specPW, float Angle, float wiggleFact, string ln, float w1, float w2) {
  this->id = Id;
  this->priority = Priority;
  this->slitStart = start;
  this->slitEnd = end;
  this->slitLength = len;
  this->ccdL = posL;
  this->ccdW = posW;
  this->slitWidth = width;
  this->line = ln;
  this->slitTop = top;
  this->slitBottom = bottom;
  this->specPosL = specPL;
  this->specPosW = specPW;
  this->angle = Angle;
  this->specStart = w1;
  this->specEnd = w2;


  if (Priority != '0' && wiggleFact > 0) {
    // Wiggle on!
    this->wiggleRoom = wiggleFact * slitLength;
    this->maxWiggle = this->wiggleRoom;
    this->wiggleUsed = false;
  } else {
    // Wiggle off or acq object.
    this->wiggleRoom = 0;
    this->maxWiggle = 0;
    this->wiggleUsed = true;
  }
}

/* FUNCTION changePosition
 *  Change the position of this slit.
 *
 */
int Slit::changePosition(float deltaW, float deltaL, float pixelScale,
			 string dispDirection) {
  // Edit slit class values.
  this->ccdL += deltaL;
  this->ccdW += deltaW;
  this->slitStart += deltaL;
  this->slitEnd += deltaL;
  this->slitTop += deltaW;
  this->slitBottom += deltaW;
  vector < string > lD;   // (formerly "lineData")
  float slitPosW = 0.0;
  float slitPosL = 0.0;

  // Unpack, edit and repack 'line' string.

  lD = stringSplit(this->line, "\t");

  // lD[0];   ID
  // lD[1];   RA
  // lD[2];   DEC
  // lD[3];   XCCD
  // lD[4];   YCCD
  // lD[7];   SIZEX
  // lD[8];   SIZEY
  // lD[9];   TILT
  // lD[10];  MAG
  // lD[11];  PRIO
  // lD[12];  TYPE
  // lD[13];  REDSHIFT
  // lD[14];  SPECLEFT
  // lD[15];  SPECRIGHT
  // lD[16];  SPECBOTTOM
  // lD[17];  SPECTOP

  // cleanup last string
  lD[17].erase(lD[17].find_last_not_of(" \t\r\n") + 1);

  if (dispDirection == "horizontal") {
    stringToFloat(lD[5], slitPosW);  // XOFFSET
    stringToFloat(lD[6], slitPosL);  // YOFFSET
  }
  else {
    stringToFloat(lD[5], slitPosL);  // XOFFSET
    stringToFloat(lD[6], slitPosW);  // YOFFSET
  }

  slitPosL += deltaL * pixelScale;
  slitPosW += deltaW * pixelScale;

  char lineChar[512];
  if (dispDirection == "horizontal") {
    sprintf(lineChar,
	    "%s\t%s\t%s\t%s\t%s\t%8.6f\t%8.6f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	    lD[0].c_str(), lD[1].c_str(), lD[2].c_str(), lD[3].c_str(), lD[4].c_str(), 
	    slitPosW, slitPosL, lD[7].c_str(), lD[8].c_str(), lD[9].c_str(), lD[10].c_str(),
	    lD[11].c_str(), lD[12].c_str(), lD[13].c_str(), lD[14].c_str(), lD[15].c_str(),
	    lD[16].c_str(), lD[17].c_str());
  } 
  else {
    sprintf(lineChar,
	    "%s\t%s\t%s\t%s\t%s\t%8.6f\t%8.6f\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
	    lD[0].c_str(), lD[1].c_str(), lD[2].c_str(), lD[3].c_str(), lD[4].c_str(), 
	    slitPosL, slitPosW, lD[7].c_str(), lD[8].c_str(), lD[9].c_str(), lD[10].c_str(),
	    lD[11].c_str(), lD[12].c_str(), lD[13].c_str(), lD[14].c_str(), lD[15].c_str(),
	    lD[16].c_str(), lD[17].c_str());
  }

  this->line = lineChar;

  return 0;
}

bool Slit::stringToFloat(const string &s, float &i) {
  istringstream myStream(s);

  if (myStream >> i)
    return true;
  else
    return false;
}

vector<string> Slit::stringSplit(string str, string delim) {
  vector < string > results;

  int cutAt;
  while (int((cutAt = str.find_first_of(delim))) != int(str.npos)) {
    if (cutAt > 0) {
      results.push_back(str.substr(0, cutAt));
    }
    str = str.substr(cutAt + 1);
  }

  if (str.length() > 0) {
    results.push_back(str);
  }

  return results;
}

/*
************************************************************************
*+
* CLASS: GraphNode
*
* DESCRIPTION: Element class for following Graph class.
*
*-
************************************************************************
*/

GraphNode::GraphNode() {
  this->id = -1;
}

GraphNode::GraphNode(int Id) {
  this->id = Id;
}

// Add an item to this GraphNode's adjList.
void GraphNode::addAdj(int addID) {
  this->adjList.push_back(addID);
}

// Remove an id from this GraphNode's adjList.
void GraphNode::removeAdj(int targetID) {
  vector<int>::iterator it;

  // search for target item and remove:
  for (it = this->adjList.begin(); it != this->adjList.end(); it++) {
    if (*it == targetID) {
      this->adjList.erase(it);
      break;
    }
  }
}

vector<int> GraphNode::getList() {
  return this->adjList;
}

int GraphNode::getDegree() {
  return this->adjList.size();
}

/*
************************************************************************
*+
* CLASS: Graph
*
* DESCRIPTION: An adjacency-list type graph data structure.
*
*
*-
************************************************************************
*/

// Adds a GraphNode to the Graph
void Graph::addNode(int targetID) {
  elements[targetID] = GraphNode(targetID);
}

// Removes a GraphNode from the Graph
void Graph::removeNode(int nid) {
  vector<GraphNode>::iterator it;

  // Remove all edges connected to this node.
  this->clearEdges(&elements[nid]);

  // Remove element.
  elements.erase(nid);
}

// Clears the graph.
void Graph::clear() {
  map<int, GraphNode>::iterator it;

  for (it = elements.begin(); it != elements.end(); it++) {
    removeNode((*it).first);
  }
}

// Adds an edge between two GraphNodes.
void Graph::addEdge(GraphNode * node1, GraphNode * node2) {
  node1->addAdj(node2->id);
  node2->addAdj(node1->id);
}

// Removes an edge between two GraphNodes.
void Graph::removeEdge(GraphNode * node1, GraphNode * node2) {
  node1->removeAdj(node2->id);
  node2->removeAdj(node1->id);
}

// Fetches a reference to a GraphNode.
GraphNode * Graph::getNode(int nid) {
  return &elements[nid];
}

// Clears all edges connected to to given node.
void Graph::clearEdges(GraphNode * node) {
  vector<int>::iterator it;
  vector<int> list = node->getList();

  for (it = list.begin(); it != list.end(); it++) {
    this->removeEdge(node, getNode((*it)));
  }
}

// Returns true if the Graph is empty of GraphNodes.
bool Graph::empty() {
  return elements.size() == 0;
}

int Graph::size() {
  return elements.size();
}

// Returns a list of nodes that have the lowest degrees.
vector<int> Graph::getMinDegree() {
  // Map iterator.
  map<int, GraphNode>::iterator it;

  // Map container for nodes with min cardinality.
  vector<int> minNodeIds;
  int min = 32000;
  int curID;
  int curDegree;

  // Find minimum degree and populate min degree list.
  for (it = elements.begin(); it != elements.end(); it++) {
    curDegree = (*it).second.getDegree();
    if (curDegree < min) {
      // New lowest degree.
      // Erase low degree list and add this item.
      min = curDegree;
      curID = (*it).first;
      minNodeIds.clear();
      minNodeIds.push_back(curID);
    } 
    else if (curDegree == min) {
      // Another item with lowest degree. Add to map.

      curID = (*it).first;
      minNodeIds.push_back(curID);
    }
  }

  return minNodeIds;
}


//****************************************************************
// Remove leading and trailing whitespace
// Replace all whitespace by blanks
// Replace all multiple whitespace by single blanks
//****************************************************************
void stringclean(string &str)
{
  // First, remove leading and trailing whitespace (blanks and tabs)
  const size_t strBegin = str.find_first_not_of(" \t");
  if (strBegin != string::npos) {
    const size_t strEnd = str.find_last_not_of(" \t");
    const size_t strRange = strEnd - strBegin + 1;
    
    str = str.substr(strBegin, strRange);
  }

  // Second, replace all tabs by blanks
  size_t i = 0;
  while (i<str.length()) {
    if (str[i] == '\t') str.replace(i,1," ");
    else i++;
  }

  // Third, shrink all multiple whitespaces
  // replace sub ranges
  string result = str;
  string fill = " ";
  size_t beginSpace = result.find_first_of(" ");
  while (beginSpace != string::npos) {
    const size_t endSpace = result.find_first_not_of(" ", beginSpace);
    const size_t range = endSpace - beginSpace;
    result.replace(beginSpace, range, fill);
    const size_t newStart = beginSpace + fill.length();
    beginSpace = result.find_first_of(" ", newStart);
  }
  
  str = result;
}


//****************************************************************
// Remove all characters in string 'key' from string 'src'
//****************************************************************
string RemoveChars(string src, string key)
{
  string dest(src.length(), ' ');
  bool found;
  size_t i, j, k;
  
  k = 0;
  // step through the source string
  for (i=0; i<src.length(); i++) {
    found = false;
    // step through the string with bad chars and look for matches
    for (j=0; j<key.length(); j++ ) {
      if ( src[i] == key[j] ) found = true;
    }
    // if no match found, append the source char to the destination char
    if (!found) dest[k++] = src[i];
  }
  
  return (dest);
}

//***************************************************************************
// Get the value of a keyword - value pair (i.e. the second word in a string
//***************************************************************************
float get_keyvalue(string line) {

  // Remove leading and trailing whitespace
  stringclean(line);
  size_t pos = line.find(" ");

  // If no blank is found then this means that the keyword has no value assigned to it
  // and that the fov file is corrupt.
  if (pos == string::npos) {
    cout << "ERROR: No keyword value found for " << line << endl;
    exit (-1);
  }

  // A keyword value is present, extract and return it:
  return atof(line.substr(pos+1,line.length()).c_str());
}

//****************************************************************************
// min of vector
//****************************************************************************
float min(vector<float> const &data)
{
  unsigned long i;
  float minval = data[0];
  size_t dim = data.size();

  for (i=0; i<dim; i++) {
    if (data[i] < minval) minval = data[i];
  }
  
  return (minval);
}


//****************************************************************************
// max of vector
//****************************************************************************
float max(vector<float> const &data)
{
  unsigned long i;
  float maxval = data[0];
  size_t dim = data.size();

  for (i=0; i<dim; i++) {
    if (data[i] > maxval) maxval = data[i];
  }
  
  return (maxval);
}


//****************************************************************************
// For debugging purposes, only
//****************************************************************************
void printSlit(map<int, Slit> slitData, int id, int label, float specLength) {

  map<int, Slit>::iterator it; // Iterator object.

  // Loop through 'slit' container to find slits of the given prio.
  for (it = slitData.begin(); it != slitData.end(); it++) {
    float left = (*it).second.ccdW + (*it).second.specPosW - specLength / 2.0;
    float right = (*it).second.ccdW + (*it).second.specPosW + specLength / 2.0;
    if ( (*it).second.id == id || (*it).second.id == 22) {
      printf("TEST %d: %d %c %f %f %f %f\n", label, (*it).second.id, (*it).second.priority, (*it).second.ccdW, (*it).second.ccdL, left, right);
    }
  }
}


//****************************************************************
// split a sentence into a vector of words
//****************************************************************
vector<string> getword(string str, char delimiter) {
  vector<string> internal;
  stringstream ss(str); // Turn the string into a stream.
  string tok;
  
  while(getline(ss, tok, delimiter)) {
    internal.push_back(tok);
  }
  
  return internal;
}


//****************************************************************
// remove leading and trailing whitespace
//****************************************************************
void trim(string &str, const string& whitespace)
{
  const size_t strBegin = str.find_first_not_of(whitespace);
  if (strBegin != string::npos) {
    const size_t strEnd = str.find_last_not_of(whitespace);
    const size_t strRange = strEnd - strBegin + 1;
    
    str = str.substr(strBegin, strRange);
  }
}
