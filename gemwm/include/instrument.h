#ifndef __INSTRUMENT_H
#define __INSTRUMENT_H

#include <stdlib.h>

using namespace std;

//************************************************************************
//************************************************************************
class instrument {

 private:
  // nothing yet

 public:
  string name;
  string mode;
  string dispDir;
  string disperser;
  string pixelscale;
  double cwl;
  double coeff[4][6][3];  // This will hold the wavecal coefficients
                          // Not all slots in this array will be filled;

  // constructor
  instrument (string instname, string instdisperser, string instmode="", 
	      double instcwl=0.0) {
    name = instname;
    disperser = instdisperser;
    mode = instmode;
    cwl = instcwl;
  }
  
  // destructor;
  ~instrument() {}
  
  void check_instconfig();
  void check_param(const string, const vector<string>);
  void calc_wavecal_coeffs(const double, const double, vector<double> &,
			   const string="");

  double x2lambda(const double, const double, const double);
  double lambda2x(const double, const double, const double,
		  const string="");
};

#endif
