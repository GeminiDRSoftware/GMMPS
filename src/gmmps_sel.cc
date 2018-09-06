// Copyright (C) 2014 Association of Universities for Research in Astronomy, Inc.
// Contact: mschirme@gemini.edu
//  
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software 
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

/*
 * E.S.O. - VLT project 
#
# "@(#) $Id: gmmps_sel.cc,v 1.2 2011/04/25 18:27:33 gmmps Exp $" 
 * $Id: gmmps_sel.cc,v 1.2 2011/04/25 18:27:33 gmmps Exp $
 *
 * main.C - C++ main for gmmps_sel.c
 * 
 * who             when       what
 * --------------  --------   ----------------------------------------
 * D.Bottini  01 Apr 00  Created
 */
/*
 *  Finally figured out why this is a shell C++ calling a c-program,
 *  some of the library functions (acOpen, acCircularSearch, etc) are
 *  only available in the C++ library, so someone decided they could have
 *  access to these functions by using this C++ file.  Well its just amazing
 *  that it works.  Should re-write.... when I feel like fixing something
 *  that works (and we all know how well that goes).
 */

extern "C" int gmmps_sel(int argc, char** argv);
int main(int argc, char** argv)
{
  gmmps_sel(argc, argv);
  return 0;
}
