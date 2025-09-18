#include <iostream>
#include <cassert>
#include <zlib.h>
#include <vector>
#include <string>
#include <unordered_set>
#include "CLI11.hpp"
#include "kseq.h"
#include "nthash.hpp"
#include "pthash_utils_encoders.hpp"
#include "pthash_utils_dense_encoders.hpp"
#include "pthash_dense_partitioned_phf.hpp"
#include "pthash_util.hpp"

KSEQ_INIT(gzFile, gzread);

namespace NtHashMPHF
{
        class GHash
        {
                private:
                std::unordered_set<uint64_t> m;
                pthash::build_configuration config;
                pthash::dense_partitioned_phf<pthash::xxhash_128, pthash::opt_bucketer, pthash::R_int, true> pth;
                std::vector<uint64_t> v;
                int k;
                
                void insert(nthash::NtHash *h)
                {
                        while (h->roll())
                        {
                                m.insert(h->hashes()[0]);
                        }
                }
                void increment(nthash::NtHash *h)
                {
                        while (h->roll())
                        {
                                ++v[pth(h->hashes()[0])];
                        }
                }
                
                public:
                GHash(int k) : k(k)
                {
                        config.seed = 7;
                        config.lambda = 5;
                        config.alpha = 0.97;
                        config.verbose = true;
                        config.num_threads = 6;
                }
                GHash(int k, pthash::build_configuration config): k(k), config(config) {};
                void insert(std::string s)
                {
                        nthash::NtHash nth(s, 1, k, 0);
                        insert(&nth);
                }
                void insert(char *s, int l)
                {
                        nthash::NtHash nth(s, l, 1, k, 0);
                        insert(&nth);
                }
                void build()
                {
                        std::cout << "building map with " << m.size() << " keys" << std::endl;
                        int target_size = m.size();
                        pth.build_in_internal_memory(m.begin(), target_size, config);
                        m.clear();
                        v.resize(target_size, 0);
                }
                uint64_t search(uint64_t h)
                {
                        return v[pth(h)];
                }
                std::vector<uint64_t> search(std::string s)
                {
                        nthash::NtHash nth(s, 1, k, 0);
                        std::vector<uint64_t> output;
                        while (nth.roll())
                        {
                                output.push_back(search(nth.hashes()[0]));
                        }
                        return output;
                }
                void inc(std::string s)
                {
                        nthash::NtHash nth(s, 1, k, 0);
                        increment(&nth);
                }
                void inc(char *s, int l)
                {
                        nthash::NtHash nth(s, l, 1, k, 0);
                        increment(&nth);
                }
        };
}

using namespace pthash;

int main(int argc, char** argv)
{
        CLI::App phf{"phf"};
        argv = phf.ensure_utf8(argv);
        
        uint64_t num_keys;
        gzFile fp;
        std::string fn;
        phf.add_option("-k,--keys", num_keys, "number of keys to generate");
        phf.add_option("-f,--file", fn, "fastq file");
        CLI11_PARSE(phf, argc, argv);

        kseq_t *s;
        int l;
        fp = gzopen(fn.c_str(), "r");
        s = kseq_init(fp);
        NtHashMPHF::GHash gh(12);
        while ((l = kseq_read(s)) >= 0)
        {
                gh.insert(s->seq.s, s->seq.l);
        }
        gh.build();
        std::cout << "searching TGATGAACACCATCA: " << gh.search("TGATGAACACCATCA")[0] << std::endl;
        gh.inc("TGATGAACACCATCA");
        for (auto b : gh.search("TGATGAACACCATCA"))
        {
                std::cout << "searching TGATGAACACCATCA: " << b << std::endl;
        }
        gzrewind(fp);
        //###############
        while ((l = kseq_read(s)) > =)
        {
        }
        return 0;
}
