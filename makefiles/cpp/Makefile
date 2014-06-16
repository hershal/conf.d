CXX=g++
CXXDEBUGFLAGS=-g
CXXFLAGS=
CXXOPTIMIZEFLAGS=-O3
LDFLAGS=
SOURCES=$(wildcard *.cpp)
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=binary

UNAME=$(shell uname)
ifeq ($(UNAME),GNU/Linux)
ETAGS_ARGS=-
endif
ifeq ($(UNAME),Cygwin)
ETAGS_ARGS=-e -L -
endif

all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) 
	$(CXX) $(CXXDEBUGFLAGS) $(LDFLAGS) $(OBJECTS) -o $(EXECUTABLE)
	find . -regex ".*\.[cChH]\(pp\)?" -print | etags -
optimize: $(OBJECTS)
	$(CXX) $(CXXOPTIMIZEFLAGS) $(LDFLAGS) $(OBJECTS) -o $(EXECUTABLE)
clean: 
	rm -f $(EXECUTABLE)
	rm -f $(OBJECTS)
	rm -f TAGS
