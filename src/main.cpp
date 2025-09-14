#include <random>
#include <string>
#include <iostream>
#include <vector>
#include "CLI11.hpp"
#define XXH_STATIC_LINKING_ONLY
#define XXH_IMPLEMENTATION
#include "xxhash.h"

#include "dense_partitioned_phf.hpp"

namespace xxh
{
	class xxhc
	{
		std::string seq;
		public:
		xxhc(std::string seq) : seq{seq} {}
		uint64_t gethash() {
			return XXH3_64bits(seq.c_str(), seq.size());
		}

	};
}

std::vector<uint64_t> distinct_uints(const uint64_t nk, const uint64_t seed)
{
	auto gen = std::mt19937_64(std::random_device()());
	std::vector<uint64_t> keys(nk * 1.05);
	std::generate(keys.begin(), keys.end(), gen);
	return keys;
}

int main(int argc, char* argv[])
{
	CLI::App hasher{"does hashing"};
	argv = hasher.ensure_utf8(argv);
	std::string sequence = "default";
	hasher.add_option("-s,--seq", sequence, "input sequence");
	CLI11_PARSE(hasher, argc, argv);

	xxh::xxhc h(sequence);
	std::cout << h.gethash() << std::endl;
	//
	pthash::build_configuration config;
	config.seed = 0;
	config.lambda = 5;
	config.alpha = 0.97;
	config.verbose = true;
	config.avg_partition_size = 100;
	config.num_threads = 4;
	config.dense_partitioning = false;
	std::vector<uint64_t> v = distinct_uints(500000, 0);
	pthash::phobic<pthash::xxhash_64> p;
	auto timing = p.build_in_internal_memory(v.begin(), v.size(), config);
	//auto x = distinct_uints(5, 5);
	//
	return 0;
}


