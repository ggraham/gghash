# Makefile for gghash/alignmentFree
#
CXX ?= g++
CC ?= gcc
NIMC ?= nim
AR ?= ar
CFLAGS = -c -Wall -O3 -fPIC -g -march=native
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
LIB = lib
BIN = bin
SRC = src
LIBDFLAG = -L$(LIB)
LIBNTHASHF = -lnthash
NIMPTHASH = nimPtHash
NIMWFA = nimWfa
NIMARMA = nimArma
NIMGMM = nimGmm
NIMAF = alignmentFree
ARMA_INC = -Iexternal/armadillo/include

WFA = external/WFA2
WFA_WF_SRC = $(WFA)/wavefront
WFA_CPP_SRC = $(WFA)/bindings/cpp
WFA_MM_SRC = $(WFA)/system
WFA_UT_SRC = $(WFA)/utils
WFA_AL_SRC = $(WFA)/alignment
WFA_INC = -I$(WFA) -I$(WFA_WF_SRC) -I$(WFA_CPP_SRC) -I$(WFA_MM_SRC) -I$(WFA_UT_SRC) -I$(WFA_AL_SRC)
WFA_CPP_LIB = $(LIB)/libwfacpp.a
_WFA_WF_OBJ =wavefront.o \
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
_WFA_MM_OBJ = mm_allocator.o \
	      mm_stack.o \
	      profiler_counter.o \
	      profiler_timer.o
_WFA_UT_OBJ = bitmap.o \
	      commons.o \
	      dna_text.o \
	      heatmap.o \
	      sequence_buffer.o \
	      vector.o
_WFA_AL_OBJ = affine2p_penalties.o \
	      affine_penalties.o \
	      cigar.o \
	      cigar_utils.o \
	      score_matrix.o
WFA_OBJ = $(patsubst %, $(WFA_UT_SRC)/%, $(_WFA_UT_OBJ)) \
	  $(patsubst %, $(WFA_AL_SRC)/%, $(_WFA_AL_OBJ)) \
	  $(patsubst %, $(WFA_MM_SRC)/%, $(_WFA_MM_OBJ)) \
	  $(patsubst %, $(WFA_WF_SRC)/%, $(_WFA_WF_OBJ)) \
	  $(patsubst %, $(WFA_CPP_SRC)/%, $(_WFA_CPP_OBJ))
LIBWFAF = -lwfacpp

all: $(NIMPTHASH) $(WFA_CPP_LIB) $(NIMWFA) $(NIMARMA) $(NIMGMM) $(NIMAF)

$(NIMPTHASH) : $(SRC)/$(NIMPTHASH).nim $(NTHASH_LIB) | bin
	$(NIMC) cpp -d:release -o:$(BIN)/$(NIMPTHASH) --passC:"$(PTHASH_INC) $(NTHASH_INC) -Iinclude" --passL:"$(LIBDFLAG) $(LIBNTHASHF)" $<

$(NTHASH_SRC)/%.o : $(NTHASH_SRC)/%.cpp
	$(CXX) $(CFLAGS) $(NTHASH_INC) -o $@ $<

$(NTHASH_LIB) : $(NTHASH_OBJ) | $(LIB)
	$(AR) rs $@ $^

$(WFA_WF_SRC)/%.o : $(WFA_WF_SRC)/%.c
	$(CC) $(CFLAGS) $(WFA_INC) -o $@ $<

$(WFA_UT_SRC)/%.o : $(WFA_UT_SRC)/%.c
	$(CC) $(CFLAGS) $(WFA_INC) -o $@ $<

$(WFA_MM_SRC)/%.o : $(WFA_MM_SRC)/%.c
	$(CC) $(CFLAGS) $(WFA_INC) -o $@ $<

$(WFA_AL_SRC)/%.o : $(WFA_AL_SRC)/%.c
	$(CC) $(CFLAGS) $(WFA_INC) -o $@ $<

$(WFA_CPP_SRC)/%.o : $(WFA_CPP_SRC)/%.cpp
	$(CXX) $(CFLAGS) $(WFA_INC) -I$(WFA_CPP_SRC) -o $@ $<

$(WFA_CPP_LIB) : $(WFA_OBJ) | $(LIB)
	$(AR) rs $@ $^ 

$(NIMWFA) : $(SRC)/$(NIMWFA).nim $(WFA_CPP_LIB) | bin
	$(NIMC) cpp -d:release -o:$(BIN)/$(NIMWFA) --passC:"-I$(WFA_CPP_SRC) -Iexternal/WFA2" --passL:"$(LIBDFLAG) $(LIBWFAF)" $<

$(NIMARMA) : $(SRC)/$(NIMARMA).nim | bin
	$(NIMC) cpp -d:release -o:$(BIN)/$(NIMARMA) --passC:"$(ARMA_INC)" --passL:"-lopenblas" $<

$(NIMGMM) : $(SRC)/$(NIMGMM).nim | bin
	$(NIMC) cpp -d:release -o:$(BIN)/$(NIMGMM) --passC:"-fopenmp $(ARMA_INC)" --passL:"-lgomp -llapack -lopenblas" $<

$(NIMAF) : $(SRC)/$(NIMAF).nim | bin
	$(NIMC) cpp -d:release -o:$(BIN)/$(NIMAF) --passC:"-fopenmp $(PTHASH_INC) $(NTHASH_INC) $(ARMA_INC) -I$(WFA_CPP_SRC) -Iexternal/WFA2" --passL:"$(LIBDFLAG) $(LIBNTHASHF) $(LIBWFAF) -lopenblas -lgomp -llapack" $<

$(LIB) :
	mkdir -p $@
$(BIN) :
	mkdir -p $@

.PHONY: clean

clean:
	rm -f $(NTHASH_OBJ) $(WFA_OBJ)
	rm -f $(LIB)/*
	rm -f $(BIN)/*
