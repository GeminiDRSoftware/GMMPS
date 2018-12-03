#include <iostream>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <cmath>
#include <string>
#include <cstring>
#include <vector>

using namespace std;

void readData(string, vector<double>&, vector<double>&);
void stringclean(string &str);
double interpolate(const vector<double>&, const vector<double>&, const double);
string NumberToString(float);
double min(const vector<double> &);
double max(const vector<double> &);

int main (int argc, char *argv[]) {

  string filterfile = "";
  string gratingfile = "";
  string detectorfile = "";
  string atmospherefile = "";
  string orderfilterfile = "";
  string plottitle = "";
  string mode = "";
  double cutoff = 0.01;

  // COMMAND LINE INPUT 
  if(argc==9) {
    filterfile = argv[1];
    gratingfile = argv[2];
    detectorfile = argv[3];
    atmospherefile = argv[4];
    orderfilterfile = argv[5];
    plottitle = argv[6];
    cutoff = atof(argv[7]);
    mode = argv[8];
  }
  else {
    cout << "calc_throughput: WRONG INPUT COMMAND LINE: EXIT" << endl;
    cout << "USAGE: calc_throughput <Filter> <Grating> <Instrument> <Atmosphere> "<< endl;
    cout << "            <Order sorting filter; \"empty\" if none!> <plot title> "<< endl;
    cout << "            <minimum relative total throughput> <mode: OT or ODF>" << endl;
    return -1;
  }
  
  // The names of the files with the transmission data
  vector<double> lambda_f, lambda_g, lambda_d, lambda_a, lambda_o;
  vector<double> throughput_f, throughput_g, throughput_d, throughput_a, throughput_o;

  // Read the input files
  readData(filterfile, lambda_f, throughput_f);
  readData(gratingfile, lambda_g, throughput_g);
  readData(detectorfile, lambda_d, throughput_d);
  readData(atmospherefile, lambda_a, throughput_a);
  readData(orderfilterfile, lambda_o, throughput_o);

  vector<double> lambda_tot, throughput_tot;

  // Initialise the output wavelength vector, 
  // and fill the transmission with zeroes
  double l;
  for (l=300; l<=2500; l=l+0.1) {
    lambda_tot.push_back(l);
    throughput_tot.push_back(0.0);
  }

  // Linearly interpolate the filter, grating and detector throughput at 
  // each wavelength. If the wavelength is not covered by all data, then 
  // the total throughput remains zero.
  unsigned long i = 0;
  double value_filter      = 0.0;
  double value_grating     = 0.0;
  double value_detector    = 0.0;
  double value_atmosphere  = 0.0;
  double value_orderfilter = 0.0;

  for (l=300; l<=2500; l=l+0.1) {
    value_filter = interpolate(lambda_f, throughput_f, l);
    value_grating = interpolate(lambda_g, throughput_g, l);
    value_detector = interpolate(lambda_d, throughput_d, l);
    value_atmosphere = interpolate(lambda_a, throughput_a, l);
    value_orderfilter = interpolate(lambda_o, throughput_o, l);
    throughput_tot[i++] = value_filter * value_grating * value_detector * value_atmosphere * value_orderfilter;
  }

  // Find the peak throughput
  double throughput_max=0.0;
  for (i=0; i<lambda_tot.size(); i++) {
    if (throughput_tot[i] > throughput_max) {
      throughput_max = throughput_tot[i];
    }
  }

  // Find the lower cutoff wavelength
  double lambda_cutoff_min = 0.0;
  for (i=0; i<lambda_tot.size(); i++) {
    if (throughput_tot[i] >= cutoff * throughput_max) {
      lambda_cutoff_min = lambda_tot[i];
      break;
    }
  }

  // Find the upper cutoff wavelength
  double lambda_cutoff_max = 0.0;
  long j;
  for (j=lambda_tot.size(); j>=0; j--) {
    if (throughput_tot[j] >= cutoff * throughput_max) {
      lambda_cutoff_max = lambda_tot[j];
      break;
    }
  }

  double cwl_guess = (lambda_cutoff_min + lambda_cutoff_max) / 2.;

  // Print the result to the command line
  cout << lambda_cutoff_min << " " << lambda_cutoff_max << " " << cwl_guess << endl;

  // The rest is only needed when creating masks from the OT catalog

  if (mode.compare("OT") == 0) {
    // dump the resulting throughput curve to an output file
    ofstream outfile(".total_system_throughput.dat");
    if (!outfile.is_open()) {
      cerr << "ERROR: calc_throughput: Could not open output file!" << endl;
      exit (1);
    }
    
    cout.precision(4);
    for (i=0; i<lambda_tot.size(); i++) {
      outfile << lambda_tot[i] << " " << throughput_tot[i] << endl;
    }
    
    outfile.close();
    
    // Create the python checkplot - commented out 2018-11-30 bmiller
//     string command = "gmmps_throughput.py ";
//     string lmin = NumberToString(lambda_cutoff_min);
//     string lmax = NumberToString(lambda_cutoff_max);
//     
//     command = command+" "+lmin+" "+lmax+" "+plottitle;
//     
//     if ( system(command.c_str()) == -1) {
//       cerr << "WARNING: Could not create the throughput plot!" << endl;
//     }
  }

  return 0;
}


// ************************************************************************
// Read in throughput data from a file
// ************************************************************************
void readData(string filename, vector<double>&column1, vector<double>&column2) {

  ifstream file;
  string line;
  vector<string> values;
  double tmp1, tmp2;

  const char *filename_cstr = filename.c_str();

  if (filename.compare("empty") != 0) {
    file.open(filename_cstr);
    if (!file.is_open()) {
      cout << "ERROR: Could not open " << filename << endl; 
      exit (1);
    }
    else {
      while (getline(file, line)) {
	stringclean(line);
	istringstream iss(line);
	iss >> tmp1 >> tmp2;
	column1.push_back(tmp1);
	column2.push_back(tmp2);
      }
    }
    file.close();
  }

  // No order sorting filter: Nonetheless, initialise the data sparsely
  else {
    long i;
    for (i=300; i<=2500; i=i+100) {
      column1.push_back(double(i));
      column2.push_back(1.0);
    }
  }
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


//***********************************************************
// Interpolate the throughput data
//***********************************************************
double interpolate(const vector<double> &lambda, const vector<double> &throughput, const double lambda_eval)
{
  unsigned long i=0;
  double result = 0.0;

  for (i=0; i<lambda.size()-1; i++) {
    if (lambda_eval >= lambda[i] && lambda_eval < lambda[i+1]) {
      result = throughput[i] + (throughput[i+1] - throughput[i]) * 
	(lambda_eval - lambda[i]) / (lambda[i+1] - lambda[i]);
      break;
    }
  }

  return result;   // will be zero if wavelength is outside data range
}

//*********************************
// Number to string conversion
//*********************************
string NumberToString ( float Number )
{
  ostringstream ss;
  ss << Number;
  return ss.str();
}


//********************
// Minimum of a vector
//********************
double min(const vector<double> &data)
{
  unsigned long i;
  double minval = data[0];
  
  for (i=0; i<data.size(); i++) {
    if (data[i] < minval) minval = data[i];
  }
  
  return (minval);
}


//********************
// Maximum of a vector
//********************
double max(const vector<double> &data)
{
  unsigned long i;
  double maxval = data[0];
  
  for (i=0; i<data.size(); i++) {
    if (data[i] > maxval) maxval = data[i];
  }
  
  return (maxval);
}

