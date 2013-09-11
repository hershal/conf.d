CXX=gccrec g++-code-assist
CXXFLAGS=-g -O0
# -Wno-write-strings
LDFLAGS=
SOURCES=$(wildcard *.cpp) $(wildcard *.c)
OBJECTS=$(SOURCES:.cpp=.o)
EXECUTABLE=binary

UNAME=$(shell uname -o)
ETAGS_ARGS=
ifeq ($(UNAME),GNU/Linux)
ETAGS_ARGS=-
endif
ifeq ($(UNAME),Cygwin)
ETAGS_ARGS=-e -L -
endif

all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS) 
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(OBJECTS) -o $@
	find . -regex ".*\.[cChH]\(pp\)?" -print | etags -
clean: 
	rm $(EXECUTABLE)
	rm $(OBJECTS)
	rm TAGS
