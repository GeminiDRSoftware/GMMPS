#include <cstdlib>
#include <iostream>
#include <cmath>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>

#include "instrument.h"
#include "gemwm.h"

using namespace std;

// *************************************************
// Check the user-defined parameters for consistency
// *************************************************
void instrument::check_instconfig()
{
  vector<string> valid_inst, valid_disperser, valid_mode;
  valid_inst.push_back("GMOS-N");
  valid_inst.push_back("GMOS-S");
  valid_inst.push_back("F2");

  // Check instrument name
  check_param(name, valid_inst);

  // Check instrument setup
  if (name.compare("GMOS-N") == 0 || name.compare("GMOS-S") == 0) {
    valid_disperser.push_back("R150");
    valid_disperser.push_back("R400");
    valid_disperser.push_back("R831");
    valid_disperser.push_back("R831_2nd");
    valid_disperser.push_back("B600");
    valid_disperser.push_back("B1200");

    valid_mode.push_back("MOS");
    // valid_mode.push_back("LSS");
    // valid_mode.push_back("IFUR");
    // valid_mode.push_back("IFU2");

    check_param(disperser, valid_disperser);
    check_param(mode, valid_mode);

    if (cwl < 350. || cwl > 1050) {
      cerr << "ERROR: Central wavelength out side valid range [350-1050nm]" << endl;
      exit (1);
    }
  }

  // Check instrument setup
  if (name.compare("F2") == 0) {
    valid_disperser.push_back("R1200_JH");
    valid_disperser.push_back("R1200_HK");
    valid_disperser.push_back("R3000_Y");
    valid_disperser.push_back("R3000_J");
    valid_disperser.push_back("R3000_H");
    valid_disperser.push_back("R3000_K");

    valid_mode.push_back("MOS");

    check_param(disperser, valid_disperser);
    check_param(mode, valid_mode);
  }
}


// *************************************************
// Check the user-defined parameters for consistency
// *************************************************
void instrument::check_param(const string param, 
			     const vector<string> valid_setup)
{
  size_t i;
  bool pass = false;
  for (i=0; i<valid_setup.size(); i++) {
    if (param.compare(valid_setup[i]) == 0) {
      pass = true;
      break;
    }
  }

  // Check instrument type
  if (!pass) {
    cerr << "ERROR: Unsupported configuration: " << name << endl;
    cerr << "       Must be one of: " << endl;
    for (i=0; i<valid_setup.size(); i++) {
      cerr << "       " << valid_setup[i] << endl;
    }
    exit (1);
  }
}

// ************************************************************************
// Calculate the wavelength calibration coefficients
// ************************************************************************
void instrument::calc_wavecal_coeffs(const double xslit, const double yslit, 
				     vector<double> &wcc, const string linearmode)
{
  /* 
     The wavelength is parametrised as a cubic function,
     lambda = sum (ci * x^i), i=0...3
     The absolute value of c1 is the dispersion.
     The ci themselves are functions of 4 parameters: The slit x and y position, 
     CWL and grating (number of rulings).
     There is one model for each disperser.
     For F2 everything is static; to maintain a homogeneous code the more variable 
     GMOS implementation was adopted
  */

  // If linearmode == "linear", then only the coefficients for a linear
  // model are considered
  
  // MODEL UNITS: Wavelength in Angstrom, 1x1 binning

  int i, j, k;
  double p[6] = {0., 0., 0., 0., 0., 0.};

  // lambda   = sum( wcc[i] * pow(xpos,i) )                                // cubic
  // wcc[0-1] = sum( p[i] * pow(xslit, i) ) + sum( p[j] * pow(yslit, j))   // cubic in x, quadratic in y
  // wcc[2-3] = sum( p[i] * pow(xslit, i) )                                // cubic
  // p[0-2]   = sum( coeff[][][i]*pow(cwl,i) );                            // quadratic

  // wcc = wavelength calibration coefficients

  // wcc[0-1]
  for (k=0; k<=1; k++) {
    for (j=0; j<=5; j++) {
      p[j] = 0.;
      if (linearmode.compare("linear") == 0) {
	for (i=0; i<=1; i++) {
	  p[j] += coeff[k][j][i]*pow(cwl,i);
	}
      } else {
	for (i=0; i<=2; i++) {
	  p[j] += coeff[k][j][i]*pow(cwl,i);
	}
      }
    }
    // Overwrite calculations if in linear mode
    if (linearmode.compare("linear") == 0) {
      p[2] = 0.;
      p[3] = 0.;
      p[5] = 0.;
    }
    wcc.push_back(p[0] + p[1]*xslit + p[2]*pow(xslit,2) + p[3]*pow(xslit,3)
		  + p[4]*yslit + p[5]*pow(yslit,2));
  }
  
  // cout << "pi: " << p[0] << " " << p[1] << " " << p[2] << " " << p[3] << " " << p[4] << endl;
  // cout << "c0: " << wcc[0] << endl;

  // wcc[2-3]
  for (k=2; k<=3; k++) {
    for (j=0; j<=3; j++) {
      p[j] = 0.;
      if (linearmode.compare("linear") == 0) {
	for (i=0; i<=1; i++) {
	  p[j] += coeff[k][j][i]*pow(cwl,i);
	}
      } else {
	for (i=0; i<=2; i++) {
	  p[j] += coeff[k][j][i]*pow(cwl,i);
	}
      }
    }
    // Overwrite calculations if in linear mode
    if (linearmode.compare("linear") == 0) {
      p[2] = 0.;
      p[3] = 0.;
    }
    wcc.push_back(p[0] + p[1]*xslit + p[2]*xslit*xslit + p[3]*pow(xslit,3) );
  }
  //  cout << wcc[0] << " " << wcc[1] << " " << wcc[2] << " " << wcc[3] << endl; 
}


// ************************************************************************
// Calculate the position of a certain wavelength along the dispersion axis
// ************************************************************************
double instrument::x2lambda(const double xslit, const double yslit, 
			    const double xpos)
{
  double lambda = 0.0;
  vector<double> wcc;
  calc_wavecal_coeffs(xslit, yslit, wcc);

  for (size_t k=0; k<wcc.size(); k++) {
    lambda += wcc[k]*pow(xpos,static_cast<int>(k));
  }
  return lambda;
}


// *********************************************************************
// Calculate the wavelength at a certain position on the dispersion axis
// *********************************************************************
double instrument::lambda2x(const double xslit, const double yslit, 
			    const double lambda, const string linearmode)
{
  vector<double> wcc;
  calc_wavecal_coeffs(xslit, yslit, wcc, linearmode);

  cout.precision(12);

  // Invert the wavelength calibration (cubic equation) using Newton's method.
  // The polynomial is in general very well behaved over the range of interest,
  // i.e. it is close to linear and monotonic.
  // The iteration terminates when the last step is less than 0.1 pixel, or if 
  // more than 15 steps were done (usually, it converges after 3-5 steps)

  double x0 = (lambda - wcc[0]) / wcc[1]; // use linear solution as starting value
  // cout << lambda << " " <<  wcc[0] << " " << wcc[1] << endl;
  double eps = 1000;
  double convergence = 0.1;
  int iter = 0;
  double x1;
  while (eps > convergence && iter <= 15) {
    double f0  = wcc[0] + wcc[1]*x0 + wcc[2]*pow(x0,2) + wcc[3]*pow(x0,3) - lambda;
    double df0 = wcc[1] + 2.*wcc[2]*x0 + 3.*wcc[3]*pow(x0,2);
    x1  =  x0 - f0 / df0;
    // Reset the iterators
    eps = fabs(x1 - x0);
    x0 = x1;
    iter++;
  }
  if (iter >= 15) {
    double x_linear = (lambda - wcc[0]) / wcc[1];
    //    cerr << "Inversion of the nonlinear wavelength model did not converge for " << lambda << "Angstrom. Using the linear position instead." << endl;
    return x_linear;
  }
  
  return x1;
}
