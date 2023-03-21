/*
 * Copyright (C) 2014, Guangxi Liu <guangxi.liu@opencores.org>
 *
 * This source file may be used and distributed without restriction provided
 * that this copyright statement is not removed from the file and that any
 * derivative work contains the original copyright notice and the associated
 * disclaimer.
 *
 * This source file is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License,
 * or (at your option) any later version.
 *
 * This source is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this source; if not, download it from
 * http://www.opencores.org/lgpl.shtml
 */

// ========== Copyright Header Begin ============================================
// Copyright (c) 2022 Princeton University
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ========== Copyright Header End ============================================

#include <stdio.h>

 
typedef struct {
    unsigned long long z1, z2, z3;
} taus_state_t;

taus_state_t state;


/* Update state */
unsigned long long taus_get()
{
    unsigned long long b;
    
    b = (((state.z1 << 5) ^ state.z1) >> 39);
    state.z1 = (((state.z1 & 18446744073709551614ULL) << 24) ^ b);
    b = (((state.z2 << 19) ^ state.z2) >> 45);
    state.z2 = (((state.z2 & 18446744073709551552ULL) << 13) ^ b);
    b = (((state.z3 << 24) ^ state.z3) >> 48);
    state.z3 = (((state.z3 & 18446744073709551104ULL) << 7) ^ b);
    
    return (state.z1 ^ state.z2 ^ state.z3);
}


/* Set state using seed */
#define LCG(n) (4294967291ULL * n)

void taus_set(unsigned long s)
{
    if (s == 0)    s = 1;    /* default seed is 1 */
    
    state.z1 = LCG(s);
    if (state.z1 < 2ULL)     state.z1 += 2ULL;
    state.z2 = LCG(state.z1);
    if (state.z2 < 64ULL)    state.z2 += 64ULL;
    state.z3 = LCG(state.z2);
    if (state.z3 < 512ULL)   state.z3 += 512ULL;
    
    /* "warm it up" */
    taus_get();
    taus_get();
    taus_get();
    taus_get();
    taus_get();
    taus_get();
    taus_get();
    taus_get();
    taus_get();
    taus_get();
}


/* Coefficients table */
static const long C0[248] = {
    11049, 8007, 5220, 2577, 18846, 16547, 14535, 12721, 25134, 23229,
    21594, 20150, 30518, 28863, 27458, 26231, 35288, 33808, 32562, 31479,
    39608, 38260, 37130, 36152, 43582, 42336, 41296, 40399, 47277, 46115,
    45147, 44314, 50745, 49651, 48742, 47963, 54020, 52985, 52126, 51390,
    57132, 56147, 55331, 54632, 60101, 59160, 58381, 57715, 62945, 62043,
    61296, 60659, 65679, 64811, 64093, 63481, 68314, 67476, 66784, 66194,
    70859, 70049, 69381, 68811, 73323, 72538, 71891, 71340, 75714, 74952,
    74324, 73790, 78036, 77296, 76686, 76167, 80297, 79576, 78982, 78477,
    82500, 81797, 81218, 80726, 84649, 83963, 83398, 82918, 86748, 86078,
    85526, 85057, 88800, 88145, 87606, 87147, 90809, 90167, 89640, 89191,
    92777, 92148, 91631, 91192, 94706, 94090, 93583, 93152, 96599, 95994,
    95496, 95074, 98457, 97863, 97374, 96960, 100282, 99698, 99219, 98811,
    102076, 101502, 101031, 100630, 103841, 103276, 102812, 102419, 105577, 105021,
    104565, 104178, 107286, 106739, 106290, 105909, 108970, 108431, 107989, 107613,
    110629, 110098, 109662, 109292, 112265, 111741, 111311, 110946, 113878, 113361,
    112937, 112578, 115469, 114959, 114541, 114186, 117040, 116536, 116124, 115774,
    118590, 118093, 117686, 117340, 120121, 119630, 119228, 118887, 121633, 121149,
    120751, 120414, 123128, 122649, 122256, 121923, 124605, 124132, 123743, 123414,
    126065, 125597, 125213, 124888, 127510, 127047, 126667, 126345, 128938, 128480,
    128105, 127786, 130351, 129898, 129527, 129212, 131750, 131301, 130934, 130622,
    133134, 132690, 132326, 132018, 134505, 134065, 133705, 133400, 135862, 135426,
    135070, 134767, 137206, 136775, 136421, 136122, 138537, 138110, 137760, 137463,
    139856, 139433, 139086, 138792, 141163, 140743, 140400, 140109, 142458, 142042,
    141702, 141413, 143742, 143330, 142992, 142706, 145015, 144606, 144272, 143988,
    146277, 145872, 145540, 145259, 150000, 148769, 147528, 146797
};

static const long C1[248] = {
    -102514, -92199, -86162, -82951, -79070, -68105, -60693, -55396, -66134, -55839,
    -48783, -43639, -57755, -48215, -41670, -36890, -51803, -42932, -36856, -32421,
    -47313, -39012, -33338, -29203, -43778, -35964, -30631, -26751, -40907, -33511,
    -28470, -24807, -38519, -31483, -26695, -23220, -36492, -29774, -25206, -21893,
    -34747, -28307, -23933, -20765, -33223, -27032, -22831, -19789, -31878, -25911,
    -21864, -18936, -30681, -24915, -21007, -18182, -29606, -24023, -20242, -17509,
    -28634, -23218, -19552, -16903, -27750, -22488, -18927, -16356, -26942, -21821,
    -18357, -15857, -26198, -21208, -17835, -15400, -25512, -20644, -17354, -14980,
    -24876, -20121, -16909, -14591, -24285, -19636, -16496, -14231, -23733, -19184,
    -16111, -13896, -23217, -18760, -15752, -13583, -22732, -18364, -15415, -13290,
    -22276, -17991, -15099, -13015, -21846, -17639, -14801, -12756, -21440, -17307,
    -14520, -12512, -21055, -16993, -14253, -12281, -20690, -16695, -14001, -12062,
    -20342, -16412, -13762, -11854, -20012, -16143, -13534, -11656, -19697, -15886,
    -13317, -11468, -19396, -15641, -13111, -11289, -19109, -15407, -12913, -11118,
    -18834, -15183, -12724, -10954, -18570, -14969, -12543, -10797, -18317, -14763,
    -12369, -10646, -18073, -14565, -12202, -10502, -17839, -14375, -12042, -10363,
    -17614, -14193, -11888, -10230, -17397, -14016, -11739, -10102, -17188, -13847,
    -11596, -9978, -16986, -13683, -11458, -9858, -16791, -13525, -11325, -9743,
    -16603, -13372, -11196, -9632, -16421, -13224, -11072, -9524, -16244, -13081,
    -10951, -9420, -16073, -12942, -10835, -9319, -15907, -12808, -10722, -9222,
    -15747, -12678, -10612, -9127, -15591, -12552, -10506, -9035, -15440, -12429,
    -10403, -8946, -15294, -12311, -10303, -8860, -15154, -12196, -10206, -8776,
    -15020, -12086, -10113, -8695, -14894, -11982, -10024, -8618, -14779, -11885,
    -9940, -8544, -14681, -11797, -9863, -8475, -13792, -11190, -9418, -8133,
    0, 0, 0, 0, 0, 0, 0, 0
};

static const long C2[248] = {
    83840, 48883, 25920, 8147, 88988, 59916, 42707, 31577, 83526, 57019,
    41464, 31523, 77411, 52885, 38533, 29386, 71990, 49106, 35743, 27241,
    67363, 45865, 33332, 25372, 63422, 43107, 31282, 23780, 60040, 40746,
    29530, 22422, 57109, 38706, 28020, 21254, 54545, 36926, 26705, 20239,
    52279, 35358, 25549, 19349, 50262, 33965, 24525, 18561, 48452, 32718,
    23609, 17858, 46818, 31593, 22785, 17226, 45333, 30573, 22038, 16654,
    43976, 29643, 21358, 16134, 42731, 28790, 20735, 15658, 41583, 28005,
    20163, 15221, 40521, 27279, 19634, 14817, 39534, 26606, 19143, 14444,
    38614, 25978, 18687, 14096, 37754, 25392, 18261, 13772, 36948, 24844,
    17862, 13468, 36190, 24328, 17488, 13184, 35477, 23843, 17136, 12916,
    34803, 23385, 16804, 12664, 34165, 22952, 16490, 12426, 33561, 22542,
    16193, 12200, 32987, 22153, 15911, 11986, 32441, 21783, 15643, 11783,
    31921, 21431, 15388, 11590, 31425, 21094, 15145, 11406, 30951, 20773,
    14913, 11230, 30497, 20466, 14691, 11061, 30063, 20173, 14479, 10901,
    29646, 19891, 14275, 10746, 29246, 19620, 14080, 10599, 28861, 19360,
    13892, 10456, 28492, 19110, 13711, 10320, 28135, 18870, 13538, 10189,
    27792, 18638, 13370, 10062, 27461, 18414, 13209, 9940, 27141, 18199,
    13053, 9822, 26832, 17990, 12903, 9709, 26534, 17788, 12758, 9599,
    26245, 17593, 12617, 9492, 25965, 17405, 12481, 9390, 25694, 17222,
    12349, 9290, 25432, 17045, 12222, 9194, 25178, 16874, 12098, 9100,
    24933, 16708, 11979, 9010, 24697, 16549, 11864, 8923, 24474, 16397,
    11754, 8840, 24268, 16255, 11650, 8761, 24088, 16129, 11557, 8689,
    23954, 16029, 11480, 8628, 23908, 15977, 11432, 8586, 24029, 16017,
    11440, 8581, 24481, 16238, 11559, 8648, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0
};


/* Calculate Inverse of the normal CDF */
long icdf(unsigned long long n)
{
    unsigned long long t;
    int i;
    unsigned num_lzd;
    unsigned addr;
    long c0, c1, c2;
    long x;
    long long y;
    int carry;

    t = n;
    num_lzd = 0;
    for (i = 0; i < 61; i++) {
        if (t & 0x8000000000000000ULL)
            break;
        else {
            ++num_lzd;
            t <<= 1;
        }
    }
    addr = num_lzd << 2;
    if (n & 2ULL)
        addr += 2;
    if (n & 4ULL)
        ++addr;

    c0 = C0[addr];
    c1 = C1[addr];
    c2 = C2[addr];

    if (num_lzd <= 60)
        n &= ~(1ULL << (63 - num_lzd));

    t = n >> 3;
    x = 0;
    for (i = 0; i < 15; i++) {
        x <<= 1;
        if (t & 1ULL)
            ++x;
        t >>= 1;
    }

    y = (long long)c2 * (long long)x;
    y += ((long long)c1 << 19);
    y >>= 20;
    y *= (long long)x;
    y >>= 19;
    y += (long long)c0;
    carry = (y & 4ULL) ? 1 : 0;
    y >>= 3;
    y += carry;
    if (n & 1ULL)
        y = -y;

    return (long)y;
}


int main(int argc, char ** argv) {
  taus_set(1);

  int64_t res = 0;
  // printf("Hello world, I am GNG!\n");
  for (int k = 0; k < 4096; k++) {
    // assemble number and print
    int16_t num = icdf(taus_get());
    res += num;
    // printf("My new random number is %d\n", num);
  }

  printf("Done! %d\n", res);

  return 0;
}
