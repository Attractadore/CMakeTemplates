#include <boost/predef.h>

#if BOOST_LIB_STD_CXX
int main() {}
#else
#error libc++ not detected
#endif
