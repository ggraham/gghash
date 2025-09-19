#pragma once
#include <vector>
#include <string>
#include <unordered_set>
#include "nthash.hpp"
#include "pthash_utils_encoders.hpp"
#include "pthash_utils_dense_encoders.hpp"
#include "pthash_dense_partitioned_phf.hpp"
#include "pthash_util.hpp"

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
        public:
        GHash(int k);
        GHash(int k, pthash::build_configuration config);
        void insert(nthash::NtHash *h);
        void increment(nthash::NtHash *h);
        void insert(std::string s);
        void insert(char *s, int l);
        void build();
        uint64_t search(uint64_t h);
        std::vector<uint64_t> search(std::string s);
        uint64_t ix(uint64_t h);
        std::vector<uint64_t> ix(std::string s);
        void inc(std::string s);
        void inc(char *s, int l);
};
} //namespace NtHashMPHF
