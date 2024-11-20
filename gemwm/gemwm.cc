#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <cmath>
#include <string>
#include <cstring>
#include <vector>
#include <iomanip>

#include "gemwm.h"
#include "instrument.h"

using namespace std;

void read_slittable(const string filename, instrument &inst);
void read_wavecal_table(instrument &inst);

void usage(int i, char *argv[])
{
  if (i == 0) {
    cout << "\n";
    cout << "  USAGE: " << argv[0] << endl;
    cout << "           -i instrument [GMOS-N, GMOS-S, F2]" << endl;
    cout << "           -m mode (MOS)" << endl;
    cout << "           -g grating (for GMOS: B600, B1200, R150, R400, R831, R831_2nd, R600)" << endl;
    cout << "                      (for F2: R1200_JH, R1200_HK, R3000_Y, R3000_J, R3000_H, R3000_K)" << endl;
    cout << "           -c CWL (Angstrom)" << endl;
    cout << "          [-x xslit yslit lambda (slit position and lambda, returns xpos for lambda)]" << endl;
    cout << "          [-l xslit yslit xpos (slit position and xpos, returns lambda for xpos)]" << endl ;
    cout << "             OR (instead of -x or -l)" << endl;
    cout << "          [-f filename (file with slit positions and conversion instructions)]\n" << endl;
    exit(1);
  }
}

int main (int argc, char *argv[]) {

  string instname = "";
  string mode = "";
  string disperser = "";
  string conversion = "";
  string filename = "";
  double cwl   = 0.0;
  double xslit = 0.0;
  double yslit = 0.0;
  double xpos  = 0.0;
  double lambda = 0.0;
  bool from_file = false;
  
  // print usage if no arguments were given
  if (argc==1) usage(0, argv);

  int i;
  for (i=1; i<argc; i++) {
    if (argv[i][0] == '-') {
      switch(tolower((int)argv[i][1])) {
      case 'i': instname = argv[++i];
	break;
      case 'f': filename = argv[++i];
	from_file = true;
	break;
      case 'm': mode = argv[++i];
	break;
      case 'g': disperser = argv[++i];
	break;
      case 'c': cwl = atof(argv[++i]);
	break;
      case 'x': 
	xslit  = atof(argv[++i]);
	yslit  = atof(argv[++i]);
	lambda = atof(argv[++i]);
	conversion = "lambda2x";
	break;
      case 'l': 
	xslit = atof(argv[++i]);
	yslit = atof(argv[++i]);
	xpos  = atof(argv[++i]);
	conversion = "x2lambda";
	break;
      }
    }
  }

  // constructor (also does basic consistency checks)
  instrument inst(instname, disperser, mode, cwl);

  // Read the wavelength calibration table;
  // selects correct instrument and disperser internally
  read_wavecal_table(inst);
  
  // Bulk conversions for a file
  if (from_file) {
    read_slittable(filename, inst);
  }
  // single conversions
  else {
    cout << setprecision(8);
    if (conversion.compare("lambda2x") == 0) 
      cout << inst.lambda2x(xslit, yslit, lambda) << endl;
    if (conversion.compare("x2lambda") == 0)
      cout << inst.x2lambda(xslit, yslit, xpos) << endl;
  }

  return 0;
}

//**************************************************
// Check the environment variable
//**************************************************
void check_environmentvar()
{
  string datapath( getenv("GMMPS"));

  cerr << "ERROR: GMMPS environment variable not set or incorrect." << endl;
  cerr << "This is an absolute path pointing to gemwm/data/" << endl;
  cerr << "in the GMMPS installation tree." << endl;
  cerr << "The current value of GMMPS is: " << datapath << endl;
  exit (1);
}

// ***********************************************************
// Read a table with slit positions and conversion data
// ***********************************************************
void read_slittable(const string filename, instrument &inst)
{
  string line;
  const char *file = filename.c_str();
  ifstream input(file);
  ofstream output("gemwm.output");

  // Leave if files could not be opened
  if (!input.is_open()) {
    cerr << "ERROR: Could not read from file: " << filename << endl;
    exit (1);
  }
  if (!output.is_open()) {
    cerr << "ERROR: Could not open file for output!" << endl;
    exit (1);
  }

  string conversionmode;
  string label;
  double result, lambda;
  double glob_lambdamin = 3000.;
  double glob_lambdamax = 25000.;
  double xslit, yslit, a, lambdamin, lambdamax;
  double dimx, dimy, slittilt, xshift, yshift;
  double dlambda=1000.;
  int objid;

  // some reasonable default settings for the wavelength grids
  if (inst.name.compare("GMOS-S") == 0 || inst.name.compare("GMOS-N") == 0) {
    if (inst.disperser.compare("R150") == 0)     dlambda = 1000;
    if (inst.disperser.compare("R400") == 0)     dlambda = 500;
    if (inst.disperser.compare("B480") == 0)     dlambda = 400;
    if (inst.disperser.compare("B600") == 0)     dlambda = 250;
    if (inst.disperser.compare("R600") == 0)     dlambda = 250;
    if (inst.disperser.compare("R831") == 0)     dlambda = 200;
    if (inst.disperser.compare("B1200") == 0)    dlambda = 100;
    if (inst.disperser.compare("R831_2nd") == 0) dlambda = 100;
  }
  if (inst.name.compare("F2") == 0) {
    if (inst.disperser.compare("R1200_JH") == 0) dlambda = 1000;
    else if (inst.disperser.compare("R1200_HK") == 0) dlambda = 1000;
    else if (inst.disperser.compare("R3000_Y") == 0)  dlambda = 500;
    else if (inst.disperser.compare("R3000_J") == 0)  dlambda = 500;
    else if (inst.disperser.compare("R3000_H") == 0)  dlambda = 500;
    else if (inst.disperser.compare("R3000_K") == 0)  dlambda = 500;
    else {
      cerr << "ERROR: GEMWM: Invalid grism+filter combination: " << inst.disperser << endl;
      return;
    }
  }

  // Read the file and do the conversions
  //  while (getline(input, line)) {
  //  istringstream iss(line);
    while(input >> conversionmode >> xslit >> yslit >> a >> lambdamin >> lambdamax
	  >> dimx >> dimy >> xshift >> yshift >> slittilt >> objid >> label) {

    // Calculate wavelengths of the gap edges
    // (here dimx is the gap number (1...4), sorry for the crappy programming)
    if (conversionmode.compare("gap") == 0) {
      result = inst.x2lambda(xslit, yslit, a);
      // print only if resulting wavelength is within the spectral range
      if (result >= lambdamin && result <= lambdamax) { 
	output << conversionmode << " " << xslit << " " << yslit << " " << a 
	       << " " << result / 10. << " " << dimx << " " << dimy << " " << xshift 
	       << " " << yshift << " " << slittilt << " " << objid << " " << label << endl;
      }
    }

    // Calculate the locations of a wavelength grid
    if (conversionmode.compare("grid") == 0) {
      // do a wavelength grid
      for (lambda=glob_lambdamin; lambda<=glob_lambdamax; lambda += dlambda) {
	if (lambda>=lambdamin && lambda<=lambdamax) {
	  result = inst.lambda2x(xslit, yslit, lambda);
	  // make every other wavelength label, only
	  double sign = 1.;
	  if ( int ((lambda-glob_lambdamin)/dlambda) %2 == 0) sign = +1.;
	  else sign = -1.;
	  // write result only if positive
	  if (result > 0.) {
	    output << conversionmode << " " << xslit << " " << yslit 
		   << " " << sign*lambda / 10. << " " << result << " " << dimx 
		   << " " << dimy << " " << xshift << " " << yshift 
		   << " " << slittilt << " " << objid << " " << label << endl;
	  }
	}
      }
    }

    // Do CWL
    if (conversionmode.compare("cwl") == 0) {
      result = inst.lambda2x(xslit, yslit, a);
      if (result > 0.) {
	output << conversionmode << " " << xslit << " " << yslit << " " << a/10. 
	       << " " << result << " " << dimx << " " << dimy << " " << xshift 
	       << " " << yshift << " " << slittilt << " " << objid << " " << label << endl;
      }
    }

    // Do individual wavelengths
    if (conversionmode.compare("indwave") == 0 ) {
      result = inst.lambda2x(xslit, yslit, a);
      if (a>=lambdamin && a<=lambdamax && result > 0) {
	output << conversionmode << " " << xslit << " " << yslit << " " << a/10. 
	       << " " << result << " " << dimx << " " << dimy << " " << xshift 
	       << " " << yshift << " " << slittilt << " " << objid << " " << label << endl;
      }
    }

    // do boxes
    if (conversionmode.compare("box") == 0 || 
	conversionmode.compare("acq") == 0) {
      string linearmode="";
      if (inst.disperser.compare("R831_2nd") == 0) {
	linearmode = "linear";
      }
      
      double result1 = inst.lambda2x(xslit, yslit, lambdamin, linearmode);
      double result2 = inst.lambda2x(xslit, yslit, lambdamax, linearmode);
      output << conversionmode << " " << xslit << " " << yslit << " " << a/10. 
	     << " " << result1 << " " << dimx << " " << dimy << " " << result1 
	     << " " << result2 << " " << slittilt << " " << objid << " " << label << endl;
    }

    // do 2nd-order box
    if (conversionmode.compare("2ndorder") == 0) {
      float order = 1.;
      double result1, result2;
      if (inst.disperser.compare("R831_2nd") == 0) {
	order = 2.;
      }

      // Use the nonlinear wavelength maps for that wavelength boundary that is expected
      // to be within the field of view, and linear ones for the "outer" boundary.
      // The nonlinear version might give totally wrong results.

      if (order == 1) {
	// higher order overlap
	result1 = inst.lambda2x(xslit, yslit, (order+1.)*lambdamin);
	result2 = inst.lambda2x(xslit, yslit, (order+1.)*lambdamax, "linear");
	output << conversionmode << " " << xslit << " " << yslit << " " << a/10. 
	       << " " << result1 << " " << dimx << " " << dimy << " " << result1 
	       << " " << result2 << " " << slittilt << " " << objid << " " << label << endl;
	// Use a -20 to +20A interval to make zero order box visible
	// Only for R150. For other gratings the zero order is never visible,
	// and the wavelength inversions become nonsensical anyway.
	// NOPE! Unstable if shifting CWLs around
	/*
	if (inst.disperser.compare("R150") == 0) {
	  result1 = inst.lambda2x(xslit, yslit, -20., "linear");
	  result2 = inst.lambda2x(xslit, yslit, 20., "linear");
	  output << conversionmode << " " << xslit << " " << yslit << " " << a/10. 
		 << " " << result1 << " " << dimx << " " << dimy << " " << result1 
		 << " " << result2 << " " << slittilt << " " << objid << " " << label << endl;
	}
	*/
      }
      
      if (order == 2.) {
	// 3rd order overlap does not exist for GMOS if in 2nd order mode
	result1 = inst.lambda2x(xslit, yslit, lambdamin/order, "linear");
	result2 = inst.lambda2x(xslit, yslit, lambdamax/order);
	output << conversionmode << " " << xslit << " " << yslit << " " << a/10. 
	       << " " << result1 << " " << dimx << " " << dimy << " " << result1 
	       << " " << result2 << " " << slittilt << " " << objid << " " << label << endl;
      }
    }
  }

  input.close();
}


// ***********************************************************
// Read the instrument wavelength calibration table
// ***********************************************************
void read_wavecal_table(instrument &inst)
{

  // The GMMPS installation directory
  const char *dpath = getenv("GMMPS");
  if (dpath == NULL) {
    cerr << "ERROR: Environment variable \"GMMPS\" not found!" << endl;
    exit (1);
  }
  string datapath = string(dpath)+"/gemwm/data/";

  // Open file with the coefficients for the wavelength solution
  string filename = datapath + inst.name + "_wavecal_coeffs.dat";
  const char *file = filename.c_str();
  ifstream input(file);

  // Leave if file could not be opened
  if (!input.is_open()) check_environmentvar();

  string disperser_tmp;
  int ind_i, ind_j;
  double a, b, c;

  string line;
  // Read the file and store coefficients if the dispersers match
  //  while (getline(input, line)) {
  //  istringstream iss(line);
  while(input >> disperser_tmp >> ind_i >> ind_j >> a >> b >> c) {
    if (inst.disperser.compare(disperser_tmp) == 0) {
      inst.coeff[ind_i][ind_j][0] = a;
      inst.coeff[ind_i][ind_j][1] = b;
      inst.coeff[ind_i][ind_j][2] = c;
    }
  }
  input.close();
}
