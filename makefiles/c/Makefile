CC=gcc
CCDEBUGFLAGS=-g
CCFLAGS=-W -Wall -Werror -Wconversion -Wsign-conversion -Wunused -Wunreachable-code -Wno-write-strings
COPTIMIZEFLAGS=-O3
LDFLAGS=
SOURCES=$(wildcard *.c)
OBJECTS=$(SOURCES:.c=.o)
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
	$(CC) $(CCFLAGS) $(CCDEBUGFLAGS) $(LDFLAGS) $(OBJECTS) -o $(EXECUTABLE)
	find . -regex ".*\.[cChH]\(pp\)?" -print | etags -
optimize: $(OBJECTS)
	$(CC) $(CCFLAGS) $(COPTIMIZEFLAGS) $(LDFLAGS) $(OBJECTS) -o $(EXECUTABLE)
clean:
	rm -f $(EXECUTABLE)
	rm -f $(OBJECTS)
	rm -f TAGS
