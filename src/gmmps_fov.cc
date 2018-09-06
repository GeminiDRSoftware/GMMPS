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
PURPOSE:
Extract the exact GMOS field of view, and rejects all objects outside.
A modified catalog is written were all objects outside are omitted.

SYNOPSIS
gmmps_FoV <input> <output> <dataFile> <pixelScale>

The dataFile contains the x|y vertices of the FoV with respect to some fiducial center
All co-ordinates are in arc seconds, and converted to pixels.

This is a generic scheme and the number of vertices may deviate depending on instrument

       X4-Y4 ----- X5-Y5
       /              \
      /                \
   X3-Y3              X6-Y6
     |                  | 
     |         X        | 
     |                  | 
   X2-Y2              X7-Y7
      \                /
       \              /
       X1-Y1 ----- X8-Y8

Arguments:
<input> full input file name.  File format:
ID, RA, DEC, X, Y, posX, posY, dX, dY, tilt, mag, priority, type

<output> full output file name.
ID, RA, DEC, X, Y, posX, posY, dX, dY, tilt, mag, priority, type

<pixelScale> 

<data> full name of file containing the vertices
*/


#include <iostream>
#include <cstdlib>
#include <fstream>
#include <cmath>
#include <string>
#include <cstring>
#include <vector>

using namespace std;

// Prototypes
int pnpoly(vector<float>&, vector<float>&, float, float);
void stringclean(string&);
int readInData(char*, float, float, float, vector<float>&, vector<float>&);
vector<string> stringSplit(string, string);


// ************************************************************************
// FUNCTION: main
// RETURNS: int, [short description]
// ************************************************************************
int main (int argc, char *argv[]) {
  int num;
  int numDropped, numGuides;
  int numP1, numP2, numP3;  // Num objects dropped.
  float X, Y;
  float dX, dY;         // Slit dimensions in x and y.
  float pX, pY;
  double rah, ram, ras;
  double decg, decm, decs;
  double ra, dec;
  float tilt;		// Slit tilt angle
  float mag;		// Magnitude
  float redshift;
  char priority, type;	// Priority of object & slit type
  char inputname[200], outputname[200], dataname[200];
  int cntr;			// Num of variables read from file
  float	pixelScale;		// Pixel scale
  float crpix1, crpix2;         // fiducial center
  string line;

  // Normally I'd use cerr instead of cout to print all the errors, 
  // but then they don't show up in the skycat message window. So cout it is...


  // COMMAND LINE INPUT 
  if(argc==7) {
    strcpy(inputname,argv[1]);
    strcpy(outputname,argv[2]);
    strcpy(dataname,argv[3]);
    pixelScale = atof(argv[4]);
    crpix1 = atof(argv[5]);
    crpix2 = atof(argv[6]);
  }
  else {
    cout << "gmmps_FoV: WRONG INPUT COMMAND LINE: EXIT" << endl;
    cout << "USAGE: gmmps_fov <inputFile> <output> <data> <pixelScale> <crpix1> <crpix2>." << endl;
    cout << "       <inputFile> full input file name." << endl;
    cout << "       <output> full output file name." << endl;
    cout << "       <data> name of file containing cut-off coordinates." << endl;
    cout << "       <pixelScale> conv. factor to get pixels from arcs." << endl;
    cout << "       <crpix1> x-coord of the fiducial center" << endl;
    cout << "       <crpix2> y-coord of the fiducial center" << endl;
    return -1;
  }
  
  // Read in the data file and get the co-ordinates
  vector<float> vertx, verty;
  if ( readInData(dataname, pixelScale, crpix1, crpix2, vertx, verty) != 0 ) {
    cout << "gmmps_FoV: Bad data file: " << dataname << endl;
    return -1;
  }
  
  // Open input object file
  ifstream inFile(inputname);
  if (!inFile.is_open()) {
    cout << "ERROR: Could not open " << inputname << " for reading!" << endl; 
    return -1;
  }

  // Open output object file
  ofstream outFile(outputname);
  if (!outFile.is_open()) {
    cout << "ERROR: Could not open " << outputname << " for writing!" << endl; 
    return -1;
  }

  // Initialise object counters
  numDropped = numGuides = numP1 = numP2 = numP3 = 0;
  
  // Read input file
  while (getline(inFile, line)) {
      // Read a line and "clean" its white spaces
      stringclean(line);
      if (line.compare(0,1,"#") == 0) continue;
      if (line.length() < 2) continue;

      // Read in while checking the format. If incorrect then don't continue
      const char *cline = line.c_str();
      if ( (cntr = sscanf(cline, "%d %lf:%lf:%lf %lf:%lf:%lf %f %f %f %f %f %f %f %f %c %c %f",
			  &num, &rah, &ram, &ras, &decg, &decm, &decs, &X, &Y,
			  &pX, &pY, &dX, &dY, &tilt, &mag, &priority, &type, &redshift)) == EOF || cntr != 18 ) {
	cout << "ERROR: Bad inputline: " << line.c_str() << endl;
	cout << "Exiting." << endl;
	inFile.close();
	outFile.close();
	return (-1);
      }

      // Convert RA and DEC to decimal degrees
      if ( rah != 0.0 ) ra = (rah/abs(rah)) * (abs(rah)*15+ram/4+ras/240);
      else ra = (rah)*15+ram/4+ras/240;

      // Dec needs special treatment as the first two digits might be negative zero (e.g. -00:12:34)
      // Originally by @@cba
      dec = copysign( (double)1.0, (double)decg) * (abs(decg)+decm/60+decs/3600);

      //  Calculate the real slit position, x_ccd+(slitpos_x/pixelScale), 
      //  and do the same for y.
      X += ( pX / pixelScale ); 
      Y += ( pY / pixelScale ); 

      // Keep only slits that are at least 90% within the FoV.
      // Eventually, this should become an input parameter in GMMPS
      bool positiontest = true;
      int polytest;

      float fraction = 0.9;
      float fdX = fraction*0.5*dX / pixelScale; // x0.5 is to get half the slit dimension
      float fdY = fraction*0.5*dY / pixelScale;
      // check the lower left corner of the slit
      polytest = pnpoly(vertx, verty, X-fdX, Y-fdY);
      if (polytest == 0) positiontest = false;
      // check the lower right corner of the slit
      polytest = pnpoly(vertx, verty, X+fdX, Y-fdY);
      if (polytest == 0) positiontest = false;
      // check the upper left corner of the slit
      polytest = pnpoly(vertx, verty, X-fdX, Y+fdY);
      if (polytest == 0) positiontest = false;
      // check the upper right corner of the slit
      polytest = pnpoly(vertx, verty, X+fdX, Y+fdY);
      if (polytest == 0) positiontest = false;

      // If inside, write it to output file
      if (positiontest) {
	outFile << " " << num << " ";
	outFile.precision(10);
	outFile << ra << " " << dec << " ";
	outFile.precision(6);
	outFile << (X-(pX/pixelScale)) << " " << (Y-(pY/pixelScale)) << " " <<
	  pX << " " << pY << " " << dX << " " << dY << " " << tilt << " " << 
	  mag << " " << priority << " " << type << " " << redshift << " " << endl;
      }
      else {
	numDropped++;
	if      ( priority == '0' ) numGuides++;
	else if ( priority == '1' ) numP1++;
	else if ( priority == '2' ) numP2++;
	else if ( priority == '3' ) numP3++;
      }
  }

  inFile.close();
  outFile.close();

  cout << "Objects outside mask area : " << numDropped << endl;
  if (numDropped > 0) {
    cout << "Thereof priority 0/1/2/3/X: " << numGuides << " / " << numP1 << " / " << numP2 << " / " << numP3 << " / " << numDropped - (numGuides+numP1+numP2+numP3) << endl;
  }
  cout << "----------------------------------------------------" << endl;
  return 0;
}


// ************************************************************************
// FUNCTION: readInData
// RETURNS: int, [0=success ]
// Read in the vertices of the FoV
// ************************************************************************
int readInData(char *fileName, float pixelScale, float crpix1, float crpix2,
	       vector<float>&vertx, vector<float>&verty) {

  ifstream file;
  string line;
  vector<string> values;

  file.open(fileName);
  if (!file.is_open()) {
    cout << "ERROR: Could not open file with FoV vertices: " << fileName << endl; 
    return -1;
  }
  else {
    while (getline(file, line)) {
      // Read a line and trim leading and trailing white space, if any
      stringclean(line);
      // Parse the line: find the blank, and extract everything from there to the end
      if (line.compare(0, 10, "FOV_CORNER") == 0) {
	values = stringSplit(line," ");
	vertx.push_back( atof( values[1].c_str()) / pixelScale + crpix1);
	verty.push_back( atof( values[2].c_str()) / pixelScale + crpix2);
      }
    }
  }

  if (vertx.size() != verty.size() ) {
    cout << "ERROR: Invalid FOV vertex definitions in " << fileName << endl;
    file.close();
    return (-1);
  }
  
  file.close();
  return (0);
}



//***************************************************************
// Test if a point is inside a polygon
//***************************************************************

/*
Polygon tester (pnpoly)

Copyright (c) 1970-2003, Wm. Randolph Franklin

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions: 

(1) Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimers.
(2) Redistributions in binary form must reproduce the above copyright notice in 
the documentation and/or other materials provided with the distribution.
(3) The name of W. Randolph Franklin may not be used to endorse or promote 
products derived from this Software without specific prior written permission. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE. 
*/

int pnpoly(vector<float> &vertx, vector<float> &verty, float testx, float testy)
{
  long i, j, c = 0;
  long nvert = vertx.size();

  for (i=0, j=nvert-1; i<nvert; j=i++) {
    if ( ((verty[i]>testy) != (verty[j]>testy)) &&
	 (testx < (vertx[j]-vertx[i]) * (testy-verty[i]) / (verty[j]-verty[i]) + vertx[i]) )
      c = !c;
  }
  // Returns 1 if the object is inside the polygon and 0 if it is outside.
  // If the object is EXACTLY on the bundary line the output is undetermined (either 0 or 1),
  // determined by rounding errors.

  return c;
}


//****************************************************************
// Remove leading and trailing whitespace
// Replace tabs by blanks
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
    if (str[i]=='\t') str.replace(i,1," ");
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
