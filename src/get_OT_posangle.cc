#include <iostream>
#include <cstdlib>
#include <cmath>

using namespace std;

void usage(int i, char *argv[])
{
  if (i == 0) {
    cout << "USAGE: " << argv[0] << " -i INST (GMOS-N or GMOS-S or F2) -c cd11 cd12 cd21 cd22" << endl;
    cout << "       Gets the OT sky position angle from a CD matrix.\n" << endl;
    cout << "       WARNING: This is not a general purpose tool as the OT angle is special." << endl;
  }

  exit (0);
}

//*************************************************************

int main(int argc, char *argv[])
{
  long i;
  double pa = 0.;
  double cd11 = -1.;
  double cd12 = -1.;
  double cd21 = -1.;
  double cd22 = -1.;
  string inst = "";

  const double PI = 3.14159265;

  // print usage if no arguments were given
  if (argc==1) usage(0,argv);

  //  Read command line arguments
  for (i=1; i<argc; i++) {
    if (argv[i][0] == '-') {
      switch((int)argv[i][1]) {
      case 'c':
	cd11 = atof(argv[++i]);
	cd12 = atof(argv[++i]);
	cd21 = atof(argv[++i]);
	cd22 = atof(argv[++i]);
	break;
      case 'i': inst = argv[++i];
	break;
      }
    }
  }

  if (inst.compare("GMOS-N") != 0 && 
      inst.compare("GMOS-S") != 0 && 
      inst.compare("F2") != 0) {
    cerr <<  "ERROR: Instrument " << inst << " not supported!\n";
    exit (1);
  }

  if (cd11 == -1. || cd12 == -1. || cd21 == -1. || cd22 == -1. ) {
    cerr <<  "ERROR: Invalid CD matrix. All four CD elements must be specified.\n";
    exit (1);
  }

  double cd11_orig = cd11;
  double cd12_orig = cd12;
  double cd21_orig = cd21;
  double cd22_orig = cd22;

  // the pixel scale
  double pscale1 = sqrt(cd11 * cd11 + cd21 * cd21);
  double pscale2 = sqrt(cd12 * cd12 + cd22 * cd22);

  // take out the pixel scale
  cd11 /= pscale1;
  cd12 /= pscale2;
  cd21 /= pscale1;
  cd22 /= pscale2;

  // sqrt(CD elements) is very close to one, but not perfectly
  // as coordinate system is not necessarily orthogonal (shear + contraction)
  double nfac1 = sqrt(cd11 * cd11 + cd21 * cd21);
  double nfac2 = sqrt(cd12 * cd12 + cd22 * cd22);

  // make sure sqrt(CD elements) = 1, 
  // so that we can do the inverse trig functions
  cd11 /= nfac1;
  cd21 /= nfac1;
  cd12 /= nfac2;
  cd22 /= nfac2;

  // Is the image flipped or not?
  bool flipped = false;
  if (inst.compare("GMOS-N") == 0 || 
      inst.compare("GMOS-S") == 0) {
    flipped = true;
  }

  if (inst.compare("F2") == 0) {
    flipped = false;
  }


  //************************************
  // The flipped case: GMOS-N and GMOS-S
  //************************************

  if (flipped) {

    // Here we are well within the quadrants, i.e. significantly off 0, 90, 180 and 270 degrees
    if      (cd11 > 0 && cd12 > 0 && cd21 < 0 && cd22 > 0) pa =    PI + acos(cd11);   //  180 < phi < 270
    else if (cd11 < 0 && cd12 > 0 && cd21 < 0 && cd22 < 0) pa = 2.*PI - acos(-cd11);  //  270 < phi < 360
    else if (cd11 < 0 && cd12 < 0 && cd21 > 0 && cd22 < 0) pa =         acos(-cd11);  //    0 < phi <  90
    else if (cd11 > 0 && cd12 < 0 && cd21 > 0 && cd22 > 0) pa =    PI - acos(cd11);   //   90 < phi < 180
    else {
      // we are very likely close to 0, 90, 180 or 270 degrees, and we allow for a slighty non-orthogonal CD matrix.
      // In this case, lock onto 0, 90, 180 or 270 degrees. Otherwise, exit with an error.
      double cd11cd12;
      double cd22cd21;
      if (cd12 != 0.) cd11cd12 = fabs(cd11/cd12);
      else cd11cd12 = 100;
      if (cd21 != 0.) cd22cd21 = fabs(cd22/cd21);
      else cd22cd21 = 100;
      
      // CD11 and CD22 close or equal to zero and CD12 CD21 very different from zero
      if (cd11cd12 < 0.05 && cd22cd21 < 0.05) {
	if (cd11 <= 0. && cd12 < 0. && cd21 > 0. && cd22 >= 0.) pa = 0.5*PI;
	if (cd11 >= 0. && cd12 < 0. && cd21 > 0. && cd22 <= 0.) pa = 0.5*PI;
	if (cd11 <= 0. && cd12 > 0. && cd21 < 0. && cd22 >= 0.) pa = 1.5*PI;
	if (cd11 >= 0. && cd12 > 0. && cd21 < 0. && cd22 <= 0.) pa = 1.5*PI;
      }
      // CD12 and CD21 close or equal to zero and CD11 CD22 very different from zero
      else if (cd11cd12 > 20. && cd22cd21 > 20.) {
	if (cd11 < 0. && cd12 >= 0. && cd21 >= 0. && cd22 < 0.) pa = 0.;
	if (cd11 < 0. && cd12 <= 0. && cd21 <= 0. && cd22 < 0.) pa = 0.;
	if (cd11 > 0. && cd12 >= 0. && cd21 >= 0. && cd22 > 0.) pa = PI;
	if (cd11 > 0. && cd12 <= 0. && cd21 <= 0. && cd22 > 0.) pa = PI;
      }
      else {
	cerr << "ERROR: Could not determine position angle from CD matrix!" << endl;
	cerr << "       Invalid matrix elements? Check your WCS..." << endl;
	cerr << "   CD1_1 = " << cd11_orig << endl;
	cerr << "   CD1_2 = " << cd12_orig << endl;
	cerr << "   CD2_1 = " << cd21_orig << endl;
	cerr << "   CD2_2 = " << cd22_orig << endl;
	cerr << "   DET   = " << cd11*cd22-cd12*cd21 << endl;
	exit (1);
      }
    }
    cout << pa*180./PI << endl;
  }


  //************************************
  // The unflipped case: F2
  //************************************

  if (!flipped) {
    if      (cd11 <  0 && cd12 <= 0 && cd21 <= 0 && cd22 >  0) pa = acos(-cd11);       //   0 <= phi <  90
    else if (cd11 >= 0 && cd12 <  0 && cd21 <  0 && cd22 <= 0) pa = acos(-cd11);       //  90 <= phi < 180
    else if (cd11 >  0 && cd12 >= 0 && cd21 >= 0 && cd22 <  0) pa = 2.*PI-acos(-cd11); // 180 <= phi < 270
    else if (cd11 <= 0 && cd12 >  0 && cd21 >  0 && cd22 >= 0) pa = 2.*PI-acos(-cd11); // 270 <= phi < 360
    else {
      // we are very likely close to 0, 90, 180 or 270 degrees, and the CD matrix is slightly non-orthogonal.
      // In this case, lock onto 0, 90, 180 or 270 degrees. Otherwise, exit with an error.
      double cd11cd12 = fabs(cd11/cd12);
      double cd22cd21 = fabs(cd22/cd21);
      
      if (cd11cd12 > 20. && cd22cd21 > 20.) {
	if (cd11 > 0. && cd22 > 0.) pa = 0.*PI/2.;
	if (cd11 < 0. && cd22 > 0.) pa = 0.*PI/2.;
	if (cd11 > 0. && cd22 < 0.) pa = 2.*PI/2.;
	if (cd11 < 0. && cd22 < 0.) pa = 2.*PI/2.;
      }    
      
      else if (cd11cd12 < 0.05 && cd22cd21 < 0.05) {
	if (cd12 > 0. && cd21 < 0.) pa = 1.*PI/2.;
	if (cd12 < 0. && cd21 < 0.) pa = 1.*PI/2.;
	if (cd12 > 0. && cd21 > 0.) pa = 3.*PI/2.;
	if (cd12 < 0. && cd21 > 0.) pa = 3.*PI/2.;
      }
      
      else {
	cerr << "ERROR: Could not determine position angle from CD matrix!\n";
	exit (1);
      }
    } 
    // Translate true sky position angle to OT position angle:
    //    double ot_pa = 270. - pa*180./PI;
    double ot_pa = pa*180./PI + 90.;
    if (ot_pa < 0) ot_pa += 360;
    cout << ot_pa << endl;
  }

  return 0;
}
