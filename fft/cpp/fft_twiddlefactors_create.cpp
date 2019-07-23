#include <iostream>
#include <cmath>
#include <complex>
#include <fstream>
#include <bitset>

#define M_PI 3.14159265
#define SIZE 1024
//#define FLOATING

std::bitset<sizeof(float) * CHAR_BIT> ftobitset(float num){
  union
  {
       float input;   // assumes sizeof(float) == sizeof(int)
       int   output;
  }    data;

  data.input = num;

  std::bitset<sizeof(float) * CHAR_BIT> bits(data.output);

  return data.output;
}

template <class BaseType, size_t FracDigits>
class fixed_point {
    const static BaseType factor = 1 << FracDigits;
    BaseType data;
public:
    fixed_point(double d){
        *this = d; // calls operator=
    }

    fixed_point& operator=(double d){
        data = static_cast<BaseType>(d*factor);
        return *this;
    }

    BaseType raw_data() const {
        return data;
    }
};

int main(int argc, char const *argv[]) {
  std::ofstream file("fft_twiddlefactors_rom.txt");
  fixed_point<unsigned char, 7> fpIm(0), fpRe(0);

  std::complex<double> t;

  for (int k = 0; k < SIZE/2; k++) {
    t = exp(std::complex<double>(0, -2 * M_PI * k / SIZE));

    #ifdef FLOATING
    std::cout << ftobitset(t.imag()) << "_" << ftobitset(t.real()) << "\n";
    file << ftobitset(t.imag()) << ftobitset(t.real()) << "\n";
    #else
    fpRe = t.real(); fpIm = t.imag();
    std::cout << std::bitset<8>(fpIm.raw_data()) << "_" << std::bitset<8>(fpRe.raw_data()) << "\n";
    file << std::bitset<8>(fpIm.raw_data()) << std::bitset<8>(fpRe.raw_data()) << "\n";
    #endif
  }
  // fpRe = 0.625; fpIm = -0.625;
  // std::cout << ":::" << std::bitset<8>(fpRe.raw_data());
  // std::cout << ":::" << std::bitset<8>(fpIm.raw_data());
  return 0;
}
