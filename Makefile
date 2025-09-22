# Makefile for gghash/alignmentFree
#
CXX ?= g++
NIMC ?= nim
AR ?= ar
CFLAGS = -Wall -O3 -fPIC
NTHASH_LIB = lib/libnthash.a
NTHASH_SRC = external/nthash/src
NTHASH_INC = -Iexternal/nthash/include
_NTHASH_OBJ = seed.o kmer.o
NTHASH_OBJ = $(patsubst %, $(NTHASH_SRC)/%, $(_NTHASH_OBJ))

PTHASH_INC = -Iexternal/pthash/include \
			 -Iexternal/pthash/external/bits/include \
			 -Iexternal/pthash/external/bits/external/essentials/include \
			 -Iexternal/pthash/external/mm_file/include \
			 -Iexternal/pthash/external/xxHash
LIBD = -Llib
LIBF = -lnthash
SRC = src
NIMB = nimPtHash

all: $(NIMB)

$(NIMB) : $(SRC)/nimPtHash.nim $(NTHASH_LIB) 
	$(NIMC) cpp -d:release --passC:"$(PTHASH_INC) $(NTHASH_INC) -Iinclude" --passL:"$(LIBD) $(LIBF)" $<

$(NTHASH_SRC)/%.o  : $(NTHASH_SRC)/%.cpp
	$(CXX) -c $(NTHASH_INC) -o $@ $< $(CFLAGS)

$(NTHASH_LIB) : $(NTHASH_OBJ)
	$(AR) -rvs $(NTHASH_LIB) $^

.PHONY: clean

clean:
	rm -f $(NTHASH_OBJ)
	rm -f $(NTHASH_LIB)
	rm -f $(SRC)/nimPtHash
