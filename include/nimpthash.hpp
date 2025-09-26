#pragma once
#include <vector>
#include <string>
#include <unordered_set>
#include <tuple>
#include "pthash.hpp"
#include "nthash/nthash.hpp"
namespace NtPtHash
{
	class GHash
	{
		std::unordered_set<uint64_t> m;
		pthash::build_configuration config;
		pthash::phobic<pthash::xxhash_128> pth;
		uint64_t k;
		uint64_t target_size;
		bool built = false;
		inline void ins(nthash::NtHash *h)
		{
			while (h->roll())
			{
				m.insert(h->hashes()[0]);
			}
		}
		inline std::vector<uint64_t> hx(nthash::NtHash *h)
		{
			std::vector<uint64_t> output;
			while (h->roll())
			{
				output.push_back(h->hashes()[0]);
			}
			return output;
		}
		inline std::vector<uint64_t> idx(nthash::NtHash *h)
		{
			std::vector<uint64_t> output;
			while (h->roll())
			{
				output.push_back(idx(h->hashes()[0]));
			}
			return output;
		}
		public:
		GHash(uint64_t k)
			: k(k) {};
		GHash(uint64_t k, pthash::build_configuration config)
			: config(config), k(k) {};
		GHash(const uint64_t k, const uint64_t num_threads, const uint64_t seed = 7, const uint64_t avg_partition_size = 100000, const double alpha = 0.97, const double lambda = 5, const bool verbose = true, const bool dense_partitioning = true)
			: k(k)
		{
			config.verbose = verbose;
			config.avg_partition_size = avg_partition_size;
			config.alpha = alpha;
			config.lambda = lambda;
			config.dense_partitioning = dense_partitioning;
			config.seed = seed;
			config.num_threads = num_threads;
		}
        inline uint64_t idx(uint64_t h)
        {
                return pth(h);
        }
		inline uint64_t getSize()
		{
			return target_size;
		}
		inline void ins(std::string s)
		{
			nthash::NtHash h(s, 1, k, 0);
			ins(&h);
		}
		inline void ins(char *s, size_t l)
		{
			nthash::NtHash h(s, l, 1, k, 0);
			ins(&h);
		}
		inline std::vector<uint64_t> hx(std::string s)
		{
			nthash::NtHash h(s, 1, k, 0);
			return hx(&h);
		}
		inline std::vector<uint64_t> hx(char *s, size_t l)
		{
			nthash::NtHash h(s, l, 1, k, 0);
			return hx(&h);
		}
		inline std::vector<uint64_t> idx(std::string s)
		{
			nthash::NtHash h(s, 1, k, 0);
			if (!built)
			{
				build();
			}
			return idx(&h);
		}
		inline std::vector<uint64_t> idx(char *s, size_t l)
		{
			nthash::NtHash h(s, l, 1, k, 0);
			if (!built)
			{
				build();
			}
			return idx(&h);
		}
		inline void build()
		{
			std::cout << "building map with " << m.size() << " keys" << std::endl;
			target_size = m.size();
			pth.build_in_internal_memory(m.begin(), target_size, config);
			m.clear();
			built = true;
		}
	};
}
