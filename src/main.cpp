#include <iostream>
#include <cassert>
#include <zlib.h>
#include <vector>
#include <string>
#include <unordered_set>
#include "NtHashMPHF.hpp"
#include "CLI11.hpp"
#include "kseq.h"

KSEQ_INIT(gzFile, gzread);

int main(int argc, char** argv)
{
        CLI::App phf{"phf"};
        argv = phf.ensure_utf8(argv);
        
        uint64_t num_keys;
        gzFile fp;
        std::string fn;
        int k;
        phf.add_option("-f,--file", fn, "fastq file");
        phf.add_option("-k,--kmer", k, "kmer size");
        CLI11_PARSE(phf, argc, argv);

        kseq_t *s;
        int l;
        uint64_t n = 0;
        fp = gzopen(fn.c_str(), "r");
        s = kseq_init(fp);
        NtHashMPHF::GHash gh(k);
        // Inserting keys
        std::cout << "Inserting sequences..." << std::endl;
        while ((l = kseq_read(s)) >= 0)
        {
                gh.insert(s->seq.s, s->seq.l);
                ++n;
                if (n % 100000 == 0)
                {
                        std::cout << n << " hashed sequences inserted" << std::endl;
                }
        }
        // Building index
        std::cout << "Building MPHF..." << std::endl;
        gh.build();
        gzrewind(fp);
        s = kseq_init(fp);
        n = 0;
        // Second pass counting keys
        std::cout << "Counting keys..." << std::endl;
        while ((l = kseq_read(s)) >= 0)
        {
                gh.inc(s->seq.s, s->seq.l);
                ++n;
                if (n % 100000 == 0)
                {
                        std::cout << n << " hashed sequences incremented" << std::endl;
                }
        }
        return 0;
}
