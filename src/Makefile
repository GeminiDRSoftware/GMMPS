# user library
USER_LIB = $(shell ./skycatlib.sh)

# Forcing the shell // do we need that? (mischa)
SHELL = /bin/sh 

# machine-specific stuff
platform = 
os = $(shell uname -s)
libvers = $(shell ./discoverOS.sh)

ifeq ($(os),Linux)
  platform = $(os)
else
ifeq ($(os),Darwin)
  platform = $(os)
endif
endif

# Exit if platform is not Darwin or Linux
ifndef platform
  $(error Unsupported platform "$(platform)". Must be Linux or Darwin)
endif

# Include and library dirs
INCLUDE_DIRS := ../include ../gemwm/include/
LIBRARY_DIRS := ../lib
# uncomment if needed
#INCLUDE_DIRS += /usr/include/ /usr/local/include/
#LIBRARY_DIRS += /usr/lib /usr/local/lib
ifeq ($(os),Darwin)
  LIBRARY_DIRS += $(USER_LIB)
endif
LIBRARIES    := m

# For Darwin / uncomment if needed
ifeq ($(os),Darwin)
#  CC=gcc
#  CXX=g++
#  INCLUDE_DIRS += /usr/X11R6/include/X11
#  INCLUDE_DIRS += /usr/X11R6/include
#  INCLUDE_DIRS += /opt/include/X11/
#  INCLUDE_DIRS += /opt/X11/include
#  LIBRARY_DIRS += /usr/X11R6/lib
#  LIBRARY_DIRS += /opt/X11/
endif

# add the include and library (dirs) to the makefile variables

# common C and C++ preprocessor directives, specific C and C++ compiler flags
WARNINGS = -Wall -Wextra -pedantic -Wundef -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align
CPPFLAGS += $(foreach includedir,$(INCLUDE_DIRS),-I$(includedir))
CFLAGS   += -std=c99 -fPIC -g -O $(WARNINGS)
CXXFLAGS += -fPIC -g -O $(WARNINGS)

LDFLAGS  += $(foreach librarydir,$(LIBRARY_DIRS),-L$(librarydir))
LDFLAGS  += $(foreach library,$(LIBRARIES),-l$(library))

# For Darwin
ifeq ($(os),Darwin)
  # CFLAGS := -iquote -I. $(CFLAGS)
  CPPFLAGS := -iquote -I. $(CPPFLAGS)
  # and for MacOs 10.9 or newer, which default to libc++, we need to do this
  NEWFLAG = $(shell sw_vers -productVersion | awk 'BEGIN{FS="."} {if ($$1$$2>=109) print "yes"; else print "no"}')
  ifeq ($(NEWFLAG),yes)
    CXXFLAGS := -stdlib=libstdc++ $(CXXFLAGS)
    LDFLAGS  := -stdlib=libstdc++ $(LDFLAGS)
  endif
endif


#################################################
# set standard targets.                         #
#################################################
default : all

# force each standard target name to be an independent target
# (i.e., it will not be affected by an actual file with the same name)
.PHONY : all
.PHONY : clean

# C programs (public and local) (gmmps_sel is handled extra at the bottom)
# These require the cfitsio library which we link statically
CSOURCES   = gmCat2Fits.c gmFits2Cat.c
COBJECTS   = $(CSOURCES:.c=.o)
CEXEC      = $(CSOURCES:.c=)

CPPSOURCES = gmmps_fov.cc gmMakeMasks.cc get_OT_posangle.cc calc_throughput.cc
CPPOBJECTS = $(CPPSOURCES:.cc=.o)
CPPEXEC    = $(CPPSOURCES:.cc=)

vpath %.h ../gemwm/include
HEADERS=gemwm.h instrument.h
CPPSOURCES_GEMWM = ../gemwm/instrument.cc ../gemwm/gemwm.cc 
CPPOBJECTS_GEMWM = $(CPPSOURCES_GEMWM:.cc=.o)
NOEXEC     = ../gemwm/instrument
TMP        = $(CPPSOURCES_GEMWM:.cc=)
CPPEXEC_GEMWM = gemwm

# where the outpout goes
BIN=../bin/


# TARGETS
all : $(CEXEC) $(CPPEXEC) $(CPPEXEC_GEMWM) gmmps_sel throughput

$(CEXEC): $(COBJECTS)
	$(CC) -o $(BIN)/$@ $@.o ../lib/libcfitsio.a $(LDFLAGS) -lcfitsio

$(CPPEXEC): $(CPPOBJECTS)
	$(CXX) -o $(BIN)/$@ $@.o $(LDFLAGS)

$(CPPEXEC_GEMWM): $(CPPOBJECTS_GEMWM) $(HEADERS)
	$(CXX) -o $(BIN)/$@ $(CPPOBJECTS_GEMWM) $(LDFLAGS) $(CXXFLAGS)

# gmmps_sel.c is automatically picked over gmmps_sel.cc.
# It appears that only the -lcat4.1.0 linker flag is necessary; keep the others just in case
gmmps_sel: gmmps_sel.o
#	$(CXX) $(LDFLAGS) gmmps_sel.cc gmmps_sel.o -o $(BIN)/gmmps_sel -lcat4.1.0 -lastrotcl2.1.0 -ltclutil2.1.0 -lBLT24 -ltcl8.4 -ltk8.4
	$(CXX) $(LDFLAGS) gmmps_sel.cc gmmps_sel.o -o $(BIN)/gmmps_sel -lcat4.1.0

throughput:
	cp $(shell pwd)/gmmps_throughput.py ../bin/
	cp $(shell pwd)/create_gemwm_input.sh ../bin/
	cp $(shell pwd)/get_propermotion.sh ../bin/
	cp $(shell pwd)/vizquery ../bin/
	rm -f *.o

clean : 
	rm -f ../bin/gm* ../bin/get_posangle ../bin/calc_throughput ../bin/gemwm *.o ../gemwm/*.o
