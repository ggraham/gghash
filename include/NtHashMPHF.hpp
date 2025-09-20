#pragma once
#include <vector>
#include <string>
#include <unordered_set>
#include "nthash.hpp"
#include "pthash.hpp"

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

	GHash(int);
        GHash(int, pthash::build_configuration);

	void insert(nthash::NtHash*);
        void insert(std::string);
        void insert(char*, int);

	void build();

	uint64_t ix(uint64_t h);
	std::vector<uint64_t> ix(nthash::NtHash*);
	std::vector<uint64_t> ix(std::string);
	std::vector<uint64_t> ix(char*, int);

	uint64_t search(uint64_t);
        std::vector<uint64_t> search(std::string);

	void inc(nthash::NtHash*);
	void inc(std::string);
        void inc(char*, int);
};
} //namespace NtHashMPHF
