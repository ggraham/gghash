#include <iostream>
#include <cassert>
#include <zlib.h>
#include <unordered_set>
#include "NtHashMPHF.hpp"

namespace NtHashMPHF
{
GHash::GHash(int k) : k(k)
{
        config.seed = 7;
        config.lambda = 5;
        config.alpha = 0.97;
        config.verbose = true;
        config.num_threads = 6;
}
GHash::GHash(int k, pthash::build_configuration config) : config(config), k(k) {}
void GHash::insert(nthash::NtHash *h) {
        while (h->roll())
        {
                m.insert(h->hashes()[0]);
        }
}
void GHash::inc(nthash::NtHash *h)
{
        while (h->roll())
        {
                ++v[pth(h->hashes()[0])];
        }
}
void GHash::insert(std::string s)
{
        nthash::NtHash nth(s, 1, k, 0);
        insert(&nth);
}
void GHash::insert(char *s, int l)
{
        nthash::NtHash nth(s, l, 1, k, 0);
        insert(&nth);
}
void GHash::build()
{
        std::cout << "building map with " << m.size() << " keys" << std::endl;
        int target_size = m.size();
        pth.build_in_internal_memory(m.begin(), target_size, config);
        m.clear();
        v.resize(target_size, 0);
}

uint64_t GHash::ix(uint64_t h)
{
        return pth(h);
}
std::vector<uint64_t> GHash::ix(nthash::NtHash *h)
{
	std::vector<uint64_t> output;
	while (h->roll())
	{
		output.push_back(ix(h->hashes()[0]));
	}
	return output;
}
std::vector<uint64_t> GHash::ix(std::string s)
{
        nthash::NtHash nth(s, 1, k, 0);
        return ix(&nth);
}
std::vector<uint64_t> GHash::ix(char *s, int l)
{
	nthash::NtHash nth(s, l, 1, k, 0);
	return ix(&nth);
}
uint64_t GHash::search(uint64_t h)
{
        return v[ix(h)];
}
std::vector<uint64_t> GHash::search(std::string s)
{
        nthash::NtHash nth(s, 1, k, 0);
        std::vector<uint64_t> output;
        while (nth.roll())
        {
                output.push_back(search(nth.hashes()[0]));
        }
        return output;
}
void GHash::inc(std::string s)
{
        nthash::NtHash nth(s, 1, k, 0);
        GHash::inc(&nth);
}
void GHash::inc(char *s, int l)
{
        nthash::NtHash nth(s, l, 1, k, 0);
        GHash::inc(&nth);
}
} //namespace NtHashMPHF
