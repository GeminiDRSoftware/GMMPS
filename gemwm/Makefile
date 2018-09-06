# machine-specific stuff
platform = 
os = $(shell uname -s)
libvers = $(shell ./discoverOS.sh)

# Include and library dirs
INCLUDE_DIRS := include/ /usr/include/ /usr/local/include/
#LIBRARY_DIRS := ../lib /usr/lib /usr/local/lib
LIBRARY_DIRS := ../lib
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

# common C and C++ preprocessor directives, specific C and C++ compiler flags
WARNINGS = -Wall -Wextra -pedantic -Wundef -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align
CPPFLAGS += $(foreach includedir,$(INCLUDE_DIRS),-I$(includedir))
CFLAGS   += -std=c99 -fPIC -g -O3 $(WARNINGS)
CXXFLAGS += -fPIC -g -O3 $(WARNINGS)

LDFLAGS  += $(foreach librarydir,$(LIBRARY_DIRS),-L$(librarydir))
LDFLAGS  += $(foreach library,$(LIBRARIES),-l$(library))

# For Darwin
ifeq ($(os),Darwin)
  CPPFLAGS := -iquote -I. $(CPPFLAGS)
  # and for MacOs 10.9 or newer, which default to libc++, we need to do this
  NEWFLAG = $(shell sw_vers -productVersion | awk 'BEGIN{FS="."} {if ($$1$$2>=109) print "yes"; else print "no"}')
  ifeq ($(NEWFLAG),yes)
    CXXFLAGS := -stdlib=libstdc++ $(CXXFLAGS)
    LDFLAGS  := -stdlib=libstdc++ $(LDFLAGS)
  endif
endif


# where the outpout goes
BIN=../bin/
vpath %.h include
HEADERS=gemwm.h instrument.h
SOURCES=$(wildcard *.cc)
OBJECTS=$(SOURCES:.cc=.o)
EXEC=gemwm

# TARGETS
all : $(EXEC)

$(EXEC): $(OBJECTS) $(HEADERS)
	$(CXX) -o $(BIN)/$@ $(OBJECTS) $(LDFLAGS) $(CXXFLAGS)

.PHONY : all clean

clean :
	rm -f ..bin/gemwm *.o
