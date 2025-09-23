# Makefile for gghash/alignmentFree
#
CXX ?= g++
CC ?= gcc
NIMC ?= nim
AR ?= ar
CFLAGS = -Wall -O3 -fPIC -g -march=native
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

WFA_INC = -Iexternal/WFA2
WFA_SRC = external/WFA2/wavefront
WFA_CPP_SRC = external/WFA2/bindings/cpp
WFA_LIB = lib/libwfa.a
WFA_CPP_LIB = lib/libwfacpp.a
_WFA_OBJ =wavefront.o \
		  wavefront_align.o \
		  wavefront_aligner.o \
		  wavefront_attributes.o \
		  wavefront_backtrace.o \
		  wavefront_backtrace_buffer.o \
		  wavefront_backtrace_offload.o \
		  wavefront_bialign.o \
		  wavefront_bialigner.o \
		  wavefront_components.o \
		  wavefront_compute.o \
		  wavefront_compute_affine.o \
		  wavefront_compute_affine2p.o \
		  wavefront_compute_edit.o \
		  wavefront_compute_linear.o \
		  wavefront_debug.o \
		  wavefront_display.o \
		  wavefront_extend.o \
		  wavefront_extend_kernels.o \
		  wavefront_extend_kernels_avx.o \
		  wavefront_heuristic.o \
		  wavefront_pcigar.o \
		  wavefront_penalties.o \
		  wavefront_plot.o \
		  wavefront_sequences.o \
		  wavefront_slab.o \
		  wavefront_termination.o \
		  wavefront_unialign.o
_WFA_CPP_OBJ = WFAligner.o
WFA_OBJ = $(patsubst %, $(WFA_SRC)/%, $(_WFA_OBJ))
WFA_CPP_OBJ  = $(patsubst %, $(WFA_CPP_SRC)/%, $(_WFA_CPP_OBJ))
all: $(NIMB) $(WFA_LIB)

$(NIMB) : $(SRC)/nimPtHash.nim $(NTHASH_LIB) 
	$(NIMC) cpp -d:release --passC:"$(PTHASH_INC) $(NTHASH_INC) -Iinclude" --passL:"$(LIBD) $(LIBF)" $<

$(NTHASH_SRC)/%.o  : $(NTHASH_SRC)/%.cpp
	$(CXX) -c $(NTHASH_INC) -o $@ $< $(CFLAGS)

$(NTHASH_LIB) : $(NTHASH_OBJ)
	$(AR) -rvs $@ $^

$(WFA_SRC)/%.o : $(WFA_SRC)/%.c
	$(CC) -c $(WFA_INC) -o $@ $< $(CFLAGS)

$(WFA_CPP_SRC)/%.o : $(WFA_CPP_SRC)/%.cpp
	$(CXX) -c -I$(WFA_INC) -I$(WFA_CPP_SRC) -o $@ $< $(CFLAGS)

$(WFA_LIB) : $(WFA_OBJ) $(WFA_CPP_OBJ)
	$(AR) -rvs $@ $^

.PHONY: clean

clean:
	rm -f $(NTHASH_OBJ)
	rm -f $(NTHASH_LIB)
	rm -f $(SRC)/nimPtHash
	rm -f $(WFA_SRC)/*.o
	rm -f $(WFA_LIB)
